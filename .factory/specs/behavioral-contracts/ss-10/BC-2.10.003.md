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
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.10.003: Quarantine corpus patterns live in `scripts/quarantine.mjs`

## Description

The quarantine pattern corpus is stored in `scripts/quarantine.mjs` at the plugin level. It is a Node.js module that exports a list of prompt-injection patterns (regular expressions and keyword lists). The module is loaded by both `quarantine-fetch.sh` (hook level) and `/brain:quarantine-check` (skill level). The corpus must be versioned and updated via normal plugin release process.

## Preconditions

1. Plugin is installed at `${CLAUDE_PLUGIN_ROOT}/`.
2. `scripts/quarantine.mjs` is present and valid Node.js module syntax.

## Postconditions

1. `scripts/quarantine.mjs` exports a default array or function that returns patterns.
2. Both the hook and the skill import from this single source of truth.
3. Adding new patterns requires a plugin version bump and re-release.

## Invariants

1. There is exactly one quarantine corpus file — no duplicate pattern lists.
2. The corpus is read-only at runtime (brain operators cannot modify it without reinstalling the plugin).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Corpus contains malformed pattern (bad regex) | Module load fails; quarantine exits 2 (fail-closed). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `require('scripts/quarantine.mjs')` | Returns pattern array | happy-path |
| Malformed regex in corpus | Load error → exit 2 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-021 | quarantine.mjs exports valid pattern list | bats quarantine.bats |
| VP-021 | Hook and skill use same module | code review |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-010 ("Prompt-Injection Quarantine") per brief §Scope §Additional v0.x deliverables ("Prompt-injection corpus patterns in `scripts/quarantine.mjs`"). |
| Architecture Module | SS-10: Prompt-Injection Quarantine |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.04.001 — depends on (hook uses this corpus)
- BC-2.10.001 — depends on (skill uses this corpus)
