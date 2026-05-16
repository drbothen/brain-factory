---
document_type: verification-property
id: VP-008
title: "Hook event catalog completeness"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
verifies_bcs: [BC-2.17.001, BC-2.17.002]
created: 2026-05-15
status: proposed
---

# VP-008: Hook event catalog completeness

## Property Statement

For every call to `emit_event` in every hook script and skill body, the `event_type` argument appears as a registered entry in `scripts/event-catalog.json`. No `emit_event` call uses an unregistered event_type.

## Verification Mechanism

meta-lint.bats — static analysis (grep-based cross-reference):

```bash
@test "all emit_event calls use catalog-registered event types" {
  local catalog="${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json"
  # Extract all event_type values from catalog
  local catalog_types; catalog_types="$(jq -r '.[].event_type' "$catalog" | sort)"
  
  # Extract all emit_event first-argument values from hook scripts and skills
  local used_types; used_types="$(grep -rh 'emit_event ' \
    "${CLAUDE_PLUGIN_ROOT}/hooks/" \
    "${CLAUDE_PLUGIN_ROOT}/skills/" \
    | grep -oP 'emit_event\s+["\'']\K[^"'\'']+' | sort -u)"
  
  # Every used type must be in the catalog
  while IFS= read -r event_type; do
    if ! grep -qF "$event_type" <<< "$catalog_types"; then
      fail "emit_event call with unregistered event_type: $event_type"
    fi
  done <<< "$used_types"
}

@test "catalog entries have all required fields" {
  local catalog="${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json"
  local count; count="$(jq 'length' "$catalog")"
  local complete; complete="$(jq '[.[] | select(.event_type and .hook_name and .severity and .fields and .example)] | length' "$catalog")"
  assert_equal "$count" "$complete"
}
```

## Assumed Prerequisites

- `jq` installed
- `scripts/event-catalog.json` exists and is valid JSON

## Counterexamples

- A new hook script uses `emit_event "ingest.url.new-event"` but the catalog does not have an entry for `ingest.url.new-event` (BC-2.17.001 violation)
- A catalog entry exists but lacks the `example` field (BC-2.17.002 violation)
- An `emit_event` call is wrapped in a variable and the static grep cannot extract the event_type — this is an implementation discipline issue; hooks must use literal string arguments in `emit_event` calls, not variable arguments

## Status

proposed — pending Phase 3 implementation of hooks and catalog
