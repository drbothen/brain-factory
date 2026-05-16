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

# Behavioral Contract BC-2.04.013: `flush-state-and-commit.sh` commits brain state on session Stop (exit 0 or advisory)

## Description

`flush-state-and-commit.sh` fires on the Stop event. It commits any uncommitted changes to the brain's git repository, updates `.brain/STATE.md` with the session's convergence state, and cleans up temporary files. This ensures the brain's state is always persisted to git at session end — preventing loss of ingest work if the operator closes Claude Code without explicitly committing.

## Preconditions

1. Stop event fires.
2. The working directory is a valid brain git repository.
3. `git` is available in PATH.

## Postconditions

**On uncommitted changes present:**
1. Hook performs `git add -A` and `git commit -m "brain(auto): flush session state"` (conventional-commit prefix `brain(auto):`).
2. Hook exits 0.
3. stdout: `{"verdict": "allow", "message": "Session state committed: <short-sha>.", "trace": "<uuid>"}`.
4. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "session.state.committed", "hook_name": "flush-state-and-commit.sh", "sha": "<short-sha>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On no uncommitted changes:**
1. Hook exits 0.
2. stdout: `{"verdict": "allow", "message": "No changes to flush.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "session.state.flushed", "hook_name": "flush-state-and-commit.sh", "committed": false}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On git commit failure:**
1. Hook exits 1 (advisory — session closes but operator is warned).
2. stdout: `{"verdict": "advise", "code": "E-FLUSH-001", "message": "Failed to auto-commit brain state. Manual commit required: <git-error>.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "session.state.commit_failed", "hook_name": "flush-state-and-commit.sh", "error": "<git-error>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

## Invariants

1. The auto-commit message always uses the `brain(auto):` conventional-commit prefix.
2. This hook NEVER exits 2 (hard block on Stop would prevent the session from closing — unacceptable UX).
3. The hook does NOT push to remote. Remote sync is operator-controlled.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `git commit` fails due to pre-commit hook failure | Exit 1 with E-FLUSH-001. Session still closes. |
| EC-002 | No git repo in working directory (non-brain directory) | Exit 0 immediately (nothing to flush). |
| EC-003 | `.brain/STATE.md` needs updating | Hook updates STATE.md before the `git add -A` so the state file is included in the auto-commit. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Stop event; brain has uncommitted changes | Auto-commit performed; exit 0 | happy-path |
| Stop event; no uncommitted changes | `{"message": "No changes to flush."}` ; exit 0 | happy-path |
| Stop event; git commit fails | E-FLUSH-001; exit 1 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Auto-commit on Stop with pending changes | bats hooks.bats |
| (no VP — P1) | Never exits 2 (never blocks Stop) | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#12 `flush-state-and-commit.sh`). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#12) |

## Related BCs

- BC-2.04.016 — composes with
