---
artifact_type: story
story_id: STORY-029
epic_id: EPIC-06
title: "/brain:write skill — full piece in author's voice + companion posts + hero prompt"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-08]
behavioral_contracts: [BC-2.08.002, BC-2.08.003]
vps: [VP-019]
dependencies: [STORY-028]
blocks: [STORY-030]
inputs:
  - architecture/subsystems/SS-08-content-brief-writing.md
  - behavioral-contracts/ss-08/BC-2.08.002.md
  - behavioral-contracts/ss-08/BC-2.08.003.md
  - architecture/verification-properties/VP-019-content-brief-pipeline.md
input-hash: ""
# BC status: BC-2.08.002 + BC-2.08.003 assigned; status=draft per Spec-First Gate S-7.01
# Priority: P0 — write skill produces the content artifact that the publishing pipeline publishes
# Dependency rationale: STORY-028 (/brain:brief) must exist because /brain:write takes a
# brief file as its mandatory input; end-to-end tests require a valid brief fixture.
# Blocks STORY-030 because the draft file produced here is what the publishing skill consumes.
---

# STORY-029: `/brain:write` skill — full piece in author's voice + companion posts + hero prompt

## Goal

Deliver the `/brain:write <brief-path>` skill that takes a content brief (produced by
STORY-028) and generates a full article or LinkedIn post in the author's voice at
`drafts/{platform}/{slug}-draft.md`. Support for `--companion-posts` (3 companion posts)
and `--hero-prompt` (hero image prompt) flags is also delivered here. After this story
the operator has a complete brief → draft pipeline.

## User Value

As a brain-factory operator, I want to run `/brain:write briefs/content/my-brief.md`
so that I get a full, publication-ready draft in my voice — plus companion social posts
and a hero image prompt when I pass the optional flags — without having to write from a
blank page.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.08.002 | `/brain:write <brief-path>` produces a full piece in the author's voice from a brief path | P0 |
| BC-2.08.003 | `/brain:write` supports `--companion-posts`, `--hero-prompt` flags | P1 |

## Acceptance Criteria

### Write skill core (BC-2.08.002)

**AC-001** — When passed a valid brief path, `/brain:write <brief-path>` writes a full
draft to `drafts/{platform}/{slug}-draft.md`. The draft frontmatter includes
`status: draft`, `brief_path` (the source brief path), `platform`, and `created`.
(traces to BC-2.08.002 postcondition 1, postcondition 3)

**AC-002** — After the draft is written, `validate-voice-avoid-list.sh` fires via
PostToolUse (advisory exit 1 if any avoid-list terms are present). The skill surfaces
any advisory to the operator but exits 0 overall — the voice hook is advisory-only,
not blocking.
(traces to BC-2.08.002 postcondition 2, invariant 2)

**AC-003** — The draft is always written to the `drafts/{platform}/` directory — never
directly to `to-publish/` or `published/`.
(traces to BC-2.08.002 invariant 1)

**AC-004** — When the brief path does not exist, the skill emits E-WRITE-001:
"Brief not found at <path>." and exits 2.
(traces to BC-2.08.002 edge case EC-001)

**AC-005** — The skill exits 0 on successful draft creation (even if the voice hook
advisory fires).
(traces to BC-2.08.002 postcondition 4; edge case EC-002)

### Companion posts flag (BC-2.08.003)

**AC-006** — When `--companion-posts` is passed, the skill generates exactly 3
companion posts, each written to `drafts/linkedin/companions/{slug}-companion-{N}.md`
(N = 1, 2, 3). Each companion post has a distinct insight not duplicated from the
main article or the other companions.
(traces to BC-2.08.003 postcondition (--companion-posts) 1, 2)

**AC-007** — When the main article is a LinkedIn short post (< 3000 chars), companion
posts are micro-companions (< 500 chars each).
(traces to BC-2.08.003 edge case EC-002)

### Hero prompt flag (BC-2.08.003)

**AC-008** — When `--hero-prompt` is passed, a hero image prompt file is written to
`drafts/assets/{slug}-hero-prompt.md`. The prompt describes visual concept, style,
mood, and key elements.
(traces to BC-2.08.003 postcondition (--hero-prompt) 1, 2)

**AC-009** — Omitting both flags produces only the main draft article. Both flags may
be passed simultaneously and both outputs are generated.
(traces to BC-2.08.003 invariant 1; edge case EC-001)

