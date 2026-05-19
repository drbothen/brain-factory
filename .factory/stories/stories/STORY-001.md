---
artifact_type: story
story_id: STORY-001
epic_id: EPIC-01
title: "Plugin repo structure, plugin.json manifest, and hooks.json.template"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-14]
behavioral_contracts: [BC-2.14.003, BC-2.14.004, BC-2.14.005]
vps: [VP-009]
dependencies: []
blocks: [STORY-002, STORY-003, STORY-004, STORY-005]
inputs:
  - architecture/subsystems/SS-14-plugin-lifecycle.md
  - architecture/adr/ADR-003-plugin-packaging.md
  - behavioral-contracts/ss-14/BC-2.14.003.md
  - behavioral-contracts/ss-14/BC-2.14.004.md
  - behavioral-contracts/ss-14/BC-2.14.005.md
  - architecture/verification-properties/VP-009-plugin-manifest-correctness.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-001: Plugin repo structure, plugin.json manifest, and hooks.json.template

## Goal

Establish the complete plugin repository folder structure under `plugins/brain-factory/`,
author `plugin.json` with semver version and all 26 skills + 14 agents registered, and
author `hooks.json.template` referencing all 13 hook script paths via
`${CLAUDE_PLUGIN_ROOT}`. This story creates the skeleton every subsequent story builds
into — no logic, only structure and manifests.

## User Value

As a plugin developer, I want the canonical plugin folder layout and manifest files in
place so that Claude Code can load the plugin via `claude --plugin-dir ./plugins/brain-factory`
and so that every subsequent story has the correct file locations to target.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.14.003 | Engine files are read-only at runtime; state lives in `.brain/` | P0 |
| BC-2.14.004 | `plugin.json` valid JSON with semver version and all agents/skills registered | P0 |
| BC-2.14.005 | `hooks.json.template` references all 13 hooks via `${CLAUDE_PLUGIN_ROOT}` | P0 |

## Acceptance Criteria

**AC-001** — `plugins/brain-factory/.claude-plugin/plugin.json` exists, is valid JSON
parseable by `jq`, contains a `version` field matching semver pattern
`^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$`, and contains `name`, `description`, `author`,
`license`, `skills`, `agents`, `hooks` fields.
(traces to BC-2.14.004 postcondition 1–2)

**AC-002** — `jq '.skills | length' plugin.json` returns 26 and
`jq '.agents | length' plugin.json` returns 14.
(traces to BC-2.14.004 postcondition 3–4)

**AC-003** — `plugins/brain-factory/hooks/hooks.json.template` exists, is valid JSON,
contains exactly 13 hook script references, and every hook path uses
`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` — no hardcoded absolute paths.
(traces to BC-2.14.005 postconditions 1–3)

**AC-004** — All hook paths in `hooks.json.template` reference scripts that exist as
stub files (`.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`) in
`plugins/brain-factory/hooks/`. No path in the template references a non-existent file.
(traces to BC-2.14.005 postcondition 2; BC-2.14.003 invariant 1)

**AC-005** — The complete plugin directory structure exists:
`plugins/brain-factory/.claude-plugin/`, `skills/`, `agents/`, `hooks/`, `hooks/lib/`,
`workflows/`, `templates/`, `templates/github-action-templates/`, `rules/`, `bin/`,
`tests/`, `tests/fixtures/`.
(traces to BC-2.14.003 postcondition 1 — no writes outside plugin root at structure time)

**AC-006** — `tests/upgrade.bats` contains bats tests that assert VP-009:
`plugin.json` schema valid, semver version, 26 skills, 14 agents, hooks.json.template
has 13 entries, no hardcoded absolute paths in hook entries.
(traces to BC-2.14.004 postconditions 1–5; BC-2.14.005 postconditions 1–4; VP-009)

**AC-007** — No file under `plugins/brain-factory/` contains a hardcoded absolute path
(e.g., `/Users/...` or `/home/...`). Template paths always use
`${CLAUDE_PLUGIN_ROOT}/templates/...`.
(traces to BC-2.14.003 invariant 2)

## Tasks

