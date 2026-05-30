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
subsystem: "SS-09"
capability: "CAP-009"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.09.006: `/brain:monthly-perf` pulls performance data from LinkedIn Posts API and reports to `.brain/logs/`

## Description

`/brain:monthly-perf` aggregates token cost data from `.brain/logs/ingest-tokens.jsonl` and pulls performance data (impressions, engagement rate, follower growth) from the LinkedIn Posts API (Community Management) for published content. It writes a structured JSON report to `.brain/logs/monthly-perf-{YYYY-MM}.jsonl` and surfaces a summary to the operator.

## Preconditions

1. LinkedIn API credentials are configured.
2. `.brain/logs/ingest-tokens.jsonl` exists (may be empty for a new brain).
3. `published/linkedin/*.md` files contain `linkedin_post_id` frontmatter fields.

## Postconditions

1. `.brain/logs/monthly-perf-{YYYY-MM}.jsonl` written with: token cost summary, per-post engagement data, 30-day trailing average, p95 cost outlier, burn-rate projection.
2. Exit 0 with summary printed to operator.
3. If 30-day trailing average > 2x 50K-token baseline: alert surfaced (same signal as `/brain:health`).

## Invariants

1. Rate-limit handling: 429 responses trigger exponential backoff.
2. Medium perf pulls available only via the Medium reference extension (if installed).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | No published posts yet | Token cost report generated; LinkedIn API call skipped (no post IDs). |
| EC-002 | LinkedIn API 429 | Retry with backoff; up to 3 attempts; then advisory E-PERF-001. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| 5 published posts; 30 days of ingest history | monthly-perf log written; summary printed; exit 0 | happy-path |
| No published posts | Token cost report only; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | monthly-perf log written on invocation | bats skills.bats (mock API) |
| (no VP — P1) | Token budget alert surfaced when > 2x baseline | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-009 ("Publishing Pipeline") per brief §Scope §Phase 2–3 polish skills (#18: `/brain:monthly-perf — pull performance data from LinkedIn Posts API (Community Management) + registered extensions`). |
| Architecture Module | SS-09: Publishing Pipeline |
| Stories | STORY-031 |
| Source Brief Section | product-brief.md §Scope §Phase 2–3 polish skills (#18); §Scalability Design Principles §5 |

## Related BCs

- BC-2.16.001 — depends on (token data from ingest log)
- BC-2.16.002 — composes with (token alert surfaced here too)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-031 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
