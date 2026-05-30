---
artifact_type: story
story_id: STORY-023
epic_id: EPIC-04
title: "meta-lint.bats hook script and cross-cutting surfaces plus per-hook bats completeness gate"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-18]
behavioral_contracts: [BC-2.18.002, BC-2.18.004, BC-2.18.005]
vps: [VP-006, VP-008]
dependencies: [STORY-022]
blocks: []
inputs:
  - architecture/subsystems/SS-18-meta-lint-self-audit.md  # v1.5
  - behavioral-contracts/ss-18/BC-2.18.002.md
  - behavioral-contracts/ss-18/BC-2.18.004.md
  - behavioral-contracts/ss-18/BC-2.18.005.md
  - architecture/verification-properties/VP-006-meta-lint-suite.md
  - architecture/verification-properties/VP-008-hook-event-catalog-completeness.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# SS-18 version note: inputs cite SS-18 v1.5 which reversed F-PASS1-I8 — per-hook .bats
# files are now canonical (not a consolidated hooks.bats). All ACs and tasks in this story
# reflect v1.5 semantics. The earlier F-PASS1-I8 decision is explicitly rejected in §Out of Scope.
# Bundling rationale: BC-2.18.002 (hook script surface), BC-2.18.004 (cross-cutting), and
# BC-2.18.005 (8-category + per-hook completeness) are the three remaining meta-lint surfaces that
# complete the meta-lint.bats file started by STORY-022. They are naturally bundled here
# because: (1) BC-2.18.005's completeness assertion requires ALL category suites to exist
# first — it is the final gate that locks the suite; (2) BC-2.18.004's
# cross-cutting checks (git ls-files grep patterns) are implemented in the same bats
# file using the same helper infrastructure as the hook-script checks; (3) BC-2.18.002
# (hook scripts) depends on the same fixture infrastructure (hooks/ directory) as the
# per-hook file existence check in BC-2.18.005. All three complete the meta-lint.bats
# file to its final green state. Total: 3 BCs × ~2.5K each + infrastructure = fits comfortably in one story.
---

# STORY-023: `meta-lint.bats` hook script and cross-cutting surfaces plus per-hook bats completeness gate

## Goal

Extend `meta-lint.bats` (started in STORY-022) with three remaining validation surfaces:
hook script static analysis (shebang, `set -euo pipefail`, no bare `exit`, no `eval`,
per-hook bats file existence and coverage, `shellcheck`, `shfmt`); cross-cutting
tracked-file checks (no AI attribution, no `--no-verify`, all `${CLAUDE_PLUGIN_ROOT}`
references resolve, all internal markdown links resolve); and the completeness gate
(exactly 8 category bats files exist, and every hook in `hooks/` has a corresponding
`tests/<hook-name>.bats` file containing ≥ 3 `@test` blocks). After this story,
`bats tests/meta-lint.bats` is the complete factory self-audit gate.

## User Value

As a brain-factory developer, I want `bats tests/meta-lint.bats` to guarantee that every
hook script has the correct shebang, error handling, no `eval`, no bare `exit`, and is
shellcheck-clean — and that no tracked file carries AI attribution tokens, `--no-verify`,
or a broken `${CLAUDE_PLUGIN_ROOT}` reference — so that these systemic quality violations
are caught automatically before they reach adversarial review or production.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.18.002 | `meta-lint.bats` validates hook scripts: shebang, `set -euo pipefail`, no bare exit, no eval | P0 |
| BC-2.18.004 | `meta-lint.bats` validates cross-cutting: no AI attribution, no `--no-verify`, no hardcoded template paths | P0 |
| BC-2.18.005 | 8 category suites + N per-hook suites cover all hooks and skills (positive + negative + edge case per hook) | P0 |

## Acceptance Criteria

### Hook Script Validation Surface (BC-2.18.002)

