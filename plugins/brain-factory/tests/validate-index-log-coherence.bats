#!/usr/bin/env bats
# STORY-008 tests: validate-index-log-coherence.sh PostToolUse hook
# Traces to: BC-2.04.006
# VP coverage: VP-002 (PostToolUse hook trigger on wiki writes — coherence violation
#              → exit 2, coherent state → exit 0, fail-closed on missing file)

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory — the hook reads wiki/index.md and wiki/log.md
  # relative to BRAIN_DIR env var (established pattern from STORY-007).
  BRAIN_DIR="$(mktemp -d)"
  mkdir -p "${BRAIN_DIR}/wiki"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PostToolUse payload for a Write to wiki/index.md or
# wiki/log.md. The coherence hook reads BOTH files from disk (BRAIN_DIR/wiki/)
# rather than from the payload content — so content field is minimal here.
# Arguments:
#   $1 — absolute file_path embedded in the payload (e.g., BRAIN_DIR/wiki/index.md)
#   $2 — tool_name (Write or Edit) [default: Write]
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local tool_name="${2:-Write}"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"---\\ntype: index\\n---\\n"},"tool_use_id":"test-789","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${file_path}"
}

# ===========================================================================
# AC-008 / BC-2.04.006 precondition 1 + ADR-002 §hook-contract invariants:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_006_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_006_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_006_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_006_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-009 / BC-2.04.006 postconditions §coherent state:
# Matching slugs in index + log → exit 0 + continue:true.
# ADR-002 v2.0 schema: {"continue":true,...}  (NOT retired v1.0 "verdict":"allow")
# ===========================================================================

@test "test_BC_2_04_006_coherent_index_and_log_exits_0" {
  # Both fixtures have the same three slugs: test-concept, test-person, test-framework.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_006_coherent_state_stdout_contains_continue_true" {
  # ADR-002 v2.0: allow → {"continue":true,...}  (not the retired v1.0 verdict:allow)
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-010 / BC-2.04.006 postconditions §coherence violation:
# Slug in index but NOT in log → exit 2, E-WIKI-003.
# ===========================================================================

@test "test_BC_2_04_006_slug_in_index_but_not_in_log_exits_2_with_E_WIKI_003" {
  # Write an index that has an extra slug not present in the log.
  # The fixture log only knows test-concept, test-person, test-framework.
  # We add extra-slug to the index — it will not be in the log.
  {
    cat "${FIXTURES_DIR}/wiki-index-with-slugs.md"
    printf '\n- [Extra Page](concepts/extra-slug.md)\n'
  } > "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-003"* ]]
}

@test "test_BC_2_04_006_coherence_violation_message_names_missing_slug" {
  # BC-2.04.006 postcondition §violation: message must name the missing slug.
  {
    cat "${FIXTURES_DIR}/wiki-index-with-slugs.md"
    printf '\n- [Extra Page](concepts/extra-slug.md)\n'
  } > "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"extra-slug"* ]]
}

@test "test_BC_2_04_006_coherence_violation_stdout_contains_decision_block" {
  # ADR-002 v2.0: block → {"continue":false,"decision":"block",...}
  {
    cat "${FIXTURES_DIR}/wiki-index-with-slugs.md"
    printf '\n- [Extra Page](concepts/extra-slug.md)\n'
  } > "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *'"decision":"block"'* ]]
}

@test "test_BC_2_04_006_E_WIKI_003_code_in_hookSpecificOutput" {
  # ADR-002 v2.0: error code at hookSpecificOutput.code (not just anywhere in output).
  # Suppress stderr so $output only contains stdout JSON (parseable by jq).
  {
    cat "${FIXTURES_DIR}/wiki-index-with-slugs.md"
    printf '\n- [Extra Page](concepts/extra-slug.md)\n'
  } > "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-WIKI-003" ]
}

# ===========================================================================
# AC-011 / BC-2.04.006 invariants 1–2 + EC-002:
# Missing log.md → exit 2, E-WIKI-004 (fail-closed).
# Missing index.md → exit 2, E-WIKI-004 (fail-closed).
# ===========================================================================

