#!/usr/bin/env bats
# STORY-011 Red Gate tests: validate-source-id-citation.sh PostToolUse hook
# Traces to: BC-2.04.009
# VP coverage: VP-002 (PostToolUse trigger: source citation validation on wiki writes;
#              unresolved source_id → exit 2 + E-WIKI-007; manifest absent → exit 2)
#
# RED GATE — all behavioral tests MUST FAIL until the hook is implemented.
# Structural tests (shebang, set -euo) may pass against the stub.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-source-id-citation.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory — the hook reads .brain/manifest.json relative
  # to BRAIN_DIR env var (vault root is distinct from plugin root per story spec §Arc-5).
  BRAIN_DIR="$(mktemp -d)"
  mkdir -p "${BRAIN_DIR}/.brain"
  mkdir -p "${BRAIN_DIR}/wiki/concepts"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a PostToolUse payload for a Write call on a wiki page.
# The hook reads source_ids from the file on disk (post-write, file exists).
# Arguments:
#   $1 — absolute file_path embedded in the payload
#   $2 — tool_name (Write or Edit) [default: Write]
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local tool_name="${2:-Write}"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"stub"},"tool_use_id":"test-citation-011","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${file_path}"
}

# ---------------------------------------------------------------------------
# Helper: write a wiki page with source_ids frontmatter to BRAIN_DIR.
# Arguments:
#   $1 — relative path under BRAIN_DIR (e.g. wiki/concepts/test.md)
#   $2 ... — source_id slugs (e.g. "ai/valid-source"); pass zero slugs for empty list
# The source_ids field is written as inline YAML flow-sequence: source_ids: [slug1, slug2]
# Uses printf '%s\n' for each line to avoid macOS printf treating '---' as flag.
# ---------------------------------------------------------------------------
_write_wiki_page() {
  local rel_path="$1"
  shift
  local slugs=("$@")
  local abs_path="${BRAIN_DIR}/${rel_path}"
  mkdir -p "$(dirname "${abs_path}")"

  # Build the source_ids line as inline YAML flow-sequence.
  local source_ids_line="source_ids: ["
  local first=1
  for slug in "${slugs[@]+${slugs[@]}}"; do
    if [ "${first}" -eq 1 ]; then
      source_ids_line="${source_ids_line}${slug}"
      first=0
    else
      source_ids_line="${source_ids_line}, ${slug}"
    fi
  done
  source_ids_line="${source_ids_line}]"

  {
    printf '%s\n' "---"
    printf '%s\n' "title: Test Page"
    printf '%s\n' "${source_ids_line}"
    printf '%s\n' "---"
    printf '%s\n' "# Test Page"
    printf '%s\n' ""
    printf '%s\n' "Content here."
  } > "${abs_path}"
}

# ---------------------------------------------------------------------------
# Helper: write manifest.json with a known entry.
# The manifest keys are source slugs relative to the brain (e.g. "ai/valid-source").
# ---------------------------------------------------------------------------
_write_manifest_with_entry() {
  printf '{"sources":{"ai/valid-source":{"title":"Valid Source","ingested_at":"2026-01-01T00:00:00Z"},"tech/another-source":{"title":"Another Source","ingested_at":"2026-01-01T00:00:00Z"}},"last_updated":"2026-01-01T00:00:00Z"}' \
    > "${BRAIN_DIR}/.brain/manifest.json"
}

# ===========================================================================
# AC-001 / BC-2.04.009 precondition 1 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_009_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_009_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_009_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_009_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-002 / BC-2.04.009 postconditions §all-resolved:
# All source_ids resolve to manifest entries → exit 0.
# BC postcondition: stdout contains "verdict":"allow" (or continue:true per ADR-002 v2.0).
# ===========================================================================

@test "test_BC_2_04_009_resolved_source_ids_exits_0" {
  # wiki page with source_ids: [ai/valid-source]; manifest has that entry → exit 0.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/valid-source"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-003 / BC-2.04.009 postconditions §unresolved:
# An unresolved source_id slug → exit 2 + E-WIKI-007 in stdout.
# BC postcondition: "code":"E-WIKI-007", unresolved slug in message.
# ===========================================================================

@test "test_BC_2_04_009_unresolved_source_id_exits_2_with_E_WIKI_007" {
  # manifest exists but does NOT have ai/nonexistent → exit 2 + E-WIKI-007.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/nonexistent"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-007"* ]]
}

@test "test_BC_2_04_009_unresolved_source_id_stdout_contains_missing_slug" {
  # BC-2.04.009 postcondition: message must contain the unresolved slug.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/nonexistent"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"ai/nonexistent"* ]]
}

@test "test_BC_2_04_009_unresolved_source_id_stdout_is_block_verdict" {
  # BC-2.04.009 postcondition: "verdict":"block" on unresolved (BC schema, not ADR-002 v2.0).
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/nonexistent"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  # BC postcondition specifies "verdict":"block" — check the code field at minimum.
  local code
  code="$(printf '%s' "$output" | jq -r '.code // .hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-WIKI-007" ]
}

