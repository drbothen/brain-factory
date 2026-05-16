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

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid hook.sh | meta-lint passes | happy-path |
| Hook with bare `exit` | meta-lint fails | error |
| Hook with `eval "$cmd"` | meta-lint fails | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 13 hooks pass meta-lint | bats meta-lint.bats |
| VP-TBD | No bare exit | grep + meta-lint |
| VP-TBD | No eval | grep + meta-lint |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-018 ("Meta-Lint and Self-Audit") per brief CLAUDE.md §Meta-Lint Contract ("Surface 2 — Hooks: shebang, set -euo pipefail, no bare exit, no eval, has bats file, shellcheck exits 0, shfmt exits 0"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Meta-Lint Contract |

## Related BCs

- BC-2.04.016 — composes with (hook contract defines what meta-lint enforces)
