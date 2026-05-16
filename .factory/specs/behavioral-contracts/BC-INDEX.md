---
document_type: bc-index
level: L3
version: "0.1.4"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
traces_to: ../prd/index.md
inherits_from: prd@v0.1.0
created: 2026-05-15
last_updated: 2026-05-15
---

# Behavioral Contract Index: brain-factory

> This is the canonical sharding index over all 95 behavioral contract files in
> `behavioral-contracts/ss-NN/`. BC files at `ss-NN/BC-2.NN.NNN.md` carry
> `traces_to: ../BC-INDEX.md` pointing back to this file per DF-020a criterion 22.
>
> Architecture subsystem IDs (`subsystem:` field) use canonical `SS-NN` labels
> per the Subsystem Registry in `architecture/ARCH-INDEX.md`. The 1:1 mapping
> (SS-NN = ss-NN = CAP-NNN) was assigned during Phase 1c architect work and
> backfilled into all 95 BC frontmatter files (F-1c-CV-07 closure, 2026-05-15).
>
> Capability anchors (CAP-NNN) are defined in `prd/index.md` Section 2 and
> cited verbatim in each BC file's Traceability section.

---

## ss-01: Brain Initialization and Scaffold (CAP-001)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.01.001 | `/brain:init` scaffolds complete brain folder structure in a fresh directory | SS-01 | CAP-001 | P0 | active | ss-01/BC-2.01.001.md |
| BC-2.01.002 | `/brain:init` completes end-to-end in under 5 minutes (tested SLA) | SS-01 | CAP-001 | P0 | active | ss-01/BC-2.01.002.md |
| BC-2.01.003 | `/brain:init` rejects non-git-repo target directory with E-INIT-001 | SS-01 | CAP-001 | P0 | active | ss-01/BC-2.01.003.md |
| BC-2.01.004 | `/brain:init` writes `embedding_status: pending` in every wiki page template | SS-01 | CAP-001 | P0 | active | ss-01/BC-2.01.004.md |
| BC-2.01.005 | `/brain:init` scaffolds `briefs/research/` subdirectory | SS-01 | CAP-001 | P1 | active | ss-01/BC-2.01.005.md |
| BC-2.01.006 | `/brain:health` reports six-dimensional convergence state in structured JSON | SS-01 | CAP-001 | P1 | active | ss-01/BC-2.01.006.md |

## ss-02: URL Ingest Pipeline (CAP-002)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.02.001 | `/brain:ingest-url` fetches URL via Defuddle and writes to `sources/{topic}/` | SS-02 | CAP-002 | P0 | active | ss-02/BC-2.02.001.md |
| BC-2.02.002 | `/brain:ingest-url` produces 5–15 cross-referenced wiki pages per ingest | SS-02 | CAP-002 | P0 | active | ss-02/BC-2.02.002.md |
| BC-2.02.003 | `/brain:ingest-url` writes JSONL token record to `.brain/logs/ingest-tokens.jsonl` | SS-02 | CAP-002 | P0 | active | ss-02/BC-2.02.003.md |
| BC-2.02.004 | `/brain:ingest-url` operates on manifest delta only (no full-corpus re-reads) | SS-02 | CAP-002 | P0 | active | ss-02/BC-2.02.004.md |
| BC-2.02.005 | `/brain:ingest-url` warns when source exceeds 50K-token chunk threshold | SS-02 | CAP-002 | P1 | active | ss-02/BC-2.02.005.md |
| BC-2.02.006 | `/brain:ingest-url` rejects already-ingested URL (source-immutability guard) | SS-02 | CAP-002 | P0 | active | ss-02/BC-2.02.006.md |
| BC-2.02.007 | `/brain:ingest-url` latency stays sub-linear as wiki grows 1K→10K pages | SS-02 | CAP-002 | P1 | active | ss-02/BC-2.02.007.md |

