---
artifact_type: story
story_id: STORY-026
epic_id: EPIC-05
title: "/brain:process-inbox skill — inbox classification and wiki routing"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-11]
behavioral_contracts: [BC-2.11.003]
vps: []
dependencies: [STORY-019, STORY-020]
blocks: []
inputs:
  - architecture/subsystems/SS-11-knowledge-synthesis.md
  - behavioral-contracts/ss-11/BC-2.11.003.md
input-hash: ""
# BC status: BC-2.11.003 assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Priority: P1 — depends on wiki layer (STORY-019/STORY-020) for the target wiki/{type}/
# directories and the PostToolUse hook chain that validates wiki writes.
# No dependency on STORY-024 or STORY-025 — process-inbox is a parallel synthesis
# capability that does not consume the connection or synthesis layer.
---

# STORY-026: `/brain:process-inbox` skill — inbox classification and wiki routing

## Goal

Deliver the `/brain:process-inbox` skill that reads markdown notes from `inbox/`,
classifies each note into one of the 6 wiki types using the `brain:librarian` agent,
writes the classified note as a proper wiki page to `wiki/{type}/{slug}.md` with
mandatory frontmatter, and clears the note from `inbox/`. After this story an operator
can capture quick notes into `inbox/` at any time and batch-process them into the wiki
layer with a single command.

## User Value

As a brain-factory operator, I want to run `/brain:process-inbox` to convert my
unstructured inbox notes into properly typed wiki pages — so that my quick captures
flow into the knowledge graph without requiring me to manually choose a type and write
frontmatter for each one.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.11.003 | `/brain:process-inbox` classifies and routes inbox notes to correct wiki type | P1 |

## Acceptance Criteria

### Inbox Classification and Routing (BC-2.11.003)

**AC-001** — When `inbox/` contains at least one markdown file, `/brain:process-inbox`
classifies each note using `brain:librarian` and writes it to
`wiki/{type}/{slug}.md` where `{type}` is one of: `concepts`, `people`, `frameworks`,
`syntheses`, `observations`, `questions`.
(traces to BC-2.11.003 postcondition 1)

**AC-002** — Every wiki page written by the skill has all mandatory frontmatter fields
populated, including `embedding_status: pending`.
(traces to BC-2.11.003 postcondition 2)

**AC-003** — After a successful run, all inbox notes that were successfully routed are
removed (or archived to `inbox/processed/`) from `inbox/`.
(traces to BC-2.11.003 postcondition 3)

**AC-004** — The skill exits 0 and emits a routing summary listing each note's
classification and destination path.
(traces to BC-2.11.003 postcondition 4)

**AC-005** — When the `brain:librarian` agent cannot confidently classify a note, the
skill defaults to classifying it as `observations/` and proceeds. No note is dropped
due to classification uncertainty.
(traces to BC-2.11.003 invariant 1)

**AC-006** — When `inbox/` is empty (no markdown files), the skill emits advisory text:
"No inbox notes to process." and exits 0.
(traces to BC-2.11.003 edge case EC-001)

**AC-007** — When hook validation rejects a written wiki page (e.g., a frontmatter
schema violation or a broken wikilink), the failing note remains in `inbox/` and is
reported individually in the partial-result summary. Other successfully processed notes
are NOT rolled back.
(traces to BC-2.11.003 edge case EC-002)

