---
document_type: adr
id: ADR-005
title: "Single-tenant power-user architecture; no multi-brain federation"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-005: Single-tenant power-user architecture

## Context

brain-factory targets a knowledge worker who uses one brain (one private second-brain repo) with a single Claude Code session at a time. The scale target for v0.9 is power-user tier: ~10,000 sources, ~40 million words, ~10,000 wiki pages (SL-10). Multi-brain federation (one user, many brains; or team brains with shared state) is explicitly out of scope through v0.x (PRD §1.5 Out of Scope).

Seven architectural disciplines for scale were locked in SL-9 and expanded in the product brief. These disciplines must be reflected in architecture decisions across every subsystem.

## Decision

brain-factory v0.x is a single-tenant architecture: one plugin installation, one brain vault (one `sources/` + `wiki/` + `.brain/` tree), one Claude Code session writing to it at a time. The seven scale disciplines (SL-9) are:

1. **Manifest-delta ingest:** every ingest operation reads only the delta (new sources since last manifest snapshot), not the full corpus. `manifest.json` is the delta ledger. `bin/lobster-run` orchestrates; skills read manifest.json before dispatching wiki writes.
2. **Index-first wiki operations:** all wiki-wide operations (lint, connect, synthesize) build an in-memory index from `wiki/index.md` and `wiki/log.md` before iterating. O(n) scan, not O(n²) cross-product (BC-2.05.002).
3. **Token instrumentation on every ingest:** every `/brain:ingest-url` invocation writes a JSONL record to `.brain/logs/ingest-tokens.jsonl` (BC-2.16.001). Token cost is observable at any scale.
4. **Memory discipline:** peak resident memory for any single operation stays under 2GB on GitHub Actions ubuntu-latest (NFR-005). No full-corpus in-memory load.
5. **Sub-linear latency growth:** ingest latency T(10K sources) / T(1K sources) ≤ 20 (NFR-004). Achieved by manifest delta + index-first patterns.
6. **Parallelism for batch operations:** GH Actions use matrix strategy parallelism for sustained 100-source/day batch ingest (BC-2.16.003, NFR-006).
7. **Chunked source representation:** `manifest.json` schema supports `chunks` array from v0.1 (BC-2.06.002), even though chunk-level embedding is a v0.5+ feature. The schema forward-compatibility is locked from v0.1 to avoid a breaking migration later.

Multi-brain federation (v2.0+), team-brain scale (100K+ sources), and hosted SaaS are explicitly out of scope.

## Consequences

**Positive:**
- Simpler concurrency model: no shared-state coordination across users or brains
- Manifest-delta discipline is a single-writer pattern — no conflict resolution needed
- Scale disciplines are validated at v0.9 with a reproducible synthetic corpus (ADR-012)
- The seven disciplines are individually verifiable (one property test per discipline)

**Negative:**
- Users cannot share wiki pages across brains without manual export (an acceptable tradeoff for v0.x)
- The 2GB memory ceiling constrains future embedding pipelines that load large batches in-process (addressed at v1.0+ with chunked streaming)

**Neutral:**
- The single-tenant model simplifies plugin.json (no multi-brain routing config)

## References

- SL-9 (user lock: "Discipline + measured v0.9 scale test")
- SL-10 (user lock: "Power-user scale — ~10,000 sources / ~40M words / ~10,000 wiki pages")
- PRD §1.5 (out of scope: multi-brain federation, team-brain scale, hosted SaaS)
- NFR-004 (sub-linear latency growth target)
- NFR-005 (peak memory target)
- NFR-006 (sustained batch scale target)
- BC-2.02.004 (manifest delta only — no full-corpus re-reads)
- BC-2.05.002 (O(n) wiki lint)
- BC-2.16.001 through BC-2.16.006 (scale-aware architecture BCs)
- ADR-010 (scale-aware ingest pipeline design)
