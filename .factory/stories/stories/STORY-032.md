---
artifact_type: story
story_id: STORY-032
epic_id: EPIC-07
title: "bin/lobster-run — YAML parsing, topological sort, and exit-code contract"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-12]
behavioral_contracts: [BC-2.12.001, BC-2.12.002]
vps: [VP-007]
dependencies: [STORY-001, STORY-002]
blocks: [STORY-033, STORY-034, STORY-035]
inputs:
  - architecture/subsystems/SS-12-lobster-runtime.md
  - behavioral-contracts/ss-12/BC-2.12.001.md
  - behavioral-contracts/ss-12/BC-2.12.002.md
  - architecture/verification-properties/VP-007-lobster-determinism.md
input-hash: ""
# BC status: BC-2.12.001 + BC-2.12.002 assigned;
# status=draft per Spec-First Gate S-7.01
# Priority: P0 — lobster-run is the foundation all workflow execution depends on
# Dependency rationale:
#   STORY-001 establishes plugin.json manifest (lobster-run checks skill registration).
#   STORY-002 establishes the plugin directory structure (bin/ path).
#   Blocks STORY-033 (headless + workflows), STORY-034 (GH Action templates invoke lobster),
#   STORY-035 (api-retry templates also invoke lobster).
# Subsystem anchor: SS-12 owns this story because bin/lobster-run is the sole SS-12
#   runtime artifact; all BC-2.12.001 and BC-2.12.002 postconditions are SS-12 concerns.
---

# STORY-032: `bin/lobster-run` — YAML parsing, topological sort, and exit-code contract

## Goal

Deliver `bin/lobster-run` as a pure-bash Lobster runtime: reads a workflow YAML file,
resolves step `depends_on` declarations via Kahn's topological sort algorithm, executes
skill steps in dependency order, and exits 0/1/2 per the canonical brain-factory
exit-code contract. Includes `--dry-run` mode for VP-007 determinism testing.

## User Value

As a brain-factory operator, I want to run `bin/lobster-run workflows/ingest-url.yaml`
so that all workflow steps execute in the correct dependency order, with pipeline
stop-on-block semantics, giving me a reliable single-command orchestrator for
multi-step brain operations.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.12.001 | `bin/lobster-run` reads workflow YAML and executes steps in declared dependency order | P0 |
| BC-2.12.002 | `bin/lobster-run` exits 0 (all succeed), 1 (advisory), 2 (any step blocks) | P0 |

## Acceptance Criteria

### Topological execution (BC-2.12.001)

**AC-001** — `bin/lobster-run <workflow.yaml>` parses the `steps:` array; each step
with a non-empty `depends_on:` list executes only after all listed dependency steps
complete successfully. In `--dry-run` mode the output order must satisfy: for every
`depends_on` edge A → B, A appears before B in the output.
(traces to BC-2.12.001 postcondition 1)

**AC-002** — Skill invocations use the brain-factory skill namespace: each step's `skill`
field is invoked as `node scripts/run-skill.mjs <skill-name> <args>` (Node 20+ is
required). In `--dry-run` mode the command is printed but not executed.
(traces to BC-2.12.001 postcondition 2)

**AC-003** — Skills are resolved against the plugin manifest (`plugin.json`) before
execution. When a step references a skill not registered in `plugin.json`, `bin/lobster-run`
exits 2 with `E-LOBSTER-002: "Skill '<name>' not found in plugin manifest."` and does not
execute any further steps.
(traces to BC-2.12.001 precondition 3; edge case EC-002)

**AC-004** — When the workflow YAML contains a `depends_on` cycle (e.g., step-A depends
on step-B and step-B depends on step-A), `bin/lobster-run` exits 2 with
`E-LOBSTER-001: "Circular dependency detected in workflow."` and does not execute any
steps.
(traces to BC-2.12.001 edge case EC-001)

**AC-005** — When the workflow YAML file cannot be parsed (malformed YAML), `bin/lobster-run`
exits 2 with `E-LOBSTER-003: "Invalid workflow YAML: <error>."`.
(traces to BC-2.12.001 edge case EC-003)

**AC-006** — Step results are written to `.brain/logs/lobster-YYYY-MM-DD.jsonl` as one
JSONL line per step with fields: `step_id`, `exit_code`, `verdict` (`allow`/`advisory`/
`block`), `duration_ms`.
(traces to BC-2.12.001 postcondition 1; SS-12 §Interfaces Outbound)

### Exit-code contract (BC-2.12.002)

**AC-007** — When all steps exit 0, `bin/lobster-run` exits 0.
(traces to BC-2.12.002 postcondition 1)

**AC-008** — When at least one step exits 1 and no step exits 2, `bin/lobster-run` exits 1.
The pipeline continues through all remaining steps despite the advisory.
(traces to BC-2.12.002 postcondition 2; invariant 2)

