---
document_type: subsystem-design
id: SS-03
title: "Source Ingest Pipeline"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-003
created: 2026-05-15
---

# SS-03: Source Ingest Pipeline

## Responsibility

Ingests a local file (PDF, markdown, text) into `sources/{topic}/`, generates wiki pages via the librarian agent, writes the manifest delta entry, and propagates partial-failure fan-out for multi-page generation.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.03.001 | Ingests local file into `sources/{topic}/` and wiki layer | P0 |
| BC-2.03.002 | Writes manifest delta entry on every successful ingest | P0 |
| BC-2.03.003 | Rejects paths outside the brain vault root | P0 |
| BC-2.03.004 | Propagates partial-failure fan-out (per-page results; no silent swallow) | P0 |

## Interfaces

**Inbound:** `/brain:ingest-source <path> [--topic <category>]`

**Outbound:** source file at `sources/{topic}/{slug}.md` (copied from local path); 5–15 wiki pages; manifest.json delta entry; structured events

**Emitted events:** `ingest.source.started`, `ingest.source.path_rejected`, `ingest.source.written`, `ingest.source.wiki_pages_generated`, `ingest.source.completed`

## Key Design

The local-file ingest workflow (`workflows/ingest-source.yaml`) mirrors the URL pipeline (SS-02) with two key differences:

1. **No Defuddle step:** the local file is read directly. PDF conversion (if needed) uses a lightweight bash invocation of `pdftotext` (poppler-utils); if not available, the skill advises the operator to install poppler-utils or convert manually.

2. **Path validation before write:** BC-2.03.003 — the incoming path is resolved to an absolute path and compared to the brain vault root (`git rev-parse --show-toplevel`). If the resolved path is outside the vault root, emit block verdict E-INGEST-001 before any file write occurs.

Partial-failure fan-out (BC-2.03.004): the same per-page result envelope used in SS-02 applies here. The lobster-run workflow step for wiki generation returns `{"pages_succeeded": [...], "pages_failed": [...]}`. If any pages fail, the workflow exits 2 and surfaces each failure. This prevents the common "one hook block swallows 14 successful writes" anti-pattern.

## Purity Classification

**Effectful shell.** Filesystem reads (local file) and writes (source + wiki) are effectful. Path validation logic (vault root check) is deterministic (pure) and bats-testable with fixture paths.

## Dependencies

- SS-04 (Hook Chain): PostToolUse hooks on all writes
- SS-05 (Wiki Layer): librarian writes wiki pages
- SS-06 (Source Layer): manifest.json delta
- SS-17 (Event Catalog): structured events

## Test Surface

- `bats/ingest.bats` — positive: local markdown file → source + wiki; negative: path outside vault → E-INGEST-001; edge: path resolves to symlink outside vault → E-INGEST-001; partial failure: one wiki page blocked → fan-out envelope with that failure surfaced
