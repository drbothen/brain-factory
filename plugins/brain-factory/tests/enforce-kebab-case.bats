#!/usr/bin/env bats
# STORY-012 Red Gate tests: enforce-kebab-case.sh PreToolUse hook
# Traces to: BC-2.04.011
# VP coverage: VP-017 (hook naming and attribution enforcement)
#
# RED GATE — all behavioral tests MUST FAIL until the hook is implemented.
# Structural tests (shebang, set -euo) may pass against the stub.
#
# NOTE: This is a PreToolUse hook. The stdin payload has "hook_event_name":"PreToolUse"
# and does NOT include "tool_result". The hook fires BEFORE the write operation.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/enforce-kebab-case.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PreToolUse payload for a Write call.
# Arguments:
#   $1 — file_path embedded in the payload (relative or absolute)
#   $2 — tool_name (Write or Edit) [default: Write]
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local tool_name="${2:-Write}"
  printf '{"session_id":"test","transcript_path":"/tmp/t","cwd":"/tmp","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"test"},"tool_use_id":"test-123"}' \
    "$tool_name" "$file_path"
}

# ===========================================================================
# AC-001 / BC-2.04.011 precondition 1 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_011_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_011_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_011_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_011_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-002 / BC-2.04.011 postconditions §kebab-case filename:
# Valid kebab-case filename → exit 0.
# ===========================================================================

@test "test_BC_2_04_011_kebab_case_filename_exits_0" {
  # wiki/concepts/ai-agents.md — all lowercase, hyphens only. Must exit 0.
  local payload
  payload="$(_payload "wiki/concepts/ai-agents.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-003 / BC-2.04.011 postconditions §non-kebab-case: spaces + uppercase:
# Filename with spaces and uppercase → exit 2 + E-NAMING-001 + suggestion.
# ===========================================================================

@test "test_BC_2_04_011_space_uppercase_filename_exits_2_with_E_NAMING_001" {
  # wiki/concepts/AI Agents.md — uppercase + space. Must block.
  local payload
  payload="$(_payload "wiki/concepts/AI Agents.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-NAMING-001"* ]]
}

@test "test_BC_2_04_011_space_uppercase_filename_stdout_contains_suggestion" {
  # Suggestion must convert AI Agents.md → ai-agents.md per AC-007.
  local payload
  payload="$(_payload "wiki/concepts/AI Agents.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"ai-agents.md"* ]]
}

# ===========================================================================
# AC-004 / BC-2.04.011 postconditions §non-kebab-case: underscore:
# Filename with underscore → exit 2 + E-NAMING-001 + suggestion.
# ===========================================================================

@test "test_BC_2_04_011_underscore_filename_exits_2_with_E_NAMING_001" {
  # wiki/concepts/ai_agents.md — underscore. Must block.
  local payload
  payload="$(_payload "wiki/concepts/ai_agents.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-NAMING-001"* ]]
}

@test "test_BC_2_04_011_underscore_filename_stdout_contains_suggestion" {
  # Suggestion must convert ai_agents.md → ai-agents.md.
  local payload
  payload="$(_payload "wiki/concepts/ai_agents.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"ai-agents.md"* ]]
}

# ===========================================================================
# AC-005 / BC-2.04.011 invariant 3 §exception list: CLAUDE.md
# Writing CLAUDE.md must be exempt from the kebab-case check.
# ===========================================================================

