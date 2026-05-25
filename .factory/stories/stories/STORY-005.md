---
artifact_type: story
story_id: STORY-005
epic_id: EPIC-01
title: "Plugin install from marketplace, tarball completeness, and /brain:upgrade-brain"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-14]
behavioral_contracts: [BC-2.14.001, BC-2.14.002]
vps: [VP-024]
dependencies: [STORY-001, STORY-002, STORY-003, STORY-004]
blocks: []
inputs:
  - architecture/subsystems/SS-14-plugin-lifecycle.md
  - architecture/adr/ADR-003-plugin-packaging.md
  - architecture/adr/ADR-017-plugin-lifecycle-phases.md
  - behavioral-contracts/ss-14/BC-2.14.001.md
  - behavioral-contracts/ss-14/BC-2.14.002.md
  - architecture/verification-properties/VP-024-plugin-lifecycle.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-005: Plugin install from marketplace, tarball completeness, and /brain:upgrade-brain

## Goal

Verify the complete plugin installation contract (all required artifacts present at the
installed path, planning docs absent, `/brain:health` callable after install) and
implement the `/brain:upgrade-brain` skill for schema migration between versions. After
this story, EPIC-01 is complete: a developer can install brain-factory, run `/brain:init`,
and later upgrade to a new version without data loss.

## User Value

As an operator installing brain-factory from the marketplace (`/plugin install brain-factory@claude-mp`),
I want the plugin to load without errors and all skills to be immediately available. As
an operator upgrading an existing brain to a new plugin version, I want `/brain:upgrade-brain`
to migrate my `.brain/` state cleanly and confirm the upgrade succeeded.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.14.001 | `/plugin install brain-factory@claude-mp` succeeds in a fresh Claude session | P0 |
| BC-2.14.002 | `/brain:upgrade-brain` upgrades the plugin and migrates `.brain/` state if needed | P1 |

## Acceptance Criteria

**AC-001** — The plugin installation directory (simulated via `${PLUGIN_ROOT}` in bats)
contains at least 13 hook scripts under `hooks/` (excluding `lib/`), at least 26
`SKILL.md` files under `skills/`, and at least 14 `AGENT.md` files under `agents/`.
(traces to BC-2.14.001 postconditions 1–2; VP-024 install completeness)

**AC-002** — The plugin installation directory contains a `templates/` directory with at
least 1 file, a `templates/github-action-templates/` subdirectory with at least 6 `.yml`
files, `scripts/defuddle-fetch.mjs`, `scripts/quarantine.mjs`, and
`scripts/event-catalog.json`.
(traces to BC-2.14.001 postcondition 2; BC-2.14.001 invariant 2)

**AC-003** — No files matching `*planning*` or paths containing `docs/planning` exist
under the plugin installation directory. The tarball does NOT ship planning artifacts.
(traces to BC-2.14.001 invariant 3)

**AC-004** — After installation, invoking `skills/health/run.sh` on a non-brain directory
exits with code 0 or 1 (RED is acceptable), but NOT 2 (crash). The output is parseable
JSON (not a raw bash stack trace).
(traces to BC-2.14.001 postcondition 3; VP-024 health-callable test)

**AC-005** — The tarball is the only distribution mechanism: no `package.json` at the
plugin root, no `setup.py`, no `Gemfile`. The plugin installs by extracting the tarball.
(traces to BC-2.14.001 invariant 1)

**AC-006** — `scripts/defuddle-fetch.mjs` exists as a Node.js ESM module (starts with
a shebang or `import` statement) and is the correct script for Defuddle-based URL
extraction (not a placeholder). `scripts/run-skill.mjs` exists as the headless skill
runner for GitHub Actions.
(traces to BC-2.14.001 invariant 2; ADR-003 tarball assembly)

**AC-007** — `/brain:upgrade-brain` (simulated via `skills/upgrade-brain/run.sh`) when
invoked against a v0.1 brain vault (`.brain/` with a `version: "1"` manifest), runs
the v0.1→v0.2 migration script, which adds `briefs/research/` if absent, exits 0, and
produces a `CHANGELOG.md` update with the upgrade record.
(traces to BC-2.14.002 postconditions 1–4)

**AC-008** — The migration script in AC-007 is idempotent: running it twice against the
same vault produces exactly the same filesystem state as running it once (verified by
sha256sum of sorted file list before and after second run).
(traces to BC-2.14.002 invariant 2)

**AC-009** — When invoked against a vault with an incompatible schema version
(`.brain/version` file indicates a version gap that has no migration path), the skill
exits 2 and emits:
`{"level":"error","code":"E-UPGRADE-001","message":"Incompatible schema version. Manual migration required. See CHANGELOG.","trace":"<uuid>"}`.
(traces to BC-2.14.002 edge case EC-001)

