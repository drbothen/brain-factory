---
artifact_type: story
story_id: STORY-001
epic_id: EPIC-01
title: "Plugin repo structure, plugin.json manifest, and hooks.json"
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

# STORY-001: Plugin repo structure, plugin.json manifest, and hooks.json

## Goal

Establish the complete plugin repository folder structure under `plugins/brain-factory/`,
author `plugin.json` with semver version and all 26 skills + 14 agents registered, and
author `hooks/hooks.json` referencing all 13 hook script paths via `${CLAUDE_PLUGIN_ROOT}`.
This story creates the skeleton every subsequent story builds into — no logic, only
structure and manifests.

## User Value

As a plugin developer, I want the canonical plugin folder layout and manifest files in
place so that Claude Code can load the plugin via `claude --plugin-dir ./plugins/brain-factory`
and so that every subsequent story has the correct file locations to target.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.14.003 | Engine files are read-only at runtime; state lives in `.brain/` | P0 |
| BC-2.14.004 | `plugin.json` valid JSON with semver version and all agents/skills registered | P0 |
| BC-2.14.005 | `hooks.json` references all 13 hooks via `${CLAUDE_PLUGIN_ROOT}` | P0 |

## Acceptance Criteria

**AC-001** — `plugins/brain-factory/.claude-plugin/plugin.json` exists, is valid JSON
parseable by `jq`, contains a `version` field matching semver pattern
`^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?$`, and contains `name`, `displayName`, `description`,
`author`, `license`, `keywords`, `skills`, `agents`, `hooks` fields. The canonical schema
(inlined for self-containedness — do NOT consult ADR-003 to obtain this; the inline below
is authoritative):

```json
{
  "name": "brain-factory",
  "displayName": "Brain Factory",
  "version": "0.1.0",
  "description": "LLM-maintained second brain plugin for Claude Code",
  "author": {"name": "Josh Magady"},
  "license": "MIT",
  "keywords": ["second-brain", "obsidian", "knowledge-management", "rag", "agents"],
  "skills": "./skills/",
  "agents": ["./agents/"],
  "hooks": "hooks/hooks.json"
}
```

Schema semantics:
- `"skills": "./skills/"` — skills are AUTO-DISCOVERED by scanning the directory. No glob
  patterns or explicit file lists are needed. The `"skills"` field ADDS scan directories
  (additive).
- `"agents": ["./agents/"]` — REPLACES the default agents/ scan directory.
- `"hooks": "hooks/hooks.json"` — points to the hooks config file (NOT hooks.json.template).
  `${CLAUDE_PLUGIN_ROOT}` substitution in hook paths happens at runtime by Claude Code.
(traces to BC-2.14.004 postcondition 1–2)

**AC-002** — Because skills are auto-discovered from the `./skills/` directory, the count
is validated by counting directories, not by reading a JSON array. The bats test asserts:
`find plugins/brain-factory/skills -mindepth 1 -maxdepth 1 -type d | wc -l` returns 26
and `find plugins/brain-factory/agents -mindepth 1 -maxdepth 1 -type d | wc -l` returns
14. The `"skills"` and `"agents"` fields in `plugin.json` are directory references, not
explicit file lists — there are no arrays to `jq '.skills | length'` against.
(traces to BC-2.14.004 postcondition 3–4)

**AC-003** — `plugins/brain-factory/hooks/hooks.json` exists, is valid JSON,
contains exactly 13 hook script references, and every hook path uses
`${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` — no hardcoded absolute paths.
`${CLAUDE_PLUGIN_ROOT}` substitution happens at RUNTIME by Claude Code; the file
itself contains the literal string `${CLAUDE_PLUGIN_ROOT}`.
(traces to BC-2.14.005 postconditions 1–3)

**AC-004** — All hook paths in `hooks.json` reference scripts that exist as
stub files (`.sh` with `#!/usr/bin/env bash` and `set -euo pipefail`) in
`plugins/brain-factory/hooks/`. No path in the file references a non-existent file.
(traces to BC-2.14.005 postcondition 2; BC-2.14.003 invariant 1)

**AC-005** — The complete plugin directory structure exists:
`plugins/brain-factory/.claude-plugin/`, `skills/`, `agents/`, `hooks/`, `hooks/lib/`,
`workflows/`, `templates/`, `templates/github-action-templates/`, `rules/`, `bin/`,
`tests/`, `tests/fixtures/`.
(traces to BC-2.14.003 postcondition 1 — no writes outside plugin root at structure time)

