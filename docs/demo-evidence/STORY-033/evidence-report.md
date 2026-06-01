# Evidence Report — STORY-033
# bin/lobster-run headless execution + six workflow YAML files

story_id: STORY-033
branch: feature/STORY-033
source_head: 6ab6871 (feature/STORY-033 HEAD)
develop_head: 00be9ad
recorded: 2026-06-01
toolchain: bats 1.10+, shellcheck 0.10+, shfmt 3.7+, yq 4.x+, node 25.2.1

## Summary

All 9 acceptance criteria for STORY-033 are covered by the current implementation.
Evidence was captured by running bats test suites and functional CLI demos against
the converged code at feature/STORY-033 HEAD (6ab6871).

Test execution results:
- `integration.bats`: 145 tests, 145 passed, 0 failed
  - 14 tests directly trace to STORY-033 BCs (BC-2.12.003, BC-2.12.004) — tests 114–127
  - Pre-existing STORY-032 tests (1–113) all pass: no regressions
- `shellcheck bin/lobster-run`: 0 warnings (PASS)
- `shfmt -d -i 2 bin/lobster-run`: 0 diffs (PASS)
- `node --check scripts/run-skill.mjs`: exit 0 (PASS)
- Functional demos: all 9 ACs captured with real command output

## Deliverables

| File | Description |
|------|-------------|
| `plugins/brain-factory/bin/lobster-run` | Bash workflow runtime — headless flag, no bare read, exit-code aggregation |
| `plugins/brain-factory/scripts/run-skill.mjs` | Node 22+ headless skill runner stub — Node<22 → exit 2 + E-SKILL-002 |
| `plugins/brain-factory/workflows/ingest-url.yaml` | Workflow: URL ingest pipeline (2 steps) |
| `plugins/brain-factory/workflows/ingest-source.yaml` | Workflow: local source ingest (2 steps) |
| `plugins/brain-factory/workflows/brief-to-publish.yaml` | Workflow: brief → write → publish (3 steps) |
| `plugins/brain-factory/workflows/daily-ritual.yaml` | Workflow: daily brain rituals (3 steps) |
| `plugins/brain-factory/workflows/weekly-refresh.yaml` | Workflow: weekly synthesis + connect (4 steps) |
| `plugins/brain-factory/workflows/scale-test.yaml` | Workflow: scale validation corpus (3 steps) |
| `plugins/brain-factory/tests/fixtures/sample-daily-brief.yaml` | VP-022 headless fixture (1 step) |

## AC to Evidence Mapping

| AC | BC | Description | Evidence File | Status |
|----|----|-------------|---------------|--------|
| AC-001 | BC-2.12.004 | `lobster-run --headless <wf> < /dev/null` completes in < 30s without hanging | ac-001-headless-no-hang.md | PASS |
| AC-002 | BC-2.12.004 | No bare `read` calls: `grep -n '^[[:space:]]*read '` returns empty | ac-002-no-bare-read.md | PASS |
| AC-003 | BC-2.12.004 | Stdout clean of interactive prompts during headless execution | ac-003-stdout-clean.md | PASS |
| AC-004 | BC-2.12.004 | Exit-code aggregation: 0 (all-pass), 1 (advisory), 2 (block) | ac-004-exit-code-aggregation.md | PASS |
| AC-005 | BC-2.12.004 | `run-skill.mjs`: node --check exits 0; Node<22 → exit 2 + E-SKILL-002; invoked per step | ac-005-run-skill-mjs.md | PASS |
| AC-006 | BC-2.12.003 | All 6 workflow files exist; exactly 6 `.yaml` files in `workflows/` | ac-006-007-008-workflow-files.md | PASS |
| AC-007 | BC-2.12.003 | All 6 files parse with `yq eval '.'`; required fields: name, description, steps[].{id,skill,args,depends_on} | ac-006-007-008-workflow-files.md | PASS |
| AC-008 | BC-2.12.003 | No `.lobster` files in `workflows/`; `.yaml` extension only | ac-006-007-008-workflow-files.md | PASS |
| AC-009 | BC-2.12.003 | Workflow file mtimes unchanged after dry-run (read-only at runtime) | ac-009-workflow-read-only.md | PASS |

## Raw Output Files

| File | Contents |
|------|----------|
| `raw-output/integration-bats-story-033.txt` | 14 STORY-033 bats tests (ok 114–127); full suite: 145 passed, 0 failed |
| `raw-output/shellcheck-shfmt-lobster-run.txt` | shellcheck + shfmt output for bin/lobster-run (zero violations) |
| `raw-output/ac-001-headless-no-hang.txt` | Headless run with /dev/null stdin — spy output, JSONL events, exit 0, elapsed 0s |
| `raw-output/ac-002-no-bare-read.txt` | grep results confirming no bare read calls |
| `raw-output/ac-003-stdout-clean.txt` | Stdout capture showing no interactive prompt patterns |
| `raw-output/ac-004-exit-code-aggregation.txt` | Three scenarios: all-pass → 0, advisory → 1, block → 2 |
| `raw-output/ac-005-run-skill-mjs.txt` | node --check exit 0; Node<22→exit 2+E-SKILL-002; dry-run invocation per step |
| `raw-output/ac-006-007-008-workflow-files.txt` | ls output; yq schema validation for all 6 files; no .lobster files |
| `raw-output/ac-009-workflow-read-only.txt` | Before/after mtime comparison; all 6 files unchanged after dry-run |
