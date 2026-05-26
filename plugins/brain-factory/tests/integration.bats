#!/usr/bin/env bats
# STORY-027 integration tests for init publishing scaffold
# Traces to: BC-2.09.005, BC-2.08.004, VP-020

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  AVOID_LIST_TEMPLATE="${PLUGIN_DIR}/rules/voice-avoid-list.txt"
  # Create a temp brain directory for each test
  BRAIN_DIR="$(mktemp -d)"
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# Helper: simulate what /brain:init does for publishing scaffold
# This extracts the init logic into a testable function
_run_init_publishing_scaffold() {
  local brain_dir="$1"
  local plugin_dir="$2"

  # Publishing directories (AC-001, AC-002)
  mkdir -p "${brain_dir}/drafts/linkedin" \
    "${brain_dir}/to-publish/linkedin" \
    "${brain_dir}/published/linkedin"

  # Voice avoid-list (AC-004, AC-005)
  mkdir -p "${brain_dir}/rules"
  if [[ ! -f "${brain_dir}/rules/voice-avoid-list.txt" ]]; then
    cp "${plugin_dir}/rules/voice-avoid-list.txt" "${brain_dir}/rules/voice-avoid-list.txt"
  fi
}

# AC-001 / BC-2.09.005: publishing directories created
@test "BC_2_09_005: init creates drafts/linkedin, to-publish/linkedin, published/linkedin" {
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  [ -d "${BRAIN_DIR}/drafts/linkedin" ]
  [ -d "${BRAIN_DIR}/to-publish/linkedin" ]
  [ -d "${BRAIN_DIR}/published/linkedin" ]
}

# AC-005 / BC-2.08.004: voice-avoid-list has exactly 30 entries
@test "BC_2_08_004: voice-avoid-list.txt has exactly 30 entries" {
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  [ -f "${BRAIN_DIR}/rules/voice-avoid-list.txt" ]
  local count
  count="$(wc -l < "${BRAIN_DIR}/rules/voice-avoid-list.txt" | tr -d ' ')"
  [ "$count" -eq 30 ]
}

# AC-005 / BC-2.08.004: no blank lines in avoid-list
@test "BC_2_08_004: voice-avoid-list.txt has no blank lines" {
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  local blank_count
  blank_count="$(grep -c '^$' "${BRAIN_DIR}/rules/voice-avoid-list.txt" || true)"
  [ "$blank_count" -eq 0 ]
}

# AC-007 / BC-2.08.004: idempotent — no overwrite of existing avoid-list
@test "BC_2_08_004: init does not overwrite existing voice-avoid-list" {
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  # Write custom content
  echo "my-custom-term" > "${BRAIN_DIR}/rules/voice-avoid-list.txt"
  # Re-run init
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  # Custom content preserved
  local content
  content="$(cat "${BRAIN_DIR}/rules/voice-avoid-list.txt")"
  [ "$content" = "my-custom-term" ]
}

# AC-003 / BC-2.09.005: idempotent — no overwrite of existing publishing dirs
@test "BC_2_09_005: init does not delete files in existing publishing dirs" {
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  # Place a file in drafts/linkedin/
  echo "test draft" > "${BRAIN_DIR}/drafts/linkedin/test-draft.md"
  # Re-run init
  _run_init_publishing_scaffold "$BRAIN_DIR" "$PLUGIN_DIR"
  # File still present
  [ -f "${BRAIN_DIR}/drafts/linkedin/test-draft.md" ]
  local content
  content="$(cat "${BRAIN_DIR}/drafts/linkedin/test-draft.md")"
  [ "$content" = "test draft" ]
}

# AC-004: template file exists in plugin with exactly 30 entries
@test "BC_2_08_004: voice-avoid-list.txt template exists in plugin rules/ with 30 entries" {
  [ -f "$AVOID_LIST_TEMPLATE" ]
  local count
  count="$(wc -l < "$AVOID_LIST_TEMPLATE" | tr -d ' ')"
  [ "$count" -eq 30 ]
}
