---
document_type: subsystem-design
id: SS-06
title: "Source Layer and Immutability"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-006
created: 2026-05-15
---

# SS-06: Source Layer and Immutability

## Responsibility

Maintains the immutable source record: `sources/{topic}/{slug}.md` files, manifest.json schema, and the enforcement that once a source is created, it cannot be overwritten without an explicit rename flow.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.06.001 | `sources/{topic}/{slug}.md` immutable after creation | P0 |
| BC-2.06.002 | `manifest.json` schema supports `chunks` array from v0.1 | P1 |
| BC-2.06.003 | `manifest.json` records `last_ingest` timestamps per source | P0 |
| BC-2.06.004 | Sources directory uses 7 default topic categories scaffolded by `/brain:init` | P1 |

## Interfaces

**Inbound:** ingest pipeline writes to `sources/{topic}/{slug}.md`; reads manifest.json

**Outbound:** manifest.json entries (via atomic write); sha256 hash storage; structured events

## Key Design (references ADR-010, ADR-015)

### manifest.json schema (canonical)

```json
{
  "version": "1",
  "sources": {
    "sources/ai/some-article.md": {
      "url": "https://...",
      "local_path": null,
      "ingested_at": "2026-01-01T00:00:00Z",
      "last_ingest": "2026-01-01T00:00:00Z",
      "sha256": "abcdef...",
      "tokens": 12400,
      "wiki_pages": ["wiki/concepts/zettelkasten.md"],
      "chunks": [],
      "topic": "ai"
    }
  },
  "last_updated": "2026-01-15T00:00:00Z"
}
```

The `chunks` array is present from v0.1 (BC-2.06.002) as an empty array. Chunk-level embedding metadata populates it at v0.5+. Forward-compatibility locked from v0.1 to avoid a breaking migration.

### 7 default topic categories (BC-2.06.004)

`/brain:init` creates: `sources/{ai,health,psychology,productivity,business,books,podcasts}/`. These match the phased-build-plan.md §4.1 scaffold. Operators can add custom topic directories (they become valid `--topic` targets for `/brain:ingest-url`).

### Immutability enforcement

Enforced at two levels:
1. **Write-time (PostToolUse):** `validate-source-immutability.sh` checks if the written path exists in manifest.json. If yes → E-SOURCE-001, exit 2.
2. **Audit-time:** `/brain:health` scans sources in the last 30 days and verifies sha256 hashes match manifest.json records. Tampering surfaces as a `HEALTH.sha256_mismatch` advisory.

## Purity Classification

**Mixed.** manifest.json key-existence check is a pure function (given manifest content and a path, return present/absent). The actual manifest read from disk and the atomic write are effectful.

## Dependencies

- SS-04 (Hook Chain): validate-source-immutability.sh enforces immutability at write time
- SS-02, SS-03 (Ingest pipelines): write source files and manifest entries
- SS-16 (Scale): token field in manifest enables cost tracking

## Test Surface

- `bats/hooks.bats` (immutability assertions): existing source path → E-SOURCE-001; new path → exit 0
- `bats/ingest.bats`: manifest.json valid JSON after ingest; `chunks` field present and empty; `last_ingest` populated