**AC-001** — `meta-lint.bats` has `@test` blocks asserting each of the following for
every hook script in `plugins/brain-factory/hooks/*.sh`: (a) first line is
`#!/usr/bin/env bash`; (b) `set -euo pipefail` appears within the first 10 lines
(line number ≤ 10); (c) no bare `exit` — every `exit` in the script body is followed
by `0`, `1`, or `2` (use word-boundary grep `\bexit\b` to avoid false positives from
here-docs or comments containing the word "exit"); (d) no `eval` anywhere; (e) `shellcheck`
exits 0 on the script; (f) `shfmt -d -i 2` produces no diff (exits 0).
(traces to BC-2.18.002 postconditions 1–3; invariants 1–3)

**AC-002** — When `set -euo pipefail` appears on line 11 (one line beyond the boundary),
the assertion fails with a message: `"<hook-name>.sh: 'set -euo pipefail' found on line
<N>, must be within first 10 lines."` The line number is included in the message.
(traces to BC-2.18.002 edge case EC-001)

**AC-003** — The bare-`exit` check uses `\bexit\b` word-boundary matching (not substring).
A script containing `# Do not exit` in a comment must NOT fail this assertion. A bats
test verifies the word-boundary behavior using a fixture hook that contains the word
"exit" inside a comment.
(traces to BC-2.18.002 edge case EC-002)

**AC-004** — Per-hook bats file coverage: `meta-lint.bats` asserts that for every hook
script in `plugins/brain-factory/hooks/*.sh`, a corresponding
`plugins/brain-factory/tests/<hook-name>.bats` file exists AND contains ≥ 3 `@test`
blocks (one positive, one negative, one edge case). The count is of `@test` declarations
within the per-hook bats file itself — NOT a prefix-grep across a shared `hooks.bats`.
(traces to BC-2.18.002 postcondition 1; SS-18 v1.5 §meta-lint.bats assertions §Hook script surface)

**AC-005** — When a hook script in `plugins/brain-factory/hooks/` has no corresponding
`tests/<hook-name>.bats` file, the assertion fails:
`"<hook-name>.sh: missing per-hook bats file tests/<hook-name>.bats"`.
When the file exists but contains fewer than 3 `@test` blocks, the assertion fails:
`"<hook-name>.sh: found <N> @test blocks in tests/<hook-name>.bats (minimum 3)."`.
(traces to BC-2.18.002 edge case EC-003; SS-18 v1.5 §NFR-020)

**AC-006** — Fixture files for this surface:
- `tests/fixtures/meta-lint/valid-hook.sh` — a minimal conformant hook.
- `tests/fixtures/meta-lint/invalid-hook-no-shebang.sh` — hook missing `#!/usr/bin/env bash`.
- `tests/fixtures/meta-lint/invalid-hook-bare-exit.sh` — hook with `exit` without code.
- `tests/fixtures/meta-lint/invalid-hook-eval.sh` — hook with `eval "$cmd"`.
- `tests/fixtures/meta-lint/invalid-hook-late-pipefail.sh` — `set -euo pipefail` on line 11.
- `tests/fixtures/meta-lint/hook-with-exit-in-comment.sh` — hook with "Do not exit" in
  a comment but no bare `exit` statement; assertion must pass.
(traces to BC-2.18.002 all edge cases and canonical test vectors)

### Cross-Cutting Validation Surface (BC-2.18.004)

**AC-007** — `meta-lint.bats` has `@test` blocks for the following cross-cutting
assertions against all files tracked by git (`git ls-files`): (a) no file contains
`Co-Authored-By: Claude`; (b) no file contains the robot emoji (`🤖`); (c) no script
file contains `--no-verify` (test files are exempted only if they include a comment
`# meta-lint-exempt: --no-verify usage is intentional for test fixture`); (d) every
`${CLAUDE_PLUGIN_ROOT}/` reference in any tracked file resolves to an existing path
under `plugins/brain-factory/`; (e) every internal markdown link `[...](path)` in
SKILL.md and AGENT.md files resolves relative to the repo root.
(traces to BC-2.18.004 postcondition 1; invariants 1–3)

