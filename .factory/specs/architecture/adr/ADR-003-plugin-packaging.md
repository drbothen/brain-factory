---
document_type: adr
id: ADR-003
title: "Plugin packaging via plugin.json + hooks.json.template"
status: accepted
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-16T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-003: Plugin packaging via plugin.json + hooks.json.template

## Context

brain-factory must be distributable as a Claude Code plugin installable via `/plugin install brain-factory@claude-mp` (BC-2.14.001). The plugin manifest tells Claude Code what skills, agents, and hooks the plugin provides. The hook registration tells Claude Code which tool events trigger which hook scripts.

Two separate files serve distinct consumers:
- `plugin.json` — consumed by the Claude Code plugin loader at install time
- `hooks.json.template` — consumed by Claude Code's hook dispatcher at runtime (after `${CLAUDE_PLUGIN_ROOT}` substitution)

## Decision

### plugin.json location and schema

Location: `plugins/brain-factory/.claude-plugin/plugin.json` (BC-2.14.004).

Required fields:
```json
{
  "name": "brain-factory",
  "version": "<semver>",
  "description": "<one-line>",
  "author": { "name": "Josh Magady" },
  "license": "MIT",
  "keywords": ["second-brain", "obsidian", "knowledge-management", "rag", "agents"],
  "skills": ["skills/*/SKILL.md"],
  "agents": ["agents/*/AGENT.md"],
  "hooks": "hooks/hooks.json.template"
}
```

Version field uses semver. The `skills` and `agents` glob patterns are resolved relative to the plugin root at install time. `plugin.json` is validated by `tests/upgrade.bats` (VP-009).

### hooks.json.template location and schema

Location: `plugins/brain-factory/hooks/hooks.json.template` (BC-2.14.005).

All 13 hook scripts are registered using `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` paths. Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}` with the installed plugin root at runtime. The template is NOT processed at build time — the substitution happens in the Claude Code runtime.

Hook registration pattern (mirrors phased-build-plan.md §5.6):
```json
{
  "hooks": {
    "SessionStart": [...],
    "PreToolUse": [
      {"matcher": "WebFetch", "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh", "timeout": 3000}]},
      {"matcher": "Write|Edit", "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh", "timeout": 2000}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh", "timeout": 2000}]}
    ],
    "PostToolUse": [
      {"matcher": "Write|Edit", "hooks": [
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-immutability.sh", "timeout": 3000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-wikilink-integrity.sh", "timeout": 5000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-index-log-coherence.sh", "timeout": 3000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-frontmatter-schema.sh", "timeout": 3000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-page-type-policy.sh", "timeout": 3000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-voice-avoid-list.sh", "timeout": 3000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-id-citation.sh", "timeout": 3000},
        {"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/validate-publish-state.sh", "timeout": 3000}
      ]}
    ],
    "Stop": [
      {"hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/flush-state-and-commit.sh", "timeout": 10000}]}
    ]
  }
}
```

Note: `brain-health-check.sh` fires on SessionStart (not listed in the above excerpt; included in the full template). The 13-hook count includes: quarantine-fetch, enforce-kebab-case, block-ai-attribution, validate-source-immutability, validate-wikilink-integrity, validate-index-log-coherence, validate-frontmatter-schema, validate-page-type-policy, validate-voice-avoid-list, validate-source-id-citation, validate-publish-state, flush-state-and-commit, brain-health-check.

### Plugin manifest generation pipeline

The plugin.json and hooks.json.template are hand-authored, not generated. Rationale: the manifest is a stable, version-controlled declaration of the plugin's surface. Automated generation from a source-of-truth would require a generator that itself needs testing. The simpler path is to treat the manifest as a spec artifact, validate it in bats (VP-009), and keep it in sync via meta-lint (BC-2.18.004 prohibits `${CLAUDE_PLUGIN_ROOT}` hardcode violations in skills/hooks).

### Per-platform variants

v0.x ships a single `hooks.json.template` because the hooks are bash scripts that run on macOS + Linux (strong) and Git Bash / WSL2 (partial). Windows-native would require per-platform variant generation — deferred to v1.0 WASM migration (ADR-007) which eliminates the platform dependency entirely.

### Tarball assembly

The plugin tarball published to claude-mp includes:
```
brain-factory-<version>.tar.gz
  └── plugins/brain-factory/
      ├── .claude-plugin/plugin.json
      ├── skills/
      ├── agents/
      ├── hooks/         (all .sh files + hooks.json.template + lib/)
      ├── workflows/     (6 .yaml files)
      ├── templates/
      ├── rules/
      ├── bin/           (lobster-run)
      └── tests/         (bats suites — included for operator self-validation)
```

The `scripts/` directory (Node 20+ utilities) is included because Defuddle CLI and run-skill.mjs are required for URL ingest and scheduled GH Actions.

## Consequences

**Positive:**
- plugin.json schema is validated in bats (VP-009) — manifest corruption caught before users encounter it
- `${CLAUDE_PLUGIN_ROOT}` substitution is handled by Claude Code runtime — no build-time templating tool required
- hand-authored manifest is version-controlled and reviewable in PRs

**Negative:**
- Manifest must be kept in sync with skill/hook additions manually; meta-lint enforces it, but not at write-time
- Per-platform hooks.json variants require manual authoring if Windows-native support is added before v1.0

**Neutral:**
- The tarball assembly step is a devops-engineer deliverable in Phase 2 (marketplace publish gate)

## Alternatives Considered

1. **Single-file plugin manifest (all hooks inline).** Rejected: separating plugin.json (install-time) from hooks.json.template (runtime) mirrors the vsdd-factory pattern and allows the hook registration to be validated independently of the plugin metadata.
2. **Generate hooks.json.template from hook script list.** Rejected: generator adds complexity without reducing the risk of drift; bats validation of the manifest is a stronger guarantee.

## References

- phased-build-plan.md §5.3 (plugin.json structure)
- phased-build-plan.md §5.6 (hooks.json.template; "no factory-dispatcher binary involved")
- plugin-plan.md §2 (engine vs target split — engine is read-only at runtime)
- BC-2.14.004 (plugin.json valid JSON with semver)
- BC-2.14.005 (hooks.json.template references all 13 hooks via ${CLAUDE_PLUGIN_ROOT})
- VP-009 (plugin manifest correctness verification property)

## Changelog

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS4-C2:** `bats/upgrade.bats` path corrected to canonical `tests/upgrade.bats` form (sweep-by-canonical-pattern discipline: `bats/X.bats` → `tests/X.bats` across 16 architecture files, ADR-003 was one of the 16 affected). [audit-trail]
