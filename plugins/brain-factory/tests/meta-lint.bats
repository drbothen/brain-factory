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

# AC-012: all emit_event call sites have matching catalog entries
@test "VP_008: all emit_event call sites have matching catalog entries" {
  local catalog_types
  catalog_types="$(jq -r '.[].event_type' "${PLUGIN_DIR}/scripts/event-catalog.json")"

  # Collect emit_event call sites from all hook scripts (exclude comment lines)
  local emit_sites=""
  local sh_file
  for sh_file in "${PLUGIN_DIR}/hooks/"*.sh "${PLUGIN_DIR}/hooks/lib/"*.sh; do
    [ -f "$sh_file" ] || continue
    # Extract event_type from lines like: emit_event "some.event.type" ...
    # Skip lines that begin with # (comments)
    local site
    site="$(grep -h 'emit_event ' "$sh_file" | grep -v '^\s*#' | \
      grep -o 'emit_event "[^"]*"' | sed 's/emit_event "//;s/"//' || true)"
    if [ -n "$site" ]; then
      emit_sites="${emit_sites}${site}"$'\n'
    fi
  done

  # If no emit sites found (all stubs), pass vacuously
  if [ -z "$(echo "$emit_sites" | tr -d '[:space:]')" ]; then
    return 0
  fi

  # Check each emit site has a catalog entry
  local missing=""
  while IFS= read -r event_type; do
    [ -z "$event_type" ] && continue
    if ! echo "$catalog_types" | grep -qxF "$event_type"; then
      missing="${missing}${event_type}"$'\n'
    fi
  done <<< "$emit_sites"

  if [ -n "$missing" ]; then
    echo "Unregistered emit_event types:" >&2
    echo "$missing" >&2
    return 1
  fi
}

# AC-014: shellcheck on hook-event-emit.sh
@test "BC_2_04_017: hook-event-emit.sh passes shellcheck" {
  run shellcheck "${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
  [ "$status" -eq 0 ]
}
