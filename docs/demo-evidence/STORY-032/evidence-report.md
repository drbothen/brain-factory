# Evidence Report — STORY-032
# bin/lobster-run — YAML parsing, topological sort, and exit-code contract

story_id: STORY-032
branch: docs/demo-evidence-backfill-wave-4-stories-017-032
source_head: d610cf0 (STORY-032 merge commit, PR #17)
develop_head: 20bedb7
recorded: 2026-05-30
toolchain: bats 1.10+, shellcheck 0.10+, shfmt 3.7+, yq 4.x+
backfill_reason: demo-recorder step skipped at original delivery; backfilled per Wave 4 Gate 3 finding H01

## Summary

All 11 acceptance criteria for STORY-032 are covered by the current implementation.
Evidence was captured by running bats test suites and lint tools against the merged
code at develop tip (20bedb7), which includes the STORY-032 merge commit d610cf0.

Test execution results:
- `integration.bats`: 114 total tests, 114 passed, 0 failed
  - 86 tests directly trace to BC-2.12.001 and BC-2.12.002 (STORY-032 BCs)
  - Tests 28-113 all BC_2_12 — comprehensive coverage across adversarial cascade fixes
- `shellcheck`: 0 warnings on bin/lobster-run (independently verified; also in bats test 48)
- `shfmt -d -i 2`: 0 diffs on bin/lobster-run (independently verified; also in bats test 49)
- Functional demos: --dry-run linear DAG, cycle detection E-LOBSTER-001, normal mode all-exit-0

## Deliverables

| File | Description |
|------|-------------|
| `plugins/brain-factory/bin/lobster-run` | Pure-bash Lobster workflow runtime (chmod +x) |
| `plugins/brain-factory/tests/integration.bats` | 86 BC_2_12 tests for STORY-032 (86 of 114 total) |
| `plugins/brain-factory/tests/fixtures/linear-dag.yaml` | 3-step linear fixture for VP-007 tests |
| `plugins/brain-factory/tests/fixtures/cycle-dag.yaml` | Cycle fixture for E-LOBSTER-001 test |

## AC to Evidence Mapping

| AC | BC | Description | Evidence File | Status |
|----|----|-------------|---------------|--------|
| AC-001 | BC-2.12.001 | Steps execute in depends_on topological order; --dry-run output ordered | ac-001-006-topological-execution.md | PASS |
| AC-002 | BC-2.12.001 | Skill invocations as `node scripts/run-skill.mjs <skill> <args>` | ac-001-006-topological-execution.md | PASS |
| AC-003 | BC-2.12.001 | Missing skill → E-LOBSTER-002, exit 2 | ac-001-006-topological-execution.md | PASS |
| AC-004 | BC-2.12.001 | Cycle → E-LOBSTER-001, exit 2, no steps executed | ac-001-006-topological-execution.md | PASS |
| AC-005 | BC-2.12.001 | Malformed YAML → E-LOBSTER-003, exit 2 | ac-001-006-topological-execution.md | PASS |
| AC-006 | BC-2.12.001 | Step results written to `.brain/logs/lobster-YYYY-MM-DD.jsonl` | ac-001-006-topological-execution.md | PASS |
| AC-007 | BC-2.12.002 | All steps exit 0 → lobster exits 0 | ac-007-011-exit-code-contract.md | PASS |
| AC-008 | BC-2.12.002 | Step exits 1, none exit 2 → lobster exits 1; all steps ran | ac-007-011-exit-code-contract.md | PASS |
| AC-009 | BC-2.12.002 | Step exits 2 → lobster exits 2 immediately; remaining skipped | ac-007-011-exit-code-contract.md | PASS |
| AC-010 | BC-2.12.001 | Pure bash; `#!/usr/bin/env bash`; `set -euo pipefail`; no node/python in script body | ac-007-011-exit-code-contract.md | PASS |
| AC-011 | VP-007 | `--dry-run` identical output on two runs (determinism) | ac-007-011-exit-code-contract.md | PASS |

## Raw Output Files

| File | Contents |
|------|----------|
| `raw-output/integration-bats-bc212-run.txt` | Full 86-test BC_2_12 subset of integration.bats (1..114 total, 86 BC_2_12) |
| `raw-output/shellcheck-shfmt-run.txt` | shellcheck + shfmt output for bin/lobster-run (zero violations) |
| `raw-output/lobster-run-demos.txt` | Functional demos: --dry-run linear DAG, cycle E-LOBSTER-001, normal all-exit-0 |

## BC-5.39.001 cascade note

STORY-032 went through multiple adversarial passes (FB8 through FB12 suffixes visible
in test names C01/FB12, H01/FB10, etc.). All adversarial findings were resolved before
merge. The 86 BC_2_12 integration tests represent the full accumulated test suite
across all fix-burst passes — not just the original 10 tests from the story spec.
This exceeds the minimum spec coverage and provides defense-in-depth per BC-5.39.001.
