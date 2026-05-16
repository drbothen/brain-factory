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

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `/brain:lint-wiki` on 10K-page wiki | Peak RSS < 2GB | scale |

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
