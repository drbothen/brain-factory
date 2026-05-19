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
subsystem: "SS-05"
capability: "CAP-005"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.05.005: Wiki pages use `wiki/{type}/{slug}.md` path (6 types: concepts/people/frameworks/syntheses/observations/questions)

## Description

The wiki layer is organized by TYPE, not by topic. The 6 valid wiki type directories are: `concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions`. This layout is locked from v0.1 to support 10K+ files without filesystem performance degradation. Note: `sources/` is a Layer-2 directory (immutable raw material) — it is NOT a wiki type. Wiki types govern the `wiki/{type}/` subdirectory only.

## Preconditions

1. `/brain:init` has been run (wiki type directories scaffolded).

## Postconditions

1. Every wiki page resides at exactly `wiki/{type}/{slug}.md` where `{type}` is one of: concepts, people, frameworks, syntheses, observations, questions.
2. No wiki page is written to `wiki/{slug}.md` (root level, no type).
3. No wiki page is written to `wiki/{undefined-type}/{slug}.md`.

## Invariants

1. The 6 wiki types are immutable in v0.x. New types require a BC update and a `/brain:lint-wiki` rule update.
2. `wiki/index.md` and `wiki/log.md` are exempt (they are infrastructure files, not wiki pages).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Write to `wiki/tools/hammer.md` | `validate-page-type-policy.sh` blocks; E-WIKI-005. |
| EC-002 | Write to `wiki/my-concept.md` (root level) | `validate-page-type-policy.sh` blocks; E-WIKI-006. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Page at `wiki/concepts/ai-agents.md` | Valid path; hook exits 0 | happy-path |
| Page at `wiki/tools/hammer.md` | E-WIKI-005; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-018 | All 6 type directories valid | bats tests/validate-page-type-policy.bats |
| VP-018 | Non-type directories blocked | bats tests/validate-page-type-policy.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-005 ("Wiki Layer and Wikilink Integrity") per brief §Scalability Design Principles §3 ("wiki/{type}/{slug}.md; 6 wiki types per plan.md §3.4: concepts, people, frameworks, syntheses, observations, questions"). |
| Architecture Module | SS-05: Wiki Layer and Wikilink Integrity |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §3 |

## Related BCs

- BC-2.04.007 — depends on (hook enforces this taxonomy at write time)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-page-type-policy.bats` (2 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
