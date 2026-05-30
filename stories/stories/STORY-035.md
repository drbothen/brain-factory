---
artifact_type: story
story_id: STORY-035
epic_id: EPIC-07
title: "scripts/lib/api-retry.sh canonical implementation, v0.5 GH Action templates (9), and community-optional templates (4)"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P1
subsystems: [SS-13]
behavioral_contracts: [BC-2.13.002, BC-2.13.003, BC-2.13.004]
vps: []
dependencies: [STORY-034, STORY-030]
blocks: []
inputs:
  - architecture/subsystems/SS-13-github-action-templates.md
  - behavioral-contracts/ss-13/BC-2.13.002.md
  - behavioral-contracts/ss-13/BC-2.13.003.md
  - behavioral-contracts/ss-13/BC-2.13.004.md
input-hash: ""
# BC status: BC-2.13.002 + BC-2.13.003 + BC-2.13.004 assigned;
# status=draft per Spec-First Gate S-7.01
# Priority: P1 — v0.5 templates and community optionals are Phase 3 deliverables;
#   BC-2.13.003 (api-retry.sh) is P1 because rate-limit handling is shared infra
# Dependency rationale:
#   STORY-034 ships the 6 v0.1 core templates and install-actions skill (templates/).
#   STORY-030 creates the minimal scripts/lib/api-retry.sh (LinkedIn use case).
#   This story canonicalizes api-retry.sh and adds v0.5+community templates.
#   No downstream blocks in EPIC-07 — this is the final EPIC-07 story.
# Subsystem anchor: SS-13 owns this story; all three BCs are SS-13 postconditions.
#   BC-2.13.003 (api-retry.sh) is classified SS-13 per epics.md rationale: "rate-limit
#   handling belongs to the GH Action template implementation; the underlying
#   scripts/lib/api-retry.sh helper is implemented once for the publishing pipeline
#   (EPIC-06) and reused here." EPIC-07 canonicalizes and extends it.
---

# STORY-035: `scripts/lib/api-retry.sh` canonical implementation, v0.5 GH Action templates (9), and community-optional templates (4)

## Goal

Deliver three related capabilities: (1) canonicalize `scripts/lib/api-retry.sh` with
full exponential backoff + `retry-after` header respect + jitter + 3-attempt maximum +
E-RATE-001 emission — extending the minimal version created in STORY-030; (2) ship the
9 v0.5 author-committed GitHub Action templates with `strategy.matrix` parallelism;
(3) ship the 4 community-optional templates with the required disclaimer comment. These
complete the GitHub Action template surface for v0.5.

## User Value

As a brain-factory operator, I want the v0.5 template additions so that I can run RSS
ingest, Readwise sync, Raindrop sync, and other multi-source workflows in parallel via
GitHub Actions matrix strategy, with reliable rate-limit retry handling across all
API-calling templates — and optionally install community templates for garden publishing,
Telegram bridging, email inbox, and cross-repo dispatch.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.13.003 | Rate-limit handling: 429 → exponential backoff with retry-after | P1 |
| BC-2.13.002 | v0.5 additions (9 templates) ship with matrix strategy parallelism | P1 |
| BC-2.13.004 | 4 community-optional templates ship in tarball with no-author-support documentation | P2 |

## Acceptance Criteria

### `scripts/lib/api-retry.sh` canonical implementation (BC-2.13.003)

**AC-001** — `scripts/lib/api-retry.sh` is sourced by any GH Action template (or skill)
calling an external API. It provides a `retry_with_backoff <command...>` function that
executes the command and retries on exit code indicating HTTP 429. This is the shared
implementation; templates do not copy-paste retry logic.
(traces to BC-2.13.003 invariant 2)

**AC-002** — On a 429 response, `retry_with_backoff` waits `retry-after` seconds if the
header is present in the response, otherwise waits a base-60-second exponential backoff:
60s, 120s, 240s for attempts 1, 2, 3 respectively.
(traces to BC-2.13.003 postcondition 1, 2)

