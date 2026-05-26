---
document_type: behavioral-contract
level: L3
version: "1.4"
status: active
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-17"
capability: "CAP-017"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.17.002: Event catalog defines: event_type, hook_name, severity, fields, example payload

## Description

Each entry in the structured event catalog has a defined schema. The catalog is a JSON array at `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json`. The schema ensures observability tools and the adversary can validate emitted events against the catalog.

## Preconditions

1. `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json` exists and is valid JSON.

## Postconditions

1. Each catalog entry is a JSON object containing: `event_type` (string, unique), `hook_name` (string), `severity` (info|warn|error), `fields` (array of field names), `example` (valid JSONL object).
2. The catalog is machine-parseable JSON (not markdown table format).

## Invariants

1. All `event_type` values match the pattern `<domain>.<past-tense-verb>` per SS-17 §Event-type naming convention (dot-separated, lowercase, past-tense). Examples: `quarantine.blocked`, `source.immutability.violated`, `wiki.wikilink.broken`. Imperative or noun forms are forbidden.
2. `example` field in each entry is a valid JSON object parseable by `jq empty`.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A hook is modified to emit a new `event_type` that is NOT registered in `event-catalog.json` | `meta-lint.bats` cross-reference check (BC-2.18.004 and NFR-025) detects the unregistered emission site; CI blocks the PR; the implementer must add a catalog entry before the merge |
| EC-002 | An `example` field in the catalog contains a malformed JSON string (e.g., unescaped quote) | `jq empty` on that entry's `example` field exits non-zero; the bats test reports the specific entry that failed; the catalog entry must be corrected before the PR merges |
| EC-003 | A hook is removed from the codebase but its catalog row is not deleted | The cross-reference check detects a catalog row with no corresponding emission site; this is flagged as a stale row; the adversary reports it; the row must be removed or the hook reinstated |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Parse `scripts/event-catalog.json` via `jq .` | Valid JSON array; all entries have required fields (`event_type`, `hook_name`, `severity`, `fields`, `example`) | happy-path |
| `jq empty` on each `example` field in `scripts/event-catalog.json` | All parse as valid JSON objects | happy-path |
| Catalog contains entry for `hook.removed_event` (past-tense) but no hook emits it | Cross-reference check flags stale entry; bats fails | edge-case |
| Catalog entry with `event_type: "source.immutability.violation"` (noun form, not past-tense) | meta-lint.bats event_type naming check fails; CI blocks the PR | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-008 | All entries have required fields | bats integration.bats (JSON parse) |
| VP-008 | All example payloads are valid JSON | bats tests/meta-lint.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-017 ("Structured Event Catalog") per brief CLAUDE.md §Logging ("Format: JSONL on stderr with `ts`, `event_type`, `plugin`, `trace`, plus event-specific fields. All `event_type` values must be registered in the structured event catalog BC before the PR merges."). |
| Architecture Module | SS-17: Structured Event Catalog |
| Stories | STORY-014 |
| Source Brief Section | product-brief.md CLAUDE.md §Logging |

## Related BCs

- BC-2.17.001 — composes with

## Changelog

### v1.4 (2026-05-25)

**POL-14 PROMOTION:** `status: draft` → `status: active`. STORY-014 delivered — PR #2 merged to develop (commit 1a1874f), CI green. Contract implementation verified by adversary at 3-CLEAN (passes 7–9). No semantic change to contract.

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-014 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/meta-lint.bats` (catalog schema JSON validation; 1 row). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
