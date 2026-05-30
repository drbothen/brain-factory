# Evidence Report — STORY-017
# Wiki page generation pipeline, token JSONL logging, and 50K-token chunk warning

story_id: STORY-017
branch: docs/demo-evidence-backfill-wave-4-stories-017-032
source_head: b30dd35 (STORY-017 merge commit, PR #16)
develop_head: 20bedb7
recorded: 2026-05-30
toolchain: bats 1.10+, shellcheck 0.10+, shfmt 3.7+
backfill_reason: demo-recorder step skipped at original delivery; backfilled per Wave 4 Gate 3 finding H01

## Summary

All 15 acceptance criteria for STORY-017 are covered by the current implementation.
Evidence was captured by running bats test suites and lint tools against the merged
code at develop tip (20bedb7), which includes the STORY-017 merge commit b30dd35.

Test execution results:
- `skills.bats`: 19 tests, 19 passed, 0 failed
  - 6 tests directly trace to BC-2.02.002, BC-2.02.003, BC-2.02.005
  - 6 structural Red Gate tests (script existence, shellcheck, shfmt)
  - 3 pre-existing BC-2.06.003 tests not from STORY-017 scope (pass, no regressions)
- `shellcheck`: 0 warnings across all 3 scripts (independently verified, also in bats)
- `shfmt -d -i 2`: 0 diffs across all 3 scripts (independently verified, also in bats)
- Functional demos: check-token-threshold.sh (below/above threshold), log-tokens.sh (happy path + -1 sentinel)

## Deliverables

| File | Description |
|------|-------------|
| `plugins/brain-factory/scripts/generate-wiki.sh` | Wiki page generation orchestrator; partial-failure fan-out envelope |
| `plugins/brain-factory/scripts/log-tokens.sh` | JSONL token record appender |
| `plugins/brain-factory/scripts/check-token-threshold.sh` | 50K-token advisory checker |
| `plugins/brain-factory/tests/fixtures/ingest-url-short-article.json` | Short-article fixture for E-INGEST-006 test |

## AC to Evidence Mapping

| AC | BC | Description | Evidence File | Status |
|----|----|-------------|---------------|--------|
| AC-001 | BC-2.02.002 | `brain:librarian` invoked; 5-15 pages at `wiki/{type}/{slug}.md` | ac-001-003-wiki-page-generation.md | PASS |
| AC-002 | BC-2.02.002 | Each page passes frontmatter + wikilink validation hooks | ac-001-003-wiki-page-generation.md | PASS |
| AC-003 | BC-2.02.002 | `source_ids` frontmatter; wiki/index.md + wiki/log.md updated | ac-001-003-wiki-page-generation.md | PASS |
| AC-004 | BC-2.02.002 | E-INGEST-006 advisory when < 5 pages; skill continues | ac-004-e-ingest-006-advisory.md | PASS |
| AC-005 | BC-2.02.002 | Slug collision → page skipped, skip recorded | ac-001-003-wiki-page-generation.md | PASS |
| AC-006 | BC-2.02.002 | Hook-blocked page → partial failure; skill exits 1 | ac-001-003-wiki-page-generation.md | PASS |
| AC-007 | BC-2.02.003 | JSONL record with all 7 fields on every ingest | ac-007-011-token-jsonl-logging.md | PASS |
| AC-008 | BC-2.02.003 | `.brain/logs/` auto-created when absent | ac-007-011-token-jsonl-logging.md | PASS |
| AC-009 | BC-2.02.003 | Record appended on partial failure; wiki_pages_created = actual | ac-007-011-token-jsonl-logging.md | PASS |
| AC-010 | BC-2.02.003 | Token count -1 sentinel; append never fails | ac-007-011-token-jsonl-logging.md | PASS |
| AC-011 | BC-2.02.003 | Each JSONL line parseable by `jq empty` | ac-007-011-token-jsonl-logging.md | PASS |
| AC-012 | BC-2.02.005 | Advisory emitted with exact wording when estimate > threshold | ac-012-015-token-threshold-warning.md | PASS |
| AC-013 | BC-2.02.005 | Warning advisory only (exit 0); ingest proceeds | ac-012-015-token-threshold-warning.md | PASS |
| AC-014 | BC-2.02.005 | Content <= 50000 triggers no warning (exclusive > boundary) | ac-012-015-token-threshold-warning.md | PASS |
| AC-015 | BC-2.02.005 | Absent policies.yaml key → default 50000 | ac-012-015-token-threshold-warning.md | PASS |

## Raw Output Files

| File | Contents |
|------|----------|
| `raw-output/skills-bats-run.txt` | Full 19-test bats run of skills.bats (includes STORY-017 BCs) |
| `raw-output/shellcheck-shfmt-run.txt` | shellcheck + shfmt output for all 3 scripts (zero violations) |
| `raw-output/log-tokens-demo.txt` | log-tokens.sh happy path and -1 sentinel demos |
| `raw-output/check-token-threshold-demo.txt` | check-token-threshold.sh below-threshold, above-threshold, and default demos |
