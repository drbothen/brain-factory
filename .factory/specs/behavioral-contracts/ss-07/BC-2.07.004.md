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
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.07.004: `/brain:adversary-review` returns structured pass/fail verdict with finding list

## Description

Every invocation of `/brain:adversary-review` returns a machine-readable structured verdict. This allows downstream skills (`/brain:brief`, `/brain:write`) to programmatically check the review result and branch on pass/fail.

## Preconditions

1. `/brain:adversary-review <path>` has completed at least one validation pass.

## Postconditions

1. Skill returns a structured JSON verdict on stdout: `{"verdict": "PASS|FAIL", "path": "<path>", "iterations": N, "agents": {...}, "findings": [{"agent": "<name>", "severity": "CRITICAL|IMPORTANT|SUGGESTION|OBSERVATION", "description": "<text>"}], "overall_score": N}`.
2. Exit 0 on PASS; exit 1 on FAIL.

## Invariants

1. The `verdict` field is always present.
2. `findings` is always an array (empty on PASS).
3. Finding severities: CRITICAL (blocks shipment), IMPORTANT (should fix), SUGGESTION (optional), OBSERVATION (informational).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | No findings (clean PASS) | `{"verdict": "PASS", "findings": []}`; exit 0. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Clean artifact | `{"verdict": "PASS", "findings": []}` | happy-path |
| Artifact with 2 critical findings | `{"verdict": "FAIL", "findings": [{"severity": "CRITICAL", ...}, ...]}` | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-010 | Verdict JSON schema valid | bats adversary.bats |
| VP-010 | Exit codes match verdict | bats adversary.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-007 ("Adversarial Review and Writescore") per brief §Scope §Phase 0/1 primitives (#13). |
| Architecture Module | SS-07: Adversarial Review and Writescore |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#13) |

## Related BCs

- BC-2.07.002 — composes with
