---
artifact_type: story
story_id: STORY-030
epic_id: EPIC-06
title: "/brain:publish-content — state machine, LinkedIn API, scheduling, and finalize flow"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-09]
behavioral_contracts: [BC-2.09.001, BC-2.09.002, BC-2.09.003, BC-2.09.004]
vps: [VP-020]
dependencies: [STORY-029, STORY-027]
blocks: [STORY-031]
inputs:
  - architecture/subsystems/SS-09-publishing-pipeline.md
  - behavioral-contracts/ss-09/BC-2.09.001.md
  - behavioral-contracts/ss-09/BC-2.09.002.md
  - behavioral-contracts/ss-09/BC-2.09.003.md
  - behavioral-contracts/ss-09/BC-2.09.004.md
  - architecture/verification-properties/VP-020-publish-state-machine.md
input-hash: ""
# BC status: BC-2.09.001 + BC-2.09.002 + BC-2.09.003 + BC-2.09.004 assigned;
# status=draft per Spec-First Gate S-7.01
# Priority: P0 — state machine + LinkedIn API are the core publishing invariants
# Dependency rationale:
#   STORY-029 (/brain:write) produces the draft that this skill publishes — tests need
#   the draft format (frontmatter fields) to build valid fixtures.
#   STORY-027 scaffolds `to-publish/linkedin/` and `published/linkedin/` directories.
#   Blocks STORY-031 (/brain:monthly-perf) because perf reads `linkedin_post_id`
#   frontmatter fields written by this skill.
---

# STORY-030: `/brain:publish-content` — state machine, LinkedIn API, scheduling, and finalize flow

## Goal

Deliver the `/brain:publish-content <file>` skill with the complete publishing state
machine: `validate-publish-state.sh` hook enforcement of `draft → ready → published`
transitions, LinkedIn Posts API (Community Management) integration, `--finalize --url`
manual-article flow, and `--schedule <date>` scheduling. After this story the operator
can publish a ready draft to LinkedIn in one command and the state machine prevents
any invalid transitions.

## User Value

As a brain-factory operator, I want to run `/brain:publish-content` on my ready draft
so that it is posted to LinkedIn via the Posts API, moved to `published/linkedin/`, and
its frontmatter is updated with `published_at` and `linkedin_post_id` — all in one
command with state-machine safety.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.09.004 | Frontmatter state machine enforces `draft → ready → published` transitions | P0 |
| BC-2.09.001 | `/brain:publish-content` posts to LinkedIn via Posts API (Community Management) | P0 |
| BC-2.09.002 | `/brain:publish-content` supports `--finalize --url "..."` for LinkedIn articles manual flow | P1 |
| BC-2.09.003 | `/brain:publish-content` supports `--schedule <date>` flag | P1 |

## Acceptance Criteria

### State machine enforcement (BC-2.09.004)

**AC-001** — `validate-publish-state.sh` (PostToolUse) exits 0 for valid transitions:
a file in `drafts/{platform}/` with `status: draft` is allowed; a file in
`to-publish/{platform}/` with `status: ready` is allowed; a file in
`published/{platform}/` with `status: published` is allowed.
(traces to BC-2.09.004 postcondition 1)

**AC-002** — `validate-publish-state.sh` exits 2 with E-PUBLISH-001 for all invalid
transitions: `draft → published` (skip), `published → ready` (regression),
`published → draft` (regression), `ready → draft` (regression).
(traces to BC-2.09.004 postcondition 2)

**AC-003** — When the file's physical directory location and its `status` frontmatter
field disagree (e.g., file in `to-publish/linkedin/` but `status: draft`), the hook
exits 2 with E-PUBLISH-001.
(traces to BC-2.09.004 invariant 4)

**AC-004** — A file manually moved from `published/linkedin/` back to `drafts/linkedin/`
and then written triggers E-PUBLISH-001 on the next hook invocation.
(traces to BC-2.09.004 edge case EC-001)

### LinkedIn Posts API (BC-2.09.001)

**AC-005** — `/brain:publish-content <file>` calls the LinkedIn Posts API Community
Management endpoint (`/rest/posts`), NOT the deprecated UGC Posts endpoint
(`/ugcPosts`). Verified via DTU mock request log.
(traces to BC-2.09.001 invariant 1)

**AC-006** — On 201 API success, the file is moved from `to-publish/linkedin/` to
`published/linkedin/` and frontmatter is updated: `status: published`,
`published_at: <ISO8601>`, `linkedin_post_id: <id>`.
(traces to BC-2.09.001 postcondition 1, 2, 3)

