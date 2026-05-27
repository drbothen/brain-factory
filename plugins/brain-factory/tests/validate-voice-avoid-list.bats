#!/usr/bin/env bats
# STORY-010 Red Gate tests: validate-voice-avoid-list.sh PostToolUse hook
# Traces to: BC-2.04.008
# VP coverage: voice quality advisory (forbidden-word detection, always exit 0)
#
# CRITICAL CONTRACT: This hook MUST NEVER exit 1 or 2.
# ALL execution paths exit 0. Advisories are surfaced via stdout systemMessage.
#
# RED GATE — all behavioral tests MUST FAIL until the hook is implemented.
# Structural tests (shebang, set -euo) may pass against the stub.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-voice-avoid-list.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory — the hook reads the written file from disk
  # using the file_path embedded in the payload.
  BRAIN_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: write content to a file in BRAIN_DIR and build a PostToolUse payload.
# Arguments:
#   $1 — relative path within BRAIN_DIR (e.g. briefs/content/test-draft.md)
#   $2 — source fixture file to copy (full path)
#   $3 — tool_name (Write or Edit) [default: Write]
# Side effect: creates the file at BRAIN_DIR/$1.
# Outputs: the JSON payload string to stdout.
# ---------------------------------------------------------------------------
_payload_with_file() {
  local rel_path="$1"
  local fixture_src="$2"
  local tool_name="${3:-Write}"
  local abs_path="${BRAIN_DIR}/${rel_path}"

  mkdir -p "$(dirname "${abs_path}")"
  cp "${fixture_src}" "${abs_path}"

  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":""},"tool_use_id":"test-789","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${abs_path}"
}

# ---------------------------------------------------------------------------
# Helper: write inline content to a file and build a payload.
# Arguments:
#   $1 — relative path within BRAIN_DIR
#   $2 — inline content string
#   $3 — tool_name [default: Write]
# ---------------------------------------------------------------------------
_payload_with_content() {
  local rel_path="$1"
  local content="$2"
  local tool_name="${3:-Write}"
  local abs_path="${BRAIN_DIR}/${rel_path}"

  mkdir -p "$(dirname "${abs_path}")"
  printf '%s' "${content}" > "${abs_path}"

  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":""},"tool_use_id":"test-789","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${abs_path}"
}

# ===========================================================================
# AC-007 / BC-2.04.008 precondition 2 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval.
# CRITICAL: hook MUST NEVER contain exit 1 or exit 2.
# ===========================================================================

@test "test_BC_2_04_008_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_008_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_008_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_008_hook_never_exits_1_or_2" {
  # BC-2.04.008 invariant: this is a pure advisory hook — it MUST NEVER block.
  # Verify at the source level that no exit 1 or exit 2 can occur.
  local exit_1_count exit_2_count
  exit_1_count="$(grep -cE '\bexit\s+[12]\b' "${HOOK}" || true)"
  exit_2_count="$(grep -cE '\bexit\s+2\b' "${HOOK}" || true)"
  [ "${exit_1_count}" -eq 0 ]
  [ "${exit_2_count}" -eq 0 ]
}

# ===========================================================================
# AC-008 / BC-2.04.008 postconditions §no match:
# File with no avoid-list terms → exit 0, stdout contains "continue":true.
# ===========================================================================

@test "test_BC_2_04_008_no_match_exits_0_with_continue_true" {
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft.md" "${FIXTURES_DIR}/briefs-draft-no-matches.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "test_BC_2_04_008_no_match_stdout_does_not_contain_systemMessage" {
  # When no terms match, no advisory message is needed.
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft.md" "${FIXTURES_DIR}/briefs-draft-no-matches.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" != *'"systemMessage"'* ]]
}

# ===========================================================================
# AC-009 / BC-2.04.008 postconditions §match found:
# File with at least one avoid-list term → exit 0 + stdout contains systemMessage
# with E-VOICE-001 advisory code. Hook NEVER exits non-zero.
# ===========================================================================

@test "test_BC_2_04_008_match_exits_0_with_system_message" {
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-matches.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"systemMessage"* ]]
}

@test "test_BC_2_04_008_match_stdout_contains_E_VOICE_001" {
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-matches.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"E-VOICE-001"* ]]
}

