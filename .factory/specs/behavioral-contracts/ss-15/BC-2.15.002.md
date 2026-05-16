---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-15"
capability: "CAP-015"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.15.002: `/brain:policy-add` registers a new governance policy with schema validation

## Description

`/brain:policy-add <id> <body>` appends a new policy to `.brain/policies.yaml`. The policy ID must be unique; the body must be valid YAML syntax. Schema validation ensures the new policy conforms to the brain-factory policy schema before appending.

## Preconditions

1. `.brain/policies.yaml` exists and is readable.
2. Policy ID is provided and does not already exist in the file.
3. Policy body is provided.

## Postconditions

1. New policy appended to `.brain/policies.yaml`.
2. File remains valid YAML after append.
3. New policy is accessible to skills that read policies.yaml.
4. Exit 0.

## Invariants

1. Duplicate policy IDs are rejected.
2. Append is atomic.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Duplicate policy ID | E-POLICY-001: "Policy ID '<id>' already exists."; exit 2. |
| EC-002 | Invalid YAML body | E-POLICY-002: "Policy body is not valid YAML."; exit 2. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| New unique policy | Appended; valid YAML; exit 0 | happy-path |
| Duplicate ID | E-POLICY-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Unique policy appended | bats policies.bats |
| (no VP — P1) | Duplicate rejected | bats policies.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-015 ("Governance and Policies") per brief §Scope §Phase 2–3 polish skills (#23: `/brain:policy-add <id> <body> — register a new governance policy in `.brain/policies.yaml`"). |
| Architecture Module | SS-15: Governance and Policies |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 2–3 polish skills (#23) |
