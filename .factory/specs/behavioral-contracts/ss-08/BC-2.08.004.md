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
subsystem: "SS-08"
capability: "CAP-008"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.08.004: Voice avoid-list (30 entries in `rules/voice-avoid-list.txt`) is enforced on brief drafts

## Description

The voice avoid-list is a 30-entry list of words and phrases that degrade the author's writing quality (LinkedIn-speak, clichés, AI-pattern phrases). It is enforced by `validate-voice-avoid-list.sh` (BC-2.04.008) on PostToolUse for `briefs/content/*-draft.md` writes. This BC defines the avoid-list file contract — its location, format, and update procedure.

## Preconditions

1. `/brain:init` has copied `rules/voice-avoid-list.txt` from `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt` to the brain's `rules/` directory.

## Postconditions

1. `rules/voice-avoid-list.txt` contains exactly 30 entries at v0.1 release.
2. Each entry is one term or phrase per line (no blank lines, no comments).
3. The hook reads this file to check drafts.

## Invariants

1. The avoid-list is stored in the brain's `rules/` directory (operator-accessible, operator-editable).
2. The plugin ships the default 30-entry list; operators may add entries via `/brain:policy-add` convention (though the policy mechanism is different from the voice-list file).
3. The avoid-list file is not immutable — operators can customize it. Hook reads it fresh on each invocation.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `rules/voice-avoid-list.txt` is empty (operator cleared it) | Hook exits 0 on all drafts (vacuously no matches). This is intentional operator customization. |
| EC-002 | Entry in avoid-list is a multi-word phrase | Hook checks for the full phrase (not individual words). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Draft with "game-changer" (in avoid-list) | Advisory; exit 1 | happy-path |
| Draft with no avoid-list terms | exit 0 | happy-path |
| `rules/voice-avoid-list.txt` has 30 entries | Confirmed by meta-lint | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Default avoid-list has exactly 30 entries | bats templates.bats (or meta-lint) |
| (no VP — P1) | All 30 entries trigger advisory | bats tests/validate-voice-avoid-list.bats (parameterized) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-008 ("Content Brief and Writing") per brief §Scope §Additional v0.x deliverables ("30-entry voice avoid-list in `rules/voice-avoid-list.txt`"). |
| Architecture Module | SS-08: Content Brief and Writing |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.04.008 — depends on (hook enforces the avoid-list)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-voice-avoid-list.bats` (1 row). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
