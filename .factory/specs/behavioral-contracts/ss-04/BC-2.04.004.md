---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
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
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "frontmatter.schema.violated", "hook_name": "validate-frontmatter-schema.sh", "path": "<path>", "missing_field": "embedding_status"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On present `embedding_status` with valid value (pending|computed|stale):**
1. Hook exits 0.
2. stdout: `{"verdict": "allow", "message": "Frontmatter schema valid.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "frontmatter.schema.validated", "hook_name": "validate-frontmatter-schema.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On present `embedding_status` with invalid value:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-SCHEMA-002", "message": "Invalid embedding_status value '<val>' in <path>. Must be one of: pending, computed, stale.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "frontmatter.schema.violated", "hook_name": "validate-frontmatter-schema.sh", "path": "<path>", "invalid_field": "embedding_status", "invalid_value": "<val>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

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
| VP-002, VP-005 | Missing embedding_status → exit 2 | bats tests/validate-frontmatter-schema.bats (positive + negative cases required at v0.1 gate) |
| VP-002, VP-005 | Valid embedding_status → exit 0 | bats tests/validate-frontmatter-schema.bats |
| VP-002, VP-005 | Invalid value → exit 2 | bats tests/validate-frontmatter-schema.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#8 `validate-frontmatter-schema.sh`) and §Scalability Design Principles §6 ("embedding_status field is mandatory in v0.1; `validate-frontmatter-schema.sh` hook enforces presence on `wiki/*` writes"). |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | STORY-009 |
| Source Brief Section | product-brief.md §Scalability Design Principles §6; §Success Criteria §v0.1 ship gate (embedding_status enforcement test) |

## Related BCs

- BC-2.04.016 — composes with (hook I/O contract)
- BC-2.05.006 — related to (embedding_status mandatory in wiki pages)
- BC-2.01.004 — composes with (init writes embedding_status; hook enforces it)
- BC-2.04.005 — related to (other mandatory fields enforced by same hook)

## Changelog

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-009 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-frontmatter-schema.bats` (3 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
