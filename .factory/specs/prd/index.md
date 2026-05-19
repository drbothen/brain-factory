---
document_type: prd
level: L3
version: "0.1.13"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-19T00:00:00
phase: phase-1b
artifact_type: prd
inherits_from: product-brief.md@v0.4.20
created: 2026-05-15
last_updated: 2026-05-19
traces_to: product-brief.md
supplements:
  - prd-supplements/interface-definitions.md
  - prd-supplements/error-taxonomy.md
  - prd-supplements/test-vectors.md
  - prd-supplements/nfr-catalog.md
---

# Product Requirements Document: brain-factory

> **BC Index Model:** This PRD is an index document. Each Behavioral Contract (BC)
> lives in its own file under `../behavioral-contracts/ss-NN/`. The tables in
> Section 2 provide one-line summaries with priority. Full contracts are linked
> per subsystem.
>
> **PRD Supplement Model:** Sections 3–5b are extracted to separate files under
> `prd-supplements/`. The core PRD retains summary references only. Each supplement
> is consumed by a different downstream agent.
>
> **Phase 1a disciplines apply.** Writing-technique principle: never quote literal
> line-number tokens. Self-Audit Checklist gate covers brief + handoff + this file.
> No blanket-coverage wording. Scoped-equivalents only.

## 1. Product Overview

### 1.1 Problem Statement

A knowledge worker who understands the Karpathy LLM-wiki methodology can execute it manually — but manual execution requires maintaining CLAUDE.md discipline themselves, trusting ad-hoc slash-command bodies stay consistent across sessions, manually enforcing immutability rules and wikilink hygiene, and reproducing the same scaffold for every new brain. When the methodology upgrades, they must edit every brain they own. The four documented failure modes (capture friction, no connection layer, no return path, maintenance debt) each kill the vault before it compounds.

The plugin eliminates this burden by centralizing the methodology as versioned artifacts and moving enforcement from agent-readable rules — which an agent can violate — to hook-level enforcement. The PreToolUse hook on WebFetch is invoked by the Claude Code harness, not by the agent. The agent cannot bypass it. This is what makes plugin enforcement strictly stronger than markdown rules.

### 1.2 Solution Vision

`brain-factory` is a versioned, distributable Claude Code plugin that packages an LLM-maintained second-brain methodology into a deployable artifact with hook-enforced discipline. It applies the `vsdd-factory` engine/target split: one stateless, read-only plugin installed once powers any number of private user brains, with enforcement at the tool-event level. In v0.x (through v0.9) brain-factory ships 26 skills, 14 specialist agents, 13 bash hooks, 19 GitHub Action templates (15 author-committed + 4 community-optional opt-in), and a minimal Lobster runtime sufficient to scaffold a functional brain in under 5 minutes via `/brain:init`, ingest a URL into 5+ cross-referenced wiki pages, and produce adversary-reviewed daily briefs and publishable content.

### 1.3 Key Differentiators

| ID | Differentiator | Description |
|----|---------------|-------------|
| KD-001 | Hook-enforced governance | Quarantine, source-immutability, wikilink-integrity, frontmatter-schema enforced at tool-event level — agent cannot bypass. Exit-code 2 blocks; exit-code 1 advises. |
| KD-002 | Cognitive-diversity adversarial review | Every brief, synthesis, and published piece passes a fresh-context different-model adversary (Opus producer + Sonnet adversary by default). |
| KD-003 | Dispatcher-ready architecture | v0.x bash hooks; v1.0 migrates to WASM via shared factory-dispatcher with parity tests (`diff_count = 0` across payload corpus). |
| KD-004 | Scale-aware architecture from v0.1 | Targets 10x Karpathy scale (~10K sources / ~40M words / ~10K wiki pages) as v0.9 tested SLA, not aspiration. Seven architectural disciplines locked from v0.1. |

### 1.4 Target Users

| Persona | Description | Volume | Pain Level |
|---------|-------------|--------|------------|
| Plugin operator (Phase 0–2) | Josh Magady, single-author dogfood | 1 | High (no existing tooling at plugin tier) |
| Plugin operator (Phase 3) | 3–5 invited pilots: CLI-comfortable, active writers, using Obsidian/Logseq/Notion | 3–5 | High |
| Plugin operator (general) | Knowledge workers comfortable on CLI, with Claude Code + git + Node 20+ | Small/growing | High |
| Methodology end-user | Knowledge worker reading 5–20 substantive pieces/week whose vault dies at 6 months | Overlaps with operator in v0.x | Very high |

### 1.5 Out of Scope

> Machine-consumed: no story AC may implement features listed here.

- WASM hooks via factory-dispatcher (Phase 4 / v1.0 only)
- factory-dispatcher repo creation (upstream prerequisite)
- Observability sinks beyond file logs (OTEL-gRPC, DataDog, Honeycomb — v1.0+)
- Native Windows support (Git Bash or WSL2 required in v0.x; Windows-native = v1.0)
- 4 community-optional GH Action templates as author-maintained features (telegram-bridge, email-inbox, cross-repo-dispatch, garden-publish ship in tarball but carry no author support)
- Medium API as a core v0.x channel (ships as reference extension only — best-effort, deprecated API)
- Multi-brain federation (v2.0+, separate roadmap)
- Team-brain scale (100K+ sources / federated brains — v2.0+)
- Hosted SaaS (local-only; not on roadmap)
- Email, correspondence, song content types as `/brain:publish-content` targets (v0.5+ deferred)
- PowerShell ports of bash hooks (throwaway code once Phase 4 lands)
- Worktree-mounted `.brain/` state (optional advanced; not committed in v0.x)

---

## 2. Behavioral Contracts Index

> Behavioral contracts are sharded under `.factory/specs/behavioral-contracts/ss-NN/BC-S.SS.NNN.md`. Phase 1c architecture COMPLETED at commit b7679ee + subsequent fix-bursts; all 95 BCs now carry canonical `subsystem: SS-NN` labels per the ARCH-INDEX Subsystem Registry. CAP-NNN capability anchors are defined below and referenced verbatim in each BC file.

### 2.1 Brain Initialization and Scaffold (CAP-001)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.01.001 | `/brain:init` scaffolds complete brain folder structure in a fresh directory | P0 |
| BC-2.01.002 | `/brain:init` completes end-to-end in under 5 minutes (tested SLA) | P0 |
| BC-2.01.003 | `/brain:init` rejects non-git-repo target directory with E-INIT-001 | P0 |
| BC-2.01.004 | `/brain:init` writes `embedding_status: pending` in every wiki page template | P0 |
| BC-2.01.005 | `/brain:init` scaffolds `briefs/research/` subdirectory | P1 |
| BC-2.01.006 | `/brain:health` reports six-dimensional convergence state in structured JSON | P1 |

> Full contracts: `../behavioral-contracts/ss-01/`

### 2.2 URL Ingest Pipeline (CAP-002)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.02.001 | `/brain:ingest-url` fetches URL via Defuddle and writes to `sources/{topic}/` | P0 |
| BC-2.02.002 | `/brain:ingest-url` produces 5–15 cross-referenced wiki pages per ingest | P0 |
| BC-2.02.003 | `/brain:ingest-url` writes JSONL token record to `.brain/logs/ingest-tokens.jsonl` | P0 |
| BC-2.02.004 | `/brain:ingest-url` operates on manifest delta only (no full-corpus re-reads) | P0 |
| BC-2.02.005 | `/brain:ingest-url` warns when source exceeds 50K-token chunk threshold | P1 |
| BC-2.02.006 | `/brain:ingest-url` rejects already-ingested URL (source-immutability guard) | P0 |
| BC-2.02.007 | `/brain:ingest-url` latency stays sub-linear as wiki grows 1K→10K pages | P1 |

> Full contracts: `../behavioral-contracts/ss-02/`

### 2.3 Source Ingest Pipeline (CAP-003)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.03.001 | `/brain:ingest-source` ingests a local file into `sources/{topic}/` and wiki layer | P0 |
| BC-2.03.002 | `/brain:ingest-source` writes manifest delta entry on every successful ingest | P0 |
| BC-2.03.003 | `/brain:ingest-source` rejects paths outside the brain vault root | P0 |
| BC-2.03.004 | `/brain:ingest-source` propagates partial-failure fan-out (per-page results; no silent swallow) | P0 |

> Full contracts: `../behavioral-contracts/ss-03/`

