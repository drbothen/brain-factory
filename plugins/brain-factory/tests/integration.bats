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

# ---------------------------------------------------------------------------
# STORY-003: init error handling, SLA assertion, briefs/research/ scaffold
# Traces to: BC-2.01.003, BC-2.01.005, BC-2.01.002
# ---------------------------------------------------------------------------

# Helper: create a minimal git repo (non-bare) with no .brain/ conflict
_make_git_dir() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  printf '%s' "$d"
}

# Helper: build a flat symlink directory containing every command on the current
# PATH EXCEPT the excluded one.  Returns the directory path.
#
# Rationale: _path_without removed entire directories, which on ubuntu-latest
# strips co-located tools (git, bash, node all live in /usr/bin/ alongside jq).
# A flat symlink dir avoids that: only the target command is absent.
_make_restricted_path() {
  local exclude="$1"
  local rdir
  rdir="$(mktemp -d)"
  local IFS=':'
  local dir cmd_path name
  for dir in $PATH; do
    [[ -d "$dir" ]] || continue
    for cmd_path in "$dir"/*; do
      [[ -x "$cmd_path" ]] || continue
      name="${cmd_path##*/}"
      [[ "$name" = "$exclude" ]] && continue
      # First directory wins (mirrors PATH precedence); don't clobber.
      [[ -e "${rdir}/${name}" ]] && continue
      ln -sf "$cmd_path" "${rdir}/${name}"
    done
  done
  printf '%s' "$rdir"
}

# AC-003 / BC-2.01.003: rejects non-git directory with E-INIT-001
@test "BC_2_01_003: rejects non-git directory with E-INIT-001 exit 2" {
  local non_git_dir
  non_git_dir="$(mktemp -d)"
  run env BRAIN_ROOT="$non_git_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-001
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-001" ]
  # No files created in the target dir (only the temp dir itself exists)
  local file_count
  file_count="$(find "$non_git_dir" -mindepth 1 | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$non_git_dir"
}

# AC-004 / BC-2.01.003: rejects existing .brain/ with E-INIT-002
@test "BC_2_01_003: rejects existing .brain/ with E-INIT-002 exit 2" {
  local brain_dir
  brain_dir="$(_make_git_dir)"
  mkdir -p "${brain_dir}/.brain"
  run env BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-002
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-002" ]
  # .brain/ must still exist but no new files added
  [ -d "${brain_dir}/.brain" ]
  local file_count
  file_count="$(find "${brain_dir}/.brain" -mindepth 1 | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$brain_dir"
}

# AC-006 / BC-2.01.003: rejects bare git repo with E-INIT-007
@test "BC_2_01_003: rejects bare git repo with E-INIT-007 exit 2" {
  local bare_dir
  bare_dir="$(mktemp -d)"
  git -C "$bare_dir" init -q --bare
  run env BRAIN_ROOT="$bare_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-007
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-007" ]
  # AC-007: No files created (bare repo dir contains git objects, not brain files)
  local file_count
  file_count="$(find "$bare_dir" -mindepth 1 -not -path '*HEAD' -not -path '*/objects*' -not -path '*/refs*' -not -path '*/info*' -not -path '*/hooks*' -not -path '*/config' -not -path '*/description' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$bare_dir"
}

# AC-008 check-order / BC-2.01.003: absent node produces E-INIT-003
# Uses a fake-bin approach: prepend a dir containing a stub node that exits 127,
# so that jq/yq (in their real bin dirs) remain discoverable.
@test "BC_2_01_003: node absent produces E-INIT-003 exit 2" {
  local brain_dir fake_bin
  brain_dir="$(_make_git_dir)"
  fake_bin="$(mktemp -d)"
  # Stub node: exits 127 (command not found equivalent)
  printf '#!/usr/bin/env bash\nexit 127\n' > "${fake_bin}/node"
  chmod +x "${fake_bin}/node"
  run env PATH="${fake_bin}:${PATH}" \
    BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  rm -rf "$fake_bin"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-003
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-003" ]
  # No brain files created
  local file_count
  file_count="$(find "$brain_dir" -mindepth 1 -not -path '*/.git*' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$brain_dir"
}

