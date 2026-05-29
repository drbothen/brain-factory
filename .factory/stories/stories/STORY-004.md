---
artifact_type: story
story_id: STORY-004
epic_id: EPIC-01
title: "/brain:health six-dimensional convergence skill"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-01]
behavioral_contracts: [BC-2.01.006]
vps: [VP-024]
dependencies: [STORY-001, STORY-002, STORY-003]
blocks: [STORY-005]
inputs:
  - architecture/subsystems/SS-01-brain-init-scaffold.md
  - behavioral-contracts/ss-01/BC-2.01.006.md
  - architecture/verification-properties/VP-024-plugin-lifecycle.md
input-hash: ""
# BC status: BC-2.01.006 assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-004: /brain:health six-dimensional convergence skill

## Goal

Implement the `/brain:health` skill that reads `.brain/STATE.md` and the brain's
directory structure and emits a structured JSON health report covering six convergence
dimensions (Capture, Sources, Wiki, Synthesis, Output, Reflection) each with a
GREEN/YELLOW/RED status. The skill also surfaces token budget alerts when the 30-day
trailing average exceeds 2x the 50K-token baseline.

## User Value

As an operator, I want to run `/brain:health` and immediately see a structured JSON
report telling me the state of my brain across six dimensions, so I can know at a
glance whether my brain is healthy, degrading, or needs attention — without reading
through log files manually.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.01.006 | `/brain:health` reports six-dimensional convergence state in structured JSON | P1 |

## Acceptance Criteria

**AC-001** — On a healthy brain with recent ingests and no anomalies, the skill exits 0
and emits:
```json
{
  "dimensions": {
    "capture": {"status": "GREEN", "detail": "..."},
    "sources": {"status": "GREEN", "detail": "..."},
    "wiki": {"status": "GREEN", "detail": "..."},
    "synthesis": {"status": "GREEN", "detail": "..."},
    "output": {"status": "GREEN", "detail": "..."},
    "reflection": {"status": "GREEN", "detail": "..."}
  },
  "overall": "GREEN",
  "last_checked": "<ISO8601>"
}
```
(traces to BC-2.01.006 postconditions 1–2)

**AC-002** — The `overall` field is `RED` if any dimension is `RED`; `YELLOW` if any
dimension is `YELLOW` and none are `RED`; `GREEN` only if all six dimensions are
`GREEN`. No other aggregate logic applies.
(traces to BC-2.01.006 postcondition 3; invariant 1)

**AC-003** — Status values are exactly `"GREEN"`, `"YELLOW"`, or `"RED"` (uppercase
strings). No other values (e.g., `"green"`, `"Ok"`, `null`) are accepted.
(traces to BC-2.01.006 invariant 2)

**AC-004** — When `.brain/logs/ingest-tokens.jsonl` does not exist (brand-new brain),
the `sources` dimension reports `GREEN` with `detail` = `"No ingest history yet."`.
The token budget check is skipped — no error and no YELLOW from a missing log file.
(traces to BC-2.01.006 edge case EC-001)

**AC-005** — When the 30-day trailing average token cost from `.brain/logs/ingest-tokens.jsonl`
exceeds `100000` (2x the 50K baseline), the `sources` dimension reports at minimum
`YELLOW` with a detail string containing "token budget" and the actual average.
If it exceeds `200000` (4x), status is `RED`.
(traces to BC-2.01.006 postcondition 4)

**AC-006** — When `.brain/STATE.md` is missing or unreadable, the skill exits 2 and
emits:
`{"level":"error","code":"E-HEALTH-001","message":"Brain state file missing — run \`/brain:init\` or \`/brain:cold-start-recover\`.","trace":"<uuid>"}`.
(traces to BC-2.01.006 edge case EC-002)

**AC-007** — When the brain has 0 wiki pages (no markdown files under `wiki/`
other than `index.md` and `log.md`), the `wiki` dimension reports `YELLOW` with
`detail` = `"No wiki pages yet — ingest your first source."`.
(traces to BC-2.01.006 edge case EC-003)

**AC-008** — The `last_checked` field in the JSON output is a valid ISO8601 UTC
timestamp matching the current invocation time (within 5 seconds).
(traces to BC-2.01.006 postcondition 2)

