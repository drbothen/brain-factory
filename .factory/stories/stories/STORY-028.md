---
artifact_type: story
story_id: STORY-028
epic_id: EPIC-06
title: "/brain:brief skill — ONE THING / PROOF / TRANSFORMATION content brief"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-08]
behavioral_contracts: [BC-2.08.001]
vps: [VP-019]
dependencies: [STORY-027, STORY-025]
blocks: [STORY-029]
inputs:
  - architecture/subsystems/SS-08-content-brief-writing.md
  - behavioral-contracts/ss-08/BC-2.08.001.md
  - architecture/verification-properties/VP-019-content-brief-pipeline.md
input-hash: ""
# BC status: BC-2.08.001 assigned; status=draft per Spec-First Gate S-7.01
# Priority: P0 — brief is the first step in the brain → brief → write → publish pipeline
# Dependency rationale:
#   STORY-027 scaffolds `briefs/content/` directory used as output target.
#   STORY-025 (/brain:synthesize) produces synthesis briefs that brief reads as context;
#   the brief skill may read these when generating PROOF points, but it is not a hard
#   runtime dependency — the test fixtures seed wiki pages directly.
---

# STORY-028: `/brain:brief` skill — ONE THING / PROOF / TRANSFORMATION content brief

## Goal

Deliver the `/brain:brief <topic>` skill that synthesizes relevant wiki pages and
recent synthesis briefs into a structured content brief at
`briefs/content/{slug}-brief.md`. The brief contains the three mandatory sections
(ONE THING / PROOF / TRANSFORMATION) with PROOF points that cite real wiki page slugs.
After this story an operator can generate a structured brief from their accumulated
knowledge in one command.

## User Value

As a brain-factory operator, I want to run `/brain:brief "my topic"` so that my wiki
knowledge is synthesized into a structured ONE THING / PROOF / TRANSFORMATION brief
I can hand directly to `/brain:write` — skipping the blank-page problem entirely.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.08.001 | `/brain:brief` generates a content brief in ONE THING / PROOF / TRANSFORMATION format | P0 |

## Acceptance Criteria

### Brief generation (BC-2.08.001)

**AC-001** — When the brain has at least 1 wiki page relevant to the given topic,
`/brain:brief <topic>` creates `briefs/content/{slug}-brief.md` containing all three
mandatory sections: `## ONE THING`, `## PROOF`, and `## TRANSFORMATION`.
(traces to BC-2.08.001 postcondition 1)

**AC-002** — The brief frontmatter includes `topic`, `created`, `status: draft`, and
`source_wiki_pages: [...]`. The `source_wiki_pages` array is non-empty and lists the
wiki page slugs that contributed to the PROOF section.
(traces to BC-2.08.001 postcondition 2)

**AC-003** — The skill exits 0 and prints the brief path to the operator.
(traces to BC-2.08.001 postcondition 3)

**AC-004** — Every wikilink citation in the PROOF section (`[[slug]]`) resolves to an
actual file in `wiki/{type}/{slug}.md`. No hallucinated citations are present — a slug
that does not exist in the wiki causes the brief to be rejected with an advisory.
(traces to BC-2.08.001 invariant 2)

**AC-005** — When the brain has no wiki pages relevant to the topic, the skill emits
advisory text: "No wiki content found for topic '<topic>'. Ingest relevant sources
first." and exits 1.
(traces to BC-2.08.001 edge case EC-001)

**AC-006** — When more than 50 wiki pages are potentially relevant, the synthesizer
selects the 20 most relevant pages (ranked by semantic proximity to the topic) and
proceeds. It does not reject the request.
(traces to BC-2.08.001 edge case EC-002)

