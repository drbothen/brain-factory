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
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.005: `/brain:init` scaffolds `briefs/research/` subdirectory

## Description

`/brain:init` creates the `briefs/research/` directory in the target brain even though the `/brain:research` skill that writes into it does not ship until v0.9. This is a brief-introduced extension beyond the five enumerated `briefs/` subdirs in phased-build-plan.md §A.2 (daily, weekly, monthly, content, decisions). The v0.1 ship gate explicitly tests that this directory exists after init, decoupling the scaffold from the skill delivery.

## Preconditions

1. All preconditions from BC-2.01.001 are satisfied.

## Postconditions

1. `briefs/research/` directory exists in the target brain after init.
2. `briefs/research/` is empty (no files) at init time — `/brain:research` writes into it at v0.9.
3. The existence of `briefs/research/` does not cause any hook to fire an advisory or block.

## Invariants

1. The `briefs/research/` directory is part of the standard init scaffold from v0.1 onward.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Operator deletes `briefs/research/` after init | `/brain:research` recreates it on first use. Not init's responsibility to enforce persistence. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh init | `briefs/research/` exists; directory is empty | happy-path |
| `ls briefs/` after init | Output includes `research/` alongside daily/ weekly/ monthly/ content/ decisions/ | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1 BC; VP-INDEX P0 matrix covers P0 BCs only) | `briefs/research/` directory exists after init | bats integration assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-001 ("Brain Initialization and Scaffold") per brief §Scope §Phase 0/1 primitives skill #1 and §Scope §Phase 2–3 new skill item #26 (`/brain:research` writes to `briefs/research/<topic>-research.md`; directory created by init). |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-01: Brain Initialization and Scaffold |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 2–3 new skill (#26 `/brain:research`); §Success Criteria §v0.1 ship gate |

## Related BCs

- BC-2.01.001 — composes with (briefs/research/ is part of init scaffold)

## Architecture Anchors

- `architecture/subsystems/SS-01-brain-init-scaffold.md`

## Story Anchor

[S-TBD]

## VP Anchors

- (no VP — P1 priority; deferred per VP-INDEX coverage policy)
