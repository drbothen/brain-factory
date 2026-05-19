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
subsystem: "SS-16"
capability: "CAP-016"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.16.002: Token budget alert: `/brain:health` warns if 30-day trailing average exceeds 2x baseline

## Description

`/brain:health` computes the 30-day trailing average token cost from `.brain/logs/ingest-tokens.jsonl` and compares it to the 50K-token baseline. If the trailing average exceeds 100K tokens (2x baseline), the Sources dimension of the health report goes YELLOW with the alert. If it exceeds 150K (3x baseline), it goes RED.

## Preconditions

1. `.brain/logs/ingest-tokens.jsonl` has at least 30 days of records.
2. `/brain:health` is invoked.

## Postconditions

1. If trailing average ≤ 100K: no alert; Sources dimension GREEN.
2. If trailing average 100K–150K: advisory alert; Sources dimension YELLOW.
3. If trailing average > 150K: critical alert; Sources dimension RED.
4. The alert message includes: "30-day trailing average: <N> tokens/ingest (baseline: 50K). <2x|3x>x baseline exceeded."

## Invariants

1. The baseline is always 50K tokens (configurable per `max_ingest_tokens_per_chunk` in policies.yaml).
2. The 30-day window is rolling (most recent 30 days, not calendar month).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Fewer than 30 days of records | Use available records; note in alert message "Based on <N>-day history." |
| EC-002 | Empty log (new brain) | No alert; Sources GREEN with "No ingest history yet." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 30 days; average 80K/ingest | Sources GREEN; no alert | happy-path |
| 30 days; average 120K/ingest | Sources YELLOW; 2x alert | edge-case |
| 30 days; average 200K/ingest | Sources RED; 3x alert | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | 2x threshold → YELLOW | bats integration.bats |
| (no VP — P1) | 3x threshold → RED | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-016 ("Scale-Aware Architecture") per brief §Scalability Design Principles §5 ("Operators receive an alert via `/brain:health` if the 30-day trailing average exceeds 2x the baseline."). |
| Architecture Module | SS-16: Scale-Aware Architecture |
| Stories | STORY-037 |
| Source Brief Section | product-brief.md §Scalability Design Principles §5 |

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-037 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
