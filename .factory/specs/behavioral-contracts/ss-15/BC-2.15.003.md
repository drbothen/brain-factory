---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-015"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.15.003: `/brain:policy-registry-validate` validates all policies against the schema

## Description

`/brain:policy-registry-validate` reads `.brain/policies.yaml` and validates all policies against the brain-factory policy schema. It reports any policies with invalid structure, unknown fields, or invalid value types. This is the bulk-audit equivalent of the per-policy validation in `/brain:policy-add`.

## Preconditions

1. `.brain/policies.yaml` exists.

## Postconditions

1. Structured JSON result: `{"valid_count": N, "invalid_count": M, "issues": [...]}`.
2. Exit 0 on all valid; exit 1 if any invalid.

## Invariants

1. All policies are validated, not just new ones.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid policies.yaml | `{"valid_count": 10, "invalid_count": 0}`; exit 0 | happy-path |
| One malformed policy | `{"valid_count": 9, "invalid_count": 1, "issues": [...]}`; exit 1 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 10 baseline policies validate | bats policies.bats |
| VP-TBD | Malformed policy detected | bats policies.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-015 ("Governance and Policies") per brief §Scope §Phase 2–3 polish skills (#24: `/brain:policy-registry-validate — validate all policies in `.brain/policies.yaml` against the schema`). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 2–3 polish skills (#24) |
