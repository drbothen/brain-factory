# AC-009: Workflow files read-only at runtime (BC-2.12.003 invariant 3)

**Traces to:** BC-2.12.003 invariant 3
**Status:** PASS

## What is being demonstrated

`bin/lobster-run` must not write to any file in `workflows/` during execution.
Verified by asserting modification timestamps (mtimes) do not change after a dry-run.

## Command sequence

```
# Record mtimes before run
$ stat -f '%m' workflows/*.yaml

brief-to-publish.yaml:  1780200298
daily-ritual.yaml:      1780200302
ingest-source.yaml:     1780200293
ingest-url.yaml:        1780200289
scale-test.yaml:        1780200315
weekly-refresh.yaml:    1780200311

# Execute dry-run
$ env CLAUDE_PLUGIN_ROOT=<tmp> BRAIN_ROOT=<tmp> \
    bin/lobster-run --dry-run workflows/daily-ritual.yaml 2>/dev/null

health-check: node <PLUGIN_ROOT>/scripts/run-skill.mjs brain:brain-health --yes --json
inbox-review: node <PLUGIN_ROOT>/scripts/run-skill.mjs brain:inbox-review --yes
quarantine-check: node <PLUGIN_ROOT>/scripts/run-skill.mjs brain:quarantine-check --yes --json

# Record mtimes after run
$ stat -f '%m' workflows/*.yaml

brief-to-publish.yaml:  1780200298  (unchanged)
daily-ritual.yaml:      1780200302  (unchanged)
ingest-source.yaml:     1780200293  (unchanged)
ingest-url.yaml:        1780200289  (unchanged)
scale-test.yaml:        1780200315  (unchanged)
weekly-refresh.yaml:    1780200311  (unchanged)
```

## Result

All 6 workflow file mtimes are identical before and after dry-run.

PASS — `bin/lobster-run` does not write to `workflows/` during execution.

## Bats test

```
ok 124 BC_2_12_003: workflow files mtime unchanged after dry-run execution (AC-009)
```

## Raw output

`raw-output/ac-009-workflow-read-only.txt`
