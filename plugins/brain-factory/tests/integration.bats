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
  # C02: create .claude-plugin/plugin.json so plugin manifest lookup passes
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/.claude-plugin"
  printf '{"name":"brain-factory","skills":"./skills/","hooks":"hooks/hooks.json"}\n' \
    > "${LOBSTER_PLUGIN_ROOT}/.claude-plugin/plugin.json"

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
  printf 'name: test-undefined-dep\ndescription: "Test undefined dependency"\nsteps:\n  - id: step-a\n    skill: init\n    depends_on: [step-x]\n' > "$fixture_path"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "$fixture_path"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-004"* ]]
}

# C01: args forwarded correctly in --dry-run output
@test "BC_2_12_001: lobster-run --dry-run forwards multi-arg steps without concatenation" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/with-args.yaml"
  _teardown_lobster_env
  [ "$status" -eq 0 ]
  # Each arg must appear as a separate token in the output (not concatenated).
  # S02 fix: args are shell-quoted with printf %q — "path with spaces" becomes
  # path\ with\ spaces (backslash-escaped) which is runnable as-is.
  [[ "$output" == *"--verbose"* ]]
  [[ "$output" == *"--output=json"* ]]
  # Match the shell-quoted form produced by printf %q on this platform
  quoted_spaces="$(printf '%q' "path with spaces")"
  [[ "$output" == *"${quoted_spaces}"* ]]
}

# I04: lobster.run.completed emitted on stderr for E-LOBSTER-001 (cycle) failure path
@test "BC_2_12_001: lobster-run emits lobster.run.completed on stderr for cycle failure (I04)" {
  _setup_lobster_env
  # Capture stderr separately by running outside bats `run` wrapper
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  # lobster.run.completed must appear on stderr
  local completed_event
  completed_event="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_event" ]
}

# I04: lobster.run.completed emitted on stderr for E-LOBSTER-003 (malformed YAML) failure path
@test "BC_2_12_001: lobster-run emits lobster.run.completed on stderr for malformed YAML failure (I04)" {
  _setup_lobster_env
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/malformed.yaml" 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  local completed_event
  completed_event="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_event" ]
}

# I05: duration_ms is numeric (not 0 for all steps, not NaN)
@test "BC_2_12_001: lobster-run step log duration_ms is a non-negative integer (I05)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  local exit_status="$status"
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' 2>/dev/null | head -1)"
  [ "$exit_status" -eq 0 ]
  [ -n "$log_file" ]
  local step_a_line
  step_a_line="$(grep 'step-a' "$log_file" 2>/dev/null || true)"
  [ -n "$step_a_line" ]
  # Extract duration_ms value and verify it is a non-negative integer
  local duration
  duration="$(printf '%s' "$step_a_line" | jq '.duration_ms')"
  [[ "$duration" =~ ^[0-9]+$ ]]
  _teardown_lobster_env
}

# I03: trace field in step.completed events is not all-zeros UUID
@test "BC_2_12_001: lobster-run emits non-zero trace UUID in step events (I03)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  # Capture stderr separately (events go to stderr)
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml" 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  local step_event
  step_event="$(printf '%s' "$stderr_out" | grep 'lobster.step.completed' | head -1 || true)"
  [ -n "$step_event" ]
  local trace
  trace="$(printf '%s' "$step_event" | jq -r '.trace')"
  # Must not be the all-zeros UUID
  [ "$trace" != "00000000-0000-0000-0000-000000000000" ]
}

# S04: bare read regex — strengthen to catch read as a command in more positions
@test "BC_2_12_001: bin/lobster-run has no bare 'read' calls (strengthened S04 regex)" {
  # Match 'read' as a command token (not part of mapfile, not in comments)
  local filtered
  filtered="$(grep -nE '(^|[[:space:];|&])read([[:space:]]|$)' \
    "${PLUGIN_DIR}/bin/lobster-run" | grep -v '^[0-9]*:[[:space:]]*#' || true)"
  [ -z "$filtered" ]
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

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 3 — Adversary Pass 3 findings
# C01: missing name/description validation
# C02: duplicate step IDs → E-LOBSTER-009
# C03: --dry-run does not require BRAIN_ROOT
# I01: lobster.run.completed emitted on dry-run success
# I02: actual exit code preserved in log (not coerced)
# I03: missing step id/skill → E-LOBSTER-003
# I04: missing CLAUDE_PLUGIN_ROOT → E-LOBSTER-010
# S01: missing file → E-LOBSTER-011
# ---------------------------------------------------------------------------

# C01: workflow missing name field → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run workflow missing name field emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/missing-name.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"name"* ]]
}

# C01: workflow missing description field → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run workflow missing description field emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/missing-description.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"description"* ]]
}

# C02: workflow with duplicate step IDs → E-LOBSTER-009, exit 2
@test "BC_2_12_001: lobster-run duplicate step id emits E-LOBSTER-009 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/duplicate-ids.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-009"* ]]
}

# C03: --dry-run does not require BRAIN_ROOT to be set
@test "BC_2_12_001: lobster-run --dry-run does not require BRAIN_ROOT" {
  _setup_lobster_env
  run env -u BRAIN_ROOT CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 0 ]
}

# I01: lobster.run.completed emitted on stderr for successful --dry-run
@test "BC_2_12_001: lobster-run emits lobster.run.completed on stderr for dry-run success (I01)" {
  _setup_lobster_env
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml" 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  local completed_event
  completed_event="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_event" ]
}

# I02: step exiting 127 (command not found) logged with exit_code 127 not 2
@test "BC_2_12_001: lobster-run preserves actual exit code in JSONL log (I02)" {
  _setup_lobster_env
  # Create a skill that exits 127 (simulates command-not-found)
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-127"
  printf -- '---\nname: mock-127\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/mock-127/SKILL.md"
  # Override run-skill.mjs to exit 127 for mock-127
  cat > "${LOBSTER_PLUGIN_ROOT}/scripts/run-skill.mjs" <<'MOCK_EOF'
#!/usr/bin/env node
const skill = process.argv[2] || "";
if (skill === "mock-advisory") {
  process.exit(1);
} else if (skill === "mock-block") {
  process.exit(2);
} else if (skill === "mock-127") {
  process.exit(127);
} else {
  process.exit(0);
}
MOCK_EOF
  chmod +x "${LOBSTER_PLUGIN_ROOT}/scripts/run-skill.mjs"
  # Create a fixture that uses mock-127
  local fixture_path
  fixture_path="${LOBSTER_PLUGIN_ROOT}/exit-127.yaml"
  printf 'name: test-exit-127\ndescription: "Step exits 127"\nsteps:\n  - id: step-a\n    skill: mock-127\n    depends_on: []\n' > "$fixture_path"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "$fixture_path"
  local exit_status="$status"
  # Lobster must exit 2 (block) for any non-{0,1} exit code
  [ "$exit_status" -eq 2 ]
  # JSONL log must record the actual exit_code (127), not 2
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' 2>/dev/null | head -1)"
  [ -n "$log_file" ]
  local step_line
  step_line="$(grep 'step-a' "$log_file" 2>/dev/null || true)"
  [ -n "$step_line" ]
  # exit_code in log must be 127 (actual), verdict must be "block"
  local logged_exit
  logged_exit="$(printf '%s' "$step_line" | jq '.exit_code')"
  [ "$logged_exit" -eq 127 ]
  local logged_verdict
  logged_verdict="$(printf '%s' "$step_line" | jq -r '.verdict')"
  [ "$logged_verdict" = "block" ]
  _teardown_lobster_env
}

# I03: step missing id field → E-LOBSTER-003, exit 2 (not silent skip)
@test "BC_2_12_001: lobster-run step missing id field emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/missing-step-id.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"id"* ]]
}

# I03: step missing skill field → E-LOBSTER-003, exit 2 (not silent skip)
@test "BC_2_12_001: lobster-run step missing skill field emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/missing-step-skill.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"skill"* ]]
}

# I04: missing CLAUDE_PLUGIN_ROOT → E-LOBSTER-010, exit 2
@test "BC_2_12_001: lobster-run missing CLAUDE_PLUGIN_ROOT emits E-LOBSTER-010 exit 2" {
  _setup_lobster_env
  local fixture_path
  fixture_path="${LOBSTER_PLUGIN_ROOT}/simple.yaml"
  printf 'name: test-simple\ndescription: "Simple workflow"\nsteps:\n  - id: step-a\n    skill: init\n    depends_on: []\n' > "$fixture_path"
  run env -u CLAUDE_PLUGIN_ROOT \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "$fixture_path"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-010"* ]]
}