**AC-007** — The `brief.md` SKILL.md passes all meta-lint assertions: frontmatter has
`name: brief`, `description`, `argument-hint`, and `allowed-tools` as a non-empty YAML
list; body has the 6 canonical sections in order; Iron Law body ≤ 200 chars; Red Flags
has ≥ 1 bullet; Procedure has ≥ 1 numbered item; no `.claude/templates/` hardcoding.
(traces to BC-2.08.001; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/brief/SKILL.md` with complete
   frontmatter (`name: brief`, `description: "Generate a ONE THING / PROOF / TRANSFORMATION
   content brief from your brain's wiki knowledge"`, `argument-hint: "<topic>"`,
   `allowed-tools: [Read, Write]`) and the 6-section body skeleton. Iron Law:
   "PROOF must cite only wiki slugs that actually exist in the brain — never hallucinate
   citations." Procedure steps are empty stubs.

2. **[failing tests — Red Gate]** In `plugins/brain-factory/tests/skills.bats`, add the
   following failing `@test` blocks (matching the VP-019 bats spec):
   - `"brain:brief: generates brief with all 3 mandatory sections (BC-2.08.001)"` —
     sets up temp brain with 5+ AI-agents wiki pages (fixture); invokes brief skill with
     topic "AI agents"; asserts `briefs/content/` contains a file with `## ONE THING`,
     `## PROOF`, `## TRANSFORMATION` headings; exits 0.
   - `"brain:brief: PROOF citations resolve to real wiki slugs (BC-2.08.001 invariant 2)"` —
     same fixture; extracts all `[[slug]]` references from the PROOF section; asserts
     each slug resolves to a file in `wiki/`.
   - `"brain:brief: no relevant wiki pages → advisory exit 1 (BC-2.08.001 EC-001)"` —
     empty brain; invokes brief with unknown topic; asserts exit 1 + advisory message.
   - `"brief SKILL.md: meta-lint compliance"` — runs meta-lint assertions on
     `skills/brief/SKILL.md` fixture.
   Run bats — confirm all 4 tests fail (Red Gate confirmed).

