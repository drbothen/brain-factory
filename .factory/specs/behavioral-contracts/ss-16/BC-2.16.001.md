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
subsystem: "SS-16"
capability: "CAP-016"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.16.001: Token instrumentation: `/brain:ingest-url` writes JSONL record per invocation

## Description

See BC-2.02.003 for the full specification of the token instrumentation JSONL record format. This BC confirms the scale-aware architecture requirement: token instrumentation is not an optional feature — it is a first-class architectural constraint that enables the operator to track cost at 10K-source scale and prevent budget surprises.

## Preconditions

1. `/brain:ingest-url` (or `/brain:ingest-source`) has completed.

## Postconditions

1. JSONL record appended to `.brain/logs/ingest-tokens.jsonl`.
2. Record is never omitted (even on partial failure).

## Invariants

1. Token records are append-only. No record is ever modified or deleted.
2. Records are written on every ingest invocation — not batched or deferred.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Ingest completes partially (some wiki pages written, then a hook blocks) | JSONL record is still appended with `status: partial` and the token count up to the point of failure; the record is never omitted |
| EC-002 | `.brain/logs/ingest-tokens.jsonl` does not exist at ingest time | The file is created by the first ingest invocation; the directory `.brain/logs/` is created if absent; exit 0; record written |
| EC-003 | Corpus reaches 10K sources and a new ingest is run; JSONL file exceeds 1MB in size | The JSONL record is still appended without truncation; the file grows append-only; operators use `/brain:monthly-perf` to aggregate, not raw file reads on the full log |

## Canonical Test Vectors

See BC-2.02.003 for test vectors.

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-025 | Token record written on every ingest | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-016 ("Scale-Aware Architecture") per brief §Scalability Design Principles §5 ("Token budget instrumentation: Every operation reports its token consumption."). |
| Architecture Module | SS-16: Scale-Aware Architecture |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §5 |

## Related BCs

- BC-2.02.003 — this BC elaborates the scale dimension of that contract
