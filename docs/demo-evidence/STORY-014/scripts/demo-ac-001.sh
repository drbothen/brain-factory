#!/usr/bin/env bash
# AC-001: emit_event and emit_verdict functions exist after sourcing hook-event-emit.sh
source plugins/brain-factory/hooks/lib/hook-event-emit.sh
declare -F emit_event
declare -F emit_verdict
