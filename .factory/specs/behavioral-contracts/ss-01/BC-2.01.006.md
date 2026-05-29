---
document_type: behavioral-contract
level: L3
version: "1.5"
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
2. Structured JSON is emitted to stdout: `{"dimensions": {"capture": {"status": "GREEN|YELLOW|RED", "detail": "..."}, "sources": {...}, "wiki": {...}, "synthesis": {...}, "output": {...}, "reflection": {...}}, "overall": "GREEN|YELLOW|RED", "last_checked": "<ISO8601>"}`.
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

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Healthy brain with recent ingests | `{"overall": "GREEN", "dimensions": {...all GREEN...}}`; exit 0 | happy-path |
| Brand-new brain (just init'd, no ingests) | `{"overall": "YELLOW", ...sources: GREEN, wiki: YELLOW, ...}`; exit 0 | edge-case |
| Brain with missing STATE.md | E-HEALTH-001 JSON; exit 2 | error |
| Brain with token cost > 2x baseline | Sources dimension YELLOW with token alert detail | edge-case |

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

### v1.5 (2026-05-28)

**Pass-8 Description prose correction (F-P8-I01):** Description sentence corrected — the skill does NOT fire the `brain-health-check.sh` hook (hook is SessionStart-event-driven per Claude Code lifecycle, not skill-driven). The skill writes the writeback surface to `.brain/STATE.md` frontmatter (Postcondition 5); the hook independently reads the cached values (`overall_health`, `dimensions`, `red_dimensions`) on next SessionStart. The cache-decoupled architecture was codified by BC-DIMENSION-RECONCILIATION.md and is reflected in AC-010 (STORY-004) and BC-2.04.014 preconditions; the Description prose previously contradicted it. Closes partial-fix regression from v1.3 → v1.4 burst.

### v1.4 (2026-05-28)

**Pass-4 Postcondition 5 enumeration completeness (F-P4-O02):** Postcondition 5 now enumerates all four field categories the skill writes (`overall_health`, `last_health_check`, `dimensions`, `red_dimensions`) rather than the two-category undersell from v1.3. Also codifies the malformed-frontmatter safeguard introduced in commit dd48972 (F-P3-I02) and the inherit_errexit yq-failure protection introduced in commit 5c8430a (F-P4-O01): `writeback_status` emits `"skipped_malformed_frontmatter"` or `"failed"` with a `writeback_error` diagnostic; original STATE.md preserved byte-identical on either skip/fail path. The hook `brain-health-check.sh` already consumes `red_dimensions` per BC-2.04.014 — this entry brings the BC body in line with the load-bearing implementation surface.

### v1.3 (2026-05-28)

**DIMENSION RECONCILIATION (BC-DIMENSION-RECONCILIATION.md):** Added Postcondition 5: skill writes back `overall_health` and `dimensions` to STATE.md frontmatter after each health computation. This enables `brain-health-check.sh` to read the cached health state on SessionStart without re-running the full dimensional analysis. This closes the AC-010 ambiguity in STORY-004 about how the hook and skill interact.

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-004; Story Anchor updated from [S-TBD] to STORY-004. No semantic change to BC contract.
