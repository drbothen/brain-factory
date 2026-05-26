#!/usr/bin/env bats
# STORY-002 tests for /brain:init core scaffold
# Traces to: BC-2.01.001, BC-2.01.004, BC-2.06.003, BC-2.06.004
# Verification Properties: VP-014, VP-012 (Group 2 stub)

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  RUN_SH="${PLUGIN_DIR}/skills/init/run.sh"
  BRAIN_DIR="$(mktemp -d)"
  git init "$BRAIN_DIR" >/dev/null 2>&1
  export BRAIN_ROOT="$BRAIN_DIR"
  export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# ---------------------------------------------------------------------------
# AC-001 / BC-2.01.001 postcondition 1: source topic directories
# ---------------------------------------------------------------------------

@test "BC_2_01_001: init creates sources/ai directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/ai" ]
}

@test "BC_2_01_001: init creates sources/health directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/health" ]
}

@test "BC_2_01_001: init creates sources/psychology directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/psychology" ]
}

@test "BC_2_01_001: init creates sources/productivity directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/productivity" ]
}

@test "BC_2_01_001: init creates sources/business directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/business" ]
}

@test "BC_2_01_001: init creates sources/books directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/books" ]
}

@test "BC_2_01_001: init creates sources/podcasts directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/sources/podcasts" ]
}

# AC-001 / BC-2.01.001: wiki directories
@test "BC_2_01_001: init creates wiki/concepts directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/wiki/concepts" ]
}

@test "BC_2_01_001: init creates wiki/people directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/wiki/people" ]
}

@test "BC_2_01_001: init creates wiki/frameworks directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/wiki/frameworks" ]
}

@test "BC_2_01_001: init creates wiki/syntheses directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/wiki/syntheses" ]
}

@test "BC_2_01_001: init creates wiki/observations directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/wiki/observations" ]
}

@test "BC_2_01_001: init creates wiki/questions directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/wiki/questions" ]
}

# AC-001 / BC-2.01.001: briefs directories
@test "BC_2_01_001: init creates briefs/daily directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/briefs/daily" ]
}

@test "BC_2_01_001: init creates briefs/weekly directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/briefs/weekly" ]
}

@test "BC_2_01_001: init creates briefs/monthly directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/briefs/monthly" ]
}

@test "BC_2_01_001: init creates briefs/content directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/briefs/content" ]
}

@test "BC_2_01_001: init creates briefs/decisions directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/briefs/decisions" ]
}

# AC-001 / BC-2.01.001: infrastructure directories
@test "BC_2_01_001: init creates inbox directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/inbox" ]
}

@test "BC_2_01_001: init creates .brain/logs directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/.brain/logs" ]
}

@test "BC_2_01_001: init creates .github/workflows directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/.github/workflows" ]
}

@test "BC_2_01_001: init creates rules directory" {
  bash "$RUN_SH"
  [ -d "${BRAIN_DIR}/rules" ]
}

# ---------------------------------------------------------------------------
# AC-002 / BC-2.01.001 postcondition 1: required files exist
# ---------------------------------------------------------------------------

@test "BC_2_01_001: init creates .brain/manifest.json" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.brain/manifest.json" ]
}

@test "BC_2_01_001: init creates .brain/STATE.md" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.brain/STATE.md" ]
}

@test "BC_2_01_001: init creates .brain/policies.yaml" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.brain/policies.yaml" ]
}

@test "BC_2_01_001: init creates wiki/index.md" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/wiki/index.md" ]
}

@test "BC_2_01_001: init creates wiki/log.md" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/wiki/log.md" ]
}

@test "BC_2_01_001: init creates CLAUDE.md" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/CLAUDE.md" ]
}

@test "BC_2_01_001: init creates rules/voice-avoid-list.txt" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/rules/voice-avoid-list.txt" ]
}

# ---------------------------------------------------------------------------
# AC-003 / BC-2.01.004 postconditions 2-3: manifest.json canonical schema
# ---------------------------------------------------------------------------

@test "BC_2_01_004: manifest.json is valid JSON" {
  bash "$RUN_SH"
  jq . "${BRAIN_DIR}/.brain/manifest.json" >/dev/null
}

@test "BC_2_01_004: manifest.json has version field equal to 1" {
  bash "$RUN_SH"
  local version
  version="$(jq -r '.version' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$version" = "1" ]
}

@test "BC_2_01_004: manifest.json has empty sources object" {
  bash "$RUN_SH"
  local sources
  sources="$(jq '.sources' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$sources" = "{}" ]
}

