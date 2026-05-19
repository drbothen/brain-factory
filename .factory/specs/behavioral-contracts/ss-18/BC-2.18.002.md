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

# Behavioral Contract BC-2.18.002: `meta-lint.bats` validates hook scripts: shebang, `set -euo pipefail`, no bare exit, no eval

## Description

For hook scripts, `meta-lint.bats` validates: first line is `#!/usr/bin/env bash`, `set -euo pipefail` appears within first 10 lines, no bare `exit` (every `exit` followed by 0/1/2), no `eval` anywhere, has a corresponding `.bats` test file, `shellcheck` exits 0, `shfmt -d -i 2` produces no diff.

## Preconditions

1. All 13 hook scripts present in `plugins/brain-factory/hooks/`.
2. `shellcheck` and `shfmt` in PATH.
3. Corresponding bats test files exist for all 13 hooks.

## Postconditions

1. All 13 hooks pass all meta-lint assertions.
2. `shellcheck` exits 0 for all hooks.
3. `shfmt -d -i 2` exits 0 for all hooks.

## Invariants

1. Bare `exit` (without explicit code) is always a failure.
2. `eval` is always a failure.
3. `set -euo pipefail` must appear within first 10 lines.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A hook script has `set -euo pipefail` on line 11 (one line beyond the 10-line boundary) | `meta-lint.bats` fails with a message identifying the hook file and the actual line where `set -euo pipefail` appears; the implementer must move it within the first 10 lines |
| EC-002 | A hook script has `exit` inside a here-doc string (e.g., `echo "Do not exit"` contains the word `exit`) | `meta-lint.bats` must use a word-boundary grep (`\bexit\b`) rather than a substring match to avoid false positives; if the implementation uses substring match, the test itself is a defect |
| EC-003 | A new hook is added to `hooks/` but its corresponding `.bats` test file is not created | `meta-lint.bats` detects the missing test file using `ls plugins/brain-factory/tests/<hook-name>.bats`; CI blocks the PR; the implementer must create the bats file with at minimum a happy-path, error, and edge-case test |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid hook.sh | meta-lint passes | happy-path |
| Hook with bare `exit` | meta-lint fails | error |
| Hook with `eval "$cmd"` | meta-lint fails | error |
| Hook with `set -euo pipefail` on line 11 | meta-lint fails; identifies line number in message | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-006 | All 13 hooks pass meta-lint | bats meta-lint.bats |
| VP-006 | No bare exit | grep + meta-lint |
| VP-006 | No eval | grep + meta-lint |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief CLAUDE.md §Meta-Lint Contract ("Surface 2 — Hooks: shebang, set -euo pipefail, no bare exit, no eval, has bats file, shellcheck exits 0, shfmt exits 0"). |
| Architecture Module | SS-18: Meta-Lint and Self-Audit |
| Stories | STORY-023 |
| Source Brief Section | product-brief.md CLAUDE.md §Meta-Lint Contract |

## Related BCs

- BC-2.04.016 — composes with (hook contract defines what meta-lint enforces)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-023 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