# S01: nonexistent workflow file → E-LOBSTER-011, exit 2
@test "BC_2_12_001: lobster-run nonexistent workflow file emits E-LOBSTER-011 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/does-not-exist.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-011"* ]]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 4 — Adversary Pass 4 findings
# I01: step IDs lack format validation
# I02: args field not validated as array
# I03: args containing newlines split incorrectly
# I04: non-mapping step shape not validated
# S01: E-LOBSTER-002 conflates manifest-missing with skill-missing
# S02: fallback UUID not v4-conformant
# ---------------------------------------------------------------------------

# I01: step with invalid ID (contains space) → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run step with invalid id (space) emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/invalid-step-id.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"kebab-case"* ]]
}

# I02: step with args as a string (not array) → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run step with non-array args emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/invalid-args-type.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"args"* ]]
}

# I03: multiline arg preserved as a single arg (not split on newline) in dry-run
@test "BC_2_12_001: lobster-run preserves multiline arg as single arg in dry-run (I03)" {
  _setup_lobster_env
  # Add init skill to mock plugin root (fixture uses init)
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' > "${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/multiline-args.yaml"
  _teardown_lobster_env
  [ "$status" -eq 0 ]
  # The multiline arg (line1\nline2) must appear shell-quoted on a single output line
  # (not split into two separate args). Output should contain --message on same line as the quoted value.
  local step_line
  step_line="$(printf '%s\n' "$output" | grep 'step-a' || true)"
  [ -n "$step_line" ]
  # --message and the multi-line arg must appear on the SAME line (not split)
  [[ "$step_line" == *"--message"* ]]
  # The quoted value must not span multiple output lines — verify by counting lines with step-a
  local step_a_lines
  step_a_lines="$(printf '%s\n' "$output" | grep -c 'step-a' || true)"
  [ "$step_a_lines" -eq 1 ]
}

# I04: steps array containing non-mapping element → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run non-mapping step emits E-LOBSTER-003 exit 2" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/non-mapping-steps.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"mapping"* ]]
}

# S01: missing plugin manifest → E-LOBSTER-012 (not E-LOBSTER-002)
@test "BC_2_12_001: lobster-run missing plugin manifest emits E-LOBSTER-012 exit 2" {
  _setup_lobster_env
  # Remove the plugin manifest so E-LOBSTER-012 fires
  rm -f "${LOBSTER_PLUGIN_ROOT}/.claude-plugin/plugin.json"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-012"* ]]
}

# S02: UUID fallback (when uuidgen and /proc absent) is v4-conformant
@test "BC_2_12_001: lobster-run UUID fallback is v4-conformant when uuidgen absent" {
  _setup_lobster_env
  # Create a restricted PATH without uuidgen to force the fallback path
  local rdir
  rdir="$(_make_restricted_path uuidgen)"
  # Also ensure /proc/sys/kernel/random/uuid is not available (macOS doesn't have it)
  # The fallback path runs when neither uuidgen nor /proc UUID is available
  local stderr_out
  stderr_out="$(env PATH="$rdir" \
    CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml" 2>&1 >/dev/null || true)"
  rm -rf "$rdir"
  _teardown_lobster_env
  # Extract the trace from the completed event
  local completed_line trace
  completed_line="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_line" ]
  trace="$(printf '%s' "$completed_line" | jq -r '.trace')"
  [ -n "$trace" ]
  # Must match UUID v4 format: xxxxxxxx-xxxx-4xxx-[89ab]xxx-xxxxxxxxxxxx
  [[ "$trace" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 5 — Adversary Pass 5 findings
# I01: log-write failure emits E-LOBSTER-006 + lobster.run.completed
# I02: VP-007 process substitution accepted by -r check
# I03: brain: namespace prefix exercised
# S01: empty WORKFLOW_FILE falls back to "unknown"
# S02: dep entry with embedded comma → E-LOBSTER-003
# S03: .skills as array → E-LOBSTER-002
# S04: JSONL log entries contain ts and trace fields
# ---------------------------------------------------------------------------

# I01: read-only log directory → E-LOBSTER-006 + lobster.run.completed on stderr
@test "BC_2_12_001: lobster-run read-only log dir emits E-LOBSTER-006 and lobster.run.completed (I01)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  # Create the log dir and make it read-only so touch "$LOG_FILE" fails
  local readonly_log_dir
  readonly_log_dir="${LOBSTER_BRAIN}/.brain/logs"
  mkdir -p "$readonly_log_dir"
  chmod 444 "$readonly_log_dir"
  # Capture both stdout and stderr
  local combined_out
  combined_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml" 2>&1 || true)"
  # Restore permissions so teardown can clean up
  chmod 755 "$readonly_log_dir"
  _teardown_lobster_env
  # stdout must contain E-LOBSTER-006
  [[ "$combined_out" == *"E-LOBSTER-006"* ]]
  # stderr must contain lobster.run.completed
  [[ "$combined_out" == *"lobster.run.completed"* ]]
}

# I02: process substitution <(echo "...") accepted as workflow source (VP-007)
@test "BC_2_12_001: lobster-run accepts process substitution as workflow file (I02/VP-007)" {
  _setup_lobster_env
  # Add init skill so skill check passes
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  local yaml_content
  yaml_content='name: ps-test
description: "Process substitution test"
steps:
  - id: step-a
    skill: init
    depends_on: []'
  # Run with process substitution — should NOT fail with E-LOBSTER-011
  local ps_out ps_status
  ps_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run <(printf '%s\n' "$yaml_content") 2>&1 || true)"
  ps_status="${PIPESTATUS[0]:-$?}"
  _teardown_lobster_env
  # Must NOT emit E-LOBSTER-011 (file-not-found)
  [[ "$ps_out" != *"E-LOBSTER-011"* ]]
  # step-a should appear in dry-run output (execution plan was printed)
  [[ "$ps_out" == *"step-a"* ]]
}

# I03: brain: namespace prefix is accepted and skill lookup strips it (BC-2.12.001 postcondition 2)
@test "BC_2_12_001: lobster-run accepts brain: namespace prefix on skill names (I03)" {
  _setup_lobster_env
  # Add init skill under its real name (brain: is stripped for directory lookup)
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/brain-namespaced.yaml"
  _teardown_lobster_env
  # Must succeed (brain:init → init lookup passes)
  [ "$status" -eq 0 ]
  # dry-run output must show step-a
  [[ "$output" == *"step-a"* ]]
}

# S02: dep entry with embedded comma → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run dep entry with embedded comma emits E-LOBSTER-003 exit 2 (S02)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  # Create fixture with a dep entry containing a comma (malformed)
  local fixture_path
  fixture_path="${LOBSTER_PLUGIN_ROOT}/bad-dep-comma.yaml"
  # The dep entry "step-a,step-b" has an embedded comma — invalid kebab-case
  printf 'name: test-bad-dep\ndescription: "Bad dep with comma"\nsteps:\n  - id: step-b\n    skill: init\n    depends_on:\n      - "step-a,step-b"\n  - id: step-a\n    skill: init\n    depends_on: []\n' >"$fixture_path"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "$fixture_path"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
}

# S03: .skills field as array in plugin.json → E-LOBSTER-002, exit 2
@test "BC_2_12_001: lobster-run .skills as array in plugin manifest emits E-LOBSTER-013 exit 2 (S03+P18I02)" {
  _setup_lobster_env
  # Overwrite plugin.json with .skills as an array (invalid type)
  printf '{"name":"brain-factory","skills":["./skills/"],"hooks":"hooks/hooks.json"}\n' \
    >"${LOBSTER_PLUGIN_ROOT}/.claude-plugin/plugin.json"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  # P18-I02: manifest schema violations now use E-LOBSTER-013 (semantic JSON invalidity),
  # not E-LOBSTER-002 (which exclusively covers skill-not-found-in-manifest)
  [[ "$output" == *"E-LOBSTER-013"* ]]
}

