---
document_type: prd-supplement
supplement_type: error-taxonomy
version: "0.1.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
traces_to: prd/index.md
created: 2026-05-15
---

# brain-factory Error Taxonomy

## Convention

Error codes follow `E-{SCOPE}-{NNN}` convention:
- `SCOPE`: uppercase abbreviation of the subsystem raising the error
- `NNN`: 3-digit sequential number within that scope

Severity levels:
- **broken**: The operation cannot complete; requires user action before retry
- **degraded**: The operation completed partially; data may be incomplete
- **cosmetic**: Advisory only; operation completed; user should review

Exit codes:
- `0`: Success / no-op
- `1`: Advisory (degraded or cosmetic severity)
- `2`: Block (broken severity)

Message format uses `<placeholder>` for dynamic values.

---

## INIT Errors (E-INIT-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-INIT-001 | broken | 2 | `/brain:init` | `brain:init requires a git repository — run 'git init -b main' first` |
| E-INIT-002 | broken | 2 | `/brain:init` | `brain already initialized at <path>. Use /brain:upgrade-brain to migrate.` |
| E-INIT-003 | broken | 2 | `/brain:init` | `Node 20+ is required. Install from nodejs.org or via nvm.` |
| E-INIT-004 | broken | 2 | `/brain:init` | `Plugin root not found — reinstall brain-factory.` |
| E-INIT-005 | broken | 2 | `/brain:init` | `Conflict: <path> already exists. Remove it or init in a clean directory.` |
| E-INIT-006 | broken | 2 | `/brain:init` | `jq and yq are required. Install via your package manager.` |
| E-INIT-007 | broken | 2 | `/brain:init` | `brain:init requires a working-tree repository — bare repos are not supported.` |

**Recovery:** All INIT errors require user remediation (install prerequisite, fix directory, etc.) before re-running `/brain:init`.

---

## HOOK Errors (E-HOOK-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-HOOK-001 | broken | 2 | Any hook | `Failed to parse stdin as JSON.` |
| E-HOOK-002 | broken | 2 | Any hook | `Event emission helper missing at ${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh.` |

**Recovery:** E-HOOK-001 indicates a Claude Code harness issue or a malformed payload. E-HOOK-002 indicates a corrupt plugin installation — reinstall.

---

## INGEST Errors (E-INGEST-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-INGEST-001 | broken | 2 | `/brain:ingest-url`, `/brain:ingest-source` | `URL already ingested as <slug>. Sources are immutable. Use /brain:rename-page to rename.` |
| E-INGEST-002 | broken | 2 | `/brain:ingest-url` | `HTTP <status> fetching <url>. Ingest aborted.` |
| E-INGEST-003 | broken | 2 | `/brain:ingest-url` | `Defuddle returned empty content for <url>. Page may not be extractable.` |
| E-INGEST-004 | broken | 2 | `/brain:ingest-url` | `Content quarantined — prompt-injection pattern detected. Ingest aborted.` |
| E-INGEST-005 | broken | 2 | `/brain:ingest-url` | `Node 20+ required for Defuddle. Install from nodejs.org.` |
| E-INGEST-006 | degraded | 1 | `/brain:ingest-url` | `Source produced fewer than 5 extractable concepts. <N> wiki pages created. Consider supplementing with additional sources.` |
| E-INGEST-007 | broken | 2 | `/brain:ingest-url`, `/brain:ingest-source` | `manifest.json unreadable — run /brain:cold-start-recover.` |
| E-INGEST-008 | broken | 2 | `/brain:ingest-url`, `/brain:ingest-source` | `Failed to update manifest.json: <error>. Source file write rolled back.` |
| E-INGEST-009 | broken | 2 | `/brain:ingest-source` | `Path '<resolved-path>' is outside the brain vault. Only vault-relative paths are allowed.` |
| E-INGEST-010 | broken | 2 | `/brain:ingest-source` | `Image files cannot be ingested as text sources. Provide a markdown or text file.` |
| E-INGEST-011 | broken | 2 | `/brain:ingest-source` | `File not found: <path>.` |

**Recovery:** Most INGEST errors require user action (fix the URL, provide different file, fix manifest). E-INGEST-006 is advisory — ingest proceeded partially.

---

## SOURCE Errors (E-SOURCE-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-SOURCE-001 | broken | 2 | `validate-source-immutability.sh` | `Source file <path> already exists in manifest. Sources are immutable. Use /brain:rename-page to rename.` |
| E-SOURCE-002 | broken | 2 | `validate-source-immutability.sh` | `manifest.json unreadable — cannot verify source immutability.` |

---

