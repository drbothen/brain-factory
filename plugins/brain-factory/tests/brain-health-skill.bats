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
# Token avg > 150K (3x baseline) → sources RED.
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

@test "BC_2_01_006: token avg over 150K sources=RED" {
  _init_brain
  # Write 5 entries at 210,000 tokens each (4x+ the 50K baseline, above 3x RED threshold)
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

@test "BC_2_01_006: last_checked is within 5 seconds of invocation time (AC-008 delta)" {
  _init_brain

  # Capture lower bound before invocation.
  local before
  before="$(date -u +%s)"

  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]

  # Capture upper bound after invocation.
  local after
  after="$(date -u +%s)"

  local last_checked
  last_checked="$(printf '%s' "${output}" | jq -r '.last_checked')"
  [ -n "${last_checked}" ]
  [ "${last_checked}" != "null" ]

  # Parse to epoch — handle GNU date (Linux) and BSD date (macOS).
  local last_epoch
  if last_epoch="$(date -u -d "${last_checked}" +%s 2>/dev/null)"; then
    : # GNU date succeeded
  else
    # macOS BSD date: -j prevents updating the system clock, -f specifies format.
    last_epoch="$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "${last_checked}" +%s 2>/dev/null)" \
      || { echo "Cannot parse last_checked timestamp: ${last_checked}"; return 1; }
  fi

  # last_epoch must fall within the [before, after] window captured around the call.
  (( last_epoch >= before ))
  (( last_epoch <= after ))
  # Overall wall-clock span of the test must itself be ≤ 5 seconds (sanity guard).
  (( (after - before) <= 5 ))
}

# ===========================================================================
# AC-009 / BC-2.01.006 edge case EC-002 / VP-024:
# Non-brain directory (no .brain/STATE.md) → skill emits E-HEALTH-001 error envelope.
# Must exit exactly 2 — no exit 0/1 path on a non-brain dir (per Pass-11 contract lock).
# Structured JSON envelope always emitted on stdout. No unhandled bash error crash.
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
# BC-2.01.006 Postcondition 5: STATE.md writeback.
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

# ===========================================================================
# C01: red_dimensions written to STATE.md frontmatter after non-GREEN run.
# After a run with at least one RED or YELLOW dimension, STATE.md frontmatter
# must contain a non-empty red_dimensions array.
# The hook reads this field to build the issue summary banner.
# ===========================================================================

@test "BC_2_01_006: after YELLOW run red_dimensions written to STATE.md frontmatter" {
  # After init: wiki=YELLOW (no pages), synthesis=YELLOW, output=YELLOW.
  # The writeback must populate red_dimensions with these dimensions.
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # Overall must be YELLOW (no RED dims)
  local overall_in_report
  overall_in_report="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall_in_report}" = "YELLOW" ]
  # red_dimensions must be a non-empty YAML list in the frontmatter
  local fm
  fm="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md")"
  # red_dimensions section must exist and not be an empty list
  [[ "$fm" == *"red_dimensions:"* ]]
  # Must have at least one entry (YAML list item starts with '  - ')
  local entry_count
  entry_count="$(printf '%s' "$fm" | awk '/^red_dimensions:/{in_rd=1; next} in_rd && /^  - /{count++} in_rd && /^[^ ]/{in_rd=0} END{print count+0}')"
  [ "${entry_count}" -gt 0 ]
}

@test "BC_2_01_006: after GREEN run red_dimensions is empty list in STATE.md" {
  # After a full green brain run, red_dimensions must be an empty list.
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall_in_report
  overall_in_report="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall_in_report}" = "GREEN" ]
  # red_dimensions must exist but be empty (yq writes "red_dimensions: []")
  local fm
  fm="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md")"
  [[ "$fm" == *"red_dimensions:"* ]]
  # No list entries under red_dimensions
  local entry_count
  entry_count="$(printf '%s' "$fm" | awk '/^red_dimensions:/{in_rd=1; next} in_rd && /^  - /{count++} in_rd && /^[^ ]/{in_rd=0} END{print count+0}')"
  [ "${entry_count}" -eq 0 ]
}

@test "BC_2_01_006: after RED run red_dimensions contains RED dimension name in STATE.md" {
  # Force sources=RED by removing manifest.json.
  _init_brain
  rm -f "${BRAIN_DIR}/.brain/manifest.json"
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local overall_in_report
  overall_in_report="$(printf '%s' "${output}" | jq -r '.overall')"
  [ "${overall_in_report}" = "RED" ]
  # red_dimensions block must contain an entry keyed "sources".
  # Using an awk-based structural check (not a simple substring) so the test
  # does NOT pass tautologically against the init-template which already has
  # "sources: GREEN" in the dimensions map before the skill runs.
  local fm
  fm="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${BRAIN_DIR}/.brain/STATE.md")"
  [[ "$fm" == *"red_dimensions:"* ]]
  local sources_in_red
  sources_in_red="$(printf '%s' "$fm" | awk '
    /^red_dimensions:/{in_rd=1; next}
    in_rd && /^[a-z]/{in_rd=0}
    in_rd && /^  - sources:/{print "yes"; exit}
  ')"
  [ "$sources_in_red" = "yes" ]
}

