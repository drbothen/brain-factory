#!/usr/bin/env bash
# AC-008: All event_type values follow domain.verb naming convention
jq '[.[].event_type]' plugins/brain-factory/scripts/event-catalog.json | head -10
