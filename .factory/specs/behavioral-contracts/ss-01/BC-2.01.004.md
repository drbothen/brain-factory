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
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.004: `/brain:init` writes `embedding_status: pending` in every wiki page template

## Description

The `embedding_status` frontmatter field is mandatory in all wiki pages from v0.1, establishing a non-breaking interface for v1.0+ vector retrieval. Every wiki page template that `/brain:init` writes to the target brain must include `embedding_status: pending` in the YAML frontmatter block. This ensures that `validate-frontmatter-schema.sh` does not block immediately on the first ingest after init. The `manifest.json` file initialized during init also includes `embeddings_model: null` to reserve the v1.0+ field.

## Preconditions

1. `/brain:init` is executing its template-expansion phase (post git-check, post-dependency-check).
2. The `${CLAUDE_PLUGIN_ROOT}/templates/` directory contains at least one wiki page type template.
3. Wiki type templates exist for all 6 types: concepts, people, frameworks, syntheses, observations, questions.

## Postconditions

1. Every wiki type template written to `wiki/{type}/` during init contains `embedding_status: pending` in its YAML frontmatter.
2. `.brain/manifest.json` contains `"embeddings_model": null` at the top level.
3. `.brain/manifest.json` contains a `"chunks"` array field at the top level (populated at v0.5+; empty array `[]` at v0.1).
4. `validate-frontmatter-schema.sh` exits 0 on all wiki page template files written by init.

## Invariants

1. The `embedding_status` default value is always `pending` (not `computed` or `stale`) for template files.
2. The `manifest.json` schema is backward-compatible with v0.5+ chunk references: the `chunks` field is always present, even when empty.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A future template version adds a new wiki type | The new template must include `embedding_status: pending` before shipping. Meta-lint catches absence at CI time. |
| EC-002 | Operator manually edits a template after init to remove `embedding_status` | `validate-frontmatter-schema.sh` will block subsequent wiki writes from that template. Not init's responsibility — this is the hook's enforcement scope. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh init; read any wiki type template file | YAML frontmatter contains `embedding_status: pending` | happy-path |
| Fresh init; read `.brain/manifest.json` | Contains `"embeddings_model": null` and `"chunks": []` | happy-path |
| Run `validate-frontmatter-schema.sh` on any init-produced wiki template | Hook exits 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | All 6 wiki type templates contain `embedding_status: pending` | bats unit assertion (templates.bats) |
| VP-014 | `manifest.json` contains `embeddings_model` and `chunks` fields | bats unit assertion |
| VP-014 | validate-frontmatter-schema.sh exits 0 on init output | bats tests/validate-frontmatter-schema.bats assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-001 ("Brain Initialization and Scaffold") per brief §Scalability Design Principles §6 ("Vector-indexing interface reservation") — every wiki page template written by init must include `embedding_status: pending` to establish the non-breaking v1.0+ interface. |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-01: Brain Initialization and Scaffold |
| Stories | [filled by story-writer — Phase 2] |
| Source Brief Section | product-brief.md §Scalability Design Principles §6; §Success Criteria §v0.1 ship gate (`validate-frontmatter-schema.sh` enforcement test) |

## Related BCs

- BC-2.01.001 — composes with (init postconditions include this)
- BC-2.04.004 — depends on (schema hook enforces the field; init populates it first)
- BC-2.05.006 — related to (embedding_status mandatory in all wiki pages)

## Architecture Anchors

- `architecture/subsystems/SS-05-wiki-layer.md`

## Story Anchor

[S-TBD]

## VP Anchors

- VP-014 — Brain init scaffold completeness (bats integration.bats)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-frontmatter-schema.bats` (1 row). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
