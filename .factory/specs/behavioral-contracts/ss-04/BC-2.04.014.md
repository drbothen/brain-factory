---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
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
2. Working directory is a brain (`.brain/STATE.md` exists) OR is not a brain (in which case the hook exits 0 and emits `brain.health.skipped` per NFR-011).

## Postconditions

**In a valid brain with GREEN overall state:**
1. Hook exits 0.
2. stdout: `{"verdict": "allow", "message": "Brain health: GREEN. <summary>", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "brain.health.checked", "hook_name": "brain-health-check.sh", "overall_state": "GREEN"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**In a valid brain with YELLOW or RED state:**
1. Hook exits 1 (advisory).
2. stdout: `{"verdict": "advise", "code": "E-HEALTH-002", "message": "Brain health: <YELLOW|RED>. <dimension summaries with issues>", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "brain.health.checked", "hook_name": "brain-health-check.sh", "overall_state": "<YELLOW|RED>", "red_dimensions": ["<dim>"]}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**Not in a brain directory (`.brain/STATE.md` absent):**
1. Hook exits 0 (no banner shown — not every session is a brain session).
2. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "brain.health.skipped", "hook_name": "brain-health-check.sh", "reason": "not_a_brain_session", "path": "<cwd>"}` (per BC-2.04.017 universal emission requirement + NFR-011).

## Invariants

1. This hook NEVER exits 2 (a SessionStart block would prevent the session from opening — unacceptable).
2. The banner is concise: one line per RED/YELLOW dimension, showing dimension name and issue summary.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Not in a brain directory | Exit 0; emit `brain.health.skipped` JSONL event to stderr (NFR-011 + BC-2.04.017). |
| EC-002 | `.brain/STATE.md` exists but is malformed | Exit 1 with advisory: "Brain STATE.md unreadable — run /brain:health for diagnosis." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| SessionStart in healthy brain | `{"verdict": "allow", "message": "Brain health: GREEN..."}` ; exit 0 | happy-path |
| SessionStart in brain with RED wiki dimension | `{"verdict": "advise", ...}` ; exit 1 | edge-case |
| SessionStart outside a brain directory | stderr: `{"event_type": "brain.health.skipped", ...}`; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | GREEN brain → exit 0 | bats tests/brain-health-check.bats |
| (no VP — P1) | RED dimension → exit 1 (never 2) | bats tests/brain-health-check.bats |
| (no VP — P1) | Non-brain directory → exit 0 + `brain.health.skipped` event on stderr | bats tests/brain-health-check.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#1 `brain-health-check.sh`) and §Scope §Additional v0.x deliverables ("Six-dimensional convergence tracking... User-visible via `/brain:health` and SessionStart hook banner"). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#1); §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.01.006 — related to (/brain:health skill surfaces the same dimensions)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/brain-health-check.bats` (3 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
