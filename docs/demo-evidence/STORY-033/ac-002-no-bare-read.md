# AC-002: No bare `read` calls in bin/lobster-run (BC-2.12.004 invariant 1)

**Traces to:** BC-2.12.004 invariant 1, VP-022
**Status:** PASS

## What is being demonstrated

`grep -n '^[[:space:]]*read ' bin/lobster-run` returns empty output — no bare `read`
calls exist outside a TTY-detection guard.

## Commands run

```
$ grep -n '^[[:space:]]*read ' plugins/brain-factory/bin/lobster-run
(no output — exit 1 from grep = no matches found)
```

Strengthened regex (bats S04):
```
$ grep -nE '(^|[[:space:];|&])read([[:space:]]|$)' bin/lobster-run \
    | grep -v '^[0-9]*:[[:space:]]*#'
(no output — PASS)
```

## Result

Both greps return empty output. No `read` call is present anywhere in `bin/lobster-run`.

## Bats test

```
ok 115 BC_2_12_004: lobster-run contains no bare read calls outside TTY guard (AC-002/VP-022)
```

Also covered by the pre-existing STORY-032 test:
```
ok 40 BC_2_12_001: bin/lobster-run has no bare 'read' calls (VP-022 prerequisite)
ok 47 BC_2_12_001: bin/lobster-run has no bare 'read' calls (strengthened S04 regex)
```

## Raw output

`raw-output/ac-002-no-bare-read.txt`
