#!/usr/bin/env bats
# STORY-008 tests: validate-wikilink-integrity.sh PostToolUse hook
# Traces to: BC-2.04.003
# VP coverage: VP-004 (wikilink resolution — all valid → exit 0, broken → exit 2,
#              no wikilinks → exit 0, missing index → exit 2 fail-closed)
# VP-002: PostToolUse hook trigger on wiki writes

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory — the hook resolves wiki/index.md relative to
  # BRAIN_DIR (established pattern from STORY-007 / validate-source-immutability.sh).
  BRAIN_DIR="$(mktemp -d)"
  mkdir -p "${BRAIN_DIR}/wiki"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PostToolUse payload for a Write call to a wiki page.
# The hook reads wikilinks from tool_input.content (the written content) and
# checks slugs against wiki/index.md on the filesystem via BRAIN_DIR.
# Arguments:
#   $1 — absolute file_path embedded in the payload
#   $2 — content string (the wiki page body, newlines as \n in JSON)
#   $3 — tool_name (Write or Edit) [default: Write]
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local content="$2"
  local tool_name="${3:-Write}"
  # Escape the content for JSON embedding: replace \ with \\, " with \", newline with \n
  local escaped_content
  escaped_content="$(printf '%s' "${content}" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
  # escaped_content now includes the surrounding quotes from json.dumps — strip them
  escaped_content="${escaped_content:1:${#escaped_content}-2}"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"%s"},"tool_use_id":"test-456","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${file_path}" "${escaped_content}"
}

# ===========================================================================
# AC-001 / BC-2.04.003 precondition 1 + ADR-002 §hook-contract invariants:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_003_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_003_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_003_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_003_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-002 / BC-2.04.003 postconditions §all wikilinks resolve:
# All slugs in wiki/index.md → exit 0 + continue:true stdout.
# ADR-002 v2.0 schema: {"continue":true,...}  (NOT retired v1.0 "verdict":"allow")
# ===========================================================================

@test "test_BC_2_04_003_all_wikilinks_valid_exits_0" {
  # wiki/index.md contains test-concept and test-person (from fixture).
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-valid-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-valid.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_003_all_wikilinks_valid_stdout_contains_continue_true" {
  # ADR-002 v2.0: allow → {"continue":true,...}  (not the retired v1.0 verdict:allow)
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-valid-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-valid.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-003 / BC-2.04.003 postconditions §broken wikilink:
# Broken slug → exit 2, E-WIKI-001 in stdout.
# ADR-002 v2.0 schema: {"continue":false,"decision":"block","reason":"...","hookSpecificOutput":{"code":"E-WIKI-001",...}}
# ===========================================================================

@test "test_BC_2_04_003_broken_wikilink_exits_2_with_E_WIKI_001" {
  # wiki-page-broken-link.md contains [[nonexistent-slug]] which is NOT in the index.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-broken-link.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-001"* ]]
}

@test "test_BC_2_04_003_broken_wikilink_message_names_the_broken_slug" {
  # BC-2.04.003 postcondition §broken: message must name the broken slug.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-broken-link.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"nonexistent-slug"* ]]
}

@test "test_BC_2_04_003_broken_wikilink_stdout_contains_decision_block" {
  # ADR-002 v2.0: block → {"continue":false,"decision":"block",...}
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-broken-link.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *'"decision":"block"'* ]]
}

@test "test_BC_2_04_003_E_WIKI_001_code_in_hookSpecificOutput" {
  # ADR-002 v2.0: error code at hookSpecificOutput.code (not just anywhere in output).
  # Suppress stderr so $output only contains stdout JSON (parseable by jq).
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-broken-link.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-WIKI-001" ]
}

# ===========================================================================
# AC-004 / BC-2.04.003 postcondition §no wikilinks + EC-001:
# Page with zero [[...]] patterns → exit 0 (vacuously valid).
# ===========================================================================

