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

# Behavioral Contract BC-2.02.004: `/brain:ingest-url` operates on manifest delta only (no full-corpus re-reads)

## Description

At 10K sources, a full corpus re-read on each ingest would cost millions of tokens per cycle — making the operation unusable at scale. `/brain:ingest-url` must operate exclusively on the manifest delta: it reads `.brain/manifest.json` to determine what has already been ingested, then processes only the new URL. It never reads the entire `sources/` tree on each invocation.

## Preconditions

1. `.brain/manifest.json` exists and is readable.
2. The manifest follows the v0.1 schema: `{sources: [{source_id, url, topic, ingested_at, last_ingest, chunks, embeddings_model}]}`.

## Postconditions

1. The skill reads exactly: `.brain/manifest.json` (to check for duplicates and get manifest state) and the fetched URL content. It does NOT read any other source files.
2. After successful ingest, only the new entry is appended to the manifest array. Existing entries are not rewritten.
3. The manifest file write is atomic: write to a `.tmp` file, then `mv` to the canonical path.

## Invariants

1. No full-corpus `sources/` directory scan on any ingest operation.
2. Manifest append is the only manifest mutation on successful ingest (no full rewrites).
3. The manifest format supports 10K+ entries without degraded read performance (JSONL alternative considered; JSON array chosen for compatibility; architecture concern if manifest exceeds 10MB).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Manifest file corrupted | Exit with E-INGEST-007: "manifest.json unreadable — run /brain:cold-start-recover." |
| EC-002 | Manifest write fails (disk full) | Exit with E-INGEST-008: "Failed to update manifest.json: <error>." Source file write should be rolled back if manifest update fails. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Ingest with 10K entries in manifest | No full `sources/` scan; only manifest read + URL fetch; performance comparable to 10-entry manifest | edge-case |
| Manifest write succeeds | New entry in manifest; no existing entries modified | happy-path |
| Manifest write fails | Source file rolled back; E-INGEST-008 emitted | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | No sources/ directory scan during ingest | bats integration.bats (strace or file-access log) |
| VP-015 | Manifest append atomic | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Scalability Design Principles §1 ("Incremental ingest: `/brain:ingest-url` and `/brain:ingest-source` operate on the manifest delta. They never read the entire `sources/` tree on each invocation."). |
| Architecture Module | SS-02: URL Ingest Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scalability Design Principles §1 |

## Related BCs

- BC-2.02.001 — composes with
- BC-2.06.003 — depends on (manifest records timestamps)
