---
document_type: subsystem-design
id: SS-02
title: "URL Ingest Pipeline"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-002
created: 2026-05-15
---

# SS-02: URL Ingest Pipeline

## Responsibility

Fetches a URL via Defuddle (Node 20+ utility), writes the cleaned source to `sources/{topic}/`, generates 5–15 cross-referenced wiki pages via the librarian agent, writes the manifest delta entry, logs the token cost, and enforces source-immutability against re-ingestion.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.02.001 | Fetches URL via Defuddle, writes to `sources/{topic}/` | P0 |
| BC-2.02.002 | Produces 5–15 cross-referenced wiki pages per ingest | P0 |
| BC-2.02.003 | Writes JSONL token record to `.brain/logs/ingest-tokens.jsonl` | P0 |
| BC-2.02.004 | Operates on manifest delta only (no full-corpus re-reads) | P0 |
| BC-2.02.005 | Warns when source exceeds 50K-token chunk threshold | P1 |
| BC-2.02.006 | Rejects already-ingested URL with E-INGEST-001 | P0 |
| BC-2.02.007 | Latency stays sub-linear as wiki grows 1K→10K pages | P1 |

## Interfaces

**Inbound:** `/brain:ingest-url <url> [--topic <category>]`

**Outbound:** source file at `sources/{topic}/{slug}.md`; 5–15 wiki pages; manifest.json delta entry; JSONL token record; structured events

**Emitted events:** `ingest.url.started`, `ingest.url.source_written`, `ingest.url.wiki_pages_generated`, `ingest.url.manifest_updated`, `ingest.url.completed`, `ingest.url.rejected_duplicate`

## Key Design (references ADR-010, ADR-008)

The ingest workflow orchestrated by `workflows/ingest-url.yaml`:
1. **fetch step:** `scripts/defuddle-fetch.mjs <url>` → cleaned markdown (70-90% token reduction per phased-build-plan.md §1)
2. **check-duplicate step:** `jq -e '.sources["sources/{topic}/{slug}.md"]' manifest.json` → if key exists → E-INGEST-001, exit 2
3. **write-source step:** Write to `sources/{topic}/{slug}.md` → triggers PostToolUse hooks (validate-source-immutability.sh)
4. **generate-wiki step:** brain:librarian agent with source + wiki/index.md context → 5–15 wiki page writes → partial-failure fan-out envelope
5. **write-manifest step:** atomic manifest.json update via manifest-write.sh (sha256 computed)
6. **log-tokens step:** append JSONL record to `.brain/logs/ingest-tokens.jsonl`

The 50K-token threshold check (BC-2.02.005) happens after fetch, before write-source: `wc -w <source>` scaled to token estimate; if over threshold, emit advisory (exit 1) and continue (not a block).

## Purity Classification

**Effectful shell.** Network fetch (Defuddle), filesystem writes, and manifest update are all effectful. The wiki page content generation (librarian agent) is LLM-based and non-deterministic by nature. The ingest pipeline is integration-tested, not property-tested.

## Dependencies

- SS-04 (Hook Chain): PostToolUse hooks fire on source + wiki writes
- SS-06 (Source Layer): manifest.json structure
- SS-05 (Wiki Layer): librarian writes to wiki/{type}/{slug}.md; wikilink validation
- SS-16 (Scale): token JSONL logging
- SS-17 (Event Catalog): structured events per step

## Test Surface

- `tests/skills.bats` — positive: fresh URL → source + wiki pages written; negative: duplicate URL → E-INGEST-001 (exit 2); edge: 50K+ word source → advisory exit 1
- Scale test via `workflows/scale-test.yaml` — T(10K) / T(1K) ≤ 20 (NFR-004)
