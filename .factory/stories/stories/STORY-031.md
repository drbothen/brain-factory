---
artifact_type: story
story_id: STORY-031
epic_id: EPIC-06
title: "/brain:monthly-perf — performance analytics from LinkedIn Posts API and token logs"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-09]
behavioral_contracts: [BC-2.09.006]
vps: []
dependencies: [STORY-030]
blocks: []
inputs:
  - architecture/subsystems/SS-09-publishing-pipeline.md
  - behavioral-contracts/ss-09/BC-2.09.006.md
input-hash: ""
# BC status: BC-2.09.006 assigned; status=draft per Spec-First Gate S-7.01
# Priority: P1 — performance analytics; requires published content (linkedin_post_id
# frontmatter fields) from STORY-030 to pull per-post engagement data.
# Dependency rationale: STORY-030 (/brain:publish-content) writes `linkedin_post_id`
# to published file frontmatter; monthly-perf reads these IDs to pull engagement data.
---

# STORY-031: `/brain:monthly-perf` — performance analytics from LinkedIn Posts API and token logs

## Goal

Deliver the `/brain:monthly-perf` skill that aggregates token cost data from
`.brain/logs/ingest-tokens.jsonl` and pulls per-post engagement metrics (impressions,
engagement rate) from the LinkedIn Posts API for all published content. The skill writes
a structured JSONL report to `.brain/logs/monthly-perf-{YYYY-MM}.jsonl` and surfaces a
summary to the operator. After this story the operator has a complete content-performance
feedback loop.

## User Value

As a brain-factory operator, I want to run `/brain:monthly-perf` so that I see my
monthly token spend, per-post engagement metrics from LinkedIn, and a burn-rate
projection — giving me the data to decide where to invest my content effort next month.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.09.006 | `/brain:monthly-perf` pulls performance data from LinkedIn Posts API and reports to `.brain/logs/` | P1 |

## Acceptance Criteria

### Performance report generation (BC-2.09.006)

**AC-001** — When invoked, `/brain:monthly-perf` writes
`.brain/logs/monthly-perf-{YYYY-MM}.jsonl` containing: token cost summary, per-post
engagement data (impressions, engagement rate), 30-day trailing average, p95 cost
outlier, and burn-rate projection.
(traces to BC-2.09.006 postcondition 1)

**AC-002** — The skill exits 0 and prints a human-readable summary to the operator.
(traces to BC-2.09.006 postcondition 2)

**AC-003** — When the 30-day trailing average token cost exceeds 2x the 50K-token
baseline, the skill surfaces the same token-budget alert as `/brain:health`. This alert
appears in the printed summary and in the JSONL report.
(traces to BC-2.09.006 postcondition 3)

**AC-004** — When no published posts exist (no `linkedin_post_id` frontmatter in
`published/linkedin/`), the LinkedIn API call is skipped. The skill still generates a
token cost report from `.brain/logs/ingest-tokens.jsonl` and exits 0.
(traces to BC-2.09.006 edge case EC-001)

**AC-005** — When the LinkedIn API returns 429, the skill retries with exponential
backoff via `scripts/lib/api-retry.sh` (up to 3 attempts). After 3 failures, the skill
emits advisory E-PERF-001 and reports partial data (token costs without LinkedIn
engagement metrics).
(traces to BC-2.09.006 invariant 1; edge case EC-002)

**AC-006** — The `perf.pulled` structured event is emitted on stderr after a successful
LinkedIn API pull. The event_type is registered in `scripts/event-catalog.json`.
(traces to BC-2.09.006; BC-2.04.017 structured event catalog; BC-2.17.001)

**AC-007** — The `monthly-perf.md` SKILL.md passes all meta-lint assertions: frontmatter
has `name: monthly-perf`, `description`, `argument-hint`, and `allowed-tools` as a
non-empty YAML list; body has the 6 canonical sections in order; Iron Law body ≤ 200
chars; Red Flags has ≥ 1 bullet; Procedure has ≥ 1 numbered item; no
`.claude/templates/` hardcoding.
(traces to BC-2.09.006; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/monthly-perf/SKILL.md` with complete
   frontmatter (`name: monthly-perf`, `description: "Pull LinkedIn performance data and
   aggregate token cost into a monthly report"`, `argument-hint: ""`,
   `allowed-tools: [Read, Write, Bash]`) and 6-section body skeleton. Iron Law:
   "Partial data is better than no data — always emit the token cost report even if
   LinkedIn API fails." Procedure steps are empty stubs.

2. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/skills.bats`:
   - `"brain:monthly-perf: report written with token cost and engagement data (BC-2.09.006)"` —
     sets up temp brain with 5 published files (fixture, each with `linkedin_post_id`),
     30 days of ingest tokens JSONL; starts LinkedIn DTU mock returning sample engagement
     data; invokes monthly-perf; asserts `.brain/logs/monthly-perf-YYYY-MM.jsonl` exists;
     `jq` can parse it; contains `token_cost_summary`, `per_post_engagement`,
     `trailing_average`, `p95_outlier`, `burn_rate_projection` keys; exit 0.
   - `"brain:monthly-perf: no published posts → token-only report, no API call"` —
     empty `published/linkedin/`; DTU mock not started; asserts report generated;
     exit 0.
   - `"brain:monthly-perf: trailing average > 2x baseline → alert in report"` —
     ingest tokens JSONL seeded with high values; asserts report contains `alert` field;
     summary output contains budget-alert text.
   - `"brain:monthly-perf: 429 → retry, then E-PERF-001 advisory"` — DTU mock returns
     429 for all 3 attempts; asserts partial report written (token costs present, no
     engagement data); exit 0 (advisory, not hard failure).
   - `"monthly-perf SKILL.md: meta-lint compliance"`.
   Run bats — confirm all 5 tests fail (Red Gate confirmed).

3. **[impl]** Implement `monthly-perf` skill Procedure in SKILL.md:
   - Step 1: Determine current month `YYYY-MM` via `date +%Y-%m`.
   - Step 2: Read `.brain/logs/ingest-tokens.jsonl`; compute: total tokens, 30-day
     trailing average, p95 outlier, burn-rate projection (extrapolated to full year).
   - Step 3: Check trailing average vs 2x baseline (50K tokens). If exceeded, set
     `alert: true` in report.
   - Step 4: Collect `linkedin_post_id` fields from all files in
     `published/linkedin/*.md` (via `yq eval '.linkedin_post_id'`). If none → skip
     LinkedIn API.
   - Step 5: For each post ID, call LinkedIn Posts API to retrieve engagement metrics
     (impressions, reactions, comments, shares). Use `scripts/lib/api-retry.sh` for
     rate-limit handling. On E-PERF-001 (3 retries exhausted) → mark engagement data
     as unavailable and continue.
   - Step 6: Write `.brain/logs/monthly-perf-{YYYY-MM}.jsonl` with all aggregated
     data as a single JSON record.
   - Step 7: Emit `perf.pulled` JSONL event on stderr.
   - Step 8: Print human-readable summary to operator; if alert → surface the
     token-budget warning. Exit 0.

4. **[green]** Run `bats tests/skills.bats -f "brain:monthly-perf\|monthly-perf SKILL"` —
   all 5 tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| 5 published posts; 30 days of ingest history | monthly-perf log written with all required fields; summary printed; exit 0 | happy-path | BC-2.09.006 canonical test vector 1 |
| No published posts | Token cost report only; no API call; exit 0 | edge-case | BC-2.09.006 EC-001 |
| 30-day average > 100K tokens (2x baseline) | `alert: true` in report; alert text in summary | alert | BC-2.09.006 postcondition 3 |
| LinkedIn API returns 429 three times | E-PERF-001 advisory; partial report; exit 0 | rate-limit | BC-2.09.006 EC-002 + invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no VP — P1) | monthly-perf log written on invocation | `tests/skills.bats` (DTU mock) |
| (no VP — P1) | Token budget alert surfaced when > 2x baseline | `tests/skills.bats` |
| (no VP — P1) | No published posts → token-only report, no API call | `tests/skills.bats` |
| (no VP — P1) | 429 → retry + E-PERF-001 advisory | `tests/skills.bats` (DTU mock) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-09-publishing-pipeline.md`:

1. Token cost data is read from `.brain/logs/ingest-tokens.jsonl` (written by
   BC-2.02.003 / EPIC-03). Never re-derive token costs from the source files.

2. Per-post engagement data requires `linkedin_post_id` in the published file's
   frontmatter. This field is written by STORY-030 (`/brain:publish-content`). If
   `linkedin_post_id` is null or absent, skip the API call for that post.

3. Report format is JSONL (one JSON record per invocation) at
   `.brain/logs/monthly-perf-{YYYY-MM}.jsonl`. Running the skill twice in the same
   month appends a second record (does not overwrite). Tests must account for
   multi-record JSONL files.

4. `scripts/lib/api-retry.sh` handles rate-limit backoff — this dependency was
   introduced in STORY-030. Confirm it is in place before wiring Step 5.

5. The `perf.pulled` event must be registered in `scripts/event-catalog.json`. If
   the event catalog update is missed here, it is a P1 adversarial finding. Add the
   row before the PR merges.

6. Medium performance pulls are only available via the Medium reference extension
   (BC-2.09.006 invariant 2). Do not wire any Medium-specific logic in v0.1.

**Forbidden dependencies:**
- `monthly-perf` skill: must NOT write to `wiki/` or `briefs/`.
- `monthly-perf` skill: must NOT call the LinkedIn Posts API publish endpoint —
  it calls the analytics/engagement endpoints only (read-only).
- `monthly-perf` skill: must NOT read `sources/` directly.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `node` | 20+ | LinkedIn engagement API call (may reuse `scripts/linkedin-post.mjs` pattern) |
| `jq` | 1.6+ | JSONL report generation and parsing in bats assertions |
| `yq` | 4.x+ | Extract `linkedin_post_id` from published file frontmatter |
| `date` | GNU/BSD | Current month `YYYY-MM` for report filename |
| `scripts/lib/api-retry.sh` | (this repo, from STORY-030) | Rate-limit backoff |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/monthly-perf/SKILL.md` | Create | Performance analytics skill |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 5 failing-then-passing monthly-perf tests |
| `plugins/brain-factory/scripts/event-catalog.json` | Modify | Register `perf.pulled` event type |

Files NOT to modify: any file under `.factory/`, any hook script, `plugin.json`,
any prior story file.

## Previous Story Intelligence

STORY-030 (`/brain:publish-content`) writes `linkedin_post_id: urn:li:share:XXXXXXX`
to the published file frontmatter. The monthly-perf skill reads this field from every
file in `published/linkedin/`. Confirm the exact frontmatter key name (`linkedin_post_id`)
and value format (`urn:li:share:XXXXXXX`) from STORY-030 before wiring Step 4 of the
Procedure — a key-name mismatch would silently skip all API calls.

The token cost JSONL format from BC-2.02.003 (EPIC-03, STORY-015/016 range) should be
confirmed: each record is expected to contain `ts`, `skill`, `prompt_tokens`,
`completion_tokens`, `total_tokens`. The trailing-average computation (Step 2) sums
`total_tokens` across records within the rolling 30-day window.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,800 |
| SS-09 subsystem design | ~900 |
| BC-2.09.006 file | ~700 |
| STORY-030 spec (linkedin_post_id format reference) | ~4,000 |
| Existing `skills.bats` (for test context) | ~2,000 |
| `scripts/event-catalog.json` (for event registration) | ~1,000 |
| **Total** | **~11,400** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Token instrumentation (writing `ingest-tokens.jsonl`) — EPIC-03 (STORY-015/016).
- Token budget alert in `/brain:health` — EPIC-08 (BC-2.16.002).
- Medium performance data — medium reference extension (future).
- The GH Action that triggers monthly-perf automatically — EPIC-07.

## Anchors

- BC-2.09.006: `behavioral-contracts/ss-09/BC-2.09.006.md`
- SS-09: `architecture/subsystems/SS-09-publishing-pipeline.md`
- STORY-030: `stories/stories/STORY-030.md` (publish skill — writes linkedin_post_id)
- BC-2.02.003: `behavioral-contracts/ss-02/BC-2.02.003.md` (ingest-tokens JSONL format)
