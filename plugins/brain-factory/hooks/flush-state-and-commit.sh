#!/usr/bin/env bash
set -euo pipefail
# flush-state-and-commit.sh — Stop lifecycle hook: auto-commit session state
# BC-2.04.013 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires on the Stop event. Commits any uncommitted changes in the brain's git
# repo under cwd. Advisory only on failure — NEVER exits 2.
# Exit codes:
#   0 — always (committed, no changes, not a git repo, or commit failed advisory)
#   Advisory messages delivered via stdout systemMessage, never via exit code

# ADVISORY ERR trap: unhandled errors exit 0 so session close is never blocked.
trap 'printf "%s\n" "{\"continue\":true,\"systemMessage\":\"Flush hook encountered an error; session closing normally.\"}" ; exit 0' ERR

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# Source event-emit helper (advisory fallback if missing — never block).
_helper_loaded=false
if [ -f "$HELPER" ]; then
  # shellcheck disable=SC1090,SC1091
  source "$HELPER" && _helper_loaded=true
fi

if [[ "$_helper_loaded" == "false" ]]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "flush-state-and-commit.sh" >&2
fi

# Provide a no-op emit_event when helper did not load.
if ! declare -f emit_event >/dev/null 2>&1; then
  emit_event() { :; }
fi

# ---------------------------------------------------------------------------
# Read stdin JSON payload.
# ---------------------------------------------------------------------------
stdin_json="$(cat)" || true

# ---------------------------------------------------------------------------
# Determine brain directory: prefer BRAIN_DIR env, fall back to cwd in payload.
# ---------------------------------------------------------------------------
brain_dir="${BRAIN_DIR:-$(printf '%s' "$stdin_json" | jq -r '.cwd // empty' 2>/dev/null || true)}"

# If no brain dir resolved, exit 0 (no-op — cannot identify brain).
if [[ -z "$brain_dir" ]]; then
  emit_event "session.state.flushed" "committed=false"
  jq -cn --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"trace":$trace,"message":"No changes to flush."}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Check if this directory is inside a git repository.
# EC-002: outside a git repo → exit 0 immediately, no commit attempted.
# Handles both regular repos (.git directory) and worktrees (.git file).
# ---------------------------------------------------------------------------
if ! git -C "$brain_dir" rev-parse --git-dir >/dev/null 2>&1; then
  emit_event "session.state.flushed" "committed=false"
  jq -cn --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"trace":$trace,"message":"No changes to flush."}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Check for uncommitted changes.
# ---------------------------------------------------------------------------
status_output="$(git -C "$brain_dir" status --porcelain 2>/dev/null || true)"

if [[ -z "$status_output" ]]; then
  # No uncommitted changes — clean state.
  emit_event "session.state.flushed" "committed=false"
  jq -cn --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"trace":$trace,"message":"No changes to flush."}'
  exit 0
fi

# ---------------------------------------------------------------------------
# EC-003: Update .brain/STATE.md with session-close timestamp if present.
# This ensures the close timestamp is included in the auto-commit.
# ---------------------------------------------------------------------------
_state_file="${brain_dir}/.brain/STATE.md"
if [[ -f "$_state_file" ]]; then
  _close_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  printf '\n<!-- session-close: %s -->\n' "$_close_ts" >>"$_state_file"
fi

# ---------------------------------------------------------------------------
# Uncommitted changes present — stage all and commit.
# Capture add stderr: partial-add failures (e.g. permission denied on a file)
# are surfaced in the commit advisory message rather than silently ignored.
# ---------------------------------------------------------------------------
add_errors=""
add_errors="$(git -C "$brain_dir" add -A 2>&1 1>/dev/null)" || true

commit_output=""
commit_exit=0
commit_output="$(git -C "$brain_dir" commit -m "brain(auto): flush session state" 2>&1)" || commit_exit=$?

if [[ "$commit_exit" -ne 0 ]]; then
  # Commit failed — emit advisory via systemMessage; session still closes (exit 0).
  error_msg="$(printf '%s' "$commit_output" | head -1)"
  # Surface partial-add errors if present (permission denied, etc.).
  if [[ -n "$add_errors" ]]; then
    error_msg="${error_msg}${error_msg:+ | }add errors: $(printf '%s' "$add_errors" | head -1)"
  fi
  emit_event "session.state.commit_failed" "error=${error_msg}"
  jq -cn \
    --arg msg "Flush failed: ${error_msg}" \
    --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"systemMessage":$msg,"hookSpecificOutput":{"hookEventName":"Stop","code":"E-FLUSH-001","trace":$trace}}'
  exit 0
fi

# Commit succeeded — retrieve short SHA.
short_sha="$(git -C "$brain_dir" rev-parse --short HEAD 2>/dev/null || true)"

emit_event "session.state.committed" "sha=${short_sha}"
jq -cn \
  --arg sha "$short_sha" \
  --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
  '{"continue":true,"trace":$trace,"message":("Session state committed: " + $sha)}'
exit 0