1. **[stub]** Create the full directory tree under `plugins/brain-factory/` per phased-build-plan.md §5.2 and ADR-003 tarball assembly section. Include stub `.gitkeep` files where directories would otherwise be empty.

2. **[failing test — Red Gate]** Write `tests/upgrade.bats` with all VP-009 assertions in failing state (the manifests don't exist yet — bats assertions fail on missing files). Assert: plugin.json exists and is valid JSON; version is semver; `skills | length` = 26; `agents | length` = 14; hooks.json.template exists; 13 hook entries; no hardcoded absolute paths; all hook paths exist as files.

3. **[impl]** Author `plugins/brain-factory/.claude-plugin/plugin.json` per ADR-003 §plugin.json location and schema. Register 26 stub skill directories and 14 stub agent directories using glob patterns `"skills/*/SKILL.md"` and `"agents/*/AGENT.md"`.

4. **[impl]** Create stub `SKILL.md` placeholder files in all 26 skill directories and stub `AGENT.md` placeholder files in all 14 agent directories so the glob patterns resolve to 26 and 14 files respectively.

5. **[impl]** Author `plugins/brain-factory/hooks/hooks.json.template` per ADR-003 §hooks.json.template location and schema. Register all 13 hooks: `quarantine-fetch.sh`, `enforce-kebab-case.sh`, `block-ai-attribution.sh`, `validate-source-immutability.sh`, `validate-wikilink-integrity.sh`, `validate-index-log-coherence.sh`, `validate-frontmatter-schema.sh`, `validate-page-type-policy.sh`, `validate-voice-avoid-list.sh`, `validate-source-id-citation.sh`, `validate-publish-state.sh`, `flush-state-and-commit.sh`, `brain-health-check.sh`.

6. **[impl]** Create stub bash scripts for all 13 hooks in `plugins/brain-factory/hooks/`: each starts with `#!/usr/bin/env bash` and `set -euo pipefail`, reads JSON from stdin, and immediately `exit 0` (no-op stubs). These stubs satisfy AC-004 (paths exist) and will be replaced in EPIC-02.

7. **[green]** Run `bats tests/upgrade.bats` — all VP-009 assertions pass.

8. **[green]** Run `shellcheck plugins/brain-factory/hooks/*.sh` — all stub hooks are shellcheck-clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `jq -e '.name and .version and .skills and .agents' plugin.json` | exit 0 | happy-path | BC-2.14.004 |
| `jq '.skills \| length' plugin.json` | 26 | happy-path | BC-2.14.004 postcondition 3 |
| `jq '.agents \| length' plugin.json` | 14 | happy-path | BC-2.14.004 postcondition 4 |
| `jq '[.. \| strings \| select(endswith(".sh"))] \| length' hooks.json.template` | 13 | happy-path | BC-2.14.005 postcondition 2 |
| `grep -c '\${CLAUDE_PLUGIN_ROOT}' hooks.json.template` | 13 | happy-path | BC-2.14.005 postcondition 3 |
| `grep 'claude/templates' hooks.json.template` | 0 (no output) | happy-path | BC-2.14.005 invariant 1 |
| A hook path in template references non-existent `.sh` file | bats test fails | error | AC-004 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-009 | plugin.json valid JSON, semver version | `tests/upgrade.bats` |
| VP-009 | 26 skills, 14 agents registered | `tests/upgrade.bats` |
| VP-009 | 13 hooks in hooks.json.template | `tests/upgrade.bats` |
| VP-009 | No hardcoded absolute paths | `tests/upgrade.bats` grep assertion |

## Architecture Compliance Rules

From `architecture/subsystems/SS-14-plugin-lifecycle.md` and `architecture/adr/ADR-003-plugin-packaging.md`:

1. `plugin.json` location is `plugins/brain-factory/.claude-plugin/plugin.json` — NOT at the repo root and NOT at `plugins/brain-factory/plugin.json`.
2. `hooks.json.template` location is `plugins/brain-factory/hooks/hooks.json.template` — NOT at `plugins/brain-factory/.claude-plugin/hooks.json.template`.
3. Template paths use `${CLAUDE_PLUGIN_ROOT}` substitution at runtime; the template itself contains the literal string `${CLAUDE_PLUGIN_ROOT}` — no build-time substitution.
4. `plugin.json` uses glob patterns for skills/agents (`"skills/*/SKILL.md"`) — NOT hardcoded file lists.
5. The engine read-only invariant (BC-2.14.003) is enforced by design: STORY-001 creates no state-mutating logic, only static manifests. Verification: bats checks that no skill or hook writes to `${CLAUDE_PLUGIN_ROOT}` (checked in integration tests in later stories).

**Forbidden dependencies:** `plugins/brain-factory/hooks/*.sh` stub scripts must NOT import Node modules, call `npm`, or require any runtime beyond `bash`. They are pure bash stubs.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ (macOS ships 3.2; use `/usr/bin/env bash` for portability) | phased-build-plan.md §1 |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `jq` | 1.6+ | CLAUDE.md §Build & Test; BC-2.14.004 test vector |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (`-i 2`) | CLAUDE.md §Conventions |

No Node.js, no npm packages, no Rust, no compiled binaries in this story.

## File Structure Requirements

Files to create:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/.claude-plugin/plugin.json` | Create | Semver 0.1.0; 26 skills glob; 14 agents glob |
| `plugins/brain-factory/hooks/hooks.json.template` | Create | 13 hooks; all use `${CLAUDE_PLUGIN_ROOT}` |
| `plugins/brain-factory/hooks/<name>.sh` (×13) | Create | Stub bash; read stdin; exit 0 |
| `plugins/brain-factory/hooks/lib/.gitkeep` | Create | Lib dir placeholder |
| `plugins/brain-factory/skills/<name>/SKILL.md` (×26) | Create | Stub SKILL.md placeholders |
| `plugins/brain-factory/agents/<name>/AGENT.md` (×14) | Create | Stub AGENT.md placeholders |
| `plugins/brain-factory/workflows/.gitkeep` | Create | Placeholder |
| `plugins/brain-factory/templates/.gitkeep` | Create | Placeholder |
| `plugins/brain-factory/templates/github-action-templates/.gitkeep` | Create | Placeholder |
| `plugins/brain-factory/rules/.gitkeep` | Create | Placeholder |
| `plugins/brain-factory/bin/.gitkeep` | Create | Placeholder |
| `plugins/brain-factory/tests/upgrade.bats` | Create | VP-009 assertions (Red Gate → Green) |
| `plugins/brain-factory/tests/fixtures/.gitkeep` | Create | Placeholder |

Files NOT to modify: `.factory/` tree, `docs/planning/`, `CLAUDE.md`.

## Previous Story Intelligence

N/A — first story in EPIC-01 and the entire project. No predecessor lessons.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,500 |
| SS-14 subsystem design | ~1,000 |
| ADR-003 plugin packaging | ~2,000 |
| BC-2.14.003, .004, .005 files | ~1,500 |
| VP-009 file | ~1,500 |
| Existing codebase context (none yet) | 0 |
| Test output context | ~500 |
| **Total** | **~9,000** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Hook logic (validation, quarantine, attribution blocking) — EPIC-02
- `/brain:init` skill implementation — STORY-002
- Plugin marketplace installation — STORY-005
- `/brain:upgrade-brain` skill — STORY-005
- `tests/meta-lint.bats` suite — EPIC-04
- Lobster runtime (`bin/lobster-run`) — EPIC-07
- GitHub Action template content — EPIC-07

## Anchors

- BC-2.14.003: `architecture/behavioral-contracts/ss-14/BC-2.14.003.md`
- BC-2.14.004: `architecture/behavioral-contracts/ss-14/BC-2.14.004.md`
- BC-2.14.005: `architecture/behavioral-contracts/ss-14/BC-2.14.005.md`
- VP-009: `architecture/verification-properties/VP-009-plugin-manifest-correctness.md`
- ADR-003: `architecture/adr/ADR-003-plugin-packaging.md`
- SS-14: `architecture/subsystems/SS-14-plugin-lifecycle.md`
- phased-build-plan §5.2–§5.6
