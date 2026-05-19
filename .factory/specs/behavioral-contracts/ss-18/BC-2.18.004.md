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
subsystem: "SS-18"
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

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A meta-lint rule is weakened (e.g., the `Co-Authored-By: Claude` grep is changed to only check commit messages, not tracked files) | The weakening is itself detectable: the meta-lint test for Surface 4 must itself be tested for regression; if the rule weakening causes a previously-failing fixture to pass, the meta-lint self-audit bats test (which runs the old fixture) catches it; rule weakening to make a failing artifact pass is a P1 finding per CLAUDE.md §Meta-Lint Contract |
| EC-002 | A skill file references `.claude/templates/` (the development-time path) instead of `${CLAUDE_PLUGIN_ROOT}/templates/` | `meta-lint.bats` detects the hardcoded path via grep; CI blocks; the author must replace with `${CLAUDE_PLUGIN_ROOT}/templates/` before merge |
| EC-003 | An internal markdown link in a SKILL.md or AGENT.md points to a file that was renamed (link rot) | `meta-lint.bats` resolves each `[...](path)` link relative to the repo root; the renamed file is no longer at the expected path; bats fails; the link must be updated to the new path or the old path restored |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Tracked file with `Co-Authored-By: Claude` | meta-lint fails | error |
| Tracked file with `${CLAUDE_PLUGIN_ROOT}/templates/valid-template.md` where file exists | meta-lint passes | happy-path |
| Tracked file with `${CLAUDE_PLUGIN_ROOT}/templates/nonexistent.md` | meta-lint fails | error |
| Tracked skill file with `.claude/templates/foo.md` hardcoded | meta-lint fails; hardcoded path detected | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | No AI attribution in repo | meta-lint.bats (grep) |
| VP-006 | All CLAUDE_PLUGIN_ROOT refs resolve | meta-lint.bats (path check) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief CLAUDE.md §Meta-Lint Contract ("Surface 4 — Cross-cutting: no AI attribution, no --no-verify, every CLAUDE_PLUGIN_ROOT ref resolves, every internal markdown link resolves"). |
| Architecture Module | SS-18: Meta-Lint and Self-Audit |
| Stories | STORY-023 |
| Source Brief Section | product-brief.md CLAUDE.md §Meta-Lint Contract |

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-023 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
