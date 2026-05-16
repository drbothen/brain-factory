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

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Hook execution (any) | `jq empty <stdout>` succeeds; stderr has JSONL | happy-path |
| Hook error path | `jq empty <stdout>` succeeds (error verdict JSON); stderr has error event | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | stdout is always valid single JSON | bats hooks.bats (capture stdout; jq empty) |
| VP-TBD | stderr contains JSONL (not verdict) | bats hooks.bats (capture stderr; validate format) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-017 ("Structured Event Catalog") per brief CLAUDE.md §Logging ("No `echo "..."` for user-facing output from hooks — hooks emit JSON on stdout, structured events on stderr."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Logging |

## Related BCs

- BC-2.04.016 — composes with (I/O contract)
- BC-2.04.017 — composes with (emission protocol)
