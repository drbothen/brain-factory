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
capability: "CAP-007"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.07.003: `/brain:adversary-review` implements multi-pass writescore revision loop

## Description

`/brain:adversary-review` implements the writescore-based multi-pass revision loop absorbed from wclaude. If the initial pass returns FAIL, the skill proposes revisions, applies them (with operator confirmation), and re-runs the validation agents until the artifact passes or a maximum iteration count is reached. Each pass is tracked with a score and finding list.

## Preconditions

1. Initial adversary review has returned FAIL (one or more agents failed).
2. The artifact is editable (not a read-only source file).
3. Maximum iterations configured in `.brain/policies.yaml` (default: 3).

## Postconditions

1. On PASS within iteration limit: artifact updated; exit 0; PASS verdict.
2. On FAIL at maximum iterations: exit 1; FAIL verdict with all iteration results included.
3. Each iteration's writescore is recorded.

## Invariants

1. Each revision pass runs all four validation agents (no partial re-runs).
2. The revision loop is bounded by `max_adversary_iterations` in policies.yaml (default: 3).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Artifact passes on first pass | No revision loop; single-pass result; exit 0. |
| EC-002 | Max iterations reached; still failing | Exit 1 with all iteration results; operator takes manual action. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Artifact fails initially; passes after 1 revision | 2 passes total; exit 0; PASS | happy-path |
| Artifact fails all 3 iterations | 3 passes; exit 1; FAIL with all iteration data | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Revision loop bounded by max_iterations | bats adversary.bats |
| VP-TBD | Each pass re-runs all 4 agents | bats adversary.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-007 ("Adversarial Review and Writescore") per brief §Family Positioning ("Writescore + revision-loop: multi-pass revision with score threshold baked into `/brain:adversary-review`."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.07.002 — composes with
