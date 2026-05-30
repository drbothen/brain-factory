---
artifact_type: story
story_id: STORY-034
epic_id: EPIC-07
title: "v0.1 core GH Action templates (6) and /brain:install-actions skill"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-13]
behavioral_contracts: [BC-2.13.001]
vps: [VP-023]
dependencies: [STORY-033, STORY-001]
blocks: [STORY-035]
inputs:
  - architecture/subsystems/SS-13-github-action-templates.md
  - behavioral-contracts/ss-13/BC-2.13.001.md
  - architecture/verification-properties/VP-023-github-action-templates.md
input-hash: ""
# BC status: BC-2.13.001 assigned;
# status=draft per Spec-First Gate S-7.01
# Priority: P0 — v0.1 ship gate requires all 6 core templates to run green on push
# Dependency rationale:
#   STORY-033 delivers bin/lobster-run headless execution (GH Actions invoke lobster-run).
#   STORY-001 establishes plugin.json and the plugin directory structure (template paths).
#   Blocks STORY-035 (v0.5 templates extend the install-actions skill and add api-retry).
# Subsystem anchor: SS-13 owns this story because all BC-2.13.001 postconditions are
#   SS-13 responsibilities per ARCH-INDEX. The install-actions skill is the SS-13
#   operator-facing interface.
---

# STORY-034: v0.1 core GH Action templates (6) and `/brain:install-actions` skill

## Goal

Ship the 6 v0.1 author-committed GitHub Action templates (`daily-brief.yml`,
`weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`,
`scale-test.yml`) in `plugins/brain-factory/templates/github-action-templates/`, pass
all VP-023 structural assertions (yamllint, schema, trigger type, ubuntu-latest, no
hardcoded tokens), and deliver the `/brain:install-actions` skill that copies them to
the operator's vault `.github/workflows/` with dry-run preview and confirmation.

## User Value

As a brain-factory operator, I want to run `/brain:install-actions` so that the 6
scheduled GitHub Action workflows are copied to my vault's `.github/workflows/`, wiring
daily-brief, weekly-refresh, RSS ingest, health check, wiki lint, and scale-test to run
automatically on my brain's GitHub repository.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.13.001 | v0.1 core set (6 author-committed templates) ships and runs green on push | P0 |

## Acceptance Criteria

### Template existence and YAML validity (BC-2.13.001)

**AC-001** — All 6 template files exist at
`${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/`: `daily-brief.yml`,
`weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`,
`scale-test.yml`. Exactly 6 files; `quarterly-mirror.yml` is absent (it is a v0.5
addition per ADR-013).
(traces to BC-2.13.001 precondition 1; invariant 1)

**AC-002** — All 6 templates pass `yamllint -d relaxed` without errors.
(traces to BC-2.13.001 postcondition 1; VP-023 property 1)

**AC-003** — All 6 templates contain the mandatory GH Actions top-level keys: `name`,
`on`, `jobs`. Each `jobs` entry contains `runs-on: ubuntu-latest` and a non-empty
`steps` list.
(traces to BC-2.13.001 postcondition 1; VP-023 property 2, 4)

**AC-004** — Trigger types match ADR-013 per-template inventory:
- `daily-brief.yml`, `weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`,
  `lint-wiki.yml` — each contains `on: schedule:` with a cron expression.
- `scale-test.yml` — contains `on: workflow_dispatch:` (manual trigger only; must NOT
  use `schedule:` to avoid expensive unintended runs).
(traces to BC-2.13.001 postcondition 1; VP-023 property 3)

**AC-005** — No template contains a hardcoded API token value, a user home-directory
path (`/Users/` or `/home/`), or a hardcoded vault path. Tokens use
`${{ secrets.LINKEDIN_ACCESS_TOKEN }}` or equivalent secret references.
(traces to BC-2.13.001 postcondition 1; VP-023 property 5)

**AC-006** — Each template invokes skills using `scripts/run-skill.mjs` (Node 22+
required). The template's job step checks `node --version` and fails clearly if Node
< 22. This is expressed as a `- name: Check Node version` step in each template before
any skill invocation step.
(traces to BC-2.13.001 postcondition 2; edge case EC-001)

### `/brain:install-actions` skill (BC-2.13.001)

