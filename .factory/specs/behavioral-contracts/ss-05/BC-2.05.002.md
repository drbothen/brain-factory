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

# Behavioral Contract BC-2.05.002: `/brain:lint-wiki` uses index-first lookup (O(n) scan, not O(n²) cross-product)

## Description

Wikilink resolution in `/brain:lint-wiki` must be implemented using index-first lookup: load `wiki/index.md` into memory once (O(n) scan), then resolve each wikilink in each page against the in-memory index (O(1) lookup per link). This avoids O(n²) behavior from checking every page against every other page. The architecture decision is locked in v0.1 to prevent drift toward quadratic implementations.

## Preconditions

1. `wiki/index.md` is loadable into memory (expected to be ≤ a few MB even at 10K pages).

## Postconditions

1. Wikilink resolution uses the index-first algorithm: load index once, resolve links by set membership.
2. Total wikilink resolution work is O(n * L) where n = number of pages and L = average wikilinks per page (not O(n²)).

## Invariants

1. The in-memory index is built once per lint-wiki run, not rebuilt per page.
2. If `wiki/index.md` is missing, lint-wiki falls back to filesystem scan (acceptable as an error-recovery path, not the default).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | 10K pages with average 20 wikilinks each | Total operations: 10K * 20 = 200K lookups against the in-memory index. O(n*L) is acceptable. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 10K-page wiki; time wikilink resolution | Resolution time is O(n*L), not O(n²) | scale |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Index loaded once; O(n*L) total work | bats performance assertion; code review |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-005 ("Wiki Layer and Wikilink Integrity") per brief §Scalability Design Principles §2 ("No quadratic hot paths: `/brain:lint-wiki` completes wikilink integrity checks via index-first lookup (O(n) scan of `index.md`, not O(n²) cross-product)."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §2 |

## Related BCs

- BC-2.05.001 — composes with
