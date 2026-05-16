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

# Behavioral Contract BC-2.09.002: `/brain:publish-content` supports `--finalize --url "..."` for LinkedIn articles manual flow

## Description

LinkedIn articles (long-form, > 3000 chars) must be published manually via the LinkedIn publishing UI. `/brain:publish-content --finalize --url "<linkedin-url>"` handles the post-publish step: it marks the already-manually-published article as `published` in the brain's state, records the LinkedIn URL, and moves the file to `published/linkedin/`. This flag is absorbed from wclaude.

## Preconditions

1. File is in `to-publish/linkedin/*.md` with `status: ready`.
2. `--finalize` and `--url` flags are both provided.
3. The provided URL is a valid LinkedIn article URL (https://www.linkedin.com/pulse/...).

## Postconditions

1. File moved to `published/linkedin/`.
2. Frontmatter updated: `status: published`, `published_at: <ISO8601>`, `linkedin_url: <url>`.
3. Exit 0. No API call is made (manual publish assumed).

## Invariants

1. `--finalize` without `--url` is an error (E-PUBLISH-007).
2. `--url` without `--finalize` is ignored (standard publish flow proceeds).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `--finalize` without `--url` | E-PUBLISH-007: "--finalize requires --url."; exit 2. |
| EC-002 | URL is not a LinkedIn URL | Warning advisory; proceeds (operator takes responsibility for URL validity). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `--finalize --url "https://www.linkedin.com/pulse/..."` | File moved; frontmatter updated; exit 0 | happy-path |
| `--finalize` without `--url` | E-PUBLISH-007; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | --finalize + --url moves file and updates frontmatter | bats skills.bats |
| VP-TBD | --finalize without --url → exit 2 | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Family Positioning ("`--finalize --url "..."` flag pattern: absorbed into `/brain:publish-content` for manual platforms including LinkedIn articles"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Family Positioning §wclaude absorption; §Scope §Phase 2–3 polish skills (#22) |

## Related BCs

- BC-2.09.001 — composes with
- BC-2.09.004 — composes with
