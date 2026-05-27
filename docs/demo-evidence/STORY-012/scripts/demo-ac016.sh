#!/usr/bin/env bash
set -euo pipefail
PLUGIN_DIR="plugins/brain-factory"
shellcheck "$PLUGIN_DIR/hooks/enforce-kebab-case.sh" "$PLUGIN_DIR/hooks/block-ai-attribution.sh" && echo "shellcheck: PASS"
shfmt -d -i 2 "$PLUGIN_DIR/hooks/enforce-kebab-case.sh" "$PLUGIN_DIR/hooks/block-ai-attribution.sh" && echo "shfmt: PASS"
