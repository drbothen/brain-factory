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
subsystem: "SS-12"
capability: "CAP-012"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.12.002: `bin/lobster-run` exits 0 (all steps succeed), 1 (advisory), 2 (any step blocks)

## Description

`bin/lobster-run` aggregates step exit codes into a single pipeline exit code following the same 0/1/2 semantics as the hook contract. This makes it composable with the hook chain and with CI pipeline steps.

## Preconditions

1. Workflow execution has completed.

## Postconditions

1. Exit 0: all steps exited 0.
2. Exit 1: at least one step exited 1; no step exited 2.
3. Exit 2: at least one step exited 2 (pipeline stopped at that step).

## Invariants

1. Exit 2 from any step stops the pipeline immediately. Remaining steps do NOT run.
2. Exit 1 from any step is accumulated; the pipeline continues.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| All steps exit 0 | lobster-run exits 0 | happy-path |
| One step exits 1; rest exit 0 | lobster-run exits 1 | edge-case |
| One step exits 2 | lobster-run exits 2 immediately | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Exit codes match expected semantics | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-012 ("Lobster Runtime") per brief §Scope §bin/lobster-run ("exits 0/1/2"). |
| Architecture Module | SS-12: Lobster Runtime |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §bin/lobster-run |

## Related BCs

- BC-2.12.001 — composes with
