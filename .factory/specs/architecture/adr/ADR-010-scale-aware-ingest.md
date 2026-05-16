---
document_type: adr
id: ADR-010
title: "Scale-aware ingest pipeline: manifest-delta only; sub-linear latency growth"
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

# ADR-010: Scale-aware ingest pipeline

## Context

The ingest pipeline (`/brain:ingest-url`, `/brain:ingest-source`) must remain fast as the brain grows. Without architectural discipline, ingest latency grows linearly or super-linearly with wiki size because the LLM agent re-reads the full corpus to understand "what already exists" before generating new wiki pages. At 10K pages, a full-corpus re-read would exhaust context budget and take minutes.

NFR-004 requires sub-linear latency growth: T(10K) / T(1K) ≤ 20. This is achievable only if the ingest pipeline reads a bounded, pre-indexed summary rather than the full corpus.

## Decision

### Manifest-delta ingest

`manifest.json` is the single source of truth for what has been ingested. Its structure:
```json
{
  "version": "1",
  "sources": {
    "sources/ai/some-article.md": {
      "url": "https://...",
      "ingested_at": "2026-01-01T00:00:00Z",
      "sha256": "abcdef...",
      "tokens": 12400,
      "wiki_pages": ["wiki/concepts/zettelkasten.md"],
      "chunks": []
    }
  },
  "last_updated": "2026-01-15T00:00:00Z"
}
```

On every ingest invocation, the skill reads manifest.json (a small JSON file, even at 10K sources) and checks if the incoming URL or path is already present. If present: reject with `E-INGEST-001` (already ingested). If absent: proceed with ingest, write the source file, generate wiki pages, append the manifest entry, and commit.

The skill never reads the wiki corpus or source files to determine "what already exists." manifest.json is the O(1) lookup (jq key lookup) for existence checking.

### Wiki generation: brain:librarian context bound

`brain:librarian` (the agent dispatched to generate 5–15 wiki pages during ingest) receives:
- The new source content (the article text, bounded by the 50K-token chunk threshold per BC-2.02.005)
- `wiki/index.md` (the index of existing wiki pages — a bounded summary, not the full corpus)
- `wiki/log.md` (recent additions — last N entries, bounded)

The librarian does NOT receive the full wiki corpus. It uses `wiki/index.md` to understand what already exists (to generate cross-references) without reading every wiki page. At 10K pages, `wiki/index.md` is the summary index — expected size ~500KB, well within context budget.

### Token instrumentation per ingest

Every `/brain:ingest-url` invocation appends a JSONL record to `.brain/logs/ingest-tokens.jsonl` (BC-2.16.001):
```json
{"ts": "...", "url": "...", "source_path": "...", "input_tokens": 12400, "output_tokens": 8200, "wiki_pages_generated": 7, "duration_ms": 18400}
```
This enables the 30-day trailing average computation (BC-2.16.002, NFR-010) and the scale test validation (NFR-007).

### Manifest write atomicity

manifest.json write uses the tmp-file + mv pattern (NFR-018):
1. Write to `/tmp/brain-manifest-XXXXXX.json` (atomic mktemp)
2. `mv /tmp/brain-manifest-XXXXXX.json manifest.json` (atomic on POSIX systems)

If the write fails between mktemp and mv, the original manifest.json is unchanged. `validate-index-log-coherence.sh` verifies that manifest.json remains consistent with the source filesystem state (BC-2.04.006).

### Scale validation

`scripts/gen-test-corpus.sh` (ADR-012) generates a reproducible synthetic corpus for scale testing. The scale test workflow (`workflows/scale-test.yaml`) uses it to validate NFR-004 (sub-linear latency), NFR-005 (memory), NFR-006 (sustained batch), and NFR-007 (token cost at scale).

## Consequences

**Positive:**
- manifest.json is the single O(1) lookup for ingest history — scales to 10K sources without degradation
- Librarian context bound (index + log, not full corpus) keeps LLM context consumption bounded
- Token instrumentation enables proactive token budget alerts before the operator notices cost growth

**Negative:**
- manifest.json must be atomically updated on every successful ingest; any failure in the mv step leaves the source file written but manifest not updated. Recovery: `/brain:health` surfaces manifest/filesystem inconsistencies; `validate-index-log-coherence.sh` catches at the next write.
- `wiki/index.md` must accurately reflect all wiki pages — librarian failures that skip index updates would cause duplicate page generation on subsequent ingests. Protected by `validate-index-log-coherence.sh`.

**Neutral:**
- The 50K-token chunk threshold (BC-2.02.005) is a warning, not a hard block — very long sources can be ingested, but they're flagged for operator awareness

## References

- NFR-004 (sub-linear latency growth)
- NFR-005 (peak memory < 2GB)
- NFR-006 (sustained batch: 100 sources/day)
- NFR-007 (token cost at 10K corpus)
- NFR-018 (manifest atomicity)
- BC-2.02.004 (manifest delta only)
- BC-2.02.005 (50K-token chunk threshold warning)
- BC-2.16.001 (token instrumentation JSONL)
- BC-2.16.005 (per-ingest cost ≤ 3x baseline at 10K corpus)
- ADR-005 (single-tenant scale disciplines)
- ADR-012 (gen-test-corpus.sh)
