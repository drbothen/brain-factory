---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-06"
capability: "CAP-006"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.06.003: `manifest.json` records `last_ingest` timestamps per source

## Description

Each manifest entry contains `last_ingest` (ISO8601) recording the most recent time the source was processed. In v0.x this is always equal to `ingested_at` (sources are ingested once). At v0.5+, when re-ingest is supported, `last_ingest` will differ from `ingested_at`. The field is present from v0.1 to avoid a schema migration at v0.5+.

## Preconditions

1. Ingest has been performed successfully.

## Postconditions

1. `last_ingest` in the manifest entry equals `ingested_at` on first ingest.
2. `last_ingest` is a valid ISO8601 UTC timestamp.

## Invariants

1. `last_ingest` is never null after a successful ingest.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Re-ingest at v0.5+ | `last_ingest` updated; `ingested_at` unchanged (preserves original creation date). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| First ingest | manifest entry has `last_ingest` = `ingested_at` | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-012 (Group 2: last_ingest field correctness) | last_ingest present and valid ISO8601 after successful ingest | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-006 ("Source Layer and Immutability") per brief §Scalability Design Principles §1 ("The brain's `manifest.json` records `last_ingest` timestamps per source."). |
| Architecture Module | SS-06: Source Layer and Immutability |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §1 |

## VP Anchors

- VP-012 — Manifest schema integrity (Group 2: last_ingest field correctness)

## Related BCs

- BC-2.06.002 — related to (manifest schema)