# ===========================================================================
# C02: Body preservation with horizontal rules.
# STATE.md body content including markdown horizontal rules (---) must survive
# the writeback cycle without corruption or truncation.
# ===========================================================================

@test "BC_2_01_006: body with horizontal rule survives writeback cycle" {
  # Write STATE.md with a body that contains a legitimate markdown horizontal rule.
  _init_brain
  local state_file="${BRAIN_DIR}/.brain/STATE.md"
  # Read existing frontmatter and rebuild with a body containing a horizontal rule.
  local fm
  fm="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "${state_file}")"
  {
    printf '%s\n' '---'
    printf '%s\n' "${fm}"
    printf '%s\n' '---'
    printf '%s\n' '# Brain State'
    printf '%s\n' 'Section A content.'
    printf '%s\n' '---'
    printf '%s\n' '## Subsection'
    printf '%s\n' '_footer text_'
  } >"${state_file}"
  # Run the skill
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  # The horizontal rule in the body must survive
  local body
  body="$(awk 'BEGIN{n=0; in_body=0} /^---$/ && n<2 {n++; if (n==2) in_body=1; next} in_body{print}' "${state_file}")"
  [[ "$body" == *"---"* ]]
  # Footer text must also survive
  [[ "$body" == *"_footer text_"* ]]
  # Section content must survive
  [[ "$body" == *"Section A content."* ]]
}

# ===========================================================================
# I04: writeback_status field in JSON report.
# The JSON output must include a "writeback_status" field.
# ===========================================================================

@test "BC_2_01_006: JSON report includes writeback_status field" {
  _init_brain
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local ws
  ws="$(printf '%s' "${output}" | jq -r '.writeback_status')"
  [ -n "${ws}" ]
  [ "${ws}" != "null" ]
  # Must be one of the three valid writeback_status enum values (BC-2.01.006 Postcondition 5)
  [[ "${ws}" == "ok" || "${ws}" == "failed" || "${ws}" == "skipped_malformed_frontmatter" ]]
}

@test "BC_2_01_006: JSON report writeback_status is ok on successful healthy brain" {
  _init_brain
  _add_wiki_pages 1
  _add_weekly_brief
  _add_content_brief
  run bash "${RUN_SH}"
  [ "$status" -eq 0 ]
  local ws
  ws="$(printf '%s' "${output}" | jq -r '.writeback_status')"
  [ "${ws}" = "ok" ]
}

# ===========================================================================
# F-P3-I02: Malformed-frontmatter writeback safeguard (commit dd48972).
# _writeback_state must abort and set writeback_status="skipped_malformed_frontmatter"
# when STATE.md has fewer than two '---' delimiter lines, and must NOT modify the
# file. Tests lock the safeguard against regression.
# BC-2.01.006 Postcondition 5 — writeback precondition check.
# ===========================================================================

@test "BC_2_01_006: zero-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged" {
  # Arrange: init brain to create directory structure, then overwrite STATE.md
  # with a body-only file containing NO '---' frontmatter markers at all.
  _init_brain
  local state_file="${BRAIN_DIR}/.brain/STATE.md"
  # Write a body-only STATE.md (no frontmatter whatsoever — zero '---' lines).
  printf '%s\n' \
    '# Brain State' \
    '' \
    'This file has no frontmatter delimiters at all.' \
    '' \
    'Some additional body content here.' \
    >"${state_file}"

  # Capture byte-exact content before running the skill.
  local before_content
  before_content="$(cat -- "${state_file}")"

  # Act: run the skill.
  run bash "${RUN_SH}"

  # Assert: skill exits 0 (advisory-only — writeback failure does NOT abort the report).
  [ "$status" -eq 0 ]

  # Assert: writeback_status is "skipped_malformed_frontmatter".
  local ws
  ws="$(printf '%s' "${output}" | jq -r '.writeback_status')"
  [ "${ws}" = "skipped_malformed_frontmatter" ]

  # Assert: writeback_error field is PRESENT and non-empty (diagnostic surfaced).
  local we
  we="$(printf '%s' "${output}" | jq -r '.writeback_error // empty')"
  [ -n "${we}" ]

  # Assert: STATE.md is byte-identical to the fixture (file was NOT touched).
  local after_content
  after_content="$(cat -- "${state_file}")"
  [ "${after_content}" = "${before_content}" ]
}

