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

# Behavioral Contract BC-2.04.004: `validate-frontmatter-schema.sh` blocks wiki writes missing `embedding_status` field (exit 2)

## Description

`validate-frontmatter-schema.sh` fires on PostToolUse (Write|Edit on `wiki/*` or `sources/*`). For wiki page writes, it enforces the presence of the `embedding_status` field in YAML frontmatter. This is the mandatory-from-v0.1 commitment that reserves the v1.0+ vector retrieval interface. Missing `embedding_status` = hard block, not advisory.

## Preconditions

1. Claude Code fires the hook via PostToolUse on Write or Edit targeting `wiki/**`.
2. The written file is a markdown file with YAML frontmatter (delimited by `---` fences).
3. `yq` is available in PATH for frontmatter parsing.

## Postconditions

**On missing `embedding_status`:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-SCHEMA-001", "message": "Missing required frontmatter field: embedding_status. Add embedding_status: pending to <path>.", "trace": "<uuid>"}`.

**On present `embedding_status` with valid value (pending|computed|stale):**
1. Hook exits 0.
2. stdout: `{"verdict": "allow", "message": "Frontmatter schema valid.", "trace": "<uuid>"}`.

**On present `embedding_status` with invalid value:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-SCHEMA-002", "message": "Invalid embedding_status value '<val>' in <path>. Must be one of: pending, computed, stale.", "trace": "<uuid>"}`.

## Invariants

1. The `embedding_status` requirement applies ONLY to `wiki/*` writes. `sources/*` writes use the `validate-source-immutability.sh` hook for a different mandatory-field set.
2. Valid `embedding_status` values: `pending`, `computed`, `stale` (exactly; case-sensitive).
3. Fail-closed: if `yq` fails to parse frontmatter, hook exits 2 with E-SCHEMA-003.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Wiki file has no frontmatter block at all | Hook exits 2 with E-SCHEMA-004: "No YAML frontmatter found in <path>." |
| EC-002 | `embedding_status` present but set to `null` | Hook exits 2 with E-SCHEMA-002 (null is not a valid value). |
| EC-003 | `yq` not in PATH | Hook exits 2 with E-SCHEMA-005: "yq required for frontmatter validation — install yq." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Wiki file with `embedding_status: pending` | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Wiki file without `embedding_status` | `{"verdict": "block", "code": "E-SCHEMA-001", ...}`; exit 2 | error |
| Wiki file with `embedding_status: invalid_value` | `{"verdict": "block", "code": "E-SCHEMA-002", ...}`; exit 2 | error |
| Wiki file with no frontmatter at all | `{"verdict": "block", "code": "E-SCHEMA-004", ...}`; exit 2 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Missing embedding_status → exit 2 | bats hooks.bats (positive + negative cases required at v0.1 gate) |
| VP-TBD | Valid embedding_status → exit 0 | bats hooks.bats |
| VP-TBD | Invalid value → exit 2 | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#8 `validate-frontmatter-schema.sh`) and §Scalability Design Principles §6 ("embedding_status field is mandatory in v0.1; `validate-frontmatter-schema.sh` hook enforces presence on `wiki/*` writes"). |
| L2 Domain Invariants | N/A |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §6; §Success Criteria §v0.1 ship gate (embedding_status enforcement test) |

## Related BCs

- BC-2.04.016 — composes with (hook I/O contract)
- BC-2.05.006 — related to (embedding_status mandatory in wiki pages)
- BC-2.01.004 — composes with (init writes embedding_status; hook enforces it)
- BC-2.04.005 — related to (other mandatory fields enforced by same hook)