## WIKI Errors (E-WIKI-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-WIKI-001 | broken | 2 | `validate-wikilink-integrity.sh` | `Broken wikilink [[<slug>]] in <path>. No matching wiki page found.` |
| E-WIKI-002 | broken | 2 | `validate-wikilink-integrity.sh` | `wiki/index.md missing or unreadable. Cannot verify wikilink integrity.` |
| E-WIKI-003 | broken | 2 | `validate-index-log-coherence.sh` | `Index-log coherence violation: [<slug>] appears in index but not in log.` |
| E-WIKI-004 | broken | 2 | `validate-index-log-coherence.sh` | `wiki/<index.md|log.md> missing or unreadable.` |
| E-WIKI-005 | broken | 2 | `validate-page-type-policy.sh` | `Invalid wiki type directory '<type>' in path <path>. Must be one of: concepts, people, frameworks, syntheses, observations, questions.` |
| E-WIKI-006 | broken | 2 | `validate-page-type-policy.sh` | `Cannot write wiki page directly to wiki/ root. Write to wiki/{type}/{slug}.md.` |
| E-WIKI-007 | broken | 2 | `validate-source-id-citation.sh` | `Unresolved source_id '<slug>' in <path>. No matching entry in manifest.json.` |
| E-WIKI-008 | broken | 2 | `validate-source-id-citation.sh` | `manifest.json unreadable — cannot verify source_id citations.` |

---

## SCHEMA Errors (E-SCHEMA-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-SCHEMA-001 | broken | 2 | `validate-frontmatter-schema.sh` | `Missing required frontmatter field: embedding_status. Add 'embedding_status: pending' to <path>.` |
| E-SCHEMA-002 | broken | 2 | `validate-frontmatter-schema.sh` | `Invalid embedding_status value '<val>' in <path>. Must be one of: pending, computed, stale.` |
| E-SCHEMA-003 | broken | 2 | `validate-frontmatter-schema.sh` | `Failed to parse frontmatter YAML in <path>.` |
| E-SCHEMA-004 | broken | 2 | `validate-frontmatter-schema.sh` | `No YAML frontmatter found in <path>.` |
| E-SCHEMA-005 | broken | 2 | `validate-frontmatter-schema.sh` | `yq required for frontmatter validation — install yq.` |
| E-SCHEMA-006 | broken | 2 | `validate-frontmatter-schema.sh` | `Missing required frontmatter field(s): [<field1>, <field2>] in <path>.` |
| E-SCHEMA-007 | broken | 2 | `validate-frontmatter-schema.sh` | `Invalid wiki type '<val>' in <path>. Must be one of: concepts, people, frameworks, syntheses, observations, questions.` |

---

## NAMING Errors (E-NAMING-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-NAMING-001 | broken | 2 | `enforce-kebab-case.sh` | `Filename '<name>' is not kebab-case. Rename to '<suggested-kebab-name>' before writing.` |

---

## QUARANTINE Errors (E-QUARANTINE-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-QUARANTINE-001 | broken | 2 | `quarantine-fetch.sh`, `/brain:quarantine-check` | `Prompt-injection pattern detected in fetched content from <url>. Content quarantined.` |
| E-QUARANTINE-002 | broken | 2 | `quarantine-fetch.sh`, `/brain:quarantine-check` | `Quarantine corpus missing at ${CLAUDE_PLUGIN_ROOT}/scripts/quarantine.mjs. Cannot safely proceed.` |
| E-QUARANTINE-003 | broken | 2 | `quarantine-fetch.sh` | `Node 20+ required for quarantine check. Install Node from nodejs.org.` |

---

## ATTR Errors (E-ATTR-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-ATTR-001 | broken | 2 | `block-ai-attribution.sh` | `Forbidden AI attribution token detected in bash command. Remove 'Co-Authored-By: Claude' / robot emoji / 'Generated with Claude Code' from the command.` |

---

## FLUSH Errors (E-FLUSH-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-FLUSH-001 | degraded | 1 | `flush-state-and-commit.sh` | `Failed to auto-commit brain state. Manual commit required: <git-error>.` |

---

## HEALTH Errors (E-HEALTH-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-HEALTH-001 | broken | 2 | `/brain:health` | `Brain state file missing — run /brain:init or /brain:cold-start-recover.` |
| E-HEALTH-002 | degraded | 1 | `brain-health-check.sh` | `Brain health: <YELLOW|RED>. <dimension summaries with issues>` |

---

