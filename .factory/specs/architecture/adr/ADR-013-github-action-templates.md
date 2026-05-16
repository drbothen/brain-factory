---
document_type: adr
id: ADR-013
title: "GitHub Action templates strategy: 19 total templates across v0.x (15 author + 4 community-optional)"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-013: GitHub Action templates strategy

## Count Disambiguation Note

The planning artifact `plugin-plan.md` references 18 GitHub Action templates in several
places. This ADR and PRD §1.2 are authoritative for the operational count: 19 templates
total (15 author-committed + 4 community-optional opt-in). The discrepancy arose because
the PRD elaborated the community-optional set from the original planning estimate. Per
CLAUDE.md Source-of-Truth Precedence, PRD and architecture supersede planning artifacts
for operational counts. `plugin-plan.md` is immutable (brain-factory-001) and records
the original planning intent; this ADR records the authoritative resolved count of 19.

## Context

brain-factory ships GH Action templates that operators install into their brain vault's `.github/workflows/` directory via `/brain:install-actions`. The PRD commits to 19 templates total: 15 author-committed (full support) + 4 community-optional (tarball-only, no author support). The v0.1 core set is 6 templates (BC-2.13.001); the v0.5 addition is 9 more (BC-2.13.002); the 4 community-optional ship with the tarball in v0.x (BC-2.13.004).

## Decision

### Template inventory

**v0.1 core set (6 templates — author-committed, full support):**
1. `daily-brief.yml` — scheduled daily: runs `/brain:daily-brief` headlessly
2. `weekly-refresh.yml` — scheduled weekly: runs `/brain:weekly-refresh` headlessly
3. `ingest-rss.yml` — triggered on schedule: ingests new RSS feed items from `feeds.yaml`
4. `health-check.yml` — scheduled: runs `/brain:health`; posts summary to Actions summary
5. `lint-wiki.yml` — scheduled: runs `/brain:lint-wiki`; fails workflow if broken links found
6. `scale-test.yml` — manual trigger (workflow_dispatch): runs full scale test suite

**v0.5 additions (9 templates — author-committed, full support):**
7. `quarterly-mirror.yml` — quarterly: runs `/brain:quarterly-mirror`
8. `publish-scheduled.yml` — scheduled: publishes content with `status: ready` in `to-publish/`
9. `monthly-perf.yml` — monthly: runs `/brain:monthly-perf`
10. `cold-start-recover.yml` — manual trigger: runs `/brain:cold-start-recover`
11. `export-brain.yml` — manual trigger: runs `/brain:export-brain`
12. `adversary-review.yml` — manual trigger (file path input): runs `/brain:adversary-review`
13. `connect.yml` — scheduled: runs `/brain:connect 7`
14. `synthesize.yml` — scheduled (after connect): runs `/brain:synthesize`
15. `upgrade-brain.yml` — manual trigger: runs `/brain:upgrade-brain`

**Community-optional (4 templates — tarball-only, no author support per PRD §1.5):**
16. `telegram-bridge.yml` — reads Telegram messages, ingests into inbox
17. `email-inbox.yml` — reads IMAP inbox, ingests into inbox
18. `cross-repo-dispatch.yml` — dispatches ingest events from other repos
19. `garden-publish.yml` — publishes wiki as a digital garden static site

### Template generation and materialization

Templates are hand-authored YAML files in `plugins/brain-factory/templates/github-action-templates/`. They are NOT generated programmatically. Rationale: YAML GH Actions templates are human-readable declarations; programmatic generation adds complexity without reducing the risk of drift.

Templates are materialized into the user's brain vault by `/brain:install-actions`, which copies the selected templates from `${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/` to the vault's `.github/workflows/`. The user can customize the copies; they are not linked back to the plugin.

### Rate-limit handling (BC-2.13.003)

All GH Action templates that call external APIs (LinkedIn Posts API, RSS feeds, IMAP) implement exponential backoff with `retry-after` header respect:
- On 429 response: read `Retry-After` header (seconds) or default to 60 seconds
- Exponential backoff: 1s, 2s, 4s, 8s... cap at 300s
- Max retries: 5 before failing the workflow step
Implemented via `scripts/lib/api-retry.sh` (ADR-016 §api-retry.sh Delivery for GitHub Actions), which all API-calling GH Action templates invoke. GH Actions runners use the `scripts/lib/` copy installed by `/brain:install-actions`; the `hooks/lib/api-retry.sh` version is used exclusively by hook scripts in the Claude Code session context.

### v0.1 ship gate

BC-2.13.001 requires the v0.1 core set (6 templates) to "run green on push." This means:
- The templates are valid GitHub Actions YAML (yamllint clean)
- The templates run successfully in the CI matrix (`ubuntu-latest`) against the smoke-brain fixture
- No template hard-codes a path or token that breaks in a fresh brain vault

## Consequences

**Positive:**
- 6 v0.1 templates are validated in CI before any user installs the plugin
- Rate-limit handling is centralized in api-retry.sh — not duplicated across 19 templates
- Community-optional templates ship without blocking author-supported features

**Negative:**
- Hand-authored templates must be kept in sync with skill interface changes; meta-lint does NOT currently scan template YAML for skill invocations. This is an accepted gap — templates are tested in CI, which catches breakage.
- 4 community-optional templates carry the "no author support" disclaimer in their headers; this must be enforced editorially (no CI enforcement)

**Neutral:**
- The `/brain:install-actions` skill lets operators choose which templates to install; not all 19 are installed by default

## References

- PRD §1.2 (v0.x ships 19 GitHub Action templates: 15 author + 4 community-optional)
- PRD §1.5 (out of scope: 4 community-optional templates as author-maintained features)
- BC-2.13.001 (v0.1 core set: 6 templates run green on push)
- BC-2.13.002 (v0.5 additions: 9 templates with matrix strategy parallelism)
- BC-2.13.003 (rate-limit handling: 429 exponential backoff)
- BC-2.13.004 (4 community-optional templates in tarball)
- ADR-016 (api-retry.sh shared helper)
