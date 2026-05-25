---
artifact_type: story
story_id: STORY-024
epic_id: EPIC-05
title: "/brain:connect skill — cross-domain connection discovery"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-11]
behavioral_contracts: [BC-2.11.001]
vps: []
dependencies: [STORY-019, STORY-020]
blocks: [STORY-025]
inputs:
  - architecture/subsystems/SS-11-knowledge-synthesis.md
  - behavioral-contracts/ss-11/BC-2.11.001.md
input-hash: ""
# BC status: BC-2.11.001 assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Priority: P1 — depends on wiki layer (EPIC-04) producing pages to synthesize across
# Dependency rationale: STORY-019 (local source ingest, EPIC-03) must exist before
# connect can read pages via the ingest pipeline; STORY-020 (lint-wiki, EPIC-04)
# delivers wikilink-resolve.sh that /brain:connect uses to validate output wikilinks.
# wiki/log.md is first written by STORY-017 (URL ingest wiki gen pipeline) and also
# appended by STORY-019 (which reuses STORY-017's pipeline). STORY-020 is a READER
# of wiki/log.md (check 7 of lint-wiki), not the writer.
# Blocks STORY-025: synthesize reads the connections file this story produces.
---

# STORY-024: `/brain:connect` skill — cross-domain connection discovery

## Goal

Deliver the `/brain:connect [days]` skill that reads recently ingested wiki pages from
`wiki/log.md`, asks the `brain:synthesizer` agent to find non-obvious cross-domain
connections, and writes a connection brief to `briefs/weekly/connections-{YYYY-MM-DD}.md`.
After this story the operator can close the ingestion → synthesis loop by discovering
what their sources say to each other.

## User Value

As a brain-factory operator, I want to run `/brain:connect` after ingesting a batch of
sources so that I can see non-obvious connections between concepts from different domains
without having to read every page myself — surfacing the serendipitous insight the second
brain exists to provide.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.11.001 | `/brain:connect [days]` finds cross-domain connections across recent ingests | P1 |

## Acceptance Criteria

### Connection Discovery (BC-2.11.001)

**AC-001** — When at least 2 wiki pages exist in the specified time window (default 7
days), `/brain:connect` writes `briefs/weekly/connections-{YYYY-MM-DD}.md` containing at
least 1 non-obvious connection per pair of distinct source topics present in the window.
(traces to BC-2.11.001 postcondition 1)

**AC-002** — Every connection entry in the output file cites both connected wiki pages
via wikilinks (`[[page-A]]` and `[[page-B]]`) plus a rationale phrase.
(traces to BC-2.11.001 postcondition 2)

**AC-003** — The skill exits 0 when the connection brief is successfully written.
(traces to BC-2.11.001 postcondition 3)

**AC-004** — All wikilinks in the output file resolve (validated by the
`validate-wikilink-integrity.sh` PostToolUse hook firing on the write).
(traces to BC-2.11.001 invariant 2)

**AC-005** — The skill reports only cross-domain connections — connections between
pages whose source topics differ. Same-topic page pairs are not reported even if a
thematic link exists.
(traces to BC-2.11.001 invariant 1)

**AC-006** — When fewer than 2 wiki pages exist within the time window, the skill
emits advisory text: "Not enough recent content for connection analysis. Ingest more
sources first." and exits 1.
(traces to BC-2.11.001 edge case EC-001)

