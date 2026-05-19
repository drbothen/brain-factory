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
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.11.002: `/brain:synthesize` builds a weekly thesis from the connection layer

## Description

`/brain:synthesize` performs the weekly synthesis ritual: it reads the most recent connection brief from `briefs/weekly/` and prior synthesises, identifies an emerging thesis or position from the connected knowledge, and writes a synthesis brief to `briefs/weekly/synthesis-{YYYY-MM-DD}.md`. The synthesis brief becomes input for the content brief pipeline.

## Preconditions

1. At least one connection brief exists in `briefs/weekly/`.
2. `brain:synthesizer` available.

## Postconditions

1. `briefs/weekly/synthesis-{YYYY-MM-DD}.md` created with a clear thesis statement, supporting evidence from the wiki, and implications.
2. Exit 0.

## Invariants

1. Synthesis must cite wiki pages via wikilinks (not hallucinated citations).
2. Each synthesis is a new file — does not overwrite prior syntheses.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | No connection briefs exist | Advisory: "No connection briefs found. Run /brain:connect first."; exit 1. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 1 connection brief | Synthesis created with thesis; wiki citations; exit 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Synthesis file created with thesis and citations | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-011 ("Knowledge Synthesis and Connection") per brief §Scope §Phase 0/1 primitives skill #8 (`/brain:synthesize — weekly synthesis, builds a thesis from connection layer`). |
| Architecture Module | SS-11: Knowledge Synthesis and Connection |
| Stories | STORY-025 |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#8) |

## Related BCs

- BC-2.11.001 — depends on (connection brief is input)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-025 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
