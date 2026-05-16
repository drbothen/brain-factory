---
document_type: subsystem-design
id: SS-16
title: "Scale-Aware Architecture"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-016
created: 2026-05-15
---

# SS-16: Scale-Aware Architecture

## Responsibility

Cross-cutting scale discipline: token instrumentation on every ingest, budget alerting, GH Actions batch parallelism, memory budgeting, per-ingest cost bounding, and the `gen-test-corpus.sh` synthetic corpus for v0.9 scale validation.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.16.001 | Token instrumentation: `/brain:ingest-url` writes JSONL record per invocation | P0 |
| BC-2.16.002 | Token budget alert: `/brain:health` warns if 30-day average exceeds 2x baseline | P1 |
| BC-2.16.003 | GH Actions process 100 sources/day sustained over 5-day test run | P1 |
| BC-2.16.004 | Peak resident memory for any single operation < 2GB | P1 |
| BC-2.16.005 | Per-ingest token cost ≤ 3x 50K-token baseline at 10K-source corpus | P1 |
| BC-2.16.006 | `scripts/gen-test-corpus.sh` generates reproducible synthetic corpus | P1 |

## Interfaces

**Inbound:** ingest pipeline writes token records; `gen-test-corpus.sh` is invoked by scale-test workflow; `/brain:health` reads token log

**Outbound:** `.brain/logs/ingest-tokens.jsonl`; `.brain/logs/scale-test-YYYY-MM-DD.jsonl`; budget alert in `/brain:health` output

## Key Design (references ADR-010, ADR-012)

### Token instrumentation (BC-2.16.001)

Every `/brain:ingest-url` and `/brain:ingest-source` invocation appends to `.brain/logs/ingest-tokens.jsonl`:
```json
{"ts":"2026-01-01T00:00:00Z","skill":"ingest-url","url":"https://...","source_path":"sources/ai/article.md","input_tokens":12400,"output_tokens":8200,"wiki_pages_generated":7,"duration_ms":18400}
```
This log is the source-of-truth for NFR-010 (30-day trailing average), NFR-007 (token cost at scale), and BC-2.16.002 (budget alert).

### Budget alert (BC-2.16.002)

`/brain:health` reads the last 30 days of ingest-tokens.jsonl, computes the average `input_tokens + output_tokens` per ingest, and warns (advisory, exit 1) if the 30-day average exceeds 2x the baseline (100K tokens; 2x = 200K). This gives the operator visibility before cost becomes a problem.

### GH Actions batch parallelism (BC-2.16.003)

`ingest-rss.yml` processes RSS feed items in a GitHub Actions matrix strategy: each feed runs as a parallel job. The scale test (`scale-test.yml`) validates 100 sources/day sustained over 5 days using `gen-test-corpus.sh`.

### Memory budget (BC-2.16.004)

Peak resident memory monitored via `/usr/bin/time -v` in the scale test workflow. The measurement is captured for the ingest workflow step and written to `.brain/logs/scale-test-YYYY-MM-DD.jsonl`. Alert threshold: 2GB.

### gen-test-corpus.sh (BC-2.16.006)

See ADR-012 for full design. Produces a reproducible synthetic brain vault tree with valid frontmatter, manifest.json, and cross-referenced wikilinks.

## Purity Classification

**Mixed.** Token log aggregation (given a JSONL file, compute average) is a pure computation. File writes and GH Actions execution are effectful.

## Dependencies

- SS-02 (URL Ingest): writes token JSONL records
- SS-03 (Source Ingest): writes token JSONL records
- SS-01 (Brain Init): `/brain:health` is the health skill (BC-2.01.006 overlap — health reports include scale metrics)

## Test Surface

- `bats/integration.bats` — token JSONL valid JSON after ingest; budget alert fires at 2x threshold; gen-test-corpus.sh produces deterministic output
- NFR-004 scale test via scale-test.yml; NFR-005 memory via `/usr/bin/time -v`
