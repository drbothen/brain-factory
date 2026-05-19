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
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.002: `validate-source-immutability.sh` blocks overwrite of existing source records (exit 2)

## Description

`validate-source-immutability.sh` is a PostToolUse hook (matcher: Write|Edit on `sources/*`). It enforces that once a source file is written to the `sources/{topic}/` layer, it cannot be overwritten or modified except through the explicit rename flow (`/brain:rename-page`). Source immutability is a core correctness invariant: the brain treats raw sources as ground truth. Silent overwrite would corrupt the brain's knowledge base without audit trail.

## Preconditions

1. Claude Code fires the hook via PostToolUse on a Write or Edit tool call targeting a path matching `sources/**`.
2. The hook receives a JSON payload on stdin containing: the file path that was written/edited and the operation type (Write or Edit).
3. `.brain/manifest.json` exists and is readable.

## Postconditions

**On overwrite attempt (path matches an existing manifest entry):**
1. Hook exits 2.
2. Hook writes to stdout: `{"verdict": "block", "code": "E-SOURCE-001", "message": "Source file <path> already exists in manifest. Sources are immutable. Use /brain:rename-page to rename.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "...", "event_type": "source.immutability.violated", "hook_name": "validate-source-immutability.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On new source write (path not in manifest):**
1. Hook exits 0.
2. Hook writes to stdout: `{"verdict": "allow", "message": "New source accepted.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "...", "event_type": "source.added", "hook_name": "validate-source-immutability.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

## Invariants

1. The hook checks the manifest, not file-system existence alone. A file could exist on disk but not in the manifest (e.g., during a failed partial ingest). In that case, the hook allows the write and the manifest is updated by the ingest skill.
2. Fail-closed: if `manifest.json` is unreadable, hook exits 2 with E-SOURCE-002.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Edit on a source file that is in the manifest (repair attempt) | Hook exits 2 (E-SOURCE-001). Source repair must go through `/brain:rename-page` or explicit operator override in policies.yaml. |
| EC-002 | Write to `sources/` with a file path not matching any existing manifest entry | Hook exits 0. New source accepted. |
| EC-003 | `manifest.json` missing or malformed | Hook exits 2 (E-SOURCE-002: "manifest.json unreadable — cannot verify source immutability."). Fail-closed. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Write to `sources/ai/new-source.md` (not in manifest) | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Edit to `sources/ai/existing-source.md` (path in manifest) | `{"verdict": "block", "code": "E-SOURCE-001", ...}`; exit 2 | error |
| Write with `manifest.json` absent | `{"verdict": "block", "code": "E-SOURCE-002", ...}`; exit 2 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-003 | Existing source overwrite → exit 2 | bats tests/validate-source-immutability.bats |
| VP-003 | New source → exit 0 | bats tests/validate-source-immutability.bats |
| VP-003 | Missing manifest → exit 2 (fail-closed) | bats tests/validate-source-immutability.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#5 `validate-source-immutability.sh`) and §Value Proposition §Core differentiator #1 ("source-immutability enforced by hooks the agent cannot bypass"). |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#5); §Scalability Design Principles §1 (incremental ingest, manifest.json) |

## Related BCs

- BC-2.04.016 — composes with (universal hook I/O contract)
- BC-2.06.001 — depends on (source immutability invariant)
- BC-2.04.017 — composes with (event emission: source.immutability.violated, source.added — past-tense per SS-17)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-source-immutability.bats` (3 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
