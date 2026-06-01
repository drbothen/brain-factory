# AC-005: scripts/run-skill.mjs — Node 22+ guard, node --check, lobster-run invocation (BC-2.12.004 postcondition 1)

**Traces to:** BC-2.12.004 postcondition 1, SS-12 §Step execution §headless
**Status:** PASS

## What is being demonstrated

Three checks:
1. `node --check scripts/run-skill.mjs` exits 0 (syntactically valid)
2. Node major < 22 → exit 2 BLOCK + `E-SKILL-002` (not exit 1)
3. `bin/lobster-run` invokes `node scripts/run-skill.mjs` for each step

## Check 1: Syntax validation

```
$ node --check plugins/brain-factory/scripts/run-skill.mjs
(no output — exit 0)
EXIT_CODE: 0
```

PASS — file is syntactically valid Node.js.

Node version on this machine: v25.2.1 (≥ 22, normal execution path).

## Check 2: Node < 22 guard (ESM-wrapper override technique)

The bats test overrides `process.versions.node` to `"20.0.0"` before executing the guard:

```
$ node - <<'NODEOF'
'use strict';
Object.defineProperty(process.versions, 'node', { value: '20.0.0', configurable: true });
const fs = require('fs');
const src = fs.readFileSync('scripts/run-skill.mjs', 'utf8');
eval(src.replace(/^#!.*\n/, ''));
NODEOF

STDERR:
{"level":"error","code":"E-SKILL-002","message":"run-skill.mjs requires Node 22+; found 20.0.0"}
EXIT_CODE: 2
```

PASS — Node 20 < 22 → exit **2** BLOCK + `E-SKILL-002`.
Exit 1 is NOT used (reserved for skill advisory verdicts only — per BC-2.12.004 v1.3).

## Check 3: lobster-run invokes run-skill.mjs per step

```
$ env CLAUDE_PLUGIN_ROOT=<tmp> BRAIN_ROOT=<tmp> \
    bin/lobster-run --dry-run test-workflow.yaml

step-a: node <PLUGIN_ROOT>/scripts/run-skill.mjs mock-pass
step-b: node <PLUGIN_ROOT>/scripts/run-skill.mjs mock-pass --yes
{"event_type":"lobster.run.completed","exit_code":0,"steps_run":2,"steps_skipped":0}
EXIT_CODE: 0
```

PASS — each step shows `node <path>/run-skill.mjs <skill> [args]`.

## Bats tests

```
ok 118 BC_2_12_004: lobster-run --headless invokes node scripts/run-skill.mjs for each step (AC-005 behavioral)
ok 122 BC_2_12_004: scripts/run-skill.mjs parseable by node --check (AC-005 static)
ok 123 BC_2_12_004: scripts/run-skill.mjs rejects Node < 22 with non-zero exit (AC-005 Node22)
ok 125 BC_2_12_004: run-skill.mjs Node<22 preflight exit-2 → lobster-run aggregates to exit 2 (IMPORTANT-1/EC-002)
```

## Raw output

`raw-output/ac-005-run-skill-mjs.txt`
