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
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.04.016: Every hook reads JSON from stdin, writes JSON verdict to stdout, exits 0/1/2 only

## Description

This BC defines the universal hook I/O contract that applies to all 13 bash hooks in brain-factory. The contract is what makes hooks dispatcher-ready (KD-003): the same JSON stdin / JSON stdout / exit-code-0/1/2 protocol will be preserved when hooks are ported to WASM in v1.0. Every hook implementation must conform to this contract — no exceptions. This BC is the foundation that all other hook BCs build on.

## Preconditions

1. The hook script is named per the 13-hook roster from brief §Scope §13 bash hooks.
2. The hook script begins with `#!/usr/bin/env bash` and `set -euo pipefail` (within first 10 lines).
3. The Claude Code harness fires the hook via the registered event type (PreToolUse, PostToolUse, SessionStart, or Stop).
4. The harness provides a JSON payload on stdin.

## Postconditions

1. The hook reads the full stdin payload as JSON (using `jq` — never raw `read` or string manipulation).
2. The hook writes exactly one JSON object to stdout before exiting. Stdout is a single JSON line: `{"verdict": "allow|advise|block", ...}` for PreToolUse/PostToolUse hooks, or a structured response appropriate to the hook type.
3. The hook exits with exactly one of: `0` (success — no action required), `1` (advisory — log and continue), `2` (block — abort the triggering operation).
4. The hook never writes non-JSON content to stdout.
5. Structured events are written to stderr (JSONL format per BC-2.04.017), NOT to stdout.

## Invariants

1. No hook uses bare `exit` without an explicit numeric code (`exit 0`, `exit 1`, or `exit 2` only).
2. No hook uses `eval`.
3. All variable expansions are quoted (`"$var"`, not `$var`).
4. If `jq` fails to parse stdin, the hook exits 2 (fail-closed) with a structured error on stdout: `{"verdict": "block", "code": "E-HOOK-001", "message": "Failed to parse stdin as JSON.", "trace": "<uuid>"}`.
5. No hook silently swallows errors and exits 0. Error = block (exit 2) by default.
6. All template path references use `${CLAUDE_PLUGIN_ROOT}/...` — never hardcoded paths.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | stdin is empty | Hook exits 2 with E-HOOK-001 (empty stdin is not valid JSON). |
| EC-002 | stdin contains malformed JSON | Hook exits 2 with E-HOOK-001. |
| EC-003 | Hook encounters an unexpected error mid-execution | Hook traps the error, emits structured error to stdout, exits 2. |
| EC-004 | Hook runs with `set -euo pipefail` and a subcommand fails | Trap fires (or `set -e` exits the script), hook emits structured error, exits 2. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `{}` (valid JSON) on stdin to any hook | Hook parses successfully; runs its logic; exits 0 or 1 or 2 depending on content | happy-path |
| `""` (empty string) on stdin | `{"verdict": "block", "code": "E-HOOK-001", ...}`; exit 2 | error |
| `not-json` on stdin | `{"verdict": "block", "code": "E-HOOK-001", ...}`; exit 2 | error |
| Valid payload causing advisory | `{"verdict": "advise", ...}`; exit 1 | happy-path |
| Valid payload causing block | `{"verdict": "block", ...}`; exit 2 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-001 | All 13 hooks exit 0/1/2 only — no other exit codes | bats hooks.bats assertion + shellcheck |
| VP-001 | No bare `exit` statement in any hook | shellcheck + grep assertion |
| VP-001 | No `eval` in any hook | grep assertion + meta-lint.bats |
| VP-001 | Empty stdin → exit 2 for all hooks | bats hooks.bats assertion (parameterized) |
| VP-001 | stdout is valid JSON for all exit codes | bats assertion (`jq empty` on stdout capture) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Constraints §Technical ("Hook contract: `#!/usr/bin/env bash` + `set -euo pipefail`. Reads JSON on stdin; writes JSON verdict on stdout; exits 0 (ok), 1 (advisory), 2 (block). Never bare `exit`. Never `eval`."). This BC defines the universal hook I/O contract shared by all 13 hooks. |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Constraints §Technical; §Scope §13 bash hooks; CLAUDE.md §Bash hook contract |

## Related BCs

- BC-2.04.001 through BC-2.04.014 — all hooks compose with this contract
- BC-2.04.015 — related to (performance budget applies to hooks conforming to this contract)
- BC-2.04.017 — composes with (stderr event emission protocol)
- BC-2.18.002 — depends on (meta-lint validates this contract on all hooks)

## Architecture Anchors

- `architecture/subsystems/SS-04-hook-enforcement-chain.md`

## Story Anchor

[S-TBD]

## VP Anchors

- VP-001 — Hook exit-code semantics coverage (bats hooks.bats)
