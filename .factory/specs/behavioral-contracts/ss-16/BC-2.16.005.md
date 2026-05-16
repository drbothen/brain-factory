---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-016"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.16.005: Per-ingest token cost stays within 3x the 50K-token baseline at 10K-source corpus

## Description

At 10K-source corpus size, the per-ingest token cost may be higher than at 1K scale (due to chunking overhead, larger index, etc.) but must stay within 3x the 50K-token baseline (i.e., ≤ 150K input tokens per ingest). This is measured as the average over the 10K-source scale test ingest run.

## Preconditions

1. 10K-source corpus has been pre-loaded.
2. `/brain:ingest-url` is run on 10 additional sources.
3. Token records are in `.brain/logs/ingest-tokens.jsonl`.

## Postconditions

1. Average `input_tokens` across the 10 test ingests is ≤ 150K.
2. No single ingest exceeds 500K tokens (pathological outlier limit).

## Invariants

1. The 3x bound is an average, not a per-ingest hard cap.
2. p95 cost is included in the monthly-perf report.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 10 test ingests on 10K-corpus | Average input_tokens ≤ 150K | scale |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Average cost within 3x baseline | bats integration.bats (scale) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-016 ("Scale-Aware Architecture") per brief §Success Criteria §v0.9 ship gate ("Token budget at scale: per-ingest cost stays within 3x the 50K-token baseline (i.e., ≤150K input tokens per ingest including chunking overhead at the 10K-source corpus size)."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Success Criteria §v0.9 ship gate §Scale test |
