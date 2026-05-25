---
artifact_type: story
story_id: STORY-016
epic_id: EPIC-03
title: "Defuddle fetch wrapper, duplicate guard, and atomic manifest-write helper"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-02]
behavioral_contracts: [BC-2.02.001, BC-2.02.004, BC-2.02.006]
vps: [VP-015, VP-012]
dependencies: [STORY-001, STORY-014]
blocks: [STORY-017, STORY-019]
inputs:
  - architecture/subsystems/SS-02-url-ingest-pipeline.md
  - architecture/adr/ADR-010-manifest-delta-architecture.md
  - behavioral-contracts/ss-02/BC-2.02.001.md
  - behavioral-contracts/ss-02/BC-2.02.004.md
  - behavioral-contracts/ss-02/BC-2.02.006.md
  - architecture/verification-properties/VP-015-url-ingest-pipeline.md
  - architecture/verification-properties/VP-012-manifest-atomicity.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.02.001 (fetch + source write), BC-2.02.006 (duplicate guard),
# and BC-2.02.004 (manifest delta write) are all tightly coupled at the implementation
# level — defuddle-fetch.mjs is the fetch surface, manifest-write.sh is the shared
# atomic write helper, and the duplicate guard is the first gate in BC-2.02.001's flow.
# These three BCs form one deliverable: the infrastructure that STORY-017 and STORY-019
# both call into. Splitting them would require STORY-017 to implement the manifest helper
# again.
---

# STORY-016: Defuddle fetch wrapper, duplicate guard, and atomic manifest-write helper

## Goal