@test "BC_2_01_006: one-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged" {
  # Arrange: init brain to create directory structure, then overwrite STATE.md
  # with a single '---' opening marker but no closing '---'.
  _init_brain
  local state_file="${BRAIN_DIR}/.brain/STATE.md"
  # Write a STATE.md with exactly one '---' line (unclosed frontmatter).
  printf '%s\n' \
    '---' \
    'overall_health: GREEN' \
    'last_health_check: "2026-01-01T00:00:00Z"' \
    '' \
    '# Brain State' \
    '' \
    'Body content following the unclosed frontmatter opener.' \
    >"${state_file}"

  # Verify the fixture really has exactly one '---' line (precondition sanity).
  local marker_count
  marker_count="$(grep -c '^---$' -- "${state_file}")"
  [ "${marker_count}" -eq 1 ]

  # Capture byte-exact content before running the skill.
  local before_content
  before_content="$(cat -- "${state_file}")"

  # Act: run the skill.
  run bash "${RUN_SH}"

  # Assert: skill exits 0 (writeback failure is advisory — JSON report still emits).
  [ "$status" -eq 0 ]

  # Assert: writeback_status is "skipped_malformed_frontmatter".
  local ws
  ws="$(printf '%s' "${output}" | jq -r '.writeback_status')"
  [ "${ws}" = "skipped_malformed_frontmatter" ]

  # Assert: writeback_error field is PRESENT and non-empty.
  local we
  we="$(printf '%s' "${output}" | jq -r '.writeback_error // empty')"
  [ -n "${we}" ]

  # Assert: STATE.md is byte-identical to the fixture (file was NOT touched).
  local after_content
  after_content="$(cat -- "${state_file}")"
  [ "${after_content}" = "${before_content}" ]
}

# ===========================================================================
# F-P6-C01: yq-failure path coverage (commit 7784cfb renamed sentinel "failed").
# _writeback_state must set writeback_status="failed" when the frontmatter
# extracted from a well-fenced STATE.md (two valid '---' markers) contains
# YAML that yq rejects at parse time. This locks the "failed" enum value
# against paper-fix regression (TD-VSDD-059) and verifies:
#   - The marker-count safeguard does NOT fire (markers are valid)
#   - The yq parse error causes _writeback_failure_reason="failed" (set before
#     the yq block in _writeback_state) to propagate through the trap EXIT path
#   - writeback_status in the JSON output is exactly "failed"
#   - writeback_error is present and non-empty (yq stderr captured)
#   - STATE.md content is byte-identical to the fixture (not touched)
# BC-2.01.006 Postcondition 5 — writeback_status enum {ok, failed,
# skipped_malformed_frontmatter}. LOCKED DECISION #6.
# ===========================================================================

@test "BC_2_01_006: malformed YAML in well-fenced frontmatter triggers writeback_status=failed and leaves file unchanged" {
  # Arrange: init brain to create directory structure, then overwrite STATE.md
  # with a file that has exactly two valid '---' fence lines (passes the
  # marker-count safeguard) but contains an unterminated flow sequence in the
  # frontmatter YAML (fails yq parse, exercising the "failed" branch).
  #
  # Fixture: dimensions.capture value is an unterminated YAML flow sequence:
  #   capture: [unterminated_flow_sequence
  # yq rejects this with "yaml: line N: did not find expected ',' or ']'"
  # Verified locally: `yq e -i '.x = "y"' <file-with-unterminated-bracket>` exits 1.
  _init_brain
  local state_file="${BRAIN_DIR}/.brain/STATE.md"
  printf '%s\n' \
    '---' \
    'overall_health: GREEN' \
    'last_health_check: ""' \
    'dimensions:' \
    '  capture: [unterminated_flow_sequence' \
    '  sources: YELLOW' \
    '  wiki: YELLOW' \
    '  synthesis: YELLOW' \
    '  output: YELLOW' \
    '  reflection: YELLOW' \
    'red_dimensions: []' \
    '---' \
    '# Brain State' \
    '' \
    'Fixture body — must be preserved byte-identical after skill run.' \
    >"${state_file}"

  # Precondition sanity: fixture must have exactly two '---' markers so the
  # marker-count safeguard is NOT the path that fires (we want yq-failure path).
  local marker_count
  marker_count="$(grep -c '^---$' -- "${state_file}")"
  [ "${marker_count}" -eq 2 ]

  # Capture byte-exact content before running the skill.
  local before_content
  before_content="$(cat -- "${state_file}")"

  # Act: run the skill.
  run bash "${RUN_SH}"

  # Assert: skill exits 0 (writeback failure is advisory — JSON report still emits).
  [ "$status" -eq 0 ]

  # Assert: writeback_status is "failed" (yq-failure path, NOT "skipped_malformed_frontmatter").
  local ws
  ws="$(printf '%s' "${output}" | jq -r '.writeback_status')"
  [ "${ws}" = "failed" ]

  # Assert: writeback_error field is PRESENT and non-empty (yq diagnostic captured via stderr).
  local we
  we="$(printf '%s' "${output}" | jq -r '.writeback_error // empty')"
  [ -n "${we}" ]

  # Assert: STATE.md is byte-identical to the fixture (file was NOT touched by writeback).
  local after_content
  after_content="$(cat -- "${state_file}")"
  [ "${after_content}" = "${before_content}" ]
}
