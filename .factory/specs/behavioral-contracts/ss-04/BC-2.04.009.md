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

# Behavioral Contract BC-2.04.009: `validate-source-id-citation.sh` blocks wiki writes with unresolved source citations (exit 2)

## Description

`validate-source-id-citation.sh` fires on PostToolUse (Write|Edit on `wiki/*`). It validates that every source ID cited in the page's `source_ids` frontmatter field resolves to a real entry in `.brain/manifest.json`. Unresolved source IDs produce wiki pages that claim to derive from non-existent sources — a data integrity violation. Hard block (exit 2).

## Preconditions

1. PostToolUse fires on Write|Edit targeting `wiki/**`.
2. `.brain/manifest.json` is readable.
3. The wiki page frontmatter contains a `source_ids` field (required per BC-2.04.005).

## Postconditions

**On unresolved source ID:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-WIKI-007", "message": "Unresolved source_id '<slug>' in <path>. No matching entry in manifest.json.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "source.citation.unresolved", "hook_name": "validate-source-id-citation.sh", "path": "<path>", "missing_source_id": "<slug>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On all source IDs resolve (or `source_ids: []` — empty):**
1. Hook exits 0.
2. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "source.citation.resolved", "hook_name": "validate-source-id-citation.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

## Invariants

1. Empty `source_ids: []` is allowed (e.g., synthesis pages that are purely LLM-generated).
2. Fail-closed: if `manifest.json` unreadable → exit 2 with E-WIKI-008.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `source_ids` is an empty list | Exit 0 (vacuously satisfied). |
| EC-002 | One of several source IDs is unresolved | Block with all unresolved IDs listed. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `source_ids: [ai/valid-source]` (manifest has this entry) | exit 0 | happy-path |
| `source_ids: [ai/nonexistent]` | E-WIKI-007; exit 2 | error |
| `source_ids: []` | exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-002 | Unresolved source_id → exit 2 | bats tests/validate-source-id-citation.bats |
| VP-002 | Empty source_ids → exit 0 | bats tests/validate-source-id-citation.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#11 `validate-source-id-citation.sh`). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | STORY-011 |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#11) |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.04.005 — depends on (source_ids is a mandatory field)
- BC-2.06.003 — depends on (manifest.json records source entries)

## Changelog

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-011 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-source-id-citation.bats` (2 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
