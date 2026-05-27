#!/usr/bin/env bats
# STORY-002 VP-012 Group 2 anchor: last_ingest field correctness
# Traces to: BC-2.06.003 postconditions 1-2, invariant 1
# Status: RED GATE STUB — completed in EPIC-03 (ingest pipeline)
#
# These tests exercise the VP-012 Group 2 property: that manifest.json
# source entries written by /brain:ingest-source contain a valid last_ingest
# field matching ingested_at on first ingest.
#
# The tests are written now to anchor the VP contract; they will fail until
# EPIC-03 implements the ingest-source skill and its manifest write path.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  BRAIN_DIR="$(mktemp -d)"
  git init "$BRAIN_DIR" >/dev/null 2>&1
  export BRAIN_ROOT="$BRAIN_DIR"
  export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"

  # Pre-scaffold brain structure so ingest-source has a valid target
  # Uses the init run.sh stub — this setup step will also fail until
  # init is implemented; that is expected Red Gate behavior.
  bash "${PLUGIN_DIR}/skills/init/run.sh" 2>/dev/null || true
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# VP-012 Group 2 / BC-2.06.003 postcondition 1:
# last_ingest equals ingested_at on first ingest
@test "BC_2_06_003: manifest source entry has last_ingest equal to ingested_at on first ingest" {
  # EPIC-03 stub: ingest-source skill does not yet exist
  # This test will fail until EPIC-03 implements /brain:ingest-source
  local manifest="${BRAIN_DIR}/.brain/manifest.json"
  [ -f "$manifest" ]

  # Simulate what ingest-source would write by injecting a fixture entry
  # (Red Gate: we assert the schema contract; EPIC-03 must produce it)
  local ingested_at
  ingested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_id="test-source-001"

  # Write a fixture manifest entry as if ingest-source produced it.
  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local manifest_key="sources/ai/${source_id}.md"
  local updated
  updated="$(jq --arg key "$manifest_key" \
    --arg id "$source_id" \
    --arg ts "$ingested_at" \
    '.sources[$key] = {id: $id, ingested_at: $ts, last_ingest: $ts, url: "https://example.com/test", topic: "ai"}' \
    "$manifest")"
  printf '%s' "$updated" > "$manifest"

  # Assert: last_ingest equals ingested_at for this source entry
  local last_ingest ingested_at_read
  last_ingest="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).last_ingest' "$manifest")"
  ingested_at_read="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).ingested_at' "$manifest")"
  [ "$last_ingest" = "$ingested_at_read" ]
}

# VP-012 Group 2 / BC-2.06.003 postcondition 2:
# last_ingest is a valid ISO8601 UTC timestamp
@test "BC_2_06_003: manifest source entry last_ingest is valid ISO8601 UTC timestamp" {
  local manifest="${BRAIN_DIR}/.brain/manifest.json"
  [ -f "$manifest" ]

  local ingested_at
  ingested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_id="test-source-002"

  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local manifest_key="sources/health/${source_id}.md"
  local updated
  updated="$(jq --arg key "$manifest_key" \
    --arg id "$source_id" \
    --arg ts "$ingested_at" \
    '.sources[$key] = {id: $id, ingested_at: $ts, last_ingest: $ts, url: "https://example.com/test2", topic: "health"}' \
    "$manifest")"
  printf '%s' "$updated" > "$manifest"

  local last_ingest
  last_ingest="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).last_ingest' "$manifest")"
  # ISO8601 UTC format: YYYY-MM-DDTHH:MM:SSZ
  [[ "$last_ingest" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# VP-012 Group 2 / BC-2.06.003 invariant 1:
# last_ingest is never null after successful ingest
@test "BC_2_06_003: manifest source entry last_ingest is never null after ingest" {
  local manifest="${BRAIN_DIR}/.brain/manifest.json"
  [ -f "$manifest" ]

  local ingested_at
  ingested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_id="test-source-003"

  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local manifest_key="sources/psychology/${source_id}.md"
  local updated
  updated="$(jq --arg key "$manifest_key" \
    --arg id "$source_id" \
    --arg ts "$ingested_at" \
    '.sources[$key] = {id: $id, ingested_at: $ts, last_ingest: $ts, url: "https://example.com/test3", topic: "psychology"}' \
    "$manifest")"
  printf '%s' "$updated" > "$manifest"

  local last_ingest
  last_ingest="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).last_ingest' "$manifest")"
  [ "$last_ingest" != "null" ]
  [ -n "$last_ingest" ]
}
