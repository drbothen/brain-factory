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
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.005: `validate-frontmatter-schema.sh` blocks wiki writes missing other mandatory fields (exit 2)

## Description

Beyond `embedding_status` (BC-2.04.004), wiki pages have additional mandatory frontmatter fields. `validate-frontmatter-schema.sh` enforces the complete mandatory-field set for `wiki/*` writes. The exact field set for v0.1 is: `title`, `type` (one of: concepts/people/frameworks/syntheses/observations/questions), `created`, `source_ids` (list of source slugs this page derives from), and `embedding_status`. Sources (`sources/*`) have a different mandatory-field schema enforced by the same hook.

## Preconditions

1. Same as BC-2.04.004 (PostToolUse on Write|Edit targeting `wiki/**`).

## Postconditions

**On any missing mandatory field:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-SCHEMA-006", "message": "Missing required frontmatter field(s): [<field1>, <field2>] in <path>.", "trace": "<uuid>"}`.

**On all mandatory fields present and valid:**
1. Hook exits 0. stdout: `{"verdict": "allow", ...}`.

**On invalid `type` value:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-SCHEMA-007", "message": "Invalid wiki type '<val>' in <path>. Must be one of: concepts, people, frameworks, syntheses, observations, questions.", "trace": "<uuid>"}`.

## Invariants

1. The mandatory-field set for v0.1 wiki pages: `title`, `type`, `created`, `source_ids`, `embedding_status`. Any of these missing → hard block.
2. Valid `type` values: `concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions` (6 values per plan.md §3.4; case-sensitive lowercase).
3. `sources/*` files have a different mandatory-field schema. The hook must check the path prefix to determine which schema applies.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Write to `sources/ai/slug.md` (not wiki) | Apply sources schema (different fields: `title`, `url`, `ingested_at`, `source_id`, `topic`). |
| EC-002 | Wiki page with `type: concepts` (valid, singular not plural) | Block with E-SCHEMA-007 ("concepts" is the required value, not "concept"). |
| EC-003 | `source_ids` is empty list `[]` | Allow (a synthesis page may not cite specific source IDs at creation time). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Complete wiki frontmatter (all 5 fields present, valid) | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Wiki page missing `title` | `{"verdict": "block", "code": "E-SCHEMA-006", ...}`; exit 2 | error |
| Wiki page with `type: concept` (not in allowed set) | `{"verdict": "block", "code": "E-SCHEMA-007", ...}`; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 5 mandatory fields enforced | bats hooks.bats (one test case per field) |
| VP-TBD | All 6 valid type values pass | bats hooks.bats (parameterized) |
| VP-TBD | Invalid type → exit 2 | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#8 `validate-frontmatter-schema.sh`) and §Scalability Design Principles §3 (wiki/{type}/{slug}.md layout; 6 wiki types). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#8); §Scalability Design Principles §3 |

## Related BCs

- BC-2.04.004 — composes with (same hook, embedding_status check)
- BC-2.04.016 — composes with
- BC-2.05.005 — depends on (wiki page type taxonomy defined here)
