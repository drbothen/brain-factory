#!/usr/bin/env bats
# STORY-014 hook-event-emit.sh tests
# Traces to: BC-2.04.017, VP-017

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  SHIM="${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
}

# AC-001: emit_event and emit_verdict functions exist
@test "BC_2_04_017: hook-event-emit.sh exports emit_event function" {
  source "$SHIM"
  declare -F emit_event
}

@test "BC_2_04_017: hook-event-emit.sh exports emit_verdict function" {
  source "$SHIM"
  declare -F emit_verdict
}

# AC-002: emit_event produces JSONL on stderr with required fields
@test "BC_2_04_017: emit_event writes JSONL to stderr with ts, event_type, hook_name, trace" {
  source "$SHIM"
  local stderr_output
  stderr_output="$(emit_event "test.emitted" 2>&1 1>/dev/null)"
  # Must be valid JSON
  echo "$stderr_output" | jq -e '.' >/dev/null
  # Must have required fields
  echo "$stderr_output" | jq -e '.ts and .event_type and .hook_name and .trace' >/dev/null
}

# AC-002: ts is ISO 8601
@test "BC_2_04_017: emit_event ts field is ISO 8601 format" {
  source "$SHIM"
  local stderr_output
  stderr_output="$(emit_event "test.emitted" 2>&1 1>/dev/null)"
  local ts
  ts="$(echo "$stderr_output" | jq -r '.ts')"
  [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# AC-004: emit_event writes ONLY to stderr (no stdout contamination)
@test "VP_017: emit_event produces no stdout output" {
  source "$SHIM"
  local stdout_output
  stdout_output="$(emit_event "test.emitted" 2>/dev/null)"
  [ -z "$stdout_output" ]
}

# AC-004: emit_verdict writes ONLY to stdout (no stderr contamination)
@test "VP_017: emit_verdict produces no stderr output" {
  source "$SHIM"
  local stderr_output
  stderr_output="$(emit_verdict '{"continue":true}' 2>&1 1>/dev/null)"
  [ -z "$stderr_output" ]
}

# AC-004: emit_verdict outputs the JSON string to stdout
@test "VP_017: emit_verdict writes JSON to stdout" {
  source "$SHIM"
  local stdout_output
  stdout_output="$(emit_verdict '{"continue":true}' 2>/dev/null)"
  echo "$stdout_output" | jq -e '.continue == true' >/dev/null
}

# AC-005: credential masking
@test "BC_2_04_017: emit_event masks credential values" {
  source "$SHIM"
  local stderr_output
  stderr_output="$(emit_event "test.emitted" api_token=secret123 2>&1 1>/dev/null)"
  local token_val
  token_val="$(echo "$stderr_output" | jq -r '.api_token')"
  [ "$token_val" = "[REDACTED]" ]
}

# AC-002: extra key=value pairs appear in output
@test "BC_2_04_017: emit_event includes extra key-value fields" {
  source "$SHIM"
  local stderr_output
  stderr_output="$(emit_event "test.emitted" file_path=/tmp/test.md severity=warn 2>&1 1>/dev/null)"
  echo "$stderr_output" | jq -e '.file_path == "/tmp/test.md"' >/dev/null
  echo "$stderr_output" | jq -e '.severity == "warn"' >/dev/null
}

# AC-003: missing helper guard pattern emits hook.helper.missing and exits 2
@test "BC_2_04_017_EC001: missing helper emits fallback JSONL and exits 2" {
  local tmp_hook
  tmp_hook="$(mktemp)"
  cat >"$tmp_hook" <<'HOOK'
#!/usr/bin/env bash
set -euo pipefail
HELPER="/nonexistent/path/hook-event-emit.sh"
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${BASH_SOURCE[0]##*/}" >&2
  exit 2
fi
source "$HELPER"
HOOK
  chmod +x "$tmp_hook"

  run bash "$tmp_hook" 2>&1
  [ "$status" -eq 2 ]
  echo "$output" | grep -q "hook.helper.missing"

  rm -f "$tmp_hook"
}
