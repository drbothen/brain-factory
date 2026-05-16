---
document_type: subsystem-design
id: SS-08
title: "Content Brief and Writing"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-008
created: 2026-05-15
---

# SS-08: Content Brief and Writing

## Responsibility

Generates structured content briefs in ONE THING / PROOF / TRANSFORMATION format from a topic, produces full written pieces in the author's voice from a brief, enforces the voice avoid-list at brief-draft time, and supports companion post and hero image prompt generation.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.08.001 | `/brain:brief <topic>` generates brief in ONE THING / PROOF / TRANSFORMATION format | P0 |
| BC-2.08.002 | `/brain:write <brief-path>` produces full piece in author's voice | P0 |
| BC-2.08.003 | `/brain:write` supports `--companion-posts`, `--hero-prompt` flags | P1 |
| BC-2.08.004 | Voice avoid-list (30 entries) enforced on brief drafts | P1 |

## Interfaces

**Inbound:** `/brain:brief <topic>`; `/brain:write <brief-path> [--companion-posts] [--hero-prompt]`

**Outbound:** brief file at `briefs/content/<topic-slug>.md`; published piece at `drafts/linkedin/<slug>.md`; companion posts at `drafts/linkedin/companions/`; hero image prompt at `briefs/content/<slug>-hero-prompt.md`

**Emitted events:** `brief.generated`, `write.started`, `write.completed`, `voice.avoid_list_advisory`

## Key Design

### Brief format

The ONE THING / PROOF / TRANSFORMATION brief template (from the author's writing methodology):
```markdown
---
title: "<topic>"
status: draft
created: <date>
---
# ONE THING
<The single insight the piece delivers — one sentence>

# PROOF
<Evidence, examples, data that prove the ONE THING>

# TRANSFORMATION
<How the reader changes after reading — what they do differently>

# Voice Notes
<Author-specific voice guidance for this topic>
```

### Voice avoid-list enforcement (BC-2.08.004)

`validate-voice-avoid-list.sh` (PostToolUse, advisory exit 1) fires when a file is written to `briefs/`. The hook reads `rules/voice-avoid-list.txt` (30 entries: terms like "utilize", "leverage", "synergy", "deep dive", etc.) and advises the operator of any matches. Advisory only — does not block the brief write. The operator reviews and revises before publishing.

### Companion posts and hero prompt (BC-2.08.003)

`--companion-posts`: generates 3 companion posts (LinkedIn-native insights derived from the piece, each ~300 chars); written to `drafts/linkedin/companions/<slug>-companion-N.md`.

`--hero-prompt`: generates an image generation prompt for a hero image; written to `briefs/content/<slug>-hero-prompt.md`.

Both are P1 (v0.9) features; the skill stubs them out in v0.1 with a "not yet implemented" advisory.

## Purity Classification

**Effectful shell.** Content generation is LLM-based (non-deterministic). The voice avoid-list matching is a pure function (grep on known pattern set) and tested independently.

## Dependencies

- SS-04 (Hook Chain): validate-voice-avoid-list.sh fires on brief writes
- SS-07 (Adversarial Review): `/brain:adversary-review` reviews the written piece
- SS-09 (Publishing): written piece moves through draft → ready → published pipeline

## Test Surface

- `bats/skills.bats` — brief frontmatter schema present; ONE THING section non-empty; voice hook fires on brief write; avoid-list advisory on known-trigger words
- Integration: end-to-end brief → write → adversary-review pipeline in local-dev-test.sh
