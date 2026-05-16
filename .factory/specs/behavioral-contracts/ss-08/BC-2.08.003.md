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
subsystem: "SS-TBD"
capability: "CAP-008"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.08.003: `/brain:write` supports `--companion-posts`, `--hero-prompt` flags

## Description

`/brain:write` supports two optional flags absorbed from wclaude: `--companion-posts` generates 3–5 companion social posts atomized from the main article (written to `drafts/linkedin/companions/`); `--hero-prompt` generates a hero image prompt written to `drafts/assets/{slug}-hero-prompt.md`. Both flags are additive — they do not change the main article output.

## Preconditions

1. Brief path resolves to a valid brief.
2. `--companion-posts` or `--hero-prompt` flag(s) are passed.

## Postconditions

**`--companion-posts`:**
1. 3–5 companion posts written to `drafts/linkedin/companions/{slug}-companion-{N}.md`.
2. Each companion has distinct insight; no duplicate with main article or other companions.

**`--hero-prompt`:**
1. Hero image prompt written to `drafts/assets/{slug}-hero-prompt.md`.
2. Prompt describes visual concept, style, mood, key elements.

## Invariants

1. Flags are optional; omitting them produces only the main article.
2. Companion posts always go to the LinkedIn companion directory regardless of the main article's target platform.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Both flags passed simultaneously | Both companion posts and hero prompt generated. |
| EC-002 | Main article is a LinkedIn post (<3000 chars) | `--companion-posts` generates micro-companion posts (<500 chars each). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `--companion-posts` | 3–5 companion files in `drafts/linkedin/companions/`; exit 0 | happy-path |
| `--hero-prompt` | Hero prompt file in `drafts/assets/`; exit 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | --companion-posts creates 3–5 files | bats skills.bats |
| VP-TBD | --hero-prompt creates prompt file | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-008 ("Content Brief and Writing") per brief §Scope §Phase 0/1 primitives (#10: `flags: --companion-posts, --hero-prompt`) and §Family Positioning §wclaude absorption ("`--companion-posts` flag on `/brain:write`; `--hero-prompt` flag on `/brain:write`"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#10); §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.08.002 — composes with