**AC-006** — `tests/upgrade.bats` contains bats tests that assert VP-009:
`plugin.json` schema valid, semver version, 26 skill directories, 14 agent directories,
`hooks/hooks.json` has 13 entries, no hardcoded absolute paths in hook entries.
(traces to BC-2.14.004 postconditions 1–5; BC-2.14.005 postconditions 1–4; VP-009)

**AC-007** — No file under `plugins/brain-factory/` contains a hardcoded absolute path
(e.g., `/Users/...` or `/home/...`). Template paths always use
`${CLAUDE_PLUGIN_ROOT}/templates/...`.
(traces to BC-2.14.003 invariant 2)

## Tasks

1. **[stub]** Create the full directory tree under `plugins/brain-factory/` per phased-build-plan.md §5.2 and ADR-003 tarball assembly section. Include stub `.gitkeep` files where directories would otherwise be empty.

2. **[failing test — Red Gate]** Write `tests/upgrade.bats` with all VP-009 assertions in failing state (the manifests don't exist yet — bats assertions fail on missing files). Assert: plugin.json exists and is valid JSON; version is semver; 26 skill directories exist under `skills/`; 14 agent directories exist under `agents/`; hooks/hooks.json exists; 13 hook entries; no hardcoded absolute paths; all hook paths exist as files.

3. **[impl]** Author `plugins/brain-factory/.claude-plugin/plugin.json` using the canonical schema inlined in AC-001. Use directory references (`"skills": "./skills/"`, `"agents": ["./agents/"]`, `"hooks": "hooks/hooks.json"`). Do NOT use glob patterns — skills and agents are auto-discovered from their directories.

4. **[impl]** Create stub `SKILL.md` placeholder files in all 26 skill directories and stub `AGENT.md` placeholder files in all 14 agent directories. Claude Code will auto-discover these from the `skills/` and `agents/` directories configured in `plugin.json`.

5. **[impl]** Author `plugins/brain-factory/hooks/hooks.json` at `plugins/brain-factory/hooks/hooks.json`. Register all 13 hooks: `quarantine-fetch.sh`, `enforce-kebab-case.sh`, `block-ai-attribution.sh`, `validate-source-immutability.sh`, `validate-wikilink-integrity.sh`, `validate-index-log-coherence.sh`, `validate-frontmatter-schema.sh`, `validate-page-type-policy.sh`, `validate-voice-avoid-list.sh`, `validate-source-id-citation.sh`, `validate-publish-state.sh`, `flush-state-and-commit.sh`, `brain-health-check.sh`. Every hook path must use `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` — the literal string, not substituted at authoring time.

6. **[impl]** Create stub bash scripts for all 13 hooks in `plugins/brain-factory/hooks/`: each starts with `#!/usr/bin/env bash` and `set -euo pipefail`, reads JSON from stdin, and immediately `exit 0` (no-op stubs). These stubs satisfy AC-004 (paths exist) and will be replaced in EPIC-02.

7. **[green]** Run `bats tests/upgrade.bats` — all VP-009 assertions pass.

8. **[green]** Run `shellcheck plugins/brain-factory/hooks/*.sh` — all stub hooks are shellcheck-clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `jq -e '.name and .version and .skills and .agents' plugin.json` | exit 0 | happy-path | BC-2.14.004 |
| `find plugins/brain-factory/skills -mindepth 1 -maxdepth 1 -type d \| wc -l` | 26 | happy-path | BC-2.14.004 postcondition 3 |
| `find plugins/brain-factory/agents -mindepth 1 -maxdepth 1 -type d \| wc -l` | 14 | happy-path | BC-2.14.004 postcondition 4 |
| `jq '[.. \| strings \| select(endswith(".sh"))] \| length' hooks/hooks.json` | 13 | happy-path | BC-2.14.005 postcondition 2 |
| `grep -c '\${CLAUDE_PLUGIN_ROOT}' hooks/hooks.json` | 13 | happy-path | BC-2.14.005 postcondition 3 |
| `grep 'claude/templates' hooks/hooks.json` | 0 (no output) | happy-path | BC-2.14.005 invariant 1 |
| A hook path in hooks.json references non-existent `.sh` file | bats test fails | error | AC-004 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-009 | plugin.json valid JSON, semver version | `tests/upgrade.bats` |
| VP-009 | 26 skill directories, 14 agent directories | `tests/upgrade.bats` |
| VP-009 | 13 hooks in hooks/hooks.json | `tests/upgrade.bats` |
| VP-009 | No hardcoded absolute paths | `tests/upgrade.bats` grep assertion |

## Architecture Compliance Rules

From `architecture/subsystems/SS-14-plugin-lifecycle.md` and `architecture/adr/ADR-003-plugin-packaging.md`:

1. `plugin.json` location is `plugins/brain-factory/.claude-plugin/plugin.json` — NOT at the repo root and NOT at `plugins/brain-factory/plugin.json`.
2. `hooks.json` location is `plugins/brain-factory/hooks/hooks.json` — NOT at `plugins/brain-factory/.claude-plugin/hooks.json`. There is no `hooks.json.template` file; the file is named `hooks.json` directly.
3. Hook paths use `${CLAUDE_PLUGIN_ROOT}` substitution at runtime by Claude Code; the `hooks.json` file itself contains the literal string `${CLAUDE_PLUGIN_ROOT}` — no build-time substitution by the implementer.
4. `plugin.json` uses directory references for auto-discovery, NOT glob patterns or hardcoded file lists. The `"skills": "./skills/"` field causes Claude Code to scan that directory automatically.
5. The engine read-only invariant (BC-2.14.003) is enforced by design: STORY-001 creates no state-mutating logic, only static manifests. Verification: bats checks that no skill or hook writes to `${CLAUDE_PLUGIN_ROOT}` (checked in integration tests in later stories).

**Path variables reference (inlined for self-containedness):**
- `${CLAUDE_PLUGIN_ROOT}` — absolute path to the plugin installation directory (changes on update; do NOT cache or hardcode).
- `${CLAUDE_PLUGIN_DATA}` — persistent data directory at `~/.claude/plugins/data/{id}/`; survives plugin updates.
- `${CLAUDE_PROJECT_DIR}` — the operator's current project root directory.

**Forbidden dependencies:** `plugins/brain-factory/hooks/*.sh` stub scripts must NOT import Node modules, call `npm`, or require any runtime beyond `bash`. They are pure bash stubs.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system /bin/bash is 3.2 due to GPLv3 licensing. Operators must install via `brew install bash` and ensure PATH resolves `/usr/bin/env bash` to the Homebrew version) | phased-build-plan.md §1; CLAUDE.md §Conventions |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `jq` | 1.7+ (latest: 1.8.1; jq 1.6 `leaf_paths` and `recurse_down` removed in 1.7) | CLAUDE.md §Build & Test; BC-2.14.004 test vector |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1; `-i 2 -d` flags stable across 3.x) | CLAUDE.md §Conventions |

