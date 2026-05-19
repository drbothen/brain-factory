---
artifact_type: story
story_id: STORY-017
epic_id: EPIC-03
title: "Wiki page generation pipeline, token JSONL logging, and 50K-token chunk warning"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-02]
behavioral_contracts: [BC-2.02.002, BC-2.02.003, BC-2.02.005]
vps: [VP-015]
dependencies: [STORY-016, STORY-014]
blocks: [STORY-018]
inputs:
  - architecture/subsystems/SS-02-url-ingest-pipeline.md
  - architecture/adr/ADR-008-librarian-agent-design.md
  - behavioral-contracts/ss-02/BC-2.02.002.md
  - behavioral-contracts/ss-02/BC-2.02.003.md
  - behavioral-contracts/ss-02/BC-2.02.005.md
  - architecture/verification-properties/VP-015-url-ingest-pipeline.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.02.002 (5–15 wiki pages), BC-2.02.003 (JSONL token logging),
# and BC-2.02.005 (50K-token warning) are the second phase of the ingest pipeline —
# they all operate AFTER the source file and manifest have been written (STORY-016 scope).
# These three BCs form the "what happens after source write" unit; they share the same
# Lobster workflow step (generate-wiki + log-tokens) and cannot be meaningfully
# implemented independently. Token logging (BC-2.02.003) must know how many wiki pages
# were created (BC-2.02.002) to write its `wiki_pages_created` field.
---

# STORY-017: Wiki page generation pipeline, token JSONL logging, and 50K-token chunk warning

## Goal

Complete the URL ingest pipeline by wiring the wiki page generation step, the token
JSONL record write, and the 50K-token advisory warning into `/brain:ingest-url`. After
STORY-016 writes the source file and manifest entry, this story connects the
`brain:librarian` agent to produce 5–15 cross-referenced wiki pages, writes the JSONL
token cost record to `.brain/logs/ingest-tokens.jsonl`, and emits an advisory when the
source content exceeds the 50K-token chunk threshold. The v0.1 ship gate requires this
story: "5+ wiki pages with cross-references" is a Phase 1 exit criterion.

## User Value

As a brain operator, I want each ingested URL to automatically produce multiple
cross-referenced wiki pages covering concepts, people, frameworks, and syntheses in the
source — so that the ingested knowledge becomes immediately queryable and linked within
my wiki rather than sitting as a flat source document.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.02.002 | `/brain:ingest-url` produces 5–15 cross-referenced wiki pages per ingest | P0 |
| BC-2.02.003 | `/brain:ingest-url` writes JSONL token record to `.brain/logs/ingest-tokens.jsonl` | P0 |
| BC-2.02.005 | `/brain:ingest-url` warns when source exceeds 50K-token chunk threshold | P1 |

## Acceptance Criteria

### Wiki Page Generation (BC-2.02.002)

**AC-001** — After source file write (STORY-016 scope), the `brain:librarian` specialist
agent is invoked with the source content and `wiki/index.md` context. It produces between
5 and 15 wiki page files, each at `wiki/{type}/{slug}.md` using one of the 6 canonical
types: `concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions`.
(traces to BC-2.02.002 postcondition 1; BC-2.05.005 path convention)

**AC-002** — Each generated wiki page passes `validate-frontmatter-schema.sh`
(embedding_status present and set to `pending`; all mandatory fields present) and
`validate-wikilink-integrity.sh` (all `[[slug]]` references resolve within the wiki).
(traces to BC-2.02.002 postconditions 2–3)

**AC-003** — Each generated wiki page has a `source_ids` frontmatter field containing the
slug of the ingesting source. `wiki/index.md` is updated with entries for all new pages.
`wiki/log.md` is updated with ingest log entries.
(traces to BC-2.02.002 postconditions 4–6)

**AC-004** — If the librarian produces fewer than 5 pages, an advisory E-INGEST-006 is
emitted: skill continues (does not block), operator is warned. Partial-failure fan-out per
BC-2.03.004 pattern applies: per-page results reported even when some hook-blocked.
(traces to BC-2.02.002 invariant 1; edge case EC-001)

