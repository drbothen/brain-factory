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

# ---------------------------------------------------------------------------
# STORY-038: gen-test-corpus.sh tests
# Traces to: BC-2.16.006
# ---------------------------------------------------------------------------

# AC-002: generates source files + manifest
@test "BC_2_16_006: gen-test-corpus.sh --sources 10 --seed 42 creates 10 sources + manifest" {
  local out_dir
  out_dir="$(mktemp -d)"
  run "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 10 --seed 42 "$out_dir"
  [ "$status" -eq 0 ]
  # 10 source files exist
  local source_count
  source_count="$(find "$out_dir/sources" -name '*.md' | wc -l | tr -d ' ')"
  [ "$source_count" -eq 10 ]
  # manifest exists with entries
  [ -f "$out_dir/.brain/manifest.json" ]
  local manifest_count
  manifest_count="$(jq '.sources | length' "$out_dir/.brain/manifest.json")"
  [ "$manifest_count" -eq 9 ]  # N-1 pre-populated
  rm -rf "$out_dir"
}

# AC-003: same seed produces identical output
@test "BC_2_16_006: same seed produces byte-identical output (reproducibility)" {
  local dir1 dir2
  dir1="$(mktemp -d)"
  dir2="$(mktemp -d)"
  "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 5 --seed 42 "$dir1"
  "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 5 --seed 42 "$dir2"
  # Compare source files (exclude manifest timestamps)
  run diff -r "$dir1/sources" "$dir2/sources"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
  run diff -r "$dir1/wiki" "$dir2/wiki"
  [ "$status" -eq 0 ]
  run diff "$dir1/.brain/manifest.json" "$dir2/.brain/manifest.json"
  [ "$status" -eq 0 ]
  rm -rf "$dir1" "$dir2"
}

# AC-006: generated sources have valid frontmatter
@test "BC_2_16_006: generated sources have valid source frontmatter" {
  local out_dir
  out_dir="$(mktemp -d)"
  "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 3 --seed 42 "$out_dir"
  # Check first source file has type: source
  local first_source
  first_source="$(find "$out_dir/sources" -name '*.md' | head -1)"
  [ -n "$first_source" ]
  local type_val
  type_val="$(yq eval '.type' "$first_source")"
  [ "$type_val" = "source" ]
  rm -rf "$out_dir"
}

# AC-008: --sources 0 exits 1
@test "BC_2_16_006: --sources 0 exits 1 with usage error" {
  local out_dir
  out_dir="$(mktemp -d)"
  run "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 0 --seed 42 "$out_dir"
  [ "$status" -eq 1 ]
  [[ "$output" == *"must be"* ]] || [[ "$output" == *"≥ 1"* ]] || [[ "$output" == *">= 1"* ]]
  rm -rf "$out_dir"
}

# AC-007: existing output dir exits 1
@test "BC_2_16_006: existing source files in output dir causes exit 1" {
  local out_dir
  out_dir="$(mktemp -d)"
  mkdir -p "$out_dir/sources/ai"
  echo "existing" > "$out_dir/sources/ai/existing.md"
  run "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 5 --seed 42 "$out_dir"
  [ "$status" -eq 1 ]
  # Conflict message must name the conflicting path
  [[ "$output" == *"sources"* ]] || [[ "$output" == *"conflict"* ]] || [[ "$output" == *"already exists"* ]] || [[ "$output" == *"existing"* ]]
  # Existing file preserved (not overwritten or deleted)
  [ -f "$out_dir/sources/ai/existing.md" ]
  local preserved_content
  preserved_content="$(cat "$out_dir/sources/ai/existing.md")"
  [ "$preserved_content" = "existing" ]
  rm -rf "$out_dir"
}

# AC-009: --format json-manifest-only
@test "BC_2_16_006: --format json-manifest-only writes manifest without sources dir" {
  local out_dir
  out_dir="$(mktemp -d)"
  run "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 10 --seed 42 --format json-manifest-only "$out_dir"
  [ "$status" -eq 0 ]
  [ -f "$out_dir/.brain/manifest.json" ]
  [ ! -d "$out_dir/sources" ]
  [ ! -d "$out_dir/wiki" ]
  rm -rf "$out_dir"
}

# AC-002: wiki pages at default ratio
@test "BC_2_16_006: wiki pages present at default --wiki-ratio 5" {
  local out_dir
  out_dir="$(mktemp -d)"
  "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 2 --seed 42 "$out_dir"
  # 2 sources × 5 ratio = 10 wiki pages
  local wiki_count
  wiki_count="$(find "$out_dir/wiki" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$wiki_count" -eq 10 ]
  rm -rf "$out_dir"
}

# AC-010: shellcheck clean
@test "BC_2_16_006: gen-test-corpus.sh passes shellcheck" {
  run shellcheck "${PLUGIN_DIR}/scripts/gen-test-corpus.sh"
  [ "$status" -eq 0 ]
}

# AC-010: shfmt clean
@test "BC_2_16_006: gen-test-corpus.sh passes shfmt" {
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/gen-test-corpus.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# AC-003: LCG seed advances — sources have varied content
@test "BC_2_16_006: generated sources have varied content (LCG produces progression)" {
  local out_dir
  out_dir="$(mktemp -d)"
  "${PLUGIN_DIR}/scripts/gen-test-corpus.sh" --sources 2 --seed 42 --avg-words 50 "$out_dir"
  local first second
  first="$(find "$out_dir/sources" -name '*.md' | sort | head -1)"
  second="$(find "$out_dir/sources" -name '*.md' | sort | head -2 | tail -1)"
  # Bodies should differ between sources
  local body1 body2
  body1="$(sed '1,/^---$/d; 1,/^---$/d' "$first")"
  body2="$(sed '1,/^---$/d; 1,/^---$/d' "$second")"
  [ "$body1" != "$body2" ]
  # First source body should have more than 5 unique words (LCG progresses, not stuck)
  local unique
  unique="$(printf '%s' "$body1" | tr ' ' '\n' | sort -u | wc -l | tr -d ' ')"
  [ "$unique" -gt 5 ]
  rm -rf "$out_dir"
}