**AC-007** — The file is NOT moved until the API confirms success (201). If the API
returns 500, the file remains in `to-publish/linkedin/` and the skill exits with an
error.
(traces to BC-2.09.001 invariant 3)

**AC-008** — When content exceeds 3000 chars, the skill emits E-PUBLISH-003 and exits
2 before making any API call.
(traces to BC-2.09.001 edge case EC-001)

**AC-009** — On 429 rate-limit response, the skill retries with exponential backoff
(up to 3 attempts, respecting `retry-after` header). After 3 failures, emits
E-PUBLISH-004 advisory.
(traces to BC-2.09.001 invariant 2; edge case EC-002)

**AC-010** — When LinkedIn credentials are not configured, the skill emits E-PUBLISH-005
and exits 2.
(traces to BC-2.09.001 edge case EC-003)

**AC-011** — When the file is still in `drafts/` (not moved to `to-publish/`), the
skill emits E-PUBLISH-006 and exits 2.
(traces to BC-2.09.001 edge case EC-004)

### Finalize flow (BC-2.09.002)

**AC-012** — When `--finalize --url <linkedin-url>` is passed, the skill marks the
file as published without making any API call: file moved to `published/linkedin/`,
frontmatter updated with `status: published`, `published_at: <ISO8601>`,
`linkedin_url: <url>`.
(traces to BC-2.09.002 postcondition 1, 2, 3)

**AC-013** — When `--finalize` is passed without `--url`, the skill emits E-PUBLISH-007
and exits 2.
(traces to BC-2.09.002 invariant 1; edge case EC-001)

### Schedule flag (BC-2.09.003)

**AC-014** — When `--schedule <date>` is passed with a valid ISO8601 date, the file
is moved to `to-publish/linkedin/` and frontmatter updated with `status: ready` and
`scheduled_for: <date>`. No API call is made.
(traces to BC-2.09.003 postcondition 1, 2, 3)

**AC-015** — When `--schedule` is passed with a past date, an advisory is emitted but
the frontmatter is still updated and the skill exits 0.
(traces to BC-2.09.003 invariant 2; edge case EC-001)

**AC-016** — When `--schedule` is passed with an invalid date format (not ISO8601
YYYY-MM-DD), the skill emits E-PUBLISH-008 and exits 2.
(traces to BC-2.09.003 edge case EC-002)

### Skill compliance

**AC-017** — The `publish-content.md` SKILL.md passes all meta-lint assertions:
frontmatter has `name: publish-content`, `description`, `argument-hint`, and
`allowed-tools` as a non-empty YAML list; body has the 6 canonical sections in order;
Iron Law body ≤ 200 chars; Red Flags has ≥ 1 bullet; Procedure has ≥ 1 numbered item;
no `.claude/templates/` hardcoding.
(traces to BC-2.09.001; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/hooks/validate-publish-state.sh` with the
   shebang (`#!/usr/bin/env bash`), `set -euo pipefail`, JSON stdin read, and stub body
   that exits 0 unconditionally.

2. **[stub]** Create `plugins/brain-factory/scripts/linkedin-post.mjs` (Node 20+) with
   stub that accepts `--file`, `--access-token`, `--api-base` args and exits 0 with a
   mock post ID.

3. **[stub]** Create `plugins/brain-factory/skills/publish-content/SKILL.md` with
   complete frontmatter (`name: publish-content`, `description: "Publish a ready draft
   to LinkedIn via the Posts API"`, `argument-hint: "<file> [--finalize --url <url>]
   [--schedule <date>]"`, `allowed-tools: [Read, Write, Bash]`) and 6-section body
   skeleton. Iron Law: "Never move a file to published/ before the LinkedIn API confirms
   success — file moves are committed only on 201 response." Procedure steps are stubs.

4. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/hooks.bats` (state machine tests, matching VP-020):
   - `"validate-publish-state: ready-state file in to-publish/ → exit 0"` — VP-020
     vector.
   - `"validate-publish-state: draft→published skip blocked with E-PUBLISH-001"` —
     VP-020 vector.
   - `"validate-publish-state: published→draft regression blocked with E-PUBLISH-001"` —
     VP-020 vector.
   - `"validate-publish-state: location-status mismatch blocked (to-publish + status
     draft)"` — VP-020 vector.
   And add to `plugins/brain-factory/tests/skills.bats`:
   - `"publish-content: LinkedIn Posts API uses Community Management endpoint (VP-020)"` —
     DTU mock captures request; asserts `/rest/posts` endpoint used; `linkedin_post_id`
     written to frontmatter; file in `published/linkedin/`; exit 0.
   - `"publish-content: file NOT moved until API confirms 201"` — DTU mock returns 500;
     asserts file still in `to-publish/linkedin/`; exit failure.
   - `"publish-content: content > 3000 chars → E-PUBLISH-003 exit 2"` — content length
     check.
   - `"publish-content: --finalize --url moves file, no API call (BC-2.09.002)"` —
     DTU mock not started; asserts file moved + frontmatter updated + exit 0.
   - `"publish-content: --finalize without --url → E-PUBLISH-007 exit 2 (BC-2.09.002)"`.
   - `"publish-content: --schedule valid date → frontmatter updated, no API call"`.
   - `"publish-content: --schedule invalid date → E-PUBLISH-008 exit 2"`.
   - `"publish-content SKILL.md: meta-lint compliance"`.
   Run bats — confirm all 12 tests fail (Red Gate confirmed).

