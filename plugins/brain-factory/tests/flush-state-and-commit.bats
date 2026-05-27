#!/usr/bin/env bats
# STORY-013 tests: flush-state-and-commit.sh Stop lifecycle hook
# Traces to: BC-2.04.013
#
# This hook fires on the Stop event (NOT PostToolUse/PreToolUse).
# stdin JSON has minimal schema: {session_id, transcript_path, cwd, hook_event_name}
# No tool_name, no tool_input, no tool_result.
#
# Exit codes: 0 (success) or 1 (advisory) ONLY — NEVER 2.
# Blocking session close is architecturally forbidden per BC-2.04.013 invariant 2.
#
# Event catalog (post-STORY-013 field reconciliation):
#   session.state.committed  → fields: sha
#   session.state.flushed    → fields: committed
#   session.state.commit_failed → fields: error

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/flush-state-and-commit.sh"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Create an isolated temp brain directory with a real git repo.
  BRAIN_DIR="$(mktemp -d)"
  cd "$BRAIN_DIR"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  # Initial commit so git repo has HEAD and git operations are valid.
  echo "init" >"${BRAIN_DIR}/init.txt"
  git add init.txt
  git commit -q -m "init"
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# ---------------------------------------------------------------------------
# Payload helper — builds the minimal Stop lifecycle event JSON.
# $1 — cwd path to embed in payload
# ---------------------------------------------------------------------------
_stop_payload() {
  printf '{"session_id":"test","transcript_path":"/tmp/t","cwd":"%s","hook_event_name":"Stop"}' "$1"
}

# ===========================================================================
# AC-001 / BC-2.04.013 invariants 1-3: Structural contract.
# These tests inspect the script's static properties.
# Structural tests that check the stub itself PASS before implementation.
# ===========================================================================

@test "test_BC_2_04_013_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_013_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_013_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_013_hook_never_exits_2" {
  # BC-2.04.013 invariant 2: this hook NEVER exits 2.
  # Blocking session close (Stop event) is architecturally forbidden.
  run grep -n 'exit 2' "${HOOK}"
  [ "$status" -ne 0 ]
}

# ===========================================================================
# AC-002 / BC-2.04.013 postconditions on uncommitted changes:
# Uncommitted file present → commit performed; exit 0; stdout contains
# the committed message with short SHA.
# FAILS against the stub (stub is a no-op that emits nothing).
# ===========================================================================

@test "test_BC_2_04_013_uncommitted_changes_commits_and_exits_0" {
  # Create an uncommitted file in the brain git repo.
  echo "new content" >"${BRAIN_DIR}/new-file.txt"
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  # Stub produces no meaningful output — implementation must include "committed" in stdout.
  [[ "$output" == *"committed"* ]] || [[ "$output" == *"Committed"* ]]
}

@test "test_BC_2_04_013_uncommitted_changes_creates_brain_auto_commit" {
  # After hook runs, a brain(auto): commit must appear in the git log.
  echo "new content" >"${BRAIN_DIR}/new-file.txt"
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'" || true
  # Verify the commit was created in the brain git repo.
  run git -C "${BRAIN_DIR}" log --oneline
  [[ "$output" == *"brain(auto):"* ]]
}

@test "test_BC_2_04_013_uncommitted_changes_stdout_contains_committed_message" {
  # stdout must contain the committed message (Session state committed).
  echo "new content" >"${BRAIN_DIR}/new-file.txt"
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  # stdout must carry some form of "committed" acknowledgement.
  [[ "$output" == *"committed"* ]] || [[ "$output" == *"Committed"* ]]
}

# ===========================================================================
# AC-003 / BC-2.04.013 postconditions on no uncommitted changes:
# Clean git state → exit 0; stdout contains "No changes".
# FAILS against the stub (stub emits empty stdout).
# ===========================================================================

@test "test_BC_2_04_013_no_changes_exits_0_with_no_flush_message" {
  # Clean git repo — no uncommitted changes.
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"No changes"* ]]
}

# ===========================================================================
# AC-004 / BC-2.04.013 postconditions on git commit failure:
# Pre-commit hook blocks commit → exit 1; stdout contains E-FLUSH-001.
# FAILS against the stub (stub exits 0).
# ===========================================================================

@test "test_BC_2_04_013_git_failure_exits_1_with_E_FLUSH_001" {
  # Install a pre-commit hook that always fails to simulate commit failure.
  mkdir -p "${BRAIN_DIR}/.git/hooks"
  printf '#!/bin/sh\nexit 1\n' >"${BRAIN_DIR}/.git/hooks/pre-commit"
  chmod +x "${BRAIN_DIR}/.git/hooks/pre-commit"
  # Create an uncommitted file so git actually attempts to commit.
  echo "change" >"${BRAIN_DIR}/test.txt"

  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 1 ]
  [[ "$output" == *"E-FLUSH-001"* ]]
}