## ss-03: Source Ingest Pipeline (CAP-003)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.03.001 | `/brain:ingest-source` ingests a local file into `sources/{topic}/` and wiki layer | SS-03 | CAP-003 | P0 | active | ss-03/BC-2.03.001.md |
| BC-2.03.002 | `/brain:ingest-source` writes manifest delta entry on every successful ingest | SS-03 | CAP-003 | P0 | active | ss-03/BC-2.03.002.md |
| BC-2.03.003 | `/brain:ingest-source` rejects paths outside the brain vault root | SS-03 | CAP-003 | P0 | active | ss-03/BC-2.03.003.md |
| BC-2.03.004 | `/brain:ingest-source` propagates partial-failure fan-out (per-page results; no silent swallow) | SS-03 | CAP-003 | P0 | active | ss-03/BC-2.03.004.md |

## ss-04: Hook Enforcement Chain (CAP-004)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.04.001 | `quarantine-fetch.sh` blocks web content containing prompt-injection patterns (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.001.md |
| BC-2.04.002 | `validate-source-immutability.sh` blocks overwrite of existing source records (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.002.md |
| BC-2.04.003 | `validate-wikilink-integrity.sh` blocks wiki writes with broken wikilinks (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.003.md |
| BC-2.04.004 | `validate-frontmatter-schema.sh` blocks wiki writes missing `embedding_status` field (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.004.md |
| BC-2.04.005 | `validate-frontmatter-schema.sh` blocks wiki writes missing other mandatory fields (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.005.md |
| BC-2.04.006 | `validate-index-log-coherence.sh` blocks index/log writes that break coherence invariant (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.006.md |
| BC-2.04.007 | `validate-page-type-policy.sh` blocks wiki writes to invalid wiki type directories (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.007.md |
| BC-2.04.008 | `validate-voice-avoid-list.sh` advises on brief drafts containing voice-avoid-list terms (exit 1) | SS-04 | CAP-004 | P1 | active | ss-04/BC-2.04.008.md |
| BC-2.04.009 | `validate-source-id-citation.sh` blocks wiki writes with unresolved source citations (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.009.md |
| BC-2.04.010 | `validate-publish-state.sh` blocks invalid frontmatter state-machine transitions (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.010.md |
| BC-2.04.011 | `enforce-kebab-case.sh` blocks file writes with non-kebab-case filenames (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.011.md |
| BC-2.04.012 | `block-ai-attribution.sh` blocks bash commands containing AI attribution tokens (exit 2) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.012.md |
| BC-2.04.013 | `flush-state-and-commit.sh` commits brain state on session Stop (exit 0 or advisory) | SS-04 | CAP-004 | P1 | active | ss-04/BC-2.04.013.md |
| BC-2.04.014 | `brain-health-check.sh` surfaces six-dimensional convergence state on SessionStart (exit 0 or 1) | SS-04 | CAP-004 | P1 | active | ss-04/BC-2.04.014.md |
| BC-2.04.015 | Every hook processes its sample payload under 100ms p99 (performance budget) | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.015.md |
| BC-2.04.016 | Every hook reads JSON from stdin, writes JSON verdict to stdout, exits 0/1/2 only | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.016.md |
| BC-2.04.017 | Hook structured event emission: every hook emits JSONL events on stderr via hook-event catalog | SS-04 | CAP-004 | P0 | active | ss-04/BC-2.04.017.md |

## ss-05: Wiki Layer and Wikilink Integrity (CAP-005)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.05.001 | `/brain:lint-wiki` completes seven-check health pass in under 10 minutes on 10K-page wiki | SS-05 | CAP-005 | P0 | active | ss-05/BC-2.05.001.md |
| BC-2.05.002 | `/brain:lint-wiki` uses index-first lookup (O(n) scan, not O(n²) cross-product) | SS-05 | CAP-005 | P0 | active | ss-05/BC-2.05.002.md |
| BC-2.05.003 | `/brain:rename-page` renames wiki page and propagates all backlinks atomically | SS-05 | CAP-005 | P0 | active | ss-05/BC-2.05.003.md |
| BC-2.05.004 | `/brain:rename-page` rejects rename if old slug does not exist | SS-05 | CAP-005 | P0 | active | ss-05/BC-2.05.004.md |
| BC-2.05.005 | Wiki pages use `wiki/{type}/{slug}.md` path (6 types: concepts/people/frameworks/syntheses/observations/questions) | SS-05 | CAP-005 | P0 | active | ss-05/BC-2.05.005.md |
| BC-2.05.006 | `embedding_status` field is mandatory in all wiki page frontmatter from v0.1 | SS-05 | CAP-005 | P0 | active | ss-05/BC-2.05.006.md |

## ss-06: Source Layer and Immutability (CAP-006)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.06.001 | `sources/{topic}/{slug}.md` is immutable after creation (no overwrite without explicit rename flow) | SS-06 | CAP-006 | P0 | active | ss-06/BC-2.06.001.md |
| BC-2.06.002 | `manifest.json` schema supports `chunks` array from v0.1 (populated at v0.5+) | SS-06 | CAP-006 | P1 | active | ss-06/BC-2.06.002.md |
| BC-2.06.003 | `manifest.json` records `last_ingest` timestamps per source | SS-06 | CAP-006 | P0 | active | ss-06/BC-2.06.003.md |
| BC-2.06.004 | Sources directory uses 7 default topic categories scaffolded by `/brain:init` | SS-06 | CAP-006 | P1 | active | ss-06/BC-2.06.004.md |

## ss-07: Adversarial Review and Writescore (CAP-007)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.07.001 | `/brain:adversary-review` runs in a different model family than the producer agent | SS-07 | CAP-007 | P0 | active | ss-07/BC-2.07.001.md |
| BC-2.07.002 | `/brain:adversary-review` dispatches all four wclaude validation agents | SS-07 | CAP-007 | P0 | active | ss-07/BC-2.07.002.md |
| BC-2.07.003 | `/brain:adversary-review` implements multi-pass writescore revision loop | SS-07 | CAP-007 | P1 | active | ss-07/BC-2.07.003.md |
| BC-2.07.004 | `/brain:adversary-review` returns structured pass/fail verdict with finding list | SS-07 | CAP-007 | P0 | active | ss-07/BC-2.07.004.md |

## ss-08: Content Brief and Writing (CAP-008)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.08.001 | `/brain:brief` generates a content brief in ONE THING / PROOF / TRANSFORMATION format | SS-08 | CAP-008 | P0 | active | ss-08/BC-2.08.001.md |
| BC-2.08.002 | `/brain:write <brief-path>` produces a full piece in the author's voice from a brief path | SS-08 | CAP-008 | P0 | active | ss-08/BC-2.08.002.md |
| BC-2.08.003 | `/brain:write` supports `--companion-posts`, `--hero-prompt` flags | SS-08 | CAP-008 | P1 | active | ss-08/BC-2.08.003.md |
| BC-2.08.004 | Voice avoid-list (30 entries in `rules/voice-avoid-list.txt`) is enforced on brief drafts | SS-08 | CAP-008 | P1 | active | ss-08/BC-2.08.004.md |

## ss-09: Publishing Pipeline (CAP-009)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.09.001 | `/brain:publish-content` posts to LinkedIn via Posts API (Community Management) | SS-09 | CAP-009 | P0 | active | ss-09/BC-2.09.001.md |
| BC-2.09.002 | `/brain:publish-content` supports `--finalize --url "..."` for LinkedIn articles manual flow | SS-09 | CAP-009 | P1 | active | ss-09/BC-2.09.002.md |
| BC-2.09.003 | `/brain:publish-content` supports `--schedule <date>` flag | SS-09 | CAP-009 | P1 | active | ss-09/BC-2.09.003.md |
| BC-2.09.004 | Frontmatter state machine enforces `draft → ready → published` transitions | SS-09 | CAP-009 | P0 | active | ss-09/BC-2.09.004.md |
| BC-2.09.005 | `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` directory structure is maintained | SS-09 | CAP-009 | P0 | active | ss-09/BC-2.09.005.md |
| BC-2.09.006 | `/brain:monthly-perf` pulls performance data from LinkedIn Posts API and reports to `.brain/logs/` | SS-09 | CAP-009 | P1 | active | ss-09/BC-2.09.006.md |

## ss-10: Prompt-Injection Quarantine (CAP-010)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.10.001 | `/brain:quarantine-check <path>` scrubs prompt-injection patterns before content reaches tool-access session | SS-10 | CAP-010 | P0 | active | ss-10/BC-2.10.001.md |
| BC-2.10.002 | `quarantine-fetch.sh` fires on EVERY WebFetch call — cannot be bypassed by any skill | SS-10 | CAP-010 | P0 | active | ss-10/BC-2.10.002.md |
| BC-2.10.003 | Quarantine corpus patterns live in `scripts/quarantine.mjs` | SS-10 | CAP-010 | P0 | active | ss-10/BC-2.10.003.md |

## ss-11: Knowledge Synthesis and Connection (CAP-011)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.11.001 | `/brain:connect [days]` finds cross-domain connections across recent ingests | SS-11 | CAP-011 | P1 | active | ss-11/BC-2.11.001.md |
| BC-2.11.002 | `/brain:synthesize` builds a weekly thesis from the connection layer | SS-11 | CAP-011 | P1 | active | ss-11/BC-2.11.002.md |
| BC-2.11.003 | `/brain:process-inbox` classifies and routes inbox notes to correct wiki type | SS-11 | CAP-011 | P1 | active | ss-11/BC-2.11.003.md |

## ss-12: Lobster Runtime (CAP-012)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.12.001 | `bin/lobster-run` reads workflow YAML and executes skill steps in declared dependency order | SS-12 | CAP-012 | P0 | active | ss-12/BC-2.12.001.md |
| BC-2.12.002 | `bin/lobster-run` exits 0 (all steps succeed), 1 (advisory), 2 (any step blocks) | SS-12 | CAP-012 | P0 | active | ss-12/BC-2.12.002.md |
| BC-2.12.003 | Six workflow YAML files ship in `plugins/brain-factory/workflows/` | SS-12 | CAP-012 | P1 | active | ss-12/BC-2.12.003.md |
| BC-2.12.004 | `bin/lobster-run` supports headless execution (no interactive prompts) | SS-12 | CAP-012 | P0 | active | ss-12/BC-2.12.004.md |

## ss-13: GitHub Action Templates (CAP-013)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.13.001 | v0.1 core set (6 author-committed templates) ships and runs green on push | SS-13 | CAP-013 | P0 | active | ss-13/BC-2.13.001.md |
| BC-2.13.002 | v0.5 additions (9 author-committed templates) ship with matrix strategy parallelism | SS-13 | CAP-013 | P1 | active | ss-13/BC-2.13.002.md |
| BC-2.13.003 | Rate-limit handling: 429 responses trigger exponential backoff with `retry-after` respect | SS-13 | CAP-013 | P1 | active | ss-13/BC-2.13.003.md |
| BC-2.13.004 | 4 community-optional templates ship in tarball with no-author-support documentation | SS-13 | CAP-013 | P2 | active | ss-13/BC-2.13.004.md |

## ss-14: Plugin Lifecycle and Upgrade (CAP-014)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.14.001 | `/plugin install brain-factory@claude-mp` succeeds in a fresh Claude session | SS-14 | CAP-014 | P0 | active | ss-14/BC-2.14.001.md |
| BC-2.14.002 | `/brain:upgrade-brain` upgrades the plugin and migrates `.brain/` state if needed | SS-14 | CAP-014 | P1 | active | ss-14/BC-2.14.002.md |
| BC-2.14.003 | Engine files are read-only at runtime; state lives exclusively in target's `.brain/` | SS-14 | CAP-014 | P0 | active | ss-14/BC-2.14.003.md |
| BC-2.14.004 | `plugin.json` is valid JSON with semver version and all agents/skills registered | SS-14 | CAP-014 | P0 | active | ss-14/BC-2.14.004.md |
| BC-2.14.005 | `hooks.json.template` references all 13 hooks via `${CLAUDE_PLUGIN_ROOT}` | SS-14 | CAP-014 | P0 | active | ss-14/BC-2.14.005.md |

## ss-15: Governance and Policies (CAP-015)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.15.001 | `.brain/policies.yaml` is initialized with 10 baseline policies by `/brain:init` | SS-15 | CAP-015 | P1 | active | ss-15/BC-2.15.001.md |
| BC-2.15.002 | `/brain:policy-add` registers a new governance policy with schema validation | SS-15 | CAP-015 | P1 | active | ss-15/BC-2.15.002.md |
| BC-2.15.003 | `/brain:policy-registry-validate` validates all policies against the schema | SS-15 | CAP-015 | P1 | active | ss-15/BC-2.15.003.md |

## ss-16: Scale-Aware Architecture (CAP-016)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.16.001 | Token instrumentation: `/brain:ingest-url` writes JSONL record per invocation | SS-16 | CAP-016 | P0 | active | ss-16/BC-2.16.001.md |
| BC-2.16.002 | Token budget alert: `/brain:health` warns if 30-day trailing average exceeds 2x baseline | SS-16 | CAP-016 | P1 | active | ss-16/BC-2.16.002.md |
| BC-2.16.003 | GH Actions process 100 sources/day sustained over 5-day test run without data loss | SS-16 | CAP-016 | P1 | active | ss-16/BC-2.16.003.md |
| BC-2.16.004 | Peak resident memory for any single operation stays under 2GB | SS-16 | CAP-016 | P1 | active | ss-16/BC-2.16.004.md |
| BC-2.16.005 | Per-ingest token cost stays within 3x the 50K-token baseline at 10K-source corpus | SS-16 | CAP-016 | P1 | active | ss-16/BC-2.16.005.md |
| BC-2.16.006 | `scripts/gen-test-corpus.sh` generates reproducible synthetic corpus for scale test | SS-16 | CAP-016 | P1 | active | ss-16/BC-2.16.006.md |

## ss-17: Structured Event Catalog (CAP-017)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.17.001 | Every `hook-event:emit` site has a registered row in the structured event catalog | SS-17 | CAP-017 | P0 | active | ss-17/BC-2.17.001.md |
| BC-2.17.002 | Event catalog defines: event_type, hook_name, severity, fields, example payload | SS-17 | CAP-017 | P0 | active | ss-17/BC-2.17.002.md |
| BC-2.17.003 | Hooks emit JSONL on stderr; stdout is reserved for the JSON verdict only | SS-17 | CAP-017 | P0 | active | ss-17/BC-2.17.003.md |
| BC-2.17.004 | No hook emits tokens, API keys, or credential values to any output stream | SS-17 | CAP-017 | P0 | active | ss-17/BC-2.17.004.md |

## ss-18: Meta-Lint and Self-Audit (CAP-018)

| BC ID | Title | Subsystem | Capability | Priority | Status | File Path |
|-------|-------|-----------|------------|----------|--------|-----------|
| BC-2.18.001 | `meta-lint.bats` validates SKILL.md frontmatter and canonical 6-section structure | SS-18 | CAP-018 | P0 | active | ss-18/BC-2.18.001.md |
| BC-2.18.002 | `meta-lint.bats` validates hook scripts: shebang, `set -euo pipefail`, no bare exit, no eval | SS-18 | CAP-018 | P0 | active | ss-18/BC-2.18.002.md |
| BC-2.18.003 | `meta-lint.bats` validates AGENT.md scope + tool-profile + routing reference | SS-18 | CAP-018 | P0 | active | ss-18/BC-2.18.003.md |
| BC-2.18.004 | `meta-lint.bats` validates cross-cutting: no AI attribution, no `--no-verify`, no hardcoded template paths | SS-18 | CAP-018 | P0 | active | ss-18/BC-2.18.004.md |
| BC-2.18.005 | 9 bats test suites cover 13 hooks and all skills (positive + negative + edge case per hook) | SS-18 | CAP-018 | P0 | active | ss-18/BC-2.18.005.md |

---

## Self-Audit Checklist (five-file gate)

Per CLAUDE.md Canonical Principle and the inherited Phase 1a/1c structural-fix disciplines, the five-file gate must run clean before any commit touching behavioral contracts. Run:

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

**NOTE (exclusion-list-extension protocol — VSDD level designators):** BC files carry `level: L3` in frontmatter. This index carries `level: L3` in frontmatter. These are VSDD specification tier designators — not line-number anchors. Excluded via `grep -v 'level: L[0-9]+|Level [0-9]+|L2|L3|L4|LEVEL'` per the exclusion-list-extension protocol (a) add exclusion; (b) re-run gate — zero matches; (c) rationale: VSDD spec level designators are domain-standard tokens, not line-number anchors.

**NOTE (exclusion-list-extension protocol — architecture ID tokens):** This index references `SS-NN`, `CAP-NNN`, `NFR-NNN`, `ADR-NNN`, and `VP-NNN` patterns throughout. These are canonical spec identifiers — not line-number anchors. Added `grep -v 'SS-[0-9]+|CAP-[0-9]+|NFR-[0-9]+|ADR-[0-9]+|VP-[0-9]+'` per the exclusion-list-extension protocol. This exclusion is sibling-swept from the ARCH-INDEX five-file gate per TD-VSDD-060.

The gate must return zero output on all five files. ARCH-INDEX.md is the fifth file added per F-1c-CV-02 remediation (sibling-sweep with ARCH-INDEX canonical five-file gate per TD-VSDD-060).

**NOTE (exclusion-list-extension protocol):** To add a new token: (a) add to `grep -v` clause; (b) re-run gate; (c) record rationale here. Do NOT work around the gate by reverting the writing-technique principle.

---

## Changelog

### v0.1.4 (2026-05-16)

**STRUCTURAL FIX (F-PASS3-C1 — sibling-sweep BC-2.12.001 + BC-2.12.004 `.lobster` extension):** BC-2.12.001 Canonical Test Vector: `workflows/ingest-url.lobster` → `workflows/ingest-url.yaml`. BC-2.12.004 Canonical Test Vector: `workflow.lobster` → `workflow.yaml`. Both were missed in the Pass 2 Decision 1 sibling-sweep of BC-2.12.003.

**STRUCTURAL FIX (F-PASS3-C2 — BC-2.17.001 + BC-2.17.002 catalog location):** BC-2.17.001 Postconditions 1–2 updated to cite `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json` (JSON format). BC-2.17.002 EC-001 updated: `event-catalog.md` → `event-catalog.json`; EC-002: `example_payload` → `example`; VP-008 Proof Method: `(markdown table parse)` → `(JSON parse)`.

**STRUCTURAL FIX (F-PASS3-I3 — BC-2.16.005 non-canonical `--count` flag):** BC-2.16.005 EC-002: `gen-test-corpus.sh --seed 42 --count 10000` → `gen-test-corpus.sh --sources 10000 --seed 42 /tmp/test-brain` per ADR-012.

**STRUCTURAL FIX (F-PASS3-I4 — BC-2.06.003 VP-012 anchor label):** BC-2.06.003 VP Anchors: `Manifest schema integrity` → `Manifest write atomicity and last_ingest field correctness` per VP-012 canonical H1 title.

### v0.1.3 (2026-05-16)

**STRUCTURAL FIX (F-PASS2-C1 — event_type past-tense sibling-sweep):** BC-2.04.002 event_type values corrected to past-tense (`source.immutability.violated`, `source.added`). BC-2.04.003 through BC-2.04.014 received explicit event_type enumeration per BC-2.04.017 universal requirement. All use `<domain>.<past-tense-verb>` per SS-17 §Event-type naming convention.

**STRUCTURAL FIX (F-PASS2-C4 — BC-2.17.002 SS-17 schema alignment):** Catalog location, format, fields, and event_type pattern corrected to match SS-17 architecture.

**STRUCTURAL FIX (F-PASS2-I3 — BC-2.13.003 api-retry path):** `scripts/api-retry.sh` → `scripts/lib/api-retry.sh`.

**STRUCTURAL FIX (F-PASS2-I7 — policies template filename):** `templates/policies-yaml-template.yaml` → `templates/policies.yaml` in BC-2.15.001 and BC-2.01.001.

**STRUCTURAL FIX (F-PASS2-I8 — BC-2.08.003 companion-posts count):** "3–5 files" → "3 files" throughout BC-2.08.003.

**STRUCTURAL FIX (Decision 1 — BC-2.12.003 workflow filenames + extension):** `.lobster` → `.yaml`; six canonical filenames per ADR-006: `ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`, `weekly-refresh.yaml`, `scale-test.yaml`.

**STRUCTURAL FIX (Decision 3 — BC-2.06.003 VP coverage):** VP-012 (Group 2) added to Verification Properties and VP Anchors; "(no direct VP — P0; VP gap noted)" removed.

### v0.1.2 (2026-05-16)

**STRUCTURAL FIX (F-PASS1-I10 — VP-TBD backfill):** All 95 BC files updated: VP-TBD placeholders replaced with actual VP IDs from VP-INDEX v0.1.1 P0 Coverage Matrix. BCs with VP coverage cite the VP-NNN directly in Verification Properties table and VP Anchors section. BCs with no VP coverage (P1/P2) replaced VP-TBD with `(no VP — P1/P2; deferred per VP-INDEX coverage policy)`. One P0 VP gap noted: BC-2.06.003 has no direct VP in VP-INDEX v0.1.1; gap noted pending VP-INDEX v0.1.2 (architect scope).

**STRUCTURAL FIX (F-PASS1-C1 + F-PASS1-C2 + F-PASS1-C3 + F-PASS1-I2 + F-PASS1-I4 — BC body fixes):** BC-2.13.001 template names corrected to ADR-013 canonical set; BC-2.16.006 CLI updated to ADR-012 interface; BC-2.04.017 helper path corrected to `hooks/lib/`; BC-2.04.001 event_type updated to past-tense (`quarantine.blocked`/`quarantine.allowed`); BC-2.01.001 hard-fail behavior made explicit for already-initialized brain. See PRD v0.1.3 changelog for details.

### v0.1.1 (2026-05-15)

**STRUCTURAL FIX (F-1c-CV-02 + F-1c-CV-07 closure):** SS-NN backfill in BC-INDEX Subsystem column matches architect's Subsystem Registry in `architecture/ARCH-INDEX.md`; Self-Audit Checklist gate extended from four-file to five-file (sibling-sweep with ARCH-INDEX gate per TD-VSDD-060, adding `architecture/ARCH-INDEX.md` as fifth file and the architecture ID token exclusion `SS-NN|CAP-NNN|NFR-NNN|ADR-NNN|VP-NNN`). Opening blockquote updated to reflect Phase 1c SS-NN assignment completion.

### v0.1.0 (2026-05-15)

**STRUCTURAL FIX (F-1b-CV-01 — BC sharding integrity):** Created this index as the canonical sharding index over all 95 BC files per DF-020a criterion 22. Added `traces_to: ../BC-INDEX.md` to all 95 BC frontmatter blocks. Extended the Self-Audit Checklist gate from a three-file gate to a four-file gate (brief + handoff + prd/index.md + BC-INDEX.md).