**AC-005** — If a wiki page slug would collide with an existing slug, the page creation
is skipped (not an overwrite) and the skip is recorded in the ingest summary.
(traces to BC-2.02.002 edge case EC-002)

**AC-006** — If `validate-wikilink-integrity.sh` blocks a page write (exit 2), that page
is counted as a partial failure; other pages proceed. The skill exits 1 (advisory) when
any page fails, 0 when all succeed.
(traces to BC-2.02.002 invariant 3; edge case EC-003)

### Token JSONL Logging (BC-2.02.003)

**AC-007** — On every `/brain:ingest-url` invocation (success or partial failure), a JSONL
record is appended to `.brain/logs/ingest-tokens.jsonl`:
`{"timestamp": "<ISO8601>", "url": "<url>", "source_id": "<slug>", "input_tokens": <N>,
"output_tokens": <N>, "wiki_pages_created": <N>, "duration_seconds": <N>}`.
All fields are always present.
(traces to BC-2.02.003 postcondition 1; invariants 1–2)

**AC-008** — If `.brain/logs/` does not exist, the skill creates it before appending. If
the log file does not exist, it is created on first write.
(traces to BC-2.02.003 postcondition 2; edge case EC-001)

**AC-009** — The JSONL record is appended even on partial failure. The `wiki_pages_created`
field reflects the actual count of successfully created pages (not the planned count).
(traces to BC-2.02.003 postcondition 3)

**AC-010** — If the token count is unavailable from the API response, the record is written
with `{"input_tokens": -1, "output_tokens": -1}` to signal unavailability. The append
never fails due to token count being unknown.
(traces to BC-2.02.003 edge case EC-002)

**AC-011** — `jq -c '.'` on each line of `ingest-tokens.jsonl` succeeds (valid JSONL per
line). Verified in bats via `tail -1 .brain/logs/ingest-tokens.jsonl | jq empty`.
(traces to BC-2.02.003 postcondition 1 — record parseable by jq)

### 50K-Token Chunk Warning (BC-2.02.005)

**AC-012** — Before invoking the librarian agent, the skill estimates the token count of
the Defuddle-cleaned source content (using word-count heuristic: `wc -w` output × 1.3
tokens/word, or via `max_ingest_tokens_per_chunk` in `.brain/policies.yaml`, default
50000). If the estimate exceeds the threshold, an advisory is emitted:
"Source content estimated at <N> tokens, exceeding the <threshold>-token chunk threshold.
Full content ingested in v0.1. Automatic chunking available at v0.5+. Consider splitting
large sources manually."
(traces to BC-2.02.005 postcondition 1)

**AC-013** — The 50K-token warning is advisory only (exit code unchanged from threshold
breach alone). Ingest proceeds with the full content as a single source file. The manifest
entry's `chunks: []` field is always present regardless of threshold.
(traces to BC-2.02.005 invariants 1–2; postcondition 1)

**AC-014** — Content at or below the threshold triggers no warning. Content exactly AT the
threshold (== 50000) triggers no warning (exclusive: > 50000 triggers warning).
(traces to BC-2.02.005 edge case EC-002)

**AC-015** — If `max_ingest_tokens_per_chunk` is absent from `policies.yaml`, the default
50000 is used without error.
(traces to BC-2.02.005 edge case EC-001)

## Tasks

1. **[stub]** Verify STORY-016 has landed and `skills/ingest-url/SKILL.md` has the wiki
   generation step marked as a stub. If STORY-016 is in flight, create a stub
   `skills/ingest-url/SKILL.md` with the generate-wiki step as `# TODO: STORY-017`.