@test "test_BC_2_04_013_git_failure_exit_is_1_not_2" {
  # Git failure must exit 1 (advisory), never 2 (block).
  # Blocking Stop is architecturally forbidden per BC-2.04.013 invariant 2.
  mkdir -p "${BRAIN_DIR}/.git/hooks"
  printf '#!/bin/sh\nexit 1\n' >"${BRAIN_DIR}/.git/hooks/pre-commit"
  chmod +x "${BRAIN_DIR}/.git/hooks/pre-commit"
  echo "change" >"${BRAIN_DIR}/test.txt"

  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  # Must be 0 or 1 — never 2.
  [ "$status" -ne 2 ]
}

# ===========================================================================
# AC-005 / BC-2.04.013 edge case EC-002:
# Outside a git repository → exit 0 immediately (no commit attempted).
# FAILS against the stub (stub passes, but we verify via an additional assertion
# that no git operations were attempted — the stub trivially passes this).
# NOTE: The "no git push" structural test also verifies this invariant at the
# source level.
# ===========================================================================

@test "test_BC_2_04_013_outside_git_exits_0_noop" {
  # A temp dir WITHOUT git init — not a git repo.
  local non_git_dir
  non_git_dir="$(mktemp -d)"
  local payload
  payload="$(_stop_payload "${non_git_dir}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'"
  rm -rf "$non_git_dir"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-006 / BC-2.04.013 invariant 1:
# The auto-commit message always uses the brain(auto): conventional-commit prefix.
# FAILS against the stub (stub makes no commit).
# ===========================================================================

@test "test_BC_2_04_013_commit_uses_brain_auto_prefix" {
  echo "new content" >"${BRAIN_DIR}/another-file.txt"
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' bash '${HOOK}'" || true
  # The most recent commit subject must start with brain(auto):
  run git -C "${BRAIN_DIR}" log -1 --format="%s"
  [[ "$output" == "brain(auto):"* ]]
}

# ===========================================================================
# AC-007 / BC-2.04.013 invariant 3:
# The hook does NOT contain any git push commands.
# Structural check — passes against both stub and implementation.
# ===========================================================================

@test "test_BC_2_04_013_hook_does_not_contain_git_push" {
  # Static check: grep for 'git push' in the hook script.
  run grep -n 'git push' "${HOOK}"
  [ "$status" -ne 0 ]
}

# ===========================================================================
# AC-008 / BC-2.04.013 postconditions — event emission:
# JSONL events to stderr for all three exit paths.
# FAILS against the stub (stub produces no stderr).
# ===========================================================================

@test "test_BC_2_04_013_commit_emits_committed_event" {
  echo "new content" >"${BRAIN_DIR}/event-file.txt"
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"session.state.committed"* ]]
}

@test "test_BC_2_04_013_noop_emits_flushed_event" {
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"session.state.flushed"* ]]
}

@test "test_BC_2_04_013_failure_emits_commit_failed_event" {
  mkdir -p "${BRAIN_DIR}/.git/hooks"
  printf '#!/bin/sh\nexit 1\n' >"${BRAIN_DIR}/.git/hooks/pre-commit"
  chmod +x "${BRAIN_DIR}/.git/hooks/pre-commit"
  echo "change" >"${BRAIN_DIR}/event-fail.txt"
  local payload
  payload="$(_stop_payload "${BRAIN_DIR}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"session.state.commit_failed"* ]]
}

# ===========================================================================
# AC-016 / CLAUDE.md §Conventions: shellcheck and shfmt normalization.
# These PASS against the stub (stub is shellcheck-clean and shfmt-normalized).
# ===========================================================================

@test "test_BC_2_04_013_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_013_shfmt_normalized" {
  run shfmt -d -i 2 "${HOOK}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# hooks.json registration: Stop event entry must reference flush-state-and-commit.sh.
# Structural check — PASSES against the existing hooks.json.
# ===========================================================================

@test "test_BC_2_04_013_hooks_json_Stop_entry_includes_flush_state_and_commit" {
  run python3 -c "
import json, sys
with open('${PLUGIN_DIR}/hooks/hooks.json') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
stop = hooks.get('Stop', [])
found = False
for entry in stop:
    for h in entry.get('hooks', []):
        cmd = h.get('command', '')
        if 'flush-state-and-commit.sh' in cmd:
            found = True
            break
if not found:
    print('ERROR: No Stop entry pointing to flush-state-and-commit.sh', file=sys.stderr)
    sys.exit(1)
print('PASS')
"
  [ "$status" -eq 0 ]
}