@test "test_BC_2_04_003_page_with_no_wikilinks_exits_0" {
  # wiki-page-no-links.md has no [[slug]] patterns at all.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-no-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-no-links.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_003_page_with_no_wikilinks_stdout_contains_continue_true" {
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-no-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-no-links.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-005 / BC-2.04.003 invariant 2 + EC-002:
# wiki/index.md absent → exit 2, E-WIKI-002 (fail-closed).
# ===========================================================================

@test "test_BC_2_04_003_missing_index_md_exits_2_with_E_WIKI_002" {
  # BRAIN_DIR/wiki/ exists but no index.md inside it — deliberate absence.
  # Do NOT create wiki/index.md — the hook must fail-closed.
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-valid-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-no-index.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-002"* ]]
}

# ===========================================================================
# VP-004 / BC-2.04.003 postconditions §event emission:
# Blocked wikilink → stderr JSONL contains wiki.wikilink.broken event.
# Valid wikilinks → stderr JSONL contains wiki.wikilink.validated event.
# ===========================================================================

@test "VP_004_blocked_wikilink_emits_wiki_wikilink_broken_event_to_stderr" {
  # BC-2.04.003 postcondition §broken step 4 + BC-2.04.017 event catalog compliance.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-broken-link.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  # Capture stderr separately; swallow exit code (hook exits 2 = non-zero).
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"wiki.wikilink.broken"* ]]
}

@test "VP_004_blocked_wikilink_stderr_event_contains_hook_name" {
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-broken-link.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-wikilink-integrity.sh"* ]]
}

@test "VP_004_valid_wikilinks_emit_wiki_wikilink_validated_event_to_stderr" {
  # BC-2.04.003 postcondition §all-resolve step 3.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-valid-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-valid.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"wiki.wikilink.validated"* ]]
}

@test "VP_004_valid_wikilinks_stderr_event_contains_hook_name" {
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-valid-links.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-valid.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"validate-wikilink-integrity.sh"* ]]
}

# ===========================================================================
# Edge case: malformed (non-JSON) stdin → exit 2, fail-closed.
# BC-2.04.003 invariant 2 applies to any unreadable input.
# ===========================================================================

@test "test_BC_2_04_003_malformed_json_stdin_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_003_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

# ===========================================================================
# CLAUDE.md §Conventions §shellcheck + shfmt:
# Hook must pass shellcheck and shfmt normalization checks.
# ===========================================================================

@test "test_BC_2_04_003_hook_passes_shellcheck" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_003_hook_passes_shfmt_normalization" {
  run shfmt -d -i 2 "${HOOK}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# hooks.json registration: PostToolUse Write|Edit chain must include
# validate-wikilink-integrity.sh.
# ===========================================================================