2. **[failing test — Red Gate]** Add failing bats tests to `tests/integration.bats`:
   - Fresh URL ingest → 5+ wiki pages created under `wiki/{type}/`; each passes
     schema validation and wikilink check.
   - All created pages have `source_ids` containing the source slug.
   - `wiki/index.md` updated after ingest.
   - `wiki/log.md` updated after ingest.
   - JSONL record appended to `.brain/logs/ingest-tokens.jsonl` with all required fields.
   - JSONL is parseable per-line by `jq empty`.
   - Source content exceeding 50K word-estimate → advisory warning in skill output.
   - Partial failure: one hook-blocked page → skill exits 1; other pages succeed.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[failing test — Red Gate]** Add failing bats tests to `tests/skills.bats`:
   - E-INGEST-006 advisory emitted when librarian produces < 5 pages.
   - Slug collision → page skipped; skip recorded in summary.
   - Log directory auto-created when absent.
   - Token count unavailable → `input_tokens: -1, output_tokens: -1` in record.
   Run bats — confirm new tests fail.

4. **[impl]** Implement the generate-wiki step in `skills/ingest-url/SKILL.md`:
   - 50K-token check against Defuddle output (AC-012, AC-013).
   - Invoke `brain:librarian` agent with source content + `wiki/index.md` context.
   - Collect per-page results in the partial-failure fan-out envelope.
   - Update `wiki/index.md` and `wiki/log.md`.
   - Exit 0 if all pages succeed; exit 1 if any fail (with fan-out result summary).

5. **[impl]** Implement the log-tokens step in `skills/ingest-url/SKILL.md`:
   - Create `.brain/logs/` if absent.
   - Compute JSONL record: timestamp (ISO 8601), url, source_id, input_tokens,
     output_tokens, wiki_pages_created (actual count), duration_seconds.
   - Append atomically using `>>` redirect (POSIX append is atomic for single writers).
   - Handle missing token count with `-1` sentinel.

6. **[green]** Run `bats tests/integration.bats` — all new tests pass.

7. **[green]** Run `bats tests/skills.bats` — all new tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Fresh 2000-word article ingest | 5–15 wiki pages; each schema-valid; index.md updated | happy-path | BC-2.02.002 |
| Short page (<500 words, <5 extractable concepts) | E-INGEST-006 advisory; pages_created < 5; skill continues | edge-case | BC-2.02.002 EC-001 |
| Slug collision with existing wiki page | Duplicate page skipped; summary records skip | edge-case | BC-2.02.002 EC-002 |
| One wiki page blocked by wikilink hook | pages_failed: 1; skill exits 1; other pages created | edge-case | BC-2.02.002 EC-003 |
| All pages succeed | JSONL record: all fields present; wiki_pages_created matches actual | happy-path | BC-2.02.003 |
| Partial failure (8 of 10 succeed) | wiki_pages_created: 8; exit 1 | edge-case | BC-2.02.003 postcondition 3 |
| Token count unavailable | input_tokens: -1; output_tokens: -1 in record | edge-case | BC-2.02.003 EC-002 |
| Source > 50K word-estimate | Advisory warning emitted; ingest still completes; exit 0 | edge-case | BC-2.02.005 |
| Source <= 50K word-estimate | No warning; exit 0 | happy-path | BC-2.02.005 EC-002 |
| `.brain/logs/` absent | Directory and file auto-created before append | edge-case | BC-2.02.003 EC-001 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-015 | 5+ wiki pages created on standard article ingest | `tests/integration.bats` |
| VP-015 | All created pages pass schema validation | `tests/integration.bats` |
| VP-015 | index.md updated after ingest | `tests/integration.bats` |
| VP-015 | JSONL token record written on every ingest | `tests/integration.bats` |
| VP-015 | Token JSONL record schema valid (jq parseable) | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-02-url-ingest-pipeline.md`:

1. Wiki page generation uses `brain:librarian` specialist agent — NOT a shell script
   directly. The agent is invoked by the `generate-wiki` workflow step in
   `workflows/ingest-url.yaml`. (SS-02 key design, step 4)
2. The partial-failure fan-out envelope format from BC-2.03.004 applies here:
   `{"pages_attempted": N, "pages_created": M, "pages_failed": K, "failures": [...]}`.
   This is the canonical result type for any multi-page generation step.
3. Token logging uses append (`>>`), not full-file rewrite. The log file is a JSONL
   append-only file — never rewritten from scratch. (BC-2.02.003 invariant 3)
4. The 50K-token check happens BEFORE the librarian agent call (after fetch, before
   generate-wiki). (SS-02 key design note on 50K threshold check position)
5. Structured events emitted in this step: `ingest.url.wiki_pages_generated`,
   `ingest.url.completed` — must be pre-registered in `scripts/event-catalog.json`.
6. `wiki/index.md` and `wiki/log.md` updates happen in the `generate-wiki` step, NOT
   as a separate dedicated step — keeping the fan-out envelope complete before the
   log-tokens step reads `wiki_pages_created`.

**Forbidden dependencies:**
- The token logging step must NOT call the Defuddle or librarian agent again.
- The generate-wiki step must NOT read `sources/` directory for any purpose beyond the
  single source file written by STORY-016.
- The word-count heuristic uses `wc -w` on the source file — no Node.js token counter.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ | CLAUDE.md §Conventions |
| `jq` | 1.6+ | JSONL validation; token record write |
| `wc` | POSIX | 50K-token word-count heuristic |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (`-i 2`) | CLAUDE.md §Conventions |

No Node.js for the token logging or 50K-check logic (only `wc -w`).

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/ingest-url/SKILL.md` | Extend | Add generate-wiki + log-tokens + 50K-warn steps |
| `plugins/brain-factory/tests/integration.bats` | Extend | Wiki page generation + token logging integration tests |
| `plugins/brain-factory/tests/skills.bats` | Extend | E-INGEST-006, slug collision, log auto-create, missing token count |
| `plugins/brain-factory/tests/fixtures/ingest-url-short-article.json` | Create | Short-article fixture for < 5 pages edge case |

