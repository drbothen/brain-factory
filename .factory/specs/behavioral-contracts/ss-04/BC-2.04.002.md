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
2. Hook writes to stdout: `{"continue": false, "decision": "block", "reason": "Source file <path> already exists in manifest. Sources are immutable. Use /brain:rename-page to rename.", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-SOURCE-001", "trace": "<uuid>"}}`.
3. Hook emits JSONL event to stderr: `{"ts": "...", "event_type": "source.immutability.violated", "hook_name": "validate-source-immutability.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On new source write (path not in manifest):**
1. Hook exits 0.
2. Hook writes to stdout: `{"continue": true, "trace": "<uuid>", "message": "New source accepted."}`.
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
| EC-004 | Malformed or empty stdin payload (not valid JSON, or missing required fields `tool_input.file_path` / `cwd`) | Hook exits 2 with E-SOURCE-003, stdout: `{"continue": false, "decision": "block", "reason": "Malformed or empty hook payload.", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-SOURCE-003", "trace": "<uuid>"}}`. Fail-closed per Invariant 2. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Write to `sources/ai/new-source.md` (not in manifest) | `{"continue": true, "trace": "<uuid>", "message": "New source accepted."}`; exit 0 | happy-path |
| Edit to `sources/ai/existing-source.md` (path in manifest) | `{"continue": false, "decision": "block", "reason": "Source file <path> already exists in manifest...", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-SOURCE-001", "trace": "<uuid>"}}`; exit 2 | error |
| Write with `manifest.json` absent | `{"continue": false, "decision": "block", "reason": "manifest.json unreadable — cannot verify source immutability.", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-SOURCE-002", "trace": "<uuid>"}}`; exit 2 | edge-case |
| Malformed or empty stdin payload (missing `tool_input.file_path` / `cwd`) | `{"continue": false, "decision": "block", "reason": "Malformed or empty hook payload.", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-SOURCE-003", "trace": "<uuid>"}}`; exit 2 | edge-case |

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
| Stories | STORY-007 |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#5); §Scalability Design Principles §1 (incremental ingest, manifest.json) |

## Related BCs

- BC-2.04.016 — composes with (universal hook I/O contract)
- BC-2.06.001 — depends on (source immutability invariant)
- BC-2.04.017 — composes with (event emission: source.immutability.violated, source.added — past-tense per SS-17)

## Changelog

### v1.4 (2026-05-26)

**SCHEMA ALIGNMENT (ADR-002 v2.0):** Replaced retired v1.0 `{"verdict": "block|allow", ...}` stdout envelope with ADR-002 v2.0 Claude Code native schema across all postconditions, edge cases, and canonical test vectors:
- Block responses now use `{"continue": false, "decision": "block", "reason": "...", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-SOURCE-NNN", "trace": "<uuid>"}}`.
- Allow responses now use `{"continue": true, "trace": "<uuid>", "message": "..."}`.
- Added EC-004: Malformed or empty stdin payload → E-SOURCE-003, exit 2 (fail-closed per Invariant 2).

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-007 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-source-immutability.bats` (3 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
