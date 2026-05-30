# AC-004: E-INGEST-006 Advisory for fewer than 5 wiki pages (BC-2.02.002)

BC: BC-2.02.002 — invariant 1, edge case EC-001
Script: `plugins/brain-factory/scripts/generate-wiki.sh`
Test file: `plugins/brain-factory/tests/skills.bats`

## AC-004 Contract

When the librarian produces fewer than 5 pages, advisory E-INGEST-006 is emitted.
Skill continues (does not block, exit 0). Partial-failure fan-out applies.

## Evidence

Two bats tests directly cover this AC:

```
ok 4 BC_2_02_002: generate-wiki.sh emits E-INGEST-006 advisory when fewer than 5 pages produced (AC-004)
ok 5 BC_2_02_002: generate-wiki.sh exits 0 on short article (E-INGEST-006 is advisory, not blocking) (AC-004)
```

Test 4 asserts: output contains "E-INGEST-006" substring.
Test 5 asserts: `[ "$status" -eq 0 ]` — E-INGEST-006 is advisory, not a block.

Supporting test:
```
ok 6 BC_2_02_002: short-article fixture has fewer than 500 words (AC-004 test vector)
```
This verifies the test vector itself satisfies the < 500-word precondition that drives the
< 5 pages outcome, preventing the fixture from silently growing past the threshold.

## Load-bearing assertion code (from skills.bats)

```bash
output="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
  --brain-dir "$BRAIN_DIR" \
  --source-file "${PLUGIN_DIR}/tests/fixtures/ingest-url-short-article.json" \
  --source-id "short-article" 2>&1 || true)"
[[ "$output" == *"E-INGEST-006"* ]]
```

The `|| true` ensures set -e does not interfere; the `*"E-INGEST-006"*` glob match
is the load-bearing assertion. A generate-wiki.sh that swallowed the error or used
a different error code would fail this test.
