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
subsystem: "SS-13"
capability: "CAP-013"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.13.003: Rate-limit handling: 429 responses trigger exponential backoff with `retry-after` respect

## Description

Any GH Action template that calls an external API (LinkedIn, Readwise, Raindrop) must handle 429 (Too Many Requests) responses with exponential backoff. The backoff uses the `retry-after` response header if present; otherwise defaults to 60-second base with exponential growth. A maximum of 3 retry attempts is enforced; after that, the job fails with E-RATE-001.

## Preconditions

1. An API call returns 429.

## Postconditions

1. Retry after `retry-after` seconds (or 60s default).
2. Subsequent retries use exponential backoff: 60s, 120s, 240s.
3. After 3 failures: E-RATE-001 surfaced; job exits 1 (advisory — data may be partial).
4. No data loss for already-processed items in the same run.

## Invariants

1. All 3 API-calling templates (LinkedIn, Readwise, Raindrop) implement this logic.
2. Backoff logic is shared (not copy-pasted per template) — centralized in `scripts/api-retry.sh`.

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Mock API returns 429 once | Retry after delay; second call succeeds | happy-path |
| Mock API returns 429 three times | E-RATE-001; exit 1; partial data preserved | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | 429 → retry with backoff | bats upgrade.bats (mock API) |
| VP-TBD | 3 failures → E-RATE-001 | bats upgrade.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-013 ("GitHub Action Templates") per brief §Scalability Design Principles §4 ("Rate-limit handling (LinkedIn Posts API, Readwise, Raindrop) is explicit: 429 responses trigger exponential backoff with `retry-after` header respect, not hard failures."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §4 |
