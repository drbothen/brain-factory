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
subsystem: "SS-18"
capability: "CAP-018"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.18.005: 9 bats test suites cover 13 hooks and all skills (positive + negative + edge case per hook)

## Description

brain-factory ships 9 bats test suites: 8 functional (`skills.bats`, `hooks.bats`, `templates.bats`, `policies.bats`, `adversary.bats`, `quarantine.bats`, `integration.bats`, `upgrade.bats`) plus `meta-lint.bats` (factory self-audit). Every hook has at least positive + negative + edge-case coverage in `hooks.bats`. The bats count of exactly 9 suites is locked (SL-2 implied; hook performance tests are test CASES within hooks.bats, not a new suite).

## Preconditions

1. All hook scripts present.
2. All fixtures in `plugins/brain-factory/tests/fixtures/`.
3. `bats` installed.

## Postconditions

1. `bats plugins/brain-factory/tests/` exits 0 (all suites pass).
2. Exactly 9 suite files exist in `plugins/brain-factory/tests/*.bats`.
3. Every hook has ≥ 3 test cases in hooks.bats (positive, negative, edge).

## Invariants

1. Suite count is exactly 9 — never fewer, never more (without a BC update).
2. Hook latency assertions are test cases within hooks.bats (not a 10th suite).
3. `meta-lint.bats` is always one of the 9 suites.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A new hook is added without a bats test file | meta-lint.bats catches the missing test file; CI blocks. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `ls plugins/brain-factory/tests/*.bats | wc -l` | 9 | happy-path |
| `bats plugins/brain-factory/tests/` | All suites exit 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | Exactly 9 bats files | bats meta-lint.bats (count assertion) |
| VP-006 | All hooks have ≥ 3 test cases | bats meta-lint.bats (test-case count per hook) |
| VP-006 | Full suite run exits 0 | CI pipeline |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief §Scope §Additional v0.x deliverables ("9 bats test suites (8 functional: skills.bats, hooks.bats, templates.bats, policies.bats, adversary.bats, quarantine.bats, integration.bats, upgrade.bats; plus meta-lint.bats per CLAUDE.md Meta-Lint Contract)"). |
| Architecture Module | SS-18: Meta-Lint and Self-Audit |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Additional v0.x deliverables; CLAUDE.md §Meta-Lint Contract |

## Related BCs

- BC-2.18.001 through BC-2.18.004 — composes with (all meta-lint checks live in meta-lint.bats, one of the 9 suites)