**AC-008** — When a tracked file contains `Co-Authored-By: Claude`, the assertion fails
with the filename and the line number. The check uses `git grep` so it respects
`.gitignore`.
(traces to BC-2.18.004 canonical test vector 1)

**AC-009** — When a tracked file contains `${CLAUDE_PLUGIN_ROOT}/templates/nonexistent.md`,
the assertion fails with: `"<file>:<line>: CLAUDE_PLUGIN_ROOT ref does not resolve:
templates/nonexistent.md"`.
(traces to BC-2.18.004 canonical test vector 3)

**AC-010** — When a tracked skill file contains `.claude/templates/foo.md` hardcoded,
the assertion fails with: `"<file>:<line>: hardcoded .claude/templates/ path detected.
Use \${CLAUDE_PLUGIN_ROOT}/templates/ instead."`.
(traces to BC-2.18.004 edge case EC-002)

**AC-011** — Fixture file for cross-cutting: `tests/fixtures/meta-lint/invalid-crosscutting-ai-attribution.md` — a markdown file containing `Co-Authored-By: Claude`. The
`@test` for assertion (a) asserts this fixture triggers a failure.
(traces to BC-2.18.004)

### 8-Category + Per-Hook Completeness Gate (BC-2.18.005)

**AC-012** — `meta-lint.bats` has a `@test "bats suites: exactly 8 category suite files exist"` that
counts `ls plugins/brain-factory/tests/*.bats | wc -l` and asserts the result is exactly 8.
Fewer than 8 or more than 8 both fail. (Per-hook bats files live in the same `tests/`
directory and contribute to this count when hooks exist — see AC-015 for the invariant
that keeps category suites distinct from per-hook files.)
(traces to BC-2.18.005 postcondition 2; invariant 1)

**AC-013** — `meta-lint.bats` has a `@test "bats suites: meta-lint.bats is in the suite list"` that asserts `tests/meta-lint.bats` exists.
(traces to BC-2.18.005 invariant 3)

**AC-014** — `meta-lint.bats` has a `@test "bats suites: all category suites exit 0"` that runs
`bats tests/` and asserts exit 0. This is the full-suite integration gate that runs as
the last meta-lint test.
(traces to BC-2.18.005 postcondition 1)

**AC-015** — The 8-category suite check (AC-012) counts ONLY the 8 canonical category files:
`meta-lint.bats`, `skills.bats`, `templates.bats`, `quarantine.bats`,
`adversary.bats`, `policies.bats`, `upgrade.bats`, `integration.bats`.
Per-hook bats files (e.g., `quarantine-fetch.bats`) are validated separately by AC-004.
If any canonical category suite is missing, the count test fails. Suite names are
canonical (per SS-18 v1.5 §Test surface organization Layer 1 and BC-2.18.005).
(traces to BC-2.18.005 preconditions 1–3; invariant 1)

**AC-016** — `meta-lint.bats` itself is shellcheck-clean. Even though it is a bats file
(not a hook), it contains bash and must be clean under `shellcheck --shell=bash`.
`shfmt -d -i 2` produces no diff on `meta-lint.bats`.
(traces to CLAUDE.md §Conventions — production-grade default applies to all bash)

## Tasks

1. **[failing test — Red Gate]** Extend `tests/meta-lint.bats` (created in STORY-022)
   with failing `@test` blocks for all hook-script assertions (AC-001 through AC-006),
   all cross-cutting assertions (AC-007 through AC-011), and the completeness gate (AC-012
   through AC-015).
   Create fixture files from AC-006 and AC-011.
   Run bats — confirm all new tests fail (Red Gate confirmed).
   NOTE: The 8-category suite count test (AC-012) will fail until all 8 category suites
   exist. During Phase 2, stub empty `.bats` files for the 7 missing category suites
   (`skills.bats`, `templates.bats`, `quarantine.bats`, `adversary.bats`, `policies.bats`,
   `upgrade.bats`, `integration.bats`) to unblock the count assertion. Per-hook bats files
   are created by EPIC-02 hook stories — stubs for them are NOT needed here.

