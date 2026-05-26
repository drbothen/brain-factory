#!/usr/bin/env bash
# AC-004: Stream separation — emit_event to stderr (stdout empty), emit_verdict to stdout (stderr empty)
source plugins/brain-factory/hooks/lib/hook-event-emit.sh
out=$(emit_event "test.emitted" 2>/dev/null)
echo "stdout_from_emit_event='${out}'"
err=$(emit_verdict '{"continue":true}' 2>&1 1>/dev/null)
echo "stderr_from_emit_verdict='${err}'"
