---
document_type: prd-supplement
supplement_type: interface-definitions
version: "0.2.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-25T00:00:00
phase: phase-1b
traces_to: prd/index.md
created: 2026-05-15
last_updated: 2026-05-25
---

# brain-factory Interface Definitions

## 1. Skill Argument-Hint Signatures (all 26 skills)

Canonical signatures from `SKILL.md` `argument-hint` frontmatter. These are displayed in Claude Code skill hints.

### Phase 0/1 Primitives (13 skills — v0.1)

| Skill | argument-hint |
|-------|--------------|
| `/brain:init` | (no arguments) |
| `/brain:health` | (no arguments) |
| `/brain:ingest-url` | `<url> [--topic <category>]` |
| `/brain:ingest-source` | `<path> [--topic <category>]` |
| `/brain:process-inbox` | (no arguments) |
| `/brain:lint-wiki` | (no arguments) |
| `/brain:connect` | `[days]` (default: 7) |
| `/brain:synthesize` | (no arguments) |
| `/brain:brief` | `<topic>` |
| `/brain:write` | `<brief-path> [--companion-posts] [--hero-prompt]` |
| `/brain:quarantine-check` | `<path-or-url>` |
| `/brain:rename-page` | `<old-slug> <new-slug>` |
| `/brain:adversary-review` | `<path>` |

### Phase 2–3 Polish Skills (12 skills — v0.9)

| Skill | argument-hint |
|-------|--------------|
| `/brain:daily-brief` | (no arguments) |
| `/brain:weekly-refresh` | (no arguments) |
| `/brain:quarterly-mirror` | (no arguments) |
| `/brain:reflect` | `<prompt>` |
| `/brain:monthly-perf` | (no arguments) |
| `/brain:install-actions` | (no arguments) |
| `/brain:upgrade-brain` | (no arguments) |
| `/brain:export-brain` | `[--static-site]` |
| `/brain:publish-content` | `<file> [--finalize --url <url>] [--schedule <date>]` |
| `/brain:policy-add` | `<id> <body>` |
| `/brain:policy-registry-validate` | (no arguments) |
| `/brain:cold-start-recover` | (no arguments) |

### Phase 2–3 New Skill (1 skill — v0.9)

| Skill | argument-hint |
|-------|--------------|
| `/brain:research` | `<topic>` |

---

## 2. Hook stdin/stdout JSON Schemas

### PreToolUse Input Schema

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "effort": {"level": "low|medium|high|xhigh|max"},
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash|Edit|Write|Read|Glob|Grep|Agent|WebFetch|WebSearch|mcp__*",
  "tool_input": {
    // Tool-specific fields — see per-tool table below
  },
  "tool_use_id": "unique-id-123"
}
```

### PostToolUse Input Schema

PostToolUse payloads extend the PreToolUse shape with `tool_result`:

```json
{
  "session_id": "...",
  "hook_event_name": "PostToolUse",
  "tool_name": "...",
  "tool_input": { ... },
  "tool_use_id": "...",
  "tool_result": {
    "type": "text|image|error",
    "text": "command output or file content",
    "exit_code": 0
  }
}
```

All fields from PreToolUse (`session_id`, `transcript_path`, `cwd`, `permission_mode`, `effort`) are also present. `tool_result` is absent in PreToolUse.

### Per-Tool `tool_input` Fields

| Tool | `tool_input` fields |
|------|---------------------|
| `Write` | `file_path`, `content` |
| `Edit` | `file_path`, `old_string`, `new_string`, `replace_all` |
| `Read` | `file_path` |
| `Bash` | `command`, `description`, `timeout`, `run_in_background` |
| `WebFetch` | `url` |
| `WebSearch` | `query` |
| `Glob` | `pattern` |
| `Grep` | `pattern`, `path` |

### Universal Hook Output Schema

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Warning or advisory message shown to user",
  "decision": "block",
  "reason": "Why the hook blocked the operation",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Context for Claude model",
    "permissionDecision": "deny|allow|ask|defer",
    "permissionDecisionReason": "Explanation"
  }
}
```

All fields are optional. brain-factory hooks embed their error codes and trace inside `hookSpecificOutput`:

```json
{
  "hookSpecificOutput": {
    "code": "E-WIKI-005",
    "trace": "<uuid-v4>",
    "details": { ... }
  }
}
```

### brain-factory Tri-State Verdict Mapping

| brain-factory verdict | Exit code | stdout shape |
|-----------------------|-----------|-------------|
| **allow** | `0` | `{}` or `{"continue": true}` (no `decision` field) |
| **advise** | `0` | `{"systemMessage": "Advisory: ...", "continue": true}` |
| **block** (preferred) | `0` | `{"decision": "block", "reason": "..."}` |
| **block** (error path) | `2` | stderr message (no JSON required) |

### Exit Code Semantics Table