# AC-003 / BC-2.01.003: node present but version < 22 produces E-INIT-003
@test "BC_2_01_003: node version < 22 produces E-INIT-003 exit 2" {
  local brain_dir fake_bin
  brain_dir="$(_make_git_dir)"
  fake_bin="$(mktemp -d)"
  printf '#!/usr/bin/env bash\necho "v20.0.0"\n' > "${fake_bin}/node"
  chmod +x "${fake_bin}/node"
  run env PATH="${fake_bin}:${PATH}" \
    BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  rm -rf "$fake_bin" "$brain_dir"
  [ "$status" -eq 2 ]
  local err_code
  err_code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$err_code" = "E-INIT-003" ]
}

# AC-008 check-order / BC-2.01.003: absent jq produces E-INIT-006
# jq is checked before node (check order: CLAUDE_PLUGIN_ROOT, jq/yq, node, git-repo, ...)
# Uses _make_restricted_path (flat symlink dir) so co-located tools like git/node
# remain discoverable — avoids the directory-removal problem on ubuntu-latest.
@test "BC_2_01_003: jq absent produces E-INIT-006 exit 2" {
  local brain_dir rdir
  brain_dir="$(_make_git_dir)"
  rdir="$(_make_restricted_path jq)"
  run env PATH="$rdir" \
    BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  rm -rf "$rdir"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-006
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-006" ]
  # No brain files created
  local file_count
  file_count="$(find "$brain_dir" -mindepth 1 -not -path '*/.git*' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$brain_dir"
}

# AC-005 / BC-2.01.003: conflicting wiki/ produces E-INIT-005
@test "BC_2_01_003: conflicting wiki/ produces E-INIT-005 exit 2" {
  local brain_dir
  brain_dir="$(_make_git_dir)"
  mkdir -p "${brain_dir}/wiki"
  run env BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-005
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-005" ]
  # Only the pre-existing wiki/ dir exists; no additional files created
  local file_count
  file_count="$(find "$brain_dir" -mindepth 1 -not -path '*/.git*' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 1 ]
  rm -rf "$brain_dir"
}

# AC-005 / BC-2.01.003: conflicting sources/ produces E-INIT-005
@test "BC_2_01_003: conflicting sources/ produces E-INIT-005 exit 2" {
  local brain_dir
  brain_dir="$(_make_git_dir)"
  mkdir -p "${brain_dir}/sources"
  run env BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-005
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-005" ]
  # Only the pre-existing sources/ dir exists; no additional files created
  local file_count
  file_count="$(find "$brain_dir" -mindepth 1 -not -path '*/.git*' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 1 ]
  rm -rf "$brain_dir"
}

# AC-004 / BC-2.01.003: missing CLAUDE_PLUGIN_ROOT produces E-INIT-004
@test "BC_2_01_003: missing CLAUDE_PLUGIN_ROOT produces E-INIT-004 exit 2" {
  local brain_dir
  brain_dir="$(_make_git_dir)"
  run env BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="/nonexistent/path/brain-factory" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-004
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-004" ]
  # CLAUDE_PLUGIN_ROOT check fires before any I/O — no brain files created
  local file_count
  file_count="$(find "$brain_dir" -mindepth 1 -not -path '*/.git*' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$brain_dir"
}

# AC-006 / BC-2.01.003: absent yq produces E-INIT-006
# jq present, yq absent — yq is now checked immediately after jq (AC-008 order)
# Uses _make_restricted_path (flat symlink dir) so co-located tools like git/node
# remain discoverable — avoids the directory-removal problem on ubuntu-latest.
@test "BC_2_01_003: yq absent produces E-INIT-006 exit 2" {
  local brain_dir rdir
  brain_dir="$(_make_git_dir)"
  rdir="$(_make_restricted_path yq)"
  run env PATH="$rdir" \
    BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  rm -rf "$rdir"
  # Must exit 2
  [ "$status" -eq 2 ]
  # stdout must contain E-INIT-006
  local code
  code="$(printf '%s' "$output" | jq -r '.code' 2>/dev/null || true)"
  [ "$code" = "E-INIT-006" ]
  # No brain files created
  local file_count
  file_count="$(find "$brain_dir" -mindepth 1 -not -path '*/.git*' | wc -l | tr -d ' ')"
  [ "$file_count" -eq 0 ]
  rm -rf "$brain_dir"
}

