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
subsystem: "SS-17"
capability: "CAP-017"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.17.003: Hooks emit JSONL on stderr; stdout is reserved for the JSON verdict only

## Description

The stdout/stderr separation is a load-bearing architectural constraint for dispatcher-readiness (KD-003). In v0.x, the Claude Code harness reads the hook's stdout for the verdict. In v1.0, the WASM dispatcher also reads stdout for the verdict. Mixing JSONL events into stdout would corrupt the verdict parsing. stderr is exclusively for structured events; stdout is exclusively for the JSON verdict.

## Preconditions

1. Any hook is executing.

## Postconditions

1. stdout contains exactly one JSON object (the verdict).
2. stderr contains zero or more JSONL event lines.
3. No non-JSON content appears on stdout.
4. No verdict content appears on stderr.

## Invariants

1. This separation holds even on error paths. Error verdicts go to stdout; error events go to stderr.
2. `set -euo pipefail` must not cause any output before the verdict JSON (traps must write to stderr).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A hook crashes mid-execution (e.g., `set -euo pipefail` triggers on an unset variable before the verdict JSON is written to stdout) | The bash `ERR` trap fires; the trap writes the error event to stderr; the hook then writes a `{"ok": false, "verdict": "block", "code": "E-HOOK-001", "message": "..."}` verdict to stdout and exits 2; stdout is never left empty |
| EC-002 | A hook developer adds a debug `echo "DEBUG: entering check"` to stdout during development | `jq empty <stdout>` fails on the combined stdout (debug string + verdict); bats hooks.bats detects the violation; the debug echo must be removed or redirected to stderr before PR merge |
| EC-003 | A hook produces zero JSONL events on stderr (the hook-event:emit helper call is accidentally removed) | bats hooks.bats captures stderr and asserts `wc -l ≥ 1`; the test fails; NFR-011 requires ≥ 1 JSONL event per hook invocation; the missing emit site must be restored |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Hook execution (any) | `jq empty <stdout>` succeeds; stderr has JSONL | happy-path |
| Hook error path | `jq empty <stdout>` succeeds (error verdict JSON); stderr has error event | error |
| Hook with debug echo on stdout | `jq empty <stdout>` fails; bats detects violation | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-026 | stdout is always valid single JSON | bats hooks.bats (capture stdout; jq empty) |
| VP-026 | stderr contains JSONL (not verdict) | bats hooks.bats (capture stderr; validate format) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-017 ("Structured Event Catalog") per brief CLAUDE.md §Logging ("No `echo "..."` for user-facing output from hooks — hooks emit JSON on stdout, structured events on stderr."). |
| Architecture Module | SS-17: Structured Event Catalog |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Logging |

## Related BCs

- BC-2.04.016 — composes with (I/O contract)
- BC-2.04.017 — composes with (emission protocol)
