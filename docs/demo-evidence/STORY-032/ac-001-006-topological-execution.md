# AC-001 through AC-006: Topological Execution (BC-2.12.001)

BC: BC-2.12.001 — `bin/lobster-run` reads workflow YAML and executes steps in dependency order
Script: `plugins/brain-factory/bin/lobster-run`
Test file: `plugins/brain-factory/tests/integration.bats`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-001 | Steps execute in `depends_on` DAG order; `--dry-run` output satisfies topological ordering |
| AC-002 | Skill invocations formatted as `node scripts/run-skill.mjs <skill> <args>` |
| AC-003 | Missing skill → E-LOBSTER-002, exit 2, no further steps |
| AC-004 | Cycle in `depends_on` → E-LOBSTER-001, exit 2, no steps executed |
| AC-005 | Malformed YAML → E-LOBSTER-003, exit 2 |
| AC-006 | Step results written to `.brain/logs/lobster-YYYY-MM-DD.jsonl` with required fields |

## Evidence

### AC-001: Topological order verified by --dry-run

Linear DAG (step-a → step-b → step-c):
```
step-a: node .../run-skill.mjs init
step-b: node .../run-skill.mjs init
step-c: node .../run-skill.mjs init
```
Output order matches dependency order. Exit: 0.

Bats tests:
```
ok 28 BC_2_12_001: lobster-run linear DAG executes steps in dependency order (--dry-run)
ok 29 BC_2_12_001: lobster-run diamond DAG A before B and C, both before D (--dry-run)
```
Test 28: linear 3-step chain — asserts output lines appear in A, B, C order.
Test 29: diamond pattern (A→{B,C}→D) — asserts A before B and C, both before D.

### AC-002: Skill invocation format

```
ok 30 BC_2_12_001: lobster-run --dry-run prints node scripts/run-skill.mjs invocation per step
```
Test 30 asserts output contains the pattern `node .*/run-skill.mjs` for each step.
This is the load-bearing format assertion: any deviation from the `node run-skill.mjs`
invocation convention would cause this test to fail.

### AC-003: Missing skill → E-LOBSTER-002

```
ok 32 BC_2_12_001: lobster-run missing skill emits E-LOBSTER-002 exit 2
```
Test asserts: output contains `E-LOBSTER-002` and exit code is 2.
No subsequent steps execute (stop-on-unknown-skill behavior).

### AC-004: Cycle detection → E-LOBSTER-001

Functional demo:
```json
{"level":"error","code":"E-LOBSTER-001","message":"Steps with unresolved dependencies (cycle present): step-a,step-b.","trace":"..."}
```
Exit: 2. steps_run: 0 (no steps executed).

Bats tests:
```
ok 31 BC_2_12_001: lobster-run cycle in depends_on emits E-LOBSTER-001 exit 2
ok 76 BC_2_12_001: lobster-run cycle message includes cycle member step IDs (C02/S02)
ok 77 BC_2_12_001: lobster-run cycle failure completed event reports steps_skipped = step count (C02/S01)
```

### AC-005: Malformed YAML → E-LOBSTER-003

```
ok 33 BC_2_12_001: lobster-run malformed YAML emits E-LOBSTER-003 exit 2
ok 78 BC_2_12_001: lobster-run malformed YAML error message contains actual yq error detail (I01)
```
Error message includes the actual yq parse error detail, not just the error code.

### AC-006: JSONL step log

```
ok 34 BC_2_12_001: lobster-run writes step results to .brain/logs/lobster-YYYY-MM-DD.jsonl
ok 45 BC_2_12_001: lobster-run step log duration_ms is a non-negative integer (I05)
ok 71 BC_2_12_001: lobster-run JSONL log entries contain ts and trace fields (S04)
```
Test 34: log file created with step result entries.
Test 45: `duration_ms` is a non-negative integer (not null, not negative, not float).
Test 71: `ts` and `trace` fields present in each log entry.

Per the functional demo, each step emits:
```json
{"ts":"...","event_type":"lobster.step.completed","step_id":"step-a","exit_code":0,"verdict":"allow","duration_ms":76}
```
All required fields present per AC-006 + SS-12 §Interfaces Outbound contract.

### AC-010: Pure bash — no Node/Python/Rust in bin/lobster-run itself

```
ok 39 BC_2_12_001: lobster-run is pure bash — no node/python/ruby calls in the script itself
ok 40 BC_2_12_001: bin/lobster-run has no bare 'read' calls (VP-022 prerequisite)
ok 47 BC_2_12_001: bin/lobster-run has no bare 'read' calls (strengthened S04 regex)
```
Test 39: `grep -E '^\s*(node|python|ruby|python3)\b'` on the script — empty result required.
Tests 40 and 47: no bare `read` builtins (VP-022 prerequisite for headless execution).

Shebang line 1: `#!/usr/bin/env bash`. `set -euo pipefail` on line 2.
