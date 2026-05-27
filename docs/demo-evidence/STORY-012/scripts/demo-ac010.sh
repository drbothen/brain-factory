#!/usr/bin/env bash
set -euo pipefail
PLUGIN_DIR="plugins/brain-factory"
INPUT='{"session_id":"d","cwd":"/tmp","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":"git commit -m \"feat: add feature\"","description":"t"},"tool_use_id":"d4"}'
printf '%s' "$INPUT" | CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" bash "$PLUGIN_DIR/hooks/block-ai-attribution.sh"
echo "Exit: $?"
