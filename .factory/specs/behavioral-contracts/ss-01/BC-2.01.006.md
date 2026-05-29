---
document_type: behavioral-contract
level: L3
version: "1.7"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v0.1.0
modified: ["2026-05-28"]
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.006: `/brain:health` reports six-dimensional convergence state in structured JSON

## Description

`/brain:health` is the operator's primary diagnostic tool. It reads `.brain/STATE.md` and the brain's directory structure and emits a structured JSON report covering the six convergence dimensions: Capture / Sources / Wiki / Synthesis / Output / Reflection. Each dimension has a status value (GREEN / YELLOW / RED) and a detail string. The `brain-health-check.sh` hook (BC-2.04.014) independently surfaces the same summary on SessionStart by reading the cached `overall_health`, `dimensions`, and `red_dimensions` values that this skill writes to `.brain/STATE.md` frontmatter (Postcondition 5); the hook is SessionStart-event-driven per the Claude Code lifecycle and is never invoked by the skill.

## Preconditions

1. The working directory contains a valid brain (`.brain/STATE.md` and `.brain/manifest.json` exist).
2. The brain was initialized via `/brain:init` (see BC-2.01.001).

## Postconditions

1. Skill exits 0.
2. Structured JSON is emitted to stdout: `{"dimensions": {"capture": {"status": "GREEN|YELLOW|RED", "detail": "..."}, "sources": {...}, "wiki": {...}, "synthesis": {...}, "output": {...}, "reflection": {...}}, "overall": "GREEN|YELLOW|RED", "last_checked": "<ISO8601>", "writeback_status": "ok|skipped_malformed_frontmatter|failed"}`. Note: `writeback_status` is one of `{ok, skipped_malformed_frontmatter, failed}` per Postcondition 5; `writeback_error` field is present when `writeback_status` is `"failed"` and contains the yq diagnostic string.
3. Overall status is RED if any dimension is RED; YELLOW if any dimension is YELLOW and none are RED; GREEN only if all dimensions are GREEN.
4. If the 30-day trailing average token cost in `.brain/logs/ingest-tokens.jsonl` exceeds 2x the 50K-token baseline, the token budget alert is surfaced in the `sources` dimension detail (status YELLOW or RED depending on severity).
5. After computing the health report, the skill writes back `overall_health`, `last_health_check`, `dimensions` (each of the six dimension entries), and `red_dimensions` to `.brain/STATE.md` YAML frontmatter so that `brain-health-check.sh` can read the cached result on the next SessionStart without re-running the full dimensional analysis. The write uses `yq` to update the frontmatter in-place. If STATE.md is unreadable (EC-002), this postcondition is not reached. If STATE.md frontmatter is malformed (fewer than 2 `---` markers, or yq parse failure inside well-fenced frontmatter), the writeback is skipped with `writeback_status` set to `"skipped_malformed_frontmatter"` or `"failed"` respectively, the original STATE.md is preserved byte-identical, and a diagnostic is surfaced in the JSON report's `writeback_error` field.

## Invariants

