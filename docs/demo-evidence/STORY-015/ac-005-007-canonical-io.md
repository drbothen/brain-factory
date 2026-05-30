# AC-005 through AC-007: Canonical I/O Contract — Static Meta-Lint (BC-2.04.016)

BC: BC-2.04.016 — Every hook reads JSON from stdin, writes JSON verdict to stdout,
exits 0/1/2 only
Test file: `plugins/brain-factory/tests/meta-lint.bats` (STORY-015 static assertions)

## AC-005: shebang on line 1 + set -euo pipefail in first 10 lines

Test name: `BC_2_04_016_AC005: all 13 hooks have shebang on line 1 and set -euo pipefail in first 10 lines`
(test 11 in meta-lint.bats run)

Load-bearing assertion code:

```bash
# Line 1 must be exactly #!/usr/bin/env bash.
local line1
line1="$(head -1 "$sh_file")"
if [ "$line1" != "#!/usr/bin/env bash" ]; then
  echo "SHEBANG FAIL: ${hook_name}.sh line 1 is '${line1}'" >&2
  failed=$((failed + 1))
fi

# set -euo pipefail must appear within first 10 lines.
local found_set
found_set="$(head -10 "$sh_file" | grep -c 'set -euo pipefail' || true)"
if [ "$found_set" -eq 0 ]; then
  echo "SET_E FAIL: ${hook_name}.sh missing 'set -euo pipefail' in first 10 lines" >&2
  failed=$((failed + 1))
fi
```

Result: `ok 11 BC_2_04_016_AC005: all 13 hooks have shebang on line 1 and set -euo pipefail in first 10 lines`

## AC-006: No bare `exit` in any hook

Test name: `BC_2_04_016_AC006: no bare exit in any hook (every exit must be exit 0, 1, or 2)`
(test 12 in meta-lint.bats run)

This assertion uses a two-step count on macOS (where grep -P is unavailable):
1. Count all `\bexit\b` occurrences on non-comment, non-awk, non-echo lines
2. Count valid `\bexit [012]\b` occurrences
3. The difference must be 0

Load-bearing assertion code:

```bash
local total_exit valid_exit
total_exit="$(echo "$code_lines" | grep -cE '\bexit\b' 2>/dev/null || true)"
valid_exit="$(echo "$code_lines" | grep -cE '\bexit [012]\b' 2>/dev/null || true)"
bare_count=$(( total_exit - valid_exit ))
```

Any bare `exit`, `exit $code`, or `exit "$VAR"` will increment `total_exit` without
incrementing `valid_exit`, producing `bare_count > 0` and failing the test.

Result: `ok 12 BC_2_04_016_AC006: no bare exit in any hook (every exit must be exit 0, 1, or 2)`

## AC-007: No `eval` in any hook script

Test name: `BC_2_04_016_AC007: no eval in any hook script`
(test 13 in meta-lint.bats run)

Load-bearing assertion code:

```bash
local eval_count
eval_count="$(grep -v '^\s*#' "$sh_file" | grep -cE '\beval\b' || true)"
if [ "$eval_count" -gt 0 ]; then
  echo "EVAL FAIL: ${hook_name}.sh has ${eval_count} eval usage(s)" >&2
  grep -nE '\beval\b' "$sh_file" | grep -v '^\s*#' >&2 || true
  failed=$((failed + 1))
fi
```

Comment lines are stripped before the grep, so a comment documenting why eval
is forbidden would not trigger a false positive.

Result: `ok 13 BC_2_04_016_AC007: no eval in any hook script`

## bats TAP output (tests 11-13 from meta-lint-run.txt)

```
ok 11 BC_2_04_016_AC005: all 13 hooks have shebang on line 1 and set -euo pipefail in first 10 lines
ok 12 BC_2_04_016_AC006: no bare exit in any hook (every exit must be exit 0, 1, or 2)
ok 13 BC_2_04_016_AC007: no eval in any hook script
```

## Per-hook bats coverage gate (meta-lint test 16)

The meta-lint test `BC_2_04_016: all 13 hooks have a corresponding per-hook bats test file`
(test 16) enforces that each hook has a `.bats` coverage file. This is a structural
enforcement point: adding a new hook without a bats file will fail meta-lint in CI.

```
ok 16 BC_2_04_016: all 13 hooks have a corresponding per-hook bats test file
```
