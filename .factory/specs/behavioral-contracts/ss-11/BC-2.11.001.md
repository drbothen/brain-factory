---
document_type: behavioral-contract
level: L3
version: "1.1"
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

# Behavioral Contract BC-2.11.001: `/brain:connect [days]` finds cross-domain connections across recent ingests

## Description

`/brain:connect [days]` (default: 7 days) scans recently ingested wiki pages and identifies non-obvious cross-domain connections — links between concepts from different source topics that weren't explicitly cited by the source authors. Uses the `brain:synthesizer` agent to find the connections. Output is written to `briefs/weekly/connections-{YYYY-MM-DD}.md`.

## Preconditions

1. At least 2 wiki pages ingested within the specified time window.
2. `brain:synthesizer` available.

## Postconditions

1. `briefs/weekly/connections-{YYYY-MM-DD}.md` created with at least 1 non-obvious connection per pair of distinct source topics.
2. Each connection cites the two wiki pages involved via wikilinks.
3. Exit 0.

## Invariants

1. Connections must be cross-domain (same-topic connections are not reported).
2. Wikilinks in the output resolve (validated by wikilink hook).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Fewer than 2 wiki pages in window | Advisory: "Not enough recent content for connection analysis. Ingest more sources first." Exit 1. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 10 wiki pages from 3 topics | Connection brief created; multiple cross-domain connections; exit 0 | happy-path |
| 0 pages in window | Advisory; exit 1 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Connection brief created with valid wikilinks | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-011 ("Knowledge Synthesis and Connection") per brief §Scope §Phase 0/1 primitives skill #7 (`/brain:connect [days] — find cross-domain connections across recent ingests`). |
| Architecture Module | SS-11: Knowledge Synthesis and Connection |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#7) |