3. **[impl]** Implement `brief` skill Procedure in SKILL.md:
   - Step 1: Slugify the topic argument to `{slug}` (lowercase, spaces → hyphens).
   - Step 2: Search `wiki/` for pages referencing the topic (use `grep -rl "<topic>"
     wiki/`). If 0 results → emit advisory; exit 1.
   - Step 3: If > 50 results, select the 20 most recently modified (by `ls -t`) for
     context budget management.
   - Step 4: Ask `brain:synthesizer` agent to generate the brief using the selected
     wiki pages. Prompt must require: ONE THING (single thesis sentence), PROOF
     (≥ 3 bullet points, each citing `[[slug]]` from the provided pages),
     TRANSFORMATION (what the reader's view changes to), 3 hooks, 3 closers.
   - Step 5: Validate that every `[[slug]]` in the PROOF section resolves in `wiki/`.
     If any slug is missing, re-prompt once to substitute with a valid slug; if still
     unresolved, emit advisory and exit 1.
   - Step 6: Write `briefs/content/{slug}-brief.md` with frontmatter and body.
   - Step 7: Exit 0 with brief path printed.

4. **[green]** Run `bats tests/skills.bats -f "brain:brief\|brief SKILL"` — all 4
   tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `/brain:brief "AI agents"` (5 relevant wiki pages seeded) | Brief with ONE THING / PROOF / TRANSFORMATION; valid frontmatter; exit 0 | happy-path | BC-2.08.001 canonical test vector 1 |
| `/brain:brief "topic with no wiki pages"` | Advisory "No wiki content found…"; exit 1 | edge-case | BC-2.08.001 EC-001 |
| 51 relevant wiki pages | Brief generated using 20 most-recent pages; exit 0 | edge-case | BC-2.08.001 EC-002 |
| Brief PROOF section | All `[[slug]]` citations resolve in `wiki/` | invariant | BC-2.08.001 invariant 2 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-019 | Brief contains all 3 mandatory sections | `tests/skills.bats` |
| VP-019 | PROOF cites real wiki slugs (slug resolution loop) | `tests/skills.bats` |
| VP-019 | No relevant wiki pages → advisory exit 1 | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-08-content-brief-writing.md`:

1. Output path is `briefs/content/{slug}-brief.md` — not `briefs/{slug}.md`. The
   `content/` subdirectory is required per the SS-08 interface specification.

2. The `brain:synthesizer` agent is the only LLM-facing component. All file I/O
   (wiki search, brief write, slug validation) is deterministic bash. Tests mock the
   synthesizer; they do not call a real LLM.

3. The voice avoid-list hook (`validate-voice-avoid-list.sh`) fires automatically on
   `briefs/content/*-draft.md` writes via PostToolUse (BC-2.04.008, EPIC-02). The
   brief skill does NOT call the hook explicitly — the hook fires because of the Write
   to the `briefs/content/` path. The brief skill therefore names its output
   `{slug}-brief.md` (not `{slug}-draft.md`) to avoid triggering the voice hook on
   the brief itself. The voice hook fires on `-draft.md` suffixes only (SS-08 §Voice
   avoid-list enforcement note).

4. `source_wiki_pages` frontmatter lists the actual slugs used in the PROOF section.
   The implementer must populate this array — it is not optional.

5. PostToolUse hooks fire on the Write of the brief file. If the wikilink-integrity
   hook rejects the write (broken wikilinks in the brief body), the brief skill must
   propagate the rejection and exits 2.

**Forbidden dependencies:**
- `brief` skill: must NOT write to `wiki/` — output is `briefs/content/` only.
- `brief` skill: must NOT call LinkedIn API or any publishing endpoint.
- `brief` skill: must NOT read `sources/` directly (read wiki, not raw sources).

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `yq` | 4.x+ | Frontmatter field extraction in bats assertions (VP-019) |
| `grep` | POSIX | Wiki page search and wikilink extraction |
| `awk` | POSIX | PROOF section extraction for slug validation loop |
| `date` | GNU/BSD | `created` timestamp in brief frontmatter |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/brief/SKILL.md` | Create | ONE THING / PROOF / TRANSFORMATION brief skill |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 4 failing-then-passing brief test blocks |

Files NOT to modify: any file under `.factory/`, any hook script, `plugin.json`,
`hooks.json.template`, any prior story file, any other existing bats file.

## Previous Story Intelligence

STORY-027 scaffolds `briefs/content/` as part of the init extension. Confirm that
`briefs/content/` is created by init before writing to it. The `brain:synthesizer`
agent is introduced here for the first time in EPIC-06; confirm its AGENT.md exists
and declares `allowed-tools: [Read, Write]` before wiring the Procedure Step 4 prompt.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,800 |
| SS-08 subsystem design | ~900 |
| BC-2.08.001 file | ~700 |
| VP-019 file (bats spec) | ~2,200 |
| Existing `skills.bats` (for test context) | ~2,000 |
| `brain:synthesizer` AGENT.md | ~800 |
| **Total** | **~9,400** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:write` — STORY-029 (takes the brief produced here as its input).
- Companion posts and hero prompt — STORY-029.
- Voice avoid-list hook wiring — EPIC-02 (STORY-010).
- Publishing pipeline — STORY-030.
- Integration with synthesis briefs as additional PROOF context — the brief skill may
  optionally read the most recent synthesis brief (from EPIC-05 STORY-025), but this
  is a quality enhancement, not a correctness requirement.

## Anchors

- BC-2.08.001: `behavioral-contracts/ss-08/BC-2.08.001.md`
- SS-08: `architecture/subsystems/SS-08-content-brief-writing.md`
- VP-019: `architecture/verification-properties/VP-019-content-brief-pipeline.md`
- STORY-027: `stories/stories/STORY-027.md` (scaffold — creates `briefs/content/`)
- STORY-025: `stories/stories/STORY-025.md` (synthesize — produces synthesis briefs used as context)
