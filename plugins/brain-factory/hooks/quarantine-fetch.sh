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
  printf '{"ts":"%s","event_type":"hook.tool.missing","hook_name":"quarantine-fetch.sh","trace":"00000000-0000-0000-0000-000000000000","code":"E-QUARANTINE-003","reason":"Node 22+ not found in PATH"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" >&2
  printf '{"continue":false,"decision":"block","code":"E-QUARANTINE-003","message":"Node 22+ required for quarantine check. Install Node from nodejs.org.","trace":"00000000-0000-0000-0000-000000000000"}\n'
  exit 2
fi

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "$HOOK_NAME" >&2
  printf '{"continue":false,"decision":"block","code":"E-HOOK-002","message":"Hook helper missing; cannot safely proceed.","trace":"00000000-0000-0000-0000-000000000000"}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract URL in a single jq call.
# (performance: one subprocess vs two; malformed JSON → empty → fail-closed).
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
url="$(printf '%s' "$stdin_json" | jq -r '.tool_input.url // ""' 2>/dev/null || true)"

# Fail-closed on malformed or empty stdin (jq failure leaves url empty).
# Also fail-closed on missing URL field.
if [[ -z "$url" ]]; then
  # Distinguish empty stdin from missing URL by checking stdin_json.
  if [[ -z "$stdin_json" ]]; then
    emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=malformed or empty hook payload"
    printf '{"continue":false,"decision":"block","code":"E-HOOK-001","message":"Malformed JSON on stdin; cannot safely proceed.","trace":"%s"}\n' \
      "${HOOK_TRACE_ID}"
  else
    emit_event "hook.input.invalid" "code=E-QUARANTINE-005" "reason=empty or missing URL in payload"
    printf '{"continue":false,"decision":"block","code":"E-QUARANTINE-005","message":"Empty or missing URL in payload; cannot safely proceed.","trace":"%s"}\n' \
      "${HOOK_TRACE_ID}"
  fi
  exit 2
fi

# ---------------------------------------------------------------------------
# Check quarantine corpus exists — fail-closed (E-QUARANTINE-002)
# ---------------------------------------------------------------------------
if [ ! -f "$CORPUS" ]; then
  trace="${HOOK_TRACE_ID}"
  emit_event "hook.tool.missing" "code=E-QUARANTINE-002" "reason=quarantine corpus (quarantine.mjs) missing"
  printf '{"continue":false,"decision":"block","code":"E-QUARANTINE-002","message":"Quarantine corpus missing at %s/scripts/quarantine.mjs. Cannot safely proceed.","trace":"%s"}\n' \
    "${CLAUDE_PLUGIN_ROOT}" "${trace}"
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
  emit_event "quarantine.fetch.failed" "code=E-QUARANTINE-004" "curl_rc=${curl_rc}"
  printf '{"continue":false,"decision":"block","code":"E-QUARANTINE-004","message":"Preview fetch failed; cannot safely proceed.","trace":"%s"}\n' \
    "$trace"
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
  pattern_matched="$(printf '%s' "$check_output" | jq -r '.pattern_matched // "unknown"' 2>/dev/null || printf 'unknown')"
  emit_event "quarantine.blocked" "url=${url}" "pattern_matched=${pattern_matched}"
  _em_url="$(_json_escape "${url}")"
  _em_pm="$(_json_escape "${pattern_matched}")"
  _em_msg="$(_json_escape "Prompt-injection pattern detected in fetched content from ${url}. Content quarantined.")"
  printf '{"continue":false,"decision":"block","code":"E-QUARANTINE-001","url":"%s","pattern_matched":"%s","message":"%s","trace":"%s"}\n' \
    "${_em_url}" "${_em_pm}" "${_em_msg}" "${trace}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Clean — allow the fetch
# ---------------------------------------------------------------------------
printf '{"continue":true,"trace":"%s"}\n' "${trace}"
emit_event "quarantine.allowed" "url=${url}"
exit 0
