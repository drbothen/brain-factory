#!/usr/bin/env bash
set -euo pipefail

# manifest-write.sh
# Sourced bash library — atomic manifest append helper.
# Requires BRAIN_DIR env var to be set by the calling skill.
#
# Usage (after sourcing):
#   manifest_write <entry_json> <manifest_path> [<event_type>]
#
# Returns 0 on success, 1 on failure (emits E-INGEST-008 on stderr).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/hook-event-emit.sh"

# manifest_write <entry_json> <manifest_path> [<event_type>]
#
# Inserts <entry_json> into the .sources object in <manifest_path> using the
# full relative path as the key (e.g. "sources/<topic>/<source_id>.md").
# ADR-015: manifest.sources is an object keyed by full relative source path.
# Writes atomically via a .tmp file then mv.
# Requires: BRAIN_DIR env var set (used for event context and call-site validation).
# Emits: <event_type> on stderr via emit_event (default: ingest.url.manifest_updated).
# The third argument allows callers such as STORY-019 (local source ingest) to
# emit ingest.source.manifest_updated instead.
manifest_write() {
  local entry_json="$1"
  local manifest_path="$2"
  local event_type="${3:-ingest.url.manifest_updated}"
  local tmp_path="${manifest_path}.tmp"

  # BRAIN_DIR is required for all production call sites.
  # Check this first so that unset BRAIN_DIR is detected before any write operations,
  # avoiding an inconsistent state where the manifest was mutated but the caller context
  # is invalid.
  if [ -z "${BRAIN_DIR:-}" ]; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: BRAIN_DIR is not set."}\n' >&2
    return 1
  fi

  # Validate entry JSON is parseable
  if ! printf '%s' "$entry_json" | jq -e '.' >/dev/null 2>&1; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: entry is not valid JSON."}\n' >&2
    return 1
  fi

  # Validate manifest exists
  if [ ! -f "$manifest_path" ]; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: manifest file not found at %s."}\n' \
      "$manifest_path" >&2
    return 1
  fi

  # Validate manifest is writable
  if [ ! -w "$manifest_path" ]; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: permission denied writing to %s."}\n' \
      "$manifest_path" >&2
    return 1
  fi

  # Derive the manifest key from the entry's topic and source_id fields.
  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local source_key
  source_key="sources/$(printf '%s' "$entry_json" | jq -r '.topic')/$(printf '%s' "$entry_json" | jq -r '.source_id').md"

  # Insert entry into the .sources object using the derived key.
  local updated
  if ! updated="$(jq --arg key "$source_key" --argjson entry "$entry_json" '.sources[$key] = $entry' "$manifest_path" 2>&1)"; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: %s"}\n' \
      "$updated" >&2
    return 1
  fi

  # Write to tmp file atomically, then mv to canonical path
  if ! printf '%s\n' "$updated" >"$tmp_path" 2>/dev/null; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: cannot write to %s."}\n' \
      "$tmp_path" >&2
    rm -f "$tmp_path"
    return 1
  fi

  if ! mv "$tmp_path" "$manifest_path" 2>/dev/null; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: cannot rename %s to %s."}\n' \
      "$tmp_path" "$manifest_path" >&2
    rm -f "$tmp_path"
    return 1
  fi

  # Extract source_id, topic, and url for event emission
  local source_id topic url
  source_id="$(printf '%s' "$entry_json" | jq -r '.source_id // "unknown"')"
  topic="$(printf '%s' "$entry_json" | jq -r '.topic // "unknown"')"
  url="$(printf '%s' "$entry_json" | jq -r '.url // "unknown"')"

  # Emit structured event with all catalog-declared fields.
  emit_event "$event_type" \
    "source_id=${source_id}" \
    "url=${url}" \
    "topic=${topic}" \
    "manifest_path=${manifest_path}"

  return 0
}