Deliver the core infrastructure of the URL ingest pipeline: `scripts/defuddle-fetch.mjs`
(the Defuddle CLI wrapper), `hooks/lib/manifest-write.sh` (the shared atomic manifest
delta helper), and the upfront duplicate-URL guard in the `/brain:ingest-url` skill body.
This story builds the foundational pieces that STORY-017 (wiki generation + token logging)
and STORY-019 (local source ingest) compose on top of. After this story, the skill can
fetch a URL, detect duplicates, write the source file, and update `manifest.json`
atomically — but does not yet produce wiki pages (that is STORY-017's scope).

## User Value

As a brain operator, I want to run `/brain:ingest-url https://example.com/article` and
have the URL fetched, cleaned by Defuddle, written to `sources/{topic}/`, and recorded in
the manifest — so that the raw knowledge is durably captured before any wiki generation
occurs, and so that re-running the same URL is blocked rather than creating duplicate data.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.02.001 | `/brain:ingest-url` fetches URL via Defuddle and writes to `sources/{topic}/` | P0 |
| BC-2.02.004 | `/brain:ingest-url` operates on manifest delta only (no full-corpus re-reads) | P0 |
| BC-2.02.006 | `/brain:ingest-url` rejects already-ingested URL (source-immutability guard) | P0 |

## Acceptance Criteria

### Defuddle Fetch Wrapper (BC-2.02.001)

**AC-001** — `scripts/defuddle-fetch.mjs` exists at
`plugins/brain-factory/scripts/defuddle-fetch.mjs`. Running
`node scripts/defuddle-fetch.mjs https://example.com` (with Node 22+) exits 0 and writes
cleaned markdown to stdout. The script uses the `defuddle` package (by kepano/Steph Ango,
CEO of Obsidian; v0.18.1 as of April 2026) to extract the main content of the page,
stripping navigation, ads, and boilerplate (targeting 70-90% token reduction over raw
HTML). Import pattern: `import { Defuddle } from 'defuddle/node'` with `linkedom` as the
DOM dependency. Installation: `npm install defuddle linkedom`.
CLI alternative: `npx defuddle parse <url> --markdown` (the `defuddle-cli` package is
deprecated and merged into the main `defuddle` package).
(traces to BC-2.02.001 precondition 2; invariant 1)

**AC-002** — When Node 22+ is NOT available in PATH, `/brain:ingest-url` exits 2 and
emits E-INGEST-005: "Node 22+ required for Defuddle. Install from nodejs.org." No fetch
is attempted. (Note: Node 20 reached EOL April 30, 2026; the project minimum is Node 22.)
(traces to BC-2.02.001 edge case EC-006)

**AC-003** — When the URL returns a non-200 HTTP status, `/brain:ingest-url` exits 2 and
emits E-INGEST-002: "HTTP <status> fetching <url>. Ingest aborted." No source file is
written.
(traces to BC-2.02.001 edge case EC-002)

**AC-004** — When Defuddle returns empty content (cleaned output is zero-length or
whitespace-only), `/brain:ingest-url` exits 2 and emits E-INGEST-003: "Defuddle returned
empty content for <url>. Page may not be extractable." No source file is written.
(traces to BC-2.02.001 edge case EC-003)

**AC-005** — On a successful fetch, a new file `sources/{topic}/{slug}.md` is created
containing the Defuddle-cleaned content with source frontmatter: `title`, `url`,
`ingested_at` (ISO 8601), `source_id` (the slug), `topic`, `embedding_status: pending`.
The slug is a kebab-case normalization of the URL path.
(traces to BC-2.02.001 postcondition 1)

**AC-006** — The `quarantine-fetch.sh` hook fires (via PreToolUse on WebFetch) before the
Defuddle fetch. If it exits 2, the skill aborts with E-INGEST-004: "Content quarantined —
prompt-injection pattern detected. Ingest aborted." No source file is written.
(traces to BC-2.02.001 precondition 5; edge case EC-005)

### Duplicate Guard (BC-2.02.006)

**AC-007** — Before any Defuddle fetch is performed, `/brain:ingest-url` reads
`.brain/manifest.json` and checks whether the URL already appears in any source entry's
`url` field (exact string match). If found, exit 2 with E-INGEST-001: "URL already
ingested as <slug>. Sources are immutable."
(traces to BC-2.02.006 postconditions 1–3; invariant 1)

**AC-008** — The duplicate check is PRIOR to the Defuddle fetch. No tokens are spent on a
URL that is already in the manifest. Verified by the bats test: mock the Defuddle call to
count invocations; confirm it is NEVER called for a duplicate URL.
(traces to BC-2.02.006 invariant 1)

**AC-009** — A URL with a different query string than an already-ingested URL is treated as
a new URL (exact string comparison). Ingest proceeds normally.
(traces to BC-2.02.006 edge case EC-001)

### Manifest Delta Write (BC-2.02.004)

**AC-010** — `hooks/lib/manifest-write.sh` exists at
`plugins/brain-factory/hooks/lib/manifest-write.sh`. It accepts the new manifest entry as
a JSON argument, reads the current `.brain/manifest.json`, appends the new entry to the
`sources` array, writes to a `.tmp` file, then `mv` renames to the canonical path (atomic
write). It sources `hook-event-emit.sh` and emits a structured event on success.
(traces to BC-2.02.004 postcondition 3; invariant 2)

**AC-011** — After a successful ingest, `.brain/manifest.json` contains a new entry:
`{"source_id": "<slug>", "url": "<url>", "topic": "<topic>", "ingested_at": "<ISO8601>",
"last_ingest": "<ISO8601>", "chunks": [], "embeddings_model": null}`. Existing entries are
NOT modified.
(traces to BC-2.02.004 postconditions 1–2; BC-2.02.001 postcondition 2)

**AC-012** — The skill reads ONLY `.brain/manifest.json` to detect duplicates and to
obtain the current manifest state. It does NOT scan `sources/` directory contents. Verified
by bats: create a temp brain with 10 source files not in manifest; confirm ingest does NOT
read those files (mock filesystem reads via test tracing).
(traces to BC-2.02.004 postcondition 1; invariant 1)

**AC-013** — When the manifest write fails (disk full / permission error), the source file
write is rolled back (deleted if it was created) and the skill exits 2 with E-INGEST-008:
"Failed to update manifest.json: <error>."
(traces to BC-2.02.004 edge case EC-002)

**AC-014** — `manifest-write.sh` is shellcheck-clean and `shfmt -d -i 2` produces no diff.
`defuddle-fetch.mjs` is lint-clean per standard Node tooling.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Create stub `scripts/defuddle-fetch.mjs` in
   `plugins/brain-factory/scripts/`: minimal Node 22+ script that exits 1 (stub). Create
   stub `hooks/lib/manifest-write.sh`: bash library that sources `hook-event-emit.sh` and
   exits 1 (stub).

2. **[failing test — Red Gate]** Add failing bats tests in `tests/skills.bats` and
   `tests/integration.bats`:
   - `defuddle-fetch.mjs` called with mock URL → outputs cleaned markdown (mock Defuddle).
   - E-INGEST-005 emitted when Node 22+ not in PATH.
   - E-INGEST-001 emitted for duplicate URL; Defuddle NOT called.
   - E-INGEST-002 emitted on non-200 HTTP status.
   - E-INGEST-003 emitted on empty Defuddle output.
   - Source file created with correct frontmatter on success.
   - `manifest.json` updated with new entry; existing entries unchanged.
   - No `sources/` directory scan during ingest (file-read trace assertion).
   - Manifest write failure → source file rolled back; E-INGEST-008 emitted.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `scripts/defuddle-fetch.mjs`: thin wrapper using the `defuddle`
   package (v0.18.1+). Import pattern: `import { Defuddle } from 'defuddle/node'`. The
   `defuddle/node` subpath requires `linkedom` as a peer dependency for DOM parsing —
   install both: `npm install defuddle linkedom`. Input: URL as first positional arg.
   Output: cleaned markdown to stdout. Error: non-zero exit with error message on
   non-200, unreachable host, or empty output. Node check: `process.version` against
   `v22` minimum (Node 20 reached EOL April 30, 2026). Do NOT use `defuddle-cli` (deprecated;
   merged into main `defuddle` package).

4. **[impl]** Implement the `/brain:ingest-url` skill body through the source-write step
   in `skills/ingest-url/SKILL.md`:
   - Node 22+ check (AC-002).
   - Duplicate guard against manifest.json (AC-007, AC-008).
   - Call `scripts/defuddle-fetch.mjs` (AC-001, AC-003, AC-004).
   - Write source file to `sources/{topic}/{slug}.md` with correct frontmatter (AC-005).
   - Call `hooks/lib/manifest-write.sh` for atomic manifest update (AC-010, AC-011, AC-013).
   - Wiki page generation and token logging are NOT implemented here — those are STORY-017.

5. **[impl]** Implement `hooks/lib/manifest-write.sh`:
   - Source `hook-event-emit.sh`.
   - Accept new entry JSON as argument.
   - Read current `manifest.json`, append entry to `.sources` array using `jq`.
   - Write via `.tmp` + `mv` (atomic).
   - Emit `ingest.url.manifest_updated` or `ingest.source.manifest_updated` structured event.
   - On error: exit 1 with E-INGEST-008 message on stdout; rollback signal on stderr.

6. **[green]** Run `bats tests/skills.bats` and `bats tests/integration.bats` — all new
   tests pass.

7. **[green]** Run `shellcheck hooks/lib/manifest-write.sh` and
   `shfmt -d -i 2 hooks/lib/manifest-write.sh` — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `defuddle-fetch.mjs https://example.com/article` (mocked 200) | Cleaned markdown on stdout; exit 0 | happy-path | BC-2.02.001 |
| `ingest-url` with URL not in manifest | Source file created; manifest updated; exit 0 | happy-path | BC-2.02.001 |
| `ingest-url` with URL already in manifest | E-INGEST-001; exit 2; no Defuddle call | error | BC-2.02.006 |
| `ingest-url` with non-200 response (mock) | E-INGEST-002; exit 2; no source file | error | BC-2.02.001 EC-002 |
| `ingest-url` with empty Defuddle output (mock) | E-INGEST-003; exit 2; no source file | error | BC-2.02.001 EC-003 |
| `ingest-url` with Node 22+ absent (mock) | E-INGEST-005; exit 2 | error | BC-2.02.001 EC-006 |
| `manifest-write.sh` with write failure (mock) | E-INGEST-008; exit 2; source file rolled back | error | BC-2.02.004 EC-002 |
| Ingest with 10K manifest entries | Only manifest.json read; no sources/ scan | edge-case | BC-2.02.004 invariant 1 |
| URL with different query string vs existing | Treated as new URL; ingest proceeds | edge-case | BC-2.02.006 EC-001 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-015 | Source file created with correct frontmatter on fresh URL | `tests/integration.bats` |
| VP-015 | Duplicate URL rejected before fetch | `tests/skills.bats` |
| VP-015 | Manifest updated atomically on success | `tests/integration.bats` |
| VP-012 | Manifest entry written with correct fields; existing entries unchanged | `tests/skills.bats` |
| VP-012 | Manifest write atomic (`.tmp` → `mv`) | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-02-url-ingest-pipeline.md` and ADR-010:

1. Defuddle is invoked via `scripts/defuddle-fetch.mjs` ONLY — never raw `curl` or WebFetch
   on raw HTML. (BC-2.02.001 invariant 1)
2. `manifest-write.sh` is a **sourced bash library** located at `hooks/lib/manifest-write.sh`.
   Both URL ingest (STORY-016) and local source ingest (STORY-019) call this shared helper.
3. The manifest write is ALWAYS atomic: write to `.brain/manifest.json.tmp`, then
   `mv .brain/manifest.json.tmp .brain/manifest.json`. Never write directly to the canonical path.
4. The duplicate check reads ONLY `manifest.json`. No `find` or `ls` of the `sources/`
   directory is permitted in any ingest operation. (BC-2.02.004 invariant 1)
5. The skill does NOT call the wiki generation pipeline in this story — wiki pages are
   STORY-017's scope. The skill body in `SKILL.md` must have a clearly marked stub section
   that STORY-017 fills in.
6. Structured events emitted: `ingest.url.started`, `ingest.url.source_written`,
   `ingest.url.manifest_updated`, `ingest.url.rejected_duplicate` — all must be pre-registered
   in `scripts/event-catalog.json` (STORY-014 deliverable).

**Forbidden dependencies:**
- `hooks/lib/manifest-write.sh`: no external HTTP calls; no Node.js; bash + jq only.
- `scripts/defuddle-fetch.mjs`: no bash invocations inside the Node script for path logic.
- `skills/ingest-url/SKILL.md` skill body must NOT call `find` or `ls` on `sources/`.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system /bin/bash is 3.2 due to GPLv3 licensing. Operators must install via `brew install bash` and ensure PATH resolves `/usr/bin/env bash` to the Homebrew version) | CLAUDE.md §Conventions; ADR-001 |
| `node` | 22+ (Node 20 reached EOL April 30, 2026; current LTS: Node 24) | CLAUDE.md §Project Identity; BC-2.02.001 precondition 2 |
| `defuddle` | 0.18.1+ (by kepano/Steph Ango; `defuddle-cli` is deprecated — use main `defuddle` package; import via `import { Defuddle } from 'defuddle/node'`; requires `linkedom` as peer dep) | SS-02 key design; AC-001 |
| `linkedom` | latest stable (peer dep for `defuddle/node` subpath import) | defuddle/node DOM requirement |
| `jq` | 1.7+ (latest: 1.8.1; jq 1.6 `leaf_paths` and `recurse_down` removed in 1.7) | manifest.json manipulation |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1; `-i 2 -d` flags stable across 3.x) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/scripts/defuddle-fetch.mjs` | Create | Node 22+ Defuddle wrapper using `defuddle` package v0.18.1+ |
| `plugins/brain-factory/hooks/lib/manifest-write.sh` | Create | Shared atomic manifest append helper |
| `plugins/brain-factory/skills/ingest-url/SKILL.md` | Create | Skill body through source-write step (wiki generation stub for STORY-017) |
| `plugins/brain-factory/tests/skills.bats` | Extend | Duplicate guard + error-path assertions |
| `plugins/brain-factory/tests/integration.bats` | Extend | Source file + manifest write integration |
| `plugins/brain-factory/tests/fixtures/ingest-url-happy.json` | Create | Happy-path bats fixture |
| `plugins/brain-factory/tests/fixtures/ingest-url-duplicate.json` | Create | Duplicate-URL bats fixture |

Files NOT to modify: any file under `.factory/`, `hooks/hooks.json`, `plugin.json`,
any prior STORY-NNN.md, `scripts/event-catalog.json` (STORY-014 owns catalog entries;
only ask STORY-014 to pre-populate the events emitted here).

## Previous Story Intelligence

STORY-014 delivered `hooks/lib/hook-event-emit.sh` and `scripts/event-catalog.json`.
The `manifest-write.sh` helper in this story sources `hook-event-emit.sh` — confirm that
helper exists before marking the impl step complete. The structured event types emitted by
the ingest pipeline (`ingest.url.started`, `ingest.url.source_written`,
`ingest.url.manifest_updated`, `ingest.url.rejected_duplicate`) were pre-catalogued in
STORY-014's event catalog pre-population (AC-009 of STORY-014). Verify those rows exist in
`scripts/event-catalog.json` before adding new emit calls.

STORY-001 created the `skills/ingest-url/` directory with a stub `SKILL.md`. This story
replaces that stub with the full skill body through the source-write step.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,500 |
| SS-02 subsystem design | ~1,500 |
| BC-2.02.001, BC-2.02.004, BC-2.02.006 files | ~3,000 |
| VP-015, VP-012 files | ~1,200 |
| ADR-010 manifest delta architecture | ~1,500 |
| skills.bats + integration.bats existing content | ~2,500 |
| event-catalog.json (STORY-014 deliverable) | ~2,000 |
| **Total** | **~15,200** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Wiki page generation (5–15 pages per ingest) — STORY-017.
- Token JSONL logging to `.brain/logs/ingest-tokens.jsonl` — STORY-017.
- 50K-token threshold warning — STORY-017.
- Sub-linear latency gate — STORY-018.
- Local source ingest (`/brain:ingest-source`) — STORY-019.

## Anchors

- BC-2.02.001: `behavioral-contracts/ss-02/BC-2.02.001.md`
- BC-2.02.004: `behavioral-contracts/ss-02/BC-2.02.004.md`
- BC-2.02.006: `behavioral-contracts/ss-02/BC-2.02.006.md`
- VP-015: `architecture/verification-properties/VP-015-url-ingest-pipeline.md`
- VP-012: `architecture/verification-properties/VP-012-manifest-atomicity.md`
- SS-02: `architecture/subsystems/SS-02-url-ingest-pipeline.md`
- ADR-010: `architecture/adr/ADR-010-manifest-delta-architecture.md`

## Changelog

| Date | Change | Reason |
|------|--------|--------|
| 2026-05-25 | Fixed Defuddle package: replaced `@defuddle/node` (incorrect) with `defuddle` v0.18.1+ by kepano/Steph Ango; noted `defuddle-cli` is deprecated and merged into main package; updated import pattern to `import { Defuddle } from 'defuddle/node'`; added `linkedom` as required peer dependency; updated Node version 20+ → 22+ throughout (Node 20 EOL April 30, 2026); updated E-INGEST-005 message; updated Library table with corrected tool names, versions, and notes; updated bash 5.0+ with macOS note; shellcheck 0.10+; jq 1.7+; shfmt 3.7+ | Uncertainty removal: defuddle package name was incorrect (`@defuddle/node` does not exist); Node 20 is EOL; version pins corrected |
