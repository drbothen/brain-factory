#!/usr/bin/env bats
# STORY-010 Red Gate tests: validate-page-type-policy.sh PostToolUse hook
# Traces to: BC-2.04.007
# VP coverage: page-type invariant (only 6 canonical wiki subdirectories are valid)
#
# RED GATE — all behavioral tests MUST FAIL until the hook is implemented.
# Structural tests (shebang, set -euo) may pass against the stub.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-page-type-policy.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory for the hook to operate against.
  BRAIN_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PostToolUse payload for a Write call.
# Arguments:
#   $1 — file_path embedded in the payload (relative or absolute)
#   $2 — tool_name (Write or Edit) [default: Write]
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local tool_name="${2:-Write}"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"---\\ntitle: Test\\n---\\n# Test"},"tool_use_id":"test-456","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${file_path}"
}

# ===========================================================================
# AC-001 / BC-2.04.007 precondition 2 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_007_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_007_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_007_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-002 / BC-2.04.007 postconditions §valid type directories:
# Paths under the 6 canonical wiki subdirectories → exit 0.
# Parameterized per directory type.
# ===========================================================================

@test "test_BC_2_04_007_valid_type_concepts_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/concepts/test-page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_valid_type_people_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/people/test-page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_valid_type_frameworks_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/frameworks/test-page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_valid_type_syntheses_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/syntheses/test-page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_valid_type_observations_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/observations/test-page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_valid_type_questions_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/questions/test-page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-003 / BC-2.04.007 postconditions §invalid type directory:
# Path under an unrecognized wiki subdirectory → exit 2 + E-WIKI-005.
# ===========================================================================

@test "test_BC_2_04_007_invalid_type_tools_exits_2_with_E_WIKI_005" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-005"* ]]
}

@test "test_BC_2_04_007_invalid_type_tools_stdout_contains_decision_block" {
  # ADR-002 v2.0: block → {"continue":false,"decision":"block",...}
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *'"decision":"block"'* ]]
}

@test "test_BC_2_04_007_error_code_in_hookSpecificOutput_for_invalid_type" {
  # HIGH: verify E-WIKI-005 is at hookSpecificOutput.code, not just anywhere in output.
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-WIKI-005" ]
}

# ===========================================================================
# AC-004 / BC-2.04.007 postconditions §direct wiki root write:
# Path directly under wiki/ (depth 1, not under a subdirectory) → exit 2 + E-WIKI-006.
# ===========================================================================

@test "test_BC_2_04_007_wiki_root_write_exits_2_with_E_WIKI_006" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/stray.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-WIKI-006"* ]]
}

@test "test_BC_2_04_007_wiki_root_write_stdout_contains_decision_block" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/stray.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *'"decision":"block"'* ]]
}

@test "test_BC_2_04_007_error_code_in_hookSpecificOutput_for_root_write" {
  # HIGH: verify E-WIKI-006 is at hookSpecificOutput.code, not just anywhere in output.
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/stray.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-WIKI-006" ]
}

# ===========================================================================
# AC-005 / BC-2.04.007 postconditions §exempt paths:
# wiki/index.md and wiki/log.md are exempt from page-type policy → exit 0.
# ===========================================================================

@test "test_BC_2_04_007_wiki_index_exempt_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/index.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_wiki_log_exempt_exits_0" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/log.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# BC-2.04.007 invariant §non-wiki paths:
# Paths outside wiki/ are not in scope for this hook → exit 0, no-op.
# ===========================================================================

@test "test_BC_2_04_007_non_wiki_path_sources_exits_0_noop" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/sources/ai/some-article.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_007_non_wiki_path_briefs_exits_0_noop" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/briefs/content/my-brief.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-006 / BC-2.04.007 postconditions §event emission:
# Blocked path → stderr JSONL contains wiki.page_type.rejected.
# Accepted path → stderr JSONL contains wiki.page_type.accepted.
# ===========================================================================

@test "test_BC_2_04_007_blocked_emits_rejected_event_to_stderr" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"wiki.page_type.rejected"* ]]
}

@test "test_BC_2_04_007_accepted_emits_accepted_event_to_stderr" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/concepts/test.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"wiki.page_type.accepted"* ]]
}

@test "test_BC_2_04_007_rejected_event_stderr_contains_hook_name" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-page-type-policy.sh"* ]]
}

@test "test_BC_2_04_007_accepted_event_stderr_contains_hook_name" {
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/concepts/test.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"validate-page-type-policy.sh"* ]]
}

# ===========================================================================
# AC-006 addendum / adversary HIGH-003: event field correctness.
# Verify JSONL fields in stderr events are properly keyed — not just present
# as substrings. Parses the JSONL line with jq to check individual fields.
# ===========================================================================

@test "test_BC_2_04_007_rejected_event_has_correct_invalid_type_field" {
  # For wiki/tools/hammer.md, the rejected event must carry invalid_type="tools"
  # as a proper JSON field (not a bare substring).
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true

  # Parse the JSONL line that contains wiki.page_type.rejected and extract the invalid_type field.
  local invalid_type
  invalid_type="$(printf '%s\n' "$stderr_out" | grep 'wiki.page_type.rejected' | jq -r '.invalid_type' 2>/dev/null || true)"
  [ "$invalid_type" = "tools" ]
}

@test "test_BC_2_04_007_rejected_event_has_correct_path_field" {
  # For wiki/tools/hammer.md, the rejected event must carry the file path
  # as a proper JSON path field, not just a bare substring.
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/tools/hammer.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true

  local event_path
  event_path="$(printf '%s\n' "$stderr_out" | grep 'wiki.page_type.rejected' | jq -r '.path' 2>/dev/null || true)"
  [[ "$event_path" == *"wiki/tools/hammer.md"* ]]
}

@test "test_BC_2_04_007_accepted_event_has_correct_path_field" {
  # For wiki/concepts/test-page.md, the accepted event must carry the file path
  # as a proper JSON path field.
  local payload
  payload="$(_payload "${BRAIN_DIR}/wiki/concepts/test-page.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"

  local event_path
  event_path="$(printf '%s\n' "$stderr_out" | grep 'wiki.page_type.accepted' | jq -r '.path' 2>/dev/null || true)"
  [[ "$event_path" == *"wiki/concepts/test-page.md"* ]]
}

# ===========================================================================
# Edge cases:
# Malformed JSON stdin → fail-closed (exit 2).
# Empty stdin → fail-closed (exit 2).
# ===========================================================================

@test "test_BC_2_04_007_malformed_json_stdin_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_007_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

# ===========================================================================
# AC-014 / CLAUDE.md §Conventions §shellcheck:
# Hook must pass shellcheck. shfmt check left to meta-lint.bats.
# ===========================================================================

@test "test_BC_2_04_007_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}
