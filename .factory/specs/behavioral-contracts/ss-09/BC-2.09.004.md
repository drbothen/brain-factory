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
capability: "CAP-009"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.09.004: Frontmatter state machine enforces `draft → ready → published` transitions

## Description

The publishing workflow follows a strict three-state machine: `draft` (in `drafts/{platform}/`) → `ready` (in `to-publish/{platform}/`) → `published` (in `published/{platform}/`). This state machine is enforced by `validate-publish-state.sh` (BC-2.04.010). The file's physical location (directory) tracks the state; the frontmatter `status` field echoes it. Both must be consistent.

## Preconditions

1. A content file is in one of the three state directories.
2. A Write or Edit is performed on the file.

## Postconditions

1. Valid transitions: `draft → ready`, `ready → published`. Both are allowed.
2. Invalid transitions: `draft → published`, `published → ready`, `published → draft`, `ready → draft`. All blocked by hook.
3. File location and `status` field are always consistent.

## Invariants

1. A file in `drafts/{platform}/` always has `status: draft`.
2. A file in `to-publish/{platform}/` always has `status: ready`.
3. A file in `published/{platform}/` always has `status: published`.
4. The hook enforces consistency: if location and status disagree, block.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | File manually moved from `published/` back to `drafts/` | Hook fires on next write; detects `status: published` in `drafts/` directory; E-PUBLISH-001 (invalid state location). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| New file in `drafts/` with `status: draft` | Valid; hook exits 0 | happy-path |
| Update `status: ready` for file in `to-publish/` | Valid; hook exits 0 | happy-path |
| Set `status: published` for file in `drafts/` | E-PUBLISH-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All valid transitions pass | bats hooks.bats |
| VP-TBD | All invalid transitions blocked | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Family Positioning ("Frontmatter state machine (draft → ready → published): absorbed into `/brain:publish-content` + new `validate-publish-state.sh` hook"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.04.010 — depends on (hook enforces this)
- BC-2.09.005 — composes with (directory structure)
