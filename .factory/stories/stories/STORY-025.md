---
artifact_type: story
story_id: STORY-025
epic_id: EPIC-05
title: "/brain:synthesize skill — weekly thesis from connection layer"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-11]
behavioral_contracts: [BC-2.11.002]
vps: []
dependencies: [STORY-024]
blocks: []
inputs:
  - architecture/subsystems/SS-11-knowledge-synthesis.md
  - behavioral-contracts/ss-11/BC-2.11.002.md
input-hash: ""
# BC status: BC-2.11.002 assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Priority: P1 — depends on STORY-024 (/brain:connect) to produce the connection brief
# that this skill reads as its primary input.
# Dependency rationale: /brain:synthesize reads the connections file produced by
# /brain:connect (STORY-024); it cannot be tested end-to-end without a connection brief.
---

# STORY-025: `/brain:synthesize` skill — weekly thesis from connection layer

## Goal

Deliver the `/brain:synthesize` skill that reads the most recent connection brief from
`briefs/weekly/` and produces a weekly synthesis brief at
`briefs/weekly/synthesis-{YYYY-MM-DD}.md` containing a clear thesis statement, supporting
wiki evidence, and implications. After this story the operator can progress from
"I see connections" to "I have a thesis I can develop into content."

## User Value

As a brain-factory operator, I want to run `/brain:synthesize` each week so that the
cross-domain connections I discovered are distilled into a single thesis statement with
supporting evidence — giving me a concrete point of view I can develop into published
content via the `/brain:brief` pipeline.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.11.002 | `/brain:synthesize` builds a weekly thesis from the connection layer | P1 |

## Acceptance Criteria

### Weekly Synthesis (BC-2.11.002)

**AC-001** — When at least one connection brief exists in `briefs/weekly/`,
`/brain:synthesize` writes `briefs/weekly/synthesis-{YYYY-MM-DD}.md` containing all
three required structural elements: a thesis statement, supporting evidence from the
wiki (cited via wikilinks), and implications.
(traces to BC-2.11.002 postcondition 1)

**AC-002** — The skill exits 0 after writing the synthesis brief.
(traces to BC-2.11.002 postcondition 2)

**AC-003** — All wiki citations in the synthesis file use wikilinks (`[[page-slug]]`);
no hallucinated citations are present — every cited page must resolve in `wiki/`.
(traces to BC-2.11.002 invariant 1)

**AC-004** — Each invocation of `/brain:synthesize` creates a new dated file
(`synthesis-{YYYY-MM-DD}.md`). It does not overwrite a synthesis file from a prior run.
If a synthesis file for today already exists, the skill either appends a suffix
(`synthesis-{YYYY-MM-DD}-2.md`) or emits a warning and exits 1 — it never overwrites.
(traces to BC-2.11.002 invariant 2)

**AC-005** — When no connection briefs exist in `briefs/weekly/`, the skill emits
advisory text: "No connection briefs found. Run /brain:connect first." and exits 1.
(traces to BC-2.11.002 edge case EC-001)

