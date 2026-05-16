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
subsystem: "SS-09"
capability: "CAP-009"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.09.005: `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` directory structure is maintained

## Description

The brain's content lifecycle directory structure uses platform-specific subdirectories within each state bucket. This is a brief-introduced extension beyond phased-build-plan.md §A.2's simpler `published/` baseline — absorbed from wclaude. The structure enables multi-platform publishing workflows and the state-machine hook (BC-2.04.010). The v0.x committed platform is LinkedIn; `drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/` are the primary directories.

## Preconditions

1. `/brain:init` has been run.

## Postconditions

1. After init: `drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/` exist.
2. When a new platform is registered (via extension): corresponding directories are created.

## Invariants

1. Platform directories always follow the `{state}/{platform}/` pattern.
2. Platform names are kebab-case (e.g., `linkedin`, `medium`, not `LinkedIn`, `Medium`).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Medium reference extension installed | `drafts/medium/`, `to-publish/medium/`, `published/medium/` created. |
| EC-002 | Custom platform `my-newsletter` | Operator creates `drafts/my-newsletter/` manually; state machine hook enforces state transitions for this platform too. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh init | `drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/` present | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | LinkedIn directories present after init | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Family Positioning ("`drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` directory structure: adopted in the target brain's content layer as a brief-introduced extension beyond phased-build-plan §A.2's simpler `published/` baseline"). |
| Architecture Module | SS-09: Publishing Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.01.001 — composes with (init scaffolds these)
- BC-2.09.004 — depends on (state machine uses these directories)