1. The six dimension names are fixed: Capture, Sources, Wiki, Synthesis, Output, Reflection. No additional dimensions may be added without a BC update.
2. Status values are exactly: `GREEN`, `YELLOW`, `RED` (uppercase only).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `.brain/logs/ingest-tokens.jsonl` does not exist yet (brand-new brain) | Sources dimension reports GREEN with detail "No ingest history yet." Token budget check skipped. |
| EC-002 | `.brain/STATE.md` is missing or unreadable | Skill exits 2 with E-HEALTH-001: "Brain state file missing — run `/brain:init` or `/brain:cold-start-recover`." |
| EC-003 | Brain has 0 wiki pages (no ingests yet) | Wiki dimension reports YELLOW with detail "No wiki pages yet — ingest your first source." |
| EC-004 | `.brain/STATE.md` exists but has fewer than 2 `---` markers (malformed frontmatter fence) | Writeback skipped; `writeback_status` = `"skipped_malformed_frontmatter"` in stdout JSON; original STATE.md preserved byte-identical; dimensional JSON report still emitted (Postcondition 2) with writeback_status field set. References Postcondition 5. |
| EC-005 | `.brain/STATE.md` has well-fenced YAML frontmatter but `yq` fails to parse it (e.g., tab-indented YAML, duplicate keys) | Writeback fails; `writeback_status` = `"failed"` in stdout JSON; `writeback_error` field populated with yq diagnostic string; original STATE.md preserved byte-identical; dimensional JSON report still emitted (Postcondition 2). References Postcondition 5. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Healthy brain with recent ingests | `{"overall": "GREEN", "dimensions": {...all GREEN...}, "writeback_status": "ok"}`; exit 0 | happy-path |
| Brand-new brain (just init'd, no ingests) | `{"overall": "YELLOW", ...sources: GREEN, wiki: YELLOW, ..., "writeback_status": "ok"}`; exit 0 | edge-case |
| Brain with missing STATE.md | E-HEALTH-001 JSON; exit 2 | error |
| Brain with token cost > 2x baseline | Sources dimension YELLOW with token alert detail; `"writeback_status": "ok"` | edge-case |
| STATE.md with fewer than 2 `---` markers (EC-004) | Dimensional report with `"writeback_status": "skipped_malformed_frontmatter"`, no `writeback_error`; exit 0 (bats: `BC_2_01_006: zero-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged` and `BC_2_01_006: one-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged` in brain-health-skill.bats) | edge-case |
| STATE.md with well-fenced but yq-unparseable YAML (EC-005) | Dimensional report with `"writeback_status": "failed"`, `"writeback_error": "<yq diagnostic>"`, original STATE.md preserved byte-identical; exit 0 (bats: `BC_2_01_006: malformed YAML in well-fenced frontmatter triggers writeback_status=failed and leaves file unchanged` in brain-health-skill.bats) | edge-case |
| Healthy brain: writeback succeeds, STATE.md updated | `"writeback_status": "ok"` in stdout; STATE.md frontmatter `overall_health`/`dimensions`/`red_dimensions`/`last_health_check` updated; exit 0 (bats: `BC_2_01_006: JSON report writeback_status is ok on successful healthy brain` in brain-health-skill.bats) | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | JSON output matches schema on healthy brain | bats integration assertion |
| (no VP — P1) | Overall GREEN only when all 6 dimensions GREEN | bats unit assertion (aggregation logic) |
| (no VP — P1) | Token budget alert fires at 2x baseline | bats integration assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-001 ("Brain Initialization and Scaffold") per brief §Scope §Phase 0/1 primitives skill #2 (`/brain:health`) and §Scope §Additional v0.x deliverables ("Six-dimensional convergence tracking in `.brain/STATE.md`"). |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-01: Brain Initialization and Scaffold |
| Stories | STORY-004 |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives skill #2; §Scalability Design Principles §5 (token budget alert) |

## Related BCs

- BC-2.04.014 — composes with (`brain-health-check.sh` fires health report on SessionStart)
- BC-2.16.002 — depends on (token budget alert surfaced by health)

## Architecture Anchors

- `architecture/subsystems/SS-01-brain-init-scaffold.md`

## Story Anchor

STORY-004

## VP Anchors

- (no VP — P1 priority; deferred per VP-INDEX coverage policy)

## Changelog

### v1.7 (2026-05-29)

**CANONICAL TEST VECTOR CITATIONS CORRECTED (F13-02):** Replaced three non-existent `test_writeback_*` function-name citations in the Canonical Test Vectors table and the v1.6 changelog narrative with the actual bats `@test` names used in `brain-health-skill.bats` per the `BC_2_01_006: <description>` convention. Non-existent names were: `test_writeback_ok`, `test_writeback_skipped_malformed_frontmatter`, `test_writeback_failed_yq_error`. Actual names: (1) ok path — `BC_2_01_006: JSON report writeback_status is ok on successful healthy brain`; (2) skipped_malformed_frontmatter path — `BC_2_01_006: zero-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged` and `BC_2_01_006: one-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged` (two tests, one per EC-004 sub-variant); (3) failed path — `BC_2_01_006: malformed YAML in well-fenced frontmatter triggers writeback_status=failed and leaves file unchanged`. Closes paper-fix risk per TD-VSDD-059 — citations are now load-bearing references to real, existing tests. No semantic contract change.

### v1.6 (2026-05-28)

**WRITEBACK ENUM COVERAGE (F-P9-I02 + F-P9-I03 + optional EC-004/EC-005):**

- **Postcondition 2 JSON example (F-P9-I02):** `writeback_status` field added to the example JSON output schema. The field is always present in the stdout report and is one of `{ok, skipped_malformed_frontmatter, failed}` per Postcondition 5. `writeback_error` is conditionally present when `writeback_status` is `"failed"`, containing the yq diagnostic string. The prior example omitted this field despite Postcondition 5 being present since v1.4 — a contract surface gap.
- **Canonical Test Vectors (F-P9-I03):** Added 3 new rows covering the writeback enum paths: (1) `writeback_status="ok"` on well-formed STATE.md (positive path, bats: `BC_2_01_006: JSON report writeback_status is ok on successful healthy brain`); (2) `writeback_status="skipped_malformed_frontmatter"` on STATE.md with fewer than 2 `---` markers (safeguard path, bats: `BC_2_01_006: zero-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged` and `BC_2_01_006: one-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged`); (3) `writeback_status="failed"` on STATE.md with well-fenced but yq-unparseable YAML (failure path, bats: `BC_2_01_006: malformed YAML in well-fenced frontmatter triggers writeback_status=failed and leaves file unchanged`). All prior rows updated to include `writeback_status` in their expected output.
- **Edge Cases EC-004 and EC-005 (optional in-scope, production-grade Rule 4):** EC-004 documents the malformed-frontmatter safeguard path (fewer than 2 `---` markers → writeback skipped, STATE.md preserved byte-identical). EC-005 documents the yq parse-failure path (well-fenced but yq-unparseable YAML → writeback fails, `writeback_error` populated, STATE.md preserved byte-identical). Both reference Postcondition 5 as the authoritative specification. The bats suite (brain-health-skill.bats, 45 tests) already covers these paths; this entry brings the BC body in line with the test coverage that existed since v1.4.

### v1.5 (2026-05-28)

**Pass-8 Description prose correction (F-P8-I01):** Description sentence corrected — the skill does NOT fire the `brain-health-check.sh` hook (hook is SessionStart-event-driven per Claude Code lifecycle, not skill-driven). The skill writes the writeback surface to `.brain/STATE.md` frontmatter (Postcondition 5); the hook independently reads the cached values (`overall_health`, `dimensions`, `red_dimensions`) on next SessionStart. The cache-decoupled architecture was codified by BC-DIMENSION-RECONCILIATION.md and is reflected in AC-010 (STORY-004) and BC-2.04.014 preconditions; the Description prose previously contradicted it. Closes partial-fix regression from v1.3 → v1.4 burst.

### v1.4 (2026-05-28)

**Pass-4 Postcondition 5 enumeration completeness (F-P4-O02):** Postcondition 5 now enumerates all four field categories the skill writes (`overall_health`, `last_health_check`, `dimensions`, `red_dimensions`) rather than the two-category undersell from v1.3. Also codifies the malformed-frontmatter safeguard introduced in commit dd48972 (F-P3-I02) and the inherit_errexit yq-failure protection introduced in commit 5c8430a (F-P4-O01): `writeback_status` emits `"skipped_malformed_frontmatter"` or `"failed"` with a `writeback_error` diagnostic; original STATE.md preserved byte-identical on either skip/fail path. The hook `brain-health-check.sh` already consumes `red_dimensions` per BC-2.04.014 — this entry brings the BC body in line with the load-bearing implementation surface.

### v1.3 (2026-05-28)

**DIMENSION RECONCILIATION (BC-DIMENSION-RECONCILIATION.md):** Added Postcondition 5: skill writes back `overall_health` and `dimensions` to STATE.md frontmatter after each health computation. This enables `brain-health-check.sh` to read the cached health state on SessionStart without re-running the full dimensional analysis. This closes the AC-010 ambiguity in STORY-004 about how the hook and skill interact.

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-004; Story Anchor updated from [S-TBD] to STORY-004. No semantic change to BC contract.
