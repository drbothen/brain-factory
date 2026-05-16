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

# Behavioral Contract BC-2.09.001: `/brain:publish-content` posts to LinkedIn via Posts API (Community Management)

## Description

`/brain:publish-content <file>` publishes a ready-state content file to LinkedIn using the LinkedIn Posts API (Community Management — the replacement for the deprecated UGC API). The file must be in `to-publish/linkedin/` state. After successful publication, the file is moved to `published/linkedin/` and its frontmatter is updated with `status: published` and `published_at`.

## Preconditions

1. `<file>` is in `to-publish/linkedin/*.md` with `status: ready` frontmatter.
2. LinkedIn API credentials are configured in `.brain/policies.yaml` (or environment variable).
3. File content length is within LinkedIn Posts API limits (posts: ≤ 3000 chars; articles: not published via Posts API — use `--finalize` flag).

## Postconditions

1. Post published to LinkedIn via Posts API.
2. File moved to `published/linkedin/{slug}.md`.
3. Frontmatter updated: `status: published`, `published_at: <ISO8601>`, `linkedin_post_id: <id>`.
4. `validate-publish-state.sh` fires on the updated file (validates `ready → published` transition).
5. Exit 0 with publication summary.

## Invariants

1. The Posts API (Community Management) is used — NOT the deprecated UGC API.
2. A 429 (rate limit) response triggers exponential backoff with `retry-after` header respect.
3. The file is only moved to `published/` after confirmed API success (201 response or equivalent).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Content > 3000 chars (too long for post) | E-PUBLISH-003: "Content too long for LinkedIn post. Use --finalize for articles." Exit 2. |
| EC-002 | 429 rate limit from API | Retry with backoff; up to 3 attempts; then E-PUBLISH-004 advisory. |
| EC-003 | API credentials not configured | E-PUBLISH-005: "LinkedIn API credentials not configured in policies.yaml." Exit 2. |
| EC-004 | File is in `drafts/` (not ready) | E-PUBLISH-006: "File is not in ready state. Run adversary review and move to to-publish/ first." Exit 2. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid ready-state LinkedIn post | Published; moved to published/; exit 0 | happy-path |
| Post > 3000 chars | E-PUBLISH-003; exit 2 | error |
| 429 response | Retry; backoff; eventual success or E-PUBLISH-004 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-020 | File moved to published/ on success | bats skills.bats (mock API) |
| VP-020 | 429 triggers retry-with-backoff | bats skills.bats (mock API) |
| VP-020 | Frontmatter updated with published_at | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Scope §Phase 2–3 polish skills (#22: `/brain:publish-content <file> — publishing orchestrator supporting LinkedIn Posts API (Community Management)`). |
| Architecture Module | SS-09: Publishing Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 2–3 polish skills (#22); §Success Criteria §v0.5 milestone |

## Related BCs

- BC-2.09.004 — composes with (state machine enforced)
- BC-2.09.005 — composes with (directory structure)
