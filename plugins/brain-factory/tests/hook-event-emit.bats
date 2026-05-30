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
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${BASH_SOURCE[0]##*/}" >&2
  exit 2
fi
source "$HELPER"
HOOK
  chmod +x "$tmp_hook"

  run bash "$tmp_hook" 2>&1
  [ "$status" -eq 2 ]
  echo "$output" | grep -q "hook.helper.missing"
  echo "$output" | grep -q "E-HOOK-002"

  rm -f "$tmp_hook"
}

# =============================================================================
# STORY-015 F-PASS01-I01: _json_get_str and _json_escape edge case coverage
#
# These functions are used by all 13 hooks to parse stdin JSON and build event
# payloads. They had ZERO bats coverage before this section. Per SOUL.md #4,
# silent-failure on hot-path shared functions is not acceptable.
#
# CONTRACT SCOPING:
#   _json_get_str is documented as: "Works for simple string values in hook
#   payload JSON (no nested keys with the same name, no escaped quotes inside
#   the value). Returns empty string when the key is absent or the value is
#   not a quoted string."
#
#   Tests for edge cases INSIDE the stated contract fail if the function is
#   broken. Tests for edge cases OUTSIDE the stated contract (escaped quotes in
#   values) are marked with skip + rationale + a follow-up story proposal, per
#   Canonical Principle Rule 6 (genuine scope-boundary defer requires explicit
#   future-story anchor).
#
#   Proposed follow-up story: STORY-0XX "_json_get_str robustness — escaped
#   quotes and nested-key disambiguation for hook stdin payloads." Filed with
#   the implementer dispatch for Pass 1.2. This is NOT a defer-pattern because
#   the limitation is explicitly documented in the function's own contract
#   comment; the test documents the gap rather than silently accepting it.
# =============================================================================

# -----------------------------------------------------------------------------
# _json_get_str edge cases
# -----------------------------------------------------------------------------

@test "F_PASS01_I01: _json_get_str simple key returns its value" {
  source "$SHIM"
  local result
  result="$(_json_get_str '{"key":"value"}' "key")"
  [ "$result" = "value" ]
}

@test "F_PASS01_I01: _json_get_str missing key returns empty string" {
  source "$SHIM"
  local result
  result="$(_json_get_str '{"foo":"bar"}' "baz")"
  [ -z "$result" ]
}

@test "F_PASS01_I01: _json_get_str empty value returns empty string" {
  source "$SHIM"
  local result
  result="$(_json_get_str '{"key":""}' "key")"
  [ -z "$result" ]
}

@test "F_PASS01_I01: _json_get_str value that equals the key string" {
  # e.g. {"key":"key"} — should return "key", not recurse or error.
  source "$SHIM"
  local result
  result="$(_json_get_str '{"key":"key"}' "key")"
  [ "$result" = "key" ]
}

@test "F_PASS01_I01: _json_get_str key appearing as a value in another field" {
  # {"foo":"key","key":"x"} — asking for key=key must return "x", not "key".
  # This tests that the function anchors on the key-colon pattern, not the raw
  # string "key" anywhere in the JSON.
  source "$SHIM"
  local result
  result="$(_json_get_str '{"foo":"key","key":"x"}' "key")"
  [ "$result" = "x" ]
}

@test "F_PASS01_I01: _json_get_str multiple keys where target key has a prefix match" {
  # {"key_one":"a","key":"b"} — asking for key=key must return "b", not "a".
  # The function anchors on "key": (colon-quote suffix), which must not match
  # "key_one": (different key name).
  # KNOWN LIMITATION: the pure-bash implementation does NOT guarantee correct
  # disambiguation when one key is a prefix of another in all cases; this test
  # documents expected behavior per contract. If it fails, the implementer must
  # fix the extraction regex to anchor on ,"key": or ^"key": boundaries.
  source "$SHIM"
  local result
  result="$(_json_get_str '{"key_one":"a","key":"b"}' "key")"
  [ "$result" = "b" ]
}

