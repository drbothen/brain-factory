---
artifact_type: story
story_id: STORY-023
epic_id: EPIC-04
title: "meta-lint.bats hook script and cross-cutting surfaces plus 9-suite completeness gate"
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
  - architecture/subsystems/SS-18-meta-lint-self-audit.md
  - behavioral-contracts/ss-18/BC-2.18.002.md
  - behavioral-contracts/ss-18/BC-2.18.004.md
  - behavioral-contracts/ss-18/BC-2.18.005.md
  - architecture/verification-properties/VP-006-meta-lint-factory-self-audit.md
  - architecture/verification-properties/VP-008-hook-event-catalog-completeness.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.18.002 (hook script surface), BC-2.18.004 (cross-cutting), and
# BC-2.18.005 (9-suite completeness) are the three remaining meta-lint surfaces that
# complete the meta-lint.bats file started by STORY-022. They are naturally bundled here
# because: (1) BC-2.18.005's count-9-suites assertion requires ALL other suites to exist
# first — it is the final "count the files" gate that locks the suite; (2) BC-2.18.004's
# cross-cutting checks (git ls-files grep patterns) are implemented in the same bats
# file using the same helper infrastructure as the hook-script checks; (3) BC-2.18.002
# (hook scripts) depends on the same fixture infrastructure (hooks/ directory) as the
# count test in BC-2.18.005. All three complete the meta-lint.bats file to its final
# green state. Total: 3 BCs × ~2.5K each + infrastructure = fits comfortably in one story.
---

# STORY-023: `meta-lint.bats` hook script and cross-cutting surfaces plus 9-suite completeness gate

## Goal

Extend `meta-lint.bats` (started in STORY-022) with three remaining validation surfaces:
hook script static analysis (shebang, `set -euo pipefail`, no bare `exit`, no `eval`,
per-hook test case coverage, `shellcheck`, `shfmt`); cross-cutting tracked-file checks
(no AI attribution, no `--no-verify`, all `${CLAUDE_PLUGIN_ROOT}` references resolve,
all internal markdown links resolve); and the 9-suite completeness gate (exactly 9 bats
files, each hook has ≥ 3 test cases in `hooks.bats`). After this story,
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
| BC-2.18.005 | 9 bats suites cover 13 hooks and all skills (positive + negative + edge case per hook) | P0 |

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

**AC-004** — Per-hook test case coverage: `meta-lint.bats` asserts that
`tests/hooks.bats` contains ≥ 3 `@test` blocks prefixed with each hook's filename
(e.g., `@test "quarantine-fetch.sh: ..."`). This is NOT a check for per-hook bats files
(which would violate the 9-suite invariant); it is a count of `@test` blocks within the
single `tests/hooks.bats` file.
(traces to BC-2.18.002 postcondition 1; SS-18 §meta-lint.bats assertions clarification)

**AC-005** — When a new hook is added to `plugins/brain-factory/hooks/` but
`tests/hooks.bats` does not yet have ≥ 3 `@test` blocks for that hook's filename prefix,
the assertion fails: `"<hook-name>.sh: found <N> @test blocks in hooks.bats (minimum 3)."`.
(traces to BC-2.18.002 edge case EC-003)

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

### 9-Suite Completeness Gate (BC-2.18.005)

**AC-012** — `meta-lint.bats` has a `@test "bats suites: exactly 9 suite files exist"` that
counts `ls plugins/brain-factory/tests/*.bats | wc -l` and asserts the result is exactly 9.
Fewer than 9 or more than 9 both fail.
(traces to BC-2.18.005 postcondition 2; invariant 1)

**AC-013** — `meta-lint.bats` has a `@test "bats suites: meta-lint.bats is in the suite list"` that asserts `tests/meta-lint.bats` exists.
(traces to BC-2.18.005 invariant 3)

**AC-014** — `meta-lint.bats` has a `@test "bats suites: all suites exit 0"` that runs
`bats tests/` and asserts exit 0. This is the full-suite integration gate that runs as
the last meta-lint test.
(traces to BC-2.18.005 postcondition 1)

**AC-015** — The 9-suite gate (AC-012) passes only when all 9 suites exist:
`meta-lint.bats`, `hooks.bats`, `skills.bats`, `templates.bats`, `quarantine.bats`,
`adversary.bats`, `policies.bats`, `upgrade.bats`, `integration.bats`. If any is
missing, the count test fails. Suite names are canonical (per SS-18 §9 bats suites and
BC-2.18.005 preconditions).
(traces to BC-2.18.005 preconditions 1–3; invariant 1)

**AC-016** — `meta-lint.bats` itself is shellcheck-clean. Even though it is a bats file
(not a hook), it contains bash and must be clean under `shellcheck --shell=bash`.
`shfmt -d -i 2` produces no diff on `meta-lint.bats`.
(traces to CLAUDE.md §Conventions — production-grade default applies to all bash)

## Tasks

1. **[failing test — Red Gate]** Extend `tests/meta-lint.bats` (created in STORY-022)
   with failing `@test` blocks for all hook-script assertions (AC-001 through AC-006),
   all cross-cutting assertions (AC-007 through AC-011), and the 9-suite gate (AC-012
   through AC-015).
   Create fixture files from AC-006 and AC-011.
   Run bats — confirm all new tests fail (Red Gate confirmed).
   NOTE: The 9-suite count test (AC-012) will fail until STORY-023 confirms all 9 suites
   exist. During Phase 2, stub empty `.bats` files for missing suites to unblock the
   count assertion.

