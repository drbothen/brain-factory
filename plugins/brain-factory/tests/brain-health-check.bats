#!/usr/bin/env bats
# STORY-013 tests: brain-health-check.sh SessionStart lifecycle hook
# Traces to: BC-2.04.014
#
# This hook fires on the SessionStart event (NOT PostToolUse/PreToolUse).
# stdin JSON has minimal schema: {session_id, transcript_path, cwd, hook_event_name}
# No tool_name, no tool_input, no tool_result.
#
# Exit codes: 0 ONLY — NEVER 1 or 2. ADR-002 v2.0: advisory visibility requires
# exit 0 + systemMessage in stdout. exit 1 goes to debug log only (invisible).
# Blocking session open is architecturally forbidden per BC-2.04.014 invariant 1.
#
# Event catalog:
#   brain.health.checked  → fields: overall_state
#   brain.health.skipped  → fields: reason

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/brain-health-check.sh"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp directory — may or may not have .brain/STATE.md depending on test.
  BRAIN_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# ---------------------------------------------------------------------------
# Payload helper — builds the minimal SessionStart lifecycle event JSON.
# $1 — cwd path to embed in payload
# ---------------------------------------------------------------------------
_session_start_payload() {
  printf '{"session_id":"test","transcript_path":"/tmp/t","cwd":"%s","hook_event_name":"SessionStart"}' "$1"
}

# ---------------------------------------------------------------------------
# Fixture helpers — create .brain/STATE.md with given overall_health value.
# ---------------------------------------------------------------------------
_create_green_state_md() {
  local dir="$1"
  mkdir -p "${dir}/.brain"
  cat >"${dir}/.brain/STATE.md" <<'EOF'
---
overall_health: GREEN
dimensions:
  capture: GREEN
  sources: GREEN
  wiki: GREEN
  synthesis: GREEN
  output: GREEN
  reflection: GREEN
---
# Brain State
All dimensions healthy.
EOF
}

_create_red_state_md() {
  local dir="$1"
  mkdir -p "${dir}/.brain"
  cat >"${dir}/.brain/STATE.md" <<'EOF'
---
overall_health: RED
dimensions:
  capture: GREEN
  sources: GREEN
  wiki: RED
  synthesis: GREEN
  output: YELLOW
  reflection: GREEN
red_dimensions:
  - wiki: "3 broken wikilinks"
  - output: "No content briefs generated"
---
# Brain State
Issues found.
EOF
}

_create_malformed_state_md() {
  local dir="$1"
  mkdir -p "${dir}/.brain"
  # Malformed YAML — unterminated flow sequence that yq cannot parse.
  printf '%s\n' '---' 'overall_health: [unterminated' '---' '# Bad STATE' >"${dir}/.brain/STATE.md"
}

# ===========================================================================
# AC-009 / BC-2.04.014 invariants 1-2: Structural contract.
# These tests inspect the script's static properties.
# Structural tests that check the stub itself PASS before implementation.
# ===========================================================================

@test "test_BC_2_04_014_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_014_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_014_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_014_hook_never_exits_2" {
  # BC-2.04.014 invariant 1: this hook NEVER exits 2.
  # Blocking session open (SessionStart event) is architecturally forbidden.
  run grep -n 'exit 2' "${HOOK}"
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_014_hook_never_exits_1" {
  # ADR-002 v2.0: exit 1 stderr goes to debug log only — invisible to operators.
  # Advisory messages MUST be delivered via stdout systemMessage + exit 0.
  run grep -n 'exit 1' "${HOOK}"
  [ "$status" -ne 0 ]
}

# ===========================================================================
# AC-010 / BC-2.04.014 postconditions on non-brain directory:
# No .brain/STATE.md → exit 0; stderr contains brain.health.skipped.
# FAILS against the stub (stub emits no stderr event).
# ===========================================================================

@test "test_BC_2_04_014_non_brain_dir_exits_0_with_skipped_event" {
  # BRAIN_DIR has no .brain/STATE.md — not a brain session.
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}' 2>&1"
  [ "$status" -eq 0 ]
  # Stub produces no events — implementation must emit brain.health.skipped to stderr.
  [[ "$output" == *"brain.health.skipped"* ]]
}

@test "test_BC_2_04_014_non_brain_dir_stderr_contains_skipped_event" {
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"brain.health.skipped"* ]]
}

# ===========================================================================
# AC-011 / BC-2.04.014 postconditions on GREEN state:
# GREEN STATE.md → exit 0; stdout contains "GREEN".
# FAILS against the stub (stub emits empty stdout).
# ===========================================================================

@test "test_BC_2_04_014_green_state_exits_0" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  # Stub produces no meaningful output — implementation must include "GREEN" in stdout.
  [[ "$output" == *"GREEN"* ]]
}