@test "F_PASS01_I01: _json_get_str key with backslash-escaped quote in value — skip outside contract" {
  # {"key":"abc\"def"} — the function docs say it does NOT handle escaped quotes.
  # This test documents the known gap; it is skipped to avoid a false-Red-Gate
  # on behavior that is explicitly out-of-contract.
  # Follow-up story: STORY-0XX "_json_get_str robustness — escaped quotes in values"
  skip "Out-of-contract: _json_get_str docs state 'no escaped quotes inside value'. " \
    "Broken behavior on this input is a known limitation, not a test failure. " \
    "Follow-up: STORY-0XX _json_get_str robustness — escaped quotes in values."
}

@test "F_PASS01_I01: _json_get_str key with literal newline escape sequence in value — skip outside contract" {
  # {"key":"line1\nline2"} — JSON \n literal in a string value.
  # The function extracts up to the closing double-quote; if \n appears before
  # the closing quote, extraction should succeed. This is technically within
  # contract (no embedded literal newlines, only the two-char sequence \n).
  # The test documents expected behavior; if it fails the implementer fixes.
  source "$SHIM"
  local json
  # shellcheck disable=SC2016
  json='{"key":"line1\nline2"}'
  local result
  result="$(_json_get_str "$json" "key")"
  # Expected: the literal characters l-i-n-e-1-\-n-l-i-n-e-2 (not a real newline).
  [ "$result" = 'line1\nline2' ]
}

# -----------------------------------------------------------------------------
# _json_escape edge cases
# -----------------------------------------------------------------------------

@test "F_PASS01_I01: _json_escape plain string passes through unchanged" {
  source "$SHIM"
  local result
  result="$(_json_escape "hello")"
  [ "$result" = "hello" ]
}

@test "F_PASS01_I01: _json_escape empty string returns empty string" {
  source "$SHIM"
  local result
  result="$(_json_escape "")"
  [ -z "$result" ]
}

@test "F_PASS01_I01: _json_escape double quote is escaped to backslash-quote" {
  source "$SHIM"
  local result
  result="$(_json_escape 'he"llo')"
  [ "$result" = 'he\"llo' ]
}

@test "F_PASS01_I01: _json_escape backslash is doubled" {
  source "$SHIM"
  local input='he\llo'
  local result
  result="$(_json_escape "$input")"
  # One backslash in input → two backslashes in output (escaped for JSON embedding).
  [ "$result" = 'he\\llo' ]
}

@test "F_PASS01_I01: _json_escape newline is replaced with backslash-n" {
  source "$SHIM"
  local input
  # Literal newline via $'\n'.
  input="he"$'\n'"llo"
  local result
  result="$(_json_escape "$input")"
  [ "$result" = 'he\nllo' ]
}

@test "F_PASS01_I01: _json_escape tab is replaced with backslash-t" {
  source "$SHIM"
  local input
  input="he"$'\t'"llo"
  local result
  result="$(_json_escape "$input")"
  [ "$result" = 'he\tllo' ]
}

@test "F_PASS01_I01: _json_escape carriage return is replaced with backslash-r" {
  source "$SHIM"
  local input
  input="he"$'\r'"llo"
  local result
  result="$(_json_escape "$input")"
  [ "$result" = 'he\rllo' ]
}

@test "F_PASS01_I01: _json_escape backslash then double-quote is double-escaped" {
  # Input: \" (2 bytes: backslash, double-quote)
  # Escaping order per implementation: backslash first (\ → \\), then double-quote
  # (\" → \\\"). Result: 4 bytes — backslash backslash backslash double-quote.
  # In single-quote notation that is: '\\\"' (no, single quotes are literal so
  # '\\\"' = \, \, \, " which IS the 4-byte sequence).
  # Verified with xxd: input 5c22, output 5c5c5c22.
  source "$SHIM"
  local input
  input='\"'
  local result
  result="$(_json_escape "$input")"
  # Expected 4 bytes: \, \, \, " — represented in single-quotes as '\\\"'
  # shellcheck disable=SC2016
  [ "$result" = '\\\"' ]
}