5. **[impl]** Implement `validate-publish-state.sh`:
   - Extract `path` and `content` from stdin JSON (`jq`).
   - Derive state bucket from path prefix: `drafts/` → `draft`, `to-publish/` → `ready`,
     `published/` → `published`. If no match → pass through (not a publishing path).
   - Extract `status` from content frontmatter (`awk`/`yq`). If no `status` field →
     emit E-PUBLISH-002; exit 2.
   - Cross-check: expected status for directory vs actual status. If mismatch or invalid
     transition → emit E-PUBLISH-001; exit 2. Otherwise exit 0.
   - Emit `publish.state_checked` JSONL event on stderr.

6. **[impl]** Implement `publish-content` skill Procedure:
   - Parse flags: `--finalize` + `--url`, `--schedule`, or bare publish.
   - Validate file is in `to-publish/{platform}/` with `status: ready`; else
     E-PUBLISH-006; exit 2.
   - `--schedule` path: validate ISO8601 date; check past-date; move to
     `to-publish/linkedin/` if not already there; update frontmatter; exit 0.
   - `--finalize` path: validate `--url` present; move to `published/linux/`; update
     frontmatter; exit 0 (no API call).
   - Standard path: check content length ≤ 3000 chars; else E-PUBLISH-003; exit 2.
   - Check credentials; else E-PUBLISH-005; exit 2.
   - Call `scripts/linkedin-post.mjs` via `node` with retry via `scripts/lib/api-retry.sh`;
     on 429 → backoff up to 3 attempts.
   - On success: move file to `published/linkedin/`; update frontmatter; exit 0.

7. **[green]** Run bats for all hook + skill publish tests — all 12 pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `status: ready` file in `to-publish/linkedin/` | Hook exits 0 | happy-path | BC-2.09.004 invariant + VP-020 |
| `status: published` in `drafts/` directory | Hook E-PUBLISH-001; exit 2 | error | BC-2.09.004 invariant 4 + VP-020 |
| Location-status mismatch | Hook E-PUBLISH-001; exit 2 | error | BC-2.09.004 invariant 4 + VP-020 |
| Valid ready-state file; DTU mock returns 201 | Published; file moved; frontmatter updated; exit 0 | happy-path | BC-2.09.001 + VP-020 |
| DTU mock returns 500 | File remains in `to-publish/`; exit failure | error | BC-2.09.001 invariant 3 |
| Content > 3000 chars | E-PUBLISH-003; exit 2 | error | BC-2.09.001 EC-001 |
| `--finalize --url "https://linkedin.com/pulse/..."` | File moved; frontmatter updated; no API call; exit 0 | happy-path | BC-2.09.002 canonical test vector |
| `--finalize` without `--url` | E-PUBLISH-007; exit 2 | error | BC-2.09.002 EC-001 |
| `--schedule 2026-06-01` | `scheduled_for` updated; exit 0 | happy-path | BC-2.09.003 canonical test vector |
| `--schedule "next week"` | E-PUBLISH-008; exit 2 | error | BC-2.09.003 EC-002 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-020 | All valid state transitions pass | `tests/hooks.bats` |
| VP-020 | All invalid transitions blocked with E-PUBLISH-001 | `tests/hooks.bats` |
| VP-020 | Posts API endpoint `/rest/posts` used (not deprecated UGC) | `tests/skills.bats` (DTU mock) |
| VP-020 | File not moved until API 201 success | `tests/skills.bats` (DTU mock) |
| VP-020 | LinkedIn directories present + file in correct location | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-09-publishing-pipeline.md`:

1. `scripts/linkedin-post.mjs` calls the LinkedIn Posts API Community Management
   endpoint. The UGC Posts API (`/ugcPosts`) is deprecated and MUST NOT be used.
   This is a correctness invariant verified by the DTU mock log.

2. The file is moved to `published/linkedin/` ONLY after the API returns 201 (or
   equivalent success). Optimistic move + rollback is NOT acceptable — the move must
   be committed only after confirmation per BC-2.09.001 invariant 3.

3. `scripts/lib/api-retry.sh` wraps the LinkedIn API call with exponential backoff.
   The retry helper must be called with `retry-after` header respect; do not
   implement bare `sleep` loops.

4. `validate-publish-state.sh` is a PostToolUse hook. It fires when ANY file is
   written to a publishing path (`drafts/`, `to-publish/`, `published/`). The hook
   must handle non-publishing paths by passing through (exit 0) to avoid blocking
   other writes.

5. The hook emits `publish.state_checked` event on stderr per BC-2.04.017 and the
   structured event catalog. The event_type must be registered in
   `scripts/event-catalog.json` before the PR merges.

**Forbidden dependencies:**
- `validate-publish-state.sh`: must NOT call any external API.
- `validate-publish-state.sh`: must NOT read `wiki/` or `sources/`.
- `publish-content` skill: must NOT post to any platform other than LinkedIn in v0.1.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `node` | 20+ | `scripts/linkedin-post.mjs` runtime (CLAUDE.md §Toolchain) |
| `jq` | 1.6+ | JSON stdin parsing in hook |
| `yq` | 4.x+ | Frontmatter extraction in hook |
| `awk` | POSIX | Fallback frontmatter extraction |
| `scripts/lib/api-retry.sh` | (this repo) | Exponential backoff wrapper (ADR-016) |
| `date` | GNU/BSD | ISO8601 validation and `published_at` timestamp |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/validate-publish-state.sh` | Create | PostToolUse state machine enforcement hook |
| `plugins/brain-factory/scripts/linkedin-post.mjs` | Create | Node 20+ LinkedIn Posts API caller |
| `plugins/brain-factory/skills/publish-content/SKILL.md` | Create | Publish orchestration skill |
| `plugins/brain-factory/tests/hooks.bats` | Modify | Add 4 failing-then-passing state machine hook tests |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 8 failing-then-passing publish skill tests |
| `plugins/brain-factory/scripts/event-catalog.json` | Modify | Register `publish.state_checked` event type |