@test "test_BC_2_04_014_green_state_stdout_contains_GREEN" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"GREEN"* ]]
}

# ===========================================================================
# BC-2.04.014 v1.6 schema structural assertions — GREEN path.
# Locks the exact hookSpecificOutput shape introduced in implementer commit
# 34b8c17: systemMessage (not message), additionalContext (not code),
# hookEventName present, no unhealthy_state/red_dimensions on GREEN.
# Note: stdout is captured directly (not via 'run') to exclude stderr JSONL events.
# ===========================================================================

@test "test_BC_2_04_014_green_stdout_has_continue_true" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)"
  [ "$(printf '%s' "$stdout_json" | jq -r '.continue')" = "true" ]
}

@test "test_BC_2_04_014_green_stdout_has_systemMessage_not_message" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload stdout_json sm has_message
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)"
  # systemMessage field must be present and non-empty
  sm="$(printf '%s' "$stdout_json" | jq -r '.systemMessage // empty')"
  [ -n "$sm" ]
  # Legacy 'message' top-level field must be absent (BC v1.6 renamed it)
  has_message="$(printf '%s' "$stdout_json" | jq 'has("message")')"
  [ "$has_message" = "false" ]
}

@test "test_BC_2_04_014_green_stdout_hookEventName_is_SessionStart" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)"
  [ "$(printf '%s' "$stdout_json" | jq -r '.hookSpecificOutput.hookEventName')" = "SessionStart" ]
}

@test "test_BC_2_04_014_green_stdout_additionalContext_contains_GREEN" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload stdout_json ac
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)"
  ac="$(printf '%s' "$stdout_json" | jq -r '.hookSpecificOutput.additionalContext')"
  [[ "$ac" == *"GREEN"* ]]
}

# ===========================================================================
# AC-012 / BC-2.04.014 postconditions on RED state:
# RED STATE.md → exit 0; stdout contains E-HEALTH-002 in systemMessage.
# ADR-002 v2.0: advisory visibility requires exit 0 + systemMessage.
# ===========================================================================

@test "test_BC_2_04_014_red_state_exits_0_with_E_HEALTH_002" {
  _create_red_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"E-HEALTH-002"* ]]
}

@test "test_BC_2_04_014_red_state_exit_is_0_not_1_or_2" {
  # RED must exit 0 (advisory via systemMessage), never 1 or 2.
  # exit 1 = debug log only (invisible); exit 2 = block (forbidden for SessionStart).
  _create_red_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-013-red-dimensions / BC-2.04.014 event contract:
# RED state event must include a non-empty red_dimensions field in the JSONL
# event emitted to stderr. The BC specifies the event carries dimension details.
# ===========================================================================

@test "test_BC_2_04_014_red_event_has_red_dimensions_field" {
  _create_red_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  # The JSONL line for brain.health.checked must contain red_dimensions.
  [[ "$stderr_out" == *"red_dimensions"* ]]
  # And the value must be non-empty (wiki and output are failing in the fixture).
  [[ "$stderr_out" != *'"red_dimensions":""'* ]]
}

# ===========================================================================
# BC-2.04.014 v1.6 schema structural assertions — RED/YELLOW path.
# Locks hookSpecificOutput.additionalContext="E-HEALTH-002", unhealthy_state=true,
# and red_dimensions as a non-empty JSON array (not absent, not a string).
# Note: stdout is captured directly (not via 'run') to exclude stderr JSONL events.
# ===========================================================================

@test "test_BC_2_04_014_red_stdout_has_continue_true" {
  _create_red_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)" || true
  [ "$(printf '%s' "$stdout_json" | jq -r '.continue')" = "true" ]
}

@test "test_BC_2_04_014_red_stdout_additionalContext_is_E_HEALTH_002" {
  _create_red_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)" || true
  [ "$(printf '%s' "$stdout_json" | jq -r '.hookSpecificOutput.additionalContext')" = "E-HEALTH-002" ]
}

@test "test_BC_2_04_014_red_stdout_unhealthy_state_is_true" {
  _create_red_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)" || true
  [ "$(printf '%s' "$stdout_json" | jq -r '.hookSpecificOutput.unhealthy_state')" = "true" ]
}

@test "test_BC_2_04_014_red_stdout_red_dimensions_is_nonempty_array" {
  # red_dimensions must be a JSON array with at least one entry.
  # The fixture has wiki=RED and output=YELLOW.
  _create_red_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)" || true
  [ "$(printf '%s' "$stdout_json" | jq '.hookSpecificOutput.red_dimensions | type')" = '"array"' ]
  [ "$(printf '%s' "$stdout_json" | jq '.hookSpecificOutput.red_dimensions | length')" -gt 0 ]
}

