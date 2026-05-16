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
capability: "CAP-014"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.14.004: `plugin.json` is valid JSON with semver version and all agents/skills registered

## Description

`plugin.json` is the Claude Code plugin manifest. It must be valid JSON, contain a semver version string, and register all 14 agents and all 26 skills in the appropriate manifest sections. This is a v0.1 ship gate requirement. An invalid or incomplete `plugin.json` prevents Claude Code from loading the plugin.

## Preconditions

1. Plugin release process has run.
2. All 26 SKILL.md and 14 AGENT.md files are present in the tarball.

## Postconditions

1. `plugin.json` is valid JSON (parseable by `jq`).
2. `plugin.json` contains `"version": "0.1.0"` (or current release version) as a valid semver string.
3. All 26 skills are registered in the `skills` array.
4. All 14 agents are registered in the `agents` array.
5. `claude --plugin-dir ./plugins/brain-factory` loads without error.

## Invariants

1. The version in `plugin.json` must match the git tag for the release.
2. Skill and agent counts in `plugin.json` must match the canonical counts (26/14).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A skill is in plugin.json but SKILL.md file is missing from tarball | Plugin load fails. CI must validate both. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `jq '.' plugin.json` | Valid JSON; exit 0 | happy-path |
| `jq '.skills | length' plugin.json` | 26 | happy-path |
| `jq '.agents | length' plugin.json` | 14 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | plugin.json valid JSON | bats integration.bats |
| VP-TBD | 26 skills and 14 agents registered | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-014 ("Plugin Lifecycle and Upgrade") per brief §Success Criteria §v0.1 ship gate ("`plugin.json` valid, version 0.1.0") and §Scope §Additional v0.x deliverables ("`plugin.json` — Claude Code plugin manifest"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Success Criteria §v0.1 ship gate; §Scope §Additional v0.x deliverables |
