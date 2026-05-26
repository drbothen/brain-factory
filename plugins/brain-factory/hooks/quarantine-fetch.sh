#!/usr/bin/env bash
set -euo pipefail
# quarantine-fetch.sh — PreToolUse hook: prompt-injection quarantine for WebFetch calls
# BC-2.04.001 v1.2 | BC-2.10.002 | SS-10 | ADR-002 | ADR-016
# Fires BEFORE WebFetch executes — fetches a 2KB preview and screens for injection patterns.
# Exit 0: allow | Exit 2: block (fail-closed on any error)

HOOK_NAME="quarantine-fetch.sh"
CORPUS="${CLAUDE_PLUGIN_ROOT}/scripts/quarantine.mjs"
HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Check Node 22+ is available — fail-closed BEFORE any other tool dependency.
# This check must be first so it fires even when PATH is restricted (e.g.
# test environments that strip PATH to only a shim directory).
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  printf '{"verdict":"block","code":"E-QUARANTINE-003","message":"Node 22+ required for quarantine check. Install Node from nodejs.org.","trace":"00000000-0000-0000-0000-000000000000"}\n'
  exit 2
fi

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$HOOK_NAME" >&2
  printf '{"verdict":"block","code":"E-HOOK-002","message":"Hook helper missing; cannot safely proceed.","trace":"00000000-0000-0000-0000-000000000000"}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract URL
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
url="$(printf '%s' "$stdin_json" | jq -r '.tool_input.url // empty')"

# ---------------------------------------------------------------------------
# Check quarantine corpus exists — fail-closed (E-QUARANTINE-002)
# ---------------------------------------------------------------------------
if [ ! -f "$CORPUS" ]; then
  trace="${HOOK_TRACE_ID}"
  emit_verdict "$(printf '{"verdict":"block","code":"E-QUARANTINE-002","message":"Quarantine corpus missing at %s/scripts/quarantine.mjs. Cannot safely proceed.","trace":"%s"}' "${CLAUDE_PLUGIN_ROOT}" "$trace")"
  exit 2
fi

# ---------------------------------------------------------------------------
# Fetch 2KB preview — fail-closed on any curl error (E-QUARANTINE-004)
# ---------------------------------------------------------------------------
trace="${HOOK_TRACE_ID}"
preview=""
curl_rc=0
preview="$(curl --max-filesize 2048 --max-time 5 -s "$url")" || curl_rc=$?

if [ "$curl_rc" -ne 0 ]; then
  emit_verdict "$(printf '{"verdict":"block","code":"E-QUARANTINE-004","message":"Preview fetch failed; cannot safely proceed.","trace":"%s"}' "$trace")"
  exit 2
fi

# ---------------------------------------------------------------------------
# Screen preview through quarantine corpus
# ---------------------------------------------------------------------------
check_output=""
check_rc=0
check_output="$(printf '%s' "$preview" | node "$CORPUS" --check)" || check_rc=$?

if [ "$check_rc" -ne 0 ]; then
  # Pattern matched — extract pattern_matched from the quarantine.mjs JSON output
  pattern_matched="$(printf '%s' "$check_output" | jq -r '.pattern_matched // "unknown"')"
  emit_verdict "$(printf '{"verdict":"block","code":"E-QUARANTINE-001","pattern_matched":"%s","url":"%s","message":"Prompt-injection pattern detected in fetched content from %s. Content quarantined.","trace":"%s"}' \
    "$pattern_matched" "$url" "$url" "$trace")"
  emit_event "quarantine.blocked" "url=${url}" "pattern_matched=${pattern_matched}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Clean — allow the fetch
# ---------------------------------------------------------------------------
emit_verdict "$(printf '{"verdict":"allow","message":"Content clean.","trace":"%s"}' "$trace")"
emit_event "quarantine.allowed" "url=${url}"
exit 0
