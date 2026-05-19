---
artifact_type: story
story_id: STORY-003
epic_id: EPIC-01
title: "/brain:init error handling, SLA assertion, and briefs/research/ scaffold"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-01]
behavioral_contracts: [BC-2.01.002, BC-2.01.003, BC-2.01.005]
vps: [VP-014]
dependencies: [STORY-001, STORY-002]
blocks: [STORY-004]
inputs:
  - architecture/subsystems/SS-01-brain-init-scaffold.md
  - behavioral-contracts/ss-01/BC-2.01.002.md
  - behavioral-contracts/ss-01/BC-2.01.003.md
  - behavioral-contracts/ss-01/BC-2.01.005.md
  - architecture/verification-properties/VP-014-brain-init-scaffold.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-003: /brain:init error handling, SLA assertion, and briefs/research/ scaffold

## Goal

Complete the `/brain:init` skill by implementing all error-path handlers
(E-INIT-001 through E-INIT-007), adding the `briefs/research/` directory to the
scaffold, and adding the `assert_under_5_minutes` timer test to `local-dev-test.sh`.
After this story, `/brain:init` is fully production-grade: correct on the happy path
(STORY-002), safe on every error path, and verified to complete within the 5-minute SLA.

## User Value

As an operator running `/brain:init` in the wrong context (no git repo, existing brain,
missing dependencies), I want to receive a clear, actionable error message with the
exact command I need to run — not a silent failure or a partial scaffold that leaves
my directory in an inconsistent state.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.01.002 | `/brain:init` completes end-to-end in under 5 minutes (tested SLA) | P0 |
| BC-2.01.003 | `/brain:init` rejects non-git-repo target directory with E-INIT-001 | P0 |
| BC-2.01.005 | `/brain:init` scaffolds `briefs/research/` subdirectory | P1 |

## Acceptance Criteria

**AC-001** — When invoked in a directory where `git rev-parse --git-dir` exits non-zero,
the skill exits 2 and emits structured JSON:
`{"level":"error","code":"E-INIT-001","message":"brain:init requires a git repository — run \`git init -b main\` first","trace":"<uuid>"}`.
No files are created or modified in the working directory.
(traces to BC-2.01.003 postconditions 1–4; BC-2.01.003 invariant 1)

**AC-002** — When invoked in a directory where `.brain/` already exists, the skill exits
2 and emits:
`{"level":"error","code":"E-INIT-002","message":"brain already initialized at <path>. Use \`/brain:upgrade-brain\` to modify an existing brain.","trace":"<uuid>"}`.
No files are created or overwritten. This is a hard-fail, not idempotent re-scaffold
(SS-01 §Architectural Decisions §Already-initialized brain).
(traces to BC-2.01.003 postconditions 1–4; BC-2.01.003 invariant 2)

**AC-003** — When Node 20+ is not in PATH (`node --version` fails or returns < 20), the
skill exits 2 and emits:
`{"level":"error","code":"E-INIT-003","message":"Node 20+ is required. Install from nodejs.org or via nvm.","trace":"<uuid>"}`.
No files created.
(traces to BC-2.01.001 precondition 4; BC-2.01.003 postconditions 1–4)

**AC-004** — When `${CLAUDE_PLUGIN_ROOT}` does not resolve to a valid directory, the
skill exits 2 and emits:
`{"level":"error","code":"E-INIT-004","message":"Plugin root not found — reinstall brain-factory.","trace":"<uuid>"}`.
No files created.
(traces to BC-2.01.001 precondition 3; BC-2.01.003 postconditions 1–4)

**AC-005** — When a conflicting path exists in the working directory (e.g., a `wiki/`
directory that does not belong to a brain), the skill exits 2 and emits:
`{"level":"error","code":"E-INIT-005","message":"Conflict: <path> already exists. Remove it or init in a clean directory.","trace":"<uuid>"}`.
The conflict check covers at minimum: `wiki/`, `sources/`, `.brain/`.
(traces to BC-2.01.001 edge case EC-005; BC-2.01.003 postconditions 1–4)

**AC-006** — When `jq` or `yq` is absent from PATH, the skill exits 2 and emits:
`{"level":"error","code":"E-INIT-006","message":"jq and yq are required. Install via your package manager.","trace":"<uuid>"}`.
No files created.
(traces to BC-2.01.001 precondition 5; BC-2.01.003 postconditions 1–4)

**AC-007** — When invoked in a bare git repository (`git rev-parse --is-bare-repository`
returns `true`), the skill exits 2 and emits:
`{"level":"error","code":"E-INIT-007","message":"brain:init requires a working-tree repository — bare repos are not supported.","trace":"<uuid>"}`.
No files created.
(traces to BC-2.01.003 edge case EC-002)

**AC-008** — The check order in `run.sh` is: (1) `${CLAUDE_PLUGIN_ROOT}` resolution,
(2) `jq`/`yq` availability, (3) Node 20+ availability, (4) git-repo check (non-git → E-INIT-001),
(5) bare-repo check (E-INIT-007), (6) `.brain/` exists check (E-INIT-002),
(7) conflict check (E-INIT-005). No file writes occur before all checks pass.
(traces to BC-2.01.003 invariant 1)

