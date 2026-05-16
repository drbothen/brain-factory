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

# Behavioral Contract BC-2.16.003: GH Actions process 100 sources/day sustained over 5-day test run without data loss

## Description

The v0.9 scale gate requires that the GH Action templates process 100 sources per day sustained over a 5-day test run (500 total sources) without rate-limit-induced data loss or hard failures. This tests the parallelism and rate-limit handling (BC-2.13.002 and BC-2.13.003) at realistic power-user scale.

## Preconditions

1. v0.9 scale test environment configured.
2. `scripts/gen-test-corpus.sh` has generated 500 sources.
3. GH Actions enabled on the test brain.

## Postconditions

1. All 500 sources ingested successfully within the 5-day window.
2. No data loss from rate limiting (all sources recorded in manifest).
3. No hard failures (exit 2) in any GH Action run.

## Invariants

1. Rate-limit handling (429 → exponential backoff) prevents data loss.
2. The 100 sources/day target is measured via manifest entry count.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 100 RSS feeds processed in one `rss-inbox.yml` run | All 100 entries in manifest; no hard failures | scale |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | 100 sources/day without data loss | bats upgrade.bats (scale simulation) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-016 ("Scale-Aware Architecture") per brief §Success Criteria §v0.9 ship gate ("GH Actions process the target ingest rate (100 sources/day sustained over 5 days of the test run) without rate-limit-induced data loss or hard failures"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Success Criteria §v0.9 ship gate §Scale test |
