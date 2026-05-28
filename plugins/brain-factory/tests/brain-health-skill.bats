#!/usr/bin/env bats
# STORY-004 Red Gate tests: brain-health skill (skills/brain-health/run.sh)
# Traces to: BC-2.01.006, VP-024
#
# These tests MUST FAIL before run.sh is implemented (Red Gate).
# They go green once the six-dimensional JSON health skill is implemented.
#
# Exit code contract for the skill (not the hook):
#   0 — healthy or partially degraded (JSON report emitted)
#   2 — unrecoverable error (E-HEALTH-001: STATE.md missing)
#
# Test naming: BC_2_01_006: <description>

WORKTREE_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../../.." && pwd)"

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  RUN_SH="${PLUGIN_DIR}/skills/brain-health/run.sh"

  # Create a fresh temp brain dir for each test
  BRAIN_DIR="$(mktemp -d)"
  export BRAIN_ROOT="${BRAIN_DIR}"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: run the init skill to scaffold a complete brain.
# After init, the brain has STATE.md, manifest.json, wiki/, briefs/,
# inbox/, etc. — the minimal valid state.
# ---------------------------------------------------------------------------
_init_brain() {
  git -C "${BRAIN_DIR}" init -q
  bash "${PLUGIN_DIR}/skills/init/run.sh" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# Helper: write N wiki page files (non-index/log .md) into wiki/concepts/
# so the wiki dimension can detect real content.
# ---------------------------------------------------------------------------
_add_wiki_pages() {
  local count="${1:-1}"
  local i
  for i in $(seq 1 "${count}"); do
    cat >"${BRAIN_DIR}/wiki/concepts/page-${i}.md" <<EOF
---
type: concept
title: "Test Concept ${i}"
embedding_status: pending
---
# Test Concept ${i}
EOF
  done
}

# ---------------------------------------------------------------------------
# Helper: add a weekly brief so synthesis dimension is GREEN.
# ---------------------------------------------------------------------------
_add_weekly_brief() {
  echo "# Weekly brief" > "${BRAIN_DIR}/briefs/weekly/week-$(date +%Y-%m-%d).md"
}

# ---------------------------------------------------------------------------
# Helper: add a content brief so output dimension is GREEN.
# ---------------------------------------------------------------------------
_add_content_brief() {
  echo "# Content brief" > "${BRAIN_DIR}/briefs/content/draft-001.md"
}

# ---------------------------------------------------------------------------
# Helper: write token log entries to .brain/logs/ingest-tokens.jsonl.
# Each entry: {"date":"YYYY-MM-DD","tokens":NNN}
# $1 — number of entries
# $2 — token count per entry
# ---------------------------------------------------------------------------
_write_token_log() {
  local count="$1"
  local tokens="$2"
  local log_path="${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl"
  mkdir -p "${BRAIN_DIR}/.brain/logs"
  local i
  for i in $(seq 1 "${count}"); do
    local date_str
    date_str="$(date -u -v-${i}d +%Y-%m-%d 2>/dev/null || date -u -d "-${i} days" +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)"
    printf '{"date":"%s","tokens":%s}\n' "${date_str}" "${tokens}" >> "${log_path}"
  done
}

# ===========================================================================
# AC-001 / BC-2.01.006 postconditions 1-2:
# Healthy brain exits 0 and emits a fully-GREEN six-dimensional JSON report.
# FAILS before implementation: run.sh does not exist → exit 127.
# ===========================================================================

@test "BC_2_01_006: healthy brain overall=GREEN exits 0" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall
  overall="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall}" = "GREEN" ]
}

@test "BC_2_01_006: healthy brain emits all six dimensions in JSON" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # Every canonical dimension key must exist
  local has_capture has_sources has_wiki has_synthesis has_output has_reflection
  has_capture="$(printf '%s' "${output}" | jq 'has("dimensions") and (.dimensions | has("capture"))')"
  has_sources="$(printf '%s' "${output}" | jq 'has("dimensions") and (.dimensions | has("sources"))')"
  has_wiki="$(printf '%s' "${output}" | jq 'has("dimensions") and (.dimensions | has("wiki"))')"
  has_synthesis="$(printf '%s' "${output}" | jq 'has("dimensions") and (.dimensions | has("synthesis"))')"
  has_output="$(printf '%s' "${output}" | jq 'has("dimensions") and (.dimensions | has("output"))')"
  has_reflection="$(printf '%s' "${output}" | jq 'has("dimensions") and (.dimensions | has("reflection"))')"
  [ "${has_capture}" = "true" ]
  [ "${has_sources}" = "true" ]
  [ "${has_wiki}" = "true" ]
  [ "${has_synthesis}" = "true" ]
  [ "${has_output}" = "true" ]
  [ "${has_reflection}" = "true" ]
}