### 2.4 Hook Enforcement Chain (CAP-004)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.001 | `quarantine-fetch.sh` blocks web content containing prompt-injection patterns (exit 2) | P0 |
| BC-2.04.002 | `validate-source-immutability.sh` blocks overwrite of existing source records (exit 2) | P0 |
| BC-2.04.003 | `validate-wikilink-integrity.sh` blocks wiki writes with broken wikilinks (exit 2) | P0 |
| BC-2.04.004 | `validate-frontmatter-schema.sh` blocks wiki writes missing `embedding_status` field (exit 2) | P0 |
| BC-2.04.005 | `validate-frontmatter-schema.sh` blocks wiki writes missing other mandatory fields (exit 2) | P0 |
| BC-2.04.006 | `validate-index-log-coherence.sh` blocks index/log writes that break coherence invariant (exit 2) | P0 |
| BC-2.04.007 | `validate-page-type-policy.sh` blocks wiki writes to invalid wiki type directories (exit 2) | P0 |
| BC-2.04.008 | `validate-voice-avoid-list.sh` advises on brief drafts containing voice-avoid-list terms (exit 1) | P1 |
| BC-2.04.009 | `validate-source-id-citation.sh` blocks wiki writes with unresolved source citations (exit 2) | P0 |
| BC-2.04.010 | `validate-publish-state.sh` blocks invalid frontmatter state-machine transitions (exit 2) | P0 |
| BC-2.04.011 | `enforce-kebab-case.sh` blocks file writes with non-kebab-case filenames (exit 2) | P0 |
| BC-2.04.012 | `block-ai-attribution.sh` blocks bash commands containing AI attribution tokens (exit 2) | P0 |
| BC-2.04.013 | `flush-state-and-commit.sh` commits brain state on session Stop (exit 0 or advisory) | P1 |
| BC-2.04.014 | `brain-health-check.sh` surfaces six-dimensional convergence state on SessionStart (exit 0 or 1) | P1 |
| BC-2.04.015 | Every hook processes its sample payload under 100ms p99 (performance budget) | P0 |
| BC-2.04.016 | Every hook reads JSON from stdin, writes JSON verdict to stdout, exits 0/1/2 only | P0 |
| BC-2.04.017 | Hook structured event emission: every hook emits JSONL events on stderr via hook-event catalog | P0 |

> Full contracts: `../behavioral-contracts/ss-04/`

### 2.5 Wiki Layer and Wikilink Integrity (CAP-005)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.05.001 | `/brain:lint-wiki` completes seven-check health pass in under 10 minutes on 10K-page wiki | P0 |
| BC-2.05.002 | `/brain:lint-wiki` uses index-first lookup (O(n) scan, not O(n²) cross-product) | P0 |
| BC-2.05.003 | `/brain:rename-page` renames wiki page and propagates all backlinks atomically | P0 |
| BC-2.05.004 | `/brain:rename-page` rejects rename if old slug does not exist | P0 |
| BC-2.05.005 | Wiki pages use `wiki/{type}/{slug}.md` path (6 types: concepts/people/frameworks/syntheses/observations/questions) | P0 |
| BC-2.05.006 | `embedding_status` field is mandatory in all wiki page frontmatter from v0.1 | P0 |

> Full contracts: `../behavioral-contracts/ss-05/`

### 2.6 Source Layer and Immutability (CAP-006)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.06.001 | `sources/{topic}/{slug}.md` is immutable after creation (no overwrite without explicit rename flow) | P0 |
| BC-2.06.002 | `manifest.json` schema supports `chunks` array from v0.1 (populated at v0.5+) | P1 |
| BC-2.06.003 | `manifest.json` records `last_ingest` timestamps per source | P0 |
| BC-2.06.004 | Sources directory uses 7 default topic categories scaffolded by `/brain:init` | P1 |

> Full contracts: `../behavioral-contracts/ss-06/`

### 2.7 Adversarial Review and Writescore (CAP-007)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.07.001 | `/brain:adversary-review` runs in a different model family than the producer agent | P0 |
| BC-2.07.002 | `/brain:adversary-review` dispatches all four wclaude validation agents | P0 |
| BC-2.07.003 | `/brain:adversary-review` implements multi-pass writescore revision loop | P1 |
| BC-2.07.004 | `/brain:adversary-review` returns structured pass/fail verdict with finding list | P0 |

> Full contracts: `../behavioral-contracts/ss-07/`

### 2.8 Content Brief and Writing (CAP-008)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.08.001 | `/brain:brief` generates a content brief in ONE THING / PROOF / TRANSFORMATION format | P0 |
| BC-2.08.002 | `/brain:write` produces a full piece in the author's voice from a brief path | P0 |
| BC-2.08.003 | `/brain:write` supports `--companion-posts`, `--hero-prompt` flags | P1 |
| BC-2.08.004 | Voice avoid-list (30 entries in `rules/voice-avoid-list.txt`) is enforced on brief drafts | P1 |

> Full contracts: `../behavioral-contracts/ss-08/`

### 2.9 Publishing Pipeline (CAP-009)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.09.001 | `/brain:publish-content` posts to LinkedIn via Posts API (Community Management) | P0 |
| BC-2.09.002 | `/brain:publish-content` supports `--finalize --url "..."` for LinkedIn articles manual flow | P1 |
| BC-2.09.003 | `/brain:publish-content` supports `--schedule <date>` flag | P1 |
| BC-2.09.004 | Frontmatter state machine enforces `draft → ready → published` transitions | P0 |
| BC-2.09.005 | `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` directory structure is maintained | P0 |
| BC-2.09.006 | `/brain:monthly-perf` pulls performance data from LinkedIn Posts API and reports to `.brain/logs/` | P1 |

> Full contracts: `../behavioral-contracts/ss-09/`

### 2.10 Prompt-Injection Quarantine (CAP-010)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.10.001 | `/brain:quarantine-check` scrubs prompt-injection patterns before content reaches tool-access session | P0 |
| BC-2.10.002 | `quarantine-fetch.sh` fires on EVERY WebFetch call — cannot be bypassed by any skill | P0 |
| BC-2.10.003 | Quarantine corpus patterns live in `scripts/quarantine.mjs` | P0 |

> Full contracts: `../behavioral-contracts/ss-10/`

### 2.11 Knowledge Synthesis and Connection (CAP-011)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.11.001 | `/brain:connect [days]` finds cross-domain connections across recent ingests | P1 |
| BC-2.11.002 | `/brain:synthesize` builds a weekly thesis from the connection layer | P1 |
| BC-2.11.003 | `/brain:process-inbox` classifies and routes inbox notes to correct wiki type | P1 |

> Full contracts: `../behavioral-contracts/ss-11/`

### 2.12 Lobster Runtime (CAP-012)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.12.001 | `bin/lobster-run` reads workflow YAML and executes skill steps in declared dependency order | P0 |
| BC-2.12.002 | `bin/lobster-run` exits 0 (all steps succeed), 1 (advisory), 2 (any step blocks) | P0 |
| BC-2.12.003 | Six workflow YAML files ship in `plugins/brain-factory/workflows/` | P1 |
| BC-2.12.004 | `bin/lobster-run` supports headless execution (no interactive prompts) | P0 |

> Full contracts: `../behavioral-contracts/ss-12/`

### 2.13 GitHub Action Templates (CAP-013)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.13.001 | v0.1 core set (6 author-committed templates) ships and runs green on push | P0 |
| BC-2.13.002 | v0.5 additions (9 author-committed templates) ship with matrix strategy parallelism | P1 |
| BC-2.13.003 | Rate-limit handling: 429 responses trigger exponential backoff with `retry-after` respect | P1 |
| BC-2.13.004 | 4 community-optional templates ship in tarball with no-author-support documentation | P2 |

> Full contracts: `../behavioral-contracts/ss-13/`

### 2.14 Plugin Lifecycle and Upgrade (CAP-014)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.14.001 | `/plugin install brain-factory@claude-mp` succeeds in a fresh Claude session | P0 |
| BC-2.14.002 | `/brain:upgrade-brain` upgrades the plugin and migrates `.brain/` state if needed | P1 |
| BC-2.14.003 | Engine files are read-only at runtime; state lives exclusively in target's `.brain/` | P0 |
| BC-2.14.004 | `plugin.json` is valid JSON with semver version and all agents/skills registered | P0 |
| BC-2.14.005 | `hooks.json.template` references all 13 hooks via `${CLAUDE_PLUGIN_ROOT}` | P0 |

> Full contracts: `../behavioral-contracts/ss-14/`

### 2.15 Governance and Policies (CAP-015)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.15.001 | `.brain/policies.yaml` is initialized with 10 baseline policies by `/brain:init` | P1 |
| BC-2.15.002 | `/brain:policy-add` registers a new governance policy with schema validation | P1 |
| BC-2.15.003 | `/brain:policy-registry-validate` validates all policies against the schema | P1 |

> Full contracts: `../behavioral-contracts/ss-15/`

