---
document_type: adr
id: ADR-008
title: "Wiki layer architecture: wikilink resolution, immutability hash, partial-failure fan-out"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-008: Wiki layer architecture

## Context

The wiki layer is the most complex subsystem in brain-factory. It must:
1. Resolve wikilinks at write time (not deferred to read time)
2. Enforce page-type policy (6 valid types: concepts/people/frameworks/syntheses/observations/questions)
3. Validate frontmatter schema on every write
4. Support rename operations that propagate backlinks atomically
5. Handle partial-failure fan-out (one failed page write must not silently swallow others)

## Decision

### Wikilink resolution

`validate-wikilink-integrity.sh` (PostToolUse, matcher: Write|Edit) resolves wikilinks at write time:
1. Extract all `[[slug]]` and `[[slug|display text]]` patterns from the written file using `awk` or `grep -oP`
2. Build a target-set by scanning `wiki/index.md` (the librarian-maintained index) for registered page slugs — O(n) lookup using `grep -F` against the index
3. For each extracted wikilink: if the slug is NOT in the target-set, emit a block verdict (exit 2) with error code `E-WIKI-001`

The index-first pattern (BC-2.05.002) avoids O(n²) cross-product: wiki index loaded once per hook invocation, wikilinks checked against it. At 10K pages, this is O(n) = O(10K) per write, staying within the 100ms p99 budget if `grep -F` is used (binary search on sorted patterns via `grep -F` is very fast on 10K lines).

### Source immutability (ADR-015 detail)

`validate-source-immutability.sh` (PostToolUse, matcher: Write|Edit):
1. Check if the written path matches `sources/` prefix
2. If it does, check if this path already exists in `manifest.json` (using `jq` lookup)
3. If the path is already in manifest.json, emit block verdict (exit 2) with `E-SOURCE-001`
4. If the path is new, allow (exit 0) — the source write is an ingest, not an overwrite

This implements BC-2.06.001 (sources immutable after creation) without hashing. The sha256 hash (ADR-015) is stored in manifest.json as an audit trail and for dispatcher-parity verification, but the block decision is based on path existence, not hash comparison. Hash comparison would require reading the existing file — path existence check is cheaper and sufficient.

### Partial-failure fan-out

Wiki generation during ingest produces 5–15 pages (BC-2.02.002). If one page write fails hook validation, the failure must be surfaced per-page, not silently swallowed. The pattern:

`brain:librarian` (the wiki-generation agent dispatched during ingest) uses a structured result envelope:
```json
{
  "pages_attempted": 7,
  "pages_succeeded": [{"path": "wiki/concepts/zettelkasten.md", "verdict": "allow"}],
  "pages_failed": [{"path": "wiki/concepts/link-rot.md", "verdict": "block", "code": "E-WIKI-001", "message": "..."}]
}
```
This envelope is returned to `bin/lobster-run` (via the generate-wiki workflow step). Lobster exits 2 if `pages_failed` is non-empty, surfacing each failure to the operator. BC-2.03.004 (partial-failure fan-out) is satisfied by this pattern.

### Rename propagation

`/brain:rename-page old-slug new-slug` (skill skill) performs:
1. Verify `wiki/{type}/old-slug.md` exists (BC-2.05.004)
2. Rename the file to `wiki/{type}/new-slug.md`
3. Update `wiki/index.md` to replace old-slug with new-slug
4. Grep all wiki files for `[[old-slug]]` and `[[old-slug|...]]` and rewrite to `[[new-slug]]`
5. Commit atomically (one git commit covering all changed files)
The atomicity guarantee is: either all backlinks are updated and committed, or the rename fails and no changes persist. Implemented as a single git transaction — if any step fails, `git checkout .` rolls back.

## Consequences

**Positive:**
- Wikilink resolution at write time (not deferred) means broken links are caught immediately
- Index-first pattern scales to 10K pages without O(n²) overhead
- Partial-failure envelope gives the operator visibility into which pages succeeded and which failed

**Negative:**
- `wiki/index.md` must be kept up-to-date; if the librarian agent fails to update it, subsequent writes may incorrectly treat valid pages as broken links. `validate-index-log-coherence.sh` guards this invariant.
- Rename propagation requires reading and rewriting potentially many wiki files — acceptable for a rare operation, but not for batch renames

**Neutral:**
- The atomicity of rename propagation is implemented via git commit rather than a filesystem journal; this is appropriate for a git-native brain vault

## References

- BC-2.05.001 (lint-wiki SLA)
- BC-2.05.002 (O(n) index-first lookup)
- BC-2.05.003 (rename propagates backlinks atomically)
- BC-2.05.004 (rename rejects non-existent slug)
- BC-2.03.004 (partial-failure fan-out)
- BC-2.04.003 (validate-wikilink-integrity.sh)
- BC-2.04.006 (validate-index-log-coherence.sh)
- ADR-015 (source immutability hash)