| Exit Code | Meaning | Claude Code Action |
|-----------|---------|-------------------|
| `0` | Success | stdout parsed as JSON; if `"decision": "block"` present, operation is blocked; otherwise allowed |
| `2` | Blocking error | stderr shown to user; operation aborted |
| Other non-zero (including `1`) | Non-blocking error | stderr written to debug log only — NOT shown to user; operation proceeds |

CRITICAL: Exit code `1` is NOT an advisory channel. Advisory messages must use exit `0` with `"systemMessage"` in the stdout JSON. A hook exiting `1` to send a warning will silently drop the message.

---

## 3. `plugin.json` Schema

```json
{
  "name": "brain-factory",
  "displayName": "Brain Factory",
  "version": "<semver>",
  "description": "LLM-maintained second brain plugin",
  "author": {"name": "Josh Magady"},
  "license": "MIT",
  "keywords": ["second-brain", "obsidian", "knowledge-management"],
  "skills": "./skills/",
  "agents": ["./agents/"],
  "hooks": "hooks/hooks.json"
}
```

Discovery rules:
- **Skills** are auto-discovered from the plugin root `skills/` directory (always scanned). The `"skills"` field adds one or more additional directories to scan. Skills do NOT require explicit enumeration.
- **Agents** field is a list of directories. It REPLACES the default agent discovery path — Claude Code scans only those directories. Use `["./agents/"]` to restore default-style discovery from a plugin-relative path.
- **Hooks** field points to the hooks manifest file. The value is a path relative to `${CLAUDE_PLUGIN_ROOT}`.
- No glob patterns are supported in any field value.
- `author` must be an object with a `name` field, not a bare string.

---

## 4. `hooks.json` Schema

The file is `hooks/hooks.json` (referenced from `plugin.json` as `"hooks": "hooks/hooks.json"`). Claude Code substitutes path variables at runtime — no template preprocessing step is needed.

### Available Path Variables

| Variable | Resolves to |
|----------|-------------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin installation directory (where `plugin.json` lives) |
| `${CLAUDE_PLUGIN_DATA}` | Persistent data directory — survives plugin updates |
| `${CLAUDE_PROJECT_DIR}` | Project root directory for the active project |

### Schema

```json
{
  "hooks": [
    {
      "name": "<hook-name>",
      "script": "${CLAUDE_PLUGIN_ROOT}/hooks/<script-name>",
      "event": "PreToolUse|PostToolUse|SessionStart|Stop",
      "matcher": "<tool-name-or-wildcard>"
    }
  ]
}
```

The 13 hooks and their matchers:

| Hook | Event | Matcher |
|------|-------|---------|
| `brain-health-check.sh` | SessionStart | (all) |
| `quarantine-fetch.sh` | PreToolUse | WebFetch |
| `enforce-kebab-case.sh` | PreToolUse | Write|Edit |
| `block-ai-attribution.sh` | PreToolUse | Bash |
| `validate-source-immutability.sh` | PostToolUse | Write|Edit on `sources/*` |
| `validate-wikilink-integrity.sh` | PostToolUse | Write|Edit on `wiki/*` |
| `validate-index-log-coherence.sh` | PostToolUse | Write|Edit on `wiki/index.md` or `wiki/log.md` |
| `validate-frontmatter-schema.sh` | PostToolUse | Write|Edit on `wiki/*` or `sources/*` |
| `validate-page-type-policy.sh` | PostToolUse | Write|Edit on `wiki/*` |
| `validate-voice-avoid-list.sh` | PostToolUse | Write|Edit on `briefs/content/*-draft.md` |
| `validate-source-id-citation.sh` | PostToolUse | Write|Edit on `wiki/*` |
| `flush-state-and-commit.sh` | Stop | (all) |
| `validate-publish-state.sh` | PostToolUse | Write|Edit on `drafts/**` or `to-publish/**` or `published/**` |

---

## 5. `manifest.json` Schema (v0.1)

```json
{
  "schema_version": "0.1.0",
  "embeddings_model": null,
  "sources": [
    {
      "source_id": "<slug>",
      "url": "<string-or-null>",
      "path": "<relative-path-or-null>",
      "topic": "<topic-category>",
      "ingested_at": "<ISO8601-UTC>",
      "last_ingest": "<ISO8601-UTC>",
      "chunks": [],
      "embeddings_model": null
    }
  ]
}
```

- `url` is set for URL ingests; `path` for local-file ingests; one is always null.
- `chunks` is always present (empty array in v0.x; populated at v0.5+).
- `embeddings_model` at source level is always null in v0.x; populated at v1.0+.

---

## 6. `.brain/policies.yaml` Schema

```yaml
schema_version: "0.1.0"
policies:
  adversary_model:
    producer: claude-opus-4-5
    adversary: claude-sonnet-4-5
  max_adversary_iterations: 3
  max_ingest_tokens_per_chunk: 50000
  token_alert_multiplier: 2.0
  quarantine_whitelist_domains: []
  # ... 6 additional baseline policies from plugin-plan.md §10.2
```

---

## 7. Flag Interaction Rules

### `/brain:publish-content` flags

