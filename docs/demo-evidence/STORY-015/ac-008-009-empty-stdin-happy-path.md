# AC-008 and AC-009: Empty Stdin + Happy Path — Runtime Contract (BC-2.04.016)

BC: BC-2.04.016 — Every hook reads JSON from stdin, writes JSON verdict to stdout,
exits 0/1/2 only
Test file: `plugins/brain-factory/tests/hook-contracts.bats` Sections 1, 2, 3

## AC-008: Fail-closed hooks exit 2 + E-HOOK-001 on empty stdin

Test coverage in Section 1 (tests 1-13 in hook-contracts.bats run):

Fail-closed hooks (10): each has an individual `@test` asserting:
  1. Exit code is 2 (first `run` call — `[ "$status" -eq 2 ]`)
  2. stdout is valid JSON (`jq -e '.'`)
  3. stdout `.code == "E-HOOK-001"` (`jq -e '.code == "E-HOOK-001"'`)

Advisory-only hooks (3): handled as follows:
- `validate-voice-avoid-list`: explicit `skip` with annotation
  "advisory-only contract supersedes fail-closed default" (test 10 — ok/skip)
- `brain-health-check`: separate test asserting advisory exit 0 + valid JSON stdout (test 12)
- `flush-state-and-commit`: separate test asserting advisory exit 0 + valid JSON stdout (test 13)

Load-bearing assertion pattern (from block-ai-attribution as representative):

```bash
run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
[ "$status" -eq 2 ]
run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
echo "$output" | jq -e '.' >/dev/null
echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
```

The two-`run` pattern (first captures exit code, second captures stdout for JSON
validation) is required because bats `run` captures both stdout and status
together but `jq` parsing on `$output` only makes sense when stderr is suppressed.

## AC-009: Happy-path fixture stdout is valid JSON

Test coverage in Section 2 (tests 14-26 in hook-contracts.bats run):

Each of the 13 hooks has a test asserting that the canonical fixture produces
valid JSON stdout. The specific assertion for hooks where the happy-path can be
fully exercised (no external file dependencies) additionally asserts
`.continue == true` per the BC-2.17.003 PC1 strengthening from Pass 4.1.

Hooks where full happy-path requires on-disk fixture infrastructure
(validate-index-log-coherence, validate-publish-state, validate-source-id-citation,
validate-source-immutability) assert `has("continue")` only — still satisfies
AC-009's contract that stdout is valid JSON with correct verdict structure.

## Exit code range check (Section 3, tests 27-31)

A subset of hooks have explicit exit code range tests:
- `BC_2_04_016: block-ai-attribution exit code is in {0,1,2} on canonical fixture`
- `BC_2_04_016: enforce-kebab-case exit code is in {0,1,2} on canonical fixture`
- `BC_2_04_016: quarantine-fetch exit code is in {0,1,2} on canonical fixture`
- `BC_2_04_016: validate-frontmatter-schema exit code is in {0,1,2} on canonical fixture`
- `BC_2_04_016: validate-wikilink-integrity exit code is in {0,1,2} on canonical fixture`

The `_assert_exit_in_range` helper explicitly fails if `status` is not 0, 1, or 2.

## bats TAP output (tests 1-31 from hook-contracts-run.txt)

```
ok 1 BC_2_04_016: block-ai-attribution empty stdin exits 2 with E-HOOK-001 in stdout
ok 2 BC_2_04_016: enforce-kebab-case empty stdin exits 2 with E-HOOK-001 in stdout
ok 3 BC_2_04_016: quarantine-fetch empty stdin exits 2 with E-HOOK-001 in stdout
ok 4 BC_2_04_016: validate-frontmatter-schema empty stdin exits 2 with E-HOOK-001 in stdout
ok 5 BC_2_04_016: validate-index-log-coherence empty stdin exits 2 with E-HOOK-001 in stdout
ok 6 BC_2_04_016: validate-page-type-policy empty stdin exits 2 with E-HOOK-001 in stdout
ok 7 BC_2_04_016: validate-publish-state empty stdin exits 2 with E-HOOK-001 in stdout
ok 8 BC_2_04_016: validate-source-id-citation empty stdin exits 2 with E-HOOK-001 in stdout
ok 9 BC_2_04_016: validate-source-immutability empty stdin exits 2 with E-HOOK-001 in stdout
ok 10 BC_2_04_016: validate-voice-avoid-list empty stdin exits 2 with JSON on stdout # skip validate-voice-avoid-list is advisory-only; empty-stdin exit behavior
ok 11 BC_2_04_016: validate-wikilink-integrity empty stdin exits 2 with E-HOOK-001 in stdout
ok 12 BC_2_04_016: brain-health-check advisory-only hook exits 0 on empty stdin with valid JSON stdout
ok 13 BC_2_04_016: flush-state-and-commit advisory-only hook exits 0 on empty stdin with valid JSON stdout
ok 14 BC_2_04_016: block-ai-attribution canonical fixture stdout is valid JSON
ok 15 BC_2_04_016: brain-health-check canonical fixture stdout is valid JSON
ok 16 BC_2_04_016: enforce-kebab-case canonical fixture stdout is valid JSON
ok 17 BC_2_04_016: flush-state-and-commit canonical fixture stdout is valid JSON
ok 18 BC_2_04_016: quarantine-fetch canonical fixture stdout is valid JSON
ok 19 BC_2_04_016: validate-frontmatter-schema canonical fixture stdout is valid JSON
ok 20 BC_2_04_016: validate-index-log-coherence canonical fixture stdout is valid JSON
ok 21 BC_2_04_016: validate-page-type-policy canonical fixture stdout is valid JSON
ok 22 BC_2_04_016: validate-publish-state canonical fixture stdout is valid JSON
ok 23 BC_2_04_016: validate-source-id-citation canonical fixture stdout is valid JSON
ok 24 BC_2_04_016: validate-source-immutability canonical fixture stdout is valid JSON
ok 25 BC_2_04_016: validate-voice-avoid-list canonical fixture stdout is valid JSON
ok 26 BC_2_04_016: validate-wikilink-integrity canonical fixture stdout is valid JSON
ok 27 BC_2_04_016: block-ai-attribution exit code is in {0,1,2} on canonical fixture
ok 28 BC_2_04_016: enforce-kebab-case exit code is in {0,1,2} on canonical fixture
ok 29 BC_2_04_016: quarantine-fetch exit code is in {0,1,2} on canonical fixture
ok 30 BC_2_04_016: validate-frontmatter-schema exit code is in {0,1,2} on canonical fixture
ok 31 BC_2_04_016: validate-wikilink-integrity exit code is in {0,1,2} on canonical fixture
```