Files NOT to modify: any file under `.factory/`, any other hook script, `plugin.json`,
any prior story file.

## Previous Story Intelligence

STORY-029 (`/brain:write`) establishes the draft frontmatter format:
`status: draft`, `brief_path`, `platform`, `created`. The publish skill reads `platform`
to determine the target directory. Verify `platform: linkedin` is consistently written
by the write skill fixture before implementing the publish routing logic. STORY-027
establishes that `to-publish/linkedin/` and `published/linkedin/` exist after init —
verify this in the fixture setup helper.

Note: `scripts/lib/api-retry.sh` is first introduced in EPIC-07 (BC-2.13.003) per the
epics.md rationale. However, `/brain:publish-content` (this story) calls the LinkedIn
API with the same retry pattern. Confirm whether `api-retry.sh` is already in scope
from EPIC-06 SS-09 or whether this story must create a minimal version. Per SS-09 §Key
Design "Rate-limit handling: `api-retry.sh` (ADR-016) wraps the LinkedIn API call" —
it is a dependency of this story. Create `scripts/lib/api-retry.sh` here; EPIC-07 will
extend it. Mark it explicitly in the File Structure table above.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,000 |
| SS-09 subsystem design | ~900 |
| BC-2.09.001 file | ~800 |
| BC-2.09.002 file | ~600 |
| BC-2.09.003 file | ~600 |
| BC-2.09.004 file | ~700 |
| VP-020 file (bats spec) | ~2,200 |
| Existing `hooks.bats` (for hook test context) | ~2,000 |
| Existing `skills.bats` (for skill test context) | ~2,000 |
| **Total** | **~13,800** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:monthly-perf` — STORY-031 (reads `linkedin_post_id` written here).
- Medium / other platform publishing — future extension.
- GH Action scheduled-publish trigger — EPIC-07.
- Rate-limit analytics — EPIC-08.

## Anchors

- BC-2.09.001: `behavioral-contracts/ss-09/BC-2.09.001.md`
- BC-2.09.002: `behavioral-contracts/ss-09/BC-2.09.002.md`
- BC-2.09.003: `behavioral-contracts/ss-09/BC-2.09.003.md`
- BC-2.09.004: `behavioral-contracts/ss-09/BC-2.09.004.md`
- SS-09: `architecture/subsystems/SS-09-publishing-pipeline.md`
- VP-020: `architecture/verification-properties/VP-020-publish-state-machine.md`
- STORY-027: `stories/stories/STORY-027.md` (scaffold — directories)
- STORY-029: `stories/stories/STORY-029.md` (write skill — produces the draft consumed here)
