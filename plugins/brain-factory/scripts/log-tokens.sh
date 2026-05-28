#!/usr/bin/env bash
set -euo pipefail

# log-tokens.sh
# Appends a JSONL token usage record to .brain/logs/ingest-tokens.jsonl.
#
# Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>
#
# All arguments are required. Pass -1 for token counts when unavailable.
#
# Exit codes:
#   0 — always (append succeeded)
#   Errors writing the log file do NOT fail silently; they propagate via set -e.

BRAIN_DIR="${1:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"
URL="${2:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"
SOURCE_ID="${3:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"
INPUT_TOKENS="${4:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"
OUTPUT_TOKENS="${5:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"
WIKI_PAGES_CREATED="${6:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"
DURATION_SECONDS="${7:?Usage: log-tokens.sh <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>}"

LOG_DIR="${BRAIN_DIR}/.brain/logs"
LOG_FILE="${LOG_DIR}/ingest-tokens.jsonl"

# Create log directory and file if they don't exist (AC-008)
mkdir -p "$LOG_DIR"

# Generate ISO 8601 UTC timestamp
TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build and append the JSONL record
# Use jq to construct valid JSON, ensuring all fields are properly typed
RECORD="$(jq -cn \
  --arg ts "$TIMESTAMP" \
  --arg url "$URL" \
  --arg source_id "$SOURCE_ID" \
  --argjson input_tokens "$INPUT_TOKENS" \
  --argjson output_tokens "$OUTPUT_TOKENS" \
  --argjson wiki_pages_created "$WIKI_PAGES_CREATED" \
  --argjson duration_seconds "$DURATION_SECONDS" \
  '{
    timestamp: $ts,
    url: $url,
    source_id: $source_id,
    input_tokens: $input_tokens,
    output_tokens: $output_tokens,
    wiki_pages_created: $wiki_pages_created,
    duration_seconds: $duration_seconds
  }')"

# Append atomically using >> (POSIX append is atomic for single writers)
printf '%s\n' "$RECORD" >>"$LOG_FILE"

exit 0