# S04: JSONL log entries contain ts and trace fields (operational observability)
@test "BC_2_12_001: lobster-run JSONL log entries contain ts and trace fields (S04)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  local exit_status="$status"
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' 2>/dev/null | head -1)"
  [ "$exit_status" -eq 0 ]
  [ -n "$log_file" ]
  local step_a_line
  step_a_line="$(grep 'step-a' "$log_file" 2>/dev/null || true)"
  [ -n "$step_a_line" ]
  # ts field must be present and non-empty
  local ts_val
  ts_val="$(printf '%s' "$step_a_line" | jq -r '.ts // ""')"
  [ -n "$ts_val" ]
  # trace field must be present and non-empty
  local trace_val
  trace_val="$(printf '%s' "$step_a_line" | jq -r '.trace // ""')"
  [ -n "$trace_val" ]
  # trace must not be the all-zeros UUID
  [ "$trace_val" != "00000000-0000-0000-0000-000000000000" ]
  _teardown_lobster_env
}

# S01: when WORKFLOW_FILE is initialized to "" (pre-arg-parse error path), completed event
# shows "unknown" workflow — test the _emit_run_completed_and_exit path for missing arg
@test "BC_2_12_001: lobster-run completed event shows unknown workflow when file arg missing (S01)" {
  _setup_lobster_env
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  # lobster.run.completed must appear on stderr
  local completed_event
  completed_event="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_event" ]
  # workflow field must be "unknown" (not empty string)
  local workflow_val
  workflow_val="$(printf '%s' "$completed_event" | jq -r '.workflow')"
  [ "$workflow_val" = "unknown" ]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 6 — Adversary Pass 6 findings
# C01: depends_on lacks type validation (parallel to args)
# C02: E-LOBSTER-001 message missing <cycle> substitution
# I01: E-LOBSTER-003 hardcodes "parse error" instead of yq error
# I03: No EXIT trap — tmpfile leaks on abnormal termination
# S01: Validation-failure paths report steps_run=0/steps_skipped=0
# S02: Cycle test doesn't assert cycle members in message
# ---------------------------------------------------------------------------

# C01: depends_on as string → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run depends_on as string emits E-LOBSTER-003 exit 2 (C01)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/depends-on-string.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"depends_on"* ]]
  [[ "$output" == *"string"* ]]
}

# C01: depends_on as object → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run depends_on as object emits E-LOBSTER-003 exit 2 (C01)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/depends-on-object.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"depends_on"* ]]
  [[ "$output" == *"object"* ]]
}

# C01: depends_on as number → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run depends_on as number emits E-LOBSTER-003 exit 2 (C01)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/depends-on-number.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"depends_on"* ]]
  [[ "$output" == *"number"* ]]
}

# C02: cycle message includes the cycle member step IDs
@test "BC_2_12_001: lobster-run cycle message includes cycle member step IDs (C02/S02)" {
  _setup_lobster_env
  local stdout_out
  stdout_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" 2>/dev/null || true)"
  _teardown_lobster_env
  # Error code must be present
  [[ "$stdout_out" == *"E-LOBSTER-001"* ]]
  # Cycle message must identify cycle members (step-a and step-b)
  [[ "$stdout_out" == *"step-a"* ]]
  [[ "$stdout_out" == *"step-b"* ]]
}

# C02/S01: cycle detection failure path — lobster.run.completed reports steps_skipped = step count
@test "BC_2_12_001: lobster-run cycle failure completed event reports steps_skipped = step count (C02/S01)" {
  _setup_lobster_env
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  local completed_event
  completed_event="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_event" ]
  local steps_run steps_skipped
  steps_run="$(printf '%s' "$completed_event" | jq '.steps_run')"
  steps_skipped="$(printf '%s' "$completed_event" | jq '.steps_skipped')"
  # Cycle: 2 steps total, 0 ran, 2 skipped
  [ "$steps_run" -eq 0 ]
  [ "$steps_skipped" -eq 2 ]
}

# I01: malformed YAML error message contains actual yq error detail (not hardcoded "parse error")
@test "BC_2_12_001: lobster-run malformed YAML error message contains actual yq error detail (I01)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/malformed.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  # Message must contain actual yq error content beyond the generic prefix.
  # The old hardcoded text was exactly "Invalid workflow YAML: parse error."
  # The new message must be longer (it embeds the real yq stderr).
  local msg
  msg="$(printf '%s' "$output" | jq -r '.message' 2>/dev/null || printf '%s' "$output")"
  local generic_sentinel="Invalid workflow YAML: parse error."
  local generic_len="${#generic_sentinel}"
  local actual_len="${#msg}"
  [ "$actual_len" -gt "$generic_len" ]
}

# I03: EXIT trap prevents tmpfile leak — process substitution run leaves no orphan tmpfile
@test "BC_2_12_001: lobster-run EXIT trap cleans up tmpfile on normal exit (I03)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  local yaml_content
  yaml_content='name: trap-test
description: "EXIT trap cleanup test"
steps:
  - id: step-a
    skill: init
    depends_on: []'
  # Snapshot tmpdir before and after
  local tmpdir_before tmpdir_after
  tmpdir_before="$(ls /tmp/ 2>/dev/null | wc -l | tr -d ' ')"
  env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run <(printf '%s\n' "$yaml_content") >/dev/null 2>&1 || true
  tmpdir_after="$(ls /tmp/ 2>/dev/null | wc -l | tr -d ' ')"
  _teardown_lobster_env
  # tmpfile count must not have grown (EXIT trap cleaned up)
  [ "$tmpdir_after" -le "$tmpdir_before" ]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 7 — Adversary Pass 7 findings
# C01: .steps as scalar silently produces exit 0 no-op
# I01: empty .skills string in plugin.json passes through
# I02: whitespace-only BRAIN_ROOT / CLAUDE_PLUGIN_ROOT passes -z check
# I04: EPOCHREALTIME precision assumption (length-based slice)
# O01: cycle test should assert no log file is created
# ---------------------------------------------------------------------------

# C01: .steps as string scalar → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run steps as string scalar emits E-LOBSTER-003 exit 2 (C01)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/steps-as-string.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
}

# C01: .steps as number scalar → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run steps as number scalar emits E-LOBSTER-003 exit 2 (C01)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/steps-as-number.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
}

# C01: .steps as mapping object → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run steps as mapping object emits E-LOBSTER-003 exit 2 (C01)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/steps-as-object.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
}

# I01: empty .skills string in plugin.json → E-LOBSTER-013, exit 2 (P18-I02 reclassified)
@test "BC_2_12_001: lobster-run empty .skills string in plugin manifest emits E-LOBSTER-013 exit 2 (I01+P18I02)" {
  _setup_lobster_env
  # Overwrite plugin.json with .skills as empty string
  printf '{"name":"brain-factory","skills":"","hooks":"hooks/hooks.json"}\n' \
    >"${LOBSTER_PLUGIN_ROOT}/.claude-plugin/plugin.json"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  # P18-I02: manifest schema violations now use E-LOBSTER-013, not E-LOBSTER-002
  [[ "$output" == *"E-LOBSTER-013"* ]]
}

# I02: whitespace-only BRAIN_ROOT → E-LOBSTER-005, exit 2
@test "BC_2_12_001: lobster-run whitespace-only BRAIN_ROOT emits E-LOBSTER-005 exit 2 (I02)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="   " \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-005"* ]]
}

# I02: BRAIN_ROOT set to nonexistent directory → E-LOBSTER-005, exit 2
@test "BC_2_12_001: lobster-run nonexistent BRAIN_ROOT directory emits E-LOBSTER-005 exit 2 (I02)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="/nonexistent/path/that/does/not/exist-$(date +%s)" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-005"* ]]
}

# I02: whitespace-only CLAUDE_PLUGIN_ROOT → E-LOBSTER-010, exit 2
# bats run splits env args on spaces, so we use a temp wrapper script that exports
# the whitespace-only value and run it via bats' run to capture exit status.
@test "BC_2_12_001: lobster-run whitespace-only CLAUDE_PLUGIN_ROOT emits E-LOBSTER-010 exit 2 (I02)" {
  local lobster_bin="${PLUGIN_DIR}/bin/lobster-run"
  local fixture_yaml="${PLUGIN_DIR}/tests/fixtures/linear-dag.yaml"
  local wrapper
  wrapper="$(mktemp)"
  printf '#!/usr/bin/env bash\nexport CLAUDE_PLUGIN_ROOT="   "\nexport BRAIN_ROOT=/tmp\nexec "%s" "%s" 2>/dev/null\n' \
    "$lobster_bin" "$fixture_yaml" >"$wrapper"
  chmod +x "$wrapper"
  run "$wrapper"
  rm -f "$wrapper"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-010"* ]]
}

