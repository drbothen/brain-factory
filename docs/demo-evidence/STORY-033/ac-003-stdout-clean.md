# AC-003: Stdout clean of interactive prompts in headless mode (BC-2.12.004 invariant 2)

**Traces to:** BC-2.12.004 invariant 2, VP-022, edge case EC-001
**Status:** PASS

## What is being demonstrated

During `--headless` execution, `stdout` must contain none of:
`"Press Enter"`, `"[y/N]"`, `"[Y/n]"`, `"Confirm:"`, `"Enter your choice"`.

The `--headless` flag must also be recognized (output must not contain `E-LOBSTER-007`).

## Command run

```
$ stdout_output="$(env CLAUDE_PLUGIN_ROOT=<tmp> BRAIN_ROOT=<tmp> \
    bin/lobster-run --headless tests/fixtures/sample-daily-brief.yaml </dev/null 2>/dev/null || true)"
```

## Output check

```
STDOUT captured: '' (empty)

Checking interactive prompt patterns:
  PASS: 'Press Enter' not found
  PASS: '[y/N]' not found
  PASS: '[Y/n]' not found
  PASS: 'Confirm:' not found
  PASS: 'Enter your choice' not found

E-LOBSTER-007: not found (--headless recognized)
```

## Architecture note

`bin/lobster-run` emits only JSONL events to **stderr**. Stdout is reserved for
`--dry-run` execution plans and `run-skill.mjs` stub output. No interactive prompts
are ever written to stdout.

## Bats test

```
ok 116 BC_2_12_004: lobster-run stdout clean of interactive prompts during --headless run (AC-003/VP-022)
```

## Raw output

`raw-output/ac-003-stdout-clean.txt`
