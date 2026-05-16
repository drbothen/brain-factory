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
subsystem: "SS-09"
capability: "CAP-009"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.09.003: `/brain:publish-content` supports `--schedule <date>` flag

## Description

`/brain:publish-content --schedule <date>` schedules a post for future publication. The file is moved to `to-publish/linkedin/` with `status: ready` and a `scheduled_for: <date>` frontmatter field. The actual publication occurs via the `monthly-perf.yml` GH Action (or a dedicated scheduler action) at the scheduled date. In v0.1 the schedule is tracked via frontmatter only; the GH Action picks it up at v0.5.

## Preconditions

1. File is in `drafts/linkedin/` or `to-publish/linkedin/`.
2. `--schedule <date>` flag provided with a valid ISO8601 date.

## Postconditions

1. File moved to `to-publish/linkedin/` (if not already there).
2. Frontmatter updated: `status: ready`, `scheduled_for: <date>`.
3. No API call made. Exit 0 with confirmation.

## Invariants

1. `scheduled_for` is a future date relative to the current date.
2. Past dates trigger advisory: "Scheduled date is in the past. Use --finalize or remove --schedule to publish immediately."

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Past date | Advisory; still updates frontmatter; exit 0. |
| EC-002 | Invalid date format | E-PUBLISH-008: "Invalid date format. Use ISO8601: YYYY-MM-DD."; exit 2. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `--schedule 2026-06-01` | `scheduled_for: 2026-06-01` in frontmatter; exit 0 | happy-path |
| `--schedule "next week"` | E-PUBLISH-008; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | scheduled_for written to frontmatter | bats skills.bats |
| (no VP — P1) | Invalid date format → exit 2 | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Family Positioning ("`--schedule <date>` flag on `/brain:publish-content` (no new skill).") and §Scope §Phase 2–3 polish skills (#22: `flags: --finalize, --schedule`). |
| Architecture Module | SS-09: Publishing Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Family Positioning §wclaude absorption; §Scope §Phase 2–3 polish skills (#22) |

## Related BCs

- BC-2.09.001 — composes with