2. **[impl]** Implement hook-script validation in `meta-lint.bats`:
   - `check_hook_shebang <file>`: `head -1 | grep -F "#!/usr/bin/env bash"`.
   - `check_hook_pipefail_line <file>`: `grep -n "set -euo pipefail"` + assert line ≤ 10.
   - `check_hook_no_bare_exit <file>`: `grep -nP '\bexit\b(?!\s+[012])'` — assert no match.
     Use word-boundary negative-lookahead or equivalent. Verify comment-only fixture passes.
   - `check_hook_no_eval <file>`: `grep -n '\beval\b'` — assert no match.
   - `check_hook_shellcheck <file>`: `shellcheck --shell=bash "$file"` — assert exit 0.
   - `check_hook_shfmt <file>`: `shfmt -d -i 2 "$file"` — assert exit 0.
   - `check_hook_test_coverage <hook_name>`: assert file `tests/${hook_name}.bats` exists;
     then `grep -c "@test"` within that file — assert ≥ 3. File-not-found is a hard fail
     with the message from AC-005, not a skip.
   - Fixture-based `@test` blocks for each violation type.
   - Live-hooks `@test` block iterating `plugins/brain-factory/hooks/*.sh`.

3. **[impl]** Implement cross-cutting validation in `meta-lint.bats`:
   - `check_no_ai_attribution`: `git grep -l "Co-Authored-By: Claude"` — assert empty.
   - `check_no_robot_emoji`: `git grep -rl "🤖"` — assert empty.
   - `check_no_no_verify`: `git grep -l "\-\-no-verify"` (excluding meta-lint-exempt files) — assert empty.
   - `check_plugin_root_refs_resolve`: iterate all `${CLAUDE_PLUGIN_ROOT}/` references via
     `git grep -rn`; for each, strip to relative path; assert file exists under
     `plugins/brain-factory/`.
   - `check_markdown_links_resolve`: for each SKILL.md + AGENT.md, extract
     `[...](path)` links; for each path (not a URL), assert file exists at repo root.

4. **[impl]** Implement 8-category + per-hook completeness gate:
   - `@test "bats suites: exactly 8 category suite files exist"` — count check (AC-012).
   - `@test "bats suites: canonical category suite names present"` — assert each of the 8
     canonical names exists (AC-015).
   - `@test "bats suites: every hook has a per-hook bats file with >= 3 tests"` — iterate
     `hooks/*.sh`; for each, assert `tests/<hook-name>.bats` exists and `grep -c "@test"` ≥ 3
     (covered by the AC-004/AC-005 helper calls from Task 2, unified here as the full-roster loop).
   - `@test "bats suites: full category suite run exits 0"` — `bats tests/` — assert exit 0.

5. **[green]** Run `bats tests/meta-lint.bats` — all new tests pass.
   Run `shellcheck --shell=bash tests/meta-lint.bats` — clean.
   Run `shfmt -d -i 2 tests/meta-lint.bats` — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `valid-hook.sh` fixture | All hook assertions pass | happy-path | BC-2.18.002 |