@test "test_BC_2_04_003_hooks_json_PostToolUse_entry_includes_validate_wikilink_integrity" {
  run python3 -c "
import json, sys
with open('${PLUGIN_DIR}/hooks/hooks.json') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
post = hooks.get('PostToolUse', [])
found = False
for entry in post:
    for h in entry.get('hooks', []):
        cmd = h.get('command', '')
        if 'validate-wikilink-integrity.sh' in cmd:
            found = True
            break
if not found:
    print('ERROR: No PostToolUse entry pointing to validate-wikilink-integrity.sh', file=sys.stderr)
    sys.exit(1)
print('PASS')
"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_003_hooks_json_wikilink_entry_uses_CLAUDE_PLUGIN_ROOT_path" {
  run grep -q 'CLAUDE_PLUGIN_ROOT.*validate-wikilink-integrity.sh\|validate-wikilink-integrity.sh.*CLAUDE_PLUGIN_ROOT' "${PLUGIN_DIR}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# F-004 / BC-2.04.003 postconditions §broken:
# Multiple broken wikilinks — both slugs named in output.
# ===========================================================================

@test "test_BC_2_04_003_multiple_broken_wikilinks_both_named_in_output" {
  # wiki-page-multi-broken.md contains [[bad-one]] and [[bad-two]] — neither in index.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-multi-broken.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-multi-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"bad-one"* ]]
  [[ "$output" == *"bad-two"* ]]
}

@test "test_BC_2_04_003_multiple_broken_wikilinks_broken_slugs_is_json_array" {
  # BC-2.04.003: broken_slugs must be a JSON array in hookSpecificOutput.details.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  local page_content
  page_content="$(cat "${FIXTURES_DIR}/wiki-page-multi-broken.md")"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-multi-broken.md"
  local payload
  payload="$(_payload "${file_path}" "${page_content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local arr_len
  arr_len="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.details.broken_slugs | length' 2>/dev/null || true)"
  [ "$arr_len" -eq 2 ]
}

# ===========================================================================
# F-003 / VP-004 §O(n) performance:
# 1000-entry index — hook completes within CI-safe threshold (1000ms).
# AC-006: local target is 100ms; CI threshold is 1000ms to account for slower runners.
# ===========================================================================

# ===========================================================================
# F-P2-001 / BC-2.04.003: Edit tool_name reads content from disk (fallback path).
# When tool_name is Edit, tool_input.content may be absent — the hook reads
# the written file from disk via BRAIN_DIR instead.
# ===========================================================================

@test "test_BC_2_04_003_Edit_tool_name_reads_content_from_disk" {
  # Arrange: valid index + wiki page with a valid wikilink written to disk.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  mkdir -p "${BRAIN_DIR}/wiki/concepts"
  printf '%s\n' '---' 'type: concept' 'title: Test' '---' '' '# Test' '' 'See [[test-concept]].' \
    > "${BRAIN_DIR}/wiki/concepts/test-edit-path.md"

  # Build an Edit payload: no 'content' field — Edit uses old_string/new_string.
  local file_path="${BRAIN_DIR}/wiki/concepts/test-edit-path.md"
  local payload
  payload=$(printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":"%s","old_string":"See","new_string":"Also see","replace_all":false},"tool_use_id":"edit-p2-001","tool_result":{"type":"text","text":"Edit applied","exit_code":0}}' \
    "${BRAIN_DIR}" "${file_path}")

  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# F-P2-002 / BC-2.04.003: Non-wiki path early-exits with continue:true.
# BC-2.04.003 precondition 1: hook only validates wiki/** files.
# A file outside wiki/ must return exit 0 + continue:true immediately.
# ===========================================================================

@test "test_BC_2_04_003_non_wiki_path_exits_0_early_return" {
  # The hook must early-exit without touching wiki/index.md at all.
  # Do NOT create wiki/index.md — if the hook does not early-exit it would
  # fail with E-WIKI-002. Early exit means exit 0 + continue:true.
  local file_path="${BRAIN_DIR}/sources/ai/article.md"
  local payload
  payload="$(_payload "${file_path}" "# Content with [[some-link]]")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "VP_004_O_n_resolution_completes_under_1000ms_on_1000_entry_index" {
  # Generate a 1000-entry index.
  {
    printf -- '---\ntype: index\ntitle: Wiki Index\n---\n\n# Wiki Index\n\n'
    local i
    for i in $(seq 1 1000); do
      printf -- '- [Concept %d](concepts/concept-%04d.md)\n' "$i" "$i"
    done
  } > "${BRAIN_DIR}/wiki/index.md"

  # Page with one valid wikilink pointing to concept-0500 (in the generated index).
  local content
  content='---\ntype: concept\ntitle: Test\n---\n\n# Test\n\nSee [[concept-0500]].\n'
  local file_path="${BRAIN_DIR}/wiki/concepts/test-perf.md"
  local payload
  payload="$(_payload "${file_path}" "$(printf '%b' "${content}")")"

  local start_ms end_ms elapsed_ms
  start_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  end_ms="$(python3 -c 'import time; print(int(time.time()*1000))')"
  elapsed_ms=$((end_ms - start_ms))

  # Hook must exit 0 (concept-0500 is in the index).
  [ "$status" -eq 0 ]
  # CI-safe threshold: 1000ms (local target is 100ms per AC-006).
  [ "$elapsed_ms" -lt 1000 ]
}
