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
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.02.007: `/brain:ingest-url` latency stays sub-linear as wiki grows 1K→10K pages

## Description

The ingest pipeline must remain performant as the wiki grows. At 10K pages, an O(n) or worse scan on every ingest would make the operation progressively slower. This BC requires that ingest latency (excluding network fetch time) stays sub-linear — O(log n) or O(n) at most — as the wiki grows from 1K to 10K pages. This is a v0.9 scale gate requirement.

## Preconditions

1. Wiki contains N pages (tested at N = 1K, 5K, 10K).
2. `scripts/gen-test-corpus.sh` has pre-populated the brain with N-1 sources and corresponding wiki pages.

## Postconditions

1. Ingest of a single new URL (excluding network fetch time) completes in time T(N) where T(N) ≤ C * log(N) for some constant C (O(log n)), or at worst T(N) ≤ C * N (O(n)).
2. T(10K) / T(1K) ≤ 20 (the 10x wiki growth does not cause more than 20x slowdown).
3. The v0.9 scale gate asserts this ratio via automated measurement.

## Invariants

1. Network fetch time is excluded from the measurement (variable by network conditions).
2. The measurement is wiki-layer operations only: manifest read, duplicate check, wiki page writes, index updates.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | wikilink-integrity check is O(n) at 10K pages | Acceptable: O(n) satisfies the contract. Architecture concern if O(n) at 10K takes > 10 minutes (see BC-2.05.001). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Ingest at 1K pages: measure T | T(1K) < 30 seconds (excluding fetch) | happy-path |
| Ingest at 10K pages: measure T | T(10K) / T(1K) ≤ 20 | edge-case (scale) |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-027 | Latency ratio ≤ 20 at 10K vs 1K pages | bats integration.bats (scale measurement) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Success Criteria §v0.9 ship gate ("`/brain:ingest-url` retrieval-plus-wiki-write latency stays sub-linear (O(log n) or better) as the wiki grows from 1K to 10K pages"). |
| Architecture Module | SS-02: URL Ingest Pipeline |
| Stories | STORY-018 |
| Source Brief Section | product-brief.md §Success Criteria §v0.9 ship gate §Scale test |

## Related BCs

- BC-2.02.004 — composes with (manifest-delta design enables sub-linear performance)
- BC-2.16.003 — related to (GH Action scale requirements)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-018 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
