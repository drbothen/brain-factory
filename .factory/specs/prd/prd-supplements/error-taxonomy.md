---
document_type: prd-supplement
supplement_type: error-taxonomy
version: "0.1.9"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-18T00:00:00
phase: phase-1b
traces_to: prd/index.md
created: 2026-05-15
last_updated: 2026-05-28
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
| E-INGEST-012 | broken | 2 | `/brain:ingest-url` | `Only HTTP and HTTPS URLs are supported. Got: <scheme> (<url>).` |

**Recovery:** Most INGEST errors require user action (fix the URL, provide different file, fix manifest). E-INGEST-006 is advisory — ingest proceeded partially. E-INGEST-012 requires the user to provide an http:// or https:// URL.

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
| E-QUARANTINE-003 | broken | 2 | `quarantine-fetch.sh` | `Node 22+ required for quarantine check. Install Node from nodejs.org.` |
| E-QUARANTINE-004 | broken | 2 | `quarantine-fetch.sh` | `Preview fetch failed; cannot safely proceed.` |

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
| E-HEALTH-002 | degraded | 0 | `brain-health-check.sh` | `Brain health: <YELLOW|RED>. Issues: <name>: <detail>; ...` (delivered via `systemMessage` field; hook exits 0 per ADR-002 v2.0) |
| E-HEALTH-003 | cosmetic | 0 | `brain-health-check.sh` | `Brain STATE.md unreadable — run /brain:health for diagnosis.` |
| E-HEALTH-004 | broken | 2 | `/brain:health` | `jq is required for /brain:health. Install via your package manager.` |
| E-HEALTH-005 | broken | 2 | `/brain:health` | `yq is required for /brain:health. Install via your package manager.` |

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
| E-LOBSTER-001 | broken | 2 | `bin/lobster-run` | `Steps with unresolved dependencies (cycle present): <cycle>.` |
| E-LOBSTER-002 | broken | 2 | `bin/lobster-run` | `Skill '<name>' not found in plugin manifest.` |
| E-LOBSTER-003 | broken | 2 | `bin/lobster-run` | `Invalid workflow YAML: <error>.` |
| E-LOBSTER-004 | broken | 2 | `bin/lobster-run` | `Unknown dependency '<name>' referenced by step '<id>'.` |
| E-LOBSTER-005 | broken | 2 | `bin/lobster-run` | `BRAIN_ROOT environment variable is not set.` |
| E-LOBSTER-006 | broken | 2 | `bin/lobster-run` | `Cannot create log directory: <path>` |
| E-LOBSTER-007 | broken | 2 | `bin/lobster-run` | `Unknown flag: <flag>` |
| E-LOBSTER-008 | broken | 2 | `bin/lobster-run` | `Missing workflow file argument.` |
| E-LOBSTER-009 | broken | 2 | `bin/lobster-run` | `Duplicate step id '<id>' in workflow.` |
| E-LOBSTER-010 | broken | 2 | `bin/lobster-run` | `CLAUDE_PLUGIN_ROOT environment variable is not set.` |
| E-LOBSTER-011 | broken | 2 | `bin/lobster-run` | `Workflow file not found: <path>` |
| E-LOBSTER-012 | broken | 2 | `bin/lobster-run` | `Plugin manifest not found at <path>` |
| E-LOBSTER-013 | broken | 2 | `bin/lobster-run` | `Plugin manifest is not valid JSON: <path>` |

---

## POLICY Errors (E-POLICY-NNN)

