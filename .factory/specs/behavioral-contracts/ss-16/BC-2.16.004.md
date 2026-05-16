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
subsystem: "SS-TBD"
capability: "CAP-016"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.16.004: Peak resident memory for any single operation stays under 2GB

## Description

At 10K-source scale, memory usage during operations (especially `/brain:lint-wiki` on a 10K-page wiki) must stay under 2GB peak resident memory. This ensures the brain can operate on a standard developer laptop or GitHub Actions runner without OOM kills.

## Preconditions

1. Operation running on a machine with ≥ 8GB RAM (standard developer laptop or CI runner).
2. 10K-page wiki present in test environment.

## Postconditions

1. Peak resident memory for any single skill invocation, hook execution, or GH Action step does not exceed 2GB.
2. Measured via `/usr/bin/time -v` or equivalent.

## Invariants

1. The 2GB limit applies to any single operation — not cumulative across parallel operations.
2. Measurement is on the GitHub Actions `ubuntu-latest` runner specification.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `/brain:lint-wiki` on a wiki exactly at the 10K-page boundary (10,000 pages, not 10,001) | The operation completes within the 2GB limit; this is the reference measurement point for the scale gate; the measurement is repeatable across three runs |
| EC-002 | A concurrent GH Action step is running while `/brain:lint-wiki` executes on the same runner | The 2GB limit applies to the lint-wiki process alone (single-operation scope); concurrent processes on the same runner are outside this BC's scope; the measurement must isolate the lint-wiki process memory via `/usr/bin/time -v` on that PID |
| EC-003 | The wiki contains pages with extremely large embedded content (a page with a 50KB description field in frontmatter) | The operation must still complete under 2GB even with outlier pages; if the limit is breached, the bats test fails and the architect must investigate the O(n) read path for memory accumulation |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `/brain:lint-wiki` on 10K-page wiki | Peak RSS < 2GB | scale |
| `/brain:lint-wiki` on 1K-page wiki | Peak RSS < 200MB (proportional scaling check) | scale |
| `/brain:lint-wiki` with one page containing 50KB frontmatter | Peak RSS < 2GB; lint completes | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Peak memory < 2GB on lint-wiki at 10K pages | bats integration.bats (time -v wrapper) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-016 ("Scale-Aware Architecture") per brief §Success Criteria §v0.9 ship gate ("Peak resident memory for any single operation stays under 2GB (measured via `/usr/bin/time -v` or equivalent on the Actions runner)."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Success Criteria §v0.9 ship gate §Scale test |
