---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-09"
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
| VP-020 | All valid transitions pass | bats tests/validate-publish-state.bats |
| VP-020 | All invalid transitions blocked | bats tests/validate-publish-state.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Family Positioning ("Frontmatter state machine (draft → ready → published): absorbed into `/brain:publish-content` + new `validate-publish-state.sh` hook"). |
| Architecture Module | SS-09: Publishing Pipeline |
| Stories | STORY-030 |
| Source Brief Section | product-brief.md §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.04.010 — depends on (hook enforces this)
- BC-2.09.005 — composes with (directory structure)

## Changelog

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-030 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-publish-state.bats` (2 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