@test "BC_2_01_004: manifest.json has embeddings_model null" {
  bash "$RUN_SH"
  local model
  model="$(jq '.embeddings_model' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$model" = "null" ]
}

@test "BC_2_01_004: manifest.json has empty chunks array" {
  bash "$RUN_SH"
  local chunks
  chunks="$(jq '.chunks' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$chunks" = "[]" ]
}

@test "BC_2_01_004: manifest.json has last_updated field" {
  bash "$RUN_SH"
  local last_updated
  last_updated="$(jq -r '.last_updated' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$last_updated" != "null" ]
  [ -n "$last_updated" ]
}

@test "BC_2_01_004: manifest.json last_updated is ISO8601 format" {
  bash "$RUN_SH"
  local last_updated
  last_updated="$(jq -r '.last_updated' "${BRAIN_DIR}/.brain/manifest.json")"
  # ISO8601 UTC: YYYY-MM-DDTHH:MM:SSZ
  [[ "$last_updated" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# ---------------------------------------------------------------------------
# AC-004 / BC-2.01.001 postcondition 1: policies.yaml with 10 entries
# ---------------------------------------------------------------------------

@test "BC_2_01_001: policies.yaml has exactly 10 baseline policies" {
  bash "$RUN_SH"
  local count
  count="$(yq eval '.policies | length' "${BRAIN_DIR}/.brain/policies.yaml")"
  [ "$count" -eq 10 ]
}

# ---------------------------------------------------------------------------
# AC-005 / BC-2.01.004 postcondition 1: embedding_status: pending in wiki templates
# ---------------------------------------------------------------------------

@test "BC_2_01_004: wiki concepts template has embedding_status pending" {
  bash "$RUN_SH"
  local target
  target="$(find "${BRAIN_DIR}/wiki/concepts" -name '*.md' | head -1)"
  [ -n "$target" ]
  local status
  status="$(yq eval '.embedding_status' "$target")"
  [ "$status" = "pending" ]
}

@test "BC_2_01_004: wiki people template has embedding_status pending" {
  bash "$RUN_SH"
  local target
  target="$(find "${BRAIN_DIR}/wiki/people" -name '*.md' | head -1)"
  [ -n "$target" ]
  local status
  status="$(yq eval '.embedding_status' "$target")"
  [ "$status" = "pending" ]
}

@test "BC_2_01_004: wiki frameworks template has embedding_status pending" {
  bash "$RUN_SH"
  local target
  target="$(find "${BRAIN_DIR}/wiki/frameworks" -name '*.md' | head -1)"
  [ -n "$target" ]
  local status
  status="$(yq eval '.embedding_status' "$target")"
  [ "$status" = "pending" ]
}

@test "BC_2_01_004: wiki syntheses template has embedding_status pending" {
  bash "$RUN_SH"
  local target
  target="$(find "${BRAIN_DIR}/wiki/syntheses" -name '*.md' | head -1)"
  [ -n "$target" ]
  local status
  status="$(yq eval '.embedding_status' "$target")"
  [ "$status" = "pending" ]
}

@test "BC_2_01_004: wiki observations template has embedding_status pending" {
  bash "$RUN_SH"
  local target
  target="$(find "${BRAIN_DIR}/wiki/observations" -name '*.md' | head -1)"
  [ -n "$target" ]
  local status
  status="$(yq eval '.embedding_status' "$target")"
  [ "$status" = "pending" ]
}

@test "BC_2_01_004: wiki questions template has embedding_status pending" {
  bash "$RUN_SH"
  local target
  target="$(find "${BRAIN_DIR}/wiki/questions" -name '*.md' | head -1)"
  [ -n "$target" ]
  local status
  status="$(yq eval '.embedding_status' "$target")"
  [ "$status" = "pending" ]
}

# ---------------------------------------------------------------------------
# AC-006 / BC-2.06.004 postconditions 1-2: 7 source topic directories
# ---------------------------------------------------------------------------

@test "BC_2_06_004: exactly 7 source topic directories exist" {
  bash "$RUN_SH"
  local count
  count="$(find "${BRAIN_DIR}/sources" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  [ "$count" -eq 7 ]
}

@test "BC_2_06_004: all 7 source topic directories are initially empty" {
  bash "$RUN_SH"
  local nonempty
  nonempty="$(find "${BRAIN_DIR}/sources" -mindepth 2 -type f | wc -l | tr -d ' ')"
  [ "$nonempty" -eq 0 ]
}

# ---------------------------------------------------------------------------
# AC-007 / BC-2.01.001 postcondition 2: CLAUDE.md sourced from template
# ---------------------------------------------------------------------------

@test "BC_2_01_001: CLAUDE.md is non-empty" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/CLAUDE.md" ]
  [ -s "${BRAIN_DIR}/CLAUDE.md" ]
}

# ---------------------------------------------------------------------------
# AC-008 / BC-2.01.001 postcondition 1: 6 GitHub Action workflow files
# ---------------------------------------------------------------------------

@test "BC_2_01_001: daily-brain.yml workflow file exists" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.github/workflows/daily-brain.yml" ]
}

@test "BC_2_01_001: weekly-brain.yml workflow file exists" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.github/workflows/weekly-brain.yml" ]
}