# I04: _now_ms returns a non-negative integer on reduced-precision platforms (regex guard)
@test "BC_2_12_001: lobster-run _now_ms produces valid millisecond integer (I04 precision guard)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/exit-code-all-pass.yaml"
  local exit_status="$status"
  local log_file
  log_file="$(find "${LOBSTER_BRAIN}/.brain/logs" -name 'lobster-*.jsonl' 2>/dev/null | head -1)"
  [ "$exit_status" -eq 0 ]
  [ -n "$log_file" ]
  local step_a_line
  step_a_line="$(grep 'step-a' "$log_file" 2>/dev/null || true)"
  [ -n "$step_a_line" ]
  # duration_ms must be a non-negative integer (not "NaN" or garbage from slice)
  local duration
  duration="$(printf '%s' "$step_a_line" | jq '.duration_ms')"
  [[ "$duration" =~ ^[0-9]+$ ]]
  _teardown_lobster_env
}

# O01: cycle detection — no log file created (steps_run=0, no I/O to log dir)
@test "BC_2_12_001: lobster-run cycle detected creates no log file entries (O01)" {
  _setup_lobster_env
  env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" >/dev/null 2>&1 || true
  # If a log file exists it must contain no step_id fields (no steps ran)
  local log_file
  log_file="${LOBSTER_BRAIN}/.brain/logs/lobster-$(date -u +%Y-%m-%d).jsonl"
  if [ -f "$log_file" ]; then
    local content
    content="$(grep '"step_id"' "$log_file" 2>/dev/null || true)"
    [ -z "$content" ]
  fi
  _teardown_lobster_env
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 8 — Adversary Pass 8 findings
# I01: unknown flag bypasses _emit_run_completed_and_exit
# I02: JSON injection in error envelopes (28 unescaped printf sites → _emit_error)
# S01: trace field missing in stdout error envelopes (resolved by I02 _emit_error)
# S02: whitespace stripping only handles spaces (tab/newline bypass)
# S03: malformed plugin.json misclassified as "empty skills field" → E-LOBSTER-013
# ---------------------------------------------------------------------------

# I01: unknown flag emits E-LOBSTER-007 AND lobster.run.completed on stderr
@test "BC_2_12_001: lobster-run unknown flag emits E-LOBSTER-007 and lobster.run.completed (I01)" {
  _setup_lobster_env
  local stderr_out
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --unknownflag "${FIXTURE_DIR}/linear-dag.yaml" 2>&1 >/dev/null || true)"
  local stdout_out
  stdout_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --unknownflag "${FIXTURE_DIR}/linear-dag.yaml" 2>/dev/null || true)"
  _teardown_lobster_env
  # stdout must contain E-LOBSTER-007
  [[ "$stdout_out" == *"E-LOBSTER-007"* ]]
  # stderr must contain lobster.run.completed
  [[ "$stderr_out" == *"lobster.run.completed"* ]]
}

# I01: unknown flag exits 2
@test "BC_2_12_001: lobster-run unknown flag exits 2 (I01)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --unknownflag "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-007"* ]]
}

# I02: error envelope is valid JSON even with double quotes in CLAUDE_PLUGIN_ROOT
@test "BC_2_12_001: error envelope is valid JSON even with quotes in env vars (I02)" {
  local wrapper
  wrapper="$(mktemp)"
  # Use a wrapper script to set CLAUDE_PLUGIN_ROOT to a value containing a double-quote
  # (env assignment in bats run splits on spaces; wrapper avoids that)
  printf '#!/usr/bin/env bash\nexport CLAUDE_PLUGIN_ROOT='"'"'/foo"bar'"'"'\nexport BRAIN_ROOT=/tmp\nexec "%s" /nonexistent-missing.yaml 2>/dev/null\n' \
    "${PLUGIN_DIR}/bin/lobster-run" >"$wrapper"
  chmod +x "$wrapper"
  run "$wrapper"
  rm -f "$wrapper"
  # Exit must be 2 (error path)
  [ "$status" -eq 2 ]
  # The error envelope on stdout must be parseable JSON (not broken by the quote in the env var)
  printf '%s' "$output" | head -1 | jq -e . >/dev/null
}

# S01: error envelope contains trace field (resolved by _emit_error helper)
@test "BC_2_12_001: error envelope from _emit_error contains trace field (S01)" {
  _setup_lobster_env
  # Trigger an error path (missing workflow file → E-LOBSTER-011)
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/does-not-exist.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  # The error envelope on stdout must contain a trace field
  local trace_val
  trace_val="$(printf '%s' "$output" | head -1 | jq -r '.trace // ""' 2>/dev/null || true)"
  [ -n "$trace_val" ]
}

# S02: tab-only BRAIN_ROOT is rejected as E-LOBSTER-005 (not treated as non-empty)
@test "BC_2_12_001: lobster-run tab-only BRAIN_ROOT emits E-LOBSTER-005 exit 2 (S02)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/mock-pass"
  printf -- '---\nname: mock-pass\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/mock-pass/SKILL.md"
  local wrapper
  wrapper="$(mktemp)"
  # Must use a wrapper because bats `run env` can't embed a literal tab in a value
  printf '#!/usr/bin/env bash\nexport CLAUDE_PLUGIN_ROOT="%s"\nexport BRAIN_ROOT=$'"'"'\t\t'"'"'\nexec "%s" "%s/exit-code-all-pass.yaml" 2>/dev/null\n' \
    "${LOBSTER_PLUGIN_ROOT}" "${LOBSTER_BIN}" "${FIXTURE_DIR}" >"$wrapper"
  chmod +x "$wrapper"
  run "$wrapper"
  rm -f "$wrapper"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-005"* ]]
}

# S03: malformed plugin.json emits E-LOBSTER-013 exit 2 (not E-LOBSTER-002)
@test "BC_2_12_001: malformed plugin.json emits E-LOBSTER-013 exit 2 (S03)" {
  _setup_lobster_env
  # Overwrite plugin.json with malformed JSON
  printf 'NOT_JSON{' >"${LOBSTER_PLUGIN_ROOT}/.claude-plugin/plugin.json"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-013"* ]]
}

# S03: malformed plugin.json does NOT emit E-LOBSTER-002 (wrong error class)
@test "BC_2_12_001: malformed plugin.json does not emit E-LOBSTER-002 (wrong error class) (S03)" {
  _setup_lobster_env
  printf 'NOT_JSON{' >"${LOBSTER_PLUGIN_ROOT}/.claude-plugin/plugin.json"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --dry-run "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  # Must emit E-LOBSTER-013, NOT E-LOBSTER-002
  [[ "$output" != *"E-LOBSTER-002"* ]]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 9 — Adversary Pass 9 findings
# I01: multi-positional args silently overwrite WORKFLOW_FILE
# L01: dry-run PLUGIN_ROOT/skill not shell-quoted (printf %q)
# L02: embedded newline in dep value bypasses kebab-case validation
# ---------------------------------------------------------------------------

# I01: two positional workflow files → E-LOBSTER-007, exit 2
@test "BC_2_12_001: lobster-run two positional workflow files emits E-LOBSTER-007 exit 2 (I01/FB9)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/linear-dag.yaml" "${FIXTURE_DIR}/diamond-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-007"* ]]
}

# L01: dry-run output uses printf %q for the run-skill.mjs path — path with
# a literal double-quote must not produce broken output
@test "BC_2_12_001: lobster-run dry-run shell-quotes path with double-quote in PLUGIN_ROOT (L01/FB9)" {
  # Create a temp plugin root whose path contains a double-quote character
  local quoted_root
  quoted_root="$(mktemp -d)/plu\"gin"
  mkdir -p "${quoted_root}/scripts"
  mkdir -p "${quoted_root}/skills"
  mkdir -p "${quoted_root}/.claude-plugin"
  printf '{"name":"brain-factory","skills":"./skills/","hooks":"hooks/hooks.json"}\n' \
    >"${quoted_root}/.claude-plugin/plugin.json"
  # Mirror init skill
  mkdir -p "${quoted_root}/skills/init"
  printf -- '---\nname: init\n---\n' >"${quoted_root}/skills/init/SKILL.md"
  # Copy mock run-skill.mjs
  cat >"${quoted_root}/scripts/run-skill.mjs" <<'MOCK_EOF'
#!/usr/bin/env node
process.exit(0);
MOCK_EOF
  chmod +x "${quoted_root}/scripts/run-skill.mjs"
  # Create a simple one-step workflow inline
  local fixture_path
  fixture_path="${quoted_root}/simple.yaml"
  printf 'name: test\ndescription: "Quote test"\nsteps:\n  - id: step-a\n    skill: init\n    depends_on: []\n' \
    >"$fixture_path"
  # Run in a wrapper so the env var assignment with embedded quote is safe
  local wrapper dry_out
  wrapper="$(mktemp)"
  printf '#!/usr/bin/env bash\nexport CLAUDE_PLUGIN_ROOT=%s\nexport BRAIN_ROOT=/tmp\nexec %s --dry-run %s\n' \
    "$(printf '%q' "$quoted_root")" \
    "$(printf '%q' "${PLUGIN_DIR}/bin/lobster-run")" \
    "$(printf '%q' "$fixture_path")" \
    >"$wrapper"
  chmod +x "$wrapper"
  dry_out="$("$wrapper" 2>/dev/null || true)"
  rm -f "$wrapper"
  rm -rf "$(dirname "$quoted_root")"
  # step-a must appear in dry-run output (invocation was printed)
  [[ "$dry_out" == *"step-a"* ]]
  # run-skill.mjs must appear in the output
  [[ "$dry_out" == *"run-skill.mjs"* ]]
}

