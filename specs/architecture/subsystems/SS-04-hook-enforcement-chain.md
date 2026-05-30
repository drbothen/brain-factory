---
document_type: subsystem-design
id: SS-04
title: "Hook Enforcement Chain"
level: L3
version: "1.3"
producer: "vsdd-factory:architect"
timestamp: 2026-05-18T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-004
created: 2026-05-15
---

# SS-04: Hook Enforcement Chain

## Responsibility

The core governance infrastructure: 13 bash hook scripts registered in hooks.json that fire at tool events (PreToolUse, PostToolUse, SessionStart, Stop). Each hook implements the canonical contract: JSON stdin → JSON verdict stdout → JSONL events stderr → exit 0/1/2.

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

**Inbound:** Claude Code harness delivers stdin JSON per Universal Hook Input Schema (interface-definitions.md §2); fields: `tool_name`, `tool_input`, `tool_result`

**Outbound:** stdout JSON verdict `{"continue":true|false,"decision":"block","reason":"...","hookSpecificOutput":{...}}`; advisory = exit 0 + systemMessage; stderr JSONL events; exit code 0/2 (exit 1 = debug log only, NOT advisory)

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

- `tests/<hook-name>.bats` — one per-hook bats file per hook script; each file covers that hook with ≥ 3 test cases (positive + negative + edge) per NFR-020 and CLAUDE.md TDD Inner Loop Discipline
- NFR-001 perf assertion: `time <hook> < fixture.json` → assert under 100ms
- NFR-016 fail-closed: inject malformed stdin → assert exit 2

## Scale Considerations

PostToolUse hooks fire on every Write/Edit. At 10K page ingest, this means 10K+ hook invocations. Hooks must be fast (NFR-001: 100ms p99). The O(n) wikilink resolution (grep -F on wiki/index.md) is the bottleneck; profiled and optimized in Phase 3 if needed.

## Changelog

### v1.3 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** §Responsibility updated `hooks.json.template` → `hooks.json` (filename rename per ADR-003 v2.0). §Interfaces Inbound updated to cite `tool_name`, `tool_input`, `tool_result` field names; Outbound updated to the new verdict envelope `{"continue":...,"decision":"block","reason":"...","hookSpecificOutput":{...}}` and clarified exit 1 semantics (debug log only; advisory = exit 0 + systemMessage). [audit-trail]

### v1.2 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE — §Test Surface updated to per-hook .bats convention):** §Test Surface entry "tests/hooks.bats — covers all 13 hooks... per NFR-019 this is the single bats file for hook tests in the 9-suite roster" replaced with "tests/<hook-name>.bats — one per-hook bats file per hook script... per NFR-020 and CLAUDE.md TDD Inner Loop Discipline." Cascades from SS-18 v1.5 per-hook .bats convention reversal (F-PHASE2-STEP-B-CLOSEOUT-O1). [audit-trail]

### v1.1 (2026-05-16)

**STRUCTURAL FIX (F-PASS1-C4 — shared helpers enumeration):** Interfaces section updated to enumerate all four `hooks/lib/` helpers correctly: `hook-event-emit.sh`, `api-retry.sh`, `manifest-write.sh` (all ADR-016), and `sha256.sh` (ADR-015, not ADR-016). Previous listing omitted `api-retry.sh` and misattributed `sha256.sh` to ADR-016. Closes F-PASS1-C4 as recorded in ARCH-INDEX v0.1.2. [audit-trail]

**STRUCTURAL FIX (F-PASS1-I12 — test surface wording):** Test Surface updated: deprecated `bats/hooks.bats` path replaced with `tests/hooks.bats` form, and wording clarified to remove the implication that hooks.bats is subdivided into 9 internal suites; all 13 hooks share `tests/hooks.bats` per NFR-019. Closes F-PASS1-I12 as recorded in ARCH-INDEX v0.1.2. [audit-trail]

**STRUCTURAL FIX (F-PASS4-C2 — canonical test path sweep):** Remaining `bats/`-prefixed path references replaced with canonical `tests/` form per the sweep-by-canonical-pattern discipline established in ARCH-INDEX v0.1.5. [audit-trail]

**RETROACTIVE CLASSIFICATION (F-PASS12-I2 — SS-NN Changelog discipline):** This file had content edits past initial creation but remained at v1.0 without a Changelog section, escaping the Pass 9 / Pass 10-I2 discipline. Bumped to v1.1 with Changelog added per F-PASS12-I2 resolution. [audit-trail]

### v1.0 (2026-05-15)

Original Phase 1c subsystem design — hook enforcement chain, 13 hook scripts, shared
helpers in hooks/lib/, exit-code contract (0/1/2), JSON I/O protocol.
