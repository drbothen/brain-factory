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
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.02.005: `/brain:ingest-url` warns when source exceeds 50K-token chunk threshold

## Description

When the Defuddle-extracted content of a URL exceeds the 50K-token per-chunk threshold (configurable via `.brain/policies.yaml` as `max_ingest_tokens_per_chunk`), the skill warns the operator in v0.1 (no automatic chunking). Chunking is a v0.5+ feature. The warning names the v0.5 behavior explicitly so operators know what to expect.

## Preconditions

1. `/brain:ingest-url` has fetched and cleaned the URL content.
2. Token count for the cleaned content has been computed (estimated via word-count heuristic or API token count).
3. `max_ingest_tokens_per_chunk` is readable from `.brain/policies.yaml` (default: 50000).

## Postconditions

1. If content exceeds threshold:
   - Skill emits advisory (not block): `"Source content estimated at <N> tokens, exceeding the <threshold>-token chunk threshold. Full content ingested in v0.1. Automatic chunking available at v0.5+. Consider splitting large sources manually."`
   - Ingest proceeds normally — the full content is ingested as a single source file.
   - `manifest.json` entry for this source includes `"chunks": []` (empty — v0.5+ will populate).
2. If content is within threshold: no warning; ingest proceeds normally.

## Invariants

1. The warning is advisory only (no exit code change from the threshold breach).
2. The `chunks` field in `manifest.json` is always present (even when empty) per BC-2.01.004 and BC-2.06.002.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `max_ingest_tokens_per_chunk` not in policies.yaml | Use default value of 50000 tokens. |
| EC-002 | Content is exactly at the threshold | No warning (threshold is exclusive: > 50K triggers warning). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Source with 30K tokens | No warning; exit 0 | happy-path |
| Source with 80K tokens | Advisory warning emitted; exit 0; full content ingested | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Threshold breach → advisory warning | bats skills.bats |
| (no VP — P1) | Ingest still completes on threshold breach | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Scalability Design Principles §7 ("Page-chunking readiness: `/brain:ingest-url` detects when source content exceeds the 50K-token threshold... outputs a warning in v0.1"). |
| Architecture Module | SS-02: URL Ingest Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §7 |

## Related BCs

- BC-2.02.001 — composes with
- BC-2.06.002 — related to (manifest chunks array reserved here)
