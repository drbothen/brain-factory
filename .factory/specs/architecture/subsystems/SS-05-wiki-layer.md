---
document_type: subsystem-design
id: SS-05
title: "Wiki Layer and Wikilink Integrity"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-005
created: 2026-05-15
---

# SS-05: Wiki Layer and Wikilink Integrity

## Responsibility

Maintains the LLM-owned knowledge graph. Enforces the 6 wiki page types, validates wikilinks at write time (index-first lookup), supports atomic rename propagation, and runs the 7-check wiki health pass within a 10-minute SLA at 10K pages.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.05.001 | `/brain:lint-wiki` completes 7-check health pass under 10 minutes on 10K pages | P0 |
| BC-2.05.002 | `/brain:lint-wiki` uses index-first lookup (O(n), not O(n²)) | P0 |
| BC-2.05.003 | `/brain:rename-page` renames wiki page and propagates backlinks atomically | P0 |
| BC-2.05.004 | `/brain:rename-page` rejects rename if old slug does not exist | P0 |
| BC-2.05.005 | Wiki pages use `wiki/{type}/{slug}.md` (6 valid types) | P0 |
| BC-2.05.006 | `embedding_status` field mandatory in all wiki page frontmatter from v0.1 | P0 |

## Interfaces

**Inbound:** `/brain:lint-wiki` (no args); `/brain:rename-page <old-slug> <new-slug>`; wiki writes from librarian agent; PostToolUse hook payload

**Outbound:** lint report (JSON + human-readable summary); renamed file + updated backlinks + atomic git commit; hook block verdict on broken wikilinks

## Key Design (references ADR-008)

### 7-check lint suite

`/brain:lint-wiki` runs these 7 checks:
1. Broken wikilinks (all `[[slug]]` references resolve to existing wiki pages)
2. Orphaned pages (wiki pages not referenced by any other page or by wiki/index.md)
3. Missing `embedding_status` field (scans frontmatter)
4. Invalid page type directories (only 6 types allowed)
5. Non-kebab-case filenames in wiki/
6. Missing source citations (wiki pages citing source IDs not in manifest.json)
7. Index/log coherence (wiki/index.md lists all pages; wiki/log.md has all generation events)

Each check uses index-first pattern: build a sorted/indexed set once, then O(n) membership checks. Total complexity: O(n) per check, O(7n) overall = O(n).

### Wikilink resolution (pure core boundary)

The wikilink resolution algorithm (is this `[[slug]]` in the wiki index?) is a pure function:
- Input: wiki/index.md contents (line-delimited slug list), wikilink string
- Output: present/absent boolean
- Implemented as `grep -qF "slug" wiki-index.txt`
- Bats-testable with fixture wiki/index.md and fixture wikilink strings

### Rename atomicity

`/brain:rename-page` uses a single git transaction:
```bash
git mv "wiki/{type}/old-slug.md" "wiki/{type}/new-slug.md"
sed -i "s/\[\[old-slug\]\]/[[new-slug]]/g" wiki/**/*.md  # backlink propagation
git add -A
git commit -m "rename: old-slug → new-slug"
```
If any step fails, `git checkout .` is called before reporting failure (no partial state).

## Purity Classification

**Mixed.** The wikilink resolution check is pure (index lookup). The lint execution, file enumeration, and rename propagation are effectful. The pure core is isolated in `hooks/lib/wikilink-resolve.sh` and tested independently.

## Dependencies

- SS-04 (Hook Chain): validate-wikilink-integrity.sh (write-time wikilink check)
- SS-06 (Source Layer): validate-source-id-citation.sh cross-checks against manifest.json
- SS-17 (Event Catalog): lint events emitted

## Test Surface

- `bats/wiki.bats` — lint all 7 checks; rename positive + negative + edge; wikilink resolution with fixture index
- Scale test: lint 10K-page synthetic corpus under 600s (NFR-003)
