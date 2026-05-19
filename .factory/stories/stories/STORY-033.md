---
artifact_type: story
story_id: STORY-033
epic_id: EPIC-07
title: "bin/lobster-run headless execution + six workflow YAML files"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-12]
behavioral_contracts: [BC-2.12.003, BC-2.12.004]
vps: [VP-022]
dependencies: [STORY-032]
blocks: [STORY-034, STORY-035]
inputs:
  - architecture/subsystems/SS-12-lobster-runtime.md
  - behavioral-contracts/ss-12/BC-2.12.003.md
  - behavioral-contracts/ss-12/BC-2.12.004.md
  - architecture/verification-properties/VP-022-lobster-headless-execution.md
input-hash: ""
# BC status: BC-2.12.003 + BC-2.12.004 assigned;
# status=draft per Spec-First Gate S-7.01
# Priority: P0 — headless execution is required for GH Actions; workflow files are P1 but
#   bundled here because they are the primary consumers of bin/lobster-run
# Dependency rationale:
#   STORY-032 delivers bin/lobster-run core (topological sort + exit codes); this story
#   adds the --headless contract and the 6 workflow YAML files that exercise it.
#   Blocks STORY-034 (GH Action templates invoke lobster-run headlessly) and
#   STORY-035 (templates depend on workflow files existing).
# Subsystem anchor: SS-12 owns this story because BC-2.12.003 (workflow files) and
#   BC-2.12.004 (headless execution) are both SS-12 postconditions per ARCH-INDEX.
---

# STORY-033: `bin/lobster-run` headless execution + six workflow YAML files

## Goal

Extend `bin/lobster-run` from STORY-032 with the headless execution guarantee
(no stdin blocking in non-TTY context, required for GitHub Actions) and ship all six
Lobster workflow YAML files in `plugins/brain-factory/workflows/`. Also wire
`scripts/run-skill.mjs` as the headless skill runner invoked by lobster-run in
non-interactive mode.

## User Value

As a brain-factory operator running brain operations via GitHub Actions, I want
`bin/lobster-run workflow.yaml` to execute to completion without ever blocking on
stdin, so that scheduled operations like daily-brief and weekly-refresh run reliably
in a CI runner without human intervention.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.12.003 | Six workflow YAML files ship in `plugins/brain-factory/workflows/` | P1 |
| BC-2.12.004 | `bin/lobster-run` supports headless execution (no interactive prompts) | P0 |

## Acceptance Criteria

### Headless execution (BC-2.12.004)

**AC-001** — `bin/lobster-run <workflow.yaml> < /dev/null` executes to completion (or
workflow-step-failure) within 30 seconds without hanging. The process must not block
waiting for stdin. Verified by bats test with `timeout 30` and `/dev/null` redirect.
(traces to BC-2.12.004 postcondition 1)

**AC-002** — `bin/lobster-run` never contains a bare `read` call (bash builtin) outside
of a `if [ -t 0 ]` TTY-detection guard. Static check: `grep -n '^\s*read ' bin/lobster-run`
returns empty output.
(traces to BC-2.12.004 invariant 1)

**AC-003** — Skill steps invoked by lobster-run in headless mode receive `--yes`
(or equivalent non-interactive flag) from the workflow YAML `args` field. The lobster-run
runtime does not add `--yes` automatically — the workflow YAML is responsible. If a step
would hang on stdin due to missing `--yes`, that is a workflow-authoring error, not a
lobster-run bug. Verified by: stdout contains no interactive-prompt patterns
(`"Press Enter"`, `"[y/N]"`, `"Confirm:"`) during headless execution of a sample workflow.
(traces to BC-2.12.004 invariant 2; edge case EC-001)

**AC-004** — Exit code from headless execution matches the workflow result: 0 (all
steps pass), 1 (any advisory, no block), 2 (any block). Identical semantics to
interactive mode.
(traces to BC-2.12.004 postcondition 2)

**AC-005** — `scripts/run-skill.mjs` exists at `${CLAUDE_PLUGIN_ROOT}/scripts/run-skill.mjs`,
requires Node 20+, and is the entry point lobster-run uses for each skill invocation
(both headless and interactive). The file must be executable and parseable by
`node --check scripts/run-skill.mjs`.
(traces to BC-2.12.004 postcondition 1; SS-12 §Step execution §headless)

### Workflow YAML files (BC-2.12.003)

