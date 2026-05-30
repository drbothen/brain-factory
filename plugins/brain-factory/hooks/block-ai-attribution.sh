#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf '"'"'{"ts":"%s","event_type":"hook.error.internal","hook_name":"block-ai-attribution.sh","trace":"%s","code":"E-HOOK-003","reason":"unhandled error"}\n'"'"' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" >&2; exit 2' ERR
# block-ai-attribution.sh — PreToolUse hook: AI attribution token gate
# BC-2.04.012 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires BEFORE Bash tool executes — scans the command string for AI attribution
# tokens forbidden by CLAUDE.md: Co-Authored-By:, 🤖, "Generated with Claude Code".
# Exit 0: no forbidden tokens found
# Exit 2: block (attribution token found, or fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>","message":"No AI attribution tokens found."}
#   block → {"continue":false,"decision":"block","reason":"...","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-ATTR-001","trace":"<uuid>","matched_pattern":"<pattern>"}}

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "block-ai-attribution.sh" >&2
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload.
# Fail-closed on empty stdin or non-JSON content; no jq call needed —
# we scan the raw JSON for forbidden patterns directly (the patterns contain
# no JSON-special chars). A minimal JSON validity check: payload must start
# with '{' and end with '}'. BC-2.04.016 invariant 4: E-HOOK-001.
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
# Strip leading/trailing whitespace for the shape check.
_stripped="${stdin_json#"${stdin_json%%[![:space:]]*}"}"
_stripped="${_stripped%"${_stripped##*[![:space:]]}"}"

if [[ -z "$_stripped" ]] || [[ "$_stripped" != '{'*'}' ]]; then
  emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=malformed or empty hook payload"
  printf '{"continue":false,"decision":"block","code":"E-HOOK-001","reason":"Malformed or empty hook payload.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-HOOK-001","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Scan the raw JSON for forbidden AI attribution tokens (pure bash, no subprocess).
# PreToolUse:Bash fires for git commit commands; the command value is the
# target. All three forbidden patterns contain no JSON-escapable characters
# so searching the raw payload is equivalent to searching the decoded command.
# ---------------------------------------------------------------------------
matched=""
if [[ "$stdin_json" == *'Co-Authored-By: Claude'* ]] ||
  [[ "$stdin_json" == *'co-authored-by: claude'* ]]; then
  matched="Co-Authored-By: Claude"
elif [[ "$stdin_json" == *'🤖'* ]]; then
  matched="🤖"
elif [[ "$stdin_json" == *'Generated with Claude Code'* ]]; then
  matched="Generated with Claude Code"
fi

# ---------------------------------------------------------------------------
# Block if any forbidden token was found.
# ---------------------------------------------------------------------------
if [[ -n "$matched" ]]; then
  emit_event "attribution.token.blocked" "matched_pattern=${matched}"
  _escaped_matched="$(_json_escape "${matched}")"
  printf '{"continue":false,"decision":"block","reason":"AI attribution token found: %s. This project prohibits AI attribution per CLAUDE.md.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-ATTR-001","trace":"%s","matched_pattern":"%s"}}\n' \
    "${_escaped_matched}" "${HOOK_TRACE_ID}" "${_escaped_matched}"
  exit 2
fi

# ---------------------------------------------------------------------------
# No forbidden tokens — allow.
# ---------------------------------------------------------------------------
emit_event "attribution.token.cleared"
printf '{"continue":true,"trace":"%s","message":"No AI attribution tokens found."}\n' \
  "${HOOK_TRACE_ID}"
exit 0