**AC-007** — The `connect.md` SKILL.md passes all meta-lint assertions: frontmatter
has `name: connect`, `description`, `argument-hint: "[days]"`, and `allowed-tools` as
a non-empty YAML list; body has the 6 canonical sections in order (Iron Law / Red Flags
/ Announce-at-Start / Procedure / Quality Bar / Output); Iron Law body is ≤ 200 chars;
Red Flags has ≥ 1 bullet; Procedure has ≥ 1 numbered item; no `.claude/templates/`
hardcoding.
(traces to BC-2.11.001; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/connect/SKILL.md` with complete
   frontmatter (`name: connect`, `description`, `argument-hint: "[days]"`,
   `allowed-tools: [Read, Write]`) and the 6-section body skeleton. Iron Law placeholder:
   "Read only from wiki/log.md N-day window; never scan the full corpus."
   This is the stub; skill body Procedure steps are empty.

2. **[failing tests — Red Gate]** In `plugins/brain-factory/tests/skills.bats`, add the
   following failing `@test` blocks:
   - `"connect: happy path — connection brief written with wikilinks"` — sets up temp
     brain with wiki/log.md containing 2 pages from 2 distinct topics; invokes connect;
     asserts `briefs/weekly/connections-*.md` exists, contains `[[`, exits 0.
   - `"connect: same-topic pages not reported"` — all pages in window from same topic;
     asserts output file has 0 cross-domain entries.
   - `"connect: fewer than 2 pages → advisory exit 1"` — wiki/log.md with 0 or 1 page;
     asserts advisory message and exit 1.
   - `"connect: SKILL.md meta-lint compliance"` — runs meta-lint assertions on
     `skills/connect/SKILL.md` fixture.
   Run bats — confirm all 4 tests fail (Red Gate confirmed).

3. **[impl]** Implement `connect` skill Procedure in SKILL.md:
   - Step 1: Parse `[days]` argument; default to 7 if absent.
   - Step 2: Read `wiki/log.md`; extract page paths with timestamps in the N-day window.
   - Step 3: If fewer than 2 pages in window → emit advisory; exit 1.
   - Step 4: For each unique pair of pages from distinct source topics, read both pages;
     ask `brain:synthesizer` agent for non-obvious cross-domain connection + rationale.
   - Step 5: Aggregate non-null connections into a markdown list:
     `- [[page-A]] ↔ [[page-B]]: <rationale>`.
   - Step 6: Write to `briefs/weekly/connections-{YYYY-MM-DD}.md` with frontmatter
     (`title`, `date`, `type: connections`, `embedding_status: pending`).
   - Step 7: Exit 0.

4. **[green]** Run `bats tests/skills.bats -f connect` — all connect tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| wiki/log.md with 10 pages from 3 topics (last 7 days) | connections-YYYY-MM-DD.md with ≥1 cross-domain entry per topic pair; exit 0 | happy-path | BC-2.11.001 canonical test vector 1 |
| wiki/log.md with 0 pages in window | Advisory; exit 1 | edge-case | BC-2.11.001 EC-001 |
| wiki/log.md with 2 pages same topic | Connection file written with 0 cross-domain entries | invariant | BC-2.11.001 invariant 1 |
| connect/SKILL.md file | All meta-lint assertions pass | compliance | CLAUDE.md §Meta-Lint Contract |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no VP — P1/SS-11) | Connection brief created with valid wikilinks | `tests/skills.bats` |
| (no VP — P1/SS-11) | Fewer-than-2 advisory exits 1 | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-11-knowledge-synthesis.md`:

1. The skill reads ONLY the N-day window from `wiki/log.md` plus the page contents in
   that window. It MUST NOT read the full wiki corpus. This is a hard scale discipline
   rule: at 7 days + 5 pages/day = 35 pages, the context is bounded. Reading beyond the
   window violates the sub-linear scale invariant.

2. The connection output is written to `briefs/weekly/connections-{YYYY-MM-DD}.md`
   (the `briefs/` layer, not `wiki/syntheses/`). This is the canonical output path per
   BC-2.11.001 description. Do not write to `wiki/` directly from this skill.

3. All wiki writes from any downstream step trigger PostToolUse hooks (SS-04). If the
   skill ends up writing pages via `brain:synthesizer`, the hook chain fires automatically.
   The skill must not suppress or bypass hook execution.

4. Partial failures in multi-page analysis (synthesizer agent returning null for one
   pair) are handled gracefully: the pair is skipped; other pairs proceed. No silent
   swallow — the skip is logged in the summary output.

5. The `brain:synthesizer` agent is the only LLM-facing component. The skill's bash
   orchestration layer (argument parsing, log reading, file writing) is deterministic
   and bats-testable with a mocked synthesizer.

**Forbidden dependencies:**
- `connect` skill: must NOT read from `sources/` directly — only `wiki/` pages.
- `connect` skill: must NOT write to `wiki/` — output goes to `briefs/weekly/`.
- `connect` skill: must NOT call `quarantine-fetch.sh` — no web fetching occurs.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | Frontmatter parsing in SKILL.md compliance check; note: on Ubuntu, apt install yq installs the WRONG tool. Use snap install yq. |
| `date` | GNU/BSD | `YYYY-MM-DD` timestamp in output filename |
| `grep` | POSIX | Log window filtering by date prefix |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/connect/SKILL.md` | Create | Connection discovery skill with meta-lint-compliant structure |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 4 failing then passing connect test blocks |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json`,
any prior STORY-NNN.md, any other existing bats files or skill files.

## Previous Story Intelligence

STORY-017 (EPIC-03, URL ingest wiki generation pipeline) is the story that first
produces `wiki/log.md` and the `wiki/{type}/` directory tree during URL ingest. The
log.md WRITER is STORY-017; it appends an entry every time the wiki generation pipeline
runs. STORY-019 (EPIC-03, local source ingest) is NOT EPIC-04 — it is the local-file
variant of the same ingest pipeline and REUSES the STORY-017 wiki generation pipeline;
STORY-019 also appends to `wiki/log.md` via the same step. STORY-020 (EPIC-04,
`/brain:lint-wiki`) is a READER of `wiki/log.md` for the index-coherence check
(check 7 of 7) — it does not produce the log.

Dependency rationale for this story's `dependencies: [STORY-019, STORY-020]`:
- STORY-019 must exist because `/brain:connect` reads `wiki/log.md` entries from recent
  ingests. STORY-019 (local source ingest) and STORY-017 (URL ingest, via transitive
  chain STORY-017 → STORY-019) populate the log that `/brain:connect` consumes. STORY-019
  is the nearer upstream dependency (same pipeline, closest producer).
- STORY-020 must exist because `/brain:connect` uses `wikilink-resolve.sh`
  (delivered by STORY-020's `hooks/lib/wikilink-resolve.sh`) to validate that all
  wikilinks in the connection brief resolve correctly.

Confirm `wiki/log.md` exists and its format before implementing the log-parsing step.
If the log format is a JSONL record per page (as implied by the structured event catalog
from EPIC-02), the date filter in Step 2 should parse the `ts` field. If it is a plain
markdown list, use `grep` against date-prefixed lines.

N/A for prior EPIC-05 stories — this is the first story in the epic.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,800 |
| SS-11 subsystem design | ~900 |
| BC-2.11.001 file | ~700 |
| wiki/log.md format reference (STORY-020 for context) | ~1,500 |
| Existing skills.bats (for context) | ~2,000 |
| `brain:synthesizer` agent AGENT.md (for interface) | ~800 |
| **Total** | **~8,700** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:synthesize` skill — STORY-025 (reads the connections file this story creates).
- `/brain:process-inbox` skill — STORY-026.
- Embedding-status progression for connection briefs — EPIC-08 (scale architecture).
- Writing connections to `wiki/syntheses/` — the canonical path is `briefs/weekly/`
  per BC-2.11.001 description. The SS-11 subsystem design mentions `wiki/syntheses/`
  but the BC takes precedence per CLAUDE.md source-of-truth precedence rule.

## Anchors

- BC-2.11.001: `behavioral-contracts/ss-11/BC-2.11.001.md`
- SS-11: `architecture/subsystems/SS-11-knowledge-synthesis.md`
- STORY-017: `stories/stories/STORY-017.md` (URL ingest wiki generation — first producer of wiki/log.md)
- STORY-019: `stories/stories/STORY-019.md` (local source ingest — also appends to wiki/log.md via STORY-017 pipeline reuse; direct `depends_on` source)
- STORY-020: `stories/stories/STORY-020.md` (lint-wiki — delivers wikilink-resolve.sh used by /brain:connect for link validation)
- CLAUDE.md §Meta-Lint Contract: authoritative SKILL.md assertion list
