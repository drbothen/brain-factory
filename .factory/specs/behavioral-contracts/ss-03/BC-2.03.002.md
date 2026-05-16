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
subsystem: "SS-03"
capability: "CAP-003"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.03.002: `/brain:ingest-source` writes manifest delta entry on every successful ingest

## Description

Same manifest-delta contract as BC-2.02.004 applied to local source ingest. The manifest entry for a local source includes the canonical file path (relative to brain root) instead of a URL. The `chunks` and `embeddings_model` fields are present in the entry from v0.1.

## Preconditions

1. Source file has been successfully read and processed.
2. `.brain/manifest.json` is readable and writable.

## Postconditions

1. New manifest entry: `{"source_id": "<slug>", "path": "<relative-path>", "topic": "<topic>", "ingested_at": "<ISO8601>", "last_ingest": "<ISO8601>", "chunks": [], "embeddings_model": null}`.
2. Existing entries not modified.
3. Write is atomic.

## Invariants

1. `path` field (not `url`) distinguishes local-source manifest entries.
2. No full manifest rewrite on append.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Manifest write fails | Source file write rolled back; E-INGEST-008 emitted. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Successful local ingest | Manifest entry with `path` field present | happy-path |
| Manifest read after 10K entries | New entry appended; existing unchanged | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Manifest entry written with path field | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-003 ("Source Ingest Pipeline") per brief §Scalability Design Principles §1. |
| Architecture Module | SS-03: Source Ingest Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §1; §Scope §Phase 0/1 primitives (#4) |

## Related BCs

- BC-2.03.001 — composes with
- BC-2.02.004 — related to (same manifest-delta contract)