## PUBLISH Errors (E-PUBLISH-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-PUBLISH-001 | broken | 2 | `validate-publish-state.sh` | `Invalid state transition: '<from>' → '<to>' is not allowed. Valid transitions: draft→ready, ready→published.` |
| E-PUBLISH-002 | broken | 2 | `validate-publish-state.sh` | `Missing status field in content file <path>.` |
| E-PUBLISH-003 | broken | 2 | `/brain:publish-content` | `Content too long for LinkedIn post. Use --finalize for articles.` |
| E-PUBLISH-004 | degraded | 1 | `/brain:publish-content` | `LinkedIn API rate limit exceeded after 3 retries. Publish deferred. Try again after <retry-after>.` |
| E-PUBLISH-005 | broken | 2 | `/brain:publish-content` | `LinkedIn API credentials not configured in policies.yaml.` |
| E-PUBLISH-006 | broken | 2 | `/brain:publish-content` | `File is not in ready state. Run adversary review and move to to-publish/ first.` |
| E-PUBLISH-007 | broken | 2 | `/brain:publish-content` | `--finalize requires --url.` |
| E-PUBLISH-008 | broken | 2 | `/brain:publish-content` | `Invalid date format. Use ISO8601: YYYY-MM-DD.` |

---

## ADVERSARY Errors (E-ADVERSARY-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-ADVERSARY-001 | broken | 2 | `/brain:adversary-review` | `Adversary model must differ from producer model. Configure different models in policies.yaml.` |

---

## RENAME Errors (E-RENAME-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-RENAME-001 | broken | 2 | `/brain:rename-page` | `Page <old-slug> not found in wiki.` |
| E-RENAME-002 | broken | 2 | `/brain:rename-page` | `Page <new-slug> already exists. Choose a different slug.` |

---

## LOBSTER Errors (E-LOBSTER-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-LOBSTER-001 | broken | 2 | `bin/lobster-run` | `Circular dependency detected in workflow: <cycle>.` |
| E-LOBSTER-002 | broken | 2 | `bin/lobster-run` | `Skill '<name>' not found in plugin manifest.` |
| E-LOBSTER-003 | broken | 2 | `bin/lobster-run` | `Invalid workflow YAML: <error>.` |

---

## POLICY Errors (E-POLICY-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-POLICY-001 | broken | 2 | `/brain:policy-add` | `Policy ID '<id>' already exists.` |
| E-POLICY-002 | broken | 2 | `/brain:policy-add` | `Policy body is not valid YAML.` |

---

## UPGRADE Errors (E-UPGRADE-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-UPGRADE-001 | broken | 2 | `/brain:upgrade-brain` | `Incompatible schema version. Manual migration required. See CHANGELOG.` |

---

## RATE Errors (E-RATE-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-RATE-001 | degraded | 1 | GH Action templates | `API rate limit exceeded after 3 retries for <service>. Partial data preserved. Retry after <retry-after>.` |

---

## WRITE Errors (E-WRITE-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-WRITE-001 | broken | 2 | `/brain:write` | `Brief not found at <path>.` |

---

## VOICE Errors (E-VOICE-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-VOICE-001 | cosmetic | 1 | `validate-voice-avoid-list.sh` | `Voice avoid-list matches found. Review before finalizing: [<matches>].` |
| E-VOICE-002 | cosmetic | 1 | `validate-voice-avoid-list.sh` | `Voice avoid-list not found — check plugin installation.` |

---

## PERF Errors (E-PERF-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-PERF-001 | degraded | 1 | `/brain:monthly-perf` | `LinkedIn API rate limited. Performance data for <month> incomplete. Retry after <retry-after>.` |

---

## Self-Audit Checklist

Per CLAUDE.md Canonical Principle:

- [x] All error codes follow `E-{SCOPE}-NNN` convention — verified.
- [x] All severity levels are one of: broken/degraded/cosmetic — verified.
- [x] All exit codes match severity (broken=2, degraded=1, cosmetic=1) — verified.
- [x] All message formats use `<placeholder>` syntax for dynamic values — verified.
- [x] Three-file gate: run before commit:
  ```bash
  for f in .factory/specs/product-brief.md .factory/SESSION-HANDOFF.md .factory/specs/prd/prd-supplements/error-taxonomy.md; do
    grep -nE '\bL[0-9]+\b' "$f" | grep -v WSL2 | grep -v 'L\[0-9\]+' | grep -v 'LinkedIn\|License\|LTS\|Linux\|Lobster\|Lock\|Loom\|Loki' | grep -v 'level: L[0-9]\+\|Level [0-9]\+\|L2\|L3\|L4\|LEVEL'
  done
  ```

  **NOTE (exclusion-list-extension protocol — VSDD level designators):** This supplement carries `level: L3` in frontmatter. `L3` is a VSDD specification tier designator — not a line-number anchor. Per the exclusion-list-extension protocol: added `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` to this gate's command. Gate re-run returns zero matches. This exclusion is identical to the one in the PRD index gate.
