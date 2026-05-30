# AC-007 through AC-011: Exit-Code Contract (BC-2.12.002)

BC: BC-2.12.002 — `bin/lobster-run` exits 0 (all succeed), 1 (advisory), 2 (any step blocks)
Script: `plugins/brain-factory/bin/lobster-run`
Test file: `plugins/brain-factory/tests/integration.bats`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-007 | All steps exit 0 → lobster exits 0 |
| AC-008 | Any step exits 1, none exit 2 → lobster exits 1; pipeline continues through all steps |
| AC-009 | Any step exits 2 → lobster exits 2 immediately; subsequent steps skipped |
| AC-010 | Pure bash; shebang `#!/usr/bin/env bash`; `set -euo pipefail` in first 10 lines |
| AC-011 | `--dry-run` prints topological order to stdout; identical output on repeated runs (VP-007) |

## Evidence

### AC-007: All steps exit 0 → lobster exits 0

```
ok 36 BC_2_12_002: lobster-run all steps exit 0 → lobster exits 0
```
Test 36: mock workflow with 3 steps all exiting 0 → asserts `[ "$status" -eq 0 ]`.
Functional demo confirms: linear-dag with stub skill (exit 0 each) → lobster exits 0,
`steps_run: 3`, `steps_skipped: 0`.

### AC-008: Step exits 1, none exit 2 → lobster exits 1, all steps ran

```
ok 37 BC_2_12_002: lobster-run one step exits 1 and none exit 2 → lobster exits 1 all steps ran
```
Test 37: step B in a 3-step workflow exits 1; no step exits 2.
Assertions:
1. `[ "$status" -eq 1 ]` — lobster exits 1 (not 0, not 2)
2. All 3 steps appear in the JSONL log (pipeline did not stop at the advisory step)

This is the "continue on advisory" contract: a single exit-1 step does not halt
subsequent steps.

### AC-009: Step exits 2 → lobster exits 2 immediately, remaining steps skipped

```
ok 38 BC_2_12_002: lobster-run one step exits 2 → lobster exits 2 and skips remaining steps
```
Test 38: step B in a 3-step workflow exits 2.
Assertions:
1. `[ "$status" -eq 2 ]` — lobster exits 2
2. Step C does NOT appear in the JSONL log (it was not executed)

The "stop-on-block" invariant is load-bearing: the JSONL log absence of step C is
checked by reading the log file and asserting step C's `step_id` does not appear.

### AC-010: Pure bash, shebang, set -euo pipefail

Shebang: `#!/usr/bin/env bash` (line 1)
`set -euo pipefail` present within first 10 lines (confirmed line 2)

```
ok 39 BC_2_12_001: lobster-run is pure bash — no node/python/ruby calls in the script itself
ok 48 BC_2_12_001: bin/lobster-run passes shellcheck
ok 49 BC_2_12_001: bin/lobster-run passes shfmt normalization
```

### AC-011: --dry-run determinism (VP-007)

```
ok 35 BC_2_12_001: lobster-run --dry-run same workflow twice produces identical output (VP-007)
```
Test 35: runs `bin/lobster-run --dry-run tests/fixtures/linear-dag.yaml` twice,
captures both stdout outputs, asserts `[ "$run1" = "$run2" ]`.

Functional demo confirms identical output on both runs (same step IDs, same format,
same skill invocation paths).

## Exit-code semantics mapping

| Step verdict | JSONL `verdict` field | Lobster exits |
|---|---|---|
| exit 0 | `allow` | 0 (if all allow) |
| exit 1 | `advisory` | 1 (if at least one advisory, no block) |
| exit 2 | `block` | 2 (immediately) |

The `verdict` field in the step JSONL log matches the exit code semantics, providing
operator-readable audit trail per BC-2.12.001 postcondition 1.