# L02: dep with embedded literal newline → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run dep with embedded newline emits E-LOBSTER-003 exit 2 (L02/FB9)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  # Construct a YAML fixture where depends_on has an entry with a literal newline embedded.
  # jq encodes the newline as \n in JSON; yq maps it into the YAML scalar.
  local fixture_path
  fixture_path="${LOBSTER_PLUGIN_ROOT}/dep-embedded-newline.yaml"
  # Write YAML with a double-quoted scalar containing \n (YAML escape for newline)
  # yq will parse "step-a\nstep-b" as a string containing a literal newline character.
  printf 'name: test-newline-dep\ndescription: "Dep with embedded newline"\nsteps:\n  - id: step-z\n    skill: init\n    depends_on:\n      - "step-a\\nstep-b"\n  - id: step-a\n    skill: init\n    depends_on: []\n' \
    >"$fixture_path"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "$fixture_path"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 10 — Adversary Pass 10 findings
# H01: three raw jq -nc sites bypass _emit_error (paper-fix from Pass 8)
#      — cycle, malformed YAML, .steps-type must all carry trace field
# M01: args array elements not type-validated (null/number/object silently coerce)
# ---------------------------------------------------------------------------

# H01: malformed YAML error envelope contains trace field (via _emit_error)
@test "BC_2_12_001: malformed YAML error envelope contains trace field (H01/FB10)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/malformed.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  local trace_val
  trace_val="$(printf '%s' "$output" | head -1 | jq -r '.trace // ""' 2>/dev/null || true)"
  [ -n "$trace_val" ]
  [[ "$trace_val" =~ ^[0-9a-f-]+$ ]]
}

# H01: .steps type mismatch error envelope contains trace field (via _emit_error)
@test "BC_2_12_001: steps-type mismatch error envelope contains trace field (H01/FB10)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/steps-as-string.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  local trace_val
  trace_val="$(printf '%s' "$output" | head -1 | jq -r '.trace // ""' 2>/dev/null || true)"
  [ -n "$trace_val" ]
  [[ "$trace_val" =~ ^[0-9a-f-]+$ ]]
}

# H01: cycle detection error envelope contains trace field (via _emit_error)
@test "BC_2_12_001: cycle detection error envelope contains trace field (H01/FB10)" {
  _setup_lobster_env
  local stdout_out
  stdout_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" 2>/dev/null || true)"
  _teardown_lobster_env
  [[ "$stdout_out" == *"E-LOBSTER-001"* ]]
  local trace_val
  trace_val="$(printf '%s' "$stdout_out" | head -1 | jq -r '.trace // ""' 2>/dev/null || true)"
  [ -n "$trace_val" ]
  [[ "$trace_val" =~ ^[0-9a-f-]+$ ]]
}

# M01: args element null → E-LOBSTER-003, exit 2 (not silent string coercion)
@test "BC_2_12_001: lobster-run args null element emits E-LOBSTER-003 exit 2 (M01/FB10)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/args-null-element.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"args element"* ]]
  [[ "$output" == *"null"* ]]
}

# M01: args null element error envelope contains trace field
@test "BC_2_12_001: lobster-run args null element error envelope contains trace field (M01/FB10)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/args-null-element.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  local trace_val
  trace_val="$(printf '%s' "$output" | head -1 | jq -r '.trace // ""' 2>/dev/null || true)"
  [ -n "$trace_val" ]
  [[ "$trace_val" =~ ^[0-9a-f-]+$ ]]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 11 — Adversary Pass 11 findings
# H01: interleaved positional+flag args bypass multi-file rejection
# M01: depends_on element type not validated (sibling-sweep from FB10)
# L01: top-level name/description lack type validation
# ---------------------------------------------------------------------------

# H01: interleaved workflow files (a.yaml --dry-run b.yaml) → E-LOBSTER-007, exit 2
@test "BC_2_12_001: lobster-run interleaved workflow files emits E-LOBSTER-007 exit 2 (H01/FB11)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/linear-dag.yaml" --dry-run "${FIXTURE_DIR}/diamond-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-007"* ]]
}

# H01: workflow file after flag does not silently overwrite first file
@test "BC_2_12_001: lobster-run rejects second workflow file even after intervening flag (H01/FB11)" {
  _setup_lobster_env
  # Verify exit 2 (not 0 from b silently replacing a)
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" --dry-run "${FIXTURE_DIR}/linear-dag.yaml"
  _teardown_lobster_env
  # Must exit 2 — the second positional must be rejected, not used
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-007"* ]]
}

# M01: depends_on element null → E-LOBSTER-003, exit 2 (parallel to args null from FB10)
@test "BC_2_12_001: lobster-run depends_on null element emits E-LOBSTER-003 exit 2 (M01/FB11)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/depends-on-null-element.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *"depends_on element"* ]]
  [[ "$output" == *"null"* ]]
}

# M01: depends_on null element error envelope contains trace field
@test "BC_2_12_001: lobster-run depends_on null element error envelope contains trace field (M01/FB11)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/depends-on-null-element.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  local trace_val
  trace_val="$(printf '%s' "$output" | head -1 | jq -r '.trace // ""' 2>/dev/null || true)"
  [ -n "$trace_val" ]
  [[ "$trace_val" =~ ^[0-9a-f-]+$ ]]
}

# L01: name as integer → E-LOBSTER-003, exit 2 (type validation before presence check)
@test "BC_2_12_001: lobster-run name as integer emits E-LOBSTER-003 exit 2 (L01/FB11)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/name-as-integer.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *".name"* ]]
}

# L01: description as integer → E-LOBSTER-003, exit 2
@test "BC_2_12_001: lobster-run description as integer emits E-LOBSTER-003 exit 2 (L01/FB11)" {
  _setup_lobster_env
  mkdir -p "${LOBSTER_PLUGIN_ROOT}/skills/init"
  printf -- '---\nname: init\n---\n' >"${LOBSTER_PLUGIN_ROOT}/skills/init/SKILL.md"
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/description-as-integer.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-003"* ]]
  [[ "$output" == *".description"* ]]
}

# ---------------------------------------------------------------------------
# STORY-032 Fix Burst 12 — Adversary Pass 13 findings
# C01: "--" branch lacks multi-file guard (sibling-sweep gap from FB11 H01)
# C02: "lobster-run --" crashes via set -e (bare shift on empty args)
# S01: cycle message can include non-cycle members (message text fix)
# ---------------------------------------------------------------------------

# C01: workflow file before "--" then another after — E-LOBSTER-007, exit 2
@test "BC_2_12_001: lobster-run rejects second workflow file after -- separator emits E-LOBSTER-007 exit 2 (C01/FB12)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/linear-dag.yaml" -- "${FIXTURE_DIR}/diamond-dag.yaml"
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-007"* ]]
}

# C02: bare "--" with no following file → E-LOBSTER-008, exit 2, completion event emitted
@test "BC_2_12_001: lobster-run bare -- emits E-LOBSTER-008 exit 2 and lobster.run.completed (C02/FB12)" {
  _setup_lobster_env
  # Capture stdout and stderr separately
  local stdout_out stderr_out
  stdout_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" -- 2>/dev/null || true)"
  stderr_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" -- 2>&1 >/dev/null || true)"
  _teardown_lobster_env
  # stdout must contain E-LOBSTER-008
  [[ "$stdout_out" == *"E-LOBSTER-008"* ]]
  # lobster.run.completed must appear on stderr (not silently aborted by set -e)
  local completed_event
  completed_event="$(printf '%s' "$stderr_out" | grep 'lobster.run.completed' || true)"
  [ -n "$completed_event" ]
}

