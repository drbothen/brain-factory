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
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.010: `validate-publish-state.sh` blocks invalid frontmatter state-machine transitions (exit 2)

## Description

`validate-publish-state.sh` fires on PostToolUse (Write|Edit on `drafts/{platform}/*.md`, `to-publish/{platform}/*.md`, or `published/{platform}/*.md`). It enforces the frontmatter state machine from the wclaude absorption: `draft → ready → published`. Invalid transitions (e.g., jumping from `draft` directly to `published`, or reverting from `published` to `draft`) are blocked. This ensures the publishing audit trail is never corrupted.

## Preconditions

1. PostToolUse fires on Write|Edit targeting `drafts/**`, `to-publish/**`, or `published/**`.
2. The file has YAML frontmatter with a `status` field.
3. The hook can read the file's previous state (if it existed before the write).

## Postconditions

**On invalid state transition:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-PUBLISH-001", "message": "Invalid state transition: '<from>' → '<to>' is not allowed. Valid transitions: draft→ready, ready→published.", "trace": "<uuid>"}`.

**On valid transition or new file creation:**
1. Hook exits 0.

## Invariants

1. Valid transitions: `draft → ready`, `ready → published`.
2. Reverse transitions are always blocked: `published → ready`, `ready → draft`, `published → draft`.
3. A new file with `status: draft` is always allowed (no prior state = creation).
4. The `status` field is mandatory in all content-lifecycle files covered by this hook.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | New file with `status: draft` (no prior state) | Exit 0 (creation). |
| EC-002 | Direct transition from `draft` to `published` (skipping `ready`) | Block with E-PUBLISH-001. |
| EC-003 | `status` field absent | Exit 2 with E-PUBLISH-002: "Missing status field in content file <path>." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| New file, `status: draft` | exit 0 | happy-path |
| `draft → ready` transition | exit 0 | happy-path |
| `ready → published` transition | exit 0 | happy-path |
| `draft → published` (skip ready) | E-PUBLISH-001; exit 2 | error |
| `published → draft` (reversal) | E-PUBLISH-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All valid transitions pass | bats hooks.bats |
| VP-TBD | All invalid transitions blocked | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#13 `validate-publish-state.sh`) and §Family Positioning (wclaude absorption: "Frontmatter state machine (draft → ready → published): absorbed into `/brain:publish-content` + new `validate-publish-state.sh` hook"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#13); §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.09.004 — depends on (publishing skill uses this state machine)