@test "test_BC_2_04_006_missing_log_md_exits_2_with_E_WIKI_004" {
  # index.md present but log.md absent — fail-closed.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  # Deliberately do NOT create log.md.
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-004"* ]]
}

@test "test_BC_2_04_006_missing_index_md_exits_2_with_E_WIKI_004" {
  # log.md present but index.md absent — fail-closed.
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  # Deliberately do NOT create index.md.
  local file_path="${BRAIN_DIR}/wiki/log.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-004"* ]]
}

# ===========================================================================
# AC-012 / BC-2.04.006 EC-001:
# Both files empty (brand-new brain) → exit 0 (vacuous coherence).
# ===========================================================================

@test "test_BC_2_04_006_both_files_empty_exits_0_vacuous_coherence" {
  # Empty index and empty log have zero slugs — trivially coherent.
  printf '' > "${BRAIN_DIR}/wiki/index.md"
  printf '' > "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_006_both_files_empty_stdout_contains_continue_true" {
  printf '' > "${BRAIN_DIR}/wiki/index.md"
  printf '' > "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-013 / VP-002 / BC-2.04.006 postconditions §event emission:
# Coherence violation → stderr JSONL contains wiki.index_log.coherence_violated.
# Coherent state → stderr JSONL contains wiki.index_log.coherence_verified.
# ===========================================================================

@test "VP_002_coherence_violation_emits_wiki_index_log_coherence_violated_event" {
  # BC-2.04.006 postcondition §violation step 3 + BC-2.04.017 event catalog compliance.
  {
    cat "${FIXTURES_DIR}/wiki-index-with-slugs.md"
    printf '\n- [Extra Page](concepts/extra-slug.md)\n'
  } > "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  # Capture stderr separately; swallow exit code (hook exits 2 = non-zero).
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"wiki.index_log.coherence_violated"* ]]
}

@test "VP_002_coherence_violation_stderr_event_contains_hook_name" {
  {
    cat "${FIXTURES_DIR}/wiki-index-with-slugs.md"
    printf '\n- [Extra Page](concepts/extra-slug.md)\n'
  } > "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-index-log-coherence.sh"* ]]
}

@test "VP_002_coherent_state_emits_wiki_index_log_coherence_verified_event" {
  # BC-2.04.006 postcondition §coherent step 2.
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"wiki.index_log.coherence_verified"* ]]
}

@test "VP_002_coherent_state_stderr_event_contains_hook_name" {
  cp "${FIXTURES_DIR}/wiki-index-with-slugs.md" "${BRAIN_DIR}/wiki/index.md"
  cp "${FIXTURES_DIR}/wiki-log-with-slugs.md" "${BRAIN_DIR}/wiki/log.md"
  local file_path="${BRAIN_DIR}/wiki/index.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"validate-index-log-coherence.sh"* ]]
}

# ===========================================================================
# Edge case: malformed (non-JSON) stdin → exit 2, fail-closed.
# ===========================================================================

@test "test_BC_2_04_006_malformed_json_stdin_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_006_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

# ===========================================================================
# CLAUDE.md §Conventions §shellcheck + shfmt:
# Hook must pass shellcheck and shfmt normalization checks.
# ===========================================================================

@test "test_BC_2_04_006_hook_passes_shellcheck" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_006_hook_passes_shfmt_normalization" {
  run shfmt -d -i 2 "${HOOK}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# hooks.json registration: PostToolUse Write|Edit chain must include
# validate-index-log-coherence.sh.
# ===========================================================================

@test "test_BC_2_04_006_hooks_json_PostToolUse_entry_includes_validate_index_log_coherence" {
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
        if 'validate-index-log-coherence.sh' in cmd:
            found = True
            break
if not found:
    print('ERROR: No PostToolUse entry pointing to validate-index-log-coherence.sh', file=sys.stderr)
    sys.exit(1)
print('PASS')
"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_006_hooks_json_coherence_entry_uses_CLAUDE_PLUGIN_ROOT_path" {
  run grep -q 'CLAUDE_PLUGIN_ROOT.*validate-index-log-coherence.sh\|validate-index-log-coherence.sh.*CLAUDE_PLUGIN_ROOT' "${PLUGIN_DIR}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}
