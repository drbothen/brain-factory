---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-017"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.17.002: Event catalog defines: event_type, hook_name, severity, fields, example payload

## Description

Each row in the structured event catalog has a defined schema. The catalog is a markdown table in `plugins/brain-factory/docs/event-catalog.md`. The schema ensures observability tools and the adversary can validate emitted events against the catalog.

## Preconditions

1. `plugins/brain-factory/docs/event-catalog.md` exists.

## Postconditions

1. Each catalog row contains: `event_type` (string, unique), `hook_name` (string), `severity` (INFO|WARN|ERROR), `trigger` (what causes this event), `fields` (name:type:description for each), `example_payload` (valid JSON JSONL line).
2. Table is human-readable markdown.

## Invariants

1. All `event_type` values match the pattern `<subsystem>.<action>` (dot-separated, lowercase).
2. `example_payload` is valid JSON.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Parse event-catalog.md as markdown table | All rows have required columns | happy-path |
| `jq empty` on each example_payload | All parse as valid JSON | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All rows have required fields | bats integration.bats (markdown table parse) |
| VP-TBD | All example payloads are valid JSON | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-017 ("Structured Event Catalog") per brief CLAUDE.md §Logging ("Format: JSONL on stderr with `ts`, `event_type`, `plugin`, `trace`, plus event-specific fields. All `event_type` values must be registered in the structured event catalog BC before the PR merges."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md CLAUDE.md §Logging |

## Related BCs

- BC-2.17.001 — composes with
