#!/usr/bin/env bash
# AC-014: shellcheck produces no warnings; shfmt produces no diff
shellcheck plugins/brain-factory/hooks/lib/hook-event-emit.sh && echo "shellcheck: PASS"
shfmt -d -i 2 plugins/brain-factory/hooks/lib/hook-event-emit.sh && echo "shfmt: PASS"
