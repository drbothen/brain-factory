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
capability: "CAP-012"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.12.004: `bin/lobster-run` supports headless execution (no interactive prompts)

## Description

`bin/lobster-run` must run without any interactive prompts — it is designed for GitHub Actions execution where stdin is not a TTY. If any step would normally require user confirmation, the workflow must be designed to skip the confirmation or use a `--yes` flag. `bin/lobster-run` itself does not implement any interactive input mechanism.

## Preconditions

1. `bin/lobster-run` is invoked from a non-interactive shell (GitHub Actions or similar).
2. No step in the workflow reads from stdin.

## Postconditions

1. Workflow executes to completion (or step failure) without blocking on stdin.
2. Exit code reflects the workflow result.

## Invariants

1. `bin/lobster-run` never calls `read` or any interactive input function.
2. Skill steps called by lobster-run must be designed to be non-interactive (use `--yes` flags or explicit argument passing).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A skill step in the workflow normally prompts the user | The skill must be invoked with flags that bypass the prompt (e.g., `--confirm`). If no such flag exists, the skill body must detect non-TTY stdin and default to safe behavior. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `bin/lobster-run workflow.lobster < /dev/null` | Runs to completion without hanging | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | No stdin required for workflow execution | bats integration.bats (redirect stdin to /dev/null) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-012 ("Lobster Runtime") per brief §Success Criteria §v0.1 ship gate ("`bin/lobster-run` executes a sample workflow YAML headlessly") and §Scope §bin/lobster-run. |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Success Criteria §v0.1 ship gate; §Scope §bin/lobster-run |

## Related BCs

- BC-2.12.001 — composes with
