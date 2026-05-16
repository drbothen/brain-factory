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

# Behavioral Contract BC-2.13.002: v0.5 additions (9 author-committed templates) ship with matrix strategy parallelism

## Description

The v0.5 tarball adds 9 more author-committed templates: `rss-inbox.yml`, `issue-capture.yml`, `readwise-sync.yml`, `raindrop-sync.yml`, `auto-connect.yml`, `monthly-perf.yml`, `token-budget.yml`, `cold-start.yml`, `snapshot.yml`. Templates that process multiple sources per run (rss-inbox, readwise-sync, raindrop-sync) must use GitHub Actions matrix strategy for parallelism.

## Preconditions

1. Plugin v0.5 installed.
2. Relevant API credentials configured (Readwise, Raindrop, etc.).

## Postconditions

1. Matrix-strategy templates fan out per feed/batch.
2. Rate-limit handling in each template: 429 → exponential backoff with `retry-after`.
3. 100 sources/day sustained ingest without data loss.

## Invariants

1. Exactly 9 new author-committed templates at v0.5 (total: 15 author-committed).
2. Matrix parallelism is explicit in the YAML (`strategy.matrix` declaration).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | One matrix job fails (single feed returns 429 after all retries exhaust) | The failed job exits 2; other matrix jobs complete successfully; the overall Action run fails; no data loss for feeds that succeeded; the failed feed is retryable on the next scheduled run |
| EC-002 | `strategy.matrix` declaration is absent from a multi-source template | `meta-lint.bats` detects the missing matrix declaration and fails; CI blocks the PR until the declaration is added |
| EC-003 | v0.5 tarball assembled without one of the 9 required templates | The tarball integrity check (bats upgrade.bats) detects the missing template and fails; tarball is rejected; release gate does not pass |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `rss-inbox.yml` with 5 feeds | 5 parallel jobs via matrix; all complete; exit 0 | happy-path |
| `rss-inbox.yml` with 1 feed returning 429 after max retries | That matrix job exits 2; other jobs succeed; Action run fails; no data lost for other feeds | error |
| `readwise-sync.yml` with `strategy.matrix` removed | `meta-lint.bats` reports missing matrix declaration; CI blocks merge | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Matrix strategy present in rss/readwise/raindrop templates | bats upgrade.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-013 ("GitHub Action Templates") per brief §Scope §GH Action templates ("v0.5 additions — author-committed (9)") and §Scalability Design Principles §4 ("GH Action parallelism: rss-inbox.yml fans out per feed; readwise-sync.yml fans out per batch"). |
| Architecture Module | SS-13: GitHub Action Templates |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §GH Action templates; §Scalability Design Principles §4 |
