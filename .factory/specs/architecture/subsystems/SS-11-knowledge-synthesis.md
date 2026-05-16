---
document_type: subsystem-design
id: SS-11
title: "Knowledge Synthesis and Connection"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-011
created: 2026-05-15
---

# SS-11: Knowledge Synthesis and Connection

## Responsibility

Surfaces non-obvious cross-domain connections across recent ingests, builds a weekly thesis from the connection layer, and classifies / routes inbox notes to the correct wiki type.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.11.001 | `/brain:connect [days]` finds cross-domain connections across recent ingests | P1 |
| BC-2.11.002 | `/brain:synthesize` builds a weekly thesis from the connection layer | P1 |
| BC-2.11.003 | `/brain:process-inbox` classifies and routes inbox notes to correct wiki type | P1 |

## Interfaces

**Inbound:** `/brain:connect [days]` (default: 7); `/brain:synthesize`; `/brain:process-inbox`

**Outbound:** connection layer at `wiki/syntheses/<date>-connections.md`; weekly synthesis at `wiki/syntheses/<date>-weekly.md`; classified inbox notes moved to `wiki/{type}/{slug}.md`

## Key Design

### Connection discovery (`/brain:connect`)

The skill reads `wiki/log.md` to identify pages generated in the last N days (bounded context — only the log subset, not the full corpus). For each recent page, it reads the page content and asks the LLM to find non-obvious connections to other pages in the same time window.

Connections are written to `wiki/syntheses/<date>-connections.md` as a list of `[[page-A]] ↔ [[page-B]]: <connection rationale>` entries.

Scale discipline: the skill reads only the N-day window from wiki/log.md (bounded) + the corresponding page contents. It does NOT read the full wiki corpus. At 7 days + 5 pages/day = 35 pages, this is a bounded context budget.

### Weekly synthesis (`/brain:synthesize`)

Reads the most recent connections file and the most recent daily briefs (from `.brain/cycles/`) to build a weekly thesis statement. Writes to `wiki/syntheses/<date>-weekly.md`. The thesis is the input to the next `/brain:brief` session.

### Inbox processing (`/brain:process-inbox`)

Reads `inbox/*.md` notes (quick captures from the operator). For each note, classifies it as one of 6 wiki types (concept/person/framework/synthesis/observation/question) and writes it to the correct `wiki/{type}/` directory. Moves processed notes to `inbox/processed/`. Partial-failure fan-out: notes that fail hook validation are reported individually; successfully processed notes are not rolled back.

## Purity Classification

**Effectful shell.** LLM-based connection discovery is non-deterministic. The inbox classification routing (given a note, select the wiki type) has a deterministic component (type taxonomy is fixed to 6 options) but the LLM decision itself is non-deterministic.

## Dependencies

- SS-05 (Wiki Layer): connections + syntheses written as wiki pages; wikilinks validated
- SS-04 (Hook Chain): PostToolUse hooks fire on all wiki writes
- SS-08 (Content Brief and Writing): synthesis feeds into `/brain:brief`

## Test Surface

- `bats/skills.bats` — connect output has valid wikilinks; synthesize output has valid frontmatter; process-inbox moves file from inbox/ to wiki/{type}/