### 2.16 Scale-Aware Architecture (CAP-016)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.16.001 | Token instrumentation: `/brain:ingest-url` writes JSONL record per invocation | P0 |
| BC-2.16.002 | Token budget alert: `/brain:health` warns if 30-day trailing average exceeds 2x baseline | P1 |
| BC-2.16.003 | GH Actions process 100 sources/day sustained over 5-day test run without data loss | P1 |
| BC-2.16.004 | Peak resident memory for any single operation stays under 2GB | P1 |
| BC-2.16.005 | Per-ingest token cost stays within 3x the 50K-token baseline at 10K-source corpus | P1 |
| BC-2.16.006 | `scripts/gen-test-corpus.sh` generates reproducible synthetic corpus for scale test | P1 |

> Full contracts: `../behavioral-contracts/ss-16/`

### 2.17 Structured Event Catalog (CAP-017)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.17.001 | Every `hook-event:emit` site has a registered row in the structured event catalog | P0 |
| BC-2.17.002 | Event catalog defines: event_type, hook_name, severity, fields, example payload | P0 |
| BC-2.17.003 | Hooks emit JSONL on stderr; stdout is reserved for the JSON verdict only | P0 |
| BC-2.17.004 | No hook emits tokens, API keys, or credential values to any output stream | P0 |

> Full contracts: `../behavioral-contracts/ss-17/`

### 2.18 Meta-Lint and Self-Audit (CAP-018)

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.18.001 | `meta-lint.bats` validates SKILL.md frontmatter and canonical 6-section structure | P0 |
| BC-2.18.002 | `meta-lint.bats` validates hook scripts: shebang, `set -euo pipefail`, no bare exit, no eval | P0 |
| BC-2.18.003 | `meta-lint.bats` validates AGENT.md scope + tool-profile + routing reference | P0 |
| BC-2.18.004 | `meta-lint.bats` validates cross-cutting: no AI attribution, no `--no-verify`, no hardcoded template paths | P0 |
| BC-2.18.005 | Test surface organization — 8 category bats suites + per-hook .bats files at plugins/brain-factory/tests/ | P0 |

> Full contracts: `../behavioral-contracts/ss-18/`

---

## 3. Interface Definition

> **Supplement:** Full interface definitions are in `prd-supplements/interface-definitions.md`.
> This section provides a summary reference only.

26 skills expose argument-hint signatures via `SKILL.md` frontmatter. 13 hooks expose stdin JSON schemas and stdout JSON verdict schemas. 14 agents expose scope and tool-profile contracts. See `prd-supplements/interface-definitions.md` for complete definitions including: all skill argument-hint signatures, all hook stdin/stdout JSON schemas, exit-code semantics table, `plugin.json` schema, `hooks.json.template` schema, `manifest.json` schema, `.brain/policies.yaml` schema, and flag interaction rules (mutually exclusive, overrides).

## 4. Non-Functional Requirements

> **Supplement:** Full NFR catalog is in `prd-supplements/nfr-catalog.md`.
> This section provides a summary reference only.

NFR-NNN non-functional requirements with numerical targets. Key areas: hook performance (<100ms p99), init SLA (<5 minutes), wiki lint SLA (<10 min on 10K pages), token budget (<50K per ingest baseline, <150K at scale), memory limit (<2GB peak), cross-platform coverage (macOS + Linux strong; Git Bash + WSL2 partial). See `prd-supplements/nfr-catalog.md` for the complete catalog.

## 5. Error Taxonomy

> **Supplement:** Full error taxonomy is in `prd-supplements/error-taxonomy.md`.
> This section provides a summary reference only.

Error codes follow `E-{SCOPE}-NNN` convention. Scopes (21 total, matching `prd-supplements/error-taxonomy.md` scope headings): ADVERSARY, ATTR, FLUSH, HEALTH, HOOK, INGEST, INIT, LOBSTER, NAMING, PERF, POLICY, PUBLISH, QUARANTINE, RATE, RENAME, SCHEMA, SOURCE, UPGRADE, VOICE, WIKI, WRITE. Every error defines: code, category, severity (broken/degraded/cosmetic), exit code, message format with `<placeholder>` syntax. See `prd-supplements/error-taxonomy.md` for the complete taxonomy.

## 5b. Test Vectors

> **Supplement:** Canonical test vectors are in `prd-supplements/test-vectors.md`.

Golden test data for hook bats suites and skill end-to-end tests. Includes: hook stdin fixture payloads + expected stdout JSON + exit codes, and skill end-to-end scenarios. See `prd-supplements/test-vectors.md` for the complete test vector tables.

---

## 6. Competitive Differentiator Traceability

> Maps each KD differentiator from Section 1.3 to the BCs that implement it.

### 6.1 KD-001 — Hook-Enforced Governance

| BC ID | Contribution |
|-------|-------------|
| BC-2.04.001 | Quarantine blocks prompt-injection before web content reaches agent |
| BC-2.04.002 | Source-immutability hook enforces that sources are write-once |
| BC-2.04.003 | Wikilink-integrity hook enforces referential integrity at write time |
| BC-2.04.004 | Frontmatter-schema hook enforces embedding_status and mandatory fields |
| BC-2.04.016 | Hook contract: exit-code 2 is a hard block — not advisory |
| BC-2.10.002 | Quarantine fires on EVERY WebFetch call — cannot be bypassed |

### 6.2 KD-002 — Cognitive-Diversity Adversarial Review

| BC ID | Contribution |
|-------|-------------|
| BC-2.07.001 | Adversary must run in a different model family than producer |
| BC-2.07.002 | All four wclaude validation agents dispatched per review |
| BC-2.07.003 | Multi-pass writescore revision loop baked in |
| BC-2.07.004 | Structured pass/fail verdict with finding list |

### 6.3 KD-003 — Dispatcher-Ready Architecture

| BC ID | Contribution |
|-------|-------------|
| BC-2.04.016 | Every hook reads JSON stdin / writes JSON stdout / exits 0/1/2 — identical contract for WASM port |
| BC-2.14.005 | hooks.json.template uses `${CLAUDE_PLUGIN_ROOT}` — wire-compatible with factory-dispatcher |
| BC-2.17.003 | Stderr/stdout separation preserved — WASM port can inherit same I/O contract |

### 6.4 KD-004 — Scale-Aware Architecture from v0.1

| BC ID | Contribution |
|-------|-------------|
| BC-2.02.004 | Manifest-delta ingest — no full-corpus re-reads at any scale |
| BC-2.05.002 | O(n) wiki lint (index-first, not O(n²) cross-product) |
| BC-2.05.001 | 10-minute SLA for full lint on 10K-page wiki |
| BC-2.16.001 | Token instrumentation on every ingest operation |
| BC-2.16.003 | GH Action parallelism for 100-sources/day sustained |
| BC-2.16.005 | Per-ingest cost bounded at 3x baseline even at 10K-source corpus |

---

## 7. Requirements Traceability Matrix

