#!/usr/bin/env bash
set -euo pipefail
PLUGIN_DIR="plugins/brain-factory"
INPUT='{"session_id":"d","cwd":"/tmp","hook_event_name":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"CLAUDE.md","content":"x"},"tool_use_id":"d3"}'
printf '%s' "$INPUT" | CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" bash "$PLUGIN_DIR/hooks/enforce-kebab-case.sh"
echo "Exit: $?"
