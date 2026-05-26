#!/usr/bin/env bash
# AC-005: Credential fields (api_token, api_key) are masked as [REDACTED]
source plugins/brain-factory/hooks/lib/hook-event-emit.sh
emit_event "test.emitted" api_token=secret123 api_key=mykey 2>&1 1>/dev/null | jq '{api_token, api_key}'
