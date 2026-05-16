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

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `rss-inbox.yml` with 5 feeds | 5 parallel jobs via matrix; all complete; exit 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Matrix strategy present in rss/readwise/raindrop templates | bats upgrade.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-013 ("GitHub Action Templates") per brief §Scope §GH Action templates ("v0.5 additions — author-committed (9)") and §Scalability Design Principles §4 ("GH Action parallelism: rss-inbox.yml fans out per feed; readwise-sync.yml fans out per batch"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §GH Action templates; §Scalability Design Principles §4 |