# C02: exit code from bare "--" must be 2, not crash exit code
@test "BC_2_12_001: lobster-run bare -- exits with code 2 (C02/FB12)" {
  _setup_lobster_env
  run env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" --
  _teardown_lobster_env
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-LOBSTER-008"* ]]
}

# S01: cycle message uses accurate "unresolved dependencies" phrasing
@test "BC_2_12_001: lobster-run cycle message uses accurate unresolved-dependencies phrasing (S01/FB12)" {
  _setup_lobster_env
  local stdout_out
  stdout_out="$(env CLAUDE_PLUGIN_ROOT="${LOBSTER_PLUGIN_ROOT}" \
    BRAIN_ROOT="${LOBSTER_BRAIN}" \
    "${LOBSTER_BIN}" "${FIXTURE_DIR}/cycle-dag.yaml" 2>/dev/null || true)"
  _teardown_lobster_env
  [[ "$stdout_out" == *"E-LOBSTER-001"* ]]
  # New message phrasing (S01 fix) — must NOT use old "Circular dependency detected" text
  [[ "$stdout_out" == *"unresolved dependencies"* ]]
  # Must still identify affected step IDs
  [[ "$stdout_out" == *"step-a"* ]]
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

# ===========================================================================
# STORY-019: Integration tests for /brain:ingest-source pipeline
# Traces to: BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004
# VP coverage: VP-016 (local source ingest pipeline), VP-012 (manifest atomicity)
#
# NOTE on event-catalog: The 5 structured event types
# (ingest.source.started, ingest.source.path_rejected, ingest.source.written,
# ingest.source.wiki_pages_generated, ingest.source.completed) and error codes
# E-INGEST-009/010/011 must be pre-registered in scripts/event-catalog.json
# by the implementer before emit calls are added. That is implementer scope.
#
# NOTE on readlink -f: Architecture Compliance Rule 1 mandates readlink -f;
# do NOT use realpath (not portable on macOS without GNU coreutils).
#
# Integration test strategy: we test the script-level pipeline helpers that
# /brain:ingest-source will delegate to — validate-ingest-path.sh (path gate),
# manifest-write.sh (atomic manifest delta with `path` not `url`), and
# generate-wiki.sh + log-tokens.sh (wiki fan-out). The partial-failure fan-out
# tests inject a directory write-protection failure for exactly one of N pages,
# mirroring the approach in the STORY-017 generate-wiki.sh tests above.
# ===========================================================================

# ---------------------------------------------------------------------------
# Integration setup: git-init'd vault with full brain scaffold
# ---------------------------------------------------------------------------
_setup_ingest_source_vault() {
  INGEST_VAULT="$(mktemp -d)"
  git init "$INGEST_VAULT" >/dev/null 2>&1
  mkdir -p "${INGEST_VAULT}/.brain/logs"
  mkdir -p "${INGEST_VAULT}/sources/ai"
  mkdir -p "${INGEST_VAULT}/wiki/concepts" \
    "${INGEST_VAULT}/wiki/people" \
    "${INGEST_VAULT}/wiki/frameworks" \
    "${INGEST_VAULT}/wiki/syntheses" \
    "${INGEST_VAULT}/wiki/observations" \
    "${INGEST_VAULT}/wiki/questions"
  printf '{"sources":{}}\n' >"${INGEST_VAULT}/.brain/manifest.json"
  cat >"${INGEST_VAULT}/wiki/index.md" <<'IDXEOF'
---
type: index
title: "Wiki Index"
---

# Wiki Index
IDXEOF
  cat >"${INGEST_VAULT}/wiki/log.md" <<'LOGEOF'
---
type: log
title: "Ingest Log"
---

# Ingest Log
LOGEOF
  export BRAIN_ROOT="$INGEST_VAULT"
}

_teardown_ingest_source_vault() {
  rm -rf "${INGEST_VAULT:-}"
}

# ---------------------------------------------------------------------------
# Helper: _write_ingest_source_file
#
# Writes the happy-path fixture into sources/{topic}/{slug}.md with the
# correct source frontmatter (path field, not url).
# Mirrors the expected output of steps 6-7 in SKILL.md Procedure.
# ---------------------------------------------------------------------------
_write_ingest_source_file() {
  local vault_dir="$1"
  local topic="$2"
  local slug="$3"
  local original_path="$4"

  mkdir -p "${vault_dir}/sources/${topic}"
  local dest="${vault_dir}/sources/${topic}/${slug}.md"
  local ingested_at
  ingested_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local relative_path="sources/${topic}/${slug}.md"

  # Write frontmatter using a quoted heredoc (no expansion inside) for the static
  # fields, then substitute the dynamic fields via printf before writing.
  # Body is appended separately (not embedded in heredoc) to avoid ## markdown
  # headings breaking yq full-file YAML parse in subsequent yq --front-matter=extract tests.
  {
    printf -- '---\n'
    printf 'title: "The Practical Guide to Retrieval-Augmented Generation"\n'
    printf 'path: "%s"\n' "$relative_path"
    printf 'ingested_at: "%s"\n' "$ingested_at"
    printf 'source_id: "%s"\n' "$slug"
    printf 'topic: "%s"\n' "$topic"
    printf 'embedding_status: pending\n'
    printf -- '---\n\n'
    cat "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md"
  } >"$dest"
  printf '%s' "$dest"
}

# ---------------------------------------------------------------------------
# Helper: _write_ingest_source_manifest_entry
#
# Appends a local-source manifest entry (path field, NOT url field) via
# manifest-write.sh. Returns the manifest path.
# ---------------------------------------------------------------------------
_write_ingest_source_manifest_entry() {
  local vault_dir="$1"
  local slug="$2"
  local topic="$3"
  local relative_path="sources/${topic}/${slug}.md"
  local manifest="${vault_dir}/.brain/manifest.json"
  local ingested_at
  ingested_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  local entry
  entry="$(printf '{"source_id":"%s","path":"%s","topic":"%s","ingested_at":"%s","last_ingest":"%s","chunks":[],"embeddings_model":null}' \
    "$slug" "$relative_path" "$topic" "$ingested_at" "$ingested_at")"

  # shellcheck source=/dev/null
  (
    BRAIN_DIR="$vault_dir"
    export BRAIN_DIR
    source "${PLUGIN_DIR}/hooks/lib/manifest-write.sh"
    manifest_write "$entry" "$manifest"
  )
}

# ===========================================================================
# AC-001 / AC-002 / AC-007 / BC-2.03.001 postconditions 1-5; BC-2.03.002 postcondition 1:
# Successful ingest → source file written with `path` field (not `url`); 5+ wiki pages;
# token record appended; exit 0
# Exercises VP-016 (ingest pipeline) and VP-012 (manifest path field)
# ===========================================================================
@test "BC_2_03_001: path validation gate passes for valid vault-relative file before source write (AC-001)" {
  # Traces to: BC-2.03.001 postcondition 1; BC-2.03.003 happy-path postcondition
  # The path validation gate (validate-ingest-path.sh) must exit 0 for a valid
  # vault-relative file before any source write. The stub exits 3 with E-STUB.
  # RED GATE: validate-ingest-path.sh stub exits 3; test asserts exit 0 → FAILS
  _setup_ingest_source_vault

  # Create a valid markdown file inside the vault (happy-path fixture)
  local test_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  mkdir -p "${INGEST_VAULT}/sources/ai"
  cp "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" "$test_file"

  # The validate-ingest-path.sh gate must exit 0 for a file inside the vault.
  # Without this gate passing, no source file can be written.
  run env BRAIN_ROOT="$INGEST_VAULT" \
    bash "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" "$test_file"

  # Must exit 0 (accepted)
  [ "$status" -eq 0 ]
  # Must print the readlink -f resolved absolute path
  local resolved
  resolved="$(readlink -f "$test_file")"
  [[ "$output" == *"$resolved"* ]]

  _teardown_ingest_source_vault
}

@test "BC_2_03_002: successful ingest appends manifest entry with path field not url (AC-007/VP-012)" {
  # Traces to: BC-2.03.002 postcondition 1; VP-012 manifest path field
  # BC-2.03.002 invariant 1: local-source entries use `path` not `url`
  # RED GATE: manifest-write.sh is IMPLEMENTED (STORY-016 deliverable) — this test
  # passes once we call it with a properly structured entry. The Red Gate here is
  # that the validate-ingest-path.sh stub (exit 3) prevents the real ingest skill
  # from reaching this step. The helper _write_ingest_source_manifest_entry directly
  # calls manifest-write.sh to test the contract that path (not url) is stored.
  # Assertion: manifest entry has `path` field — verifies BC-2.03.002 invariant 1.
  _setup_ingest_source_vault
  local manifest="${INGEST_VAULT}/.brain/manifest.json"

  # Write source file first (precondition for manifest step)
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  # Call manifest-write.sh to append entry with path field
  _write_ingest_source_manifest_entry "$INGEST_VAULT" "rag-guide" "ai"

  # Manifest must have exactly 1 entry
  local count
  count="$(jq '.sources | length' "$manifest")"
  [ "$count" -eq 1 ]

  # Entry must have `path` field (not url — BC-2.03.002 invariant 1)
  local path_val
  path_val="$(jq -r 'first(.sources[]).path' "$manifest")"
  [ -n "$path_val" ]
  [ "$path_val" != "null" ]

  # Entry must NOT have `url` field
  local url_val
  url_val="$(jq -r 'first(.sources[]).url // "absent"' "$manifest")"
  [ "$url_val" = "absent" ]

  _teardown_ingest_source_vault
}

@test "BC_2_03_001: ingest pipeline produces 5+ wiki pages via generate-wiki.sh (AC-002/VP-016)" {
  # Traces to: BC-2.03.001 postconditions 2-3; VP-016 wiki generation
  # RED GATE: scripts/generate-wiki.sh not implemented → no wiki pages created → count < 5 → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file"
  [ "$status" -eq 0 ]

  local wiki_count
  wiki_count="$(find "${INGEST_VAULT}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' | wc -l | tr -d ' ')"
  [ "$wiki_count" -ge 5 ]

  _teardown_ingest_source_vault
}

@test "BC_2_03_001: token record appended to .brain/logs/ingest-tokens.jsonl on successful ingest (AC-002)" {
  # Traces to: BC-2.03.001 postcondition 4; log-tokens.sh integration
  # RED GATE: scripts/log-tokens.sh not implemented → JSONL file not created → FAILS
  _setup_ingest_source_vault

  run bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$INGEST_VAULT" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" \
    "rag-guide" \
    "1200" \
    "600" \
    "7" \
    "10"
  [ "$status" -eq 0 ]
  [ -f "${INGEST_VAULT}/.brain/logs/ingest-tokens.jsonl" ]

  # Record must exist and be valid JSONL
  local record
  record="$(tail -1 "${INGEST_VAULT}/.brain/logs/ingest-tokens.jsonl")"
  [ -n "$record" ]
  run jq -e '.' <<<"$record"
  [ "$status" -eq 0 ]

  _teardown_ingest_source_vault
}

# ===========================================================================
# AC-008 / BC-2.03.002 postconditions 2-3 + EC-001:
# Existing manifest entries NOT modified; atomic write; manifest write failure
# → source rolled back + E-INGEST-008
# Exercises VP-012 (manifest atomicity)
# ===========================================================================
@test "BC_2_03_002: second ingest does not modify first entry (existing entries preserved) (AC-008)" {
  # Traces to: BC-2.03.002 postcondition 2; VP-012
  # RED GATE: manifest-write.sh stub returns 1 → count stays 0 → second entry doesn't exist → FAILS
  _setup_ingest_source_vault

  # First entry
  _write_ingest_source_file "$INGEST_VAULT" "ai" "first-source" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null
  _write_ingest_source_manifest_entry "$INGEST_VAULT" "first-source" "ai"

  # Second entry
  local second_file="${INGEST_VAULT}/sources/ai/second-source.md"
  cp "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" "$second_file"
  _write_ingest_source_manifest_entry "$INGEST_VAULT" "second-source" "ai"

  local count
  count="$(jq '.sources | length' "${INGEST_VAULT}/.brain/manifest.json")"
  [ "$count" -eq 2 ]

  # First entry must still be present with original source_id
  local first_id
  first_id="$(jq -r '.sources["sources/ai/first-source.md"].source_id' \
    "${INGEST_VAULT}/.brain/manifest.json")"
  [ "$first_id" = "first-source" ]

  _teardown_ingest_source_vault
}

@test "BC_2_03_002: manifest write failure rolls back source file and emits E-INGEST-008 (AC-008)" {
  # Traces to: BC-2.03.002 EC-001; VP-012 atomicity
  # RED GATE: manifest-write.sh stub does not emit E-INGEST-008 → assertion FAILS
  _setup_ingest_source_vault

  local manifest="${INGEST_VAULT}/.brain/manifest.json"

  # Make manifest read-only to simulate write failure
  chmod 444 "$manifest"

  local entry
  entry='{"source_id":"rollback-test","path":"sources/ai/rollback-test.md","topic":"ai","ingested_at":"2026-05-30T00:00:00Z","last_ingest":"2026-05-30T00:00:00Z","chunks":[],"embeddings_model":null}'

  local err_out
  err_out="$(bash -c "
    source '${PLUGIN_DIR}/hooks/lib/manifest-write.sh'
    BRAIN_DIR='${INGEST_VAULT}'
    manifest_write '${entry}' '${manifest}'
  " 2>&1 || true)"

  # Restore for teardown
  chmod 644 "$manifest"

  # Must emit E-INGEST-008
  [[ "$err_out" == *"E-INGEST-008"* ]]

  _teardown_ingest_source_vault
}

@test "BC_2_03_002: manifest write is atomic (uses .tmp+mv pattern) (VP-012)" {
  # Traces to: BC-2.03.002 postcondition 3; VP-012 atomicity property
  # RED GATE: manifest-write.sh stub does not contain .tmp → assertion fails → FAILS
  local manifest_lib="${PLUGIN_DIR}/hooks/lib/manifest-write.sh"
  grep -q '\.tmp' "$manifest_lib" || {
    echo "FAIL: manifest-write.sh does not contain .tmp pattern" >&2
    return 1
  }
  grep -q '\bmv\b' "$manifest_lib" || {
    echo "FAIL: manifest-write.sh does not contain mv (atomic rename)" >&2
    return 1
  }
}

# ===========================================================================
# AC-013 / AC-015 / BC-2.03.004 postconditions 1-3 + invariant 1:
# 10 pages planned, 1 hook-blocked → pages_failed:1, pages_created:9,
# pages_attempted:10; exit 1
# Exercises VP-016 (partial failure reported accurately)
# Injection mechanism: chmod 555 on concepts/ (mirrors STORY-017 approach)
# ===========================================================================
@test "BC_2_03_004: partial failure (1 hook-blocked) exits 1 with pages_failed:1 pages_created:N-1 (AC-013/AC-015)" {
  # Traces to: BC-2.03.004 postconditions 1-2; invariant 1
  # VP-016: partial failure reported accurately
  # Injection: make wiki/concepts/ read-only to block any concept pages
  # RED GATE: generate-wiki.sh not implemented → run fails or exits wrong code → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  # Block writes to concepts/ to inject exactly one failure category
  chmod 555 "${INGEST_VAULT}/wiki/concepts"

  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file"

  # Restore before any assertion that might short-circuit teardown
  chmod 755 "${INGEST_VAULT}/wiki/concepts"

  # exit 1 = partial failure (advisory — pages_failed > 0)
  [ "$status" -eq 1 ]

  # Output must be a JSON fan-out envelope
  local pages_attempted pages_created pages_failed
  pages_attempted="$(printf '%s' "$output" | jq -r '.pages_attempted' 2>/dev/null || true)"
  pages_created="$(printf '%s' "$output" | jq -r '.pages_created' 2>/dev/null || true)"
  pages_failed="$(printf '%s' "$output" | jq -r '.pages_failed' 2>/dev/null || true)"

  [ -n "$pages_attempted" ]
  [ "$pages_attempted" != "null" ]
  [ -n "$pages_failed" ]
  [ "$pages_failed" -ge 1 ]
  [ -n "$pages_created" ]
  [ "$pages_created" -ge 1 ]

  _teardown_ingest_source_vault
}

@test "BC_2_03_004: pages_attempted == pages_created + pages_failed invariant holds on partial failure (AC-015)" {
  # Traces to: BC-2.03.004 invariant 1; STORY-019 Test Vectors (invariant row)
  # VP-016: pages_attempted = pages_created + pages_failed in all scenarios
  # RED GATE: generate-wiki.sh not implemented → output not parseable → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  # Inject hook failure for concepts/ pages
  chmod 555 "${INGEST_VAULT}/wiki/concepts"

  local envelope
  envelope="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file" 2>/dev/null || true)"

  chmod 755 "${INGEST_VAULT}/wiki/concepts"

  local pages_attempted pages_created pages_failed
  pages_attempted="$(printf '%s' "$envelope" | jq -r '.pages_attempted' 2>/dev/null || true)"
  pages_created="$(printf '%s' "$envelope" | jq -r '.pages_created' 2>/dev/null || true)"
  pages_failed="$(printf '%s' "$envelope" | jq -r '.pages_failed' 2>/dev/null || true)"

  # All three fields must be numeric
  [[ "$pages_attempted" =~ ^[0-9]+$ ]]
  [[ "$pages_created" =~ ^[0-9]+$ ]]
  [[ "$pages_failed" =~ ^[0-9]+$ ]]

  # Invariant: pages_attempted == pages_created + pages_failed
  local computed_sum
  computed_sum=$(( pages_created + pages_failed ))
  [ "$pages_attempted" -eq "$computed_sum" ]

  _teardown_ingest_source_vault
}

