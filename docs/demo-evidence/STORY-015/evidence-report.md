# Evidence Report — STORY-015
# Hook contract meta-lint expansion

story_id: STORY-015
branch: feature/STORY-015
head: 37a39b4
recorded: 2026-05-30
toolchain: bats 1.10+, shellcheck 0.10+, shfmt 3.7+

## Summary

All 15 acceptance criteria for STORY-015 are satisfied by the current
implementation. Evidence was captured by re-running all bats suites and
lint tools against the worktree at HEAD 37a39b4.

Test execution results:
- `hook-contracts.bats`: 88 tests, 88 passed, 0 failed, 1 skip (documented)
- `hook-event-emit.bats`: 26 tests, 25 passed, 0 failed, 1 skip (documented)
- `meta-lint.bats`: 21 tests, 21 passed, 0 failed
- `shellcheck`: 0 warnings (clean)
- `shfmt -d`: 0 diffs (clean)

## AC to Evidence Mapping

| AC | BC | Description | Evidence File | Status |
|----|----|-------------|---------------|--------|
| AC-001 | BC-2.04.015 | p99 latency < 100ms over 10 runs, all 13 hooks | ac-001-004-perf-budget.md | PASS |
| AC-002 | BC-2.04.015 | 13 `tests/fixtures/<hook>-sample.json` files exist | ac-001-004-perf-budget.md | PASS |
| AC-003 | BC-2.04.015 | quarantine-fetch Node startup included in budget | ac-001-004-perf-budget.md | PASS |
| AC-004 | BC-2.04.015 | Latency tests live in hook-contracts.bats, not a separate script | ac-001-004-perf-budget.md | PASS |
| AC-005 | BC-2.04.016 | All 13 hooks have shebang line 1 + set -euo pipefail in first 10 lines | ac-005-007-canonical-io.md | PASS |
| AC-006 | BC-2.04.016 | No bare `exit` in any hook (every exit is exit 0/1/2) | ac-005-007-canonical-io.md | PASS |
| AC-007 | BC-2.04.016 | No `eval` in any hook | ac-005-007-canonical-io.md | PASS |
| AC-008 | BC-2.04.016 | Fail-closed: empty stdin exits 2 + E-HOOK-001 (10 hooks); advisory-only hooks skipped | ac-008-009-empty-stdin-happy-path.md | PASS |
| AC-009 | BC-2.04.016 | Happy-path fixture stdout is valid JSON for all 13 hooks | ac-008-009-empty-stdin-happy-path.md | PASS |
| AC-010 | BC-2.17.003 | No bare echo/printf to stdout in any hook | ac-010-012-stream-separation.md | PASS |
| AC-011 | BC-2.17.003 | stderr has >= 1 JSONL line per invocation for all 13 hooks | ac-010-012-stream-separation.md | PASS |
| AC-012 | BC-2.17.003 | stdout is exactly one JSON object per invocation | ac-010-012-stream-separation.md | PASS |
| AC-013 | BC-2.17.004 | No credential variable refs in emit_event/emit_verdict calls | ac-013-014-credential-leakage.md | PASS |
| AC-014 | BC-2.17.004 | Sentinel injection — credential value absent from stdout + stderr | ac-013-014-credential-leakage.md | PASS |
| AC-015 | CLAUDE.md | shellcheck exits 0; shfmt -d produces no diff | ac-015-lint-clean.md | PASS |

## Raw Output Files

| File | Contents |
|------|----------|
| `raw-output/hook-contracts-run.txt` | Full 88-test bats run of hook-contracts.bats |
| `raw-output/hook-event-emit-run.txt` | Full 26-test bats run of hook-event-emit.bats |
| `raw-output/meta-lint-run.txt` | Full 21-test bats run of meta-lint.bats |
| `raw-output/shellcheck-run.txt` | shellcheck + shfmt output (zero violations) |

## Skip Documentation

One bats skip is recorded in hook-event-emit.bats and one in hook-contracts.bats.
Both are properly annotated per STORY-015 AC-008 requirements.

hook-event-emit.bats test 17:
  `F_PASS01_I01: _json_get_str key with backslash-escaped quote in value`
  Skip rationale: Deferred to v1.0 WASM dispatcher migration — pure-bash JSON
  parsing in v0.x explicitly does not handle embedded escaped quotes. The
  limitation is documented in the function's own contract comment. This is a
  scope-boundary defer with an explicit future-version anchor, not a defer-pattern
  per Canonical Principle Rule 3.

hook-event-emit.bats test 18:
  `F_PASS01_I01: _json_get_str key with literal newline escape sequence in value`
  This test actually passes (TAP status: ok); the skip annotation was removed
  in Pass 5.1 because the `\n` literal sequence falls within the stated contract.
  The raw output shows `ok 18` (no skip).

hook-contracts.bats test 10:
  `BC_2_04_016: validate-voice-avoid-list empty stdin exits 2 with JSON on stdout`
  Skip rationale: `validate-voice-avoid-list` is advisory-only. Its empty-stdin
  exit behavior is verified in the per-hook bats suite. The skip uses the exact
  annotation required by AC-008: "advisory-only contract supersedes fail-closed default."
