#!/usr/bin/env bash
set -euo pipefail

# check-token-threshold.sh
# Estimates token count of a source file and emits an advisory warning if the
# estimated count exceeds the configured threshold (default: 50000).
#
# Usage: check-token-threshold.sh <brain_dir> <source_file_path>
#
# Exit codes:
#   0 — always (this script is advisory-only; it never blocks)
#
# Stdout: JSON object {"estimated_tokens": N, "threshold": T, "exceeds": true|false}
#         plus E-INGEST-009 advisory JSON when threshold exceeded
# Stderr: structured advisory event when threshold exceeded

BRAIN_DIR="${1:?Usage: check-token-threshold.sh <brain_dir> <source_file_path>}"
SOURCE_FILE="${2:?Usage: check-token-threshold.sh <brain_dir> <source_file_path>}"

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"

if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${BASH_SOURCE[0]##*/}" >&2
  exit 0
fi
# shellcheck source=/dev/null
source "$HELPER"

# Read threshold from policies.yaml or default to 50000
POLICIES_FILE="${BRAIN_DIR}/.brain/policies.yaml"
THRESHOLD=50000
if [ -f "$POLICIES_FILE" ]; then
  CONFIGURED="$(yq eval '.max_ingest_tokens_per_chunk // ""' "$POLICIES_FILE" 2>/dev/null || true)"
  if [ -n "$CONFIGURED" ] && [ "$CONFIGURED" != "null" ] && [ "$CONFIGURED" != '""' ]; then
    THRESHOLD="$CONFIGURED"
  fi
fi

# Extract body content (after YAML frontmatter) and count words
# Skip frontmatter: lines between the first and second '---' marker
BODY_WORDS=0
if [ -f "$SOURCE_FILE" ]; then
  BODY_WORDS="$(awk '
    BEGIN { in_frontmatter = 0; past_frontmatter = 0; fence_count = 0 }
    /^---$/ && fence_count < 2 {
      fence_count++
      if (fence_count == 1) { in_frontmatter = 1; next }
      if (fence_count == 2) { in_frontmatter = 0; past_frontmatter = 1; next }
    }
    past_frontmatter { print }
  ' "$SOURCE_FILE" | wc -w | tr -d ' ')"
fi

# Estimate tokens: word_count * 1.3 (integer arithmetic via awk)
ESTIMATED_TOKENS="$(awk -v words="$BODY_WORDS" 'BEGIN { printf "%d", words * 1.3 }')"

# Determine if threshold is exceeded (strictly greater)
EXCEEDS="false"
if [ "$ESTIMATED_TOKENS" -gt "$THRESHOLD" ]; then
  EXCEEDS="true"
fi

# Emit advisory warning when threshold exceeded
if [ "$EXCEEDS" = "true" ]; then
  ADVISORY_MSG="Source content estimated at ${ESTIMATED_TOKENS} tokens, exceeding the ${THRESHOLD}-token chunk threshold. Full content ingested in v0.1. Automatic chunking available at v0.5+. Consider splitting large sources manually."
  printf '{"level":"warn","code":"E-INGEST-009","message":"%s"}\n' "$ADVISORY_MSG"
  emit_event "ingest.url.token_threshold_exceeded" \
    "estimated_tokens=${ESTIMATED_TOKENS}" \
    "threshold=${THRESHOLD}" \
    "source_file=${SOURCE_FILE}"
fi

exit 0
