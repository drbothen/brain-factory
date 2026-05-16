---
document_type: subsystem-design
id: SS-14
title: "Plugin Lifecycle and Upgrade"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-014
created: 2026-05-15
---

# SS-14: Plugin Lifecycle and Upgrade

## Responsibility

Manages plugin install, upgrade, and migration. Validates the plugin manifest (plugin.json, hooks.json.template). Keeps engine files read-only at runtime, with all mutable state in the brain vault's `.brain/`.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.14.001 | `/plugin install brain-factory@claude-mp` succeeds in fresh Claude session | P0 |
| BC-2.14.002 | `/brain:upgrade-brain` upgrades plugin and migrates `.brain/` state | P1 |
| BC-2.14.003 | Engine files are read-only at runtime; state lives in `.brain/` | P0 |
| BC-2.14.004 | `plugin.json` valid JSON with semver version and all agents/skills registered | P0 |
| BC-2.14.005 | `hooks.json.template` references all 13 hooks via `${CLAUDE_PLUGIN_ROOT}` | P0 |

## Interfaces

**Inbound:** Claude Code plugin install command; `/brain:upgrade-brain`

**Outbound:** plugin registered in Claude Code; `.brain/` state migrated if needed; structured events

## Key Design (references ADR-003, ADR-017)

### Plugin manifest structure

`plugins/brain-factory/.claude-plugin/plugin.json` declares skills, agents, and the hook template reference. Validated in `bats/upgrade.bats` via `jq` schema check (required fields present, `version` matches semver regex, `hooks` field points to the template).

`hooks.json.template` lists all 13 hooks across 4 tool-event types. Validated by counting hook entries and asserting the count equals 13 (or the expected count for the installed version).

### Upgrade migration

`/brain:upgrade-brain` runs the migration script for the version delta (e.g., `migrations/0.1.0-to-0.2.0.sh <vault-root>`). Migration scripts are idempotent: running twice produces the same outcome (NFR-024). Each migration script:
1. Validates the current state is the expected pre-migration shape
2. Applies the migration atomically
3. Reports the outcome: `migrated: <description>`

### Engine read-only enforcement

The hook chain does not write to `${CLAUDE_PLUGIN_ROOT}`. Skills read templates via `${CLAUDE_PLUGIN_ROOT}/templates/...` (read-only). `block-ai-attribution.sh` and `enforce-kebab-case.sh` apply to the brain vault cwd, not to the plugin installation path.

## Purity Classification

**Mixed.** Manifest JSON schema validation is a pure function. Install, upgrade, and migration are effectful filesystem operations.

## Dependencies

- SS-01 (Brain Init): first use after install is `/brain:init`
- SS-04 (Hook Chain): hooks.json.template registration
- All subsystems: plugin manifest registers their skills and agents

## Test Surface

- `bats/upgrade.bats` — plugin.json JSON schema valid; hooks.json.template contains all 13 hooks; upgrade-brain runs migration idempotently
