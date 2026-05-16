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
subsystem: "SS-06"
capability: "CAP-006"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.06.004: Sources directory uses 7 default topic categories scaffolded by `/brain:init`

## Description

The `sources/` directory uses topic-based subdirectories to prevent a flat single-directory layout from degrading at 10K+ files. The 7 default topic categories (`ai`, `health`, `psychology`, `productivity`, `business`, `books`, `podcasts`) are scaffolded by `/brain:init`. Operators may add custom categories; the 7 defaults are the baseline. Two additional subdirs (`highlights/`, `bookmarks/`) are created on-demand by v0.5 GH Action templates and are not part of the v0.1 init scaffold.

## Preconditions

1. `/brain:init` has been run (BC-2.01.001).

## Postconditions

1. `sources/ai/`, `sources/health/`, `sources/psychology/`, `sources/productivity/`, `sources/business/`, `sources/books/`, `sources/podcasts/` all exist after init.
2. Each is an empty directory at init time (no source files; those are created by ingest operations).

## Invariants

1. The 7 default categories are always present after init.
2. Custom categories are allowed: `/brain:ingest-url` and `/brain:ingest-source` create new `sources/{custom-topic}/` directories on demand.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Operator runs ingest with `--topic=research` (custom) | `sources/research/` created on demand. |
| EC-002 | `highlights/` and `bookmarks/` absent after v0.1 init | Expected — these are v0.5 GH Action on-demand directories. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh init; `ls sources/` | 7 directories listed: ai health psychology productivity business books podcasts | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | All 7 default categories present after init | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-006 ("Source Layer and Immutability") per brief §Scalability Design Principles §3 ("`sources/` uses `sources/{topic}/` subdirectories (7 default categories: ai, health, psychology, productivity, business, books, podcasts; extensible)") and §Scope §Additional v0.x deliverables ("7 default topic categories scaffolded by `/brain:init`"). |
| Architecture Module | SS-06: Source Layer and Immutability |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §3; §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.01.001 — composes with (init creates these)
