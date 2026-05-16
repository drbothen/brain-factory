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
subsystem: "SS-16"
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

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A single ingest in the 10-run sample exceeds 500K tokens (pathological outlier) | That ingest is flagged as an outlier in the token log; the bats scale test fails with a specific message identifying the outlier ingest URL and its token count; the implementer must investigate the chunking path for that content type |
| EC-002 | The 10K-source corpus is loaded but `manifest.json` is not pre-built (no existing-corpus baseline) | The test must still run using `gen-test-corpus.sh --seed 42 --count 10000` to pre-build the corpus before measurement; the measurement protocol is documented in the bats scale test setup |
| EC-003 | An ingest runs on an unusually dense source (100K-word academic paper requiring 10 chunks) | Chunked ingests are measured as the total input tokens across all chunks for that source; if that total exceeds 150K, it contributes to the average; if the average breaches 150K, the scale gate fails and the chunking strategy must be revisited |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 10 test ingests on 10K-corpus | Average input_tokens ≤ 150K | scale |
| 10 test ingests where 1 ingest costs 520K tokens | Test fails; outlier logged; implementer alerted | error |
| 10 test ingests with a 10-chunk source | Total tokens for chunked source summed; average computed across all 10 | edge-case |

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