@test "BC_2_01_006: healthy brain all six dimensions GREEN" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local capture sources wiki synthesis output_dim reflection
  capture="$(printf '%s' "${output}" | jq -r '.dimensions.capture.status')"
  sources="$(printf '%s' "${output}" | jq -r '.dimensions.sources.status')"
  wiki="$(printf '%s' "${output}" | jq -r '.dimensions.wiki.status')"
  synthesis="$(printf '%s' "${output}" | jq -r '.dimensions.synthesis.status')"
  output_dim="$(printf '%s' "${output}" | jq -r '.dimensions.output.status')"
  reflection="$(printf '%s' "${output}" | jq -r '.dimensions.reflection.status')"
  [ "${capture}" = "GREEN" ]
  [ "${sources}" = "GREEN" ]
  [ "${wiki}" = "GREEN" ]
  [ "${synthesis}" = "GREEN" ]
  [ "${output_dim}" = "GREEN" ]
  [ "${reflection}" = "GREEN" ]
}

# ===========================================================================
# AC-002 / BC-2.01.006 postcondition 3 / invariant 1:
# overall aggregation logic — RED > YELLOW > GREEN.
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: overall=RED when any dimension is RED" {
  _init_brain
  # Force sources to RED by removing manifest.json (invalid JSON surface)
  rm -f "${BRAIN_DIR}/.brain/manifest.json"
  run bash "${RUN_SH}"
  local overall
  overall="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall}" = "RED" ]
}

@test "BC_2_01_006: overall=YELLOW when any dimension YELLOW and none RED" {
  # Init produces wiki=YELLOW (no pages) and synthesis=YELLOW (no weekly briefs)
  # and output=YELLOW (no content briefs) — none RED → overall YELLOW
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall
  overall="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall}" = "YELLOW" ]
}

@test "BC_2_01_006: overall=GREEN only when all six dimensions GREEN" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall
  overall="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall}" = "GREEN" ]
}

# ===========================================================================
# AC-003 / BC-2.01.006 invariant 2:
# Status values are exactly GREEN, YELLOW, or RED (uppercase).
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: all dimension status values are GREEN YELLOW or RED uppercase" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local dims
  dims="$(printf '%s' "${output}" | jq -r '.dimensions | to_entries[] | .value.status')"
  local s
  while IFS= read -r s; do
    [[ "${s}" =~ ^(GREEN|YELLOW|RED)$ ]]
  done <<< "${dims}"
}

@test "BC_2_01_006: overall status value is GREEN YELLOW or RED uppercase" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall
  overall="$(printf '%s' "${output}" | jq -r '.overall')"
  [[ "${overall}" =~ ^(GREEN|YELLOW|RED)$ ]]
}

# ===========================================================================
# AC-004 / BC-2.01.006 edge case EC-001:
# Missing ingest-tokens.jsonl → sources=GREEN "No ingest history yet."
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: missing ingest-tokens.jsonl sources dimension GREEN" {
  _init_brain
  # After init there is no ingest-tokens.jsonl — verify the log does not exist
  [ ! -f "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" ]
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local sources_status
  sources_status="$(printf '%s' "${output}" | jq -r '.dimensions.sources.status')"
  [ "${sources_status}" = "GREEN" ]
}

@test "BC_2_01_006: missing ingest-tokens.jsonl sources detail is No ingest history yet" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local sources_detail
  sources_detail="$(printf '%s' "${output}" | jq -r '.dimensions.sources.detail')"
  [ "${sources_detail}" = "No ingest history yet." ]
}

# ===========================================================================
# AC-005 / BC-2.01.006 postcondition 4:
# Token avg > 100K (2x baseline) → sources YELLOW with "token budget" in detail.
# Token avg > 200K (4x baseline) → sources RED.
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: token avg over 100K sources=YELLOW with token budget in detail" {
  _init_brain
  # Write 5 entries at 105,000 tokens each (within 30-day window)
  _write_token_log 5 105000
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local sources_status sources_detail
  sources_status="$(printf '%s' "${output}" | jq -r '.dimensions.sources.status')"
  sources_detail="$(printf '%s' "${output}" | jq -r '.dimensions.sources.detail')"
  [ "${sources_status}" = "YELLOW" ]
  [[ "${sources_detail}" == *"token budget"* ]]
}

