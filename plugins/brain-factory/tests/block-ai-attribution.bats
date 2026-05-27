#!/usr/bin/env bats
# STORY-012 Red Gate tests: block-ai-attribution.sh PreToolUse hook
# Traces to: BC-2.04.012
# VP coverage: VP-017 (hook naming and attribution enforcement)
#
# RED GATE — all behavioral tests MUST FAIL until the hook is implemented.
# Structural tests (shebang, set -euo) may pass against the stub.
#
# NOTE: This is a PreToolUse hook on Bash tool calls. The stdin payload has
# "hook_event_name":"PreToolUse" and "tool_name":"Bash". The hook fires BEFORE
# the bash command executes. tool_input has "command" (not "file_path").

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PreToolUse payload for a Bash call.
# Arguments:
#   $1 — command string (must be safe for printf interpolation — no single quotes)
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_bash_payload() {
  local command="$1"
  printf '{"session_id":"test","transcript_path":"/tmp/t","cwd":"/tmp","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"%s","description":"test"},"tool_use_id":"test-123"}' \
    "$command"
}

# ---------------------------------------------------------------------------
# Helper: build a PreToolUse Bash payload safely using jq for commands that
# contain characters problematic for printf interpolation (quotes, backslashes,
# emoji, or other special characters).
# Arguments:
#   $1 — command string (any content is safe via jq --arg)
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_bash_payload_safe() {
  local command="$1"
  jq -cn --arg cmd "$command" \
    '{"session_id":"test","transcript_path":"/tmp/t","cwd":"/tmp","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":$cmd,"description":"test"},"tool_use_id":"test-123"}'
}

# ===========================================================================
# AC-009 / BC-2.04.012 precondition 1 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_012_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_012_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_012_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_012_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-010 / BC-2.04.012 postconditions §no attribution tokens:
# Clean bash command → exit 0.
# ===========================================================================

@test "test_BC_2_04_012_clean_commit_exits_0" {
  # git commit -m "feat: add feature" — no attribution tokens. Must exit 0.
  local payload
  payload="$(jq -cn --arg cmd 'git commit -m "feat: add feature"' \
    '{"session_id":"test","transcript_path":"/tmp/t","cwd":"/tmp","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":$cmd,"description":"test"},"tool_use_id":"test-123"}')"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-011 / BC-2.04.012 postconditions §token found: Co-Authored-By.
# Command containing "Co-Authored-By: Claude" → exit 2 + E-ATTR-001.
# ===========================================================================

@test "test_BC_2_04_012_coauthored_by_exits_2_with_E_ATTR_001" {
  # Use _bash_payload_safe because the command contains double quotes.
  local payload
  payload="$(_bash_payload_safe 'git commit -m "feat: add feature\n\nCo-Authored-By: Claude Opus <noreply@anthropic.com>"')"
  run bash -c "printf '%s' \$'${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-ATTR-001"* ]]
}

@test "test_BC_2_04_012_coauthored_by_exits_2_via_fixture" {
  # Drive via the pre-built fixture for maximum test reproducibility.
  run bash -c "cat '${FIXTURES_DIR}/bash-ai-attribution-coauthored.json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-ATTR-001"* ]]
}

# ===========================================================================
# AC-012 / BC-2.04.012 postconditions §token found: robot emoji.
# Command containing 🤖 → exit 2 + E-ATTR-001. No exceptions for comments.
# ===========================================================================

@test "test_BC_2_04_012_robot_emoji_exits_2_with_E_ATTR_001" {
  # Use _bash_payload_safe for safe emoji embedding.
  local payload
  payload="$(_bash_payload_safe 'echo "🤖 done"')"
  run bash -c "printf '%s' \$'${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-ATTR-001"* ]]
}

@test "test_BC_2_04_012_robot_emoji_exits_2_via_fixture" {
  run bash -c "cat '${FIXTURES_DIR}/bash-ai-attribution-emoji.json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-ATTR-001"* ]]
}

# ===========================================================================
# AC-013 / BC-2.04.012 postconditions §token found: "Generated with Claude Code".
# Command containing "Generated with Claude Code" → exit 2 + E-ATTR-001.
# ===========================================================================

@test "test_BC_2_04_012_generated_with_exits_2_with_E_ATTR_001" {
  local payload
  payload="$(_bash_payload_safe 'printf "Generated with Claude Code\n" >> HEADER.txt')"
  run bash -c "printf '%s' \$'${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-ATTR-001"* ]]
}

# ===========================================================================
# AC-015 / BC-2.04.012 postconditions §event emission:
# Blocked command → stderr JSONL contains attribution.token.blocked.
# Clean command → stderr JSONL contains attribution.token.cleared.
# ===========================================================================

@test "test_BC_2_04_012_blocked_emits_blocked_event" {
  # Use the coauthored fixture — guaranteed to block.
  local stderr_out
  stderr_out="$(cat "${FIXTURES_DIR}/bash-ai-attribution-coauthored.json" | \
    CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"attribution.token.blocked"* ]]
}

@test "test_BC_2_04_012_clean_emits_cleared_event" {
  local payload stderr_out
  payload="$(cat "${FIXTURES_DIR}/bash-clean-commit.json")"
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"attribution.token.cleared"* ]]
}

@test "test_BC_2_04_012_blocked_event_has_matched_pattern" {
  # The blocked JSONL event must carry "matched_pattern" as a proper JSON field
  # per BC-2.04.012 postconditions §token found: 3.
  local stderr_out matched_pattern
  stderr_out="$(cat "${FIXTURES_DIR}/bash-ai-attribution-coauthored.json" | \
    CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  matched_pattern="$(printf '%s\n' "$stderr_out" | grep 'attribution.token.blocked' | jq -r '.matched_pattern' 2>/dev/null || true)"
  # The matched_pattern field must be non-empty — it names which forbidden token triggered.
  [ -n "$matched_pattern" ]
}

@test "test_BC_2_04_012_blocked_event_matched_pattern_exact_value_coauthored" {
  # matched_pattern for Co-Authored-By fixture must be exactly "Co-Authored-By: Claude"
  # per event-catalog.json example value and BC-2.04.012.
  local stderr_out matched_pattern
  stderr_out="$(cat "${FIXTURES_DIR}/bash-ai-attribution-coauthored.json" | \
    CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  matched_pattern="$(printf '%s\n' "$stderr_out" | grep 'attribution.token.blocked' | jq -r '.matched_pattern' 2>/dev/null || true)"
  [ "$matched_pattern" = "Co-Authored-By: Claude" ]
}

# ===========================================================================
# AC-016 / CLAUDE.md §Conventions §shellcheck:
# Hook must pass shellcheck. shfmt check left to meta-lint.bats.
# ===========================================================================

@test "test_BC_2_04_012_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Edge cases:
# Malformed JSON stdin → fail-closed (exit 2).
# Empty stdin → fail-closed (exit 2).
# ===========================================================================

@test "test_BC_2_04_012_malformed_json_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_012_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}