@test "test_BC_2_04_011_claude_md_exempt_exits_0" {
  local payload
  payload="$(_payload "CLAUDE.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-006 / BC-2.04.011 invariant 3 §exception list: full list.
# All 7 uppercase-convention files must be exempt from the kebab-case check.
# ===========================================================================

@test "test_BC_2_04_011_readme_exempt_exits_0" {
  local payload
  payload="$(_payload "README.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_011_changelog_exempt_exits_0" {
  local payload
  payload="$(_payload "CHANGELOG.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_011_license_exempt_exits_0" {
  local payload
  payload="$(_payload "LICENSE")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_011_manifest_md_exempt_exits_0" {
  local payload
  payload="$(_payload "MANIFEST.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_011_brain_state_exempt_exits_0" {
  # .brain/STATE.md is an explicit exception — uppercase STATE.md is the canonical name.
  local payload
  payload="$(_payload ".brain/STATE.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_011_brain_manifest_exempt_exits_0" {
  # .brain/manifest.json is all-lowercase and valid kebab-case, but also on the exception
  # list as a known special file.
  local payload
  payload="$(_payload ".brain/manifest.json")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-007 / BC-2.04.011 postconditions §non-kebab: suggestion derivation.
# Suggestion lowercases + replaces spaces with hyphens + replaces underscores.
# ===========================================================================

@test "test_BC_2_04_011_suggestion_lowercases_and_hyphenates" {
  # "My Cool Page.md" → suggested: "my-cool-page.md"
  local payload
  payload="$(_payload "wiki/concepts/My Cool Page.md")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"my-cool-page.md"* ]]
}

# ===========================================================================
# AC-008 / BC-2.04.011 postconditions §event emission:
# Rejected filename → stderr JSONL contains naming.kebab_case.rejected.
# Accepted filename → stderr JSONL contains naming.kebab_case.accepted.
# ===========================================================================

@test "test_BC_2_04_011_rejected_emits_rejected_event" {
  local payload stderr_out
  payload="$(_payload "wiki/concepts/AI Agents.md")"
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"naming.kebab_case.rejected"* ]]
}

@test "test_BC_2_04_011_accepted_emits_accepted_event" {
  local payload stderr_out
  payload="$(_payload "wiki/concepts/ai-agents.md")"
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"naming.kebab_case.accepted"* ]]
}

@test "test_BC_2_04_011_rejected_event_has_correct_filename_field" {
  # The rejected JSONL event must carry "filename" as a proper JSON field
  # containing the basename of the rejected file.
  # BC-2.04.011 postconditions §non-kebab: 4 specifies field name "filename".
  local payload stderr_out filename_field
  payload="$(_payload "wiki/concepts/AI Agents.md")"
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  filename_field="$(printf '%s\n' "$stderr_out" | grep 'naming.kebab_case.rejected' | jq -r '.filename' 2>/dev/null || true)"
  [ "$filename_field" = "AI Agents.md" ]
}

@test "test_BC_2_04_011_rejected_event_has_correct_suggested_field" {
  # The rejected JSONL event must carry "suggested" as a proper JSON field
  # per BC-2.04.011 postconditions §non-kebab: 4.
  local payload stderr_out suggested_field
  payload="$(_payload "wiki/concepts/AI Agents.md")"
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  suggested_field="$(printf '%s\n' "$stderr_out" | grep 'naming.kebab_case.rejected' | jq -r '.suggested' 2>/dev/null || true)"
  [ "$suggested_field" = "ai-agents.md" ]
}

@test "test_BC_2_04_011_accepted_event_has_correct_filename_field" {
  # The accepted JSONL event must carry "filename" as a proper JSON field
  # per BC-2.04.011 postconditions §kebab: 2.
  local payload stderr_out filename_field
  payload="$(_payload "wiki/concepts/ai-agents.md")"
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  filename_field="$(printf '%s\n' "$stderr_out" | grep 'naming.kebab_case.accepted' | jq -r '.filename' 2>/dev/null || true)"
  [ "$filename_field" = "ai-agents.md" ]
}

# ===========================================================================
# AC-002 variant / BC-2.04.011 postconditions §kebab-case filename with Edit tool:
# Valid kebab-case filename via Edit tool → exit 0.
# ===========================================================================

@test "test_BC_2_04_011_edit_tool_kebab_case_exits_0" {
  # Edit tool with a valid kebab-case file — the hook applies equally to Write and Edit.
  local payload
  payload="$(_payload "wiki/concepts/ai-agents.md" "Edit")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-016 / CLAUDE.md §Conventions §shellcheck:
# Hook must pass shellcheck. shfmt check left to meta-lint.bats.
# ===========================================================================

@test "test_BC_2_04_011_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Edge cases:
# Malformed JSON stdin → fail-closed (exit 2).
# Empty stdin → fail-closed (exit 2).
# ===========================================================================

@test "test_BC_2_04_011_malformed_json_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_011_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}