# ===========================================================================
# AC-014 / BC-2.04.014 edge case EC-002:
# Malformed STATE.md → exit 0; stdout contains "unreadable" in systemMessage.
# ADR-002 v2.0: advisory visibility requires exit 0 + systemMessage.
# ===========================================================================

@test "test_BC_2_04_014_malformed_state_exits_0_advisory" {
  _create_malformed_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"unreadable"* ]]
}

@test "test_BC_2_04_014_malformed_state_exit_is_0_not_1_or_2" {
  # Malformed STATE.md must exit 0 (advisory via systemMessage), never 1 or 2.
  # exit 1 = debug log only (invisible); exit 2 = block (forbidden for SessionStart).
  _create_malformed_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# BC-2.04.014 v1.6 schema structural assertions — UNREADABLE (EC-002) path.
# Locks hookSpecificOutput.additionalContext="E-HEALTH-003" and
# unhealthy_state=true for the malformed-STATE.md code path.
# Note: stdout is captured directly (not via 'run') to exclude stderr JSONL events.
# ===========================================================================

@test "test_BC_2_04_014_unreadable_stdout_additionalContext_is_E_HEALTH_003" {
  _create_malformed_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)" || true
  [ "$(printf '%s' "$stdout_json" | jq -r '.hookSpecificOutput.additionalContext')" = "E-HEALTH-003" ]
}

@test "test_BC_2_04_014_unreadable_stdout_unhealthy_state_is_true" {
  _create_malformed_state_md "${BRAIN_DIR}"
  local payload stdout_json
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  stdout_json="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>/dev/null)" || true
  [ "$(printf '%s' "$stdout_json" | jq -r '.hookSpecificOutput.unhealthy_state')" = "true" ]
}

# ===========================================================================
# AC-015 / BC-2.04.017 universal emission requirement:
# Every exit path emits at least one JSONL event to stderr.
# FAILS against the stub (stub emits no stderr).
# ===========================================================================

@test "test_BC_2_04_014_green_emits_checked_event" {
  _create_green_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"brain.health.checked"* ]]
}

@test "test_BC_2_04_014_red_emits_checked_event" {
  _create_red_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"brain.health.checked"* ]]
}

@test "test_BC_2_04_014_skipped_emits_skipped_event" {
  # Non-brain dir — no .brain/STATE.md.
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"brain.health.skipped"* ]]
}

@test "test_BC_2_04_014_malformed_state_emits_checked_event_with_unreadable_state" {
  # Malformed STATE.md — hook must still emit brain.health.checked to stderr
  # with overall_state:UNREADABLE per BC-2.04.014 §AC-015 and BC-2.04.017.
  _create_malformed_state_md "${BRAIN_DIR}"
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"brain.health"* ]]
}

# ===========================================================================
# BC-2.04.014 event contract: brain.health.skipped must include path field.
# The path field must be present and non-empty in the JSONL event emitted
# to stderr when the session is not a brain session.
# FAILS against the current implementation (skipped event has no path field).
# ===========================================================================

@test "test_BC_2_04_014_skipped_event_has_path_field" {
  # Non-brain dir — no .brain/STATE.md.
  local payload
  payload="$(_session_start_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  # The JSONL line for brain.health.skipped must contain a non-empty "path" field.
  [[ "$stderr_out" == *'"path"'* ]]
  # The path value must not be empty (\"path\":\"\" would fail production-grade test).
  [[ "$stderr_out" != *'"path":""'* ]]
}

# ===========================================================================
# AC-016 / CLAUDE.md §Conventions: shellcheck and shfmt normalization.
# These PASS against the stub (stub is shellcheck-clean and shfmt-normalized).
# ===========================================================================

@test "test_BC_2_04_014_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_014_shfmt_normalized" {
  run shfmt -d -i 2 "${HOOK}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# hooks.json registration: SessionStart entry must reference brain-health-check.sh.
# Structural check — PASSES against the existing hooks.json.
# ===========================================================================

@test "test_BC_2_04_014_hooks_json_SessionStart_entry_includes_brain_health_check" {
  run python3 -c "
import json, sys
with open('${PLUGIN_DIR}/hooks/hooks.json') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
session_start = hooks.get('SessionStart', [])
found = False
for entry in session_start:
    for h in entry.get('hooks', []):
        cmd = h.get('command', '')
        if 'brain-health-check.sh' in cmd:
            found = True
            break
if not found:
    print('ERROR: No SessionStart entry pointing to brain-health-check.sh', file=sys.stderr)
    sys.exit(1)
print('PASS')
"
  [ "$status" -eq 0 ]
}
