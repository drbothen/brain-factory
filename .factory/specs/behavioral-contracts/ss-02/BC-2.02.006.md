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
capability: "CAP-002"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.02.006: `/brain:ingest-url` rejects already-ingested URL (source-immutability guard)

## Description

Source immutability applies not just at the file-system level (via the hook) but also at the skill level. `/brain:ingest-url` performs an upfront duplicate check against `.brain/manifest.json` before fetching the URL at all. This prevents redundant API calls, redundant token usage, and potential race conditions with the immutability hook.

## Preconditions

1. `.brain/manifest.json` is readable.
2. The URL parameter is provided.

## Postconditions

**On duplicate URL:**
1. Skill exits 2 (before any fetch occurs).
2. Emits E-INGEST-001: "URL already ingested as <slug>. Sources are immutable."
3. No fetch is performed. No token cost incurred.

**On new URL:**
1. Proceed with fetch (BC-2.02.001).

## Invariants

1. The URL check is performed BEFORE the Defuddle fetch. No tokens are spent on a duplicate.
2. URL matching is exact string comparison against `manifest.json` entries.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Same URL with different query string | Treated as different URL (exact match). Ingest proceeds. |
| EC-002 | URL redirects to a previously-ingested URL | Not detected in v0.1 (redirect resolution is v0.5+). Operator must manage manually. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| First ingest of URL | Proceeds to fetch | happy-path |
| Second ingest of same URL | E-INGEST-001; exit 2; no fetch | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Duplicate URL blocked before fetch | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Scalability Design Principles §1 (incremental ingest; manifest-delta; source immutability). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §1; §Scope §Phase 0/1 primitives (#3) |

## Related BCs

- BC-2.02.001 — composes with (this check is the first gate in BC-2.02.001)
- BC-2.04.002 — related to (immutability also enforced at hook level after write)
