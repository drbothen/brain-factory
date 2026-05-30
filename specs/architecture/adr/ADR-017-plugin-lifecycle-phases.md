---
document_type: adr
id: ADR-017
title: "Plugin lifecycle phases: install, upgrade, downgrade, uninstall"
status: accepted
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-017: Plugin lifecycle phases

## Context

brain-factory operators install, upgrade, and potentially downgrade the plugin. At each lifecycle phase, the plugin must maintain user data integrity in the brain vault's `.brain/` directory. Key constraint: engine files (plugin source) are read-only at runtime; all mutable state lives in the target's `.brain/` (BC-2.14.003).

## Decision

### Install (BC-2.14.001)

`/plugin install brain-factory@claude-mp` in a fresh Claude session:
1. Claude Code downloads the plugin tarball from claude-mp
2. Expands to `~/.claude/plugins/.../brain-factory/<version>/`
3. Registers skills, agents, and hooks from plugin.json and hooks.json
4. No modifications to any brain vault at install time — install is engine-only

First use (after install): operator runs `/brain:init` in their brain vault directory. This is the only step that creates `.brain/` state.

### `/brain:init` (first-time vault creation)

Creates the full vault structure (BC-2.01.001):
```
sources/{ai,health,psychology,productivity,business,books,podcasts,highlights,bookmarks}/
inbox/processed/
wiki/{concepts,people,frameworks,syntheses,observations,questions}/
wiki/index.md, wiki/log.md
briefs/{daily,weekly,monthly,content,decisions}/
briefs/research/
published/
.brain/STATE.md
.brain/manifest.json (empty: {"version":"1","sources":{},"last_updated":"..."})
.brain/policies.yaml (10 baseline policies)
.brain/logs/ (empty)
.brain/cycles/ (empty)
CLAUDE.md (scaffolded from template)
feeds.yaml (example RSS feeds)
.github/workflows/ (.gitkeep; populated by /brain:install-actions)
```
Wiki page templates are written with `embedding_status: pending` (BC-2.01.004).
`/brain:init` fails with `E-INIT-001` if the target directory is not a git repo (BC-2.01.003).
`/brain:init` completes in under 5 minutes wall-clock (BC-2.01.002, NFR-002).

### Upgrade (BC-2.14.002)

`/brain:upgrade-brain` is the upgrade skill. It:
1. Determines the currently installed version (reads `~/.claude/plugins/.../brain-factory/version.txt`)
2. Installs the new version via `/plugin install brain-factory@claude-mp` (or operator provides new version path)
3. Runs migration scripts if the new version's `migrations/` directory contains a script for the current → new version transition
4. Reports the outcome: upgraded version N → N+1; migrations applied; no data loss

Migration scripts are idempotent (BC-2.14.002; NFR-024 — upgrade is idempotent, running twice produces same outcome).

### Migration script design

Migration scripts live in `plugins/brain-factory/migrations/<from-version>-to-<to-version>.sh`. They:
- Accept `<brain-vault-root>` as argument
- Read `.brain/manifest.json`, `.brain/policies.yaml`, and other state files
- Apply schema migrations (e.g., adding new required fields to manifest.json entries)
- Write updated state files atomically (via manifest-write.sh pattern)
- Exit 0 on success; exit 2 on unrecoverable migration failure (vault left unchanged)

v0.1 → v0.2 migration: adds `sha256` field to existing manifest.json entries that predate ADR-015. Computes sha256 for each source file and backfills the field.

### Downgrade

Downgrade (installing an older version) is not officially supported but is operationally possible. The older version may not understand new fields in `.brain/manifest.json` added by the newer version. The architectural guarantee: new fields are additive — older versions ignore unknown fields via `jq` selection (no strict schema enforcement that rejects unknown fields). This makes downgrade safe-ish for one major version step; multi-version downgrade is not tested.

### Uninstall

`/plugin remove brain-factory` removes the engine from `~/.claude/plugins/`. It does NOT delete the brain vault or `.brain/` state — user data is preserved. The operator must manually remove the vault if desired. This is the standard Claude Code plugin remove behavior.

### Engine read-only at runtime enforcement

BC-2.14.003: engine files are read-only at runtime. This is enforced by:
1. `block-ai-attribution.sh` and `enforce-kebab-case.sh` do not write to plugin paths
2. Skills read templates via `${CLAUDE_PLUGIN_ROOT}/templates/...` (read-only access)
3. All writes go to the brain vault (current working directory)
The hook chain cannot write to the plugin installation path because hooks run in the brain vault's cwd.

## Consequences

**Positive:**
- Clean install/upgrade separation: install is engine-only; `/brain:init` creates vault state
- Idempotent upgrade is testable (bats upgrade.bats runs twice; asserts same outcome)
- Additive schema changes ensure downgrade safety for one version step

**Negative:**
- Migration scripts require careful authoring for every schema change; missing a migration script leaves older vault state incompatible with new engine expectations
- Multi-version downgrade is not tested or guaranteed

**Neutral:**
- The `/plugin install` and `/plugin remove` mechanics are handled by Claude Code; brain-factory controls only what happens to `.brain/` state before and after

## Changelog

### v1.1 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** Both occurrences of `hooks.json.template` updated to `hooks.json` (filename rename per ADR-003 v2.0): §Install (BC-2.14.001) step 3 and §References BC-2.14.005. [audit-trail]

## References

- BC-2.14.001 (install succeeds in fresh Claude session)
- BC-2.14.002 (upgrade-brain migrates .brain/ state)
- BC-2.14.003 (engine files read-only at runtime)
- BC-2.14.004 (plugin.json valid JSON with semver)
- BC-2.14.005 (hooks.json references all 13 hooks)
- BC-2.01.001..BC-2.01.006 (brain:init behavior)
- NFR-024 (upgrade idempotent)
- ADR-003 (plugin.json + hooks.json packaging)