@test "BC_2_03_004: pages_attempted == pages_created + pages_failed invariant holds on full success (AC-015)" {
  # Traces to: BC-2.03.004 invariant 1 (happy path scenario)
  # RED GATE: generate-wiki.sh not implemented → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  local envelope
  envelope="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file" 2>/dev/null || true)"

  local pages_attempted pages_created pages_failed
  pages_attempted="$(printf '%s' "$envelope" | jq -r '.pages_attempted' 2>/dev/null || true)"
  pages_created="$(printf '%s' "$envelope" | jq -r '.pages_created' 2>/dev/null || true)"
  pages_failed="$(printf '%s' "$envelope" | jq -r '.pages_failed' 2>/dev/null || true)"

  [[ "$pages_attempted" =~ ^[0-9]+$ ]]
  [[ "$pages_created" =~ ^[0-9]+$ ]]
  [[ "$pages_failed" =~ ^[0-9]+$ ]]

  local computed_sum
  computed_sum=$(( pages_created + pages_failed ))
  [ "$pages_attempted" -eq "$computed_sum" ]

  _teardown_ingest_source_vault
}

# ===========================================================================
# AC-014 / BC-2.03.004 postcondition 3 + invariant 2:
# failures array is always present in envelope, never absent, even when empty
# ===========================================================================
@test "BC_2_03_004: fan-out envelope always includes failures array even when empty (AC-014)" {
  # Traces to: BC-2.03.004 postcondition 3; invariant 2 (no silent omission)
  # VP-016: no silent swallow on failed pages
  # RED GATE: generate-wiki.sh not implemented → no JSON output → jq parse fails → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  local envelope
  envelope="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file" 2>/dev/null || true)"

  # failures key must exist (type must be array, not null/absent)
  local failures_type
  failures_type="$(printf '%s' "$envelope" | jq -r '.failures | type' 2>/dev/null || true)"
  [ "$failures_type" = "array" ]

  _teardown_ingest_source_vault
}