**AC-009** — `briefs/research/` directory exists and is empty after a successful init
run.
(traces to BC-2.01.005 postconditions 1–2)

**AC-010** — `plugins/brain-factory/tests/local-dev-test.sh` contains an
`assert_under_5_minutes` function that:
(a) Runs `/brain:init` in a fresh temp brain directory.
(b) Measures wall-clock time with `$SECONDS` or `date +%s`.
(c) Asserts `elapsed -lt 300`.
(d) Fails with an explicit message "brain:init took ${elapsed}s, exceeds 5-minute SLA"
if the assertion does not hold.
(traces to BC-2.01.002 postconditions 1–3)

**AC-011** — `tests/integration.bats` contains a `@test "/brain:init: completes under
5 minutes (BC-2.01.002)"` test that passes in CI (GitHub Actions ubuntu-latest runner).
(traces to BC-2.01.002 postcondition 2)

## Tasks

1. **[failing test — Red Gate]** Add to `tests/integration.bats` (from STORY-002):
   - `@test "/brain:init: rejects non-git directory with E-INIT-001"`
   - `@test "/brain:init: rejects existing .brain/ with E-INIT-002 — hard-fail"`
   - `@test "/brain:init: rejects bare git repository with E-INIT-007"`
   - `@test "/brain:init: node not in PATH produces E-INIT-003"`
   - `@test "/brain:init: jq/yq absent produces E-INIT-006"`
   - `@test "/brain:init: conflicting wiki/ produces E-INIT-005"`
   - `@test "/brain:init: briefs/research/ exists after init"`
   - `@test "/brain:init: completes under 5 minutes (BC-2.01.002)"`
   All tests fail because the error-path logic is not yet in `run.sh`.

2. **[impl]** Add the prerequisite check chain to `run.sh` (prepend to happy-path logic
   from STORY-002):

   ```bash
   # Check order: CLAUDE_PLUGIN_ROOT → jq/yq → node → git → bare → .brain → conflicts
   [[ -d "${CLAUDE_PLUGIN_ROOT:-}" ]] || _die E-INIT-004 "Plugin root not found..."
   command -v jq >/dev/null && command -v yq >/dev/null || _die E-INIT-006 "jq and yq..."
   node --version 2>/dev/null | grep -qP '^v(2[0-9]|[3-9]\d)' || _die E-INIT-003 "Node 20+..."
   git rev-parse --git-dir >/dev/null 2>&1 || _die E-INIT-001 "brain:init requires a git..."
   [[ "$(git rev-parse --is-bare-repository)" != "true" ]] || _die E-INIT-007 "bare repos..."
   [[ ! -d "${BRAIN_ROOT:-$PWD}/.brain" ]] || _die E-INIT-002 "brain already initialized..."
   for path in wiki sources; do
     [[ ! -d "${BRAIN_ROOT:-$PWD}/$path" ]] || _die E-INIT-005 "Conflict: $path already exists..."
   done
   ```

   Implement `_die()` helper: emit `{"level":"error","code":"$1","message":"$2","trace":"$(uuidgen || date +%s%N)"}` to stdout; `exit 2`.

3. **[impl]** Add `briefs/research/` to the `mkdir -p` call in `run.sh`'s scaffold
   section (alongside `briefs/daily`, `briefs/weekly`, etc.).

4. **[impl]** Create `plugins/brain-factory/tests/local-dev-test.sh` with the
   `assert_under_5_minutes` function. The script sets up a temp brain, runs init via
   `cd "$brain_dir" && CLAUDE_PLUGIN_ROOT="..." bash "${CLAUDE_PLUGIN_ROOT}/skills/init/run.sh"`,
   measures elapsed time, asserts < 300 seconds, then runs the directory-structure
   assertions from VP-014.

5. **[green]** Run the newly added `tests/integration.bats` error-path tests. All pass.

6. **[green]** Run `bash plugins/brain-factory/tests/local-dev-test.sh` — completes
   without error; `assert_under_5_minutes` passes.

7. **[green]** Run `shellcheck plugins/brain-factory/skills/init/run.sh` and
   `shellcheck plugins/brain-factory/tests/local-dev-test.sh`.

