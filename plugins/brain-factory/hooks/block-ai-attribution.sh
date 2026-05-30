#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf "%s\n" "block-ai-attribution hook blocked: internal error." >&2; exit 2' ERR
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
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-HOOK-002","trace":$trace}}'
  printf "%s\n" "block-ai-attribution hook blocked: internal error." >&2
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload
# ---------------------------------------------------------------------------
stdin_json="$(cat)"

# Validate JSON is parseable — fail-closed on malformed or empty stdin.
# BC-2.04.016 invariant 4: canonical empty/malformed-stdin code is E-HOOK-001.
# Hook-specific codes (E-ATTR-001) apply to domain violations only.
if ! printf '%s' "$stdin_json" | jq empty 2>/dev/null; then
  emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=malformed or empty hook payload"
  jq -cn \
    --arg code "E-HOOK-001" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PreToolUse","code":$code,"trace":$trace}}'
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract command from the payload
# ---------------------------------------------------------------------------
command_str="$(printf '%s' "$stdin_json" | jq -r '.tool_input.command // empty')"

# Fail-closed if we cannot determine the command.
if [[ -z "$command_str" ]]; then
  emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=missing tool_input.command in payload"
  jq -cn \
    --arg code "E-HOOK-001" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PreToolUse","code":$code,"trace":$trace}}'
  exit 2
fi

# ---------------------------------------------------------------------------
# Scan command for forbidden AI attribution tokens (single pass, priority order).
# ---------------------------------------------------------------------------
matched=""
if printf '%s' "$command_str" | grep -qiF 'Co-Authored-By: Claude'; then
  matched="Co-Authored-By: Claude"
elif printf '%s' "$command_str" | grep -qF '🤖'; then
  matched="🤖"
elif printf '%s' "$command_str" | grep -qF 'Generated with Claude Code'; then
  matched="Generated with Claude Code"
fi

# ---------------------------------------------------------------------------
# Block if any forbidden token was found.
# ---------------------------------------------------------------------------
if [[ -n "$matched" ]]; then
  emit_event "attribution.token.blocked" "matched_pattern=${matched}"
  jq -cn \
    --arg code "E-ATTR-001" \
    --arg pattern "${matched}" \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":"AI attribution token found: \($pattern). This project prohibits AI attribution per CLAUDE.md.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":$code,"trace":$trace,"matched_pattern":$pattern}}'
  exit 2
fi

# ---------------------------------------------------------------------------
# No forbidden tokens — allow.
# ---------------------------------------------------------------------------
emit_event "attribution.token.cleared"
jq -cn \
  --arg trace "${HOOK_TRACE_ID}" \
  '{"continue":true,"trace":$trace,"message":"No AI attribution tokens found."}'
exit 0
