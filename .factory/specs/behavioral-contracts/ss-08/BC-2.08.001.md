---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.08.001: `/brain:brief` generates a content brief in ONE THING / PROOF / TRANSFORMATION format

## Description

`/brain:brief <topic>` generates a content brief for a given topic by synthesizing relevant wiki pages and recent synthesis briefs. The output brief must follow the ONE THING / PROOF / TRANSFORMATION format from the brain-factory methodology: one clear thesis, proof points from the wiki knowledge base, and the transformation for the reader. The brief is written to `briefs/content/{slug}-brief.md`.

## Preconditions

1. Working directory is a valid brain with at least 1 wiki page related to the topic.
2. `brain:synthesizer` agent is available.

## Postconditions

1. `briefs/content/{slug}-brief.md` is created with the mandatory brief structure: ONE THING, PROOF, TRANSFORMATION, plus 3 hooks and 3 closers as per the methodology.
2. Brief frontmatter includes: `topic`, `created`, `status: draft`, `source_wiki_pages: [...]`.
3. Exit 0 with the brief path printed.

## Invariants

1. The ONE THING / PROOF / TRANSFORMATION format is non-negotiable — the brief must contain all three sections.
2. PROOF points must cite actual wiki page slugs from the brain (not hallucinated citations).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | No wiki pages on topic | Advisory: "No wiki content found for topic '<topic>'. Ingest relevant sources first." Exit 1. |
| EC-002 | Topic is too broad (> 50 potentially relevant pages) | Synthesizer selects the 20 most relevant pages. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `/brain:brief "AI agents"` (5 relevant wiki pages) | Brief with ONE THING / PROOF / TRANSFORMATION; valid frontmatter; exit 0 | happy-path |
| `/brain:brief "topic with no wiki pages"` | Advisory; exit 1 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-019 | Brief contains all 3 mandatory sections | bats skills.bats |
| VP-019 | PROOF cites real wiki slugs | bats skills.bats (verify slug resolution) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-008 ("Content Brief and Writing") per brief §Scope §Phase 0/1 primitives skill #9 (`/brain:brief <topic> — generate a content brief in ONE THING / PROOF / TRANSFORMATION format`). |
| Architecture Module | SS-08: Content Brief and Writing |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#9) |

## Related BCs

- BC-2.08.002 — related to (/brain:write takes the brief as input)