# ===========================================================================
# AC-004 / BC-2.04.009 edge case EC-002:
# Multiple source_ids with one unresolved → all unresolved IDs listed in output.
# ===========================================================================

@test "test_BC_2_04_009_multiple_unresolved_lists_all" {
  # source_ids has ai/valid-source (resolved) and ai/missing1 + ai/missing2 (not in manifest).
  # Both missing slugs must appear in E-WIKI-007 output.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" \
    "ai/valid-source" "ai/missing1" "ai/missing2"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-007"* ]]
  [[ "$output" == *"ai/missing1"* ]]
  [[ "$output" == *"ai/missing2"* ]]
}

# ===========================================================================
# AC-005 / BC-2.04.009 invariant 1 + edge case EC-001:
# Empty source_ids: [] → exit 0 (vacuously satisfied).
# ===========================================================================

@test "test_BC_2_04_009_empty_source_ids_exits_0" {
  # source_ids is an empty list; no manifest lookup needed → exit 0.
  _write_manifest_with_entry
  # Pass no slugs — helper writes source_ids: []
  _write_wiki_page "wiki/concepts/test-page.md"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-006 / BC-2.04.009 invariant 2:
# Fail-closed: manifest.json absent → exit 2 + E-WIKI-008.
# ===========================================================================

@test "test_BC_2_04_009_missing_manifest_exits_2_with_E_WIKI_008" {
  # .brain/manifest.json does NOT exist → fail-closed, exit 2 + E-WIKI-008.
  _write_wiki_page "wiki/concepts/test-page.md" "ai/some-source"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-008"* ]]
}

@test "test_BC_2_04_009_missing_manifest_E_WIKI_008_code_in_structured_field" {
  # HIGH: verify E-WIKI-008 is at the structured code field, not just a bare substring.
  _write_wiki_page "wiki/concepts/test-page.md" "ai/some-source"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.code // .hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-WIKI-008" ]
}

# ===========================================================================
# AC-007 / BC-2.04.009 postconditions §event emission:
# Unresolved → stderr contains source.citation.unresolved + hook_name + missing_source_id.
# All-resolved → stderr contains source.citation.resolved.
# ===========================================================================

@test "test_BC_2_04_009_unresolved_emits_unresolved_event" {
  # BC-2.04.009 postcondition: stderr JSONL contains "source.citation.unresolved".
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/nonexistent"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"source.citation.unresolved"* ]]
}

@test "test_BC_2_04_009_resolved_emits_resolved_event" {
  # BC-2.04.009 postcondition: stderr JSONL contains "source.citation.resolved" on success.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/valid-source"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"source.citation.resolved"* ]]
}

@test "test_BC_2_04_009_unresolved_event_has_correct_hook_name_field" {
  # BC-2.04.009 postcondition: stderr event carries hook_name="validate-source-id-citation.sh".
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/nonexistent"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-source-id-citation.sh"* ]]
}

@test "test_BC_2_04_009_unresolved_event_has_correct_fields" {
  # Parse the stderr JSONL line for source.citation.unresolved and verify
  # missing_source_id field carries the unresolved slug as a proper JSON value.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/nonexistent"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true

  # Extract missing_source_id from the JSONL event line.
  local missing_id
  missing_id="$(printf '%s\n' "$stderr_out" | grep 'source.citation.unresolved' | jq -r '.missing_source_id' 2>/dev/null || true)"
  [ "$missing_id" = "ai/nonexistent" ]
}

@test "test_BC_2_04_009_resolved_event_has_correct_hook_name_field" {
  # Verify hook_name field on the resolved event.
  _write_manifest_with_entry
  _write_wiki_page "wiki/concepts/test-page.md" "ai/valid-source"
  local file_path="${BRAIN_DIR}/wiki/concepts/test-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"

  local hook_name
  hook_name="$(printf '%s\n' "$stderr_out" | grep 'source.citation.resolved' | jq -r '.hook_name' 2>/dev/null || true)"
  [ "$hook_name" = "validate-source-id-citation.sh" ]
}

# ===========================================================================
# AC-015 / CLAUDE.md §Conventions §shellcheck:
# Hook must pass shellcheck.
# ===========================================================================

@test "test_BC_2_04_009_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Edge cases: malformed stdin + empty stdin → fail-closed (exit 2).
# BC-2.04.009 invariant 2 applies to any unreadable input.
# ===========================================================================

@test "test_BC_2_04_009_malformed_json_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_009_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}
