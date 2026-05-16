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
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.017: Hook structured event emission: every hook emits JSONL events on stderr via hook-event catalog

## Description

Every hook in the 13-hook set emits structured JSONL events to stderr on every invocation. These events are the observability stream for brain-factory in v0.x (file logs only; OTEL sinks are v1.0). Every `hook-event:emit` site (the helper call that writes to stderr) must have a corresponding row in the structured event catalog. A new emission site without a catalog row is a P1 adversarial finding. This BC defines the JSONL event schema and the catalog requirement.

## Preconditions

1. Hook is executing (any of the 13 hooks, any event type).
2. The `hook-event:emit` helper function is sourced from `${CLAUDE_PLUGIN_ROOT}/scripts/hook-event-emit.sh`.

## Postconditions

1. For every hook invocation, at minimum one JSONL event is written to stderr.
2. Every emitted JSONL event conforms to the base schema: `{"ts": "<ISO8601>", "event_type": "<catalog-registered-event-type>", "hook_name": "<script-name>", "trace": "<uuid>", ...hook-specific-fields}`.
3. The `event_type` value appears in the structured event catalog (BC-2.17.001 and BC-2.17.002 define the catalog).
4. stdout is reserved exclusively for the JSON verdict. stderr is reserved exclusively for JSONL events. No hook mixes these streams.
5. No secrets (API keys, tokens, credentials) appear in any emitted event.

## Invariants

1. `ts` is always a valid ISO 8601 timestamp.
2. `hook_name` is always the basename of the hook script (e.g., `quarantine-fetch.sh`).
3. `trace` is always a UUID (v4 preferred) consistent within a single hook invocation.
4. Event types are lowercase dot-separated strings: `quarantine.block`, `source.immutability.violation`, `wiki.wikilink.broken`, etc.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `hook-event-emit.sh` helper is missing | Hook emits a best-effort JSONL directly to stderr and exits 2 with E-HOOK-002: "Event emission helper missing." |
| EC-002 | Hook invoked in a context where stderr is not writable | Hook logs to a fallback location (`.brain/logs/hooks-emergency.jsonl`) if stderr is unavailable. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Any hook invocation | At least one valid JSONL line on stderr | happy-path |
| Hook blocking a write | Event on stderr with `event_type` ending in `.block` or `.violation` | happy-path |
| Hook allowing a write | Event on stderr with `event_type` ending in `.allow` or `.new` | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 13 hooks emit at least one JSONL line per invocation | bats hooks.bats (stderr capture assertion) |
| VP-TBD | JSONL schema valid for all emitted events | bats assertion (`jq empty` on stderr capture) |
| VP-TBD | No secrets in emitted events | grep assertion on stderr capture |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief CLAUDE.md §Logging ("Hooks emit structured events via `hook-event:emit`. Format: JSONL on stderr with `ts`, `event_type`, `plugin`, `trace`, plus event-specific fields. All `event_type` values must be registered in the structured event catalog BC before the PR merges.") and brief §Structured event emission. |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Logging; §Structured event emission |

## Related BCs

- BC-2.04.016 — composes with (stdout/stderr separation is part of the I/O contract)
- BC-2.17.001 — depends on (catalog registration requirement)
- BC-2.17.002 — depends on (catalog schema)
- BC-2.17.003 — composes with (this BC implements the stderr-only rule)
- BC-2.17.004 — composes with (no secrets in emission)