@test "BC_2_01_006: token avg over 200K sources=RED" {
  _init_brain
  # Write 5 entries at 210,000 tokens each (4x+ the 50K baseline)
  _write_token_log 5 210000
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local sources_status
  sources_status="$(printf '%s' "${output}" | jq -r '.dimensions.sources.status')"
  [ "${sources_status}" = "RED" ]
}

@test "BC_2_01_006: token avg over 100K detail contains actual average value" {
  _init_brain
  _write_token_log 5 105000
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local sources_detail
  sources_detail="$(printf '%s' "${output}" | jq -r '.dimensions.sources.detail')"
  # The detail must include the numeric average (105000)
  [[ "${sources_detail}" == *"105000"* ]]
}

# ===========================================================================
# AC-006 / BC-2.01.006 edge case EC-002:
# Missing .brain/STATE.md → E-HEALTH-001 JSON emitted, exit 2.
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: missing STATE.md emits E-HEALTH-001 exit 2" {
  _init_brain
  # Remove STATE.md to trigger the precondition violation
  rm -f "${BRAIN_DIR}/.brain/STATE.md"
  run bash "${RUN_SH}"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "${output}" | jq -r '.code')"
  [ "${code}" = "E-HEALTH-001" ]
}

@test "BC_2_01_006: missing STATE.md emitted JSON has level=error" {
  _init_brain
  rm -f "${BRAIN_DIR}/.brain/STATE.md"
  run bash "${RUN_SH}"
  [ "$status" -eq 2 ]
  local level
  level="$(printf '%s' "${output}" | jq -r '.level')"
  [ "${level}" = "error" ]
}

@test "BC_2_01_006: missing STATE.md error JSON has non-empty trace field" {
  _init_brain
  rm -f "${BRAIN_DIR}/.brain/STATE.md"
  run bash "${RUN_SH}"
  [ "$status" -eq 2 ]
  local trace
  trace="$(printf '%s' "${output}" | jq -r '.trace')"
  [ -n "${trace}" ]
  [ "${trace}" != "null" ]
}

# ===========================================================================
# AC-007 / BC-2.01.006 edge case EC-003:
# 0 wiki pages (no .md files under wiki/ except index.md and log.md)
# → wiki=YELLOW "No wiki pages yet — ingest your first source."
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: zero wiki pages wiki dimension YELLOW" {
  _init_brain
  # After init: only wiki/index.md, wiki/log.md, and _template.md files exist
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local wiki_status
  wiki_status="$(printf '%s' "${output}" | jq -r '.dimensions.wiki.status')"
  [ "${wiki_status}" = "YELLOW" ]
}

@test "BC_2_01_006: zero wiki pages wiki detail is No wiki pages yet" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local wiki_detail
  wiki_detail="$(printf '%s' "${output}" | jq -r '.dimensions.wiki.detail')"
  [ "${wiki_detail}" = "No wiki pages yet — ingest your first source." ]
}

# ===========================================================================
# AC-008 / BC-2.01.006 postcondition 2:
# last_checked is a valid ISO8601 UTC timestamp.
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: last_checked field is present in JSON output" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local last_checked
  last_checked="$(printf '%s' "${output}" | jq -r '.last_checked')"
  [ -n "${last_checked}" ]
  [ "${last_checked}" != "null" ]
}