**AC-006** — The `synthesize.md` SKILL.md passes all meta-lint assertions: frontmatter
has `name: synthesize`, `description`, `argument-hint`, and `allowed-tools` as a
non-empty YAML list; body has the 6 canonical sections in order; Iron Law body ≤ 200
chars; Red Flags has ≥ 1 bullet; Procedure has ≥ 1 numbered item; no
`.claude/templates/` hardcoding.
(traces to BC-2.11.002; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/synthesize/SKILL.md` with complete
   frontmatter (`name: synthesize`, `description`, `argument-hint: ""`,
   `allowed-tools: [Read, Write]`) and the 6-section body skeleton. Iron Law placeholder:
   "Read only the most recent connections brief; never read the full wiki corpus directly."
   Procedure steps are empty stubs.

2. **[failing tests — Red Gate]** In `plugins/brain-factory/tests/skills.bats`, add the
   following failing `@test` blocks:
   - `"synthesize: happy path — synthesis file written with thesis and wikilinks"` — sets
     up temp brain with `briefs/weekly/connections-YYYY-MM-DD.md` fixture; invokes
     synthesize; asserts `briefs/weekly/synthesis-*.md` exists, contains `[[`, exits 0.
   - `"synthesize: no overwrite — second run creates distinct file"` — invokes synthesize
     twice on the same day; asserts 2 distinct files exist (or second run exits 1 with
     warning), not 1 overwritten file.
   - `"synthesize: no connection briefs → advisory exit 1"` — empty `briefs/weekly/`;
     asserts advisory message and exit 1.
   - `"synthesize: SKILL.md meta-lint compliance"` — runs meta-lint assertions on
     `skills/synthesize/SKILL.md` fixture.
   Run bats — confirm all 4 tests fail (Red Gate confirmed).

3. **[impl]** Implement `synthesize` skill Procedure in SKILL.md:
   - Step 1: List `briefs/weekly/connections-*.md` files; select the most recent by
     filename date.
   - Step 2: If no connection brief found → emit advisory; exit 1.
   - Step 3: Determine target filename `briefs/weekly/synthesis-{YYYY-MM-DD}.md`; if
     file exists append `-2` (then `-3`, etc.) to avoid overwrite.
   - Step 4: Read the selected connection brief and any prior synthesis files in
     `.brain/cycles/` for context.
   - Step 5: Ask `brain:synthesizer` agent to identify an emerging thesis from the
     connections; request supporting wiki page citations and implications.
   - Step 6: Write `briefs/weekly/synthesis-{YYYY-MM-DD}.md` with frontmatter
     (`title`, `date`, `type: synthesis`, `embedding_status: pending`) and body
     sections: `## Thesis`, `## Supporting Evidence`, `## Implications`.
   - Step 7: Exit 0.

4. **[green]** Run `bats tests/skills.bats -f synthesize` — all synthesize tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| 1 connection brief in briefs/weekly/ | synthesis-YYYY-MM-DD.md created with thesis + citations; exit 0 | happy-path | BC-2.11.002 canonical test vector 1 |
| No briefs/weekly/ connection files | Advisory "Run /brain:connect first"; exit 1 | edge-case | BC-2.11.002 EC-001 |
| Second run on same day (synthesis file already exists) | New distinct file (suffix -2) or warning + exit 1; no overwrite | invariant | BC-2.11.002 invariant 2 |
| synthesize/SKILL.md file | All meta-lint assertions pass | compliance | CLAUDE.md §Meta-Lint Contract |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no VP — P1/SS-11) | Synthesis brief created with thesis and wiki citations | `tests/skills.bats` |
| (no VP — P1/SS-11) | No connection briefs → advisory exit 1 | `tests/skills.bats` |
| (no VP — P1/SS-11) | No overwrite invariant enforced | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-11-knowledge-synthesis.md`:

1. The skill reads the most recent connection brief from `briefs/weekly/` as its
   primary input. It may also read prior synthesis files from `.brain/cycles/` for
   continuity context. It MUST NOT read the full wiki corpus — this preserves the
   bounded-context discipline.

2. Output is written to `briefs/weekly/synthesis-{YYYY-MM-DD}.md`. This is the `briefs/`
   layer, not `wiki/`. The synthesis brief becomes input for `/brain:brief` (EPIC-06);
   it is not a wiki page and does not trigger wiki-layer hook validation.

3. The `brain:synthesizer` agent is the only LLM-facing component. All file I/O
   (finding the brief, writing the output) is deterministic bash and bats-testable with
   a mocked synthesizer.

4. The no-overwrite invariant (AC-004) is behavioral: the skill checks for an existing
   file before writing, not after. The check must be atomic enough that two concurrent
   invocations do not race to create the same file — prefer checking + appending suffix
   in a single pipeline rather than check-then-write with a gap.

5. PostToolUse hooks fire on the Write of the synthesis file. The skill must not
   bypass hook execution. If the hook rejects the write (malformed frontmatter, bad
   wikilinks), the skill propagates the rejection and exits 2.

**Forbidden dependencies:**
- `synthesize` skill: must NOT read `sources/` directly.
- `synthesize` skill: must NOT write to `wiki/` — output goes to `briefs/weekly/`.
- `synthesize` skill: must NOT call `quarantine-fetch.sh` — no web fetching.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `yq` | 4.x+ | Frontmatter field extraction in SKILL.md compliance check |
| `date` | GNU/BSD | `YYYY-MM-DD` timestamp in output filename |
| `ls` / `find` | POSIX | Locating most-recent connections brief by filename sort |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/synthesize/SKILL.md` | Create | Weekly synthesis skill with meta-lint-compliant structure |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 4 failing then passing synthesize test blocks |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json.template`,
any prior STORY-NNN.md, any other existing bats files or skill files.

## Previous Story Intelligence

STORY-024 (`/brain:connect`) produces `briefs/weekly/connections-{YYYY-MM-DD}.md` —
the primary input for this skill. Confirm the connection brief format (frontmatter
fields + body line format `- [[A]] ↔ [[B]]: <rationale>`) before implementing Step 4.
The synthesizer prompt in Step 5 should reference the connection entries by their
wikilink pairs; test that the synthesizer's output cites actual wiki slugs that exist
in the test brain fixture.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,600 |
| SS-11 subsystem design | ~900 |
| BC-2.11.002 file | ~650 |
| STORY-024 spec (for connection brief format) | ~2,800 |
| Existing skills.bats (for context) | ~2,000 |
| `brain:synthesizer` agent AGENT.md | ~800 |
| **Total** | **~9,750** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:connect` — STORY-024 (predecessor; produces the input brief).
- `/brain:process-inbox` — STORY-026.
- Integration with `/brain:brief` pipeline — EPIC-06 (reads the synthesis file produced
  here, but that wiring is EPIC-06's responsibility).
- Embedding-status progression for synthesis briefs — EPIC-08.

## Anchors

- BC-2.11.002: `behavioral-contracts/ss-11/BC-2.11.002.md`
- SS-11: `architecture/subsystems/SS-11-knowledge-synthesis.md`
- STORY-024: `stories/stories/STORY-024.md` (connect skill — produces connection brief)
- CLAUDE.md §Meta-Lint Contract: authoritative SKILL.md assertion list
