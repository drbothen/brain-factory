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
capability: "CAP-018"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.18.003: `meta-lint.bats` validates AGENT.md scope + tool-profile + routing reference

## Description

For agent files, `meta-lint.bats` validates: frontmatter present with `name`, `scope`, `tool-profile` fields; body references the Agent Routing Table (substring match on the CLAUDE.md anchor); allowed/denied tools explicitly enumerated; filename and directory are kebab-case lowercase.

## Preconditions

1. All 14 AGENT.md files present in `plugins/brain-factory/agents/`.

## Postconditions

1. All 14 agents pass all meta-lint assertions.
2. `bats meta-lint.bats` exits 0 for agent surface.

## Invariants

1. Missing `tool-profile` is always a failure.
2. Missing routing-table reference is always a failure.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | An AGENT.md has a `tool-profile` field but lists zero allowed tools and zero denied tools (empty enumeration) | `meta-lint.bats` fails; the tool-profile must enumerate at least one allowed or denied tool explicitly; an empty `tool-profile` is not equivalent to a complete tool-profile declaration |
| EC-002 | An AGENT.md references the routing table using paraphrased anchor text instead of the canonical substring `Agent Routing Table` | `meta-lint.bats` uses a substring match for the exact string `Agent Routing Table`; a paraphrase does not satisfy the assertion; the meta-lint failure directs the author to use the canonical phrase |
| EC-003 | A new agent is added to `plugins/brain-factory/agents/` but the CLAUDE.md Agent Routing Table is not updated with a corresponding row | `meta-lint.bats` does not detect this gap (it validates the AGENT.md file body, not CLAUDE.md); however, the adversary catches this during Phase 1d review; the production-grade fix requires both the AGENT.md to pass meta-lint AND a CLAUDE.md routing row to be present |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid AGENT.md | meta-lint passes | happy-path |
| AGENT.md without `tool-profile` | meta-lint fails | error |
| AGENT.md with empty `allowed-tools: []` and empty `denied-tools: []` | meta-lint fails; empty enumeration is not compliant | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 14 agents pass meta-lint | bats meta-lint.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief CLAUDE.md §Meta-Lint Contract ("Surface 3 — Agents: frontmatter with name/scope/tool-profile, routing table reference, allowed/denied tools enumerated, kebab-case filename"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Meta-Lint Contract |
