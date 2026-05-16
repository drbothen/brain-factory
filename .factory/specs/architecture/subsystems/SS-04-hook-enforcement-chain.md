---
document_type: subsystem-design
id: SS-04
title: "Hook Enforcement Chain"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-004
created: 2026-05-15
---

# SS-04: Hook Enforcement Chain

## Responsibility

The core governance infrastructure: 13 bash hook scripts registered in hooks.json.template that fire at tool events (PreToolUse, PostToolUse, SessionStart, Stop). Each hook implements the canonical contract: JSON stdin → JSON verdict stdout → JSONL events stderr → exit 0/1/2.

## BC Inventory

| BC ID | Hook / Property | Exit | Priority |
|-------|----------------|------|----------|
| BC-2.04.001 | quarantine-fetch.sh blocks prompt-injection | 2 | P0 |
| BC-2.04.002 | validate-source-immutability.sh blocks overwrite | 2 | P0 |
| BC-2.04.003 | validate-wikilink-integrity.sh blocks broken links | 2 | P0 |
| BC-2.04.004 | validate-frontmatter-schema.sh blocks missing embedding_status | 2 | P0 |
| BC-2.04.005 | validate-frontmatter-schema.sh blocks other missing fields | 2 | P0 |
| BC-2.04.006 | validate-index-log-coherence.sh blocks coherence violations | 2 | P0 |
| BC-2.04.007 | validate-page-type-policy.sh blocks invalid wiki type dirs | 2 | P0 |
| BC-2.04.008 | validate-voice-avoid-list.sh advises on avoid-list terms | 1 | P1 |
| BC-2.04.009 | validate-source-id-citation.sh blocks unresolved citations | 2 | P0 |
| BC-2.04.010 | validate-publish-state.sh blocks invalid state transitions | 2 | P0 |
| BC-2.04.011 | enforce-kebab-case.sh blocks non-kebab filenames | 2 | P0 |
| BC-2.04.012 | block-ai-attribution.sh blocks AI attribution tokens | 2 | P0 |
| BC-2.04.013 | flush-state-and-commit.sh commits brain state on Stop | 0/1 | P1 |
| BC-2.04.014 | brain-health-check.sh reports convergence on SessionStart | 0/1 | P1 |
| BC-2.04.015 | Every hook processes payload under 100ms p99 | — | P0 |
| BC-2.04.016 | Every hook: JSON stdin → JSON stdout → exit 0/1/2 | — | P0 |
| BC-2.04.017 | Every hook emits JSONL events on stderr via event catalog | — | P0 |

## Hook Registration Matrix

| Tool Event | Matcher | Hooks |
|-----------|---------|-------|
| SessionStart | (all) | brain-health-check.sh |
| PreToolUse | WebFetch | quarantine-fetch.sh |
| PreToolUse | Write\|Edit | enforce-kebab-case.sh |
| PreToolUse | Bash | block-ai-attribution.sh |
| PostToolUse | Write\|Edit | validate-source-immutability.sh, validate-wikilink-integrity.sh, validate-index-log-coherence.sh, validate-frontmatter-schema.sh, validate-page-type-policy.sh, validate-voice-avoid-list.sh, validate-source-id-citation.sh, validate-publish-state.sh |
| Stop | (all) | flush-state-and-commit.sh |

## Interfaces

**Inbound:** Claude Code harness delivers stdin JSON per Universal Hook Input Schema (interface-definitions.md §2)

**Outbound:** stdout JSON verdict; stderr JSONL events; exit code 0/1/2

**Shared helpers (four files):**
- `hooks/lib/hook-event-emit.sh` (ADR-016 — event emission + verdict)
- `hooks/lib/api-retry.sh` (ADR-016 — exponential backoff for external API calls)
- `hooks/lib/manifest-write.sh` (ADR-016 — atomic manifest.json writes)
- `hooks/lib/sha256.sh` (ADR-015 — portable sha256 shim; NOT an ADR-016 helper)

## Purity Classification

**Mixed.** The decision logic within each hook (pattern matching, schema validation, path checking) is pure and bats-testable with fixture payloads. The I/O operations (reading manifest.json, reading wiki/index.md for wikilink resolution) are effectful. The canonical bats test pattern feeds a complete stdin fixture and asserts on stdout JSON and exit code, isolating the pure decision logic.

## Dependencies

- SS-17 (Event Catalog): all hooks emit events registered in the catalog (BC-2.04.017)
- SS-06 (Source Layer): validate-source-immutability.sh reads manifest.json
- SS-05 (Wiki Layer): validate-wikilink-integrity.sh reads wiki/index.md
- SS-10 (Quarantine): quarantine-fetch.sh uses scripts/quarantine.mjs pattern corpus

## Test Surface

- `tests/hooks.bats` — covers all 13 hooks with ≥ 3 test cases per hook (positive + negative + edge); per NFR-019 this is the single bats file for hook tests in the 9-suite roster
- NFR-001 perf assertion: `time <hook> < fixture.json` → assert under 100ms
- NFR-016 fail-closed: inject malformed stdin → assert exit 2

## Scale Considerations

PostToolUse hooks fire on every Write/Edit. At 10K page ingest, this means 10K+ hook invocations. Hooks must be fast (NFR-001: 100ms p99). The O(n) wikilink resolution (grep -F on wiki/index.md) is the bottleneck; profiled and optimized in Phase 3 if needed.
