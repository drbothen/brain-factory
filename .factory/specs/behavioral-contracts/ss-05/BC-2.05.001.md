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
subsystem: "SS-TBD"
capability: "CAP-005"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.05.001: `/brain:lint-wiki` completes seven-check health pass in under 10 minutes on 10K-page wiki

## Description

`/brain:lint-wiki` runs a seven-check health pass on the wiki layer: (1) wikilink integrity, (2) frontmatter schema, (3) index-log coherence, (4) orphan pages, (5) page-type taxonomy compliance, (6) source ID citation validity, (7) embedding_status field presence. This is the bulk-audit equivalent of the per-write hook checks. The 10-minute SLA on a 10K-page wiki is a v0.9 scale gate requirement.

## Preconditions

1. Working directory is a valid brain.
2. `wiki/index.md` is readable.
3. All wiki pages in `wiki/{type}/` are accessible.

## Postconditions

1. Skill emits a structured JSON report: `{"checks": [{"name": "<check>", "status": "PASS|FAIL", "issues": [...]}], "overall": "PASS|FAIL", "pages_scanned": N, "duration_seconds": N}`.
2. Exit 0 on PASS overall; exit 1 on any FAIL.
3. On a 10K-page wiki, `duration_seconds` ≤ 600 (10 minutes wall-clock on GitHub Actions runner).

## Invariants

1. All 7 checks run every time (no selective skipping).
2. Index-first lookup for wikilink resolution (O(n) scan, not O(n²)).
3. The 10-minute SLA includes all 7 checks on a 10K-page wiki.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Empty wiki (0 pages) | All checks pass (vacuously); PASS overall; exit 0. |
| EC-002 | wiki/index.md missing | FAIL on checks 1, 3, 4; partial report; exit 1. |
| EC-003 | Single broken wikilink | FAIL check 1; issues list contains the broken link; exit 1. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Healthy 100-page wiki | All 7 checks PASS; exit 0 | happy-path |
| Wiki with 3 orphan pages | Check 4 FAIL; 3 issues listed; exit 1 | error |
| 10K-page wiki (synthetic corpus) | All checks pass; duration ≤ 600s | scale |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 7 checks run and report | bats skills.bats |
| VP-TBD | 10-minute SLA on 10K-page wiki | bats integration.bats (scale) |
| VP-TBD | O(n) wikilink resolution (not O(n²)) | bats performance assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-005 ("Wiki Layer and Wikilink Integrity") per brief §Scope §Phase 0/1 primitives skill #6 (`/brain:lint-wiki`) and §Success Criteria §v0.9 ship gate ("`/brain:lint-wiki` full health pass completes in under 10 minutes on a 10K-page wiki"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#6); §Success Criteria §v0.9 ship gate; §Scalability Design Principles §2 |

## Related BCs

- BC-2.05.002 — composes with (O(n) resolution required)
- BC-2.04.003 — related to (per-write hook checks; lint-wiki is the bulk audit)
