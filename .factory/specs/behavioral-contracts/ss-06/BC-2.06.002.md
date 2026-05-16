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

# Behavioral Contract BC-2.06.002: `manifest.json` schema supports `chunks` array from v0.1 (populated at v0.5+)

## Description

Every manifest entry includes a `chunks` array from v0.1, even though the chunking feature ships at v0.5+. This field reservation ensures the v0.5+ chunk-writing code does not need to migrate existing manifest entries — it simply populates the pre-existing field. The `embeddings_model` field is similarly reserved (null in v0.x; populated by v1.0+ vector retrieval).

## Preconditions

1. `/brain:init` has initialized `.brain/manifest.json`.

## Postconditions

1. Every manifest entry (whether created by URL or local-file ingest) contains: `"chunks": []` (empty array in v0.x) and `"embeddings_model": null`.
2. These fields are present from the first ingest onward.

## Invariants

1. `chunks` is always an array (never null, never absent).
2. `embeddings_model` is always null in v0.x.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Operator manually deletes `chunks` field from manifest | Next ingest that reads the manifest may encounter missing field. The ingest skill must handle missing `chunks` gracefully (treat as empty array). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh ingest; read manifest entry | `"chunks": []` and `"embeddings_model": null` present | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | chunks and embeddings_model present in every new entry | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-006 ("Source Layer and Immutability") per brief §Scalability Design Principles §6 ("The `manifest.json` schema includes an `embeddings_model` field (default: null in v0.x)") and §7 ("The `manifest.json` schema supports a `chunks: [...]` array from v0.1"). |
| Architecture Module | SS-06: Source Layer and Immutability |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §6, §7 |

## Related BCs

- BC-2.01.004 — composes with (init writes schema)
- BC-2.06.003 — related to (manifest schema)