**AC-006** — All six workflow files exist at `${CLAUDE_PLUGIN_ROOT}/workflows/`:
`ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`,
`weekly-refresh.yaml`, `scale-test.yaml`. No other `.yaml` or `.lobster` files are
present in the `workflows/` directory for v0.1.
(traces to BC-2.12.003 postcondition 1; invariant 1)

**AC-007** — All six workflow files are valid YAML parseable by `yq eval '.' <file>`
without error. Each file contains the required schema fields: `name` (string),
`description` (string), `steps` (array with at least one element). Each step object
contains `id` (string), `skill` (string), `args` (array), `depends_on` (array, may be
empty).
(traces to BC-2.12.003 postcondition 2, 3)

**AC-008** — Workflow files use the `.yaml` extension (not `.lobster`). A bats
meta-lint assertion confirms: `ls ${CLAUDE_PLUGIN_ROOT}/workflows/*.lobster 2>/dev/null`
returns empty output.
(traces to BC-2.12.003 invariant 2; edge case EC-002)

**AC-009** — All six workflow files are read-only at runtime: `bin/lobster-run` does
not write to any file in `workflows/` during execution. Verified by asserting
modification timestamps do not change after a dry-run execution.
(traces to BC-2.12.003 invariant 3)

## Tasks

1. **[stub]** Create `plugins/brain-factory/scripts/run-skill.mjs` with a minimal
   Node 20+ shebang (`#!/usr/bin/env node`) and a stub body that prints the skill name
   and arguments to stdout then exits 0. Add `'use strict';` and check
   `process.versions.node` major >= 20 (exit 1 with error if below 20).

2. **[stub — workflow files]** Create all six workflow YAML files in
   `plugins/brain-factory/workflows/` with correct schema structure (`name`, `description`,
   `steps` array with at least one step). Steps reference real `brain:*` skills from
   EPIC-01–06. Use `--yes` / `--json` flags where applicable to ensure headless safety.

3. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/integration.bats` covering VP-022 and BC-2.12.003/004:
   - `"lobster-run: headless /dev/null stdin — does not hang"` (VP-022 primary)
   - `"lobster-run: no bare read calls (static headless check)"` (VP-022 static)
   - `"lobster-run: stdout clean of interactive prompts during headless run"` (VP-022)
   - `"lobster-run: headless exit code matches workflow result"` (BC-2.12.004)
   - `"lobster-run: all 6 workflow files exist in workflows/"` (BC-2.12.003)
   - `"lobster-run: all 6 workflow files pass yq parse"` (BC-2.12.003 postcondition 2)
   - `"lobster-run: workflow files use .yaml not .lobster extension"` (BC-2.12.003 invariant 2)
   - `"scripts/run-skill.mjs: parseable by node --check"` (BC-2.12.004 postcondition 1)
   - `"scripts/run-skill.mjs: requires Node 20+"` (BC-2.12.004)
   Run bats — confirm all 9 tests fail (Red Gate confirmed).

4. **[impl]** Extend `bin/lobster-run` with headless guarantees:
   - In the step-execution block, verify `! [ -t 0 ]` is not checked in lobster-run
     itself — lobster-run does not gate on TTY; it relies on workflow authoring for
     non-interactive args.
   - Add structured stdout for headless output: only JSONL step summaries to stderr;
     no human-readable prompts to stdout.
   - Add the `--dry-run` path to use `run-skill.mjs` as the execution vehicle
     (when not `--dry-run`, the step executor invokes `node scripts/run-skill.mjs`).

5. **[green]** Run bats for all 9 tests — all pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `lobster-run workflows/daily-ritual.yaml < /dev/null` (30s timeout) | Exits ≤ 2; no hang | happy-path | BC-2.12.004 + VP-022 |
| `grep -n '^\s*read ' bin/lobster-run` | Empty | static | BC-2.12.004 invariant 1 + VP-022 |
| Headless stdout on sample workflow | No `"Press Enter"`, `"[y/N]"`, `"Confirm:"` | static | BC-2.12.004 invariant 2 + VP-022 |
| `ls workflows/` | Exactly 6 `.yaml` files; no `.lobster` files | happy-path | BC-2.12.003 postconditions 1, invariant 2 |
| `yq eval '.' workflows/*.yaml` | All 6 parse without error | happy-path | BC-2.12.003 postcondition 2 |
| `yq eval '.name' workflows/ingest-url.yaml` | Non-empty string | happy-path | BC-2.12.003 postcondition 3 |
| `node --check scripts/run-skill.mjs` | Exit 0 | happy-path | BC-2.12.004 postcondition 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-022 | No stdin blocking in /dev/null context | `tests/integration.bats` |
| VP-022 | No bare `read` calls (static check) | `tests/integration.bats` |
| VP-022 | Stdout contains no interactive prompt text | `tests/integration.bats` |
| VP-022 | Headless exit code: 0/1/2 only | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-12-lobster-runtime.md`:

1. In headless mode (`--headless` flag or non-TTY detection), `bin/lobster-run` invokes
   `node scripts/run-skill.mjs <skill-name> <args>` for each step.

2. The six workflow files are in `plugins/brain-factory/workflows/` using `.yaml`
   extension. The directory path disambiguates from GH Action templates (`.yml` in
   `templates/github-action-templates/`).

3. Workflow files are read-only at runtime. `bin/lobster-run` must not write to
   `workflows/`.

4. Every JSONL event written by lobster-run during step execution must be registered
   in `scripts/event-catalog.json` before PR merges.

**Forbidden dependencies:**
- `bin/lobster-run` must NOT call `read` (bash builtin) without a TTY guard.
- Workflow YAML files must NOT reference `.claude/templates/...` paths; use
  `${CLAUDE_PLUGIN_ROOT}/templates/...` per CLAUDE.md §Conventions.
- `scripts/run-skill.mjs` must NOT be a compiled binary — it is a Node 20+ JS file.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 3.2+ | macOS compat |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `yq` | 4.x+ | Workflow YAML parsing and validation |
| `node` | 20+ | `scripts/run-skill.mjs` runtime (CLAUDE.md §Toolchain) |
| `timeout` | GNU coreutils or macOS | VP-022 headless hang detection |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/scripts/run-skill.mjs` | Create | Node 20+ headless skill runner |
| `plugins/brain-factory/workflows/ingest-url.yaml` | Create | Workflow: URL ingest pipeline |
| `plugins/brain-factory/workflows/ingest-source.yaml` | Create | Workflow: local source ingest |
| `plugins/brain-factory/workflows/brief-to-publish.yaml` | Create | Workflow: brief → write → publish |
| `plugins/brain-factory/workflows/daily-ritual.yaml` | Create | Workflow: daily brain rituals |
| `plugins/brain-factory/workflows/weekly-refresh.yaml` | Create | Workflow: weekly synthesis + connect |
| `plugins/brain-factory/workflows/scale-test.yaml` | Create | Workflow: scale validation corpus |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 9 headless + workflow-file tests |
| `plugins/brain-factory/tests/fixtures/sample-daily-brief.yaml` | Create | VP-022 headless fixture |

Files NOT to modify: `bin/lobster-run` core logic from STORY-032 (only additive changes),
any `.factory/` artifact, `plugin.json`, any hook script.

## Previous Story Intelligence

STORY-032 delivers `bin/lobster-run` with topological sort and exit-code contract.
The `--dry-run` mode from STORY-032 is a prerequisite for the headless regression test
fixture in this story. Verify `--dry-run` works before writing headless tests that
depend on it. The `tests/integration.bats` file created in STORY-032 is extended here;
do not overwrite existing tests.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,000 |
| SS-12 subsystem design | ~900 |
| BC-2.12.003 file | ~700 |
| BC-2.12.004 file | ~700 |
| VP-022 file | ~2,000 |
| STORY-032 bin/lobster-run source (for extension context) | ~2,000 |
| Existing integration.bats from STORY-032 | ~1,500 |
| **Total** | **~11,800** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- GH Action template installation — STORY-034.
- Rate-limit retry handling — STORY-035.
- `scripts/run-skill.mjs` full implementation (scheduling, timeout handling) — this
  story delivers a working stub that passes Node 20+ checks; full robustness is in
  STORY-034 context.

## Anchors

- BC-2.12.003: `behavioral-contracts/ss-12/BC-2.12.003.md`
- BC-2.12.004: `behavioral-contracts/ss-12/BC-2.12.004.md`
- SS-12: `architecture/subsystems/SS-12-lobster-runtime.md`
- VP-022: `architecture/verification-properties/VP-022-lobster-headless-execution.md`
- STORY-032: `stories/stories/STORY-032.md` (bin/lobster-run core — predecessor)