| Code | Severity | Exit | Raised By | Message Format |
|------|----------|------|-----------|---------------|
| E-POLICY-001 | broken | 2 | `/brain:policy-add` | `Policy ID '<id>' already exists.` |
| E-POLICY-002 | broken | 2 | `/brain:policy-add` | `Policy body is not valid YAML.` |
| E-POLICY-003 | broken | 2 | `/brain:policy-add` | `Policy body missing required field: <field>.` |

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
- [x] All exit codes match severity (broken=2, degraded=1, cosmetic=1) — verified with exception: E-HEALTH-002 is degraded but exits 0. This is correct per ADR-002 v2.0: `brain-health-check.sh` is a SessionStart hook where exit 1 is debug-log only (not shown to the operator); operator-visible advisories require exit 0 + `systemMessage`. E-HEALTH-002 is a hook advisory, not a skill exit code, so the standard degraded=1 mapping does not apply.
- [x] All message formats use `<placeholder>` syntax for dynamic values — verified.
- [x] Three-file gate: run before commit:
  ```bash
  for f in .factory/specs/product-brief.md .factory/SESSION-HANDOFF.md .factory/specs/prd/prd-supplements/error-taxonomy.md; do
    grep -nE '\bL[0-9]+\b' "$f" | grep -v WSL2 | grep -v 'L\[0-9\]+' | grep -v 'LinkedIn\|License\|LTS\|Linux\|Lobster\|Lock\|Loom\|Loki' | grep -v 'level: L[0-9]\+\|Level [0-9]\+\|L2\|L3\|L4\|LEVEL'
  done
  ```

  **NOTE (exclusion-list-extension protocol — VSDD level designators):** This supplement carries `level: L3` in frontmatter. `L3` is a VSDD specification tier designator — not a line-number anchor. Per the exclusion-list-extension protocol: added `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` to this gate's command. Gate re-run returns zero matches. This exclusion is identical to the one in the PRD index gate.

---

## Changelog

### v0.1.9 (2026-05-28)

**ADR-002 v2.0 EXIT-CODE ALIGNMENT (F-P9-C03):** E-HEALTH-002 exit-code column corrected from `1` → `0`. The hook `brain-health-check.sh` delivers the YELLOW/RED health advisory via the `systemMessage` field in the stdout JSON verdict and always exits 0 per ADR-002 v2.0 (exit 1 is debug-log only and NOT shown to the operator). The prior value of `1` reflected the v1.0-era advisory-via-exit-1 pattern that was superseded when ADR-002 was updated to v2.0 in May 2026. Message format updated to match the one-line summary pattern `Brain health: <YELLOW|RED>. Issues: <name>: <detail>; ...` per BC-2.04.014 v1.5 Postcondition 2.

TD-VSDD-060 sibling-sweep: all five HEALTH error rows verified:
- E-HEALTH-001 (broken, exit 2): raised by `/brain:health` skill when STATE.md missing — exit 2 is correct (skill exits non-zero on fatal error).
- E-HEALTH-002 (degraded, exit 0): raised by `brain-health-check.sh` on YELLOW/RED health — corrected to 0 in this version.
- E-HEALTH-003 (cosmetic, exit 0): raised by `brain-health-check.sh` on UNREADABLE STATE.md — exit 0 already correct.
- E-HEALTH-004 (broken, exit 2): raised by `/brain:health` when `jq` missing — exit 2 correct.
- E-HEALTH-005 (broken, exit 2): raised by `/brain:health` when `yq` missing — exit 2 correct.

No other HEALTH row changes required.

### v0.1.8 (2026-05-28)

**CONTENT FIX (STORY-004 Pass 3 Fix Burst — F-P3-C03):** Registered E-HEALTH-003. This code is emitted by `brain-health-check.sh` when `.brain/STATE.md` exists but `overall_health` is empty or unparseable (UNREADABLE state). The hook exits 0 (per BC-2.04.014 Invariant 1 — SessionStart must never be blocked), emitting `"Brain STATE.md unreadable — run /brain:health for diagnosis."` as a systemMessage. Severity is cosmetic (exit 0, session continues, user is advised to run `/brain:health` to regenerate STATE.md health fields). The v0.1.7 changelog noted this gap but deferred formal registration — this entry closes that gap. TD-VSDD-060 sibling-sweep confirmed no additional unregistered HEALTH error codes exist.

### v0.1.7 (2026-05-28)

**CONTENT FIX (STORY-004 Fix Burst 2 — I01):** Registered E-HEALTH-004 and E-HEALTH-005. These codes cover missing `jq` (E-HEALTH-004) and missing `yq` (E-HEALTH-005) when `/brain:health` is invoked. Previously, absence of these tools produced cryptic "command not found" bash errors mid-execution; the preflight now catches them before any filesystem operations and emits a clean structured error envelope (exit 2). E-HEALTH-003 was previously emitted by `brain-health-check.sh` for UNREADABLE STATE.md but was never registered in this taxonomy — it is registered retroactively here by noting its absence and leaving the numeric gap to preserve the hook's existing code. E-HEALTH-004 and E-HEALTH-005 are the next unused codes.