2. **[impl]** Implement hook-script validation in `meta-lint.bats`:
   - `check_hook_shebang <file>`: `head -1 | grep -F "#!/usr/bin/env bash"`.
   - `check_hook_pipefail_line <file>`: `grep -n "set -euo pipefail"` + assert line ≤ 10.
   - `check_hook_no_bare_exit <file>`: `grep -nP '\bexit\b(?!\s+[012])'` — assert no match.
     Use word-boundary negative-lookahead or equivalent. Verify comment-only fixture passes.
   - `check_hook_no_eval <file>`: `grep -n '\beval\b'` — assert no match.
   - `check_hook_shellcheck <file>`: `shellcheck --shell=bash "$file"` — assert exit 0.
   - `check_hook_shfmt <file>`: `shfmt -d -i 2 "$file"` — assert exit 0.
   - `check_hook_test_coverage <hook_name>`: `grep -c "@test \"${hook_name}:"` tests/hooks.bats — assert ≥ 3.
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

4. **[impl]** Implement 9-suite completeness gate:
   - `@test "bats suites: exactly 9 suite files exist"` — count check.
   - `@test "bats suites: canonical suite names present"` — assert each of the 9 canonical
     names exists.
   - `@test "bats suites: full suite run exits 0"` — `bats tests/` — assert exit 0.

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
| Suite count = 9 | Count check PASS; `bats tests/` exits 0 | happy-path | BC-2.18.005 |
| Suite count = 8 (one suite missing) | Count check FAIL | error | BC-2.18.005 invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-006 | All 13 hooks pass meta-lint hook assertions | `tests/meta-lint.bats` |
| VP-006 | No AI attribution in any tracked file | `tests/meta-lint.bats` (git grep) |
| VP-006 | All CLAUDE_PLUGIN_ROOT refs resolve | `tests/meta-lint.bats` (path check) |
| VP-006 | Exactly 9 bats files; full suite run exits 0 | `tests/meta-lint.bats` (count + run) |
| VP-008 | Hook event catalog completeness verified by meta-lint cross-ref | `tests/meta-lint.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-18-meta-lint-self-audit.md`:

1. The per-hook test-coverage check counts `@test` blocks in `tests/hooks.bats` using
   the hook filename as a prefix (e.g., `@test "quarantine-fetch.sh: ..."'`). It does
   NOT expect per-hook `.bats` files — that would violate NFR-019 (exactly 9 suites).
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
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.9+ | Hook validation; must be in CI PATH |
| `shfmt` | 3.7+ (`-i 2`) | Hook validation; must be in CI PATH |
| `git` | any modern | `git grep` for cross-cutting checks |
| `grep` | POSIX + `-P` for Perl regex | Word-boundary bare-exit detection |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/tests/meta-lint.bats` | Extend | Add hook + cross-cutting + 9-suite gate surfaces |
| `plugins/brain-factory/tests/fixtures/meta-lint/valid-hook.sh` | Create | Conformant minimal hook fixture |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-no-shebang.sh` | Create | Missing `#!/usr/bin/env bash` |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-bare-exit.sh` | Create | Contains bare `exit` |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-eval.sh` | Create | Contains `eval "$cmd"` |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-hook-late-pipefail.sh` | Create | `set -euo pipefail` on line 11 |
| `plugins/brain-factory/tests/fixtures/meta-lint/hook-with-exit-in-comment.sh` | Create | "Do not exit" in comment; no bare exit statement |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-crosscutting-ai-attribution.md` | Create | File containing `Co-Authored-By: Claude` |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json.template`,
any prior STORY-NNN.md, any existing hook scripts in `plugins/brain-factory/hooks/`.

## Previous Story Intelligence

STORY-022 created `tests/meta-lint.bats` with the SKILL.md and AGENT.md validation
surfaces and the fixture infrastructure in `tests/fixtures/meta-lint/`. Confirm:
- `tests/meta-lint.bats` exists and all STORY-022 tests are green.
- `tests/fixtures/meta-lint/` directory exists with the 7 fixtures from STORY-022.
- The bats `test_helper.bash` pattern used in STORY-022 is consistent with what this
  story adds. Do NOT introduce a second helper pattern.

The SS-18 design document contains the critical clarification (F-PASS1-I8 decision):
the per-hook test-coverage check looks for `@test` blocks prefixed with the hook's
filename in `tests/hooks.bats` — NOT for per-hook bats files. Confirm this interpretation
against the SS-18 document before implementing AC-004, as getting this wrong would
either falsely pass (checking the wrong thing) or falsely fail (looking for files that
must not exist per NFR-019).

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
- Adding test cases to `tests/hooks.bats` for any hook — EPIC-02 stories own that.
- Running the full Phase 1 exit gate — Phase 3+ activity after implementation is complete.

## Anchors

- BC-2.18.002: `behavioral-contracts/ss-18/BC-2.18.002.md`
- BC-2.18.004: `behavioral-contracts/ss-18/BC-2.18.004.md`
- BC-2.18.005: `behavioral-contracts/ss-18/BC-2.18.005.md`
- VP-006: `architecture/verification-properties/VP-006-meta-lint-factory-self-audit.md`
- VP-008: `architecture/verification-properties/VP-008-hook-event-catalog-completeness.md`
- SS-18: `architecture/subsystems/SS-18-meta-lint-self-audit.md`
- CLAUDE.md §Meta-Lint Contract: authoritative assertion list