| BC ID | Source (CAP) | Module(s) | Priority | Test Suite (SS-18 canonical 9-suite roster) |
|-------|-------------|-----------|----------|---------------------------------------------|
| BC-2.01.001 | CAP-001 | SS-01: Brain Initialization and Scaffold | P0 | tests/integration.bats |
| BC-2.01.002 | CAP-001 | SS-01: Brain Initialization and Scaffold | P0 | tests/integration.bats (assert_under_5_minutes) |
| BC-2.01.003 | CAP-001 | SS-01: Brain Initialization and Scaffold | P0 | tests/integration.bats |
| BC-2.01.004 | CAP-001 | SS-01: Brain Initialization and Scaffold | P0 | tests/integration.bats |
| BC-2.01.005 | CAP-001 | SS-01: Brain Initialization and Scaffold | P1 | tests/integration.bats |
| BC-2.01.006 | CAP-001 | SS-01: Brain Initialization and Scaffold | P1 | tests/integration.bats |
| BC-2.02.001 | CAP-002 | SS-02: URL Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.02.002 | CAP-002 | SS-02: URL Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.02.003 | CAP-002 | SS-02: URL Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.02.004 | CAP-002 | SS-02: URL Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.02.005 | CAP-002 | SS-02: URL Ingest Pipeline | P1 | tests/skills.bats |
| BC-2.02.006 | CAP-002 | SS-02: URL Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.02.007 | CAP-002 | SS-02: URL Ingest Pipeline | P1 | tests/integration.bats (scale — slow lane) |
| BC-2.03.001 | CAP-003 | SS-03: Source Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.03.002 | CAP-003 | SS-03: Source Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.03.003 | CAP-003 | SS-03: Source Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.03.004 | CAP-003 | SS-03: Source Ingest Pipeline | P0 | tests/skills.bats |
| BC-2.04.001 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/quarantine.bats |
| BC-2.04.002 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-source-immutability.bats |
| BC-2.04.003 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-wikilink-integrity.bats |
| BC-2.04.004 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-frontmatter-schema.bats |
| BC-2.04.005 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-frontmatter-schema.bats |
| BC-2.04.006 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-index-log-coherence.bats |
| BC-2.04.007 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-page-type-policy.bats |
| BC-2.04.008 | CAP-004 | SS-04: Hook Enforcement Chain | P1 | tests/validate-voice-avoid-list.bats |
| BC-2.04.009 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-source-id-citation.bats |
| BC-2.04.010 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/validate-publish-state.bats |
| BC-2.04.011 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/enforce-kebab-case.bats |
| BC-2.04.012 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/block-ai-attribution.bats |
| BC-2.04.013 | CAP-004 | SS-04: Hook Enforcement Chain | P1 | tests/flush-state-and-commit.bats |
| BC-2.04.014 | CAP-004 | SS-04: Hook Enforcement Chain | P1 | tests/brain-health-check.bats |
| BC-2.04.015 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/hook-contracts.bats (perf assertion — p99 latency) |
| BC-2.04.016 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/hook-contracts.bats |
| BC-2.04.017 | CAP-004 | SS-04: Hook Enforcement Chain | P0 | tests/hook-event-emit.bats |
| BC-2.05.001 | CAP-005 | SS-05: Wiki Layer and Wikilink Integrity | P0 | tests/skills.bats (scale path) |
| BC-2.05.002 | CAP-005 | SS-05: Wiki Layer and Wikilink Integrity | P0 | tests/skills.bats (property-based) |
| BC-2.05.003 | CAP-005 | SS-05: Wiki Layer and Wikilink Integrity | P0 | tests/skills.bats |
| BC-2.05.004 | CAP-005 | SS-05: Wiki Layer and Wikilink Integrity | P0 | tests/skills.bats |
| BC-2.05.005 | CAP-005 | SS-05: Wiki Layer and Wikilink Integrity | P0 | tests/skills.bats |
| BC-2.05.006 | CAP-005 | SS-05: Wiki Layer and Wikilink Integrity | P0 | tests/validate-frontmatter-schema.bats |
| BC-2.06.001 | CAP-006 | SS-06: Source Layer and Immutability | P0 | tests/validate-source-immutability.bats |
| BC-2.06.002 | CAP-006 | SS-06: Source Layer and Immutability | P1 | tests/skills.bats |
| BC-2.06.003 | CAP-006 | SS-06: Source Layer and Immutability | P0 | tests/integration.bats |
| BC-2.06.004 | CAP-006 | SS-06: Source Layer and Immutability | P1 | tests/integration.bats |
| BC-2.07.001 | CAP-007 | SS-07: Adversarial Review and Writescore | P0 | tests/adversary.bats |
| BC-2.07.002 | CAP-007 | SS-07: Adversarial Review and Writescore | P0 | tests/adversary.bats |
| BC-2.07.003 | CAP-007 | SS-07: Adversarial Review and Writescore | P1 | tests/adversary.bats |
| BC-2.07.004 | CAP-007 | SS-07: Adversarial Review and Writescore | P0 | tests/adversary.bats |
| BC-2.08.001 | CAP-008 | SS-08: Content Brief and Writing | P0 | tests/integration.bats |
| BC-2.08.002 | CAP-008 | SS-08: Content Brief and Writing | P0 | tests/integration.bats |
| BC-2.08.003 | CAP-008 | SS-08: Content Brief and Writing | P1 | tests/integration.bats |
| BC-2.08.004 | CAP-008 | SS-08: Content Brief and Writing | P1 | tests/validate-voice-avoid-list.bats |
| BC-2.09.001 | CAP-009 | SS-09: Publishing Pipeline | P0 | tests/integration.bats |
| BC-2.09.002 | CAP-009 | SS-09: Publishing Pipeline | P1 | tests/integration.bats |
| BC-2.09.003 | CAP-009 | SS-09: Publishing Pipeline | P1 | tests/integration.bats |
| BC-2.09.004 | CAP-009 | SS-09: Publishing Pipeline | P0 | tests/validate-publish-state.bats |
| BC-2.09.005 | CAP-009 | SS-09: Publishing Pipeline | P0 | tests/integration.bats |
| BC-2.09.006 | CAP-009 | SS-09: Publishing Pipeline | P1 | tests/integration.bats |
| BC-2.10.001 | CAP-010 | SS-10: Prompt-Injection Quarantine | P0 | tests/quarantine.bats |
| BC-2.10.002 | CAP-010 | SS-10: Prompt-Injection Quarantine | P0 | tests/quarantine.bats |
| BC-2.10.003 | CAP-010 | SS-10: Prompt-Injection Quarantine | P0 | tests/quarantine.bats |
| BC-2.11.001 | CAP-011 | SS-11: Knowledge Synthesis and Connection | P1 | tests/integration.bats |
| BC-2.11.002 | CAP-011 | SS-11: Knowledge Synthesis and Connection | P1 | tests/integration.bats |
| BC-2.11.003 | CAP-011 | SS-11: Knowledge Synthesis and Connection | P1 | tests/integration.bats |
| BC-2.12.001 | CAP-012 | SS-12: Lobster Runtime | P0 | tests/integration.bats |
| BC-2.12.002 | CAP-012 | SS-12: Lobster Runtime | P0 | tests/integration.bats |
| BC-2.12.003 | CAP-012 | SS-12: Lobster Runtime | P1 | tests/integration.bats |
| BC-2.12.004 | CAP-012 | SS-12: Lobster Runtime | P0 | tests/integration.bats |
| BC-2.13.001 | CAP-013 | SS-13: GitHub Action Templates | P0 | tests/upgrade.bats |
| BC-2.13.002 | CAP-013 | SS-13: GitHub Action Templates | P1 | tests/upgrade.bats |
| BC-2.13.003 | CAP-013 | SS-13: GitHub Action Templates | P1 | tests/upgrade.bats |
| BC-2.13.004 | CAP-013 | SS-13: GitHub Action Templates | P2 | tests/meta-lint.bats (doc assertions) |
| BC-2.14.001 | CAP-014 | SS-14: Plugin Lifecycle and Upgrade | P0 | tests/upgrade.bats |
| BC-2.14.002 | CAP-014 | SS-14: Plugin Lifecycle and Upgrade | P1 | tests/upgrade.bats |
| BC-2.14.003 | CAP-014 | SS-14: Plugin Lifecycle and Upgrade | P0 | tests/integration.bats |
| BC-2.14.004 | CAP-014 | SS-14: Plugin Lifecycle and Upgrade | P0 | tests/upgrade.bats |
| BC-2.14.005 | CAP-014 | SS-14: Plugin Lifecycle and Upgrade | P0 | tests/upgrade.bats |
| BC-2.15.001 | CAP-015 | SS-15: Governance and Policies | P1 | tests/policies.bats |
| BC-2.15.002 | CAP-015 | SS-15: Governance and Policies | P1 | tests/policies.bats |
| BC-2.15.003 | CAP-015 | SS-15: Governance and Policies | P1 | tests/policies.bats |
| BC-2.16.001 | CAP-016 | SS-16: Scale-Aware Architecture | P0 | tests/integration.bats |
| BC-2.16.002 | CAP-016 | SS-16: Scale-Aware Architecture | P1 | tests/integration.bats |
| BC-2.16.003 | CAP-016 | SS-16: Scale-Aware Architecture | P1 | tests/upgrade.bats (scale) |
| BC-2.16.004 | CAP-016 | SS-16: Scale-Aware Architecture | P1 | tests/integration.bats (perf assertion) |
| BC-2.16.005 | CAP-016 | SS-16: Scale-Aware Architecture | P1 | tests/integration.bats (perf assertion — scale) |
| BC-2.16.006 | CAP-016 | SS-16: Scale-Aware Architecture | P1 | tests/integration.bats |
| BC-2.17.001 | CAP-017 | SS-17: Structured Event Catalog | P0 | tests/meta-lint.bats |
| BC-2.17.002 | CAP-017 | SS-17: Structured Event Catalog | P0 | tests/meta-lint.bats (catalog completeness) |
| BC-2.17.003 | CAP-017 | SS-17: Structured Event Catalog | P0 | tests/hook-event-emit.bats |
| BC-2.17.004 | CAP-017 | SS-17: Structured Event Catalog | P0 | tests/hook-event-emit.bats (security grep assertion) |
| BC-2.18.001 | CAP-018 | SS-18: Meta-Lint and Self-Audit | P0 | tests/meta-lint.bats |
| BC-2.18.002 | CAP-018 | SS-18: Meta-Lint and Self-Audit | P0 | tests/meta-lint.bats |
| BC-2.18.003 | CAP-018 | SS-18: Meta-Lint and Self-Audit | P0 | tests/meta-lint.bats |
| BC-2.18.004 | CAP-018 | SS-18: Meta-Lint and Self-Audit | P0 | tests/meta-lint.bats |
| BC-2.18.005 | CAP-018 | SS-18: Meta-Lint and Self-Audit | P0 | tests/meta-lint.bats |