No Node.js, no npm packages, no Rust, no compiled binaries in this story.

## File Structure Requirements

Files to create:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/.claude-plugin/plugin.json` | Create | Semver 0.1.0; 26 skills glob; 14 agents glob |
| `plugins/brain-factory/hooks/hooks.json` | Create | 13 hooks; all use `${CLAUDE_PLUGIN_ROOT}` literal string |
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

- BC-2.14.003: `behavioral-contracts/ss-14/BC-2.14.003.md`
- BC-2.14.004: `behavioral-contracts/ss-14/BC-2.14.004.md`
- BC-2.14.005: `behavioral-contracts/ss-14/BC-2.14.005.md`
- VP-009: `architecture/verification-properties/VP-009-plugin-manifest-correctness.md`
- ADR-003: `architecture/adr/ADR-003-plugin-packaging.md`
- SS-14: `architecture/subsystems/SS-14-plugin-lifecycle.md`
- phased-build-plan §5.2–§5.6

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| 2026-05-25 | Renamed `hooks.json.template` → `hooks.json` throughout (AC-003, AC-004, AC-006, File Structure table, test vectors); updated plugin.json schema to inline canonical form with auto-discovery semantics (`"skills": "./skills/"` not glob patterns); updated AC-002 to directory-count validation; updated Library table: bash 5.0+ with macOS note, shellcheck 0.10+, jq 1.7+; added path variables reference (CLAUDE_PLUGIN_ROOT, CLAUDE_PLUGIN_DATA, CLAUDE_PROJECT_DIR) to Architecture Compliance Rules; updated story title | Uncertainty removal: inline spec references replace ADR-only pointers; version pins corrected; hooks.json.template was never the correct filename |
