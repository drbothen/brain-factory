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
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.02.003: `/brain:ingest-url` writes JSONL token record to `.brain/logs/ingest-tokens.jsonl`

## Description

Every invocation of `/brain:ingest-url` writes a JSONL record to `.brain/logs/ingest-tokens.jsonl` capturing token costs for the operation. This instrumentation underpins the `/brain:monthly-perf` reporting and the token budget alert in `/brain:health`. The record format is immutable in v0.1 and backward-compatible with v0.5+ chunking additions.

## Preconditions

1. `/brain:ingest-url` has completed (successfully or partially).
2. `.brain/logs/` directory exists.

## Postconditions

1. A new JSONL record is appended to `.brain/logs/ingest-tokens.jsonl`:
   `{"timestamp": "<ISO8601>", "url": "<url>", "source_id": "<slug>", "input_tokens": <N>, "output_tokens": <N>, "wiki_pages_created": <N>, "duration_seconds": <N>}`.
2. If the log file does not exist, it is created.
3. The record is appended even on partial failure (e.g., wiki page generation partially fails). The `wiki_pages_created` field reflects the actual count.

## Invariants

1. `timestamp` is always ISO8601 UTC.
2. `input_tokens` and `output_tokens` are always non-negative integers.
3. The record is appended atomically (no partial writes).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `.brain/logs/` directory does not exist | Create the directory and file before appending. |
| EC-002 | Token count unavailable (API did not return usage) | Write `{"input_tokens": -1, "output_tokens": -1}` to indicate unavailable. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Successful ingest | Valid JSONL record appended; all fields present | happy-path |
| Read `ingest-tokens.jsonl` after ingest | `jq -c '.'` parses without error; all required fields present | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | JSONL record written on every ingest | bats integration.bats |
| VP-TBD | Record schema valid | bats assertion (`jq empty` on tail of log) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Scalability Design Principles §5 ("Token budget instrumentation: `/brain:ingest-url` writes a JSONL record to `.brain/logs/ingest-tokens.jsonl` on every invocation"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §5 |

## Related BCs

- BC-2.02.001 — composes with
- BC-2.16.001 — related to (token instrumentation is a scale-aware architecture requirement)
- BC-2.16.002 — depends on (health alert reads this log)
