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
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.014: `brain-health-check.sh` surfaces six-dimensional convergence state on SessionStart (exit 0 or 1)

## Description

`brain-health-check.sh` fires on the SessionStart event. It reads `.brain/STATE.md` and emits the six-dimensional convergence state as a banner to the operator. This gives the operator immediate situational awareness at the start of each session without requiring a manual `/brain:health` invocation. If any dimension is RED, the hook exits 1 (advisory) so the state is surfaced prominently.

## Preconditions

1. SessionStart event fires.
2. Working directory is a brain (`.brain/STATE.md` exists) OR is not a brain (in which case the hook exits 0 silently).

## Postconditions

**In a valid brain with GREEN overall state:**
1. Hook exits 0.
2. stdout: `{"verdict": "allow", "message": "Brain health: GREEN. <summary>", "trace": "<uuid>"}`.

**In a valid brain with YELLOW or RED state:**
1. Hook exits 1 (advisory).
2. stdout: `{"verdict": "advise", "code": "E-HEALTH-002", "message": "Brain health: <YELLOW|RED>. <dimension summaries with issues>", "trace": "<uuid>"}`.

**Not in a brain directory (`.brain/STATE.md` absent):**
1. Hook exits 0 silently (no banner shown — not every session is a brain session).

## Invariants

1. This hook NEVER exits 2 (a SessionStart block would prevent the session from opening — unacceptable).
2. The banner is concise: one line per RED/YELLOW dimension, showing dimension name and issue summary.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Not in a brain directory | Exit 0 silently. |
| EC-002 | `.brain/STATE.md` exists but is malformed | Exit 1 with advisory: "Brain STATE.md unreadable — run /brain:health for diagnosis." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| SessionStart in healthy brain | `{"verdict": "allow", "message": "Brain health: GREEN..."}` ; exit 0 | happy-path |
| SessionStart in brain with RED wiki dimension | `{"verdict": "advise", ...}` ; exit 1 | edge-case |
| SessionStart outside a brain directory | No output; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | GREEN brain → exit 0 | bats hooks.bats |
| VP-TBD | RED dimension → exit 1 (never 2) | bats hooks.bats |
| VP-TBD | Non-brain directory → exit 0 silently | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#1 `brain-health-check.sh`) and §Scope §Additional v0.x deliverables ("Six-dimensional convergence tracking... User-visible via `/brain:health` and SessionStart hook banner"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#1); §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.01.006 — related to (/brain:health skill surfaces the same dimensions)
