---
document_type: behavioral-contract
level: L3
version: "1.2"
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
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.006: `/brain:health` reports six-dimensional convergence state in structured JSON

## Description

`/brain:health` is the operator's primary diagnostic tool. It reads `.brain/STATE.md` and the brain's directory structure and emits a structured JSON report covering the six convergence dimensions: Capture / Sources / Wiki / Synthesis / Output / Reflection. Each dimension has a status value (GREEN / YELLOW / RED) and a detail string. The skill also fires the `brain-health-check.sh` hook, which displays the same summary on SessionStart.

## Preconditions

1. The working directory contains a valid brain (`.brain/STATE.md` and `.brain/manifest.json` exist).
2. The brain was initialized via `/brain:init` (see BC-2.01.001).

## Postconditions

1. Skill exits 0.
2. Structured JSON is emitted to stdout: `{"dimensions": {"capture": {"status": "GREEN|YELLOW|RED", "detail": "..."}, "sources": {...}, "wiki": {...}, "synthesis": {...}, "output": {...}, "reflection": {...}}, "overall": "GREEN|YELLOW|RED", "last_checked": "<ISO8601>"}`.
3. Overall status is RED if any dimension is RED; YELLOW if any dimension is YELLOW and none are RED; GREEN only if all dimensions are GREEN.
4. If the 30-day trailing average token cost in `.brain/logs/ingest-tokens.jsonl` exceeds 2x the 50K-token baseline, the token budget alert is surfaced in the `sources` dimension detail (status YELLOW or RED depending on severity).

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

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-004; Story Anchor updated from [S-TBD] to STORY-004. No semantic change to BC contract.
