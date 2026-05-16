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
subsystem: "SS-05"
capability: "CAP-005"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.05.004: `/brain:rename-page` rejects rename if old slug does not exist

## Description

This BC defines the error-case branch of BC-2.05.003: the rename-page skill performs an existence check on the old slug as its first operation, before any file system changes. If the old slug does not exist in the wiki, the skill aborts immediately with a structured error.

## Preconditions

1. `/brain:rename-page` is invoked with an old-slug argument.

## Postconditions

1. If `wiki/{type}/old-slug.md` does not exist (in any type directory): Exit 2 with E-RENAME-001.
2. No file system changes made.

## Invariants

1. Existence check is performed before any write operations.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Same slug exists in multiple type directories | Should not occur (slugs are unique across all wiki types). If it does, treat as ambiguous and prompt operator to specify type. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Old slug does not exist | E-RENAME-001; exit 2; no changes | error |
| Old slug exists | Proceed with rename | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Non-existent old slug → exit 2 before any changes | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-005 ("Wiki Layer and Wikilink Integrity") per brief §Scope §Phase 0/1 primitives (#12). |
| Architecture Module | SS-05: Wiki Layer and Wikilink Integrity |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#12) |

## Related BCs

- BC-2.05.003 — composes with (error branch)