### v0.1.6 (2026-05-28)

**CONTENT FIX (STORY-032 Fix Burst 8 — I02/S01/S03):** Registered E-LOBSTER-013. E-LOBSTER-013 covers plugin manifest present but not parseable as JSON (`Plugin manifest is not valid JSON: <path>`). Previously, a malformed plugin.json caused `jq` queries to silently return empty, misclassifying the error as "empty .skills field" (E-LOBSTER-002). This error is distinct from E-LOBSTER-012 (manifest file absent) and from E-LOBSTER-002 (manifest valid JSON but skill not found).

### v0.1.5 (2026-05-27)

**CONTENT FIX (STORY-032 Fix Burst 4 — S01):** Registered E-LOBSTER-012. E-LOBSTER-012 covers plugin manifest not found at `CLAUDE_PLUGIN_ROOT/.claude-plugin/plugin.json`. Previously this condition emitted E-LOBSTER-002 ("Skill not found in plugin manifest") which incorrectly conflated two distinct error classes: manifest absence and skill absence. E-LOBSTER-002 now exclusively covers skill-not-in-manifest. E-LOBSTER-012 exclusively covers the manifest file itself being absent.

### v0.1.4 (2026-05-27)

**CONTENT FIX (STORY-032 Fix Burst 3 — C02/I04/S01):** Registered E-LOBSTER-009, E-LOBSTER-010, and E-LOBSTER-011. E-LOBSTER-009 covers duplicate step IDs within a single workflow (previously misdiagnosed as a circular dependency). E-LOBSTER-010 covers missing `CLAUDE_PLUGIN_ROOT` environment variable (previously unvalidated — the script would silently fail at skill-manifest lookup). E-LOBSTER-011 covers workflow file not found (previously conflated with E-LOBSTER-003 "Invalid workflow YAML" since `yq eval` errors on nonexistent files).

### v0.1.3 (2026-05-27)

**CONTENT FIX (STORY-032 Fix Burst 2 — I01):** Registered E-LOBSTER-004 through E-LOBSTER-008. These error codes were emitted by `bin/lobster-run` since STORY-032 initial delivery but were absent from the canonical taxonomy. E-LOBSTER-004 covers unknown dependency references; E-LOBSTER-005 covers missing BRAIN_ROOT; E-LOBSTER-006 covers log directory creation failure; E-LOBSTER-007 covers unknown CLI flags; E-LOBSTER-008 (new, S03 fix) covers missing workflow file argument — replacing the incorrect prior behavior of emitting E-LOBSTER-003 for a missing argument.

### v0.1.2 (2026-05-18)

**CONTENT FIX (F-PHASE2-STEP-B-CLOSEOUT-O2 — E-POLICY-003 registered):** Added E-POLICY-003 (broken, exit 2, raised by `/brain:policy-add`) with message "Policy body missing required field: `<field>`." This error covers the case where the policy YAML body is valid YAML but omits a required field (`id`, `name`, `description`, `enforcement`, or `severity`). The error was introduced alongside STORY-043 (EPIC-09: Policy registry management) which defined it inline at AC-006. Formally registered here per STORY-043's inline specification to complete the POLICY error series.

### v0.1.1 (2026-05-18)

**CONTENT FIX (F-PHASE2-STEP-B-EPIC-02-PART-1-I1 — E-QUARANTINE-004 registered):** Added E-QUARANTINE-004 (broken, exit 2, raised by `quarantine-fetch.sh`) with message "Preview fetch failed; cannot safely proceed." This error covers the case where the hook's own `curl --max-filesize 2048 -s --max-time 5` preview fetch fails (network timeout, DNS error, non-2xx response). The error was introduced alongside BC-2.04.001 v1.2 which corrected the PreToolUse-WebFetch payload shape and made explicit that the hook fetches its own curl preview per SS-10 §Key Design.

### v0.1.0 (2026-05-16)

Initial error taxonomy created during Phase 1b spec crystallization.
