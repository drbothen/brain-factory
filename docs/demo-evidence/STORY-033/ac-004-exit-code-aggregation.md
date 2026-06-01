# AC-004: Exit-code aggregation — 0 (all-pass), 1 (advisory), 2 (block) (BC-2.12.004 postcondition 2)

**Traces to:** BC-2.12.004 postcondition 2
**Status:** PASS

## What is being demonstrated

Headless exit code matches the workflow result:
- Exit 0: all steps pass
- Exit 1: at least one advisory, no block
- Exit 2: at least one block

Semantics are identical to interactive mode.

## Commands run (using fixture workflows + mock run-skill.mjs)

Mock: `mock-pass` → exit 0, `mock-advisory` → exit 1, `mock-block` → exit 2

### Scenario 1: all-pass (exit-code-all-pass.yaml)

```
$ env CLAUDE_PLUGIN_ROOT=<tmp> BRAIN_ROOT=<tmp> \
    bin/lobster-run tests/fixtures/exit-code-all-pass.yaml 2>/dev/null
EXIT_CODE: 0
```

PASS — all steps pass → lobster exits 0.

### Scenario 2: advisory (exit-code-advisory.yaml)

```
$ env CLAUDE_PLUGIN_ROOT=<tmp> BRAIN_ROOT=<tmp> \
    bin/lobster-run tests/fixtures/exit-code-advisory.yaml 2>/dev/null
EXIT_CODE: 1
```

PASS — one step exits 1, no blocks → lobster exits 1; pipeline continues through all steps.

### Scenario 3: block (exit-code-block.yaml)

```
$ env CLAUDE_PLUGIN_ROOT=<tmp> BRAIN_ROOT=<tmp> \
    bin/lobster-run tests/fixtures/exit-code-block.yaml 2>/dev/null
EXIT_CODE: 2
```

PASS — step-b exits 2 → lobster exits 2 immediately; step-c is skipped.

## Aggregation summary

| Scenario | Expected | Actual | Result |
|----------|----------|--------|--------|
| all-pass | 0 | 0 | PASS |
| advisory | 1 | 1 | PASS |
| block | 2 | 2 | PASS |

## Bats tests

```
ok 117 BC_2_12_004: lobster-run --headless exit code 0 on all-pass workflow (AC-004/BC-2.12.004)
ok 126 BC_2_12_004: lobster-run --headless all-advisory workflow exits 1 all steps ran (IMPORTANT-2/AC-004)
ok 127 BC_2_12_004: lobster-run --headless blocking workflow exits 2 fail-fast (IMPORTANT-2/AC-004)
```

(Also covered by pre-existing STORY-032 tests 36, 37, 38.)

## Raw output

`raw-output/ac-004-exit-code-aggregation.txt`
