---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-11"
capability: "CAP-011"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.11.003: `/brain:process-inbox` classifies and routes inbox notes to correct wiki type

## Description

`/brain:process-inbox` reads notes from the `inbox/` directory, classifies each note by wiki type (concepts/people/frameworks/syntheses/observations/questions), and routes them to the appropriate `wiki/{type}/` directory via the normal wiki page creation pipeline. Notes are then removed from `inbox/`. The `brain:librarian` agent performs the classification.

## Preconditions

1. `inbox/` directory contains at least one markdown file.
2. `brain:librarian` available.

## Postconditions

1. Each inbox note classified and written to `wiki/{type}/{slug}.md`.
2. All mandatory frontmatter fields populated (including `embedding_status: pending`).
3. Inbox notes removed (or archived) after successful routing.
4. Exit 0 with routing summary.

## Invariants

1. Every note gets a classification — if the librarian cannot classify, it defaults to `observations/`.
2. No inbox note is left in `inbox/` after a successful run.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Empty `inbox/` directory | Advisory: "No inbox notes to process."; exit 0. |
| EC-002 | Note classification fails (hook rejects) | Note remains in inbox; partial result reported. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 5 inbox notes of various types | All 5 classified and moved to wiki/; inbox empty; exit 0 | happy-path |
| Empty inbox | "No notes to process"; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | All inbox notes routed | bats skills.bats |
| (no VP — P1) | Inbox cleared after successful run | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-011 ("Knowledge Synthesis and Connection") per brief §Scope §Phase 0/1 primitives skill #5 (`/brain:process-inbox — classify and route inbox notes`). |
| Architecture Module | SS-11: Knowledge Synthesis and Connection |
| Stories | STORY-026 |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#5) |

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-026 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