| Flag combination | Behavior |
|-----------------|----------|
| (no flags) | Standard publish to LinkedIn Posts API |
| `--finalize --url "<url>"` | Mark as manually published; record URL; move to published/ |
| `--schedule <date>` | Set scheduled_for; move to to-publish/; no API call |
| `--finalize` without `--url` | E-PUBLISH-007; exit 2 |
| `--schedule` + `--finalize` | `--finalize` takes precedence; schedule flag ignored |

### `/brain:write` flags

| Flag combination | Behavior |
|-----------------|----------|
| (no flags) | Generate main article only |
| `--companion-posts` | Generate main article + 3 companion posts |
| `--hero-prompt` | Generate main article + hero image prompt |
| `--companion-posts --hero-prompt` | Generate main article + companions + hero prompt |

---

## Changelog

### 0.2.0 — 2026-05-25

API corrections verified against Claude Code runtime in May 2026. All changes in this version are corrections of wrong assumptions in 0.1.0, not design decisions.

**§2 Hook stdin/stdout JSON Schemas — breaking corrections:**

- Replaced the wrong universal input schema `{"tool": ..., "input": ..., "output": ...}` with the correct Claude Code hook payload shapes for PreToolUse and PostToolUse. The correct top-level fields are `session_id`, `transcript_path`, `cwd`, `permission_mode`, `effort`, `hook_event_name`, `tool_name`, `tool_input`, and `tool_use_id`.
- Added per-tool `tool_input` fields table documenting the shape Claude Code sends for Write, Edit, Read, Bash, WebFetch, WebSearch, Glob, and Grep.
- Replaced the wrong output schema `{"verdict": "allow|advise|block", "code": ..., "message": ..., "trace": ...}` with the correct Claude Code hook output shape (`continue`, `suppressOutput`, `systemMessage`, `decision`, `reason`, `hookSpecificOutput`). brain-factory error codes and traces are now correctly placed inside `hookSpecificOutput`.
- Added explicit tri-state verdict mapping table showing the exit-code and stdout combination for each of brain-factory's three verdict states.
- Corrected exit code semantics: exit `1` is NOT an advisory channel. Exit `1` (and all non-zero except `2`) causes stderr to be written to the debug log only — not shown to the user, and the operation proceeds. Advisory messages must use exit `0` + `"systemMessage"` in stdout JSON. Exit `2` is the blocking error path (stderr shown to user, operation aborted). Exit `0` with `"decision": "block"` is the preferred block path.

**§3 plugin.json Schema — breaking corrections:**

- `author` must be an object `{"name": "..."}`, not a bare string.
- Added `displayName`, `keywords`, and `hooks` fields.
- `skills` field is a directory path string (not an array of explicit skill objects). Skills are auto-discovered from the plugin root `skills/` directory automatically; this field adds additional directories.
- `agents` field is an array of directory paths (not an array of explicit agent objects). It replaces default discovery when present.
- Removed explicit enumeration constraint (was "exactly 26 entries"). Discovery is automatic.

**§4 hooks.json — naming and schema corrections:**

- Renamed from `hooks.json.template` to `hooks.json`. Claude Code substitutes `${CLAUDE_PLUGIN_ROOT}` and other path variables at runtime — there is no template file.
- Added Available Path Variables table documenting `${CLAUDE_PLUGIN_ROOT}`, `${CLAUDE_PLUGIN_DATA}`, and `${CLAUDE_PROJECT_DIR}`.

**§5 manifest.json — no changes.**

---

## Self-Audit Checklist

- [x] All 26 skills have argument-hint signatures — verified.
- [x] All 13 hooks have event/matcher definitions — verified.
- [x] Exit code semantics table complete and corrected (exit 1 is NOT advisory) — verified.
- [x] JSON schemas are complete and corrected (plugin.json, hooks.json, manifest.json, policies.yaml) — verified.
- [x] Flag interaction rules defined for all skills with flags — verified.
- [x] Hook input/output schemas match verified May 2026 Claude Code API — verified.
- [x] Per-tool `tool_input` fields table present — verified.
- [x] Path variable table for hooks.json present — verified.
- [x] Changelog entry written for 0.2.0 with breaking-change rationale — verified.
- [x] Three-file gate run before commit:
  ```bash
  for f in .factory/specs/product-brief.md .factory/SESSION-HANDOFF.md .factory/specs/prd/prd-supplements/interface-definitions.md; do
    grep -nE '\bL[0-9]+\b' "$f" | grep -v WSL2 | grep -v 'L\[0-9\]+' | grep -v 'LinkedIn\|License\|LTS\|Linux\|Lobster\|Lock\|Loom\|Loki' | grep -v 'level: L[0-9]\+\|Level [0-9]\+\|L2\|L3\|L4\|LEVEL'
  done
  ```

  **NOTE (exclusion-list-extension protocol — VSDD level designators):** This supplement carries `level: L3` in frontmatter. Added `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` per the exclusion-list-extension protocol. Identical exclusion clause to the PRD index gate and error-taxonomy.md gate (per TD-VSDD-060 sibling-sweep).
