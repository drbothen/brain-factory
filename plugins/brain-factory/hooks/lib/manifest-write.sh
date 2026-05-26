#!/usr/bin/env bash
set -euo pipefail

# manifest-write.sh
# Sourced bash library — atomic manifest append helper.
# Requires BRAIN_DIR env var to be set by the calling skill.
#
# Usage (after sourcing):
#   manifest_write <entry_json> <manifest_path>
#
# Returns 0 on success, 1 on failure (emits E-INGEST-008 on stderr).

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/hook-event-emit.sh"

# manifest_write <entry_json> <manifest_path>
#
# Appends <entry_json> to the .sources array in <manifest_path>.
# Writes atomically via a .tmp file then mv.
# Requires: BRAIN_DIR env var set (used for event context and call-site validation).
# Emits: ingest.url.manifest_updated on stderr via emit_event.
manifest_write() {
  local entry_json="$1"
  local manifest_path="$2"
  local tmp_path="${manifest_path}.tmp"

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

  # Validate manifest is writable — check BEFORE referencing BRAIN_DIR
  # so that permission errors produce E-INGEST-008, not an unbound variable error.
  if [ ! -w "$manifest_path" ]; then
    printf '{"level":"error","code":"E-INGEST-008","message":"Failed to update manifest.json: permission denied writing to %s."}\n' \
      "$manifest_path" >&2
    return 1
  fi

  # Read current manifest and append new entry to .sources array
  local updated
  if ! updated="$(jq --argjson entry "$entry_json" '.sources += [$entry]' "$manifest_path" 2>&1)"; then
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

  # Extract source_id and topic for event emission
  local source_id topic
  source_id="$(printf '%s' "$entry_json" | jq -r '.source_id // "unknown"')"
  topic="$(printf '%s' "$entry_json" | jq -r '.topic // "unknown"')"

  # Emit structured event — happens BEFORE the BRAIN_DIR gate below, so that the
  # event always reaches stderr even when BRAIN_DIR is not set by the caller.
  emit_event "ingest.url.manifest_updated" \
    "source_id=${source_id}" \
    "topic=${topic}" \
    "manifest_path=${manifest_path}"

  # BRAIN_DIR is required for all production call sites.
  # This gate is intentionally LAST: write and event emission succeed first, then
  # fail fast to signal to the caller that BRAIN_DIR must be exported.
  # shellcheck disable=SC2153
  local _brain_dir_check="${BRAIN_DIR}"

  return 0
}
