#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block), never leaks via non-zero
# non-2 exit codes that ADR-002 v2.0 treats as "non-blocking error; operation ALLOWED".
trap 'exit 2' ERR
# quarantine-fetch.sh — PreToolUse hook: prompt-injection quarantine for WebFetch calls
# BC-2.04.001 v1.2 | BC-2.10.002 | SS-10 | ADR-002 v2.0 | ADR-016
# Fires BEFORE WebFetch executes — fetches a 2KB preview and screens for injection patterns.
# Exit 0: allow | Exit 2: block (fail-closed on any error)
# stdout protocol (ADR-002 v2.0):
#   allow  → {"continue":true,"trace":"<uuid>"}
#   block  → {"continue":false,"decision":"block","code":"<E-NNN>","message":"<text>","trace":"<uuid>"}
#            + human-readable message on stderr

HOOK_NAME="quarantine-fetch.sh"
CORPUS="${CLAUDE_PLUGIN_ROOT}/scripts/quarantine.mjs"
HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Check Node 22+ is available — fail-closed BEFORE any other tool dependency.
# This check must be first so it fires even when PATH is restricted (e.g.
# test environments that strip PATH to only a shim directory).
# ---------------------------------------------------------------------------
if ! command -v node >/dev/null 2>&1; then
  jq -n \
    --arg code "E-QUARANTINE-003" \
    --arg msg "Node 22+ required for quarantine check. Install Node from nodejs.org." \
    '{"continue":false,"decision":"block","code":$code,"message":$msg,"trace":"00000000-0000-0000-0000-000000000000"}'
  echo "Quarantine hook blocked: Node 22+ not found in PATH — install Node from nodejs.org" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$HOOK_NAME" >&2
  jq -n \
    --arg code "E-HOOK-002" \
    --arg msg "Hook helper missing; cannot safely proceed." \
    '{"continue":false,"decision":"block","code":$code,"message":$msg,"trace":"00000000-0000-0000-0000-000000000000"}'
  echo "Quarantine hook blocked: hook helper (hook-event-emit.sh) missing — cannot safely proceed" >&2
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract URL
# ---------------------------------------------------------------------------
stdin_json="$(cat)"

# Validate JSON is parseable — fail-closed on malformed stdin.
if ! printf '%s' "$stdin_json" | jq empty 2>/dev/null; then
  jq -n \
    --arg code "E-HOOK-003" \
    --arg msg "Malformed JSON on stdin; cannot safely proceed." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","code":$code,"message":$msg,"trace":$trace}'
  echo "Quarantine hook blocked: malformed JSON on stdin — cannot safely proceed" >&2
  exit 2
fi

url="$(printf '%s' "$stdin_json" | jq -r '.tool_input.url // empty')"

# ---------------------------------------------------------------------------
# Validate URL is non-empty — fail-closed on missing URL
# ---------------------------------------------------------------------------
if [ -z "$url" ]; then
  jq -n \
    --arg code "E-QUARANTINE-005" \
    --arg msg "Empty or missing URL in payload; cannot safely proceed." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","code":$code,"message":$msg,"trace":$trace}'
  echo "Quarantine hook blocked: empty URL in WebFetch payload — cannot safely proceed" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Check quarantine corpus exists — fail-closed (E-QUARANTINE-002)
# ---------------------------------------------------------------------------
if [ ! -f "$CORPUS" ]; then
  trace="${HOOK_TRACE_ID}"
  jq -n \
    --arg code "E-QUARANTINE-002" \
    --arg msg "Quarantine corpus missing at ${CLAUDE_PLUGIN_ROOT}/scripts/quarantine.mjs. Cannot safely proceed." \
    --arg trace "$trace" \
    '{"continue":false,"decision":"block","code":$code,"message":$msg,"trace":$trace}'
  echo "Quarantine hook blocked: quarantine corpus (quarantine.mjs) missing — cannot safely proceed" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Fetch 2KB preview — fail-closed on any curl error (E-QUARANTINE-004)
# --proto =http,https restricts to HTTP/HTTPS only (SSRF guard: blocks file://,
# ftp://, gopher://, dict://, and other non-web schemes).
# ---------------------------------------------------------------------------
trace="${HOOK_TRACE_ID}"
preview=""
curl_rc=0
preview="$(curl --proto '=http,https' --max-filesize 2048 --max-time 5 -s "$url")" || curl_rc=$?

if [ "$curl_rc" -ne 0 ]; then
  jq -n \
    --arg code "E-QUARANTINE-004" \
    --arg msg "Preview fetch failed; cannot safely proceed." \
    --arg trace "$trace" \
    '{"continue":false,"decision":"block","code":$code,"message":$msg,"trace":$trace}'
  echo "Quarantine hook blocked: preview fetch failed (curl exit ${curl_rc}) — cannot safely proceed" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Screen preview through quarantine corpus
# ---------------------------------------------------------------------------
check_output=""
check_rc=0
check_output="$(printf '%s' "$preview" | node "$CORPUS" --check)" || check_rc=$?

if [ "$check_rc" -ne 0 ]; then
  # Pattern matched — extract pattern_matched from the quarantine.mjs JSON output.
  # Use jq for safe extraction (avoids JSON-injection in the verdict output).
  pattern_matched="$(printf '%s' "$check_output" | jq -r '.pattern_matched // "unknown"')"
  url_escaped="$(_json_escape "$url")"
  pattern_escaped="$(_json_escape "$pattern_matched")"
  jq -n \
    --arg code "E-QUARANTINE-001" \
    --arg url "$url_escaped" \
    --arg pattern_matched "$pattern_escaped" \
    --arg msg "Prompt-injection pattern detected in fetched content from ${url_escaped}. Content quarantined." \
    --arg trace "$trace" \
    '{"continue":false,"decision":"block","code":$code,"url":$url,"pattern_matched":$pattern_matched,"message":$msg,"trace":$trace}'
  echo "Quarantine hook blocked: prompt-injection pattern '${pattern_matched}' detected in ${url} — content quarantined" >&2
  emit_event "quarantine.blocked" "url=${url}" "pattern_matched=${pattern_matched}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Clean — allow the fetch
# ---------------------------------------------------------------------------
jq -n --arg trace "$trace" '{"continue":true,"trace":$trace}'
emit_event "quarantine.allowed" "url=${url}"
exit 0
