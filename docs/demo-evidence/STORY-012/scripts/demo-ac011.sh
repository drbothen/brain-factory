#!/usr/bin/env bash
set -euo pipefail
PLUGIN_DIR="plugins/brain-factory"
INPUT=$(jq -cn --arg cmd 'git commit -m "feat: add" --trailer "Co-Authored-By: Claude Opus"' \
  '{"session_id":"d","cwd":"/tmp","hook_event_name":"PreToolUse","tool_name":"Bash","tool_input":{"command":$cmd,"description":"t"},"tool_use_id":"d5"}')
printf '%s' "$INPUT" | CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" bash "$PLUGIN_DIR/hooks/block-ai-attribution.sh" || true
echo "Exit: $?"