Files NOT to modify: `scripts/defuddle-fetch.mjs`, `hooks/lib/manifest-write.sh` (both
STORY-016 owned), any `.factory/` file, any prior STORY-NNN.md.

## Previous Story Intelligence

STORY-016 wrote the `skills/ingest-url/SKILL.md` stub through the source-write step.
This story extends that stub by filling in the generate-wiki and log-tokens steps.
STORY-014 pre-populated `scripts/event-catalog.json` with all ingest event types
including `ingest.url.wiki_pages_generated` and `ingest.url.completed`. Verify those
rows exist before adding emit calls in the generate-wiki step.

The partial-failure fan-out envelope format (`pages_attempted`, `pages_created`,
`pages_failed`, `failures`) was established in BC-2.03.004. Use the same format here
even though this is SS-02 scope — STORY-019 reuses the same fan-out pattern and the
same result envelope. Consistency between the two ingest pipelines reduces operator
cognitive load.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,200 |
| SS-02 subsystem design | ~1,500 |
| BC-2.02.002, BC-2.02.003, BC-2.02.005 files | ~2,500 |
| VP-015 file | ~800 |
| ADR-008 librarian agent design | ~1,500 |
| integration.bats + skills.bats existing content | ~3,000 |
| event-catalog.json (STORY-014 deliverable) | ~2,000 |
| **Total** | **~14,500** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Defuddle fetch wrapper and duplicate guard — STORY-016.
- Manifest-write helper — STORY-016.
- Sub-linear latency gate (O(log n) assertion) — STORY-018.
- Local source ingest — STORY-019.
- `brain:librarian` agent implementation — EPIC-04 (wiki layer).

## Anchors

- BC-2.02.002: `behavioral-contracts/ss-02/BC-2.02.002.md`
- BC-2.02.003: `behavioral-contracts/ss-02/BC-2.02.003.md`
- BC-2.02.005: `behavioral-contracts/ss-02/BC-2.02.005.md`
- VP-015: `architecture/verification-properties/VP-015-url-ingest-pipeline.md`
- SS-02: `architecture/subsystems/SS-02-url-ingest-pipeline.md`
- ADR-008: `architecture/adr/ADR-008-librarian-agent-design.md`