---

## Self-Audit Checklist (completed before delivery)

Per CLAUDE.md Canonical Principle Self-Audit Checklist:

- [x] Did I rationalize any decision with "MVP," "for now," "good enough," or "we can fix later"? **No.** All BC preconditions and postconditions are fully specified. All counts (26 skills, 14 agents, 13 hooks, 18 CAP subsystems, 95 BCs total across 18 subsystems, 8 category bats suites + 13 per-hook bats files) are stated as exact commitments. No "TBD" or placeholder language in BC bodies.
- [x] Did I add a new tech-debt-register entry without all three of: explicit human direction, concrete future dependency, and a specific future story/wave anchor? **No.** No tech-debt-register entries created.
- [x] Did I leave any "pending architect review," "TODO for architect," or "Placeholder for architect" in a spec artifact for a question I could have answered in scope? **No.** Module column in traceability matrix originally used a Phase 1b placeholder at delivery time (legitimate cross-component work requiring architect output). Backfilled with canonical SS-NN module labels during F-1c-CV-07 fix-burst (2026-05-15) after architect Subsystem Registry landed.
- [x] Did I find a bug or gap in another AI's output and surface it as a question/advisory instead of fixing it in scope? **No.** All brief underspecifications elaborated into full BCs in scope.
- [x] Did I default to the cheapest mechanism instead of the correct mechanism? **No.** All 18 subsystems fully specified. No "see brief" deferrals.
- [x] Did I paper-fix a finding by renaming, doc-commenting, or asserting-only when the real fix is structural? **No.** Each BC has testable preconditions, postconditions, invariants, edge cases, and canonical test vectors.
- [x] Did I sibling-sweep all callsites when I changed a hook signature, exit-code semantic, or canonical identifier? **Yes.** Hook names, exit codes, and subsystem IDs are consistent across PRD index, BC files, supplements, and traceability matrix.
- [x] Did I modify a planning artifact in `docs/planning/` without explicit human direction? **No.** All writes to `.factory/specs/`.
- [x] **Changelog audit-trail discipline (inherited five-file gate):** Before committing this PRD burst, run:

  ```bash
  for f in \
    .factory/specs/product-brief.md \
    .factory/SESSION-HANDOFF.md \
    .factory/specs/prd/index.md \
    .factory/specs/behavioral-contracts/BC-INDEX.md \
    .factory/specs/architecture/ARCH-INDEX.md; do
    echo "--- $f ---"
    grep -nE '\bL[0-9]+\b' "$f" \
      | grep -v WSL2 \
      | grep -v 'L\[0-9\]+' \
      | grep -v 'LinkedIn\|License\|LTS\|Linux\|Lobster\|Lock\|Loom\|Loki' \
      | grep -v 'level: L[0-9]\+\|Level [0-9]\+\|L2\|L3\|L4\|LEVEL' \
      | grep -v 'SS-[0-9]\+\|CAP-[0-9]\+\|NFR-[0-9]\+\|ADR-[0-9]\+\|VP-[0-9]\+'
  done
  ```

  and confirm it returns zero output. All five files (brief, handoff, PRD index, BC-INDEX, ARCH-INDEX) must be free of literal line-number anchors. The exclusion list (`WSL2`, `L\[0-9\]+`, and the listed legitimate L-prefixed words including `L2`/`L3`/`L4` VSDD level designators, plus architecture ID tokens `SS-NN|CAP-NNN|NFR-NNN|ADR-NNN|VP-NNN`) is the authoritative set; new domain tokens must be added to the exclusion list before introduction.

  **NOTE (exclusion-list-extension protocol — VSDD level designators):** The `L2`, `L3`, `L4` tokens in this PRD's frontmatter (`level: L3`) and in BC files (`level: L3`) are VSDD specification tier designators — not line-number references. Added exclusion `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` per the exclusion-list-extension protocol (a) add exclusion; (b) re-run gate — zero matches; (c) rationale: VSDD spec level designators are domain-standard tokens, not line-number anchors.

  **NOTE (exclusion-list-extension protocol — architecture ID tokens):** This PRD references `SS-NN`, `CAP-NNN`, `NFR-NNN`, `ADR-NNN`, and `VP-NNN` patterns throughout. These are canonical spec identifiers — not line-number anchors. Added `grep -v 'SS-[0-9]+|CAP-[0-9]+|NFR-[0-9]+|ADR-[0-9]+|VP-[0-9]+'` per the exclusion-list-extension protocol. Sibling-swept from BC-INDEX and ARCH-INDEX five-file gate per TD-VSDD-060.

  **NOTE (exclusion-list-extension protocol):** To add a new token: (a) add to `grep -v` clause; (b) re-run gate; (c) record rationale in changelog. Do NOT work around the gate by reverting the writing-technique principle.

  **NOTE (five-file gate history):** Three-file gate introduced at v0.1.0. Extended to four-file at v0.1.1 by adding BC-INDEX.md (F-1b-CV-01). Extended to five-file at v0.1.3 by adding ARCH-INDEX.md (F-PASS1-C6 closure, 2026-05-16). The architecture ID token exclusion clause was added at the same time via sibling-sweep with the BC-INDEX and ARCH-INDEX canonical gate commands. Plain-prose `line [0-9]+` clause added at v0.1.7 (F-PASS6-I1 closure, sibling-swept with BC-INDEX).

  **Clause 2 — plain-prose line-number check (added v0.1.7, F-PASS6-I1; exclusion improved v0.1.8, F-PASS7-C1):** In addition to the L-prefixed gate above, also run:

  ```bash
  for f in \
    .factory/specs/product-brief.md \
    .factory/SESSION-HANDOFF.md \
    .factory/specs/prd/index.md \
    .factory/specs/behavioral-contracts/BC-INDEX.md \
    .factory/specs/architecture/ARCH-INDEX.md; do
    echo "--- $f ---"
    grep -nE '\bline [0-9]+\b' "$f" \
      | grep -v '```' \
      | grep -v '\`line [0-9]\+\`'
  done
  ```

  and confirm it returns zero output. Legitimate exclusions: (a) content inside triple-backtick code-block fences — shell command examples, bats harness code, and generated output blocks legitimately reference line numbers as command arguments or tool output; (b) single-backtick inline code spans (`line N`) — inline code references are not narrative prose anchors. The writing-technique principle still applies: prefer behavioral descriptions over `line N` references even in inline code contexts. Descriptions of this defect class MUST use semantic terms (e.g., "plain-prose line-number citation in §Bring-up plan") — never quote a specific line number, which the gate cannot distinguish from an active citation.

  **NOTE (exclusion-list-extension protocol — plain-prose clause):** To add a new exclusion for the plain-prose clause: (a) add to `grep -v` clause; (b) re-run gate — zero matches; (c) record rationale in changelog with dated entry. Triple-backtick fences and single-backtick inline spans are the two pre-approved exclusion categories (sibling-swept from ARCH-INDEX v0.1.8 improved Clause 2).

