# AC-010 through AC-012: Stream Separation (BC-2.17.003)

BC: BC-2.17.003 — Hooks emit JSONL on stderr; stdout reserved for JSON verdict only
Test files:
- Static: `plugins/brain-factory/tests/meta-lint.bats` (AC-010)
- Runtime: `plugins/brain-factory/tests/hook-contracts.bats` Section 4 (AC-011, AC-012)

## AC-010: No bare echo/printf to stdout in any hook (meta-lint static analysis)

Test name: `BC_2_17_003_AC010: no bare echo/printf to stdout in any hook (must use stderr redirect or emit_verdict)`
(test 14 in meta-lint.bats run)

This is a static analysis check using awk to join backslash-continuation lines
into logical lines before grepping. The assertion blocks any `echo` or `printf`
call that does not have `>&2`, `>>`, `>file`, `emit_verdict`, `jq`, or a
`printf '%s'` pattern (the last form is used for the emit_verdict helper itself).

Load-bearing assertion code:

```bash
local logical_lines
logical_lines="$(awk '
  /\\$/ { line = line substr($0, 1, length($0)-1); next }
  { print line $0; line = "" }
  END { if (line != "") print line }
' "$sh_file" 2>/dev/null || cat "$sh_file")"

local bad_lines
bad_lines="$(echo "$logical_lines" \
  | grep -E '^\s*(echo|printf)\s' \
  | grep -v '^\s*#' \
  | grep -v '>&2' \
  | grep -v '>>' \
  | grep -v '>[^&]' \
  | grep -v 'emit_verdict' \
  | grep -v '^\s*jq' \
  | grep -v "printf '.\?{" \
  | grep -v 'printf '\''%s' \
  || true)"
```

Result: `ok 14 BC_2_17_003_AC010: no bare echo/printf to stdout in any hook (must use stderr redirect or emit_verdict)`

## AC-011: stderr has >= 1 JSONL line per invocation

Test coverage in Section 4 (tests 32-57 in hook-contracts.bats run, odd-numbered):

The `_assert_stderr_jsonl` helper:
1. Captures stderr to a temp file while discarding stdout
2. Asserts `wc -l` >= 1
3. Iterates each non-empty line and asserts `jq -e '.'` succeeds

Load-bearing assertion code:

```bash
local line_count
line_count="$(wc -l <"$stderr_file" | tr -d ' ')"
if [[ "$line_count" -lt 1 ]]; then
  echo "Hook ${hook_name}: stderr has 0 lines (expected >= 1 JSONL per BC-2.17.003)" >&2
  rm -f "$stderr_file"
  return 1
fi

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  if ! echo "$line" | jq -e '.' >/dev/null 2>&1; then
    echo "Hook ${hook_name}: non-JSONL on stderr: ${line}" >&2
    bad_lines=$((bad_lines + 1))
  fi
done <"$stderr_file"
```

## AC-012: stdout is exactly one JSON object per invocation

Test coverage in Section 4 (tests 32-57 in hook-contracts.bats run, even-numbered):

The `_assert_stdout_single_json` helper:
1. Captures stdout to a variable
2. Asserts `jq -e '.'` succeeds
3. Asserts `jq -r 'type'` returns `"object"` (not array, not null)
4. Asserts `grep -c '^'` returns 1 (exactly one line)

The single-line assertion is load-bearing: a hook that emits a status line plus
the JSON verdict would fail this check even if the JSON line itself is valid.

## bats TAP output (tests 32-57 from hook-contracts-run.txt)

```
ok 32 BC_2_17_003: block-ai-attribution stderr has >=1 JSONL on canonical fixture
ok 33 BC_2_17_003: block-ai-attribution stdout is single JSON object on canonical fixture
ok 34 BC_2_17_003: brain-health-check stderr has >=1 JSONL on canonical fixture
ok 35 BC_2_17_003: brain-health-check stdout is single JSON object on canonical fixture
ok 36 BC_2_17_003: enforce-kebab-case stderr has >=1 JSONL on canonical fixture
ok 37 BC_2_17_003: enforce-kebab-case stdout is single JSON object on canonical fixture
ok 38 BC_2_17_003: flush-state-and-commit stderr has >=1 JSONL on canonical fixture
ok 39 BC_2_17_003: flush-state-and-commit stdout is single JSON object on canonical fixture
ok 40 BC_2_17_003: quarantine-fetch stderr has >=1 JSONL on canonical fixture
ok 41 BC_2_17_003: quarantine-fetch stdout is single JSON object on canonical fixture
ok 42 BC_2_17_003: validate-frontmatter-schema stderr has >=1 JSONL on canonical fixture
ok 43 BC_2_17_003: validate-frontmatter-schema stdout is single JSON object on canonical fixture
ok 44 BC_2_17_003: validate-index-log-coherence stderr has >=1 JSONL on canonical fixture
ok 45 BC_2_17_003: validate-index-log-coherence stdout is single JSON object on canonical fixture
ok 46 BC_2_17_003: validate-page-type-policy stderr has >=1 JSONL on canonical fixture
ok 47 BC_2_17_003: validate-page-type-policy stdout is single JSON object on canonical fixture
ok 48 BC_2_17_003: validate-publish-state stderr has >=1 JSONL on canonical fixture
ok 49 BC_2_17_003: validate-publish-state stdout is single JSON object on canonical fixture
ok 50 BC_2_17_003: validate-source-id-citation stderr has >=1 JSONL on canonical fixture
ok 51 BC_2_17_003: validate-source-id-citation stdout is single JSON object on canonical fixture
ok 52 BC_2_17_003: validate-source-immutability stderr has >=1 JSONL on canonical fixture
ok 53 BC_2_17_003: validate-source-immutability stdout is single JSON object on canonical fixture
ok 54 BC_2_17_003: validate-voice-avoid-list stderr has >=1 JSONL on canonical fixture
ok 55 BC_2_17_003: validate-voice-avoid-list stdout is single JSON object on canonical fixture
ok 56 BC_2_17_003: validate-wikilink-integrity stderr has >=1 JSONL on canonical fixture
ok 57 BC_2_17_003: validate-wikilink-integrity stdout is single JSON object on canonical fixture
```
