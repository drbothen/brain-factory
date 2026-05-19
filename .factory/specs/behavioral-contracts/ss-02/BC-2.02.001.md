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
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.02.001: `/brain:ingest-url` fetches URL via Defuddle and writes to `sources/{topic}/`

## Description

`/brain:ingest-url <url>` is the primary knowledge-acquisition skill. It fetches the URL using `scripts/defuddle-fetch.mjs` (Defuddle CLI wrapper, ~70-90% token savings over raw HTML), writes the cleaned markdown to `sources/{topic}/{slug}.md`, updates `.brain/manifest.json`, and triggers the wiki-page generation pipeline. The quarantine hook fires before the fetch; the source-immutability hook fires after the write.

## Preconditions

1. The working directory is a valid brain with `.brain/manifest.json` present.
2. Node 20+ is available in PATH (required for `scripts/defuddle-fetch.mjs`).
3. The URL is a valid HTTPS or HTTP URL (scheme check performed first).
4. The URL is not already in `.brain/manifest.json` (duplicate detection — same URL within the same topic).
5. The `quarantine-fetch.sh` hook has already processed the fetched content and exited 0 (allow).

## Postconditions

1. A new file `sources/{topic}/{slug}.md` is created with the Defuddle-cleaned content and source frontmatter: `title`, `url`, `ingested_at` (ISO8601), `source_id` (the slug), `topic`, `embedding_status: pending`.
2. `.brain/manifest.json` is updated with a new entry: `{"source_id": "<slug>", "url": "<url>", "topic": "<topic>", "ingested_at": "<ISO8601>", "last_ingest": "<ISO8601>", "chunks": [], "embeddings_model": null}`.
3. The wiki page generation pipeline is triggered, producing 5–15 cross-referenced wiki pages (see BC-2.02.002).
4. A JSONL token record is written to `.brain/logs/ingest-tokens.jsonl` (see BC-2.02.003).
5. Skill exits 0 with a summary: number of wiki pages created, token cost, elapsed time.

## Invariants

1. Defuddle is invoked via `scripts/defuddle-fetch.mjs` — never raw `curl` or WebFetch on the raw HTML.
2. The source file is written ONCE and is thereafter immutable (enforced by `validate-source-immutability.sh`).
3. The manifest delta is updated on EVERY successful ingest — never on partial failure.
4. If wiki page generation fails for any individual page, the error is propagated per-page (partial-failure fan-out per BC-2.03.004) — the source file write and manifest update still stand.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | URL already in manifest | Exit with E-INGEST-001: "URL already ingested as <slug>. Sources are immutable. Use /brain:ingest-url --force-refresh (v0.5+ only) to re-ingest." v0.1 behavior: block. |
| EC-002 | URL returns non-200 HTTP status | Exit with E-INGEST-002: "HTTP <status> fetching <url>. Ingest aborted." |
| EC-003 | Defuddle returns empty content | Exit with E-INGEST-003: "Defuddle returned empty content for <url>. Page may not be extractable." |
| EC-004 | Source content exceeds 50K-token threshold | Proceed with warning: "Source exceeds 50K-token chunk threshold. Full content ingested in v0.1; chunking available at v0.5+." |
| EC-005 | `quarantine-fetch.sh` returns exit 2 on the fetched content | Skill aborts with E-INGEST-004: "Content quarantined — prompt-injection pattern detected. Ingest aborted." |
| EC-006 | Node 20+ not in PATH | Exit with E-INGEST-005: "Node 20+ required for Defuddle. Install from nodejs.org." |
| EC-007 | Topic not one of the 7 default categories | The skill accepts any topic string and creates the subdirectory if it does not exist. Custom topics are allowed via policy. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `/brain:ingest-url https://example.com/article` (valid, not in manifest) | `sources/ai/example-com-article.md` created; manifest updated; 5+ wiki pages created; token JSONL written; exit 0 | happy-path |
| Same URL a second time | E-INGEST-001; exit 2 | error |
| URL returns 404 | E-INGEST-002; exit 2 | error |
| Quarantine hook blocks fetched content | E-INGEST-004; exit 2 | error |
| Source content > 50K tokens | Source file created; warning emitted; manifest updated; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | Source file created on success | bats integration.bats |
| VP-015 | Manifest updated atomically | bats integration.bats |
| VP-015 | Duplicate URL rejected | bats skills.bats |
| VP-015 | Token JSONL record written on every invocation | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Scope §Phase 0/1 primitives skill #3 (`/brain:ingest-url`). This BC defines the complete contract for URL ingestion — the primary knowledge-acquisition pathway. |
| Architecture Module | SS-02: URL Ingest Pipeline |
| Stories | STORY-016 |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#3); §Scalability Design Principles §1, §5, §7 |

## Related BCs

- BC-2.02.002 — composes with (wiki page generation triggered by this)
- BC-2.02.003 — composes with (token record written by this)
- BC-2.02.004 — depends on (manifest-delta operation)
- BC-2.04.001 — depends on (quarantine fires first)
- BC-2.04.002 — depends on (immutability hook fires after write)
- BC-2.06.001 — depends on (source immutability invariant)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-016 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