- [x] **Changelog version-monotonicity check (F-PASS16-I1, mirrored F-PASS17-I3(b)):** Changelog entries MUST appear in strict descending semver order — each `### vX.Y.Z` entry must be followed by `### vX.Y.(Z-1)` (or the next-lower version). No version may appear out of sequence. Bash sweep:

  ```bash
  grep -nE '^### v' .factory/specs/prd/index.md | awk '{print $2}' | sort -rV -c
  ```

  exits 0 if entries are strictly descending. Incremental scope: when adding a new Changelog entry to this PRD, insert it at the TOP of the Changelog section (after `## Changelog`) — always newer version before older. Verify by running the bash sweep above before commit. Canonical-baseline scope: Pass 17 F-PASS17-I3(b) sibling-sweep from ARCH-INDEX v0.1.19 (commit b70fc7d). Canonical-baseline sweep at codification: PRD Changelog (10 entries v0.1.0..v0.1.9) verified monotone via `grep -nE '^### v' index.md | awk '{print $2}' | sort -rV -c` exit 0. (Mirrored from ARCH-INDEX discipline #22 per F-PASS6-O1-arch / F-PASS6-O1-PO sibling-sweep precedent.) [audit-trail]

- [x] **Header-vs-body count check (F-PASS17-I1 closure, mirrored F-PASS17-I3(b)):** For any section header that contains a count claim (e.g., "(N total items)", "(M confirmed disciplines)", "N fix-bursts complete"), verify the count matches the visible body item / row / list-entry count. Headers MUST accurately describe the body they introduce. Paper-fixing a header by updating the count claim without reconciling the body is a TD-VSDD-059 violation.

  Incremental scope: applied before any PRD burst that updates a section header containing a count claim. The header text MUST be reconciled with body count before commit. Canonical-baseline scope: Pass 17 F-PASS17-I3(b) sibling-sweep from ARCH-INDEX v0.1.19. Canonical-baseline sweep at codification: PRD section headers carrying number claims include "21 total" scopes in §5 Error Taxonomy and counts embedded in body prose; no PRD section headers carry a standalone count-claim `(N total ...)` format in the heading text itself that would require body reconciliation. PRD is clean at codification. (Mirrored from ARCH-INDEX discipline #23 per F-PASS6-O1-arch / F-PASS6-O1-PO sibling-sweep precedent.) [audit-trail]

- [x] **last_updated freshness check:** Before commit, verify `last_updated` frontmatter date >= MAX(date in any Changelog entry). If a new Changelog entry dated YYYY-MM-DD is added, `last_updated` MUST be ≥ YYYY-MM-DD. Current: `last_updated: 2026-05-19`; most recent Changelog entry: v0.1.13 (2026-05-19). **PASS.**

---

## Changelog

### v0.1.13 (2026-05-19)

**RTM FIX (F-PHASE2-ADV-PASS1-C02):** 21 Requirements Traceability Matrix rows swept from stale `tests/hooks.bats` to per-hook `tests/<hook-name>.bats` to align with UD-006 per-hook bats convention (SS-18 v1.5 + NFR-019 v0.1.1). Rows affected: BC-2.04.002–2.04.008, BC-2.04.010–2.04.017, BC-2.05.006, BC-2.06.001, BC-2.08.004, BC-2.17.001, BC-2.17.003–2.17.004. No semantic change to contract definitions. Zero residual live `tests/hooks.bats` hits in `.factory/specs/`. (F-PHASE2-ADV-PASS1-C02)

### v0.1.12 (2026-05-18)

**RTM FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE-RTM):** Requirements Traceability Matrix row for BC-2.04.009 test-method migrated from `tests/hooks.bats` to `tests/validate-source-id-citation.bats` (hook confirmed from BC-2.04.009 H1: `validate-source-id-citation.sh`). RTM row for BC-2.09.004 test-method migrated from `tests/hooks.bats` to `tests/validate-publish-state.bats` (hook confirmed from BC-2.09.004 body: enforced by `validate-publish-state.sh` per BC-2.04.010). These two rows were the residual `hooks.bats` RTM hits noted in the PO closeout 2 cascade report (`39d6fba`) as out-of-scope for the per-hook bats grep pattern. Zero residual live `hooks.bats` RTM hits remain in `.factory/specs/`. (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE-RTM)

### v0.1.11 (2026-05-18)

**TEST-ARCHITECTURE AMENDMENT CASCADE (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE):** BC-2.18.005 row 306 title updated from "9 bats test suites cover 13 hooks and all skills (positive + negative + edge case per hook)" to "Test surface organization — 8 category bats suites + per-hook .bats files at plugins/brain-factory/tests/" to mirror BC-2.18.005 H1 (now v1.2). Requirements Traceability Matrix row 484 title cell unchanged (no title column; cell is CAP/SS/priority/test-method). Self-Audit Checklist count claim updated from "9 bats suites" to "8 category bats suites + 13 per-hook bats files". `inherits_from` updated to `product-brief.md@v0.4.20`. (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE)

### v0.1.10 (2026-05-16)

**STRUCTURAL FIX (F-PASS17-I3(b) sibling-sweep — Discipline #22 Changelog version-monotonicity check mirrored into PRD Self-Audit Checklist from ARCH-INDEX v0.1.19 (commit b70fc7d)):** Per F-PASS17-I3 finding, discipline #22's bash sweep was architecture-only and did not cover PRD Changelogs. Both scopes declared: Incremental scope — insert new PRD Changelog entries at TOP, run `grep -nE '^### v' index.md | awk '{print $2}' | sort -rV -c` before commit; Canonical-baseline scope — PRD Changelog (10 entries v0.1.0..v0.1.9) verified monotone via bash sweep exit 0 at codification time. Mirrored per F-PASS6-O1-arch / F-PASS6-O1-PO sibling-sweep precedent. [audit-trail]

**STRUCTURAL FIX (F-PASS17-I3(b) sibling-sweep — Discipline #23 Header-vs-body count check mirrored into PRD Self-Audit Checklist from ARCH-INDEX v0.1.19):** Per F-PASS17-I3 finding, discipline #23 (Header-vs-body count check, codified by architect in Pass 17 burst) must be mirrored into PRD Self-Audit Checklist per the sibling-sweep precedent. Both scopes declared: Incremental scope — before any PRD burst updating a section header with a count claim, reconcile the header text with body count before commit; Canonical-baseline scope — PRD section headers scanned at codification: no PRD headers carry a standalone count-claim `(N total ...)` format in the heading text itself; count claims in PRD appear in body prose only (not in heading text). PRD is clean at codification. [audit-trail]

### v0.1.9 (2026-05-16)

**STRUCTURAL FIX (F-PASS12-C2 — canonical-baseline timestamp sweep for PRD/BC inventory):** Pass 11 architect burst codified the Timestamp Field Convention Policy at ARCH-INDEX v0.1.13 enumerating the PRD index, 4 supplements, BC-INDEX, and 95 BC files as in-scope but deferred the canonical-baseline sweep to a PO follow-up burst. This burst closes that deferral. Per the policy semantic (`timestamp = most recent meaningful content edit`), each in-scope file received per-file classification: files with documented content edits at 2026-05-16 → `timestamp: 2026-05-16T00:00:00`; files unchanged after initial 2026-05-15 creation → `timestamp: 2026-05-15T00:00:00`. Counts: PRD index bumped to 2026-05-16 (this file); 3 supplements bumped to 2026-05-16 (interface-definitions, error-taxonomy, test-vectors); 1 supplement retained at 2026-05-15 (nfr-catalog — last content commit 2026-05-15); BC-INDEX bumped to 2026-05-16; all 95 BCs bumped to 2026-05-16 (earliest body-content commit d89ea4b at 2026-05-16 00:00:10 populated Architecture Module cells in all 95 files). Closes F-PASS12-C2 (CRITICAL) per CLAUDE.md Canonical Principle Rule 4. [audit-trail]

### v0.1.8 (2026-05-16)

**STRUCTURAL FIX (F-PASS7-C1-PO — Clause 2 gate self-violation: plain-prose line-number citations in PRD v0.1.7 changelog):** The PRD v0.1.7 changelog entry for F-PASS6-I1 described the finding by citing plain-prose line-number references (both as specific integers following the word "line") inside single-backtick inline code spans. The Clause 2 gate's `grep -v '```'` exclusion covers only triple-backtick fences, not single-backtick inline spans — so these inline citations are matched by the gate, self-violating the rule the entry was adding. Fix: the violating descriptions replaced with semantic equivalents referencing the §Bring-up plan and §bin/lobster-run sections where the violations appeared. Structural fix: Clause 2 improved with additional `grep -v '\`line [0-9]\+\`'` exclusion for single-backtick inline spans, mirroring ARCH-INDEX v0.1.8 improved Clause 2. BC-INDEX sibling-swept. Writing-technique NOTE added: descriptions of this defect class must use semantic terms — never quote a specific line number. (F-PASS7-C1)

**STRUCTURAL FIX (F-PASS7-C2-PO — inherits_from re-pin to post-burst brief version per Option B):** `inherits_from` re-pinned from `product-brief.md@v0.4.16` to `product-brief.md@v0.4.19`. The v0.1.6 entry (F-PASS5-C1) recorded Option A reasoning ("pinned to the brief version at PRD authoring time, not the latest"). F-PASS6-C2 architect adjudication (ARCH-INDEX v0.1.7) chose Option B (pin-at-burst-end). This burst bumps the brief 0.4.18→0.4.19, making v0.4.19 the post-burst brief version — the correct Option B pin. Corrective note added to the v0.1.6 entry recording the Option A→B transition. (F-PASS7-C2)

**STRUCTURAL FIX (F-PASS7-I3-PO sibling-sweep from ARCH-INDEX — note history):** F-PASS7-I3 added Clause 2 to ARCH-INDEX Self-Audit Checklist (architect burst). F-PASS7-I3-PO propagates the improved Clause 2 exclusion (single-backtick inline span filter) to PRD and BC-INDEX Clause 2 gates per TD-VSDD-060 sibling-sweep obligation. (F-PASS7-I3-PO)

### v0.1.7 (2026-05-16)

**STRUCTURAL FIX (F-PASS6-I1 — five-file gate extended with plain-prose `line [0-9]+` clause):** The existing L-prefixed gate (`\bL[0-9]+\b`) does not catch plain-prose line-number citations in the form of a bare integer following the word "line." F-PASS6-I1 identified two such violations in the brief v0.4.16 changelog entry — one in §Bring-up plan and one in §bin/lobster-run. Gate extended: Clause 2 added to PRD Self-Audit Checklist using `grep -nE '\bline [0-9]+\b'` with documented exclusion protocol (code-block fences; `[audit-trail]`-tagged entries). Sibling-swept to BC-INDEX §Self-Audit Checklist per TD-VSDD-060. (F-PASS6-I1)

**STRUCTURAL FIX (F-PASS6-O1-PO — last_updated freshness check added to PRD Self-Audit):** Per Pass 5 architect introduction in ARCH-INDEX, the `last_updated freshness check` item is now present in PRD Self-Audit Checklist: "Before commit, verify `last_updated` frontmatter date >= MAX(date in any Changelog entry)." Sibling-swept to BC-INDEX §Self-Audit Checklist per TD-VSDD-060. (F-PASS6-O1-PO)

### v0.1.6 (2026-05-16)

**STRUCTURAL FIX (F-PASS5-C1 — PRD §2 stale paragraph + inherits_from drift):** `inherits_from` updated from `product-brief.md@v0.4.15` to `product-brief.md@v0.4.16` (the brief version current at PRD creation time; v0.4.17 is the post-this-burst brief version — inherits_from is pinned to the brief version at PRD authoring time, not the latest). §2 opening blockquote rewritten: stale "Architecture has not yet been produced (Phase 1c); subsystem field uses `SS-TBD` placeholder" replaced with current-state text reflecting Phase 1c COMPLETED status and all 95 BCs carrying canonical `subsystem: SS-NN` labels per ARCH-INDEX. `last_updated` bumped to 2026-05-16. (F-PASS5-C1)

> **NOTE (post-Pass-7 amendment per ARCH-INDEX v0.1.8 §Versioning Policy):** This entry's claim "inherits_from is pinned to the brief version at PRD authoring time, not the latest" embedded Option A reasoning. F-PASS6-C2 architect adjudication (ARCH-INDEX v0.1.7) chose Option B (pin-at-burst-end). F-PASS7-C2 PO closure (this commit) re-pins to post-burst brief version per Option B. The Option A reasoning in the original v0.1.6 entry is historical; the current invariant is Option B + final-reconciliation discipline (ARCH-INDEX v0.1.8 §Parallel-burst hazard mitigation).

### v0.1.5 (2026-05-16)

**STRUCTURAL FIX (F-PASS3-C1 — sibling-sweep BC-2.12.001 + BC-2.12.004 `.lobster` extension):** BC-2.12.001 Canonical Test Vector updated: `bin/lobster-run workflows/ingest-url.lobster` → `bin/lobster-run workflows/ingest-url.yaml`. BC-2.12.004 Canonical Test Vector updated: `bin/lobster-run workflow.lobster < /dev/null` → `bin/lobster-run workflow.yaml < /dev/null`. These two were missed in the Pass 2 sibling-sweep of BC-2.12.003 (Decision 1).

**STRUCTURAL FIX (F-PASS3-C2 — BC-2.17.001 + BC-2.17.002 stale catalog location):** BC-2.17.001 Postcondition 1 updated: `plugins/brain-factory/docs/event-catalog.md` → `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json`; Postcondition 2 field list updated from markdown-table format to JSON schema fields (`event_type`, `hook_name`, `severity`, `fields`, `example`). BC-2.17.002 EC-001 updated: `event-catalog.md` → `event-catalog.json`; EC-002 updated: `example_payload` → `example`; VP-008 Proof Method updated: `(markdown table parse)` → `(JSON parse)`. Completes the F-PASS2-C4 sibling-sweep that updated BC-2.17.002 body but left BC-2.17.001 Postconditions stale.

**STRUCTURAL FIX (F-PASS3-I3 — BC-2.16.005 non-canonical `--count` flag):** BC-2.16.005 EC-002 updated: `gen-test-corpus.sh --seed 42 --count 10000` → `gen-test-corpus.sh --sources 10000 --seed 42 /tmp/test-brain` per ADR-012 §Script interface and BC-2.16.006 canonical CLI.

**STRUCTURAL FIX (F-PASS3-I4 — BC-2.06.003 VP-012 anchor label):** BC-2.06.003 VP Anchors section updated: `VP-012 — Manifest schema integrity (Group 2: last_ingest field correctness)` → `VP-012 — Manifest write atomicity and last_ingest field correctness (Group 2: last_ingest field correctness)` per VP-012 canonical H1 title in `verification-properties/VP-012-manifest-atomicity.md`.

### v0.1.4 (2026-05-16)

**STRUCTURAL FIX (F-PASS2-C1 sibling-sweep — event_type past-tense in all hook BCs):** BC-2.04.002 `event_type` values corrected to past-tense: `source.immutability.violation` → `source.immutability.violated`; `source.new` → `source.added`. BC-2.04.003 through BC-2.04.014 each received explicit `event_type` enumeration in Postconditions per BC-2.04.017 universal requirement. All event_types use `<domain>.<past-tense-verb>` pattern per SS-17 §Event-type naming convention.

**STRUCTURAL FIX (F-PASS2-C4 — BC-2.17.002 align with SS-17 catalog schema):** BC-2.17.002 updated: catalog location changed from `plugins/brain-factory/docs/event-catalog.md` to `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json`; format changed from "markdown table" to "JSON array"; fields aligned with SS-17 schema (`event_type`, `hook_name`, `severity`, `fields`, `example` — no `trigger`; `example` not `example_payload`); event_type pattern changed from `<subsystem>.<action>` to `<domain>.<past-tense-verb>` per SS-17 §Event-type naming convention. Canonical test vectors updated to reflect JSON format.

**STRUCTURAL FIX (F-PASS2-I1 — test-vectors.md gen-test-corpus CLI sibling-sweep):** `prd-supplements/test-vectors.md` Scenario 4 (Scale Test) corrected: `bash scripts/gen-test-corpus.sh 10000 --seed 42 --dir /tmp/scale-brain` → `bash scripts/gen-test-corpus.sh --sources 10000 --seed 42 /tmp/scale-brain` per ADR-012 §Script interface and BC-2.16.006.

**STRUCTURAL FIX (F-PASS2-I3 — BC-2.13.003 api-retry path sibling-sweep):** BC-2.13.003 Invariant 2 corrected: `scripts/api-retry.sh` → `scripts/lib/api-retry.sh` per ADR-013, ADR-016, and SS-13.

**STRUCTURAL FIX (F-PASS2-I7 — canonical policies template filename):** BC-2.15.001 and BC-2.01.001 updated: `templates/policies-yaml-template.yaml` → `templates/policies.yaml` per SS-15 and ARCH-INDEX source-of-truth precedence.

**STRUCTURAL FIX (F-PASS2-I8 — BC-2.08.003 companion-posts count):** BC-2.08.003 Description, Postconditions, Canonical Test Vector, and Verification Properties updated: "3–5 files" → "3 files" per F-PASS1-I7 closure and `prd-supplements/interface-definitions.md`.

**STRUCTURAL FIX (Decision 1 — BC-2.12.003 Lobster workflow filenames + extension):** BC-2.12.003 updated throughout: extension changed from `.lobster` to `.yaml`; six workflow filenames changed to canonical ADR-006 set: `ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`, `weekly-refresh.yaml`, `scale-test.yaml`. Postconditions, Invariants, and Canonical Test Vectors updated. Traceability Capability Anchor Justification updated to cite ADR-006 §Workflow file inventory decision.

**STRUCTURAL FIX (Decision 2 — 9-suite roster downstream sweep):** §7 RTM rows corrected: `tests/ingest.bats` → `tests/skills.bats` for BC-2.02.001..006, BC-2.03.001..004, BC-2.06.002; `tests/wiki.bats` → `tests/skills.bats` for BC-2.05.001..005. BC-2.06.003 RTM row updated to `tests/integration.bats` (VP-012 Group 2 coverage via integration pipeline). All RTM rows now use only brief v0.4.15 canonical 9-suite names per SS-18 §9 bats suites alignment decision (F-PASS2-I4).

**STRUCTURAL FIX (Decision 3 — BC-2.06.003 VP coverage update):** BC-2.06.003 Verification Properties table updated: "(no direct VP — P0; VP gap noted)" replaced with "VP-012 (Group 2: last_ingest field correctness)". VP Anchors section added citing VP-012.

### v0.1.3 (2026-05-16)

**STRUCTURAL FIX (F-PASS1-C1):** BC-2.13.001 Description and Postconditions updated to use ADR-013 canonical v0.1 template names (`daily-brief.yml`, `weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`, `scale-test.yml`). Removed erroneous names (`weekly-lint.yml`, `weekly-synthesis.yml`, `schema-refresh.yml`, `wikilink-check.yml`, `quarterly-mirror.yml`). `quarterly-mirror.yml` is a v0.5 addition per ADR-013 §Template inventory — it must not appear in the v0.1 list. Canonical test vector updated to enumerate the 6 correct filenames.

**STRUCTURAL FIX (F-PASS1-C2 — BC portion):** BC-2.16.006 CLI invocation corrected to match ADR-012 interface: positional `<output-dir>` argument, `--sources N` flag (not positional count), all six ADR-012 flags enumerated in Description and Preconditions. Canonical test vector corrected from `gen-test-corpus.sh 10000 --seed 42 --dir /tmp/test-brain` (wrong) to `gen-test-corpus.sh --sources 10000 --seed 42 /tmp/test-brain` (correct per ADR-012 §Script interface).

**STRUCTURAL FIX (F-PASS1-C3):** BC-2.04.017 Precondition 2 updated: `${CLAUDE_PLUGIN_ROOT}/scripts/hook-event-emit.sh` → `${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh`. `prd-supplements/error-taxonomy.md` E-HOOK-002 message format corrected to same path. Authoritative source: ADR-016 + ARCH-INDEX + ADR-002 + ADR-014 + SS-04 all agree on `hooks/lib/` location.

**STRUCTURAL FIX (F-PASS1-C6):** Self-Audit Checklist gate extended from four-file to five-file by adding `.factory/specs/architecture/ARCH-INDEX.md` as the fifth file. Gate command updated with: (1) ARCH-INDEX in the `for` loop, (2) architecture ID token exclusion clause (`SS-NN|CAP-NNN|NFR-NNN|ADR-NNN|VP-NNN`) sibling-swept from BC-INDEX canonical gate. Prose updated: "All four files" → "All five files (brief, handoff, PRD index, BC-INDEX, ARCH-INDEX)". Gate label: "(inherited four-file gate)" → "(inherited five-file gate)". Historical note added: four-file at v0.1.1, five-file at v0.1.3.

**STRUCTURAL FIX (F-PASS1-I7):** `prd-supplements/interface-definitions.md` §7 `/brain:write` flag interaction table updated: `3–5 companion posts` → `3 companion posts` to match SS-08 current state. Decision rationale: 3 is the narrower, unambiguous contract; SS-08 alignment confirmed.

**STRUCTURAL FIX (F-PASS1-I10):** VP-TBD placeholders in all 95 BC files replaced with actual VP IDs from VP-INDEX P0 Coverage Matrix. P0 BCs with VP coverage: updated to cite VP-NNN directly. P1/P2 BCs with no VP coverage: placeholder replaced with `(no VP — P1/P2; deferred per VP-INDEX coverage policy)`. One P0 VP gap noted: BC-2.06.003 (last_ingest timestamps) has no direct VP in VP-INDEX v0.1.1; gap noted inline pending VP-INDEX v0.1.2 update (architect scope).

**STRUCTURAL FIX (F-PASS1-I11):** §7 RTM Test Type column header and all values renamed from ambiguous short-form labels to explicit canonical 9-suite file names per SS-18 roster. Column header renamed from "Test Type" to "Test Suite (SS-18 canonical 9-suite roster)". Note: subsequent F-PASS2 Decision 2 sweep corrected `tests/ingest.bats` → `tests/skills.bats` and `tests/wiki.bats` → `tests/skills.bats` throughout the RTM to align with brief v0.4.15 naming (see v0.1.4 changelog).

**STRUCTURAL FIX (F-PASS1-I1 — architect decision applied):** `/brain:init` public CLI verified as zero-argument in `interface-definitions.md`. Already correct — no change required. Confirmed per SS-01 §Architectural Decisions §Public CLI: zero arguments.

**STRUCTURAL FIX (F-PASS1-I2 — architect decision applied):** BC-2.01.001 Description and Precondition 2 updated to explicitly state hard-fail behavior: "If `.brain/` already exists, `/brain:init` HARD-FAILS with E-INIT-002 (exit 2). It does NOT idempotently re-scaffold." EC-002 updated with explicit "HARD-FAIL" label and rationale per SS-01 §Architectural Decisions.

**STRUCTURAL FIX (F-PASS1-I4 — architect decision applied):** BC-2.04.001 Postconditions updated: `event_type: quarantine.block` → `quarantine.blocked`; `quarantine.allow` → `quarantine.allowed`. BC-2.04.017 Invariant 4 updated: imperative forms enumerated as meta-lint violations; past-tense examples cited per SS-17 §Event-type naming convention. Related BC reference in BC-2.04.001 updated to reflect new event type names.

### v0.1.2 (2026-05-15)

**STRUCTURAL FIX (F-1c-CV-07 closure + Phase 1c handoff):** §7 RTM Module column backfilled with SS-NN subsystem labels per architect's Subsystem Registry (ARCH-INDEX.md). The 95 BC rows in the Requirements Traceability Matrix now carry canonical module assignments (SS-01 through SS-18) matching the 1:1 mapping established by the Phase 1c architect. Self-Audit Checklist note updated to reflect that Phase 1c has landed and the placeholder is no longer active.

### v0.1.1 (2026-05-15)

**STRUCTURAL FIX (F-1b-CV-01 — BC sharding integrity):** Created `behavioral-contracts/BC-INDEX.md` as the canonical sharding index over all 95 BC files per DF-020a criterion 22. Added `traces_to: ../BC-INDEX.md` to all 95 BC frontmatter blocks. Extended the Self-Audit Checklist gate from a three-file gate to a four-file gate (brief + handoff + prd/index.md + BC-INDEX.md). Both the PRD index gate and BC-INDEX gate use the identical canonical four-file command.

**STRUCTURAL FIX (F-1b-CV-02 — BC edge-case coverage):** Added `## Edge Cases` sections with 3 concrete edge cases each to 14 BC files that previously had zero edge-case coverage: BC-2.13.002, BC-2.13.004, BC-2.15.001, BC-2.15.003, BC-2.16.001, BC-2.16.003, BC-2.16.004, BC-2.16.005, BC-2.16.006, BC-2.17.002, BC-2.17.003, BC-2.18.002, BC-2.18.003, BC-2.18.004. Canonical test vector tables extended with matching edge-case rows in the same files.

**STRUCTURAL FIX (F-1b-CV-03 — §5 error scope list):** Corrected the §5 Error Taxonomy summary scope list. Removed `SCALE` (non-existent scope). Added 12 scopes that were missing: ADVERSARY, ATTR, FLUSH, HEALTH, NAMING, PERF, RATE, RENAME, SCHEMA, SOURCE, UPGRADE, VOICE, WRITE. §5 now enumerates all 21 actual scopes from `prd-supplements/error-taxonomy.md` in alphabetical order.

**STRUCTURAL FIX (F-1b-CV-04 — supplement gate VSDD level-designator exclusion):** Extended the Self-Audit Checklist gate in all 4 supplements (`error-taxonomy.md`, `nfr-catalog.md`, `interface-definitions.md`, `test-vectors.md`) to include `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'`. Each supplement now has an inline gate command (replacing the "see error-taxonomy.md for command" pointer) with the complete canonical exclusion list per TD-VSDD-060 sibling-sweep.

### v0.1.0 (2026-05-15)

**STRUCTURAL FIX: Phase 1b PRD entry — elaborates converged brief v0.4.15 into BCs, error taxonomy, edge cases, NFR catalog, interface definitions, and test vectors. Inherits 13 Phase 1a structural-fix disciplines per STATE.md. Extends the Self-Audit Checklist two-file gate to a three-file gate covering brief + handoff + this PRD index. BC count: 95 BCs across 18 capability subsystems (CAP-001 through CAP-018). Subsystem field uses SS-TBD pending Phase 1c architect assignment.**

**STRUCTURAL FIX (exclusion-list extension — VSDD level designators):** The three-file gate surfaced `level: L3` in PRD frontmatter as a candidate match. This is a VSDD specification tier designator (L2 = domain spec, L3 = PRD/BCs, L4 = verification properties) — not a line-number anchor. Per the exclusion-list-extension protocol: added `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` to the gate command. Gate re-run returns zero matches. All PRD shards and BC files use `level: L3` in frontmatter; this exclusion scope-eliminates the false-positive class for VSDD tier designators within this burst's scope (re-verify in subsequent passes).
