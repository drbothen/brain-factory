---
document_type: adr
id: ADR-003
title: "Plugin packaging via plugin.json + hooks.json"
status: accepted
level: L3
version: "2.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-25T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-003: Plugin packaging via plugin.json + hooks.json

## Context

brain-factory must be distributable as a Claude Code plugin installable via `/plugin install brain-factory@claude-mp` (BC-2.14.001). The plugin manifest tells Claude Code what skills, agents, and hooks the plugin provides. The hook registration tells Claude Code which tool events trigger which hook scripts.

Two separate files serve distinct consumers:
- `plugin.json` — consumed by the Claude Code plugin loader at install time
- `hooks.json` — consumed by Claude Code's hook dispatcher at runtime (after `${CLAUDE_PLUGIN_ROOT}` substitution)

## Decision

### plugin.json location and schema

Location: `plugins/brain-factory/.claude-plugin/plugin.json` (BC-2.14.004).

Required and supported fields (verified May 2026):
```json
{
  "name": "brain-factory",
  "displayName": "Brain Factory",
  "version": "<semver>",
  "description": "<one-line>",
  "author": {"name": "Josh Magady"},
  "license": "MIT",
  "keywords": ["second-brain", "obsidian", "knowledge-management", "rag", "agents"],
  "skills": "./skills/",
  "agents": ["./agents/"],
  "hooks": "hooks/hooks.json",
  "mcpServers": "./mcp-config.json",
  "dependencies": []
}
```

**Key behavior differences from v1.1 (corrections):**

- `"name"` is the ONLY required field. All others are optional but recommended.
- `"skills"` field value is a **directory path** (string or array), NOT a glob pattern. Claude Code auto-discovers skills from the `skills/` directory by convention. The `"skills"` field in plugin.json ADDS additional directories beyond the default — it is additive. `"skills/*/SKILL.md"` glob patterns (v1.1 design) are incorrect.
- `"agents"` field value is a directory path (string or array). Unlike skills, the `"agents"` field REPLACES the default `agents/` directory rather than adding to it.
- `"hooks"` field points to `hooks/hooks.json` — NOT `hooks/hooks.json.template`. The filename `hooks.json.template` was a brain-factory invention; Claude Code reads `hooks.json` directly. Path variable substitution (`${CLAUDE_PLUGIN_ROOT}`) is performed by Claude Code at runtime when it reads the file — not at "build time" or "install time."
- `"mcpServers"` allows the plugin to declare MCP server configurations.
- `"displayName"`, `"commands"`, `"lspServers"`, `"outputStyles"`, `"userConfig"`, `"channels"` are additional supported fields (not used in v0.x but documented for completeness).

Version field uses semver. `plugin.json` is validated by `tests/upgrade.bats` (VP-009).

### hooks.json location and schema

Location: `plugins/brain-factory/hooks/hooks.json` (BC-2.14.005).

**File rename from v1.1:** The file was previously named `hooks.json.template`. This name was a brain-factory invention. Claude Code reads `hooks.json` and performs `${CLAUDE_PLUGIN_ROOT}` substitution at runtime. The file is renamed to `hooks.json` throughout.

