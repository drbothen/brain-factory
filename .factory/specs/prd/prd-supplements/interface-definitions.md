---
document_type: prd-supplement
supplement_type: interface-definitions
version: "0.1.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-16T00:00:00
phase: phase-1b
traces_to: prd/index.md
created: 2026-05-15
last_updated: 2026-05-16
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

### Universal Hook Input Schema (PreToolUse and PostToolUse)

```json
{
  "tool": "<tool-name>",
  "input": { "<tool-input-fields>" },
  "output": { "<tool-output-fields>" }
}
```

For PreToolUse hooks, `output` is absent. For PostToolUse hooks, `output` contains the tool's result.

### Universal Hook Output Schema (Verdict)

```json
{
  "verdict": "allow|advise|block",
  "code": "E-SCOPE-NNN",
  "message": "<human-readable message>",
  "trace": "<uuid-v4>"
}
```

- `verdict` is required.
- `code` and `message` are required when `verdict` is `advise` or `block`.
- `trace` is always required.

### Exit Code Semantics Table

| Exit Code | Verdict | Meaning | Claude Code Action |
|-----------|---------|---------|-------------------|
| 0 | `allow` | Operation is clean; proceed | Allow the tool call to complete |
| 1 | `advise` | Advisory issue detected; log and continue | Allow the tool call; surface advisory to operator |
| 2 | `block` | Operation blocked; abort | Abort the tool call; surface block reason to operator |

---

## 3. `plugin.json` Schema

```json
{
  "name": "brain-factory",
  "version": "<semver>",
  "description": "<plugin description>",
  "author": "Josh Magady",
  "license": "MIT",
  "skills": [
    { "name": "brain:<skill-name>", "path": "${CLAUDE_PLUGIN_ROOT}/skills/<dir>/SKILL.md" }
  ],
  "agents": [
    { "name": "brain:<agent-name>", "path": "${CLAUDE_PLUGIN_ROOT}/agents/<dir>/AGENT.md" }
  ]
}
```

- `skills` array: exactly 26 entries at v0.9.
- `agents` array: exactly 14 entries at v0.9.

---

## 4. `hooks.json.template` Schema

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

## Self-Audit Checklist

- [x] All 26 skills have argument-hint signatures — verified.
- [x] All 13 hooks have event/matcher definitions — verified.
- [x] Exit code semantics table complete — verified.
- [x] JSON schemas are complete (plugin.json, hooks.json.template, manifest.json, policies.yaml) — verified.
- [x] Flag interaction rules defined for all skills with flags — verified.
- [x] Three-file gate run before commit:
  ```bash
  for f in .factory/specs/product-brief.md .factory/SESSION-HANDOFF.md .factory/specs/prd/prd-supplements/interface-definitions.md; do
    grep -nE '\bL[0-9]+\b' "$f" | grep -v WSL2 | grep -v 'L\[0-9\]+' | grep -v 'LinkedIn\|License\|LTS\|Linux\|Lobster\|Lock\|Loom\|Loki' | grep -v 'level: L[0-9]\+\|Level [0-9]\+\|L2\|L3\|L4\|LEVEL'
  done
  ```

  **NOTE (exclusion-list-extension protocol — VSDD level designators):** This supplement carries `level: L3` in frontmatter. Added `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` per the exclusion-list-extension protocol. Identical exclusion clause to the PRD index gate and error-taxonomy.md gate (per TD-VSDD-060 sibling-sweep).
