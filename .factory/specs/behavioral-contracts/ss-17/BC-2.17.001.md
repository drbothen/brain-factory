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
subsystem: "SS-17"
capability: "CAP-017"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.17.001: Every `hook-event:emit` site has a registered row in the structured event catalog

## Description

The structured event catalog is a machine-readable registry of all event types emitted by brain-factory's hook chain. Every `hook-event:emit` call in any hook script must have a corresponding row in the catalog before the PR that introduces the emit site can merge. Adding an emit site without a catalog row is a P1 adversarial finding. The catalog is the source of truth for event schema validation and observability tool configuration.

## Preconditions

1. A PR introduces a new `hook-event:emit` call in a hook script.

## Postconditions

1. The structured event catalog (at `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json`) has a new entry for the new event type.
2. The entry includes: `event_type`, `hook_name`, `severity`, `fields` (array), and `example` (valid JSON object).
3. The PR cannot merge until the catalog row is present and reviewed.

## Invariants

1. The catalog is append-only. Event types are never removed (only deprecated).
2. Every event_type in the catalog has a unique identifier.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Same event_type emitted from two hooks | Both hooks reference the same catalog row; the `hook_name` field in the emitted event distinguishes the emitter. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| New hook script with new emit site | Catalog row present before PR merge | happy-path |
| PR with emit site but no catalog row | Adversary flags as P1 finding; PR blocked | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-008 | All hook scripts' emit sites have catalog rows | bats tests/meta-lint.bats (cross-reference check) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-017 ("Structured Event Catalog") per brief CLAUDE.md §Structured event emission ("Every `hook-event:emit` site must appear as a row in the structured event catalog BC before the PR merges. New emission sites added without a corresponding catalog row are a P1 finding in adversarial review."). |
| Architecture Module | SS-17: Structured Event Catalog |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Structured event emission |

## Related BCs

- BC-2.17.002 — composes with (catalog schema)
- BC-2.04.017 — depends on (emit sites defined in hook contract)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/meta-lint.bats` (catalog cross-reference check; 1 row). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
