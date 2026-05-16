---
document_type: subsystem-design
id: SS-06
title: "Source Layer and Immutability"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-16T00:00:00
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

- `tests/hooks.bats` (immutability assertions): existing source path → E-SOURCE-001; new path → exit 0
- `tests/skills.bats`: manifest.json valid JSON after ingest; `chunks` field present and empty; `last_ingest` populated (covered by VP-012 Group 2)

## Changelog

### v1.1 (2026-05-16)

**STRUCTURAL FIX (F-PASS2-I4 sibling-sweep — test path alignment):** Test Surface updated from deprecated `bats/`-prefixed path to canonical `tests/` form per brief §Test architecture (Source-of-Truth Precedence + brain-factory-001). Functional coverage unchanged. Closes the sibling-sweep portion of F-PASS2-I4 as recorded in ARCH-INDEX v0.1.3. [audit-trail]

**STRUCTURAL FIX (F-PASS4-C2 — canonical test path sweep):** Remaining `bats/`-prefixed path references replaced with canonical `tests/` form per the sweep-by-canonical-pattern discipline established in ARCH-INDEX v0.1.5. [audit-trail]

**RETROACTIVE CLASSIFICATION (F-PASS12-I2 — SS-NN Changelog discipline):** This file had content edits past initial creation but remained at v1.0 without a Changelog section, escaping the Pass 9 / Pass 10-I2 discipline. Bumped to v1.1 with Changelog added per F-PASS12-I2 resolution. [audit-trail]

### v1.0 (2026-05-15)

Original Phase 1c subsystem design — source layer immutability, sha256 hash algorithm,
manifest.json schema, E-SOURCE-001 block on write-to-existing-path.
