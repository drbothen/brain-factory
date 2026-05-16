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
capability: "CAP-007"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.07.002: `/brain:adversary-review` dispatches all four wclaude validation agents

## Description

`/brain:adversary-review <path>` dispatches all four absorbed wclaude validation agents as sub-agents: `brain:voice-analyzer`, `brain:content-structure-reviewer`, `brain:frontmatter-validator`, `brain:platform-compliance-checker`. Each agent reviews the artifact from its specialized perspective. The skill aggregates all findings and presents a consolidated pass/fail verdict.

## Preconditions

1. All four validation agents are registered in the plugin manifest.
2. The artifact at `<path>` is a markdown file.

## Postconditions

1. All four agents are dispatched in sequence (or parallel if the orchestrator supports it).
2. Each agent's findings are collected.
3. Consolidated result: `{"verdict": "PASS|FAIL", "agents": {"voice_analyzer": {...}, "content_structure": {...}, "frontmatter": {...}, "platform_compliance": {...}}, "overall_issues": [...]}`.
4. If any agent returns FAIL, the overall verdict is FAIL.
5. Exit 0 on PASS; exit 1 on FAIL.

## Invariants

1. All four agents ALWAYS run — no short-circuit on the first FAIL.
2. Each agent runs in the adversary model family (different from producer model).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | One agent errors (e.g., network timeout) | Overall verdict is FAIL with error note. The other agents' results are still reported. |
| EC-002 | Artifact has no frontmatter | `brain:frontmatter-validator` finds the missing frontmatter; FAIL. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| High-quality article with all required fields | All 4 agents PASS; overall PASS; exit 0 | happy-path |
| Article with LinkedIn-incompatible length | `brain:platform-compliance-checker` FAIL; overall FAIL; exit 1 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 4 agents dispatched and return results | bats adversary.bats |
| VP-TBD | Any agent FAIL → overall FAIL | bats adversary.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-007 ("Adversarial Review and Writescore") per brief §Scope §Phase 0/1 primitives (#13: `/brain:adversary-review <path> — fresh-context quality gate with multi-pass writescore revision loop via the four absorbed wclaude validation agents`). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#13); §Family Positioning §wclaude absorption |

## Related BCs

- BC-2.07.001 — depends on (model family constraint)
