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
subsystem: "SS-13"
capability: "CAP-013"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.13.004: 4 community-optional templates ship in tarball with no-author-support documentation

## Description

The v0.5 tarball includes 4 community-optional templates: `garden-publish.yml`, `telegram-bridge.yml`, `email-inbox.yml`, `cross-repo-dispatch.yml`. These are per-operator opt-in add-ons. They are NOT author-maintained integrations; they carry no author support commitment. Each template must include a prominent comment at the top stating it is community-optional with no author support. The README documents this distinction.

## Preconditions

1. Plugin v0.5 tarball assembled.

## Postconditions

1. All 4 community-optional templates present in tarball.
2. Each template has a header comment: `# COMMUNITY OPTIONAL: This template is not author-maintained. Use at your own risk. No support commitment.`
3. README documents the community-optional distinction.

## Invariants

1. Exactly 4 community-optional templates in v0.5 tarball.
2. Community-optional templates are not covered by bats suites (no author testing commitment).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Operator installs a community-optional template but does not have the required external service configured (e.g., Telegram bot token absent) | The template fails at runtime with a service-configuration error; the failure is contained to that template run; no other brain operations are affected |
| EC-002 | Community-optional template header comment is missing or truncated in the tarball | `grep` assertion in meta-lint.bats detects missing or partial comment; tarball integrity check fails; release gate blocks |
| EC-003 | A contributor submits a PR adding a 5th community-optional template | The PR must document the addition; the template must include the standard disclaimer comment; the BC invariant (exactly 4) is updated to reflect the new count via a separate BC amendment — the current count is not silently exceeded |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `head -3 garden-publish.yml` | Community optional comment present | happy-path |
| `head -3 telegram-bridge.yml` | Community optional comment present | happy-path |
| `garden-publish.yml` with disclaimer comment removed | `grep` assertion fails; tarball check blocks release | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P2) | All 4 community templates have disclaimer comment | grep assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-013 ("GitHub Action Templates") per brief §Scope §GH Action templates ("Community-optional add-ons (4) — shipped in the v0.5 tarball for per-operator opt-in; no author support commitment"). |
| Architecture Module | SS-13: GitHub Action Templates |
| Stories | STORY-035 |
| Source Brief Section | product-brief.md §Scope §GH Action templates |

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-035 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
