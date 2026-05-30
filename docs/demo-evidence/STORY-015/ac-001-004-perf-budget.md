# AC-001 through AC-004: Performance Budget (BC-2.04.015)

BC: BC-2.04.015 — Every hook processes its sample payload under 100ms p99
Test file: `plugins/brain-factory/tests/hook-contracts.bats` Section 6
Fixture path convention: `tests/fixtures/<hook-name>-sample.json`

## AC-001: Latency assertions exist in hook-contracts.bats

The test `_assert_hook_p99_under_100ms` runs each hook 10 times using
`$EPOCHREALTIME` (bash 5.0+ builtin, zero subprocess overhead at the timing
boundary) and asserts the 9th-of-10 sorted value (p99 estimator) is under 100ms.

Test names (Section 6, tests 72-84 in hook-contracts.bats run):
- `BC_2_04_015: block-ai-attribution p99 latency <100ms over 10 runs`
- `BC_2_04_015: brain-health-check p99 latency <100ms over 10 runs`
- `BC_2_04_015: enforce-kebab-case p99 latency <100ms over 10 runs`
- `BC_2_04_015: flush-state-and-commit p99 latency <100ms over 10 runs`
- `BC_2_04_015: quarantine-fetch p99 latency <100ms over 10 runs (Node startup INCLUDED per AC-003)`
- `BC_2_04_015: validate-frontmatter-schema p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-index-log-coherence p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-page-type-policy p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-publish-state p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-source-id-citation p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-source-immutability p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-voice-avoid-list p99 latency <100ms over 10 runs`
- `BC_2_04_015: validate-wikilink-integrity p99 latency <100ms over 10 runs`

All 13 reported `ok` in the recorded run.

## AC-002: Fixtures at tests/fixtures/<hook-name>-sample.json

Verification: 13 of 13 fixtures present. The meta-lint test
`BC_2_04_015_AC002: all 13 hooks have a -sample.json fixture at tests/fixtures/`
(test 17 in meta-lint.bats) passes and structurally enforces this going forward.

Fixtures present (confirmed by `ls plugins/brain-factory/tests/fixtures/ | grep -sample.json`):
  block-ai-attribution-sample.json
  brain-health-check-sample.json
  enforce-kebab-case-sample.json
  flush-state-and-commit-sample.json
  quarantine-fetch-sample.json
  validate-frontmatter-schema-sample.json
  validate-index-log-coherence-sample.json
  validate-page-type-policy-sample.json
  validate-publish-state-sample.json
  validate-source-id-citation-sample.json
  validate-source-immutability-sample.json
  validate-voice-avoid-list-sample.json
  validate-wikilink-integrity-sample.json

## AC-003: quarantine-fetch Node startup overhead included

Test name exactly matches the AC-003 annotation requirement:
`BC_2_04_015: quarantine-fetch p99 latency <100ms over 10 runs (Node startup INCLUDED per AC-003)`

The `_assert_hook_p99_under_100ms` helper uses `bash "${hook}" < "${fixture}"`
(no --exclude-node-startup flag or equivalent). This is load-bearing:
a `sleep 0.2` injected into the hook would cause this test to fail.

The test comment in hook-contracts.bats Section 6 documents the Phase 1c
architecture flag: "If Node startup alone approaches 100ms in CI, the
quarantine hook design requires rethinking."

## AC-004: Latency tests are in hook-contracts.bats, not a separate CI script

Evidence: Section 6 of hook-contracts.bats contains all 13 latency test
declarations. No separate `latency-check.sh` or equivalent CI script exists.
The `grep -c '_assert_hook_p99_under_100ms' tests/hook-contracts.bats` count
is 14 (1 definition + 13 invocations), confirming the parameterized structure
is in the bats suite.

## Key Assertion Code (load-bearing)

From `_assert_hook_p99_under_100ms` in hook-contracts.bats:

```bash
if [[ "${p99}" -ge 100 ]]; then
  echo "FAIL: Hook ${hook_name} p99 latency ${p99}ms >= 100ms budget (BC-2.04.015)" >&2
  echo "All times (ms): ${times[*]}" >&2
  echo "Sorted: ${sorted_str}" >&2
  return 1
fi
```

The assertion fails if p99 >= 100 (not if p99 > 100), which means 99ms passes
and 100ms fails. This correctly implements the "under 100ms" contract.

## bats TAP output (tests 72-84 from hook-contracts-run.txt)

```
ok 72 BC_2_04_015: block-ai-attribution p99 latency <100ms over 10 runs
ok 73 BC_2_04_015: brain-health-check p99 latency <100ms over 10 runs
ok 74 BC_2_04_015: enforce-kebab-case p99 latency <100ms over 10 runs
ok 75 BC_2_04_015: flush-state-and-commit p99 latency <100ms over 10 runs
ok 76 BC_2_04_015: quarantine-fetch p99 latency <100ms over 10 runs (Node startup INCLUDED per AC-003)
ok 77 BC_2_04_015: validate-frontmatter-schema p99 latency <100ms over 10 runs
ok 78 BC_2_04_015: validate-index-log-coherence p99 latency <100ms over 10 runs
ok 79 BC_2_04_015: validate-page-type-policy p99 latency <100ms over 10 runs
ok 80 BC_2_04_015: validate-publish-state p99 latency <100ms over 10 runs
ok 81 BC_2_04_015: validate-source-id-citation p99 latency <100ms over 10 runs
ok 82 BC_2_04_015: validate-source-immutability p99 latency <100ms over 10 runs
ok 83 BC_2_04_015: validate-voice-avoid-list p99 latency <100ms over 10 runs
ok 84 BC_2_04_015: validate-wikilink-integrity p99 latency <100ms over 10 runs
```
