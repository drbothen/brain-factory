# AC-001: Headless no-hang (VP-022 / BC-2.12.004)

**Traces to:** BC-2.12.004 postcondition 1, VP-022
**Status:** PASS

## What is being demonstrated

`bin/lobster-run --headless <workflow.yaml> < /dev/null` must execute to completion (or
workflow-step-failure) within 30 seconds without blocking on stdin.

## Command run

```
env CLAUDE_PLUGIN_ROOT=<tmp-spy-root> BRAIN_ROOT=<tmp-brain> \
  bin/lobster-run --headless tests/fixtures/sample-daily-brief.yaml < /dev/null
```

Fixture: `tests/fixtures/sample-daily-brief.yaml` (1 step: `health-check` using `brain:brain-health --yes --json`).
Spy `run-skill.mjs` exits 0 for all skills.

## Output

```
STDOUT (spy run-skill.mjs):
run-skill.mjs: skill=brain:brain-health args=["--yes","--json"]

STDERR (JSONL):
{"ts":"2026-06-01T05:22:26Z","event_type":"lobster.step.completed","hook_name":"bin/lobster-run","trace":"dc634c72-bc3f-4f5b-b973-eb68107bfb8d","step_id":"health-check","exit_code":0,"verdict":"allow","duration_ms":123}
{"ts":"2026-06-01T05:22:26Z","event_type":"lobster.run.completed","hook_name":"bin/lobster-run","trace":"dc634c72-bc3f-4f5b-b973-eb68107bfb8d","workflow":"sample-daily-brief.yaml","exit_code":0,"steps_run":1,"steps_skipped":0}
```

Exit code: **0** (≤ 2, PASS)
Elapsed: **0s** (well under 30s — no hang)

## Bats test

```
ok 114 BC_2_12_004: lobster-run --headless flag accepted — does not hang with /dev/null stdin (AC-001/VP-022)
```

## Raw output

`raw-output/ac-001-headless-no-hang.txt`
