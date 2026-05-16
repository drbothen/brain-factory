---
document_type: subsystem-design
id: SS-09
title: "Publishing Pipeline"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-009
created: 2026-05-15
---

# SS-09: Publishing Pipeline

## Responsibility

Manages the `draft → ready → published` state machine, posts to LinkedIn via Posts API (Community Management), supports manual LinkedIn article finalization, handles scheduled publishing, and tracks performance via monthly pull from the LinkedIn Posts API.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.09.001 | `/brain:publish-content` posts to LinkedIn via Posts API | P0 |
| BC-2.09.002 | Supports `--finalize --url "..."` for LinkedIn articles manual flow | P1 |
| BC-2.09.003 | Supports `--schedule <date>` flag | P1 |
| BC-2.09.004 | Frontmatter state machine enforces `draft → ready → published` transitions | P0 |
| BC-2.09.005 | `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` structure maintained | P0 |
| BC-2.09.006 | `/brain:monthly-perf` pulls performance data from LinkedIn Posts API | P1 |

## Interfaces

**Inbound:** `/brain:publish-content <file> [--finalize --url <url>] [--schedule <date>]`; `/brain:monthly-perf`

**Outbound:** published content record at `published/linkedin/<slug>.md`; LinkedIn post ID written to frontmatter; performance data at `.brain/logs/perf-YYYY-MM.jsonl`

**Emitted events:** `publish.started`, `publish.posted`, `publish.failed`, `perf.pulled`

## Key Design

### LinkedIn Posts API integration (DTU scope)

The LinkedIn Posts API (Community Management) is an external dependency. brain-factory calls it via:
1. `scripts/linkedin-post.mjs` (Node 20+): reads `LINKEDIN_ACCESS_TOKEN` from environment (set in brain vault's `.brain/.env` or CI secrets)
2. Posts the content body (≤ 3000 chars for LinkedIn native posts), returns post ID
3. Writes post ID back to the published file's frontmatter: `linkedin_post_id: urn:li:share:XXXXXXX`

Rate-limit handling: `api-retry.sh` (ADR-016) wraps the LinkedIn API call.

The `--finalize --url` flow handles LinkedIn Articles (longer-form): the operator manually publishes to LinkedIn and provides the URL; the skill records it in frontmatter without calling the Posts API.

### State machine enforcement (BC-2.09.004)

`validate-publish-state.sh` (PostToolUse) enforces valid transitions:
- `draft → ready`: always allowed
- `ready → published`: only via `/brain:publish-content` (which triggers the API call and writes `published_at`); direct frontmatter edit to `published` without `published_at` → E-PUBLISH-001 block
- Any other transition: E-PUBLISH-001 block (invalid transition — E-PUBLISH-002 is "Missing status field", not "invalid transition")

### Directory structure (BC-2.09.005)

```
drafts/linkedin/<slug>.md          (status: draft)
to-publish/linkedin/<slug>.md     (status: ready — moved here when ready for scheduling)
published/linkedin/<slug>.md      (status: published — moved here after post)
```
`/brain:publish-content` moves the file through these directories as part of the state transition.

## Purity Classification

**Effectful shell.** LinkedIn API call and file system moves are effectful. The state machine transition validation is a pure function (given current status and target status, return valid/invalid) and bats-testable.

## Dependencies

- SS-04 (Hook Chain): validate-publish-state.sh enforces state machine
- SS-08 (Content Brief and Writing): produces the artifact being published
- SS-16 (Scale): performance data logged to `.brain/logs/`

## Test Surface

- `tests/skills.bats` — state machine transitions; `--schedule` flag parses date correctly; monthly-perf JSON schema valid
- Integration: publish-content with LinkedIn DTU mock (not real API in bats)