@test "BC_2_01_001: ingest-rss.yml workflow file exists" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.github/workflows/ingest-rss.yml" ]
}

@test "BC_2_01_001: ingest-bookmarks.yml workflow file exists" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.github/workflows/ingest-bookmarks.yml" ]
}

@test "BC_2_01_001: brain-health-check.yml workflow file exists" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.github/workflows/brain-health-check.yml" ]
}

@test "BC_2_01_001: adversary-review.yml workflow file exists" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/.github/workflows/adversary-review.yml" ]
}

# ---------------------------------------------------------------------------
# AC-009 / BC-2.01.001 postcondition 1: voice-avoid-list.txt with 30 entries
# ---------------------------------------------------------------------------

@test "BC_2_01_001: voice-avoid-list.txt has exactly 30 entries" {
  bash "$RUN_SH"
  [ -f "${BRAIN_DIR}/rules/voice-avoid-list.txt" ]
  local count
  count="$(wc -l < "${BRAIN_DIR}/rules/voice-avoid-list.txt" | tr -d ' ')"
  [ "$count" -eq 30 ]
}

@test "BC_2_01_001: voice-avoid-list.txt has no blank lines" {
  bash "$RUN_SH"
  local blank_count
  blank_count="$(grep -c '^$' "${BRAIN_DIR}/rules/voice-avoid-list.txt" || true)"
  [ "$blank_count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# AC-011 / BC-2.01.001 invariant 1: plugin directory not modified during init
# ---------------------------------------------------------------------------

@test "BC_2_01_001: plugin directory not modified during init (no files newer than run.sh after run)" {
  # Record modification time of run.sh as reference point
  local before_snapshot
  before_snapshot="$(find "${PLUGIN_DIR}" -type f -newer "${PLUGIN_DIR}/skills/init/run.sh" | sort)"
  bash "$RUN_SH"
  local after_snapshot
  after_snapshot="$(find "${PLUGIN_DIR}" -type f -newer "${PLUGIN_DIR}/skills/init/run.sh" | sort)"
  # No new plugin files should have been created or modified during init
  [ "$before_snapshot" = "$after_snapshot" ]
}

# ---------------------------------------------------------------------------
# AC-012 / BC-2.01.001 invariant 2: no hardcoded .claude/templates paths
# ---------------------------------------------------------------------------

@test "BC_2_01_001: run.sh uses CLAUDE_PLUGIN_ROOT not hardcoded .claude/templates paths" {
  local count
  count="$(grep -c '\.claude/templates' "${RUN_SH}" || true)"
  [ "$count" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Lint quality / BC-2.01.001 architecture compliance
# ---------------------------------------------------------------------------

@test "BC_2_01_001: init prints success confirmation with brain root path" {
  run bash "$RUN_SH"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Brain initialized"* ]]
  [[ "$output" == *"${BRAIN_DIR}"* ]]
}

# ---------------------------------------------------------------------------
# BC-2.01.001 EC-004: missing CLAUDE_PLUGIN_ROOT exits 2 with structured error
# ---------------------------------------------------------------------------

@test "BC_2_01_001: missing CLAUDE_PLUGIN_ROOT exits 2" {
  run env -u CLAUDE_PLUGIN_ROOT bash "$RUN_SH"
  [ "$status" -eq 2 ]
}

@test "BC_2_01_001: missing CLAUDE_PLUGIN_ROOT emits E-INIT-004 error code" {
  run env -u CLAUDE_PLUGIN_ROOT bash "$RUN_SH"
  [[ "$output" == *"E-INIT-004"* ]]
}

# ---------------------------------------------------------------------------
# Lint quality / BC-2.01.001 architecture compliance
# ---------------------------------------------------------------------------

@test "BC_2_01_001: run.sh passes shellcheck" {
  run shellcheck "${RUN_SH}"
  [ "$status" -eq 0 ]
}

@test "BC_2_01_001: run.sh passes shfmt normalization check" {
  run shfmt -d -i 2 "${RUN_SH}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}
