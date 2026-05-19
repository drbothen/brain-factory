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
subsystem: "SS-06"
capability: "CAP-006"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.06.001: `sources/{topic}/{slug}.md` is immutable after creation

## Description

A source file, once written to `sources/{topic}/{slug}.md`, is immutable. It cannot be overwritten, appended to, or deleted by any skill or hook (except through the explicit `/brain:rename-page` flow). This is a core correctness invariant: sources are the brain's permanent record of what was read. Mutability would corrupt the knowledge base without audit trail. The immutability invariant is enforced by `validate-source-immutability.sh` (BC-2.04.002) at the hook level and by duplicate detection in ingest skills (BC-2.02.006).

## Preconditions

1. A source file `sources/{topic}/{slug}.md` has been successfully created by an ingest operation.
2. The file's slug is recorded in `.brain/manifest.json`.

## Postconditions

1. Any subsequent Write or Edit targeting `sources/{topic}/{slug}.md` is blocked by `validate-source-immutability.sh` (exit 2).
2. The file content on disk is unchanged.

## Invariants

1. Source immutability applies to ALL content under `sources/` — not just files ingested via skills. Manual writes via Bash or text editor are also caught by the PostToolUse hook.
2. The only authorized mutation is the rename flow (`/brain:rename-page`), which deletes the old file and creates a new one with the new slug — never overwrites in place.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Operator uses raw `echo >> sources/ai/foo.md` via Bash | PostToolUse hook fires after the Bash tool call; `validate-source-immutability.sh` detects the mutation and exits 2. The write already happened, so the hook advisory causes the session to flag the mutation for operator review. This is an inherent limitation of PostToolUse hooks — they cannot prevent writes, only detect them. |
| EC-002 | Source file deleted externally | Not caught by any v0.1 hook (deletion is not a Write/Edit event). The manifest becomes stale. `/brain:lint-wiki` will surface the orphan source reference on next run. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Edit to existing source file | `validate-source-immutability.sh` exits 2; E-SOURCE-001 | error |
| Write to new source file (not in manifest) | Hook exits 0; source accepted | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-003 | Existing source overwrite → hook exit 2 | bats tests/validate-source-immutability.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-006 ("Source Layer and Immutability") per brief §Value Proposition §Core differentiator #1 ("source-immutability enforced by hooks the agent cannot bypass"). |
| Architecture Module | SS-06: Source Layer and Immutability |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Value Proposition §Core differentiator #1; §Scalability Design Principles §1 |

## Related BCs

- BC-2.04.002 — depends on (hook enforces this)
- BC-2.02.006 — related to (skill-level duplicate detection)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-source-immutability.bats` (1 row). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