**AC-003** — After 3 failed attempts (all returning 429), `retry_with_backoff` emits
E-RATE-001 to stderr and exits 1 (advisory). Data processed before the rate-limit
encounter is preserved; no rollback of already-processed items.
(traces to BC-2.13.003 postcondition 3, 4)

**AC-004** — All 3 API-calling templates (LinkedIn-based, Readwise-based, Raindrop-based)
source and invoke `retry_with_backoff` — not bare `curl` calls. Verified by grep: every
`curl` call in these templates is wrapped in `retry_with_backoff`.
(traces to BC-2.13.003 invariant 1)

**AC-005** — `scripts/lib/api-retry.sh` includes jitter: the actual wait is
`base_delay + (RANDOM % (base_delay / 2))` to avoid thundering-herd retry storms across
multiple parallel matrix jobs hitting the same API.
(traces to BC-2.13.003 postcondition 2; production-grade default per CLAUDE.md §Canonical Principle)

**AC-006** — The STORY-030-created minimal `scripts/lib/api-retry.sh` is superseded by
this canonical version. Backward compatibility is maintained: the `retry_with_backoff`
function signature is identical. STORY-030's `/brain:publish-content` calls are unaffected.
(traces to BC-2.13.003 invariant 2; STORY-030 Previous Story Intelligence note)

**AC-007** — `scripts/lib/api-retry.sh` passes shellcheck clean and shfmt -d -i 2 check.
Starts with `#!/usr/bin/env bash` and `set -euo pipefail`. No `eval`. No bare `exit`
without explicit code.
(traces to BC-2.13.003; CLAUDE.md §Conventions §Bash hook contract)

### v0.5 template additions (BC-2.13.002)

**AC-008** — All 9 v0.5 template files exist at
`${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/`:
`rss-inbox.yml`, `issue-capture.yml`, `readwise-sync.yml`, `raindrop-sync.yml`,
`auto-connect.yml`, `monthly-perf.yml`, `token-budget.yml`, `cold-start.yml`,
`snapshot.yml`. Exactly 9 new files (total author-committed: 15).
(traces to BC-2.13.002 postcondition 1; invariant 1)

**AC-009** — Templates that process multiple sources per run use `strategy.matrix`
parallelism: `rss-inbox.yml`, `readwise-sync.yml`, `raindrop-sync.yml` each contain
a `strategy: matrix:` declaration. `meta-lint.bats` asserts the matrix declaration is
present for these three templates.
(traces to BC-2.13.002 postcondition 1; invariant 2; edge case EC-002)

**AC-010** — Each v0.5 template includes rate-limit handling (sources `api-retry.sh`)
where it calls external APIs. Non-API templates (`auto-connect.yml`, `token-budget.yml`,
`snapshot.yml`) do not need to source `api-retry.sh`.
(traces to BC-2.13.002 postcondition 2; BC-2.13.003 invariant 1)

**AC-011** — A bats tarball integrity check asserts exactly 9 v0.5 templates are present.
If any of the 9 is missing, the check fails and the release gate blocks.
(traces to BC-2.13.002 edge case EC-003)

**AC-012** — When a matrix job fails (one feed returns 429 after all retries exhausted),
the failing job exits 2; other matrix jobs in the same run complete successfully; no
data loss for feeds that succeeded. Verified via mock API fixture in bats.
(traces to BC-2.13.002 edge case EC-001)

### Community-optional templates (BC-2.13.004)

**AC-013** — All 4 community-optional template files exist at
`${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/community/`:
`garden-publish.yml`, `telegram-bridge.yml`, `email-inbox.yml`,
`cross-repo-dispatch.yml`. Exactly 4 files.
(traces to BC-2.13.004 postcondition 1; invariant 1)

