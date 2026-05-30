# hook-event-emit.sh
# Sourced by all brain-factory hook scripts.
# DO NOT add a shebang — this is sourced, not executed directly.
# shellcheck shell=bash
#
# Exports:
#   emit_event <event_type> [key=value ...]  — writes JSONL to stderr
#   emit_verdict <json-string>               — writes JSON to stdout
#
# GUARD PATTERN (every hook that sources this file must use):
#   HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"
#   if [ ! -f "$HELPER" ]; then
#     printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
#       "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${BASH_SOURCE[0]##*/}" >&2
#     exit 2
#   fi
#   source "$HELPER"

# Shared trace ID for the hook invocation — set once per source operation.
# Pure bash implementation using $RANDOM (no subprocess) for performance.
# $RANDOM gives 0-32767; six values cover 94 bits of entropy — sufficient
# for trace correlation within a single hook invocation.
# Format mirrors UUID v4 layout (xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx).
if [[ -z "${HOOK_TRACE_ID:-}" ]]; then
  printf -v HOOK_TRACE_ID '%04x%04x-%04x-%04x-%04x-%04x%04x%04x' \
    $((RANDOM)) $((RANDOM)) $((RANDOM)) \
    $(((RANDOM & 0x0FFF) | 0x4000)) \
    $(((RANDOM & 0x3FFF) | 0x8000)) \
    $((RANDOM)) $((RANDOM)) $((RANDOM))
fi

# _json_get_str <json-string> <key>
#
# Pure bash extraction of a quoted string value for a JSON key.
# Works for simple string values in hook payload JSON (no nested keys with
# the same name, no escaped quotes inside the value).  Returns empty string
# when the key is absent or the value is not a quoted string.
# Usage: file_path="$(_json_get_str "$stdin_json" 'file_path')"
_json_get_str() {
  local _jgs_json="$1" _jgs_key="$2"
  local _jgs_rest="${_jgs_json#*\""${_jgs_key}"\":\"}"
  # Key not found — rest is unchanged.
  [[ "$_jgs_rest" == "$_jgs_json" ]] && return 0
  printf '%s' "${_jgs_rest%%\"*}"
}

# _json_escape <string>
#
# Escapes a string for safe embedding in a JSON double-quoted value.
# Escapes: backslash, double-quote, newline, tab.
_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  printf '%s' "$s"
}

# emit_event <event_type> [key=value ...]
#
# Writes a single JSONL line to stderr with the following fields:
#   ts         — ISO 8601 UTC timestamp
#   event_type — first argument
#   hook_name  — basename of the calling script (BASH_SOURCE[1])
#   trace      — HOOK_TRACE_ID shared across the invocation
#
# Additional key=value pairs are appended as JSON string fields.
# Credential masking: keys matching *_token, *_key, *_secret, *_password
# (case-insensitive) have their value replaced with "[REDACTED]".
#
# Produces NO stdout output.
emit_event() {
  local event_type="$1"
  shift

  local ts hook_name
  # Use bash 4.2+ printf %T builtin for zero-subprocess UTC timestamp.
  # TZ=UTC ensures the timestamp is in UTC regardless of local timezone.
  # Falls back to date subprocess on older bash (pre-4.2).
  if ! TZ=UTC printf -v ts '%(%Y-%m-%dT%H:%M:%SZ)T' -1 2>/dev/null; then
    ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  fi
  hook_name="$(_json_escape "${BASH_SOURCE[1]##*/}")"
  event_type="$(_json_escape "$event_type")"

  # Build JSON incrementally with base required fields.
  local json
  json="{\"ts\":\"${ts}\",\"event_type\":\"${event_type}\",\"hook_name\":\"${hook_name}\",\"trace\":\"${HOOK_TRACE_ID}\""

  # Append each extra key=value pair.
  local kv key val
  for kv in "$@"; do
    key="${kv%%=*}"
    val="${kv#*=}"
    # Credential masking — case-insensitive suffix match on raw key (before escaping).
    local key_lower="${key,,}"
    if [[ "$key_lower" == *_token ]] ||
      [[ "$key_lower" == *_key ]] ||
      [[ "$key_lower" == *_secret ]] ||
      [[ "$key_lower" == *_password ]]; then
      val="[REDACTED]"
    else
      val="$(_json_escape "$val")"
    fi
    # Escape key after credential pattern matching.
    key="$(_json_escape "$key")"
    json="${json},\"${key}\":\"${val}\""
  done

  json="${json}}"
  printf '%s\n' "$json" >&2
}

# emit_verdict <json-string>
#
# Writes the provided JSON string to stdout.
# Produces NO stderr output.
emit_verdict() {
  printf '%s\n' "$1"
}
