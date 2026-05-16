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
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.14.003: Engine files are read-only at runtime; state lives exclusively in target's `.brain/`

## Description

The engine/target split is a fundamental architectural constraint: the plugin files in `~/.claude/plugins/.../brain-factory/<version>/` are never modified during runtime. All mutable state lives in the target brain's `.brain/` directory. This separation ensures that one plugin version can power multiple brains without cross-contamination and that plugin upgrades are safe (no state in the plugin directory to corrupt).

## Preconditions

1. Plugin is installed at `${CLAUDE_PLUGIN_ROOT}/`.
2. Brain is at working directory with `.brain/`.

## Postconditions

1. No skill or hook ever writes to `${CLAUDE_PLUGIN_ROOT}/` at runtime.
2. All writes by brain operations target the working directory's `.brain/`, `wiki/`, `sources/`, `briefs/`, etc.

## Invariants

1. `${CLAUDE_PLUGIN_ROOT}/` is a read-only mount at runtime.
2. Template reads use `${CLAUDE_PLUGIN_ROOT}/templates/...` (read-only). Template WRITES go to the target brain.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Skill attempts to write to ${CLAUDE_PLUGIN_ROOT}/ | `enforce-kebab-case.sh` or `validate-page-type-policy.sh` would not catch this (different paths). This is a code-level correctness constraint enforced at design time, not by hooks. Implementer must not write to plugin dir. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Run /brain:ingest-url; check ${CLAUDE_PLUGIN_ROOT}/ for writes | No writes to plugin directory | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-024 | No writes to plugin dir during ingest | bats integration.bats (file-watcher on plugin dir) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-014 ("Plugin Lifecycle and Upgrade") per brief §Constraints §Technical ("Engine read-only at runtime. Plugin files are never modified by a running brain operation. State lives exclusively in the target's `.brain/`.") and plugin-plan.md §2 ("engine/target split rule 1"). |
| Architecture Module | SS-14: Plugin Lifecycle and Upgrade |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Constraints §Technical |
