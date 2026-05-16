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

# Behavioral Contract BC-2.05.006: `embedding_status` field is mandatory in all wiki page frontmatter from v0.1

## Description

Every wiki page — whether created by ingest, manually, or by any skill — must include `embedding_status: pending|computed|stale` in its YAML frontmatter. This field is enforced by `validate-frontmatter-schema.sh` (BC-2.04.004) at write time and audited by `/brain:lint-wiki` (BC-2.05.001) at bulk-audit time. This is the v0.1 interface reservation for v1.0+ vector retrieval.

## Preconditions

1. A Write or Edit is about to be performed on a `wiki/*` file.

## Postconditions

1. `embedding_status` is present in the frontmatter with a valid value.
2. If missing: `validate-frontmatter-schema.sh` blocks the write (exit 2).

## Invariants

1. Valid values: `pending`, `computed`, `stale` (case-sensitive, lowercase).
2. Default value at creation: `pending`.
3. The field schema is backward-compatible: v0.x implementations write `pending`; v1.0+ implementations may update to `computed` or `stale`.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Manual wiki page creation without embedding_status | Hook blocks; E-SCHEMA-001. |
| EC-002 | Page with `embedding_status: PENDING` (wrong case) | Hook blocks; E-SCHEMA-002. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Wiki page with `embedding_status: pending` | Hook exits 0 | happy-path |
| Wiki page without `embedding_status` | E-SCHEMA-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 3 valid values accepted | bats hooks.bats |
| VP-TBD | Missing field blocked | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-005 ("Wiki Layer and Wikilink Integrity") per brief §Scalability Design Principles §6 ("Every wiki page's frontmatter MUST include an `embedding_status` field... `validate-frontmatter-schema.sh` hook enforces presence on `wiki/*` writes"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §6 |

## Related BCs

- BC-2.04.004 — depends on (hook enforces this)
- BC-2.01.004 — composes with (init writes this in templates)
