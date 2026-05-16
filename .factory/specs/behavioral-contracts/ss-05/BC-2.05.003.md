---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-005"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.05.003: `/brain:rename-page` renames wiki page and propagates all backlinks atomically

## Description

`/brain:rename-page <old-slug> <new-slug>` is the ONLY permitted path for renaming a wiki page. It renames the file, updates `wiki/index.md`, updates `wiki/log.md`, and performs a full backlink sweep to update all pages that reference `[[old-slug]]` to `[[new-slug]]`. All changes are committed atomically. Partial renames (where some backlinks are missed) are a data integrity violation.

## Preconditions

1. `wiki/{type}/old-slug.md` exists.
2. `wiki/{type}/new-slug.md` does NOT exist (rename target must be fresh).
3. `new-slug` is a valid kebab-case string.

## Postconditions

1. `wiki/{type}/old-slug.md` is renamed to `wiki/{type}/new-slug.md`.
2. All pages containing `[[old-slug]]` are updated to `[[new-slug]]`.
3. `wiki/index.md` entry updated.
4. `wiki/log.md` entry updated with rename event.
5. Exit 0 with summary: `{"renamed": "old-slug → new-slug", "backlinks_updated": N}`.

## Invariants

1. All backlink updates happen before any single file is renamed (or via atomic git commit).
2. If backlink sweep fails for any page, the entire rename is rolled back.
3. The skill uses index-first backlink detection (not full-wiki grep scan).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | old-slug does not exist | E-RENAME-001: "Page <old-slug> not found."; exit 2. |
| EC-002 | new-slug already exists | E-RENAME-002: "Page <new-slug> already exists. Choose a different slug."; exit 2. |
| EC-003 | new-slug is not kebab-case | E-NAMING-001; exit 2. |
| EC-004 | 0 backlinks to update | Rename proceeds; `backlinks_updated: 0`; exit 0. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Rename `ai-agents` → `ai-agent-systems`; 5 backlinks | All 5 backlinks updated; file renamed; index updated; exit 0 | happy-path |
| Rename to non-existent page | E-RENAME-001; exit 2 | error |
| Target slug already exists | E-RENAME-002; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All backlinks updated | bats skills.bats (inject known backlinks) |
| VP-TBD | Rename atomic (no partial state) | bats skills.bats (inject failure mid-rename) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-005 ("Wiki Layer and Wikilink Integrity") per brief §Scope §Phase 0/1 primitives skill #12 (`/brain:rename-page <old-slug> <new-slug> — rename wiki page and propagate all backlinks`). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#12); CLAUDE.md brain-factory-002 |

## Related BCs

- BC-2.04.011 — related to (kebab-case enforcement; rename-page is the correct path for slug changes)
