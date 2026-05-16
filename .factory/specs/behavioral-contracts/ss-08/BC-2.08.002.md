---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-008"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.08.002: `/brain:write <brief-path>` produces a full piece in the author's voice from a brief path

## Description

`/brain:write <brief-path>` takes a content brief (from BC-2.08.001) and produces a full article or post in the author's voice. The `brain:writer` agent uses the voice rules encoded in `CLAUDE.md` and the voice avoid-list to produce content consistent with the author's established style. Output is written to `drafts/linkedin/{slug}-draft.md` (or the appropriate platform subdirectory).

## Preconditions

1. `<brief-path>` resolves to a valid content brief (has ONE THING / PROOF / TRANSFORMATION sections).
2. `brain:writer` agent is available.
3. `rules/voice-avoid-list.txt` is readable.

## Postconditions

1. Full piece written to `drafts/{platform}/{slug}-draft.md`.
2. `validate-voice-avoid-list.sh` fires on the written draft (advisory if avoid-list matches).
3. Frontmatter includes: `status: draft`, `brief_path`, `platform`, `created`.
4. Exit 0.

## Invariants

1. Output is always written to the `drafts/{platform}/` directory (not directly to `to-publish/` or `published/`).
2. The voice avoid-list hook fires after the write — operator can review advisory before proceeding.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Brief path does not exist | E-WRITE-001: "Brief not found at <path>."; exit 2. |
| EC-002 | Voice avoid-list advisory fires | Hook exits 1; skill notes advisory in output; overall skill exits 0 (avoid-list is advisory). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid brief path | Draft written to `drafts/linkedin/`; exit 0 | happy-path |
| Non-existent brief path | E-WRITE-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Draft written to drafts/{platform}/ | bats skills.bats |
| VP-TBD | Voice hook fires after write | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-008 ("Content Brief and Writing") per brief §Scope §Phase 0/1 primitives skill #10 (`/brain:write <brief-path> — produce a full piece in the author's voice`). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#10) |

## Related BCs

- BC-2.08.001 — depends on
- BC-2.08.003 — composes with (flags)
- BC-2.04.008 — composes with (voice hook fires)