@test "test_BC_2_04_008_match_stdout_continue_true" {
  # Even when matches are found, hook MUST emit continue:true — advisory only.
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-matches.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-010 / BC-2.04.008 postconditions §missing avoid-list file:
# When CLAUDE_PLUGIN_ROOT/rules/voice-avoid-list.txt does not exist →
# exit 0 + stdout contains E-VOICE-002.
# ===========================================================================

@test "test_BC_2_04_008_missing_avoid_list_exits_0_with_E_VOICE_002" {
  # Create a temp CLAUDE_PLUGIN_ROOT without a rules/ directory.
  local fake_plugin_root
  fake_plugin_root="$(mktemp -d)"
  # Write a simple file to check against (content doesn't matter — avoid-list is gone).
  local abs_path="${BRAIN_DIR}/briefs/content/test.md"
  mkdir -p "${BRAIN_DIR}/briefs/content"
  printf '%s\n' "# Test" > "${abs_path}"
  local payload
  payload="$(printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"%s","content":""},"tool_use_id":"test-789","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${abs_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${fake_plugin_root}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  rm -rf "${fake_plugin_root}"
  [ "$status" -eq 0 ]
  [[ "$output" == *"E-VOICE-002"* ]]
}

@test "test_BC_2_04_008_missing_avoid_list_stdout_contains_continue_true" {
  # Even when the avoid-list file is missing, hook exits 0 with continue:true.
  local fake_plugin_root
  fake_plugin_root="$(mktemp -d)"
  local abs_path="${BRAIN_DIR}/briefs/content/test.md"
  mkdir -p "${BRAIN_DIR}/briefs/content"
  printf '%s\n' "# Test" > "${abs_path}"
  local payload
  payload="$(printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"%s","content":""},"tool_use_id":"test-789","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${abs_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${fake_plugin_root}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  rm -rf "${fake_plugin_root}"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-012 / BC-2.04.008 postconditions §multiple matches:
# File with 3+ avoid-list terms → hookSpecificOutput.matches array length >= 3.
# ===========================================================================

@test "test_BC_2_04_008_multiple_matches_reports_all_in_array" {
  # briefs-draft-with-matches.md contains: game-changer, leverage, synergy, scalable, empower (5 terms)
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-multi.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 0 ]
  local match_count
  match_count="$(printf '%s' "$output" | jq '.hookSpecificOutput.matches | length' 2>/dev/null || true)"
  [ "${match_count}" -ge 3 ]
}

# ===========================================================================
# AC-013 / BC-2.04.008 postconditions §event emission:
# Match found → stderr JSONL contains voice.avoid_list.matched.
# No match → stderr JSONL contains voice.avoid_list.passed.
# ===========================================================================

@test "test_BC_2_04_008_match_emits_matched_event_to_stderr" {
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-events.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"voice.avoid_list.matched"* ]]
}

@test "test_BC_2_04_008_no_match_emits_passed_event_to_stderr" {
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-clean.md" "${FIXTURES_DIR}/briefs-draft-no-matches.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"voice.avoid_list.passed"* ]]
}

@test "test_BC_2_04_008_match_event_stderr_contains_hook_name" {
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-hookname.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"validate-voice-avoid-list.sh"* ]]
}

# ===========================================================================
# AC-013 addendum / adversary HIGH-003: event field correctness.
# Verify JSONL fields in stderr events are properly keyed — not just present
# as substrings. Parses the JSONL line with jq to check individual fields.
# ===========================================================================

@test "test_BC_2_04_008_matched_event_has_correct_match_count" {
  # briefs-draft-with-matches.md contains 5 avoid-list terms.
  # The matched event must carry match_count as a proper JSON numeric field >= 3.
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-field-check.md" "${FIXTURES_DIR}/briefs-draft-with-matches.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"

  local match_count
  match_count="$(printf '%s\n' "$stderr_out" | grep 'voice.avoid_list.matched' | jq -r '.match_count' 2>/dev/null || true)"
  # match_count must parse as a number and be >= 3
  [ -n "$match_count" ]
  [ "$match_count" -ge 3 ]
}

@test "test_BC_2_04_008_passed_event_has_correct_path_field" {
  # For a brief with no matches, the passed event must carry the file path
  # as a proper JSON path field (not just a bare substring).
  local payload
  payload="$(_payload_with_file "briefs/content/test-draft-clean-fields.md" "${FIXTURES_DIR}/briefs-draft-no-matches.md")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"

  local event_path
  event_path="$(printf '%s\n' "$stderr_out" | grep 'voice.avoid_list.passed' | jq -r '.path' 2>/dev/null || true)"
  # path field must be present and non-empty
  [ -n "$event_path" ]
}

# ===========================================================================
# AC-014 / CLAUDE.md §Conventions §shellcheck:
# Hook must pass shellcheck.
# ===========================================================================

@test "test_BC_2_04_008_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}