| `invalid-hook-no-shebang.sh` | Shebang check FAIL | error | BC-2.18.002 |
| `invalid-hook-bare-exit.sh` | Bare-exit check FAIL | error | BC-2.18.002 invariant 1 |
| `invalid-hook-eval.sh` | No-eval check FAIL | error | BC-2.18.002 invariant 2 |
| `invalid-hook-late-pipefail.sh` | pipefail-line check FAIL; line N in message | edge-case | BC-2.18.002 EC-001 |
| `hook-with-exit-in-comment.sh` | Bare-exit check PASS (word-boundary match) | edge-case | BC-2.18.002 EC-002 |
| `invalid-crosscutting-ai-attribution.md` | AI attribution check FAIL; file + line | error | BC-2.18.004 |
| Tracked file with `${CLAUDE_PLUGIN_ROOT}/missing.md` | PLUGIN_ROOT ref check FAIL | error | BC-2.18.004 canonical test 3 |
| 8 category suites present + all hooks have per-hook .bats files (≥ 3 tests each) | Count check PASS; `bats tests/` exits 0 | happy-path | BC-2.18.005 |
| 7 category suites present (one missing) | Category count check FAIL | error | BC-2.18.005 invariant 1 |
| Hook exists; no corresponding `tests/<hook-name>.bats` | Per-hook file check FAIL; message names missing file | error | BC-2.18.005; AC-005 |
| Hook has per-hook bats file with only 2 `@test` blocks | Count check FAIL; message names count and minimum | error | BC-2.18.005; AC-005 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-006 | All 13 hooks pass meta-lint hook assertions | `tests/meta-lint.bats` |
| VP-006 | No AI attribution in any tracked file | `tests/meta-lint.bats` (git grep) |
| VP-006 | All CLAUDE_PLUGIN_ROOT refs resolve | `tests/meta-lint.bats` (path check) |
| VP-006 | Exactly 8 category bats suites; every hook has per-hook .bats file; full suite run exits 0 | `tests/meta-lint.bats` (count + per-hook file check + run) |
| VP-008 | Hook event catalog completeness verified by meta-lint cross-ref | `tests/meta-lint.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-18-meta-lint-self-audit.md`:

1. The per-hook test-coverage check asserts that each hook script in `hooks/` has a
   dedicated `tests/<hook-name>.bats` file with ≥ 3 `@test` blocks. Per-hook bats files
   are CANONICAL per CLAUDE.md §TDD Inner Loop Discipline and SS-18 v1.5. The earlier
   F-PASS1-I8 consolidation decision (all hook tests in `tests/hooks.bats`) is REVERSED.
   NFR-019 was also rewritten in nfr-catalog v0.1.1 to match: 8 category suites are
   counted; per-hook files are NOT counted in the 8-suite invariant.
2. `shellcheck` and `shfmt` are called on hook scripts FROM `meta-lint.bats` — this means
   `shellcheck` and `shfmt` must be in PATH for the test to pass. The test suite
   documents this dependency clearly; CI provision is handled by STORY-003 toolchain setup.
3. The word-boundary `\bexit\b` rule for bare-exit detection is mandatory. A naive
   `grep "exit"` would produce false positives for comments and documentation strings. The
   adversary will test the word-boundary behavior with a fixture containing "exit" in a
   comment; if the check fails on the comment-only fixture, it is a test defect, not a
   source defect.
4. `git grep` is used for cross-cutting checks (not `find` + `grep`). `git grep` respects
   `.gitignore` and only scans tracked files, preventing spurious failures on vendored
   content or build artifacts.
5. The `meta-lint.bats` file itself must pass the hook-script assertions. Even though
   it is a bats test file (not in `hooks/`), it contains bash logic and should be
   shellcheck-clean and shfmt-normalized. The adversary will verify this.

**Forbidden dependencies:**
- `meta-lint.bats`: must NOT `source` or execute any hook script (static analysis only).
- Cross-cutting checks: must NOT use `find . -name "*.md"` — use `git ls-files` to scope
  to tracked files only.