**AC-009** — When invoked from a non-brain directory (no `.brain/STATE.md`), the skill
emits a structured E-HEALTH-001 error envelope to stdout
(`{"level":"error","code":"E-HEALTH-001","message":"Brain state file missing — run \`/brain:init\` or \`/brain:cold-start-recover\`.","trace":"<uuid>"}`)
and exits 2. The skill never crashes with an unhandled bash error (no bare `set -e`
unexpected exit on missing file reads). The exit-code contract is binary: 0 (success)
or 2 (unrecoverable error); no exit 1 path exists in this skill.
(traces to BC-2.01.006 edge case EC-002; VP-024 health-callable test; brain-health-skill.bats lines 423-432)

**AC-010** — `brain-health-check.sh` hook (registered in `hooks.json` under
`SessionStart`) displays a human-readable health summary on session start. The hook
reads `overall_health` from `.brain/STATE.md` frontmatter (written by the last
`/brain:health` invocation) — it does NOT re-implement the six-dimensional logic and
does NOT execute `skills/brain-health/run.sh` inline on every SessionStart. The
`/brain:health` skill is responsible for updating `overall_health`, `last_health_check`,
`dimensions`, and `red_dimensions` in STATE.md frontmatter after each run (see postcondition 5).
(traces to BC-2.01.006 postconditions 1–2; BC-2.04.014 description; hooks.json SessionStart registration)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/brain-health/run.sh` stub: reads
   `.brain/STATE.md`, returns a hardcoded `{"overall":"GREEN",...}` — stub skeleton only.
   Note: canonical directory is `skills/brain-health/` (not `skills/health/`). See BC-DIMENSION-RECONCILIATION.md §3.

2. **[failing test — Red Gate]** Write `plugins/brain-factory/tests/brain-health-skill.bats`
   (standalone bats file for the brain-health skill — does NOT extend `tests/integration.bats`;
   hook tests for `brain-health-check.sh` are separate in `brain-health-check.bats`).
   Tests follow the `BC_2_01_006: <description>` naming convention. Representative
   test categories that must all fail before implementation (Red Gate):
   - Happy-path: healthy brain with full STATE.md, recent ingests — overall GREEN, exit 0
   - Aggregation: one dimension forced RED → overall RED; all GREEN one YELLOW → overall YELLOW
   - Error path: missing STATE.md → E-HEALTH-001 JSON envelope on stdout, exit 2
   - Brand-new brain edge case: no wiki pages → wiki YELLOW; no ingest log → sources GREEN
   - Token budget alert: 30-day trailing average > 2× baseline (> 100000) → sources YELLOW
   - Status enum constraint: all six dimension status values match `^(GREEN|YELLOW|RED)$`
   - VP-024 callable: invoked from non-brain dir → exits 2, no unhandled bash crash, stdout is valid JSON

3. **[impl]** Implement dimension logic in `skills/brain-health/run.sh`:

   *Capture dimension:* GREEN if `inbox/` directory exists and is readable; YELLOW if
   more than 50 unprocessed items in `inbox/` (suggest process-inbox); RED if `inbox/`
   missing.

   *Sources dimension:* (precedence order — first matching condition wins)
   1. RED if `manifest.json` missing or invalid JSON.
   2. GREEN with detail "No ingest history yet." if `ingest-tokens.jsonl` is missing — brand-new brain, no history yet (BC-2.01.006 EC-001 / AC-004). Source count is NOT checked in this state.
   3. If `ingest-tokens.jsonl` exists: compute 30-day trailing average from each line `{"date":"...","tokens":NNN}` using awk. RED if avg > 200000 (4x baseline). YELLOW with "token budget" in detail if avg > 100000 (2x baseline). YELLOW "No sources ingested yet" if source_count == 0. GREEN with source count otherwise.

   *Wiki dimension:* GREEN if wiki page count > 0 (non-index/log .md files under `wiki/`);
   YELLOW if count = 0.

   *Synthesis dimension:* GREEN if at least 1 file in `briefs/weekly/`; YELLOW if none.

   *Output dimension:* GREEN if at least 1 file in `briefs/content/`; YELLOW if none.

   *Reflection dimension:* GREEN if `.brain/STATE.md` exists and is non-empty; YELLOW if
   STATE.md is empty; RED if missing (also triggers E-HEALTH-001 if STATE.md is
   missing before we even get to dimensions).

4. **[impl]** Implement `overall` aggregation logic: scan all six dimension statuses;
   if any is `RED` → `RED`; else if any is `YELLOW` → `YELLOW`; else `GREEN`.

5. **[impl]** Implement token budget alert: use `awk` to parse `.brain/logs/ingest-tokens.jsonl`
   and compute the 30-day trailing average. If the file does not exist, skip. If it exists
   but is empty, skip. Emit YELLOW detail string with actual average when > 100000.

6. **[impl]** Implement STATE.md frontmatter write-back in `skills/brain-health/run.sh`:
   after computing the health report, use `yq` to update `overall_health`, `last_health_check`,
   `dimensions`, and `red_dimensions` in `.brain/STATE.md` YAML frontmatter so the SessionStart
   hook reads the cached result. If STATE.md frontmatter is malformed (fewer than 2 `---` markers),
   skip the write and set `writeback_status: "skipped_malformed_frontmatter"` in the JSON report.
   If `yq` fails inside well-fenced frontmatter, set `writeback_status: "failed"` and surface the
   error in the `writeback_error` field of the JSON report. The original STATE.md must be preserved
   byte-identical on any writeback failure. This satisfies BC-2.01.006 postcondition 5.

7. **[green]** Run all health bats tests. All pass.

8. **[green]** Run `shellcheck plugins/brain-factory/skills/brain-health/run.sh` and
   `shellcheck plugins/brain-factory/hooks/brain-health-check.sh`.

9. **[green]** Run `shfmt -d -i 2` on both files.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Healthy brain with ingests | `{"overall":"GREEN",...all GREEN...}`; exit 0 | happy-path | BC-2.01.006 |
| Brand-new brain (just init'd) | `sources:GREEN, wiki:YELLOW, overall:YELLOW`; exit 0 | edge-case | BC-2.01.006 EC-003 |
| Brain with missing STATE.md | E-HEALTH-001 JSON; exit 2 | error | BC-2.01.006 EC-002 |
| Token cost 105,000 avg (> 2× baseline) | `sources:YELLOW` with "token budget" in detail | edge-case | BC-2.01.006 postcondition 4 |
| No `ingest-tokens.jsonl` | `sources:GREEN` with "No ingest history yet." | edge-case | BC-2.01.006 EC-001 |
| One dimension forced RED | `overall:RED` | unit-test | BC-2.01.006 postcondition 3 |
| All GREEN, one YELLOW | `overall:YELLOW` | unit-test | BC-2.01.006 postcondition 3 |
| All GREEN | `overall:GREEN` | unit-test | BC-2.01.006 postcondition 3 |
| Non-brain dir | E-HEALTH-001 JSON envelope on stdout, exit 2; no unhandled bash crash | VP-024 | VP-024 health-callable |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-024 | `/brain:health` callable without crash after install | `tests/brain-health-skill.bats` |
| VP-024 | Health returns structured JSON (not raw stack traces) | `tests/brain-health-skill.bats` jq assertion |

## Architecture Compliance Rules

From `architecture/subsystems/SS-01-brain-init-scaffold.md`:

1. **The six dimension names are canonical and fixed:** `capture`, `sources`, `wiki`,
   `synthesis`, `output`, `reflection` (all lowercase in the JSON key). Adding a seventh
   dimension requires a BC update.
2. **Status values are exactly three uppercase strings:** `"GREEN"`, `"YELLOW"`, `"RED"`.
   No other values allowed. The bats test checks via `[[ "$status" =~ ^(GREEN|YELLOW|RED)$ ]]`.
3. **`brain-health-check.sh` reads cached STATE.md, not skill output inline** — the hook reads `overall_health` from `.brain/STATE.md` YAML frontmatter. The `/brain:health` skill is responsible for writing `overall_health`, `last_health_check`, `dimensions`, and `red_dimensions` back to STATE.md frontmatter after each run (BC-2.01.006 postcondition 5). On writeback failure, `writeback_status` is set to `"skipped_malformed_frontmatter"` (malformed frontmatter guard) or `"failed"` (yq failure), the `writeback_error` field is populated in the JSON report, and the original STATE.md is preserved byte-identical. The hook does NOT call `skills/brain-health/run.sh` inline on every SessionStart. The canonical skill path is `skills/brain-health/run.sh` (not `skills/health/run.sh`).
4. **Token budget baseline is 50,000 tokens.** The 2× alert threshold is 100,000.
   4× threshold (200,000) triggers RED. These values are constants in `run.sh`, not
   configuration — changing them requires a BC update.
5. **`awk`-based JSONL parsing** for `.brain/logs/ingest-tokens.jsonl`. Do not use
   `jq` for the trailing-average computation (jq slurp on a large JSONL file is slower
   than awk). Use `awk -F'"tokens":' '{...}'` to extract the `tokens` field.

**Forbidden patterns:**
- `jq` slurp on `ingest-tokens.jsonl` for the 30-day average (performance issue at scale)
- Hardcoding the baseline (50000) in multiple places — define once as a `readonly` variable
- Any dimension emitting a status other than GREEN/YELLOW/RED
- Crashing with an unhandled bash error on missing files (use `[[ -f ... ]] || ...` guards)

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | phased-build-plan.md §1 |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `jq` | 1.7+ (latest: 1.8.1) | JSON output validation in bats |
| `awk` | POSIX | Token budget computation in run.sh |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

Files to create/modify:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/brain-health/run.sh` | Create | Six-dimensional JSON output; `#!/usr/bin/env bash`; `set -euo pipefail` |
| `plugins/brain-factory/skills/brain-health/SKILL.md` | Replace stub | Full SKILL.md with all 6 sections |
| `plugins/brain-factory/hooks/brain-health-check.sh` | Modify | Reads `overall_health` from STATE.md frontmatter; does NOT call run.sh inline |
| `plugins/brain-factory/tests/brain-health-skill.bats` | Create | Red Gate bats tests for brain-health/run.sh (supersedes integration.bats additions) |
| `plugins/brain-factory/templates/state-md-template.md` | Modify | Add frontmatter with `overall_health` and canonical `dimensions` map |

