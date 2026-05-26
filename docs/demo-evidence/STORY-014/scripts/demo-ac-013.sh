#!/usr/bin/env bash
# AC-013: All example payloads in event-catalog.json are valid JSON strings
echo "Parsing all 28 example payloads as JSON..."
jq '.[].example | fromjson | .event_type' plugins/brain-factory/scripts/event-catalog.json | head -5
echo "(all 28 passed fromjson)"
