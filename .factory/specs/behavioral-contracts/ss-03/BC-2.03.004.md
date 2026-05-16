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
subsystem: "SS-03"
capability: "CAP-003"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.03.004: `/brain:ingest-source` propagates partial-failure fan-out (per-page results; no silent swallow)

## Description

When wiki page generation produces a mix of successes and failures (e.g., 8 of 10 pages created successfully, 2 blocked by hooks), the skill reports the complete per-page result set. It does not silently swallow the failures and report only the successes. The source file and manifest entry stand; the partial wiki result is transparent to the operator.

## Preconditions

1. Source file has been successfully written.
2. Wiki page generation has been attempted for all planned pages.

## Postconditions

1. Skill exit code is 1 (advisory) if any page generation failed; 0 if all succeeded.
2. The result summary includes: `{"source_id": "<slug>", "pages_attempted": N, "pages_created": M, "pages_failed": K, "failures": [{"slug": "<slug>", "error": "E-NNN: <message>"}, ...]}`.
3. Failed pages are not silently omitted from the result.
4. The manifest entry stands (source is ingested; partial wiki is a known state).

## Invariants

1. `pages_attempted = pages_created + pages_failed` (no unaccounted pages).
2. The skill never reports `pages_created = pages_attempted` when any page failed.
3. No `set +e` to silence hook-rejected writes.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | All pages fail (e.g., 0 of 10 created) | Exit 1 with full failure list; source and manifest remain. Operator must investigate. |
| EC-002 | No pages planned (source too short) | `pages_attempted: 0, pages_created: 0, pages_failed: 0`; exit 0. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 10 pages planned; 10 succeed | `pages_created: 10, pages_failed: 0`; exit 0 | happy-path |
| 10 pages planned; 8 succeed, 2 hook-blocked | `pages_created: 8, pages_failed: 2, failures: [...]`; exit 1 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Partial failure reported accurately | bats skills.bats |
| VP-TBD | No silent swallow on failed pages | bats skills.bats (inject hook failure for one page) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-003 ("Source Ingest Pipeline") per CLAUDE.md §Error handling ("Partial-failure fan-out (e.g., batch wiki page generation): propagate per-item results; do not swallow and return empty."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | CLAUDE.md §Error handling |

## Related BCs

- BC-2.03.001 — composes with
