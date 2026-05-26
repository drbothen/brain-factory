#!/usr/bin/env bash
# AC-009: Catalog has 28 entries (27 hooks + helper.missing)
echo -n "Entry count: "
jq 'length' plugins/brain-factory/scripts/event-catalog.json
# AC-010: All event_type values are unique
echo -n "All unique: "
jq 'map(.event_type) | (unique | length) == length' plugins/brain-factory/scripts/event-catalog.json
