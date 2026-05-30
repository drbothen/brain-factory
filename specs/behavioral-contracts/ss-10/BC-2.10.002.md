---
document_type: behavioral-contract
level: L3
version: "1.3"
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

# Behavioral Contract BC-2.10.002: `quarantine-fetch.sh` fires on EVERY WebFetch call — cannot be bypassed by any skill

## Description

The quarantine hook registration in `hooks.json` uses `matcher: WebFetch` without conditions. This ensures the hook fires on EVERY WebFetch call — not only calls initiated by ingest skills. A skill body that calls WebFetch directly, a manual operator action, or any future skill cannot bypass the quarantine check. The hook contract (exit 2 = block) is absolute.

## Preconditions

1. `hooks.json` registers `quarantine-fetch.sh` with `matcher: WebFetch` and `event: PreToolUse`.
2. Claude Code harness is operating normally.

## Postconditions

1. Every WebFetch call triggers `quarantine-fetch.sh` before the fetch result is available to the agent.
2. No skill body can programmatically suppress the PreToolUse hook.

## Invariants

1. The hook matcher is `WebFetch` (exact); not a pattern-matched subset.
2. No exception or bypass mechanism exists in v0.x.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Skill deliberately calls WebFetch with operator-trusted content | Quarantine still fires. If the content is clean, hook exits 0 (allow). False positives are acceptable. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Any WebFetch call | quarantine-fetch.sh fires before response available | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-011 | hooks.json registers quarantine on WebFetch | bats integration.bats (hook registration check) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-010 ("Prompt-Injection Quarantine") per brief §Constraints §Technical ("Prompt-injection quarantine non-optional. Every ingest pipeline MUST run `/brain:quarantine-check` before content reaches a Claude session with tool access. This is the most important rule in the entire system.") and brief §Problem Statement ("The PreToolUse hook on WebFetch is invoked by the Claude Code harness, not by the agent. The agent cannot bypass it."). |
| Architecture Module | SS-10: Prompt-Injection Quarantine |
| Stories | STORY-006 |
| Source Brief Section | product-brief.md §Problem Statement; §Constraints §Technical |

## Related BCs

- BC-2.04.001 — composes with (quarantine-fetch.sh is defined there)
- BC-2.14.005 — depends on (hooks.json registers this)

## Changelog

### v1.3 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** Both occurrences of `hooks.json.template` updated to `hooks.json` (filename rename per ADR-003 v2.0): §Description and §Preconditions. [audit-trail]

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-006 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