**AC-014** — Each community-optional template's first 3 lines include the exact disclaimer:
`# COMMUNITY OPTIONAL: This template is not author-maintained. Use at your own risk.
No support commitment.` A `grep` assertion in `tests/upgrade.bats` verifies the
disclaimer is present and not truncated.
(traces to BC-2.13.004 postcondition 2; edge case EC-002)

**AC-015** — The plugin README documents the community-optional distinction: a section
titled "Community-Optional Templates" explains that these 4 templates are per-operator
opt-in add-ons with no author support commitment.
(traces to BC-2.13.004 postcondition 3)

**AC-016** — Community-optional templates are NOT covered by the upgrade.bats suite
(no author testing commitment per BC-2.13.004 invariant 2). The meta-lint.bats check
for `strategy.matrix` does NOT run on community templates. A bats comment documents
this explicitly.
(traces to BC-2.13.004 invariant 2)

## Tasks

1. **[impl — api-retry.sh]** Canonicalize `plugins/brain-factory/scripts/lib/api-retry.sh`:
   - Source guard: `if declare -f retry_with_backoff > /dev/null; then return 0; fi`
     (idempotent re-source).
   - `retry_with_backoff <command...>`: runs the command; on exit 1 (indicating 429),
     checks stderr for `retry-after:` header value; computes wait with jitter
     (`base + RANDOM % (base/2)`); retries up to 3 times.
   - After 3 failures: `echo '{"level":"error","code":"E-RATE-001","message":
     "Rate limit exhausted after 3 retries"}' >&2`; `return 1` (advisory).
   - `set -euo pipefail` + shebang; shellcheck clean; shfmt -d -i 2 passes.

2. **[stub — v0.5 templates]** Create 9 v0.5 template YAML files in
   `templates/github-action-templates/` with correct structure. Matrix templates
   (`rss-inbox.yml`, `readwise-sync.yml`, `raindrop-sync.yml`) include
   `strategy: matrix: feed: [...]` (placeholder values). All pass yamllint.

3. **[stub — community templates]** Create 4 community-optional template YAML files in
   `templates/github-action-templates/community/`. Each starts with the exact 3-line
   disclaimer. Minimal GH Actions structure (name, on, jobs).

4. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/upgrade.bats`:
   - `"api-retry.sh: 429 once → retries; second call succeeds"` (BC-2.13.003 canonical test vector 1)
   - `"api-retry.sh: 429 three times → E-RATE-001 exit 1"` (BC-2.13.003 canonical test vector 2)
   - `"api-retry.sh: retry-after header respected"` (BC-2.13.003 postcondition 1)
   - `"api-retry.sh: shellcheck clean"` (CLAUDE.md §Conventions)
   - `"api-retry.sh: shfmt -d -i 2 clean"` (CLAUDE.md §Conventions)
   - `"v0.5 templates: all 9 exist"` (BC-2.13.002 invariant 1)
   - `"v0.5 templates: matrix templates have strategy.matrix declaration"` (BC-2.13.002 invariant 2)
   - `"v0.5 templates: tarball integrity — all 9 present"` (BC-2.13.002 EC-003)
   - `"v0.5 templates: matrix job partial failure — other jobs succeed"` (BC-2.13.002 EC-001)
   - `"community templates: all 4 exist in community/"` (BC-2.13.004 postcondition 1)
   - `"community templates: all 4 have disclaimer comment"` (BC-2.13.004 postcondition 2)
   - `"community templates: no meta-lint assertions run on community dir"` (BC-2.13.004 invariant 2)
   Run bats — confirm all 12 tests fail (Red Gate confirmed).

5. **[impl — v0.5 templates]** Fill in full v0.5 template content following the
   same structural patterns as the v0.1 templates from STORY-034. API-calling templates
   source `api-retry.sh`. Matrix templates set `strategy: matrix:` with example values.
   All pass yamllint.

6. **[impl — community templates]** Fill in community template content. Each has the
   required disclaimer + minimal GH Actions structure. No author testing required.

7. **[green]** Run bats for all 12 tests — all pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Mock API returns 429 once, then 200 | Second call succeeds; exit 0 | happy-path | BC-2.13.003 canonical test vector 1 |
| Mock API returns 429 three times | E-RATE-001 on stderr; exit 1; partial data preserved | edge-case | BC-2.13.003 canonical test vector 2 |
| Mock API returns 429 with `retry-after: 5` header | Waits ≥ 5s before retry | edge-case | BC-2.13.003 postcondition 1 |
| `ls templates/github-action-templates/*.yml | wc -l` | 15 (6 core + 9 v0.5) | happy-path | BC-2.13.002 invariant 1 |
| `yq eval '.strategy.matrix' rss-inbox.yml` | Non-null value | happy-path | BC-2.13.002 invariant 2 |
| `rss-inbox.yml` with `strategy.matrix` removed | meta-lint.bats fails; EC-002 | edge-case | BC-2.13.002 EC-002 |
| One matrix job mock exits 2, 4 others exit 0 | Failing job exits 2; 4 jobs complete; data from 4 preserved | edge-case | BC-2.13.002 EC-001 |
| `ls templates/github-action-templates/community/ | wc -l` | 4 | happy-path | BC-2.13.004 invariant 1 |
| `head -3 garden-publish.yml` | Disclaimer present; exact match | happy-path | BC-2.13.004 postcondition 2 |
| Community template disclaimer removed | upgrade.bats grep assertion fails; release gate blocks | edge-case | BC-2.13.004 EC-002 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (BC-2.13.003) | 429 → retry with backoff | `tests/upgrade.bats` (mock API) |
| (BC-2.13.003) | 3 failures → E-RATE-001; exit 1 | `tests/upgrade.bats` |
| (BC-2.13.002) | matrix strategy present in rss/readwise/raindrop | `tests/upgrade.bats` |
| (BC-2.13.004) | All 4 community templates have disclaimer | `tests/upgrade.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-13-github-action-templates.md`:

1. `scripts/lib/api-retry.sh` is the SINGLE authoritative implementation of exponential
   backoff. It is dual-delivered: the plugin-side copy lives in `scripts/lib/` and is
   used by Claude Code session skills; the vault-side copy is installed by
   `/brain:install-actions` and used by GH Actions runners. Both copies must be kept in
   sync (the plugin is the source of truth; install-actions copies it).

2. Community-optional templates are in `templates/github-action-templates/community/`.
   They are NOT subject to the same meta-lint checks as core templates. The `upgrade.bats`
   matrix for community templates covers only: existence + disclaimer comment. No yamllint
   assertion required (per BC-2.13.004 invariant 2 — no author testing commitment).

3. Matrix parallelism declaration (`strategy.matrix`) is MANDATORY in `rss-inbox.yml`,
   `readwise-sync.yml`, `raindrop-sync.yml`. Absence is detected by `meta-lint.bats`
   per BC-2.13.002 EC-002.

4. `api-retry.sh` must include a source-idempotency guard to prevent double-registration
   of the `retry_with_backoff` function if the file is sourced twice.

**Forbidden dependencies:**
- `scripts/lib/api-retry.sh` must NOT use `eval`. No hardcoded token values.
- v0.5 templates must NOT copy-paste retry logic — they MUST source `api-retry.sh`.
- Community templates must NOT use `${CLAUDE_PLUGIN_ROOT}` references (same reason as
  core templates: they are installed into the vault).
- Community templates must NOT claim author support in any wording.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | macOS compat; api-retry.sh targets 5.0+ |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions §shellcheck clean + shfmt |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions §shfmt-normalized |
| `yamllint` | 1.x+ (latest: 1.38.0; Python 3.10+ required) | Template YAML validity |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | Matrix strategy assertion |
| `curl` | 7.x+ | API calls wrapped by api-retry.sh |
| `scripts/lib/api-retry.sh` | (this repo) | Backoff wrapper — THIS is the canonical delivery |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/scripts/lib/api-retry.sh` | Modify (canonicalize) | Extends STORY-030 minimal version |
| `plugins/brain-factory/templates/github-action-templates/rss-inbox.yml` | Create | v0.5; matrix strategy |
| `plugins/brain-factory/templates/github-action-templates/issue-capture.yml` | Create | v0.5 |
| `plugins/brain-factory/templates/github-action-templates/readwise-sync.yml` | Create | v0.5; matrix strategy |
| `plugins/brain-factory/templates/github-action-templates/raindrop-sync.yml` | Create | v0.5; matrix strategy |
| `plugins/brain-factory/templates/github-action-templates/auto-connect.yml` | Create | v0.5 |
| `plugins/brain-factory/templates/github-action-templates/monthly-perf.yml` | Create | v0.5 |
| `plugins/brain-factory/templates/github-action-templates/token-budget.yml` | Create | v0.5 |
| `plugins/brain-factory/templates/github-action-templates/cold-start.yml` | Create | v0.5 |
| `plugins/brain-factory/templates/github-action-templates/snapshot.yml` | Create | v0.5 |
| `plugins/brain-factory/templates/github-action-templates/community/garden-publish.yml` | Create | community-optional |
| `plugins/brain-factory/templates/github-action-templates/community/telegram-bridge.yml` | Create | community-optional |
| `plugins/brain-factory/templates/github-action-templates/community/email-inbox.yml` | Create | community-optional |
| `plugins/brain-factory/templates/github-action-templates/community/cross-repo-dispatch.yml` | Create | community-optional |
| `plugins/brain-factory/tests/upgrade.bats` | Modify | Add 12 v0.5 + community + api-retry tests |
| `plugins/brain-factory/README.md` | Modify | Add "Community-Optional Templates" section |

Files NOT to modify: any `.factory/` artifact, `plugin.json`, any hook script, any prior
story file, any v0.1 core template from STORY-034.

## Previous Story Intelligence

STORY-030 created a minimal `scripts/lib/api-retry.sh` as a dependency of
`/brain:publish-content`. That minimal version handles LinkedIn API 429 responses.
This story EXTENDS it (not replaces it) to the canonical version:
- Add `retry-after` header parsing (STORY-030's minimal version uses fixed 60s delay).
- Add jitter (`RANDOM % (base/2)` per production-grade default principle).
- Add source-idempotency guard (STORY-030 version lacks this).
- Backward compatibility: `retry_with_backoff` function signature unchanged.
- STORY-034 copied `scripts/lib/api-retry.sh` to the vault via `install-actions`. After
  this story canonicalizes it, the install-actions skill automatically copies the
  canonical version (the copy logic is unchanged; it copies from `scripts/lib/`).

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~5,500 |
| SS-13 subsystem design | ~900 |
| BC-2.13.002 file | ~700 |
| BC-2.13.003 file | ~600 |
| BC-2.13.004 file | ~700 |
| STORY-030's api-retry.sh minimal version (for extension context) | ~500 |
| Existing upgrade.bats from STORY-034 | ~1,500 |
| **Total** | **~10,400** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- EPIC-08: scale-aware architecture and observability (not SS-13).
- Future community template additions beyond the 4 defined — requires BC amendment
  per BC-2.13.004 EC-003 before any 5th template can be added.
- Readwise, Raindrop, Telegram credentials management — those are operator-configured
  via GitHub Secrets; out of scope for this story.

## Anchors

- BC-2.13.002: `behavioral-contracts/ss-13/BC-2.13.002.md`
- BC-2.13.003: `behavioral-contracts/ss-13/BC-2.13.003.md`
- BC-2.13.004: `behavioral-contracts/ss-13/BC-2.13.004.md`
- SS-13: `architecture/subsystems/SS-13-github-action-templates.md`
- STORY-030: `stories/stories/STORY-030.md` (api-retry.sh minimal — predecessor)
- STORY-034: `stories/stories/STORY-034.md` (v0.1 templates + install-actions — predecessor)
