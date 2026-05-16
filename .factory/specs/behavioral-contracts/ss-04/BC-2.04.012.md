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
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.012: `block-ai-attribution.sh` blocks bash commands containing AI attribution tokens (exit 2)

## Description

`block-ai-attribution.sh` fires on PreToolUse on Bash tool calls. It scans the bash command string for AI attribution tokens forbidden by project convention: `Co-Authored-By: Claude`, robot emoji (`🤖`), and the string "Generated with Claude Code". Any match triggers a hard block. This is one of the most important governance hooks — AI attribution in commits violates the explicit user directive documented in CLAUDE.md.

## Preconditions

1. PreToolUse fires on a Bash tool call.
2. The hook receives the bash command string in the stdin JSON payload.

## Postconditions

**On AI attribution token found:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-ATTR-001", "message": "Forbidden AI attribution token detected in bash command. Remove 'Co-Authored-By: Claude' / robot emoji / 'Generated with Claude Code' from the command.", "trace": "<uuid>"}`.

**On no attribution tokens:**
1. Hook exits 0.

## Invariants

1. The hook checks for all three forbidden patterns in a single scan.
2. The hook does NOT block AI attribution in content files (only bash commands that would commit such strings). Wiki content is not subject to this hook.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Bash command contains 🤖 in a comment | E-ATTR-001; exit 2. No exceptions for comments. |
| EC-002 | Bash command doing a `git commit` with forbidden trailer | E-ATTR-001; exit 2. |
| EC-003 | Bash command doing `grep "Co-Authored-By"` (searching for the pattern) | Exit 0. The hook matches the pattern as a substring; a grep command searching for the pattern does contain it. Decision: the hook scans the command string as-is. If this causes a false positive, the operator must quote/escape differently. The false-positive rate is acceptable given the safety value. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `git commit -m "feat: add feature"` | exit 0 | happy-path |
| `git commit -m "feat: add feature\n\nCo-Authored-By: Claude Opus"` | E-ATTR-001; exit 2 | error |
| `echo "🤖 done"` | E-ATTR-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 3 forbidden patterns blocked | bats hooks.bats |
| VP-TBD | Clean commands pass | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#4 `block-ai-attribution.sh`) and brief §Constraints §Technical ("No AI attribution in commits... Enforced by `block-ai-attribution.sh`"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#4); §Constraints §Technical; CLAUDE.md conventions |

## Related BCs

- BC-2.04.016 — composes with