**AC-009** — When any step exits 2, `bin/lobster-run` exits 2 immediately. All subsequent
steps (those not yet started) are skipped — they do NOT run.
(traces to BC-2.12.002 postcondition 3; invariant 1)

**AC-010** — `bin/lobster-run` is a pure-bash interpreter: no Node, no Python, no Rust
invoked by `bin/lobster-run` itself (only by child skill invocations). The shebang is
`#!/usr/bin/env bash`; `set -euo pipefail` is present within the first 10 lines.
(traces to BC-2.12.001 invariant 1)

### VP-007 determinism (VP-007 anchor)

**AC-011** — `bin/lobster-run --dry-run <workflow.yaml>` prints step IDs in topological
execution order to stdout without executing any skills. Running the same workflow twice
produces identical output (determinism assertion per VP-007).
(traces to BC-2.12.001 postcondition 1; VP-007 property statement)

## Tasks

1. **[stub]** Create `plugins/brain-factory/bin/lobster-run` with shebang
   (`#!/usr/bin/env bash`) and `set -euo pipefail`. Add a stub body that reads `$1` as
   the workflow file path and exits 0 unconditionally. Make executable with `chmod +x`.

2. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/integration.bats` covering VP-007 and BC-2.12.001/002:
   - `"lobster-run: linear DAG → executes steps in dependency order (--dry-run)"` (VP-007)
   - `"lobster-run: cycle → E-LOBSTER-001 exit 2"` (BC-2.12.001 EC-001, VP-007)
   - `"lobster-run: same YAML → same ordering on two runs (determinism)"` (VP-007)
   - `"lobster-run: missing skill → E-LOBSTER-002 exit 2"` (BC-2.12.001 EC-002)
   - `"lobster-run: malformed YAML → E-LOBSTER-003 exit 2"` (BC-2.12.001 EC-003)
   - `"lobster-run: all steps exit 0 → lobster exits 0"` (BC-2.12.002 postcondition 1)
   - `"lobster-run: one step exits 1, none exit 2 → lobster exits 1"` (BC-2.12.002 postcondition 2)
   - `"lobster-run: one step exits 2 → lobster exits 2 immediately"` (BC-2.12.002 postcondition 3)
   - `"lobster-run: step JSONL written to .brain/logs/lobster-YYYY-MM-DD.jsonl"` (BC-2.12.001)
   - `"lobster-run: pure bash — no Node/Python/Rust in bin/lobster-run itself"` (BC-2.12.001 invariant 1)
   Run bats — confirm all 10 tests fail (Red Gate confirmed).

3. **[impl]** Implement `bin/lobster-run` core:
   - Parse `$1` as the workflow YAML path. Read with `yq eval` into bash arrays.
   - Validate required fields (`name`, `description`, `steps`). If any missing →
     E-LOBSTER-003; exit 2.
   - Build dependency graph: for each step, record `depends_on` edges.
   - Run Kahn's BFS topological sort: detect cycles → E-LOBSTER-001; exit 2.
   - Check all referenced skills against `plugin.json` (via `jq`). Missing → E-LOBSTER-002; exit 2.
   - In `--dry-run` mode: print step IDs in topological order to stdout; exit 0.
   - In normal mode: execute each step via `node "${CLAUDE_PLUGIN_ROOT}/scripts/run-skill.mjs"
     <skill-name> <args>` in topological order.
   - Capture each step's exit code. Accumulate: if exit 2 → write JSONL log + stop
     immediately + exit 2. If exit 1 → write JSONL log + continue. If exit 0 → write
     JSONL log + continue.
   - After all steps: exit 0 (all passed) or exit 1 (any advisory, none blocked).

4. **[green]** Run bats for all 10 `integration.bats` tests — all pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Linear DAG: A → B → C (`--dry-run`) | Output: A, B, C in order; exit 0 | happy-path | BC-2.12.001 postcondition 1 + VP-007 |
| Diamond DAG: A → {B, C} → D (`--dry-run`) | Output: A before B and C, both before D; exit 0 | happy-path | BC-2.12.001 postcondition 1 |
| Same workflow run twice (`--dry-run`) | Identical output both runs | happy-path | VP-007 determinism |
| Cycle: A depends on B, B depends on A | E-LOBSTER-001; exit 2 | error | BC-2.12.001 EC-001 |
| Missing skill `brain:nonexistent` | E-LOBSTER-002; exit 2 | error | BC-2.12.001 EC-002 |
| Malformed YAML (unclosed bracket) | E-LOBSTER-003; exit 2 | error | BC-2.12.001 EC-003 |
| All steps mock exit 0 | lobster exits 0 | happy-path | BC-2.12.002 postcondition 1 |
| Step B mock exits 1, others exit 0 | lobster exits 1; all steps ran | edge-case | BC-2.12.002 postcondition 2 |
| Step B mock exits 2 | lobster exits 2; step C not executed | error | BC-2.12.002 postcondition 3 + invariant 1 |
| `grep -n '^\s*read ' bin/lobster-run` | Empty output (no bare `read` calls) | static | BC-2.12.001 invariant 1 + VP-022 prerequisite |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-007 | Topological order determinism | `tests/integration.bats` |
| VP-007 | Cycle detection E-LOBSTER-001 | `tests/integration.bats` |
| VP-007 | Step failure stops pipeline | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-12-lobster-runtime.md`:

