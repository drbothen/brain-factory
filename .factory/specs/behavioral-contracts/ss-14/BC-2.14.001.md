---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.14.001: `/plugin install brain-factory@claude-mp` succeeds in a fresh Claude session

## Description

The primary distribution mechanism for brain-factory is the `drbothen/claude-mp` marketplace. An operator running `/plugin install brain-factory@claude-mp` in a fresh Claude Code session must receive a working plugin installation. The tarball at the current version is pulled from GitHub Releases, extracted, and the plugin is loaded by Claude Code. This is the end-to-end install contract.

## Preconditions

1. Claude Code is installed with network access.
2. `drbothen/claude-mp` marketplace has the current version of brain-factory.
3. GitHub Releases has the tarball for the current version.

## Postconditions

1. Plugin files are extracted to `~/.claude/plugins/.../brain-factory/<version>/`.
2. `claude --plugin-dir` loads the plugin without error.
3. `/brain:health` returns a response (may be RED on a new non-brain directory; no crash).
4. Exit 0.

## Invariants

1. The tarball is the only distribution mechanism in v0.x (no `npm install`, no `pip install`).
2. The tarball contains: plugin.json, hooks.json.template, all 13 hook scripts, all 26 skill SKILL.md files, all 14 agent AGENT.md files, all templates, all workflows, all scripts.
3. Planning docs do NOT ship in the published tarball.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Marketplace is unreachable | Claude Code surfaces "marketplace unreachable" error — not a brain-factory bug. |
| EC-002 | Tarball SHA mismatch | Installation fails; SHA validation error surfaced. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh Claude session; `/plugin install brain-factory@claude-mp` | Plugin loads; /brain:health callable; exit 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-024 | Plugin installs and loads from marketplace | bats upgrade.bats (local install simulation) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-014 ("Plugin Lifecycle and Upgrade") per brief §Success Criteria §v0.1 ship gate ("`/plugin install brain-factory@claude-mp` succeeds in a fresh Claude session"). |
| Architecture Module | SS-14: Plugin Lifecycle and Upgrade |
| Stories | STORY-005 |
| Source Brief Section | product-brief.md §Success Criteria §v0.1 ship gate |

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-005 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
