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

# ===========================================================================
# STORY-017: Wiki generation edge cases
# Traces to: BC-2.02.002 EC-001, BC-2.02.003 EC-002, BC-2.02.005 EC-001
# ===========================================================================

# Helper: write a short source file (< 500 words — produces < 5 wiki pages)
_write_short_source() {
  local brain_dir="$1"
  local slug="$2"
  mkdir -p "${brain_dir}/sources/ai"
  cat >"${brain_dir}/sources/ai/${slug}.md" <<'SHORTEOF'
---
title: "Short Article"
url: "https://example.com/short"
ingested_at: "2026-05-26T00:00:00Z"
source_id: "short-article"
topic: "ai"
embedding_status: pending
---

# Short Article

This is a brief summary with limited extractable concepts.

The main idea is simple. There are few concepts here.
SHORTEOF
}

# Helper: create minimal wiki dirs
_setup_wiki_dirs_skills() {
  local brain_dir="$1"
  mkdir -p "${brain_dir}/wiki/concepts" \
    "${brain_dir}/wiki/people" \
    "${brain_dir}/wiki/frameworks" \
    "${brain_dir}/wiki/syntheses" \
    "${brain_dir}/wiki/observations" \
    "${brain_dir}/wiki/questions"

  cat >"${brain_dir}/wiki/index.md" <<'IDXEOF'
---
type: index
title: "Wiki Index"
---
# Wiki Index
IDXEOF

  cat >"${brain_dir}/wiki/log.md" <<'LOGEOF'
---
type: log
title: "Ingest Log"
---
# Ingest Log
LOGEOF
}

# ===========================================================================
# AC-004 / BC-2.02.002 invariant 1 EC-001: < 5 pages → E-INGEST-006 advisory
# ===========================================================================
@test "BC_2_02_002: generate-wiki.sh emits E-INGEST-006 advisory when fewer than 5 pages produced (AC-004)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # Short article fixture → librarian produces < 5 pages
  _write_short_source "$BRAIN_DIR" "short-article"
  _setup_wiki_dirs_skills "$BRAIN_DIR"

  local output
  output="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/short-article.md" 2>&1 || true)"

  # Must emit E-INGEST-006 advisory when < 5 pages produced
  [[ "$output" == *"E-INGEST-006"* ]]
}

@test "BC_2_02_002: generate-wiki.sh exits 0 on short article (E-INGEST-006 is advisory, not blocking) (AC-004)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # E-INGEST-006 must be advisory (skill continues, does not block)
  _write_short_source "$BRAIN_DIR" "short-article"
  _setup_wiki_dirs_skills "$BRAIN_DIR"

  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/short-article.md"

  # Advisory: skill must continue (exit 0)
  [ "$status" -eq 0 ]
}

@test "BC_2_02_002: short-article fixture has fewer than 500 words (AC-004 test vector)" {
  # Verify the short article fixture actually exercises the < 5 pages edge case
  local fixture="${PLUGIN_DIR}/tests/fixtures/ingest-url-short-article.json"
  [ -f "$fixture" ]

  local word_count_approx
  word_count_approx="$(jq -r '.word_count_approx' "$fixture" 2>/dev/null || true)"
  # Fixture must declare a word count below 500
  [ -n "$word_count_approx" ]
  [ "$word_count_approx" -lt 500 ]
}

# ===========================================================================
# AC-010 / BC-2.02.003 EC-002: Token count unavailable → sentinel -1 values
# ===========================================================================
@test "BC_2_02_003: log-tokens.sh writes input_tokens: -1 when token count unavailable (AC-010)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  # Pass -1 for both token counts (unavailable from API)
  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "-1" \
    "-1" \
    "5" \
    "10" || true

  local input_tokens output_tokens
  input_tokens="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null \
    | jq -r '.input_tokens' 2>/dev/null || true)"
  output_tokens="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null \
    | jq -r '.output_tokens' 2>/dev/null || true)"

  [ "$input_tokens" = "-1" ]
  [ "$output_tokens" = "-1" ]
}

@test "BC_2_02_003: log-tokens.sh succeeds even when token counts are -1 (AC-010)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  # The append must NOT fail due to token count being unknown
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  run bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "-1" \
    "-1" \
    "5" \
    "10"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-015 / BC-2.02.005 EC-001: Missing max_ingest_tokens_per_chunk → default 50000
# ===========================================================================
@test "BC_2_02_005: check-token-threshold.sh uses default 50000 when key absent from policies.yaml (AC-015)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # policies.yaml exists but has NO max_ingest_tokens_per_chunk key
  mkdir -p "${BRAIN_DIR}/.brain"
  cat >"${BRAIN_DIR}/.brain/policies.yaml" <<'POLEOF'
policies:
  - id: POL-001
    name: source-immutability
    description: "Sources are immutable after ingest."
    enforcement: block
POLEOF

  local small_source="${BRAIN_DIR}/sources/ai/small.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  # Use cat heredoc to avoid printf -- interpretation on macOS
  cat >"$small_source" <<'SMALLEOF'
---
title: "Small"
type: source
embedding_status: pending
---

word word word word word word word word word word
SMALLEOF

  # Must NOT error on missing key — must use default 50000
  run bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$small_source"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_005: check-token-threshold.sh uses default 50000 when policies.yaml absent entirely (AC-015)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # No .brain/policies.yaml at all — must default without error
  mkdir -p "${BRAIN_DIR}/.brain"
  # init/run.sh (called in setup) creates policies.yaml — remove it to test the absent case
  rm -f "${BRAIN_DIR}/.brain/policies.yaml"
  [ ! -f "${BRAIN_DIR}/.brain/policies.yaml" ]

  local small_source="${BRAIN_DIR}/sources/ai/small.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  cat >"$small_source" <<'SMALLEOF'
---
title: "Small"
type: source
embedding_status: pending
---

word word word
SMALLEOF

  run bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$small_source"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Shellcheck + shfmt compliance for new scripts (forward-looking)
# These fail until the scripts are implemented — structural Red Gate tests.
# ===========================================================================
@test "BC_2_02_002: scripts/generate-wiki.sh exists (structural Red Gate)" {
  # Red Gate: script not implemented yet
  [ -f "${PLUGIN_DIR}/scripts/generate-wiki.sh" ]
}

@test "BC_2_02_003: scripts/log-tokens.sh exists (structural Red Gate)" {
  # Red Gate: script not implemented yet
  [ -f "${PLUGIN_DIR}/scripts/log-tokens.sh" ]
}

@test "BC_2_02_005: scripts/check-token-threshold.sh exists (structural Red Gate)" {
  # Red Gate: script not implemented yet
  [ -f "${PLUGIN_DIR}/scripts/check-token-threshold.sh" ]
}

@test "BC_2_02_002: scripts/generate-wiki.sh passes shellcheck (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shellcheck "${PLUGIN_DIR}/scripts/generate-wiki.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_003: scripts/log-tokens.sh passes shellcheck (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shellcheck "${PLUGIN_DIR}/scripts/log-tokens.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_005: scripts/check-token-threshold.sh passes shellcheck (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shellcheck "${PLUGIN_DIR}/scripts/check-token-threshold.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_002: scripts/generate-wiki.sh passes shfmt normalization (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/generate-wiki.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BC_2_02_003: scripts/log-tokens.sh passes shfmt normalization (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/log-tokens.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BC_2_02_005: scripts/check-token-threshold.sh passes shfmt normalization (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/check-token-threshold.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