### Skill compliance

**AC-010** — The `write.md` SKILL.md passes all meta-lint assertions: frontmatter has
`name: write`, `description`, `argument-hint`, and `allowed-tools` as a non-empty YAML
list; body has the 6 canonical sections in order; Iron Law body ≤ 200 chars; Red Flags
has ≥ 1 bullet; Procedure has ≥ 1 numbered item; no `.claude/templates/` hardcoding.
(traces to BC-2.08.002; CLAUDE.md §Meta-Lint Contract SKILL.md surface)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/write/SKILL.md` with complete
   frontmatter (`name: write`, `description: "Produce a full piece in the author's
   voice from a content brief"`, `argument-hint: "<brief-path> [--companion-posts]
   [--hero-prompt]"`, `allowed-tools: [Read, Write]`) and the 6-section body skeleton.
   Iron Law: "Output always goes to `drafts/{platform}/` — never skip directly to
   `to-publish/` or `published/`." Procedure steps are empty stubs.

2. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/skills.bats`:
   - `"brain:write: draft created with correct frontmatter (BC-2.08.002)"` — creates
     fixture brief; invokes write skill; asserts `drafts/linkedin/*.md` exists with
     `status: draft` and `brief_path` frontmatter; exits 0.
   - `"brain:write: brief not found → E-WRITE-001 exit 2 (BC-2.08.002 EC-001)"` —
     passes nonexistent brief path; asserts exit 2 + E-WRITE-001 message.
   - `"brain:write: --companion-posts generates 3 companion files (BC-2.08.003)"` —
     invokes with `--companion-posts`; asserts exactly 3 files in
     `drafts/linkedin/companions/` matching `*-companion-?.md`; each distinct.
   - `"brain:write: --hero-prompt generates prompt file (BC-2.08.003)"` — invokes with
     `--hero-prompt`; asserts `drafts/assets/*-hero-prompt.md` exists with non-empty body.
   - `"brain:write: no flags → only main draft, no companion or hero files (BC-2.08.003)"` —
     invokes without flags; asserts `drafts/linkedin/companions/` is empty or absent.
   - `"write SKILL.md: meta-lint compliance"` — meta-lint assertions on `write/SKILL.md`.
   Run bats — confirm all 6 tests fail (Red Gate confirmed).

3. **[impl]** Implement `write` skill Procedure in SKILL.md:
   - Step 1: Validate `<brief-path>` exists and has ONE THING / PROOF / TRANSFORMATION
     sections. If missing → emit E-WRITE-001; exit 2.
   - Step 2: Extract `topic` slug and `platform` from brief frontmatter (default
     platform: `linkedin`).
   - Step 3: Determine output path `drafts/{platform}/{slug}-draft.md`.
   - Step 4: Ask `brain:writer` agent to produce the full piece. Prompt must specify:
     author voice (from `CLAUDE.md`), the ONE THING (lead), PROOF points (body), and
     TRANSFORMATION (close). Output must fit LinkedIn post format (≤ 3000 chars) or
     article format (≥ 3000 chars) depending on topic scope.
   - Step 5: Write `drafts/{platform}/{slug}-draft.md` with frontmatter
     (`status: draft`, `brief_path`, `platform`, `created`, `embedding_status: pending`).
   - Step 6: If `--companion-posts` passed → ask `brain:writer` agent to generate 3
     companion posts; write to `drafts/linkedin/companions/{slug}-companion-{1,2,3}.md`.
   - Step 7: If `--hero-prompt` passed → ask `brain:writer` agent to generate hero image
     prompt; write to `drafts/assets/{slug}-hero-prompt.md`.
   - Step 8: Exit 0. Voice hook fires automatically on draft write via PostToolUse.

4. **[green]** Run `bats tests/skills.bats -f "brain:write\|write SKILL"` — all 6
   tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Valid brief path | Draft in `drafts/linkedin/`; correct frontmatter; exit 0 | happy-path | BC-2.08.002 canonical test vector 1 |
| Non-existent brief path | E-WRITE-001; exit 2 | error | BC-2.08.002 EC-001 |
| `--companion-posts` | 3 companion files in `drafts/linkedin/companions/`; exit 0 | happy-path | BC-2.08.003 canonical test vector 1 |
| `--hero-prompt` | Hero prompt in `drafts/assets/`; exit 0 | happy-path | BC-2.08.003 canonical test vector 2 |
| Both flags simultaneously | Main draft + 3 companions + hero prompt; exit 0 | happy-path | BC-2.08.003 EC-001 |
| No flags | Only main draft; no companion/hero files | happy-path | BC-2.08.003 invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-019 | Draft written to `drafts/{platform}/` | `tests/skills.bats` |
| VP-019 | Voice hook fires after write (PostToolUse integration) | `tests/skills.bats` |
| (no VP — P1) | `--companion-posts` creates 3 files | `tests/skills.bats` |
| (no VP — P1) | `--hero-prompt` creates prompt file | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-08-content-brief-writing.md`:

1. Companion posts always go to `drafts/linkedin/companions/` regardless of the main
   article's target platform. The `linkedin` subdirectory is hardcoded for companion
   posts per BC-2.08.003 invariant 2.

2. Hero prompt goes to `drafts/assets/{slug}-hero-prompt.md` — note `drafts/assets/`,
   not `briefs/content/`. The hero prompt is a production-asset draft, not a brief.

3. The `validate-voice-avoid-list.sh` hook fires on `briefs/content/*-draft.md` matches
   only. The write skill outputs to `drafts/{platform}/{slug}-draft.md` — this path
   DOES match the `*-draft.md` suffix pattern but NOT the `briefs/content/` prefix
   pattern. Per SS-08 v1.1: the hook matcher is `briefs/content/*-draft.md`; drafts
   in `drafts/linkedin/` are NOT subject to the voice hook via automatic PostToolUse.
   The operator reviews voice quality during adversarial review (EPIC-09 STORY-TBD).

4. The `brain:writer` agent is the only LLM-facing component. File I/O (path
   resolution, flag parsing, file writes) is deterministic bash and fully bats-testable
   with a mocked writer.

5. Platform default is `linkedin`. If the brief frontmatter contains a `platform` field,
   use that value. Otherwise default to `linkedin`.

**Forbidden dependencies:**
- `write` skill: must NOT write to `to-publish/` or `published/` directly.
- `write` skill: must NOT call any publishing API.
- `write` skill: must NOT read `sources/` directly.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | Frontmatter field extraction in bats assertions |
| `grep` / `find` | POSIX | Companion file existence assertions |
| `date` | GNU/BSD | `created` timestamp in draft frontmatter |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/write/SKILL.md` | Create | Write skill with meta-lint-compliant structure |
| `plugins/brain-factory/tests/skills.bats` | Modify | Add 6 failing-then-passing write test blocks |

Files NOT to modify: any file under `.factory/`, any hook script, `plugin.json`,
`hooks.json`, any prior story file.

## Previous Story Intelligence

STORY-028 (`/brain:brief`) establishes the `briefs/content/{slug}-brief.md` brief
format (frontmatter fields: `topic`, `created`, `status: draft`, `source_wiki_pages`).
Confirm these field names in the brief fixture used by the write skill's bats tests;
the write skill reads `topic` to derive the output slug and `platform` to route the
draft. The `brain:writer` agent was referenced but not created in STORY-028 — check
whether an AGENT.md exists; if not, create a minimal one with `allowed-tools: [Read,
Write]` as part of this story's file structure scope.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,200 |
| SS-08 subsystem design | ~900 |
| BC-2.08.002 file | ~700 |
| BC-2.08.003 file | ~650 |
| VP-019 file (bats spec) | ~2,200 |
| STORY-028 spec (brief format reference) | ~2,800 |
| Existing `skills.bats` (for test context) | ~2,000 |
| `brain:writer` AGENT.md | ~800 |
| **Total** | **~13,250** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Voice avoid-list hook wiring — EPIC-02 (STORY-010).
- Publishing state machine and `/brain:publish-content` — STORY-030.
- Adversarial review of the draft — EPIC-09.
- `--companion-posts` for non-LinkedIn platforms — future extension.

## Anchors

- BC-2.08.002: `behavioral-contracts/ss-08/BC-2.08.002.md`
- BC-2.08.003: `behavioral-contracts/ss-08/BC-2.08.003.md`
- SS-08: `architecture/subsystems/SS-08-content-brief-writing.md`
- VP-019: `architecture/verification-properties/VP-019-content-brief-pipeline.md`
- STORY-028: `stories/stories/STORY-028.md` (brief skill — produces the input for write)
- STORY-027: `stories/stories/STORY-027.md` (scaffold — creates `drafts/linkedin/`)