**AC-010** — After a successful migration, `/brain:health` returns exit 0 (GREEN or
YELLOW is acceptable; RED is not unless the brain was already in RED state before migration).
(traces to BC-2.14.002 postconditions 1–2; VP-024 post-upgrade health test)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/upgrade-brain/run.sh` stub: reads
   `--from` and `--to` version arguments, echoes a stub migration message, exits 0.

2. **[failing test — Red Gate]** Extend `tests/upgrade.bats` (from STORY-001) with
   VP-024 assertions:
   - `@test "plugin install: all required artifact types present in installed plugin"` —
     fails because scripts/ stubs missing (defuddle-fetch.mjs, run-skill.mjs).
   - `@test "plugin install: planning docs NOT present in plugin installation"` — passes
     if STORY-001 was correct; include anyway as regression guard.
   - `@test "plugin install: brain:health callable without crash after install"` — fails
     (health skill exists from STORY-004 but test harness may not be wired).
   - `@test "upgrade-brain: migration from v0.1 to v0.2 adds missing directories"` — fails
     (stub upgrade-brain does nothing).
   - `@test "upgrade-brain: migration is idempotent"` — fails.
   - `@test "upgrade-brain: brain passes health GREEN/YELLOW status after migration"` — fails.
   - `@test "upgrade-brain: incompatible schema version emits E-UPGRADE-001"` — fails.

3. **[impl]** Create the `scripts/` directory under `plugins/brain-factory/` and author
   stub files: `scripts/defuddle-fetch.mjs` (minimal ESM module skeleton), `scripts/run-skill.mjs`
   (minimal headless runner skeleton), `scripts/event-catalog.json` (empty `{}` JSON object).
   These are not production-complete implementations — they satisfy the tarball completeness
   check (AC-002). Full implementations come in EPIC-03 (defuddle-fetch) and EPIC-07 (run-skill).

4. **[impl]** Implement the v0.1→v0.2 migration script at
   `plugins/brain-factory/migrations/0.1.0-to-0.2.0.sh`:
   - Reads `BRAIN_ROOT` from the environment.
   - Validates precondition: `${BRAIN_ROOT}/.brain/manifest.json` exists and `version = "1"`.
   - If `${BRAIN_ROOT}/briefs/research/` is absent, creates it.
   - Writes a line to `${BRAIN_ROOT}/CHANGELOG.md` recording the migration.
   - Exits 0 on success; exits 2 with E-UPGRADE-001 if the version is unrecognized.
   - The script is idempotent: running it twice is safe (uses `[[ ! -d ]] || true` pattern
     for directory creation, append-only for CHANGELOG).

5. **[impl]** Implement `skills/upgrade-brain/run.sh`: parse `--from` and `--to` args
   (or read from `.brain/manifest.json` `version` field). Dispatch to the appropriate
   migration script in `plugins/brain-factory/migrations/`. On unknown version gap,
   emit E-UPGRADE-001 and exit 2.

6. **[impl]** Add a `setup_v01_fixture_brain()` helper function to `tests/helpers.bash`
   (create this file if not yet created): creates a minimal v0.1 brain vault without
   `briefs/research/` to simulate a pre-upgrade brain.

7. **[green]** Run `bats tests/upgrade.bats` — all VP-024 assertions pass.

8. **[green]** Run `shellcheck plugins/brain-factory/skills/upgrade-brain/run.sh`
   and `shellcheck plugins/brain-factory/migrations/0.1.0-to-0.2.0.sh`.

9. **[green]** Run `shfmt -d -i 2` on both scripts.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Count hook scripts in plugin | ≥ 13 `.sh` files (excl. lib/) | happy-path | BC-2.14.001 invariant 2 |
| Count SKILL.md files | ≥ 26 | happy-path | BC-2.14.001 invariant 2 |
| Count AGENT.md files | ≥ 14 | happy-path | BC-2.14.001 invariant 2 |
| Find `*planning*` in plugin dir | No output | happy-path | BC-2.14.001 invariant 3 |
| `health/run.sh` on non-brain dir | Exit ≤ 1; valid JSON output | happy-path | BC-2.14.001 postcondition 3 |
| v0.1 brain → upgrade to v0.2 | `briefs/research/` created; CHANGELOG updated; exit 0 | happy-path | BC-2.14.002 postconditions 1–4 |
| Upgrade twice (idempotency) | State sha256 unchanged on second run | idempotency | BC-2.14.002 invariant 2 |
| Unknown schema version | E-UPGRADE-001; exit 2 | error | BC-2.14.002 EC-001 |
| Post-upgrade health check | Exit 0 or 1 (GREEN/YELLOW) | integration | BC-2.14.002 postconditions 1–2 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-024 | All required artifact types present in installed plugin | `tests/upgrade.bats` |
| VP-024 | Planning docs absent from plugin dir | `tests/upgrade.bats` |
| VP-024 | `/brain:health` callable without crash after install | `tests/upgrade.bats` |
| VP-024 | Upgrade migration from v0.1 to v0.2 correct | `tests/upgrade.bats` |
| VP-024 | Migration idempotent (sha256 state comparison) | `tests/upgrade.bats` |
| VP-024 | Brain passes health after migration | `tests/upgrade.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-14-plugin-lifecycle.md` and `architecture/adr/ADR-017-plugin-lifecycle-phases.md`:

1. **Upgrades are always forward-only.** No downgrade support in v0.x. The migration
   script must validate the `--from` version is less than the `--to` version; if not,
   emit E-UPGRADE-001.
2. **Migration scripts are idempotent per BC-2.14.002 invariant 2.** Each migration step
   must use `[[ ! -e "$target" ]] && create...` patterns — never unconditional creation
   that would overwrite existing data.
3. **Migration scripts live in `plugins/brain-factory/migrations/` per ADR-017.** The
   naming convention is `<from>-to-<to>.sh` (e.g., `0.1.0-to-0.2.0.sh`). The upgrade-brain
   skill dispatches to the correct script via a version-string lookup.
4. **`scripts/defuddle-fetch.mjs` and `scripts/run-skill.mjs` are Node.js ESM modules**
   (required by phased-build-plan.md §1: "Node 20+ is required at the operator's machine
   for narrow utilities only"). They must NOT be bash scripts renamed with `.mjs`.
5. **Planning artifacts must not ship in the tarball.** The `.gitignore` in
   `plugins/brain-factory/` must exclude `docs/`, `*.factory/`, and any path containing
   `planning`. The bats test for AC-003 is the enforcement gate.

**Forbidden patterns:**
- Migration script that unconditionally overwrites files (breaks idempotency)
- `upgrade-brain/run.sh` that re-implements directory enumeration from init — it must
  call the migration script, not re-run init logic
- `scripts/*.mjs` files that are bash scripts in disguise (must be valid Node.js ESM)

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | phased-build-plan.md §1 |
| `node` | 22+ (Node 20 EOL April 2026; LTS: 24) | Scripts are Node ESM; phased-build-plan.md §1 |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `jq` | 1.7+ (latest: 1.8.1) | Manifest version check in migration scripts |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

Files to create/modify:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/upgrade-brain/run.sh` | Create | Version dispatch to migration scripts |
| `plugins/brain-factory/skills/upgrade-brain/SKILL.md` | Replace stub | Full 6-section SKILL.md |
| `plugins/brain-factory/migrations/0.1.0-to-0.2.0.sh` | Create | Idempotent v0.1→v0.2 migration |
| `plugins/brain-factory/scripts/defuddle-fetch.mjs` | Create | Stub ESM module skeleton |
| `plugins/brain-factory/scripts/run-skill.mjs` | Create | Stub ESM module skeleton |
| `plugins/brain-factory/scripts/event-catalog.json` | Create | `{}` placeholder |
| `plugins/brain-factory/tests/helpers.bash` | Create | `setup_v01_fixture_brain()` helper |
| `plugins/brain-factory/tests/upgrade.bats` | Modify | Add VP-024 assertions |

Files NOT to modify: `tests/integration.bats`, `skills/init/run.sh`, `skills/health/run.sh`,
`.factory/` tree, `docs/planning/`.

## Previous Story Intelligence

STORY-004 completed the health skill. Key carryover:

1. The VP-024 test for "health callable without crash" requires the health skill to exist
   and not crash on a non-brain directory. STORY-004 already implemented this; STORY-005
   adds the bats test harness wire-up for it in `upgrade.bats`.
2. The `setup_v01_fixture_brain()` helper in `tests/helpers.bash` should re-use the
   directory creation pattern from `tests/local-dev-test.sh` (STORY-003) but WITHOUT
   running `/brain:init` — instead it manually creates a minimal `.brain/manifest.json`
   and `.brain/STATE.md` to simulate a pre-upgrade brain that lacks v0.2 additions.
3. The `event-catalog.json` stub in `scripts/` is required for completeness (AC-002) but
   will be replaced with the real catalog during EPIC-02 (hook enforcement chain).

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-14 subsystem design | ~1,000 |
| ADR-003 plugin packaging | ~1,500 |
| ADR-017 lifecycle phases | ~800 |
| BC-2.14.001, BC-2.14.002 | ~1,500 |
| VP-024 (full with bats tests) | ~2,500 |
| STORY-001 upgrade.bats (to extend) | ~1,000 |
| STORY-004 health skill (for wiring) | ~1,000 |
| Test output context | ~500 |
| **Total** | **~12,800** |

Within 20% of 200K-token context. No split required.

## Out of Scope

- Full Defuddle implementation in `scripts/defuddle-fetch.mjs` — EPIC-03
- Full headless runner in `scripts/run-skill.mjs` — EPIC-07
- Real marketplace publish (tarball assembly, GitHub Release) — EPIC-09
- `event-catalog.json` full content — EPIC-02
- Per-platform `hooks.json` variants — EPIC-09

## Anchors

- BC-2.14.001: `behavioral-contracts/ss-14/BC-2.14.001.md`
- BC-2.14.002: `behavioral-contracts/ss-14/BC-2.14.002.md`
- VP-024: `architecture/verification-properties/VP-024-plugin-lifecycle.md`
- SS-14: `architecture/subsystems/SS-14-plugin-lifecycle.md`
- ADR-003: `architecture/adr/ADR-003-plugin-packaging.md`
- ADR-017: `architecture/adr/ADR-017-plugin-lifecycle-phases.md`
- phased-build-plan §3 (what ships at end of Phase 1), §5.2–§5.6