# AC-001 / BC-2.01.005: briefs/research/ exists after successful init
@test "BC_2_01_005: briefs/research/ exists after init" {
  local brain_dir
  brain_dir="$(_make_git_dir)"
  run env BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  [ "$status" -eq 0 ]
  [ -d "${brain_dir}/briefs/research" ]
  rm -rf "$brain_dir"
}

# SLA / BC-2.01.002: init completes under 5 minutes (300 seconds)
# NOTE: also asserts briefs/research/ exists (BC-2.01.005) so that this test
# fails at Red Gate (run.sh has no briefs/research/ in its mkdir list yet).
@test "BC_2_01_002: completes under 5 minutes" {
  local brain_dir
  brain_dir="$(_make_git_dir)"
  local start_seconds="$SECONDS"
  run env BRAIN_ROOT="$brain_dir" \
    CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  local elapsed=$(( SECONDS - start_seconds ))
  [ "$status" -eq 0 ]
  [ "$elapsed" -lt 300 ]
  # briefs/research/ must also be present (guard: ensure this test fails until
  # the full STORY-003 implementation lands, making this a real Red Gate test)
  [ -d "${brain_dir}/briefs/research" ]
  rm -rf "$brain_dir"
}

# ---------------------------------------------------------------------------
# STORY-032: bin/lobster-run — YAML parsing, topological sort, exit-code contract
# Traces to: BC-2.12.001, BC-2.12.002, VP-007
# ---------------------------------------------------------------------------