8. **[green]** Run `shfmt -d -i 2 plugins/brain-factory/skills/init/run.sh` — no diff.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Temp dir, no `.git/` | `{"code":"E-INIT-001",...}`; exit 2; no files | error | BC-2.01.003 |
| `/tmp` (definitely not git) | E-INIT-001; exit 2 | error | BC-2.01.003 |
| Dir with `.brain/` already | `{"code":"E-INIT-002",...}`; exit 2; no new files | error | BC-2.01.003 |
| Bare git repo (`git init --bare`) | `{"code":"E-INIT-007",...}`; exit 2 | edge-case | BC-2.01.003 EC-002 |
| `node` absent from PATH | E-INIT-003; exit 2 | error | BC-2.01.001 precondition 4 |
| `jq` absent from PATH | E-INIT-006; exit 2 | error | BC-2.01.001 precondition 5 |
| Dir inside valid git repo (non-bare) | Init proceeds normally | happy-path | BC-2.01.003 EC-001 |
| `ls briefs/` after init | Includes `research/` | happy-path | BC-2.01.005 postcondition 1 |
| `ls briefs/research/` after init | Empty directory | happy-path | BC-2.01.005 postcondition 2 |
| Timer on GitHub Actions ubuntu-latest | elapsed < 300s | performance | BC-2.01.002 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-014 | E-INIT-001 emitted on non-git directory | `tests/integration.bats` |
| VP-014 | No files created on error exit | `tests/integration.bats` file-system assertion |
| VP-014 | Git check is first non-plugin-root check | `tests/integration.bats` + bash trace |
| VP-014 | `assert_under_5_minutes` passes | `tests/local-dev-test.sh` |
| VP-014 | `briefs/research/` exists after init | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-01-brain-init-scaffold.md`:

1. **Git check is the FIRST file-system-sensitive check** (after tool-availability checks):
   no file reads from the target directory before the git check passes. This is verified
   by bash `set -x` trace in bats.
2. **E-INIT-002 hard-fail is NOT idempotent re-scaffold.** The test must explicitly verify
   that running init on an existing `.brain/` directory does NOT create any new files
   (not even a partial scaffold). The correct recovery path is `/brain:upgrade-brain`.
3. **The zero-argument CLI contract:** `run.sh` uses `${BRAIN_ROOT:-$PWD}` as the target.
   The `local-dev-test.sh` harness `cd`s into the temp brain directory, not passes `--target`.
4. **Error JSON on stdout, not stderr.** The hook chain JSON-in/JSON-out contract
   (ADR-002) applies: structured output goes to stdout; only unstructured diagnostic
   traces go to stderr. `_die()` helper must write to stdout and exit 2.

**Forbidden patterns:**
- `exit` without an explicit exit code — the `_die` function must always call `exit 2`.
- Swallowing errors with `set +e` or `|| true` in the prerequisite checks. Each check
  must fail loudly.
- Calling `uuidgen` without a fallback: some CI environments lack it. Use
  `uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || date +%s%N`.

## Library and Framework Requirements

Same as STORY-002. Additionally:

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `node` | 20+ (checked at runtime) | BC-2.01.001 precondition 4 |
| `uuidgen` (with fallback) | any | `_die` trace field |

## File Structure Requirements

Files to modify/create:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/init/run.sh` | Modify | Add prerequisite check chain and `briefs/research/` to mkdir |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 8 new error-path + SLA tests |
| `plugins/brain-factory/tests/local-dev-test.sh` | Create | `assert_under_5_minutes` + end-to-end init validation |

Files NOT to modify: `tests/upgrade.bats` (STORY-001), `tests/skills.bats` (STORY-002 stub),
`.factory/` tree, `docs/planning/`.

## Previous Story Intelligence

STORY-002 delivered the happy path of `run.sh` and the core VP-014 bats tests. Error
paths were explicitly excluded. Key lessons carried forward:
- `_die` helper must be defined before the check chain. Define it at the top of `run.sh`
  after the `set -euo pipefail` line.
- The `briefs/research/` mkdir should go in the same `mkdir -p` block as the other
  `briefs/` subdirectories to avoid a separate code path that could be missed.
- `local-dev-test.sh` is a separate file from `integration.bats` per SS-01 §Test Surface.
  It tests the full init via real bash invocation, not via bats `run`. The SLA test belongs
  in BOTH files: in `integration.bats` as a bats `@test` (for CI) and in `local-dev-test.sh`
  as the canonical `assert_under_5_minutes` function (for local-dev verification per BC-2.01.002).

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-01 subsystem design | ~1,200 |
| BC-2.01.002, .003, .005 | ~2,500 |
| VP-014 (reread for error-path assertions) | ~2,500 |
| STORY-002 init run.sh (to extend) | ~2,000 |
| STORY-002 integration.bats (to extend) | ~1,000 |
| Test output | ~500 |
| **Total** | **~12,700** |

Within 20% of 200K-token context window. No split required.

## Out of Scope

- `/brain:health` skill — STORY-004
- Plugin install from marketplace — STORY-005
- `/brain:upgrade-brain` — STORY-005
- Source immutability enforcement — EPIC-02
- `briefs/research/` content (files written into it) — EPIC-05 (`/brain:research` skill)

## Anchors

- BC-2.01.002: `behavioral-contracts/ss-01/BC-2.01.002.md`
- BC-2.01.003: `behavioral-contracts/ss-01/BC-2.01.003.md`
- BC-2.01.005: `behavioral-contracts/ss-01/BC-2.01.005.md`
- VP-014: `architecture/verification-properties/VP-014-brain-init-scaffold.md`
- SS-01: `architecture/subsystems/SS-01-brain-init-scaffold.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md` (JSON stdout contract for _die)
- phased-build-plan §5.8, §5.10
