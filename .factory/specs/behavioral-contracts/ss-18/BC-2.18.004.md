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
capability: "CAP-018"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.18.004: `meta-lint.bats` validates cross-cutting: no AI attribution, no `--no-verify`, no hardcoded template paths

## Description

For all tracked repo files, `meta-lint.bats` validates: no file contains `Co-Authored-By: Claude`; no file contains the robot emoji; no `--no-verify` in any committed script (test files excepted only if explicitly justified); every `${CLAUDE_PLUGIN_ROOT}/...` reference resolves to a path that exists under `plugins/brain-factory/`; every internal markdown link resolves.

## Preconditions

1. Plugin repo is clean (all files tracked in git).
2. `git ls-files` enumerates all tracked files.

## Postconditions

1. No tracked file fails any cross-cutting assertion.
2. `bats meta-lint.bats` exits 0 for cross-cutting surface.

## Invariants

1. `Co-Authored-By: Claude` is always a failure.
2. `--no-verify` is always a failure (no exceptions without explicit documented justification).
3. Hardcoded `.claude/templates/` is always a failure.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Tracked file with `Co-Authored-By: Claude` | meta-lint fails | error |
| Tracked file with `${CLAUDE_PLUGIN_ROOT}/templates/valid-template.md` where file exists | meta-lint passes | happy-path |
| Tracked file with `${CLAUDE_PLUGIN_ROOT}/templates/nonexistent.md` | meta-lint fails | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | No AI attribution in repo | meta-lint.bats (grep) |
| VP-TBD | All CLAUDE_PLUGIN_ROOT refs resolve | meta-lint.bats (path check) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief CLAUDE.md §Meta-Lint Contract ("Surface 4 — Cross-cutting: no AI attribution, no --no-verify, every CLAUDE_PLUGIN_ROOT ref resolves, every internal markdown link resolves"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Meta-Lint Contract |