**AC-007** — `/brain:install-actions` (no args) lists all 6 template files that will
be installed to `${BRAIN_VAULT}/.github/workflows/`, with full source → destination
paths, and prompts the operator to confirm before writing. This is the dry-run preview.
(traces to BC-2.13.001 postcondition 1; SS-13 §Interfaces Inbound)

**AC-008** — On operator confirmation, `/brain:install-actions` copies all 6 templates
from `${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/` to
`${BRAIN_VAULT}/.github/workflows/`. The `.github/workflows/` directory is created if
it does not exist.
(traces to BC-2.13.001 postcondition 1)

**AC-009** — Templates are copied as-is (no substitutions at copy time). Template YAML
files are standalone with no `${CLAUDE_PLUGIN_ROOT}` references embedded — these paths
are resolved at plugin execution time, not at template-copy time.
(traces to BC-2.13.001 postcondition 1; SS-13 §Key Design)

**AC-010** — The `install-actions.md` SKILL.md passes all meta-lint assertions:
frontmatter has `name: install-actions`, `description`, `argument-hint: "(no args)"`,
and `allowed-tools` as a non-empty YAML list; body has 6 canonical sections in order;
Iron Law ≤ 200 chars; Red Flags has ≥ 1 bullet; Procedure has ≥ 1 numbered item;
no `.claude/templates/` hardcoding.
(traces to BC-2.13.001; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

### VP-023 meta-lint coverage

**AC-011** — VP-023 bats assertions in `tests/upgrade.bats` (or `tests/meta-lint.bats`
extension) all pass: existence check, yamllint, mandatory keys, ubuntu-latest runner,
scale-test workflow_dispatch trigger, no hardcoded tokens.
(traces to BC-2.13.001 postcondition 1; VP-023 verification mechanism)

## Tasks

1. **[stub — templates]** Create 6 YAML template files in
   `plugins/brain-factory/templates/github-action-templates/` with correct structure
   (`name`, `on`, `jobs` with at least one job). Use a placeholder `steps` block that
   includes `- name: Check Node version` and a stub `run-skill.mjs` invocation.
   Trigger types per ADR-013: scheduled templates use `on: schedule:` with a placeholder
   cron; `scale-test.yml` uses `on: workflow_dispatch:`. All use `runs-on: ubuntu-latest`.

2. **[stub — skill]** Create `plugins/brain-factory/skills/install-actions/SKILL.md`
   with complete frontmatter (`name: install-actions`, `description: "Install brain-factory
   GitHub Action templates to your vault .github/workflows/"`, `argument-hint: "(no args)"`,
   `allowed-tools: [Read, Write, Bash]`) and 6-section body skeleton. Iron Law: "Never
   write to .github/workflows/ without showing the operator a dry-run preview and
   receiving explicit confirmation."

3. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/upgrade.bats` covering VP-023 and BC-2.13.001:
   - `"GH Action templates: all 6 v0.1 core templates exist"` (VP-023)
   - `"GH Action templates: all 6 core templates pass yamllint"` (VP-023)
   - `"GH Action templates: all core templates have mandatory top-level keys"` (VP-023)
   - `"GH Action templates: all core templates use ubuntu-latest runner"` (VP-023)
   - `"GH Action templates: scale-test.yml uses workflow_dispatch trigger"` (VP-023)
   - `"GH Action templates: scheduled templates use cron on: trigger"` (VP-023)
   - `"GH Action templates: no hardcoded API tokens or vault paths"` (VP-023)
   - `"install-actions: copies 6 templates to vault .github/workflows/"` (BC-2.13.001)
   - `"install-actions: creates .github/workflows/ dir if absent"` (BC-2.13.001)
   - `"install-actions: SKILL.md meta-lint compliance"` (CLAUDE.md §Meta-Lint)
   Run bats — confirm all 10 tests fail (Red Gate confirmed).

4. **[impl — templates]** Implement the 6 template YAML files with full content:
   - `daily-brief.yml`: scheduled 06:00 UTC cron; steps: Check Node version,
     `run-skill.mjs brain:brief --yesterday`.
   - `weekly-refresh.yml`: scheduled Monday 07:00 UTC; steps: Check Node version,
     `run-skill.mjs brain:synthesize`, `run-skill.mjs brain:connect 7`.
   - `ingest-rss.yml`: scheduled hourly; `brain:ingest-url` per configured feed URL.
   - `health-check.yml`: scheduled daily 05:50 UTC; `brain:health --json`.
   - `lint-wiki.yml`: on push + schedule daily; `brain:lint-wiki`.
   - `scale-test.yml`: workflow_dispatch only; `brain:health` + a small ingest batch.
   All templates: use `${{ secrets.BRAIN_VAULT_PATH }}` for vault path; tokens via
   `${{ secrets.LINKEDIN_ACCESS_TOKEN }}` where needed; no hardcoded paths.

5. **[impl — skill]** Implement `install-actions` skill Procedure:
   - List all 6 template files from `${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/`.
   - For each, show: source path → destination `${BRAIN_VAULT}/.github/workflows/<name>`.
   - Prompt operator to confirm. If declined, exit 0 with "Installation cancelled."
   - On confirmation: `mkdir -p "${BRAIN_VAULT}/.github/workflows/"`.
   - Copy each template: `cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/${t}"
     "${BRAIN_VAULT}/.github/workflows/${t}"`.
   - Report "Installed N/6 templates."

6. **[green]** Run bats for all 10 `upgrade.bats` tests — all pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `ls templates/github-action-templates/*.yml` | Exactly 6 files | happy-path | BC-2.13.001 invariant 1 |
| `yamllint -d relaxed daily-brief.yml` | Exit 0 | happy-path | VP-023 property 1 |
| `yq eval '.on \| has("schedule")' daily-brief.yml` | `true` | happy-path | VP-023 property 3 |
| `yq eval '.on \| has("workflow_dispatch")' scale-test.yml` | `true` | happy-path | VP-023 property 3 |
| `yq eval '.jobs[].runs-on' daily-brief.yml` | `ubuntu-latest` | happy-path | VP-023 property 4 |
| `grep -n 'ACCESS_TOKEN\s*=\s*[^$]' daily-brief.yml` | Empty | static | VP-023 property 5 |
| `/brain:install-actions` (confirmed) on temp vault | 6 files in `vault/.github/workflows/`; exit 0 | happy-path | BC-2.13.001 postcondition 1 |
| `/brain:install-actions` (declined) | "Installation cancelled."; no files written | happy-path | BC-2.13.001 postcondition 1 |
| `quarterly-mirror.yml` absent from templates/ | `ls` returns 6 files, no quarterly-mirror | happy-path | BC-2.13.001 invariant 1; ADR-013 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-023 | All 6 templates exist | `tests/upgrade.bats` |
| VP-023 | All 6 pass yamllint | `tests/upgrade.bats` |
| VP-023 | Mandatory GH Actions keys present | `tests/upgrade.bats` |
| VP-023 | ubuntu-latest runner in all templates | `tests/upgrade.bats` |
| VP-023 | scale-test.yml uses workflow_dispatch | `tests/upgrade.bats` |
| VP-023 | No hardcoded tokens or paths | `tests/upgrade.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-13-github-action-templates.md`:

1. Templates live at `${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/` (using
   `.yml` extension). GH Actions runners cannot access `${CLAUDE_PLUGIN_ROOT}` at
   runtime — `/brain:install-actions` materializes the templates into the vault.

2. Templates are standalone YAML files — no substitutions at copy time. The install
   skill copies them as-is (no `envsubst`, no `sed` replacements in the template body).

3. `/brain:install-actions` copies `scripts/lib/api-retry.sh` to the vault alongside
   the templates (noted in ADR-016 §api-retry.sh Delivery for GitHub Actions). The
   api-retry.sh copy is the canonical one for GH Action runners.

4. All 6 templates must survive `yamllint -d relaxed` (VP-023 verification mechanism).

5. Every new JSONL event type emitted by install-actions must be registered in
   `scripts/event-catalog.json` before PR merges.

**Forbidden dependencies:**
- Template YAML files must NOT contain `${CLAUDE_PLUGIN_ROOT}` references — they are
  installed into the vault and run on GH Actions runners where that env var is absent.
- Template YAML files must NOT reference `.claude/templates/` (CLAUDE.md §Conventions).
- `/brain:install-actions` must NOT overwrite existing files without warning the operator.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `yamllint` | 1.x+ (latest: 1.38.0; Python 3.10+ required) | VP-023 YAML validity assertion |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | Template YAML structural assertions |
| `node` | 22+ (Node 20 EOL April 2026) | Template `run-skill.mjs` invocation (CLAUDE.md §Toolchain) |
| `cp` | POSIX | Template copy in install-actions |

### CI Runner Tool Availability (ubuntu-latest = Ubuntu 24.04)

Pre-installed: bash 5.2, jq 1.7, Node 22, yq 4.53 (mikefarah)
NOT pre-installed (must install in workflow): shellcheck, shfmt, yamllint

Add this setup step to each GH Action template:
```yaml
- name: Install tools
  run: |
    sudo apt-get update && sudo apt-get install -y shellcheck
    sudo snap install shfmt
    pip install yamllint
```

Note: STORY-033 delivers `scripts/run-skill.mjs` (the headless skill runner). The GH Action templates invoke it as `node scripts/run-skill.mjs <skill-name> [args]`. It requires Node 22+ and exits with the skill's exit code.

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/templates/github-action-templates/daily-brief.yml` | Create | v0.1 core: scheduled daily brief |
| `plugins/brain-factory/templates/github-action-templates/weekly-refresh.yml` | Create | v0.1 core: scheduled weekly synthesis |
| `plugins/brain-factory/templates/github-action-templates/ingest-rss.yml` | Create | v0.1 core: scheduled RSS ingest |
| `plugins/brain-factory/templates/github-action-templates/health-check.yml` | Create | v0.1 core: scheduled health check |
| `plugins/brain-factory/templates/github-action-templates/lint-wiki.yml` | Create | v0.1 core: push + scheduled wiki lint |
| `plugins/brain-factory/templates/github-action-templates/scale-test.yml` | Create | v0.1 core: manual scale test |
| `plugins/brain-factory/skills/install-actions/SKILL.md` | Create | /brain:install-actions skill |
| `plugins/brain-factory/tests/upgrade.bats` | Create/Modify | VP-023 structural assertions + install test |

Files NOT to modify: any `.factory/` artifact, `plugin.json`, any hook script, any prior
story file, `bin/lobster-run`, workflow YAML files in `workflows/`.

## Previous Story Intelligence

STORY-033 ships `scripts/run-skill.mjs` as the headless skill runner. GH Action templates
invoke skills via `node scripts/run-skill.mjs <skill-name> <args>`. The template's `steps:`
block must use the same invocation pattern. Verify `scripts/run-skill.mjs` path is
relative to the vault root (after install, not the plugin root) — the copy step in
`install-actions` should also copy `scripts/run-skill.mjs` to the vault or reference
the installed plugin path. Per SS-13 §Key Design and ADR-016: `scripts/lib/api-retry.sh`
is also copied to the vault by `/brain:install-actions` so GH Actions runners can access
it. Include this copy in the AC-008 implementation.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~5,000 |
| SS-13 subsystem design | ~900 |
| BC-2.13.001 file | ~700 |
| VP-023 file | ~2,500 |
| 6 template YAML files (stubs) | ~1,500 |
| upgrade.bats (new file) | ~1,000 |
| **Total** | **~11,600** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- v0.5 additions (9 templates + matrix strategy) — STORY-035.
- Community-optional templates (4) — STORY-035.
- Rate-limit `api-retry.sh` canonical implementation — STORY-035 (this story copies the
  STORY-030-created minimal version; STORY-035 extends it to canonical form).
- CI matrix "run green on push" integration — this is exercised by the CI pipeline in
  Phase 3 against a smoke-brain fixture. The bats tests here validate structure only.

## Anchors

- BC-2.13.001: `behavioral-contracts/ss-13/BC-2.13.001.md`
- SS-13: `architecture/subsystems/SS-13-github-action-templates.md`
- VP-023: `architecture/verification-properties/VP-023-github-action-templates.md`
- STORY-033: `stories/stories/STORY-033.md` (lobster headless + run-skill.mjs)
- STORY-001: `stories/stories/STORY-001.md` (plugin.json — template path anchor)