Files NOT to modify: `tests/upgrade.bats`, `tests/skills.bats`, `skills/init/run.sh`,
`.factory/` tree, `docs/planning/`.

## Previous Story Intelligence

STORY-003 completed the init skill with full error handling. Two lessons carry forward:

1. The `_die` helper pattern (emit JSON to stdout, exit 2) applies here too. Define a
   local `_health_error` helper in `health/run.sh` for E-HEALTH-001.
2. The `local-dev-test.sh` from STORY-003 performs a full init on a temp brain. The health
   skill tests should reuse that temp brain setup pattern rather than re-inventing it —
   extract a `setup_temp_brain()` helper into `tests/helpers.bash` that both test files
   source.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-01 subsystem design (partial re-read) | ~800 |
| BC-2.01.006 | ~1,200 |
| VP-024 (health-callable test) | ~1,500 |
| brain-health-skill.bats (new file, test categories + helpers) | ~2,000 |
| Test output context | ~500 |
| **Total** | **~9,000** |

Within 20% of 200K-token context. No split required.

## Out of Scope

- `brain-health-check.sh` SessionStart hook behavior beyond reading cached STATE.md — EPIC-02
- Token instrumentation (writing to `ingest-tokens.jsonl`) — EPIC-08
- `/brain:cold-start-recover` skill (referenced in E-HEALTH-001 message) — future story
- Six-dimensional STATE.md tracking schema (the content; STATE.md template is in STORY-002)

## Anchors

- BC-2.01.006: `behavioral-contracts/ss-01/BC-2.01.006.md`
- VP-024: `architecture/verification-properties/VP-024-plugin-lifecycle.md`
- SS-01: `architecture/subsystems/SS-01-brain-init-scaffold.md`
- phased-build-plan §5.8 (health skill is Phase 1 deliverable)
