---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-18T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-18"
capability: "CAP-018"
lifecycle_status: active
introduced: v0.1.0
modified: ["v1.2"]
---

# Behavioral Contract BC-2.18.005: Test surface organization — 8 category bats suites + per-hook .bats files at plugins/brain-factory/tests/

## Description

brain-factory ships 8 category bats suites (`meta-lint.bats`, `skills.bats`, `templates.bats`, `policies.bats`, `adversary.bats`, `quarantine.bats`, `integration.bats`, `upgrade.bats`) plus 13 per-hook bats files at `plugins/brain-factory/tests/<hook-name>.bats` (one per hook script). There is no consolidated `hooks.bats` — each hook script has its own dedicated test file. Hook latency assertions live inside the per-hook bats file for that hook, not in a separate performance suite.

## Preconditions

1. All 13 hook scripts present under `plugins/brain-factory/hooks/`.
2. All fixtures in `plugins/brain-factory/tests/fixtures/`.
3. `bats` installed.

## Postconditions

1. `bats plugins/brain-factory/tests/` exits 0 (all suites and per-hook files pass).
2. Exactly 8 category suite files exist: `tests/meta-lint.bats`, `tests/skills.bats`, `tests/templates.bats`, `tests/policies.bats`, `tests/adversary.bats`, `tests/quarantine.bats`, `tests/integration.bats`, `tests/upgrade.bats`.
3. Exactly 13 per-hook bats files exist at `tests/<hook-name>.bats`, one per hook script.
4. Every per-hook bats file covers ≥ 3 test cases for its hook (positive, negative, edge).

## Invariants

1. Every hook script has a corresponding `tests/<hook-name>.bats` file — no hook ships without its own bats file.
2. Hook latency assertions are test cases within the per-hook bats file for that hook (not a separate performance suite).
3. `meta-lint.bats` is always one of the 8 category suites; it asserts that every hook has a corresponding bats file (catching regressions when a new hook is added without a test).
4. The 8 category suites are stable; adding a new hook means adding a new per-hook bats file, not a new category suite.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A new hook is added without a per-hook bats file | meta-lint.bats catches the missing test file; CI blocks. |
| EC-002 | A per-hook bats file exists but its hook script is removed | meta-lint.bats catches the orphan bats file; advisory (exit 1). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `ls plugins/brain-factory/tests/*.bats \| grep -c '^'` | 21 (8 category + 13 per-hook) | happy-path |
| `ls plugins/brain-factory/tests/<hook-name>.bats` (for each of 13 hooks) | File exists | happy-path |
| `bats plugins/brain-factory/tests/` | All files exit 0 | happy-path |
| Add new hook without bats file, run `bats tests/meta-lint.bats` | Assertion fails; CI blocks | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | Exactly 8 category bats suites present | bats meta-lint.bats (category-suite count assertion) |
| VP-006 | Exactly 13 per-hook bats files present | bats meta-lint.bats (per-hook file presence assertion) |
| VP-006 | All hooks have ≥ 3 test cases in their per-hook file | bats meta-lint.bats (test-case count per hook) |
| VP-006 | Full suite + per-hook run exits 0 | CI pipeline |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief §Scope §Test architecture ("8 category suites (meta-lint.bats, skills.bats, templates.bats, policies.bats, adversary.bats, quarantine.bats, integration.bats, upgrade.bats) plus 13 per-hook bats files at tests/<hook-name>.bats"). |
| Architecture Module | SS-18: Meta-Lint and Self-Audit |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Test architecture (v0.4.20); CLAUDE.md §Meta-Lint Contract; CLAUDE.md §HOOK TESTS; CLAUDE.md §TDD Inner Loop Discipline |

## Related BCs

- BC-2.18.001 through BC-2.18.004 — composes with (all meta-lint checks live in meta-lint.bats, one of the 8 category suites)

## Changelog

### v1.2 (2026-05-18)

**TEST-ARCHITECTURE AMENDMENT (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE):** Rewrote BC to reflect brief v0.4.20's per-hook + category bats model. H1 title updated from "9 bats test suites cover 13 hooks and all skills (positive + negative + edge case per hook)" to "Test surface organization — 8 category bats suites + per-hook .bats files at plugins/brain-factory/tests/". Description, Preconditions, Postconditions, Invariants, Test Vectors, Verification Properties, and Traceability all rewritten to: remove consolidated `hooks.bats` reference; remove "exactly 9 suites" invariant; establish 8 category suites + 13 per-hook files model; add EC-002 for orphan bats file detection. Capability Anchor Justification updated to cite brief §Test architecture (v0.4.20) verbatim. BC-INDEX and PRD index rows cascade-updated in same burst. [audit-trail]

### v1.1 (2026-05-16)

Prior version. 9-suite model with consolidated `hooks.bats`.
