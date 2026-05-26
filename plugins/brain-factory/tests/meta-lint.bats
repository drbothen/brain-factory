#!/usr/bin/env bats
# STORY-014 VP-008 catalog completeness + schema tests
# Traces to: BC-2.17.001, BC-2.17.002, VP-008

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CATALOG="${PLUGIN_DIR}/scripts/event-catalog.json"
}

# AC-006: catalog exists and is valid JSON array
@test "BC_2_17_002: event-catalog.json exists and is valid JSON array" {
  [ -f "$CATALOG" ]
  run jq -e 'type == "array"' "$CATALOG"
  [ "$status" -eq 0 ]
}

# AC-007: each entry has required fields
@test "BC_2_17_002: all catalog entries have event_type, hook_name, severity, fields, example" {
  local missing
  missing="$(jq '[.[] | select((.event_type == null) or (.hook_name == null) or (.severity == null) or (.fields == null) or (.example == null))] | length' "$CATALOG")"
  [ "$missing" -eq 0 ]
}

# AC-008: event_type naming convention (domain.past-tense)
@test "BC_2_17_002: all event_type values match domain.verb pattern" {
  local bad
  bad="$(jq '[.[].event_type | select(test("^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_.]*$") | not)] | length' "$CATALOG")"
  [ "$bad" -eq 0 ]
}

# AC-009: catalog has at least 27 entries (one per event type across 13 hooks)
@test "BC_2_17_001: catalog has at least 27 event entries" {
  local count
  count="$(jq 'length' "$CATALOG")"
  [ "$count" -ge 27 ]
}

# AC-010: event_type values are unique
@test "BC_2_17_001: all event_type values are unique" {
  local total unique
  total="$(jq '[.[].event_type] | length' "$CATALOG")"
  unique="$(jq '[.[].event_type] | unique | length' "$CATALOG")"
  [ "$total" -eq "$unique" ]
}

# AC-013: jq empty on every example field
@test "BC_2_17_002: all example payloads are valid JSON" {
  jq -e '.[].example' "$CATALOG" | while IFS= read -r example; do
    echo "$example" | jq empty
  done
}

# AC-007: severity values are restricted to info|warn|error
@test "BC_2_17_002: severity values are info, warn, or error" {
  local bad
  bad="$(jq '[.[].severity | select(. != "info" and . != "warn" and . != "error")] | length' "$CATALOG")"
  [ "$bad" -eq 0 ]
}

# AC-014: shellcheck on hook-event-emit.sh
@test "BC_2_04_017: hook-event-emit.sh passes shellcheck" {
  run shellcheck "${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
  [ "$status" -eq 0 ]
}