@test "BC_2_01_006: last_checked is valid ISO8601 UTC format" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local last_checked
  last_checked="$(printf '%s' "${output}" | jq -r '.last_checked')"
  # ISO8601 UTC: YYYY-MM-DDTHH:MM:SSZ
  [[ "${last_checked}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# ===========================================================================
# AC-009 / BC-2.01.006 edge case EC-002 / VP-024:
# Non-brain directory (no .brain/STATE.md) → skill callable without crash.
# Must exit ≤ 1 for a soft-fail, or exit 2 only when EC-002 applies.
# Structured JSON always emitted. No unhandled bash error crash.
# FAILS before implementation.
# ===========================================================================

@test "BC_2_01_006: non-brain dir invocation does not crash (VP-024 health-callable)" {
  # BRAIN_DIR has no .brain/ — completely empty temp dir, not even a git repo.
  # The implementation always exits 2 on missing STATE.md via E-HEALTH-001.
  run bash "${RUN_SH}"
  # Must exit exactly 2 — E-HEALTH-001 applies when STATE.md is absent.
  [ "$status" -eq 2 ]
  # Must emit the E-HEALTH-001 structured error envelope, not a raw bash error.
  local code
  code="$(printf '%s' "${output}" | jq -r '.code')"
  [ "${code}" = "E-HEALTH-001" ]
}

@test "BC_2_01_006: non-brain dir emits structured JSON not raw bash error" {
  run bash "${RUN_SH}"
  # Must exit 2 (E-HEALTH-001 applies — no STATE.md present).
  [ "$status" -eq 2 ]
  # The output must be parseable JSON — not a bash error message.
  local parsed
  parsed="$(printf '%s' "${output}" | jq '.' 2>/dev/null)" || true
  [ -n "${parsed}" ]
  # And specifically the E-HEALTH-001 code must be present.
  local code
  code="$(printf '%s' "${output}" | jq -r '.code')"
  [ "${code}" = "E-HEALTH-001" ]
}

# ===========================================================================
# AC-010 / BC-2.01.006 postcondition 2 (hook thin-wrapper requirement):
# brain-health-check.sh must delegate to skills/brain-health/run.sh.
# It must NOT re-implement the six-dimensional logic internally.
# Verified via grep: hook must reference the skill run.sh path.
# FAILS before implementation (current hook has its own STATE.md reading logic).
# ===========================================================================

@test "BC_2_01_006: brain-health-check.sh hook references skills/brain-health/run.sh" {
  local hook_path="${PLUGIN_DIR}/hooks/brain-health-check.sh"
  [ -f "${hook_path}" ]
  # The hook must call the skill — grep for the skill path reference
  run grep -c 'brain-health/run\.sh\|skills/brain-health' "${hook_path}"
  [ "$status" -eq 0 ]
  [ "$output" -gt 0 ]
}

@test "BC_2_01_006: brain-health-check.sh does not re-implement dimension logic (thin-wrapper enforced)" {
  local hook_path="${PLUGIN_DIR}/hooks/brain-health-check.sh"
  [ -f "${hook_path}" ]
  # AC-010 (reworded): hook reads CACHED overall_health from STATE.md frontmatter.
  # It must NOT duplicate the skill's dimension computation logic.
  # The skill's job: read manifest.json, ingest-tokens.jsonl, count wiki pages.
  # The hook's job: read only the cached STATE.md frontmatter overall_health field.
  #
  # Verify (1): hook references the skill (delegates full computation there)
  local skill_refs
  skill_refs="$(grep -c 'brain-health/run\.sh\|skills/brain-health' "${hook_path}" || true)"
  [ "${skill_refs}" -gt 0 ]
  # Verify (2): hook must NOT directly read manifest.json (skill's responsibility)
  local manifest_reads
  manifest_reads="$(grep -c 'manifest\.json' "${hook_path}" || true)"
  [ "${manifest_reads}" -eq 0 ]
  # Verify (3): hook must NOT directly read ingest-tokens.jsonl (skill's responsibility)
  local token_log_reads
  token_log_reads="$(grep -c 'ingest-tokens\.jsonl' "${hook_path}" || true)"
  [ "${token_log_reads}" -eq 0 ]
  # Verify (4): hook must NOT count wiki pages independently (skill's responsibility)
  # Wiki counting in run.sh uses find + wiki/ directory; hook should not do the same.
  local wiki_count_refs
  wiki_count_refs="$(grep -c 'wiki_count\|wiki/.*find\|find.*wiki/' "${hook_path}" || true)"
  [ "${wiki_count_refs}" -eq 0 ]
}

# ===========================================================================
# BC-2.01.006 v1.3 Postcondition 5: STATE.md writeback.
# After the skill runs successfully (exit 0), it must write the computed
# overall_health and dimension statuses back to STATE.md frontmatter using
# yq -i. The body (markdown content after the frontmatter) must be preserved.
# FAILS before implementation: current run.sh does not write STATE.md.
# ===========================================================================

@test "BC_2_01_006: after run overall_health is written to STATE.md frontmatter" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # After successful run, STATE.md frontmatter must have overall_health = GREEN
  local health_in_state
  health_in_state="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md" \
    | grep '^overall_health:' | sed 's/overall_health:[[:space:]]*//' | tr -d '[:space:]')"
  [ "${health_in_state}" = "GREEN" ]
}