# Helper: set up a lobster test environment with a mock CLAUDE_PLUGIN_ROOT.
# Sets LOBSTER_BIN, LOBSTER_BRAIN, LOBSTER_PLUGIN_ROOT, FIXTURE_DIR in caller scope.
# Creates a mock scripts/run-skill.mjs that exits based on skill name:
#   mock-pass     → exit 0
#   mock-advisory → exit 1
#   mock-block    → exit 2
#   (anything else) → exit 0
_setup_lobster_env() {
  LOBSTER_BIN="${PLUGIN_DIR}/bin/lobster-run"
  FIXTURE_DIR="${PLUGIN_DIR}/tests/fixtures"

  # Temp brain root with required log dir
  LOBSTER_BRAIN="$(mktemp -d)"
  mkdir -p "${LOBSTER_BRAIN}/.brain/logs"

  # Temp plugin root with a mock scripts/run-skill.mjs
  LOBSTER_PLUGIN_ROOT="$(mktemp -d)"
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/scripts"
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills"

  # Mirror real skills into mock plugin root so skill-registration checks pass
  if [[ -d "${PLUGIN_DIR}/skills" ]]; then
    for skill_dir in "${PLUGIN_DIR}/skills"/*/; do
      skill_name="$(basename "$skill_dir")"
      mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/${skill_name}"
      if [[ -f "${skill_dir}/SKILL.md" ]]; then
        cp "${skill_dir}/SKILL.md" "${LOBSTER_PLUGIN_ROOT}/skills/${skill_name}/SKILL.md"
      fi
    done
  fi

  # Mock run-skill.mjs: exit code determined by skill name suffix
  cat > "${LOBSTER_PLUGIN_ROOT}/scripts/run-skill.mjs" <<'MOCK_EOF'
#!/usr/bin/env node
const skill = process.argv[2] || "";
if (skill === "mock-advisory") {
  process.exit(1);
} else if (skill === "mock-block") {
  process.exit(2);
} else {
  process.exit(0);
}
MOCK_EOF
  chmod +x "${LOBSTER_PLUGIN_ROOT}/scripts/run-skill.mjs"
}

_teardown_lobster_env() {
  rm -rf "${LOBSTER_BRAIN:-}" "${LOBSTER_PLUGIN_ROOT:-}"
}

# AC-001 / BC-2.12.001 / VP-007: linear DAG executes in dependency order (--dry-run)
@test "BC_2_12_001: lobster-run linear DAG executes steps in dependency order (--dry-run)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  # Must exit 0
  [ "$status" -eq 0 ]
  # step-a must appear before step-b, step-b before step-c
  local pos_a pos_b pos_c
  pos_a="$(printf '%s\n' "$output" | grep -n 'step-a' | head -1 | cut -d: -f1)"
  pos_b="$(printf '%s\n' "$output" | grep -n 'step-b' | head -1 | cut -d: -f1)"
  pos_c="$(printf '%s\n' "$output" | grep -n 'step-c' | head -1 | cut -d: -f1)"
  # All three step IDs must appear in output
  [ -n "$pos_a" ]
  [ -n "$pos_b" ]
  [ -n "$pos_c" ]
  # Order constraint: a < b < c
  [ "$pos_a" -lt "$pos_b" ]
  [ "$pos_b" -lt "$pos_c" ]
}

# AC-001 / BC-2.12.001: diamond DAG — A before B and C, both before D (--dry-run)
@test "BC_2_12_001: lobster-run diamond DAG A before B and C, both before D (--dry-run)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/diamond-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 0 ]
  local pos_a pos_b pos_c pos_d
  pos_a="$(printf '%s\n' "$output" | grep -n 'step-a' | head -1 | cut -d: -f1)"
  pos_b="$(printf '%s\n' "$output" | grep -n 'step-b' | head -1 | cut -d: -f1)"
  pos_c="$(printf '%s\n' "$output" | grep -n 'step-c' | head -1 | cut -d: -f1)"
  pos_d="$(printf '%s\n' "$output" | grep -n 'step-d' | head -1 | cut -d: -f1)"
  [ -n "$pos_a" ]
  [ -n "$pos_b" ]
  [ -n "$pos_c" ]
  [ -n "$pos_d" ]
  # a before b and c; b and c before d
  [ "$pos_a" -lt "$pos_b" ]
  [ "$pos_a" -lt "$pos_c" ]
  [ "$pos_b" -lt "$pos_d" ]
  [ "$pos_c" -lt "$pos_d" ]
}

# AC-002 / BC-2.12.001: --dry-run prints invocation command with node scripts/run-skill.mjs
@test "BC_2_12_001: lobster-run --dry-run prints node scripts/run-skill.mjs invocation per step" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 0 ]
  # Output must contain the run-skill.mjs invocation pattern
  [[ "$output" == *"run-skill.mjs"* ]]
}

# AC-004 / BC-2.12.001 EC-001: cycle in depends_on → E-LOBSTER-001, exit 2
@test "BC_2_12_001: lobster-run cycle in depends_on emits E-LOBSTER-001 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-001"* ]]
}

# AC-003 / BC-2.12.001 EC-002: missing skill → E-LOBSTER-002, exit 2
@test "BC_2_12_001: lobster-run missing skill emits E-LOBSTER-002 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/missing-skill.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-002"* ]]
}

# AC-005 / BC-2.12.001 EC-003: malformed YAML → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run malformed YAML emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/malformed.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
}

# AC-006 / BC-2.12.001: step results written to .brain/logs/lobster-YYYY-MM-DD.jsonl
@test "BC_2_12_001: lobster-run writes step results to .brain/logs/lobster-YYYY-MM-DD.jsonl" {
  _setup_lobster_env
  # Add mock-pass as a registered skill so skill-check passes
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  local exit_status="$status"
  # Find JSONL log file
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' | head -1)"
  [ "$exit_status" -eq 0 ]
  [ -n "$log_file" ]
  # Log file must contain required fields for each step
  local step_a_line
  step_a_line="$(grep 'step-a' "$log_file" 2>/dev/null || true)"
  [ -n "$step_a_line" ]
  # Each line must have step_id, exit_code, verdict, duration_ms
  local has_step_id has_exit_code has_verdict has_duration
  has_step_id="$(printf '%s' "$step_a_line" | grep -c '"step_id"' || true)"
  has_exit_code="$(printf '%s' "$step_a_line" | grep -c '"exit_code"' || true)"
  has_verdict="$(printf '%s' "$step_a_line" | grep -c '"verdict"' || true)"
  has_duration="$(printf '%s' "$step_a_line" | grep -c '"duration_ms"' || true)"
  [ "$has_step_id" -gt 0 ]
  [ "$has_exit_code" -gt 0 ]
  [ "$has_verdict" -gt 0 ]
  [ "$has_duration" -gt 0 ]
  # S05: assert verdict value is "allow" for a passing step
  [[ "$step_a_line" == *'"verdict":"allow"'* ]]
  _teardown_lobster_env
}

# AC-011 / VP-007: same workflow twice in --dry-run produces identical output (determinism)
@test "BC_2_12_001: lobster-run --dry-run same workflow twice produces identical output (VP-007)" {
  _setup_lobster_env
  # lobster-run must exist and be executable — fail here at Red Gate if not
  [ -f "${LOBSTER_BIN}" ]
  [ -x "${LOBSTER_BIN}" ]
  local out1 out2
  out1="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml")"
  out2="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml")"
  _teardown_lobster_env
  [ "$out1" = "$out2" ]
}

# AC-007 / BC-2.12.002 postcondition 1: all steps exit 0 → lobster exits 0
@test "BC_2_12_002: lobster-run all steps exit 0 → lobster exits 0" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  _teardown_lobster_env
  [ "$status" -eq 0 ]
}

# AC-008 / BC-2.12.002 postcondition 2: one step exits 1, none exit 2 → lobster exits 1; pipeline continues
@test "BC_2_12_002: lobster-run one step exits 1 and none exit 2 → lobster exits 1 all steps ran" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-advisory"
  printf -- '---\nname: mock-advisory\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-advisory/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-advisory.yaml"
  local exit_status="$status"
  # Verify all three steps ran by checking the JSONL log
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' 2>/dev/null | head -1)"
  [ "$exit_status" -eq 1 ]
  # All three steps must appear in log (pipeline continued after advisory)
  [ -n "$log_file" ]
  local step_c_line
  step_c_line="$(grep 'step-c' "$log_file" 2>/dev/null || true)"
  [ -n "$step_c_line" ]
  # I06: step-b must have verdict "advisory" in log
  local step_b_line
  step_b_line="$(grep 'step-b' "$log_file" 2>/dev/null || true)"
  [[ "$step_b_line" == *'"verdict":"advisory"'* ]]
  _teardown_lobster_env
}

# AC-009 / BC-2.12.002 postcondition 3 + invariant 1: one step exits 2 → lobster exits 2 immediately
@test "BC_2_12_002: lobster-run one step exits 2 → lobster exits 2 and skips remaining steps" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-block"
  printf -- '---\nname: mock-block\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-block/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-block.yaml"
  local exit_status="$status"
  # Verify step-c was NOT executed (only step-a and step-b ran)
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' 2>/dev/null | head -1)"
  [ "$exit_status" -eq 2 ]
  # step-c must NOT appear in log — it was skipped
  # S03: read log before teardown so the file still exists during assertions
  if [ -n "$log_file" ]; then
    local step_c_line
    step_c_line="$(grep 'step-c' "$log_file" 2>/dev/null || true)"
    [ -z "$step_c_line" ]
    # I06: step-b must have verdict "block" in log
    local step_b_line
    step_b_line="$(grep 'step-b' "$log_file" 2>/dev/null || true)"
    [[ "$step_b_line" == *'"verdict":"block"'* ]]
  fi
  _teardown_lobster_env
}

# AC-010 / BC-2.12.001 invariant 1: bin/lobster-run is pure bash — no Node/Python/Ruby invocations
@test "BC_2_12_001: lobster-run is pure bash — no node/python/ruby calls in the script itself" {
  # bin/lobster-run must exist and be a bash script
  [ -f "${PLUGIN_DIR}/bin/lobster-run" ]
  # Shebang must be #!/usr/bin/env bash
  local shebang
  shebang="$(head -1 "${PLUGIN_DIR}/bin/lobster-run")"
  [ "$shebang" = "#!/usr/bin/env bash" ]
  # set -euo pipefail must appear within first 10 lines
  local pipefail_found
  pipefail_found="$(head -10 "${PLUGIN_DIR}/bin/lobster-run" | grep -c 'set -euo pipefail' || true)"
  [ "$pipefail_found" -gt 0 ]
  # The script must not invoke node/python/ruby as a top-level command in its own logic
  # (child skill invocations use node, but they are invoked via run-skill.mjs — the test
  # checks that lobster-run's own logic does not shell out to interpreters directly)
  local node_calls python_calls ruby_calls
  # Exclude lines that are comments and the canonical child-skill invocation pattern
  node_calls="$(grep -v '^\s*#' "${PLUGIN_DIR}/bin/lobster-run" | grep -v 'run-skill\.mjs' | grep -c '\bnode\b' || true)"
  python_calls="$(grep -v '^\s*#' "${PLUGIN_DIR}/bin/lobster-run" | grep -c '\bpython[23]\?\b' || true)"
  ruby_calls="$(grep -v '^\s*#' "${PLUGIN_DIR}/bin/lobster-run" | grep -c '\bruby\b' || true)"
  [ "$node_calls" -eq 0 ]
  [ "$python_calls" -eq 0 ]
  [ "$ruby_calls" -eq 0 ]
}

# C02: AC-010 / VP-022 prerequisite: bin/lobster-run has no bare 'read' calls
@test "BC_2_12_001: bin/lobster-run has no bare 'read' calls (VP-022 prerequisite)" {
  # grep exits 1 when no match (which is what we want — no bare read calls)
  run grep -n '^\s*read ' "${PLUGIN_DIR}/bin/lobster-run"
  [ "$status" -eq 1 ]
}

# C03: AC-004 / BC-2.12.001 EC-001: undefined dependency → E-LOBSTER-004, exit 2
@test "BC_2_12_001: lobster-run undefined dependency reference emits E-LOBSTER-004 exit 2" {
  _setup_lobster_env
  # Add the init skill so SKILL.md check passes for step-a
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  # Create fixture with step-a depending on step-x (undefined)
  local fixture_path
  fixture_path="${LOBSTER_PLUGIN_ROOT}/undefined-dep.yaml"
  printf 'name: test-undefined-dep\nsteps:\n  - id: step-a\n    skill: init\n    depends_on: [step-x]\n' > "$fixture_path"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "$fixture_path"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-004"* ]]
}

# AC-010 / BC-2.12.001 invariant 1: bin/lobster-run passes shellcheck
@test "BC_2_12_001: bin/lobster-run passes shellcheck" {
  [ -f "${PLUGIN_DIR}/bin/lobster-run" ]
  run shellcheck "${PLUGIN_DIR}/bin/lobster-run"
  [ "$status" -eq 0 ]
}

# AC-010 / BC-2.12.001 invariant 1: bin/lobster-run passes shfmt
@test "BC_2_12_001: bin/lobster-run passes shfmt normalization" {
  [ -f "${PLUGIN_DIR}/bin/lobster-run" ]
  run shfmt -d -i 2 "${PLUGIN_DIR}/bin/lobster-run"
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
  # Extract body after second --- (portable across BSD sed/GNU sed)
  body1="$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$first")"
  body2="$(awk 'BEGIN{c=0} /^---$/{c++; next} c>=2' "$second")"
  [ "$body1" != "$body2" ]
  # First source body should have more than 5 unique words (LCG progresses, not stuck)
  local unique
  unique="$(printf '%s' "$body1" | tr ' ' '\n' | sort -u | wc -l | tr -d ' ')"
  [ "$unique" -gt 5 ]
  rm -rf "$out_dir"
}
