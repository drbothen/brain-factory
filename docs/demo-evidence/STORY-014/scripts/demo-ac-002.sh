#!/usr/bin/env bash
# AC-002: emit_event writes JSONL to stderr with required fields (ts, event_type, hook_name, trace)
source plugins/brain-factory/hooks/lib/hook-event-emit.sh
emit_event "test.emitted" file_path=/tmp/demo.md 2>&1 1>/dev/null | jq .