All 13 hook scripts are registered using `${CLAUDE_PLUGIN_ROOT}/hooks/<name>.sh` paths. Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}` with the installed plugin root at runtime.

### Path variables available in hooks.json

Three path variables are substituted by Claude Code at runtime:

| Variable | Resolves to | When to use |
|----------|-------------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin installation directory (changes on update) | Hook script paths, template paths |
| `${CLAUDE_PLUGIN_DATA}` | Persistent data directory (survives updates) | Plugin state that must persist across upgrades |
| `${CLAUDE_PROJECT_DIR}` | Project root directory | Paths relative to the user's current project |

brain-factory hooks use `${CLAUDE_PLUGIN_ROOT}` for all hook script paths. `${CLAUDE_PLUGIN_DATA}` is not used in v0.x (state lives in `.brain/` in the vault, not the plugin data dir). `${CLAUDE_PROJECT_DIR}` is not used in hooks directly — the brain vault root is resolved at runtime by hooks reading `.brain/STATE.md`.

Hook registration pattern (mirrors phased-build-plan.md §5.6):
```json
{
  "hooks": {
    "SessionStart": [...],
    "PreToolUse": [
      {"matcher": "WebFetch", "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh", "timeout": 3000}]},
      {"matcher": "Write\\|Edit", "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh", "timeout": 2000}]},
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh", "timeout": 2000}]}
    ],
    "PostToolUse": [
      {"matcher": "Write\\|Edit", "hooks": [
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

**Matcher syntax correction from v1.1:** Pipe-separated matchers require backslash escape: `"Write\\|Edit"` not `"Write|Edit"`. See ADR-002 v2.0 for full matcher syntax documentation.

Note: `brain-health-check.sh` fires on SessionStart (not listed in the above excerpt; included in the full hooks.json). The 13-hook count includes: quarantine-fetch, enforce-kebab-case, block-ai-attribution, validate-source-immutability, validate-wikilink-integrity, validate-index-log-coherence, validate-frontmatter-schema, validate-page-type-policy, validate-voice-avoid-list, validate-source-id-citation, validate-publish-state, flush-state-and-commit, brain-health-check.

### Skills auto-discovery behavior

Claude Code auto-discovers skills by scanning the `skills/` directory (convention). The `"skills"` field in plugin.json ADDS additional scan directories — it is additive, not a replacement. In v0.x brain-factory, all skills live under `skills/` so the `"skills"` field is set to `"./skills/"` (reinforcing the default rather than adding a new directory). Glob patterns like `"skills/*/SKILL.md"` are NOT supported and were incorrect in v1.1.

### Plugin manifest generation pipeline

The plugin.json and hooks.json are hand-authored, not generated. Rationale: the manifest is a stable, version-controlled declaration of the plugin's surface. Automated generation from a source-of-truth would require a generator that itself needs testing. The simpler path is to treat the manifest as a spec artifact, validate it in bats (VP-009), and keep it in sync via meta-lint (BC-2.18.004 prohibits `${CLAUDE_PLUGIN_ROOT}` hardcode violations in skills/hooks).

### Per-platform variants

v0.x ships a single `hooks.json` because the hooks are bash scripts that run on macOS + Linux (strong) and Git Bash / WSL2 (partial). Windows-native would require per-platform variant generation — deferred to v1.0 WASM migration (ADR-007) which eliminates the platform dependency entirely.

### Tarball assembly

The plugin tarball published to claude-mp includes:
```
brain-factory-<version>.tar.gz
  └── plugins/brain-factory/
      ├── .claude-plugin/plugin.json
      ├── skills/
      ├── agents/
      ├── hooks/         (all .sh files + hooks.json + lib/)
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
- Correct `hooks.json` filename eliminates the confusing `hooks.json.template` concept — the file is not a template in the traditional sense; it is a hooks config that Claude Code reads directly

**Negative:**
- Manifest must be kept in sync with skill/hook additions manually; meta-lint enforces it, but not at write-time
- Per-platform hooks.json variants require manual authoring if Windows-native support is added before v1.0
- v1.1 glob-pattern references to `"skills/*/SKILL.md"` and `"agents/*/AGENT.md"` in plugin.json must be replaced with directory paths

**Neutral:**
- The tarball assembly step is a devops-engineer deliverable in Phase 2 (marketplace publish gate)

## Alternatives Considered

1. **Single-file plugin manifest (all hooks inline).** Rejected: separating plugin.json (install-time) from hooks.json (runtime) mirrors the vsdd-factory pattern and allows the hook registration to be validated independently of the plugin metadata.
2. **Generate hooks.json from hook script list.** Rejected: generator adds complexity without reducing the risk of drift; bats validation of the manifest is a stronger guarantee.
3. **Keep the `hooks.json.template` filename.** Rejected: the name implies a build-time template-processing step that does not exist. Claude Code reads the file at runtime and substitutes variables. The correct name is `hooks.json`.

## References

- phased-build-plan.md §5.3 (plugin.json structure)
- phased-build-plan.md §5.6 (hooks.json; "no factory-dispatcher binary involved")
- plugin-plan.md §2 (engine vs target split — engine is read-only at runtime)
- BC-2.14.004 (plugin.json valid JSON with semver — glob patterns corrected to directory paths)
- BC-2.14.005 (hooks.json references all 13 hooks via ${CLAUDE_PLUGIN_ROOT} — filename corrected from hooks.json.template)
- VP-009 (plugin manifest correctness verification property)
- ADR-002 v2.0 (hook stdin/stdout contract; matcher syntax; hook handler types)

## Changelog

### v2.0 (2026-05-25)

**Breaking schema and naming changes** — v1.1 contained speculative/incorrect assumptions about the Claude Code plugin API. All corrections are based on verified May 2026 API behavior.

1. **ADR title updated:** "Plugin packaging via plugin.json + hooks.json.template" → "Plugin packaging via plugin.json + hooks.json" (file renamed throughout).

2. **hooks.json.template → hooks.json:** The filename `hooks.json.template` was a brain-factory invention with no basis in the Claude Code API. Claude Code reads `hooks.json` directly and performs `${CLAUDE_PLUGIN_ROOT}` substitution at runtime. Every reference in this ADR updated. BC-2.14.005 and hooks.json itself must be renamed accordingly.

3. **plugin.json `"skills"` field corrected:** v1.1 used glob pattern `"skills/*/SKILL.md"`. Skills are auto-discovered by Claude Code from the `skills/` directory. The `"skills"` field is a directory path (additive), not a glob pattern. Corrected to `"./skills/"`.

4. **plugin.json `"agents"` field corrected:** v1.1 used glob pattern `"agents/*/AGENT.md"`. The `"agents"` field is a directory path (replaces default), not a glob pattern. Corrected to `["./agents/"]`.

5. **plugin.json schema expanded:** Added `"displayName"` and `"mcpServers"` to the documented schema. Noted additional supported fields (`"commands"`, `"lspServers"`, `"outputStyles"`, `"userConfig"`, `"channels"`) for completeness.

6. **Path variables documented:** Three Claude Code path variables catalogued with their semantics: `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, `${CLAUDE_PROJECT_DIR}`. brain-factory's v0.x usage of each clarified.

7. **Matcher syntax corrected in hooks.json example:** `"Write|Edit"` → `"Write\\|Edit"` (pipe requires backslash escape per ADR-002 v2.0).

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS4-C2:** `bats/upgrade.bats` path corrected to canonical `tests/upgrade.bats` form (sweep-by-canonical-pattern discipline: `bats/X.bats` → `tests/X.bats` across 16 architecture files, ADR-003 was one of the 16 affected). [audit-trail]

### v1.0 (2026-05-15)

Initial accepted ADR. Contained speculative plugin.json schema (glob patterns instead of directory paths) and incorrect hooks file naming (`hooks.json.template`). Superseded by v2.0.
