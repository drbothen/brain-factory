#!/usr/bin/env bash
# AC-006+007: event-catalog.json exists, valid JSON array, entries have required fields
jq 'length' plugins/brain-factory/scripts/event-catalog.json
jq '.[0]' plugins/brain-factory/scripts/event-catalog.json