@test "BC_2_03_004: fan-out envelope failures array present on partial failure with failure entries (AC-014)" {
  # Traces to: BC-2.03.004 postcondition 3; no failed page silently omitted
  # RED GATE: generate-wiki.sh not implemented → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  # Block concepts/ to inject failures
  chmod 555 "${INGEST_VAULT}/wiki/concepts"

  local envelope
  envelope="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file" 2>/dev/null || true)"

  chmod 755 "${INGEST_VAULT}/wiki/concepts"

  # failures array must exist and be non-empty (partial failure occurred)
  local failures_type failures_count
  failures_type="$(printf '%s' "$envelope" | jq -r '.failures | type' 2>/dev/null || true)"
  failures_count="$(printf '%s' "$envelope" | jq -r '.failures | length' 2>/dev/null || true)"
  [ "$failures_type" = "array" ]
  [ "$failures_count" -ge 1 ]

  # Each failure entry must have slug and error fields
  local first_slug first_error
  first_slug="$(printf '%s' "$envelope" | jq -r '.failures[0].slug' 2>/dev/null || true)"
  first_error="$(printf '%s' "$envelope" | jq -r '.failures[0].error' 2>/dev/null || true)"
  [ -n "$first_slug" ]
  [ "$first_slug" != "null" ]
  [ -n "$first_error" ]
  [ "$first_error" != "null" ]

  _teardown_ingest_source_vault
}

# ===========================================================================
# AC-017 / BC-2.03.004 EC-001:
# All pages blocked → pages_created:0; pages_failed:N; source + manifest stand; exit 1
# ===========================================================================
@test "BC_2_03_004: all pages blocked exits 1 with pages_created:0 and pages_failed:N (AC-017)" {
  # Traces to: BC-2.03.004 EC-001 (all 0 of N created)
  # Injection: block ALL wiki subdirectories simultaneously
  # RED GATE: generate-wiki.sh not implemented → FAILS
  _setup_ingest_source_vault

  local source_file="${INGEST_VAULT}/sources/ai/rag-guide.md"
  _write_ingest_source_file "$INGEST_VAULT" "ai" "rag-guide" \
    "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" >/dev/null

  # Write manifest entry so source "stands" for assertion
  _write_ingest_source_manifest_entry "$INGEST_VAULT" "rag-guide" "ai"

  # Block ALL wiki type directories to force total failure
  chmod 555 "${INGEST_VAULT}/wiki/concepts" \
    "${INGEST_VAULT}/wiki/people" \
    "${INGEST_VAULT}/wiki/frameworks" \
    "${INGEST_VAULT}/wiki/syntheses" \
    "${INGEST_VAULT}/wiki/observations" \
    "${INGEST_VAULT}/wiki/questions"

  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$INGEST_VAULT" \
    "$source_file"

  # Restore before teardown assertions
  chmod 755 "${INGEST_VAULT}/wiki/concepts" \
    "${INGEST_VAULT}/wiki/people" \
    "${INGEST_VAULT}/wiki/frameworks" \
    "${INGEST_VAULT}/wiki/syntheses" \
    "${INGEST_VAULT}/wiki/observations" \
    "${INGEST_VAULT}/wiki/questions"

  # exit 1 = advisory (all pages failed but source + manifest stand)
  [ "$status" -eq 1 ]

  # pages_created must be 0
  local pages_created
  pages_created="$(printf '%s' "$output" | jq -r '.pages_created' 2>/dev/null || true)"
  [ "$pages_created" = "0" ]

  # pages_failed must be > 0 (at least some pages were attempted)
  local pages_failed
  pages_failed="$(printf '%s' "$output" | jq -r '.pages_failed' 2>/dev/null || true)"
  [ "$pages_failed" -ge 1 ]

  # Source file must still exist (not rolled back on wiki failure)
  [ -f "$source_file" ]

  # Manifest entry must still exist (not rolled back on wiki failure)
  local manifest_count
  manifest_count="$(jq '.sources | length' "${INGEST_VAULT}/.brain/manifest.json")"
  [ "$manifest_count" -ge 1 ]

  _teardown_ingest_source_vault
}

# ===========================================================================
# AC-010 / AC-012 / BC-2.03.003 invariant 2 (integration):
# System directory /etc/ blocked even when in policies.yaml allowlist
# ===========================================================================
@test "BC_2_03_003: system dir /etc/ blocked even if in allowlist (integration; AC-010/AC-012)" {
  # Traces to: BC-2.03.003 invariant 2; AC-012 security clause
  # This is the integration-level check: validate-ingest-path.sh is called
  # by the full ingest pipeline; system dirs must never reach source write.
  # RED GATE: validate-ingest-path.sh stub exits 3; test asserts exit 2 → FAILS
  INGEST_VAULT="$(mktemp -d)"
  git init "$INGEST_VAULT" >/dev/null 2>&1
  mkdir -p "${INGEST_VAULT}/.brain"
  printf '{"sources":{}}\n' >"${INGEST_VAULT}/.brain/manifest.json"
  # Put /etc/ in the allowlist — must still be blocked
  printf 'allowed_external_paths:\n  - /etc/\n' \
    >"${INGEST_VAULT}/.brain/policies.yaml"

  run env BRAIN_ROOT="$INGEST_VAULT" \
    bash "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" "/etc/passwd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  rm -rf "$INGEST_VAULT"
}