1. Kahn's algorithm (BFS) on the `depends_on` DAG. Steps with no dependencies execute
   first; subsequent steps execute only after all their dependencies succeed.

2. `bin/lobster-run` is a pure bash interpreter — no Node, no Python, no Rust in the
   runtime itself. Only child skill invocations use Node 20+.

3. Step result envelope written to `.brain/logs/lobster-YYYY-MM-DD.jsonl` per the
   defined schema: `{"step_id": "...", "exit_code": N, "verdict": "...", "duration_ms": N}`.

4. `--dry-run` flag must be supported (required by VP-007 verification mechanism).

5. Every event emitted by `bin/lobster-run` must be registered in
   `scripts/event-catalog.json` before the PR merges (BC-2.04.017 / CLAUDE.md §Conventions).

**Forbidden dependencies:**
- `bin/lobster-run` must NOT `source` or `import` any Node, Python, or compiled binary
  as part of its own execution logic (child `node scripts/run-skill.mjs` calls are allowed).
- `bin/lobster-run` must NOT call `read` (bash builtin) in any code path not gated by
  `if [ -t 0 ]` TTY detection (pre-requisite for VP-022 headless test in STORY-033).
- `bin/lobster-run` must NOT write to `wiki/`, `sources/`, or `briefs/` directly.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 3.2+ | POSIX compat; macOS ships 3.2 |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `yq` | 4.x+ | YAML parsing in bin/lobster-run |
| `jq` | 1.6+ | JSON plugin.json manifest check |
| `node` | 20+ | Invoked by child skill steps (not by lobster-run itself) |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/bin/lobster-run` | Create | Pure-bash Lobster runtime (chmod +x) |
| `plugins/brain-factory/tests/integration.bats` | Create/Modify | Topological sort + exit-code bats suite |
| `plugins/brain-factory/tests/fixtures/linear-dag.yaml` | Create | 3-step linear fixture for VP-007 tests |
| `plugins/brain-factory/tests/fixtures/cycle-dag.yaml` | Create | Cycle fixture for E-LOBSTER-001 test |
| `plugins/brain-factory/scripts/event-catalog.json` | Modify | Register lobster step events |

Files NOT to modify: any existing `.factory/` artifact, `plugin.json`, any hook script,
any prior story file.

## Previous Story Intelligence

N/A — first story in EPIC-07. No prior EPIC-07 story intelligence to carry forward.

STORY-001 establishes `plugin.json` format. The lobster-run skill registration check
must use the same `jq` path as STORY-001 uses for manifest queries. Verify the
`plugin.json` `skills` array key before implementing the skill-lookup.

Note on `scripts/run-skill.mjs`: this is the Node 20+ headless skill runner referenced
in SS-12. It is established by EPIC-07 (this story is the first consumer). If
`scripts/run-skill.mjs` does not yet exist when this story's bats tests run in dry-run
mode, the static check test must assert only the invocation command string, not actual
execution. The integration test that exercises real skill invocation is deferred to
STORY-033.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,500 |
| SS-12 subsystem design | ~900 |
| BC-2.12.001 file | ~800 |
| BC-2.12.002 file | ~500 |
| VP-007 file | ~1,200 |
| Existing integration.bats (for context) | ~1,500 |
| plugin.json fixture context | ~500 |
| **Total** | **~9,900** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `--headless` flag and non-TTY guarantee — STORY-033 (BC-2.12.004).
- Six workflow YAML files — STORY-033 (BC-2.12.003).
- `scripts/run-skill.mjs` implementation — first used here as a stub; full headless
  runner wired in STORY-033.
- GH Action templates — STORY-034.
- Rate-limit retry — STORY-035.

## Anchors

- BC-2.12.001: `behavioral-contracts/ss-12/BC-2.12.001.md`
- BC-2.12.002: `behavioral-contracts/ss-12/BC-2.12.002.md`
- SS-12: `architecture/subsystems/SS-12-lobster-runtime.md`
- VP-007: `architecture/verification-properties/VP-007-lobster-determinism.md`
- STORY-001: `stories/stories/STORY-001.md` (plugin.json manifest — skill registry)
- STORY-002: `stories/stories/STORY-002.md` (bin/ directory structure)