@test "BC_2_01_006: after run last_health_check is written to STATE.md frontmatter" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # last_health_check must be set to an ISO8601 timestamp (non-empty)
  local last_check
  last_check="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md" \
    | grep '^last_health_check:' | sed 's/last_health_check:[[:space:]]*//' | tr -d '[:space:]"')"
  [ -n "${last_check}" ]
  [[ "${last_check}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "BC_2_01_006: after run dimension statuses written to STATE.md frontmatter" {
  # After a full green brain run, the skill must write back dimension values.
  # init sets wiki: YELLOW; after _add_wiki_pages the skill computes wiki: GREEN.
  # The writeback must overwrite wiki: YELLOW → wiki: GREEN in the frontmatter.
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  # Verify wiki starts as YELLOW in init template (pre-condition for the test)
  local wiki_before
  wiki_before="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md" \
    | awk '/^  wiki:/{print $2}')"
  [ "${wiki_before}" = "YELLOW" ]
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # After run, wiki dimension must be GREEN (writeback overrode the YELLOW from init)
  local wiki_after
  wiki_after="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md" \
    | awk '/^  wiki:/{print $2}')"
  [ "${wiki_after}" = "GREEN" ]
}

@test "BC_2_01_006: after run STATE.md body content is preserved" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # The STATE.md body (content after the frontmatter) must still be present.
  # The init skill writes '# Brain STATE' in the body — it must survive the writeback.
  local body
  body="$(awk '/^---$/{n++; next} n==1{next} n>=2{print}' "${BRAIN_DIR}/.brain/STATE.md")"
  [ -n "${body}" ]
  [[ "${body}" == *"#"* ]]
}

@test "BC_2_01_006: after YELLOW run overall_health YELLOW is written to STATE.md" {
  # Start with a GREEN overall_health in STATE.md (manually set after init).
  # Then run the skill with a YELLOW brain (no wiki pages/briefs).
  # The writeback must overwrite GREEN → YELLOW.
  _init_brain
  # Manually set overall_health to GREEN in STATE.md before running
  local state_file="${BRAIN_DIR}/.brain/STATE.md"
  local tmpfile
  tmpfile="$(mktemp)"
  awk '/^---$/{n++; print; next} n==1 && /^overall_health:/{print "overall_health: GREEN"; next} {print}' \
    "${state_file}" > "${tmpfile}"
  mv "${tmpfile}" "${state_file}"
  # Verify it is now GREEN before the run
  local before
  before="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${state_file}" \
    | grep '^overall_health:' | sed 's/overall_health:[[:space:]]*//' | tr -d '[:space:]')"
  [ "${before}" = "GREEN" ]
  # Run skill: no wiki pages, no briefs → overall should be YELLOW
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall_in_report
  overall_in_report="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall_in_report}" = "YELLOW" ]
  # Writeback must have changed GREEN → YELLOW in STATE.md
  local health_in_state
  health_in_state="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${state_file}" \
    | grep '^overall_health:' | sed 's/overall_health:[[:space:]]*//' | tr -d '[:space:]')"
  [ "${health_in_state}" = "YELLOW" ]
}

# ===========================================================================
# Structural quality gate:
# run.sh must pass shellcheck and shfmt when it exists.
# These tests FAIL before implementation (file not found).
# ===========================================================================

@test "BC_2_01_006: brain-health run.sh passes shellcheck" {
  [ -f "${RUN_SH}" ]
  run shellcheck "${RUN_SH}"
  [ "$status" -eq 0 ]
}

@test "BC_2_01_006: brain-health run.sh passes shfmt normalization check" {
  [ -f "${RUN_SH}" ]
  run shfmt -d -i 2 "${RUN_SH}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BC_2_01_006: brain-health run.sh starts with correct shebang" {
  [ -f "${RUN_SH}" ]
  run head -1 "${RUN_SH}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "BC_2_01_006: brain-health run.sh has set -euo pipefail within first 10 lines" {
  [ -f "${RUN_SH}" ]
  run bash -c "head -10 '${RUN_SH}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "BC_2_01_006: brain-health run.sh does not use eval" {
  [ -f "${RUN_SH}" ]
  run grep -n '\beval\b' "${RUN_SH}"
  # grep exits 1 when no match — which is what we want
  [ "$status" -ne 0 ]
}

@test "BC_2_01_006: brain-health run.sh has no hardcoded .claude/templates paths" {
  [ -f "${RUN_SH}" ]
  local count
  count="$(grep -c '\.claude/templates' "${RUN_SH}" || true)"
  [ "${count}" -eq 0 ]
}