**AC-008** — The `process-inbox.md` SKILL.md passes all meta-lint assertions:
frontmatter has `name: process-inbox`, `description`, `argument-hint`, and
`allowed-tools` as a non-empty YAML list; body has the 6 canonical sections in order;
Iron Law body ≤ 200 chars; Red Flags has ≥ 1 bullet; Procedure has ≥ 1 numbered item;
no `.claude/templates/` hardcoding.
(traces to BC-2.11.003; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/process-inbox/SKILL.md` with complete
   frontmatter (`name: process-inbox`, `description`, `argument-hint: ""`,
   `allowed-tools: [Read, Write, Bash]`) and the 6-section body skeleton. Iron Law
   placeholder: "Every inbox note must receive a classification — no note is silently
   dropped." Procedure steps are empty stubs.

2. **[failing tests — Red Gate]** In `plugins/brain-factory/tests/skills.bats`, add the
   following failing `@test` blocks:
   - `"process-inbox: happy path — 5 notes classified and moved to wiki/"` — sets up
     temp brain with 5 inbox notes of varied content; invokes process-inbox; asserts
     each note appears in `wiki/{some-type}/`, `inbox/` is empty (or notes moved to
     `inbox/processed/`), exits 0.
   - `"process-inbox: empty inbox → advisory exit 0"` — empty `inbox/`; asserts
     advisory message and exit 0.
   - `"process-inbox: partial failure — hook reject leaves note in inbox"` — 1 note
     has frontmatter that will fail hook validation; asserts that note remains in
     `inbox/`, other notes are routed; exit summary reports failure.
   - `"process-inbox: default fallback — unclassifiable note goes to observations/"` —
     provides a deliberately ambiguous note; asserts destination is
     `wiki/observations/{slug}.md`.
   - `"process-inbox: SKILL.md meta-lint compliance"` — runs meta-lint assertions on
     `skills/process-inbox/SKILL.md` fixture.
   Run bats — confirm all 5 tests fail (Red Gate confirmed).

3. **[impl]** Implement `process-inbox` skill Procedure in SKILL.md:
   - Step 1: List `inbox/*.md` files (excluding `inbox/processed/`). If empty → emit
     advisory; exit 0.
   - Step 2: For each note in the list:
     a. Read the note content.
     b. Ask `brain:librarian` agent to classify into one of:
        `concepts | people | frameworks | syntheses | observations | questions`.
     c. If classification confidence is below threshold → default to `observations`.
     d. Derive `{slug}` from the note filename (kebab-case the stem).
     e. Construct mandatory frontmatter: `title`, `type`, `source_id` (none — inbox
        capture), `created`, `embedding_status: pending`.
     f. Write to `wiki/{type}/{slug}.md` (triggers PostToolUse hook chain).
     g. If write succeeds → archive source note to `inbox/processed/{original-name}`.
     h. If write fails (hook rejects) → leave note in `inbox/`; record failure.
   - Step 3: Emit routing summary: "Processed N notes. Succeeded: M. Failed: K."
     For failures, list note name and rejection reason.
   - Step 4: Exit 0 if any notes succeeded (or inbox was empty); exit 1 if ALL notes
     failed processing.

4. **[green]** Run `bats tests/skills.bats -f process-inbox` — all process-inbox tests
   pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| 5 inbox notes of varied content | All 5 in wiki/{type}/; inbox/processed/ has originals; routing summary; exit 0 | happy-path | BC-2.11.003 canonical test vector 1 |
| Empty inbox/ directory | "No inbox notes to process."; exit 0 | edge-case | BC-2.11.003 EC-001 |
| Empty inbox/ | Exit 0 (not 1 — empty inbox is not an error) | edge-case | BC-2.11.003 EC-001 |
| 1 hook-rejected note + 4 valid notes | 4 routed successfully; 1 remains in inbox/; partial summary; exit 0 | partial-failure | BC-2.11.003 EC-002 |
| Ambiguous note content | Classified as observations/ (default fallback) | invariant | BC-2.11.003 invariant 1 |
| process-inbox/SKILL.md file | All meta-lint assertions pass | compliance | CLAUDE.md §Meta-Lint Contract |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no VP — P1/SS-11) | All inbox notes routed to wiki/{type}/ | `tests/skills.bats` |
| (no VP — P1/SS-11) | Inbox cleared after successful run | `tests/skills.bats` |
| (no VP — P1/SS-11) | Partial failure: hook-rejected note remains in inbox | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-11-knowledge-synthesis.md`:

1. The skill writes wiki pages via the normal wiki page creation pipeline (Write tool).
   The PostToolUse hook chain (SS-04) fires on every Write to `wiki/`. The skill must
   not bypass or suppress hook execution. If `validate-frontmatter-schema.sh` fires exit
   2 on a note's page, that note is treated as a failed routing (AC-007).

2. Notes are routed to `wiki/{type}/{slug}.md` — one of the 6 canonical wiki types
   (`concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions`).
   Writing to any other directory is a type-policy violation (caught by
   `validate-page-type-policy.sh`).

3. Partial-failure fan-out is non-negotiable (BC-2.11.003 EC-002, CLAUDE.md §Error
   handling): notes that fail hook validation are reported individually; successfully
   processed notes are not rolled back. The skill must iterate notes independently and
   collect per-note results before emitting the summary.

4. The `brain:librarian` agent is the only LLM-facing component. The classification
   threshold and default fallback logic are deterministic bash (testable without LLM
   invocation using a mocked librarian that returns pre-set classifications).

5. After successful write, the source note is moved to `inbox/processed/` rather than
   deleted. This preserves the operator's original capture for auditability while
   clearing `inbox/` per the postcondition. The `processed/` subdirectory must be
   created if it does not exist.

**Forbidden dependencies:**
- `process-inbox` skill: must NOT directly overwrite existing wiki pages (new slug
  required per source-immutability principle; if slug collision exists, append a suffix).
- `process-inbox` skill: must NOT call `quarantine-fetch.sh` — inbox notes are
  local files, not fetched web content.
- `process-inbox` skill: must NOT read from `sources/` — inbox notes are distinct from
  source documents.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `yq` | 4.x+ | Frontmatter field extraction and writing |
| `find` / `ls` | POSIX | Listing inbox/*.md files |
| `mv` | POSIX | Moving processed notes to inbox/processed/ |
| `mkdir -p` | POSIX | Creating inbox/processed/ if absent |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/process-inbox/SKILL.md` | Create | Inbox classification skill with meta-lint-compliant structure |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 5 failing then passing process-inbox test blocks |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json.template`,
any prior STORY-NNN.md, any other existing bats files or skill files.

## Previous Story Intelligence

STORY-019 (wiki page creation pipeline) produces the `wiki/{type}/` directory structure
that this skill writes into. Confirm the wiki page frontmatter schema (specifically
which fields are mandatory) from STORY-019's AC and from BC-2.05.006 (`embedding_status`
mandatory) before writing the frontmatter construction step.

The partial-failure fan-out pattern used here mirrors BC-2.03.004 (STORY-015,
`/brain:ingest-source`). Reuse the per-item result accumulation pattern from that
implementation: collect `{note, status, path_or_error}` per iteration, then emit the
summary in one pass at the end. Do not mix per-item echo with the final summary.

N/A for prior EPIC-05 stories — `process-inbox` has no dependency on `connect` or
`synthesize`; it is a parallel capability in the same epic.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,100 |
| SS-11 subsystem design | ~900 |
| BC-2.11.003 file | ~750 |
| STORY-019 spec (wiki page creation, frontmatter schema) | ~2,500 |
| Existing skills.bats (for context) | ~2,000 |
| `brain:librarian` agent AGENT.md | ~800 |
| **Total** | **~10,050** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:connect` — STORY-024.
- `/brain:synthesize` — STORY-025.
- Embedding-status progression for routed wiki pages — EPIC-08 (scale architecture).
- LLM-quality tuning of the `brain:librarian` classification prompt — Phase 3 dogfood
  refinement. This story only wires the skill; classification quality is a Phase 3
  concern.
- Source ingest from inbox (processing an inbox note as a source document) — this skill
  creates wiki pages, not source records. Source ingest is EPIC-03.

## Anchors

- BC-2.11.003: `behavioral-contracts/ss-11/BC-2.11.003.md`
- SS-11: `architecture/subsystems/SS-11-knowledge-synthesis.md`
- STORY-019: `stories/stories/STORY-019.md` (wiki page creation — provides target dirs)
- BC-2.05.006: `behavioral-contracts/ss-05/BC-2.05.006.md` (embedding_status mandatory)
- BC-2.11.003 EC-002 / BC-2.03.004: partial-failure fan-out pattern
- CLAUDE.md §Meta-Lint Contract: authoritative SKILL.md assertion list