- Suite-count check: must NOT rely on hardcoded filenames for the count (use `ls *.bats | wc -l`
  so adding a new suite fails the count, alerting developers).

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | Hook validation; must be in CI PATH |
| `shfmt` | 3.7+ (latest: 3.13.1) | Hook validation; must be in CI PATH |
| `git` | any modern | `git grep` for cross-cutting checks |
| `grep` | POSIX + `-P` for Perl regex | Word-boundary bare-exit detection |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/tests/meta-lint.bats` | Extend | Add hook + cross-cutting + 8-category + per-hook completeness gate surfaces |
| `plugins/brain-factory/tests/fixtures/meta-lint/valid-hook.sh` | Create | Conformant minimal hook fixture |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-no-shebang.sh` | Create | Missing `#!/usr/bin/env bash` |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-bare-exit.sh` | Create | Contains bare `exit` |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-eval.sh` | Create | Contains `eval "$cmd"` |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-late-pipefail.sh` | Create | `set -euo pipefail` on line 11 |
| `plugins/brain-factory/tests/fixtures/meta-lint/hook-with-exit-in-comment.sh` | Create | "Do not exit" in comment; no bare exit statement |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-crosscutting-ai-attribution.md` | Create | File containing `Co-Authored-By: Claude` |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json`,
any prior STORY-NNN.md, any existing hook scripts in `plugins/brain-factory/hooks/`.

## Previous Story Intelligence

STORY-022 created `tests/meta-lint.bats` with the SKILL.md and AGENT.md validation
surfaces and the fixture infrastructure in `tests/fixtures/meta-lint/`. Confirm:
- `tests/meta-lint.bats` exists and all STORY-022 tests are green.
- `tests/fixtures/meta-lint/` directory exists with the 7 fixtures from STORY-022.
- The bats `test_helper.bash` pattern used in STORY-022 is consistent with what this
  story adds. Do NOT introduce a second helper pattern.

The SS-18 design document v1.5 REVERSED the earlier F-PASS1-I8 decision: per-hook
bats files (`tests/<hook-name>.bats`) are now canonical. The consolidated `tests/hooks.bats`
file is REJECTED (see §Out of Scope). When implementing AC-004, the check must look for
per-hook files — NOT for prefix-grep patterns within a shared hooks.bats. SS-18 v1.5 is
authoritative; disregard any prior session or research output that references the
consolidated-hooks.bats pattern.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,500 |
| SS-18 subsystem design | ~1,500 |
| BC-2.18.002, BC-2.18.004, BC-2.18.005 files | ~2,400 |
| VP-006, VP-008 files | ~1,200 |
| CLAUDE.md §Meta-Lint Contract section | ~2,500 |
| meta-lint.bats from STORY-022 (existing content) | ~2,000 |
| **Total** | **~13,100** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- SKILL.md and AGENT.md validation surfaces — STORY-022.
- Actual hook script implementation (`hooks/*.sh`) — STORY-009 through STORY-015 (EPIC-02).
- Running the full Phase 1 exit gate — Phase 3+ activity after implementation is complete.
- Single consolidated `tests/hooks.bats` (rejected — see SS-18 v1.5 F-PASS1-I8 reversal;
  CLAUDE.md §TDD Inner Loop Discipline mandates per-hook .bats files). The file
  `tests/hooks.bats` must NOT be created by this story or any story — the canonical
  pattern is `tests/<hook-name>.bats` (one file per hook). EPIC-02 hook stories each
  create their own `tests/<hook-name>.bats`; this story's completeness gate verifies them.

## Anchors

- BC-2.18.002: `behavioral-contracts/ss-18/BC-2.18.002.md`
- BC-2.18.004: `behavioral-contracts/ss-18/BC-2.18.004.md`
- BC-2.18.005: `behavioral-contracts/ss-18/BC-2.18.005.md`
- VP-006: `architecture/verification-properties/VP-006-meta-lint-suite.md`
- VP-008: `architecture/verification-properties/VP-008-hook-event-catalog-completeness.md`
- SS-18: `architecture/subsystems/SS-18-meta-lint-self-audit.md`
- CLAUDE.md §Meta-Lint Contract: authoritative assertion list
