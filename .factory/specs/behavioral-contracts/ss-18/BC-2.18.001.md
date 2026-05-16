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
subsystem: "SS-18"
capability: "CAP-018"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.18.001: `meta-lint.bats` validates SKILL.md frontmatter and canonical 6-section structure

## Description

`plugins/brain-factory/tests/meta-lint.bats` validates the factory's own source artifacts against their templates. For skills: it checks YAML frontmatter presence, required fields (`name`, `description`, `argument-hint`, `allowed-tools`), section headings in canonical order (Iron Law, Red Flags, Announce-at-Start, Procedure, Quality Bar, Output), Iron Law non-empty and ≤ 200 chars, Red Flags has ≥ 1 bullet, Procedure is a numbered list, and no `.claude/templates/` hardcoded paths.

## Preconditions

1. All 26 SKILL.md files exist in the plugin.
2. `bats` is available.

## Postconditions

1. All 26 skills pass all meta-lint assertions.
2. `bats plugins/brain-factory/tests/meta-lint.bats` exits 0.
3. Any SKILL.md failing a check is a P1 adversarial finding.

## Invariants

1. Meta-lint rules MUST NOT be weakened to make a failing artifact pass. If artifact fails, fix the artifact.
2. Meta-lint runs in CI (mandatory, blocking) and as part of the pre-push gate.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | New skill added without following template | meta-lint catches missing section; CI blocks. |
| EC-002 | Iron Law > 200 chars | Meta-lint fails with assertion: "Iron Law too long in <skill-name>." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid SKILL.md conforming to template | meta-lint passes for this skill | happy-path |
| SKILL.md missing Iron Law section | meta-lint fails | error |
| SKILL.md with hardcoded `.claude/templates/` path | meta-lint fails | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | All 26 skills pass meta-lint | bats meta-lint.bats |
| VP-006 | No `.claude/templates/` paths in any SKILL.md | grep assertion + meta-lint |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief CLAUDE.md §Meta-Lint Contract ("Surface 1 — Skills: frontmatter, canonical 6-section structure, Iron Law ≤ 200 chars, Red Flags ≥ 1 bullet, numbered Procedure, no `.claude/templates/` paths"). |
| Architecture Module | SS-18: Meta-Lint and Self-Audit |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Meta-Lint Contract |

## Related BCs

- BC-2.18.002 — composes with (hook meta-lint)
- BC-2.18.003 — composes with (agent meta-lint)
- BC-2.18.004 — composes with (cross-cutting meta-lint)
- BC-2.18.005 — depends on (this is part of the 9-suite bats coverage)
