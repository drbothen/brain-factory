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

# Behavioral Contract BC-2.14.005: `hooks.json.template` references all 13 hooks via `${CLAUDE_PLUGIN_ROOT}`

## Description

`hooks.json.template` is the per-platform hooks configuration template. It references all 13 hook scripts via the `${CLAUDE_PLUGIN_ROOT}` environment variable, never with hardcoded absolute paths. Per-platform hooks.json variants (darwin-arm64, darwin-x86_64, linux-x86_64, windows-x86_64) are generated from this template at install or release time. This template is the source of truth for hook registration.

## Preconditions

1. `hooks.json.template` exists at `${CLAUDE_PLUGIN_ROOT}/hooks.json.template`.

## Postconditions

1. `hooks.json.template` is valid JSON.
2. All 13 hooks are registered with correct event types and matchers.
3. All hook paths use `${CLAUDE_PLUGIN_ROOT}/hooks/<script-name>` (no absolute paths).
4. Generated per-platform variants match the template content for v0.x bash hooks.

## Invariants

1. `${CLAUDE_PLUGIN_ROOT}` is used at every hook path reference.
2. The template contains exactly 13 hook entries — no more, no less.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `${CLAUDE_PLUGIN_ROOT}` not set at runtime | Hook fails to load; Claude Code surfaces the error. Not a template bug. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `jq '.hooks | length' hooks.json.template` | 13 | happy-path |
| `grep -c '${CLAUDE_PLUGIN_ROOT}' hooks.json.template` | 13 | happy-path |
| `grep 'claude/templates' hooks.json.template` | 0 (no hardcoded paths) | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-009 | 13 hooks registered in template | bats integration.bats |
| VP-009 | No hardcoded absolute paths | grep assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-014 ("Plugin Lifecycle and Upgrade") per brief §Success Criteria §v0.1 ship gate ("`hooks.json.template` valid JSON; references all hooks via `${CLAUDE_PLUGIN_ROOT}`") and §Scope §Additional v0.x deliverables ("`hooks.json.template`"). |
| Architecture Module | SS-14: Plugin Lifecycle and Upgrade |
| Stories | STORY-001 |
| Source Brief Section | product-brief.md §Success Criteria §v0.1 ship gate; §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.10.002 — depends on (quarantine hook registration here)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-001 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
