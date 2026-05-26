# hook-event-emit.sh
# Sourced by all brain-factory hook scripts.
# DO NOT add a shebang — this is sourced, not executed directly.
# shellcheck shell=bash
#
# Exports:
#   emit_event <event_type> [key=value ...]  — writes JSONL to stderr
#   emit_verdict <json-string>               — writes JSON to stdout

# Shared trace ID for the hook invocation — set once per source operation.
# Falls back across platforms: uuidgen (macOS/BSD), /proc (Linux), od fallback.
: "${HOOK_TRACE_ID:=$(uuidgen 2>/dev/null ||
  cat /proc/sys/kernel/random/uuid 2>/dev/null ||
  od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}')}"

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
  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  hook_name="${BASH_SOURCE[1]##*/}"

  # Build JSON incrementally with base required fields.
  local json
  json="{\"ts\":\"${ts}\",\"event_type\":\"${event_type}\",\"hook_name\":\"${hook_name}\",\"trace\":\"${HOOK_TRACE_ID}\""

  # Append each extra key=value pair.
  local kv key val
  for kv in "$@"; do
    key="${kv%%=*}"
    val="${kv#*=}"
    # Credential masking — case-insensitive suffix match.
    local key_lower="${key,,}"
    if [[ "$key_lower" == *_token ]] ||
      [[ "$key_lower" == *_key ]] ||
      [[ "$key_lower" == *_secret ]] ||
      [[ "$key_lower" == *_password ]]; then
      val="[REDACTED]"
    fi
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
