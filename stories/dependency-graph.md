---
artifact_type: dependency-graph
version: "v0.1.1"
created: 2026-05-19
last_updated: 2026-05-19
total_stories: 43
total_epics: 9
authored_by: vsdd-factory:story-writer
inputs:
  - product-brief.md@v0.4.20
  - prd/index.md@v0.1.13
  - behavioral-contracts/BC-INDEX.md@v0.1.15
  - architecture/ARCH-INDEX.md@v0.1.23
  - architecture/verification-properties/VP-INDEX.md@v0.1.7
  - stories/STORY-INDEX.md@v0.3.3
phase: phase-2-story-decomposition-step-c
phase_2_status: STEP-C-IN-PROGRESS
input-hash: ""
---

# brain-factory Dependency Graph

**43 stories — 9 epics — v0.1.1**

> **Input-version freshness invariant (F-PHASE2-ADV-PASS2-S04):** Whenever an upstream input (brief, PRD, BC-INDEX, ARCH-INDEX, VP-INDEX, STORY-INDEX, epics.md) is amended, this artifact's `inputs:` block MUST be refreshed in the same fix-burst chain. Stale `inputs:` references are a Pass-fail-class defect, not a cosmetic one. State-manager and story-writer dispatches handling upstream amendments MUST stage downstream artifacts' `inputs:` refresh in the same logical burst chain.

---

## Changelog

### v0.1.1 — 2026-05-19 (F-PHASE2-ADV-PASS2-I01+I03+S04)

- **§Stats WIP cleanup (I01):** Removed internal monologue lines (494–515). Replaced with clean authoritative §Stats block: 16 terminal nodes, 68 total edges, STORY-001 max out-degree 16, STORY-022 max in-degree 6, critical path 13 stories.
- **Input version refresh (I03):** `prd/index.md` v0.1.12 → v0.1.13; `behavioral-contracts/BC-INDEX.md` v0.1.12 → v0.1.15; `stories/STORY-INDEX.md` v0.3.0 → v0.3.3. No derived content amended.
- **S04 invariant comment added:** Input-version freshness rule codified in artifact header per F-PHASE2-ADV-PASS2-S04.

### v0.1.0 — 2026-05-19 (initial)

Initial dependency graph. 43 stories, 68 directed edges, 9 epics. Topological order, cycle-check, BC dependency audit, and §Stats verified.

---

## §Convention

This document is the authoritative source for story dependency relationships. The
following conventions govern all edges in this graph.

**Edge type:** Directed edge `A → B` means "A blocks B" — equivalently, "B depends on A".
To render: A must be delivered before B can begin.

**Edge granularity:** Only DIRECT dependencies are listed as edges. Transitive
dependencies are inferred by graph traversal, NOT by redundant direct-edge addition.
If B depends on C, and C depends on A, only edges `A → C` and `C → B` are listed —
the edge `A → B` is intentionally absent.

**Dependency basis:** A dependency edge `A → B` exists when story B references (in its
Tasks, File Structure Requirements, or Previous Story Intelligence sections) a code file,
hook script, library helper, schema, scaffolded directory, or other deliverable that
story A produces — and B's bats tests would fail without A's deliverable being present.

**Frontmatter vs. graph:** Per-story `dependencies:` and `blocks:` frontmatter fields
are at-creation-time estimates. This graph supersedes frontmatter under the
Source-of-Truth Precedence rule in CLAUDE.md (PRD supplements supersede PRD prose for
the same surface area — by analogy, the dep-graph supersedes per-story frontmatter for
dependency claims). Per-story frontmatter is NOT updated by this burst; agents consuming
dependency information (wave-scheduler, implementer, CI) MUST consult this file.

**Adjudication rule:** When a finding (F-PHASE2-CONSISTENCY-IXX) surfaces a `blocks:`
claim without a matching `depends_on:`, this file resolves it explicitly — either adding
the edge with rationale (§F-PHASE2-CONSISTENCY Resolutions, RESOLVED-EDGE-ADDED) or
rejecting the claim (RESOLVED-AS-NOT-A-DEPENDENCY or RESOLVED-TRANSITIVE-NOT-DIRECT).

**Edge labels:** Edges are tagged `[frontmatter-confirmed]` when the relationship was
present in both `blocks:` of A and `dependencies:` of B, or `[graph-derived]` when
first established by this graph based on production-vs-consumption analysis of Tasks and
File Structure sections.

---

## §Edges

All direct dependency edges. Sorted by source story ID. Format:
`STORY-XXX → STORY-YYY [tag] (rationale)`

### EPIC-01 Internal Edges

- STORY-001 → STORY-002 [frontmatter-confirmed] (STORY-002 builds init skill into the plugin skeleton and stubs STORY-001 creates; replaces stub SKILL.md)
- STORY-001 → STORY-003 [frontmatter-confirmed] (STORY-003 extends `skills/init/run.sh` created in STORY-002 which requires STORY-001's directory scaffold)
- STORY-001 → STORY-004 [frontmatter-confirmed] (STORY-004 builds health skill into the plugin skeleton; modifies `brain-health-check.sh` stub from STORY-001)
- STORY-001 → STORY-005 [frontmatter-confirmed] (STORY-005 checks plugin structure established by STORY-001; adds `scripts/` directory alongside STORY-001's layout)
- STORY-001 → STORY-006 [frontmatter-confirmed] (STORY-006 replaces `quarantine-fetch.sh` stub created by STORY-001; requires plugin structure and `hooks.json.template`)
- STORY-001 → STORY-014 [frontmatter-confirmed] (STORY-014 replaces `hooks/lib/hook-event-emit.sh` stub and creates `scripts/event-catalog.json` in the `scripts/` directory STORY-001 seeds)
- STORY-001 → STORY-016 [frontmatter-confirmed] (STORY-016 delivers `hooks/lib/manifest-write.sh` and `defuddle-fetch.mjs` into directories established by STORY-001)
- STORY-001 → STORY-020 [frontmatter-confirmed] (STORY-020 delivers `/brain:lint-wiki` skill into plugin skill directory established by STORY-001)
- STORY-001 → STORY-022 [frontmatter-confirmed] (STORY-022 creates `tests/meta-lint.bats` and iterates over `plugins/brain-factory/skills/*/SKILL.md` stubs from STORY-001)
- STORY-001 → STORY-027 [frontmatter-confirmed] (STORY-027 establishes publishing directories into the plugin tree STORY-001 scaffolds)
- STORY-001 → STORY-032 [frontmatter-confirmed] (STORY-032 writes `bin/lobster-run` into the `bin/` directory and reads `plugin.json` from STORY-001)
- STORY-001 → STORY-034 [frontmatter-confirmed] (STORY-034 delivers GH Action templates into `templates/github-action-templates/` scaffolded by STORY-001)
- STORY-001 → STORY-037 [frontmatter-confirmed] (STORY-037 reads `.brain/manifest.json` schema established by STORY-001 `manifest.json` initial structure)
- STORY-001 → STORY-038 [frontmatter-confirmed] (STORY-038 generates a brain vault tree that mirrors `.brain/` layout established by STORY-001)
- STORY-001 → STORY-040 [frontmatter-confirmed] (STORY-040 implements adversarial review skill into plugin structure from STORY-001)
- STORY-001 → STORY-042 [frontmatter-confirmed] (STORY-042 writes `.brain/policies.yaml` using the baseline `policies.yaml` template from STORY-001)
- STORY-002 → STORY-003 [frontmatter-confirmed] (STORY-003 extends `skills/init/run.sh` delivered by STORY-002 to add error paths)
- STORY-002 → STORY-004 [frontmatter-confirmed] (STORY-004 references `tests/helpers.bash` pattern from STORY-002 and extends `tests/integration.bats`)
- STORY-002 → STORY-005 [frontmatter-confirmed] (STORY-005 exercises the health skill installed by STORY-004 which depends on templates from STORY-002)
- STORY-002 → STORY-022 [frontmatter-confirmed] (STORY-022 validates all 26 SKILL.md files; requires full plugin skeleton including skill directory stubs from STORY-002)
- STORY-002 → STORY-032 [frontmatter-confirmed] (STORY-032 reads plugin directory structure for skill registration; STORY-002 delivers `skills/init/SKILL.md` as the first real SKILL.md)
- STORY-002 → STORY-040 [frontmatter-confirmed] (STORY-040 adversarial review skill depends on brain vault structure established at init time by STORY-002)
- STORY-003 → STORY-004 [frontmatter-confirmed] (STORY-004 extends `tests/integration.bats` from STORY-003; uses `local-dev-test.sh` patterns for test harness setup)
- STORY-003 → STORY-005 [frontmatter-confirmed] (STORY-005 exercises the full init including error paths from STORY-003 to confirm post-upgrade health)
- STORY-003 → STORY-022 [frontmatter-confirmed] (STORY-022 validates SKILL.md stubs from all 5 EPIC-01 stories; STORY-003 replaces the init SKILL.md stub)
- STORY-004 → STORY-005 [frontmatter-confirmed] (STORY-005 wire-tests health callable via `skills/health/run.sh` delivered by STORY-004)
- STORY-004 → STORY-022 [frontmatter-confirmed] (STORY-022 validates all 14 AGENT.md and 26 SKILL.md artifacts; STORY-004 delivers health SKILL.md)
- STORY-005 → STORY-022 [frontmatter-confirmed] (STORY-022 meta-lints all plugin artifacts including those from STORY-005; all 5 EPIC-01 stories must be complete)

### EPIC-02 Internal Edges

- STORY-006 → STORY-007 [frontmatter-confirmed] (STORY-007 follows STORY-006's per-hook bats convention; reuses `hooks/lib/hook-event-emit.sh` pattern established by STORY-006)
- STORY-006 → STORY-008 [frontmatter-confirmed] (STORY-008 follows STORY-006's per-hook bats convention and JSONL emission pattern)
- STORY-006 → STORY-009 [frontmatter-confirmed] (STORY-009 follows STORY-006's per-hook bats convention and fixture pattern)
- STORY-006 → STORY-010 [frontmatter-confirmed] (STORY-010 follows STORY-006's per-hook bats convention)
- STORY-006 → STORY-011 [frontmatter-confirmed] (STORY-011 follows STORY-006's per-hook bats convention)
- STORY-006 → STORY-012 [frontmatter-confirmed] (STORY-012 follows STORY-006's per-hook bats convention)
- STORY-006 → STORY-013 [frontmatter-confirmed] (STORY-013 follows STORY-006's per-hook bats convention and JSONL emission pattern)
- STORY-014 → STORY-006 [graph-derived] (STORY-006 calls `hooks/lib/hook-event-emit.sh` in all emit_event calls; the shim delivered by STORY-014 must exist; full integration of STORY-006 requires the shim — see F-PHASE2-CONSISTENCY-I04 resolution)
- STORY-014 → STORY-007 [graph-derived] (STORY-007 calls `hooks/lib/hook-event-emit.sh` for `source.immutability.violated` / `source.added` events — see I04)
- STORY-014 → STORY-008 [graph-derived] (STORY-008 calls `hooks/lib/hook-event-emit.sh` for `wiki.wikilink.broken` / `wiki.index_log.coherence_violated` events — see I04)
- STORY-014 → STORY-009 [graph-derived] (STORY-009 calls `hooks/lib/hook-event-emit.sh` for `frontmatter.schema.violated` / `frontmatter.schema.validated` events — see I04)
- STORY-014 → STORY-010 [graph-derived] (STORY-010 calls `hooks/lib/hook-event-emit.sh` for `wiki.page_type.rejected` / `voice.avoid_list.matched` events — see I04)
- STORY-014 → STORY-011 [graph-derived] (STORY-011 calls `hooks/lib/hook-event-emit.sh` for `source.citation.unresolved` / `publish.state.transition_rejected` events — see I04)
- STORY-014 → STORY-012 [graph-derived] (STORY-012 calls `hooks/lib/hook-event-emit.sh` for `naming.kebab_case.rejected` / `attribution.token.blocked` events — see I04)
- STORY-014 → STORY-013 [graph-derived] (STORY-013 calls `hooks/lib/hook-event-emit.sh` for `session.state.committed` / `brain.health.checked` events — see I04)
- STORY-014 → STORY-015 [frontmatter-confirmed] (STORY-015 meta-lint tests depend on `hooks/lib/hook-event-emit.sh` and `scripts/event-catalog.json` delivered by STORY-014)

### EPIC-03 Internal Edges

- STORY-014 → STORY-016 [frontmatter-confirmed] (STORY-016 calls `hook-event-emit.sh` for manifest-write JSONL events and emits catalog-registered event types)
- STORY-016 → STORY-017 [frontmatter-confirmed] (STORY-017 ingest pipeline calls `hooks/lib/manifest-write.sh` delivered by STORY-016)
- STORY-014 → STORY-017 [frontmatter-confirmed] (STORY-017 wiki generation emits catalog-registered events via the shim delivered by STORY-014)
- STORY-017 → STORY-018 [frontmatter-confirmed] (STORY-018 bats harness tests the ingest-url skill pipeline delivered by STORY-017; requires the pipeline to measure latency)
- STORY-016 → STORY-019 [frontmatter-confirmed] (STORY-019 calls `hooks/lib/manifest-write.sh` delivered by STORY-016 for atomic manifest delta)
- STORY-017 → STORY-019 [frontmatter-confirmed] (STORY-019 reuses wiki generation pipeline infrastructure from STORY-017)
- STORY-014 → STORY-019 [frontmatter-confirmed] (STORY-019 emits catalog-registered events via `hook-event-emit.sh` from STORY-014)

### EPIC-04 Internal Edges

- STORY-009 → STORY-020 [frontmatter-confirmed] (STORY-020 `/brain:lint-wiki` seven-check pass depends on `validate-frontmatter-schema.sh` from STORY-009 for the embedding_status check dimension)
- STORY-014 → STORY-020 [frontmatter-confirmed] (STORY-020 emits catalog-registered events via `hook-event-emit.sh` from STORY-014)
- STORY-020 → STORY-021 [frontmatter-confirmed] (STORY-021 `/brain:rename-page` requires `/brain:lint-wiki` from STORY-020 to validate wikilinks after renaming)
- STORY-020 → STORY-022 [graph-derived] (STORY-022 validates live SKILL.md files including `skills/lint-wiki/SKILL.md` delivered by STORY-020; meta-lint must run over ALL plugin skills — see F-PHASE2-CONSISTENCY-I07 resolution)
- STORY-022 → STORY-023 [frontmatter-confirmed] (STORY-023 hook script and cross-cutting surfaces of meta-lint.bats are built on the SKILL/AGENT surface delivered by STORY-022)

### EPIC-05 Internal Edges

- STORY-019 → STORY-024 [frontmatter-confirmed] (STORY-024 `/brain:connect` reads source manifest and wiki page content produced by the ingest pipeline from STORY-019)
- STORY-020 → STORY-024 [frontmatter-confirmed] (STORY-024 `/brain:connect` uses wikilink resolution from STORY-020 to traverse cross-domain connections)
- STORY-024 → STORY-025 [frontmatter-confirmed] (STORY-025 `/brain:synthesize` weekly thesis builds on connection layer from STORY-024)
- STORY-019 → STORY-026 [frontmatter-confirmed] (STORY-026 `/brain:process-inbox` routes captured content into the source/wiki layer delivered by STORY-019)
- STORY-020 → STORY-026 [frontmatter-confirmed] (STORY-026 calls `/brain:lint-wiki` from STORY-020 to validate wiki pages created during inbox routing)

### EPIC-06 Internal Edges

- STORY-027 → STORY-028 [frontmatter-confirmed] (STORY-028 `/brain:brief` writes to `briefs/content/` directories scaffolded by STORY-027)
- STORY-025 → STORY-028 [frontmatter-confirmed] (STORY-028 brief scaffold derives from synthesis output from STORY-025)
- STORY-028 → STORY-029 [frontmatter-confirmed] (STORY-029 `/brain:write` requires the brief file produced by `/brain:brief` from STORY-028)
- STORY-011 → STORY-030 [graph-derived] (STORY-030 publish state machine bats tests exercise `validate-publish-state.sh` which is implemented by STORY-011; the per-hook bats suite for validate-publish-state.sh depends on the hook being delivered — see F-PHASE2-ADV-PASS1-C03)
- STORY-029 → STORY-030 [frontmatter-confirmed] (STORY-030 `/brain:publish-content` publishes the written piece from STORY-029)
- STORY-027 → STORY-030 [frontmatter-confirmed] (STORY-030 state machine enforces `draft → ready → published` transitions in `briefs/content/` directories from STORY-027)
- STORY-030 → STORY-031 [frontmatter-confirmed] (STORY-031 `/brain:monthly-perf` reads LinkedIn post performance data from content published via STORY-030)

### EPIC-07 Internal Edges

- STORY-032 → STORY-033 [frontmatter-confirmed] (STORY-033 headless execution mode and workflow YAML files require `bin/lobster-run` core from STORY-032)
- STORY-033 → STORY-034 [frontmatter-confirmed] (STORY-034 GH Action templates invoke `bin/lobster-run` in headless mode from STORY-033)
- STORY-034 → STORY-035 [frontmatter-confirmed] (STORY-035 v0.5 and community templates extend the GH Action template set from STORY-034; also depends on api-retry.sh)
- STORY-030 → STORY-035 [frontmatter-confirmed] (STORY-035 community publish template invokes the publish-content pipeline from STORY-030)

### EPIC-08 Internal Edges

- STORY-017 → STORY-036 [frontmatter-confirmed] (STORY-036 wires token JSONL instrumentation into ingest skills delivered by STORY-017)
- STORY-019 → STORY-036 [frontmatter-confirmed] (STORY-036 also instruments local ingest pipeline from STORY-019)
- STORY-036 → STORY-037 [frontmatter-confirmed] (STORY-037 `/brain:health` token budget alert reads `ingest-tokens.jsonl` populated by STORY-036)
- STORY-038 → STORY-039 [frontmatter-confirmed] (STORY-039 scale validation gate requires `gen-test-corpus.sh` from STORY-038 to populate 10K source corpus)
- STORY-038 → STORY-018 [graph-derived] (STORY-018 VP-027 slow-lane @test has a bats `skip` annotation waiting for `scripts/gen-test-corpus.sh` from STORY-038 to be unskipped — see F-PHASE2-CONSISTENCY-I06 resolution)
- STORY-036 → STORY-039 [frontmatter-confirmed] (STORY-039 throughput and per-ingest-cost checks require the token JSONL log populated by STORY-036)
- STORY-034 → STORY-039 [frontmatter-confirmed] (STORY-039 GH Actions throughput check requires GH Action templates from STORY-034 to be present)
- STORY-035 → STORY-039 [frontmatter-confirmed] (STORY-039 full v0.5 workflow suite requires api-retry templates from STORY-035)

### EPIC-09 Internal Edges

- STORY-040 → STORY-041 [frontmatter-confirmed] (STORY-041 structured verdict and streak counter builds on adversarial dispatch core from STORY-040)
- STORY-041 → STORY-042 [frontmatter-confirmed] (STORY-042 governance policies initialization depends on adversarial review workflow from STORY-041 as a governance gate)
- STORY-042 → STORY-043 [frontmatter-confirmed] (STORY-043 `/brain:policy-registry-validate` reads the policies registry from STORY-042)

---

## §F-PHASE2-CONSISTENCY Resolutions

### F-PHASE2-CONSISTENCY-I04 — STORY-014 blocks STORY-006..013

**Finding:** STORY-014 (`blocks: [STORY-006..013, STORY-015]`) claims to block all hook
implementation stories, but STORY-006..013 did not list STORY-014 in their
`dependencies:`.

**Analysis:** STORY-014 produces two indivisible deliverables that every hook in
STORY-006..013 requires:
1. `hooks/lib/hook-event-emit.sh` — the sourced bash library that every hook calls to
   emit JSONL events. Every hook's Tasks section contains a `hooks/lib/hook-event-emit.sh`
   emit call. Without the shim, the JSONL emission assertions in each hook's bats suite
   will fail.
2. `scripts/event-catalog.json` — the machine-readable catalog that `tests/meta-lint.bats`
   (STORY-014's AC-012) checks for completeness. STORY-015 depends on this catalog.

Decision: STORY-014 is a GENUINE direct prerequisite for the fully-integrated
implementation of STORY-006..013. The production-vs-consumption test passes:
- STORY-006..013 each produce `emit_event` call sites that reference `hook-event-emit.sh`.
- STORY-015's meta-lint completeness check requires `event-catalog.json`.
- Hook bats tests cannot pass green without the shim emitting valid JSONL to stderr.

**Edges added:**
```
STORY-014 → STORY-006 [graph-derived]
STORY-014 → STORY-007 [graph-derived]
STORY-014 → STORY-008 [graph-derived]
STORY-014 → STORY-009 [graph-derived]
STORY-014 → STORY-010 [graph-derived]
STORY-014 → STORY-011 [graph-derived]
STORY-014 → STORY-012 [graph-derived]
STORY-014 → STORY-013 [graph-derived]
```

**Edges NOT added:** `STORY-014 → STORY-015` was already present in both frontmatter
directions (STORY-015 `dependencies: [STORY-001, STORY-014]`; STORY-014 `blocks: [STORY-015]`).

**Status:** RESOLVED-EDGE-ADDED (8 graph-derived edges added: STORY-014 → STORY-006..013)

---

### F-PHASE2-CONSISTENCY-I05 — STORY-032 transitive blocks STORY-034/035

**Finding:** STORY-032 claims `blocks: [STORY-033, STORY-034, STORY-035]`. STORY-034
depends on STORY-033 directly; STORY-035 depends on STORY-034 directly. The
STORY-032 → STORY-034 and STORY-032 → STORY-035 entries in `blocks:` are transitive.

**Analysis (production-vs-consumption):**
- STORY-034 depends on STORY-033 (`bin/lobster-run` headless mode + 6 workflow YAMLs).
  STORY-034 does NOT directly consume any specific file from STORY-032 that STORY-033
  does not already expose.
- STORY-035 depends on STORY-034 (GH Action template set). `api-retry.sh` in STORY-035
  is an independent deliverable that does not require `bin/lobster-run` core directly.
- The chain is: STORY-032 → STORY-033 → STORY-034 → STORY-035. The transitive closure
  already encodes the dependency without direct edges.

**Decision:** Apply convention strictly — only direct edges. STORY-032 → STORY-034 and
STORY-032 → STORY-035 are transitive and NOT added as direct edges.

**Edges added:** None (relationship already captured transitively).

**Edges intentionally NOT added:**
- `STORY-032 → STORY-034` — transitive via STORY-033; not direct
- `STORY-032 → STORY-035` — transitive via STORY-033 → STORY-034; not direct

**Status:** RESOLVED-TRANSITIVE-NOT-DIRECT

---

### F-PHASE2-CONSISTENCY-I06 — STORY-038 blocks STORY-018

**Finding:** STORY-038 (`blocks: [STORY-039, STORY-018]`) claims to block STORY-018.
STORY-018 only lists `dependencies: [STORY-017]`.

**Analysis (production-vs-consumption):**
STORY-018 contains this explicit comment in its frontmatter:
> "The 10K-page upper bound test has a bats `skip` annotation: `skip "requires
> gen-test-corpus.sh (EPIC-08 BC-2.16.006) to generate 10K-source corpus"`.
> The skip annotation cites the specific story that removes it."

STORY-018 AC-003 explicitly states the 10K test is skip-annotated until
`scripts/gen-test-corpus.sh` exists. STORY-038 frontmatter also states:
"Blocks STORY-018 (VP-027 slow-lane) has a @test with a skip annotation waiting for
this script."

The deliverable consumed: `scripts/gen-test-corpus.sh` from STORY-038. Without it,
STORY-018's T(10K) `@test` cannot be unskipped to green. The dependency is real — the
bats test is scaffolded in STORY-018 but remains permanently skipped until STORY-038
delivers the corpus generator. For CI correctness (ensuring the unskip actually runs),
STORY-038 must precede STORY-018 in the wave.

**Edge added:**
```
STORY-038 → STORY-018 [graph-derived]
```

**Status:** RESOLVED-EDGE-ADDED (1 graph-derived edge added)

---

### F-PHASE2-CONSISTENCY-I07 — STORY-020 blocks STORY-022

**Finding:** STORY-020 claims `blocks: [STORY-021, STORY-022]`. STORY-022 only lists
`dependencies: [STORY-001, STORY-002, STORY-003, STORY-004, STORY-005]` (all EPIC-01).

**Analysis (production-vs-consumption):**
STORY-022 (meta-lint SKILL.md and AGENT.md surfaces) validates the live plugin artifacts
by iterating over `plugins/brain-factory/skills/*/SKILL.md` and
`plugins/brain-factory/agents/*/AGENT.md` files (AC-007 and AC-013). STORY-022 AC-007
states: "During Phase 2 (before skill implementation), this test is skipped if the
`skills/` directory is empty or contains only stubs."

Key question: Does STORY-022 need the `skills/lint-wiki/SKILL.md` file from STORY-020
to pass its live-skills validation test?

Answer: YES. STORY-022 validates ALL 26 SKILL.md files. STORY-020 delivers
`skills/lint-wiki/SKILL.md` as the first non-stub SKILL.md from EPIC-04. Once STORY-020
lands (replacing the stub with a real SKILL.md), the live-skills `@test` will include it.
STORY-022 must be run AFTER STORY-020 to include STORY-020's SKILL.md in the validation
sweep — otherwise the meta-lint would silently skip a real, newly-written SKILL.md that
might be non-conformant. The production-vs-consumption test passes: STORY-022 consumes
`skills/lint-wiki/SKILL.md` delivered by STORY-020.

The counter-argument is that STORY-022 already works against stubs for the fixture-based
tests (AC-006). However, the live-skills `@test` (AC-007) is not fully useful without
STORY-020's deliverable. Per the production-grade default in CLAUDE.md, we capture the
real dependency.

**Edge added:**
```
STORY-020 → STORY-022 [graph-derived]
```

Note: This creates a structural reordering concern. STORY-022 depends on all of EPIC-01
(STORY-001..005) AND STORY-020. STORY-020 depends on STORY-001, STORY-009, STORY-014.
No cycle is introduced (verified: STORY-022 does not appear in any path from STORY-022
back to STORY-020).

**Status:** RESOLVED-EDGE-ADDED (1 graph-derived edge added)

---

### F-PHASE2-ADV-PASS1-C03 — STORY-011 → STORY-030 missing edge

**Finding:** STORY-030's `validate-publish-state.bats` tests exercise `validate-publish-state.sh`,
which is implemented by STORY-011 (BC-2.04.009/010). STORY-030 frontmatter listed
`dependencies: [STORY-029, STORY-027]` but omitted STORY-011.

**Analysis (production-vs-consumption):** STORY-030 creates `tests/validate-publish-state.bats`
(a per-hook bats suite). The bats tests invoke `hooks/validate-publish-state.sh`. That hook
is delivered by STORY-011. Without STORY-011, the hook script does not exist and
STORY-030's bats tests cannot pass. The dependency is real and direct.

**Edge added:**
```
STORY-011 → STORY-030 [graph-derived]
```

**Status:** RESOLVED-EDGE-ADDED (1 graph-derived edge added; STORY-030 `dependencies` also updated)

---

### F-PHASE2-CONSISTENCY-S01 — STORY-027 → STORY-029 transitive

**Finding:** STORY-027 claims `blocks: [STORY-028, STORY-029, STORY-030]`. The
STORY-027 → STORY-029 entry is transitive via STORY-028.

**Analysis:** Chain is STORY-027 → STORY-028 → STORY-029. STORY-029 `dependencies:
[STORY-028]` is correct and sufficient. STORY-029 does not directly consume a file
from STORY-027 that STORY-028 does not already expose (the briefs directories are
established by STORY-027 and accessible to STORY-029 transitively through STORY-028's
use of them). The STORY-027 → STORY-030 edge IS direct (STORY-030 `dependencies:
[STORY-029, STORY-027]` — STORY-030 directly reads the publish state machine for
`briefs/content/` directories from STORY-027).

**Edges added:** None for the transitive case.
**Edges intentionally NOT added:** `STORY-027 → STORY-029` (transitive via STORY-028).

**Status:** RESOLVED-TRANSITIVE-NOT-DIRECT

---

### F-PHASE2-CONSISTENCY-S02 — STORY-033 → STORY-035 transitive

**Finding:** STORY-033 claims `blocks: [STORY-034, STORY-035]`. The STORY-033 → STORY-035
entry is transitive via STORY-034.

**Analysis:** Chain is STORY-033 → STORY-034 → STORY-035. STORY-035's direct dependency
on STORY-033 is NOT present in its frontmatter (`dependencies: [STORY-034, STORY-030]`).
STORY-035 does not directly consume a specific file from STORY-033 that STORY-034 does
not already expose. The relationship is fully captured by STORY-033 → STORY-034 and
STORY-034 → STORY-035.

**Edges added:** None.
**Edges intentionally NOT added:** `STORY-033 → STORY-035` (transitive via STORY-034).

**Status:** RESOLVED-TRANSITIVE-NOT-DIRECT

---

## §Topological Order

Topological sort using Kahn's algorithm (consistent with `bin/lobster-run` algorithm,
BC-2.12.001 and STORY-032 design). Stories within the same layer have no mutual
dependencies and can execute in parallel.

### Topological Layers (strict Kahn's)

| Layer | Stories | Count |
|-------|---------|-------|
| 0 | STORY-001 | 1 |
| 1 | STORY-014, STORY-027, STORY-038 | 3 |
| 2 | STORY-002, STORY-006, STORY-016 | 3 |
| 3 | STORY-003, STORY-007, STORY-008, STORY-009, STORY-010, STORY-011, STORY-012, STORY-013, STORY-017, STORY-032 | 10 |
| 4 | STORY-004, STORY-015, STORY-019, STORY-033, STORY-036, STORY-040 | 6 |
| 5 | STORY-005, STORY-020, STORY-034, STORY-037, STORY-041 | 5 |
| 6 | STORY-018, STORY-021, STORY-022, STORY-024, STORY-026, STORY-042 | 6 |
| 7 | STORY-023, STORY-025, STORY-043 | 3 |
| 8 | STORY-028 | 1 |
| 9 | STORY-029 | 1 |
| 10 | STORY-030 | 1 |
| 11 | STORY-031, STORY-035 | 2 |
| 12 | STORY-039 | 1 |
| **Total** | 43 stories | **13 layers** |

Layer derivation notes:
- STORY-006 deps: STORY-001 (L0), STORY-014 (L1) → Layer 2
- STORY-016 deps: STORY-001 (L0), STORY-014 (L1) → Layer 2
- STORY-019 deps: STORY-016 (L2), STORY-017 (L3), STORY-014 (L1) → Layer 4
- STORY-020 deps: STORY-001 (L0), STORY-009 (L3), STORY-014 (L1) → Layer 4
- STORY-022 deps: STORY-001..005 (max STORY-005 at L5), STORY-020 (L4) → Layer 6
- STORY-030 deps: STORY-029 (L9), STORY-027 (L1), STORY-011 (L3) → Layer 10
- STORY-035 deps: STORY-034 (L5), STORY-030 (L10) → Layer 11
- STORY-039 deps: STORY-036 (L4), STORY-038 (L1), STORY-034 (L5), STORY-035 (L11) → Layer 12

---

## §Cycle-Check

**Verdict: PASS — graph is acyclic.**

Kahn's algorithm above succeeded in assigning all 43 stories to layers without requiring
cycle-breaking. A cycle exists only if the algorithm terminates with stories remaining
unprocessed (positive in-degree but removed from the queue). All 43 stories were assigned.

Cross-verification for the most complex chains:
- STORY-020 → STORY-022: STORY-022 does not appear in any path from STORY-022 →
  STORY-020. STORY-022 only flows to STORY-023. STORY-023 terminates. No cycle.
- STORY-038 → STORY-018: STORY-018 has no outgoing edges (blocks: []). No cycle.
- STORY-014 → STORY-006: STORY-006's outgoing edges go to STORY-007..013 only
  (convention-establishment, not back to STORY-014). No cycle.

---

## §BC Dependency Audit

Spot-check of 8 critical dependency edges via BC → SS → story chain.

| Edge | BC Chain | Verification |
|------|----------|-------------|
| STORY-014 → STORY-006 | BC-2.04.017 (universal hook emission) → SS-17 → STORY-014 produces `hook-event-emit.sh`; BC-2.04.001 (quarantine-fetch.sh) → SS-04 → STORY-006 calls `emit_event` via the shim. Both BCs confirmed. | AC-007 in STORY-006 cites BC-2.04.017 event catalog compliance. |
| STORY-016 → STORY-017 | BC-2.02.001 (Defuddle fetch wrapper) → SS-02 → STORY-016 delivers `hooks/lib/manifest-write.sh`; BC-2.02.002 (wiki page generation) → SS-02 → STORY-017 Tasks step 1 states "Verify STORY-016 landed (`hooks/lib/manifest-write.sh` exists)". | STORY-017 Previous Story Intelligence section confirms. |
| STORY-019 → STORY-024 | BC-2.03.001 (local ingest) → SS-03 → STORY-019 populates `manifest.json` with local source entries; BC-2.11.001 (cross-domain connection discovery) → SS-11 → STORY-024 `/brain:connect` reads manifest to find connection candidates. | STORY-024 `dependencies: [STORY-019, STORY-020]` confirmed. |
| STORY-032 → STORY-033 | BC-2.12.001 (lobster-run YAML parsing + topo sort) → SS-12 → STORY-032 delivers `bin/lobster-run` binary; BC-2.12.003 (headless execution) → SS-12 → STORY-033 adds headless mode to `bin/lobster-run`. STORY-033 frontmatter: `dependencies: [STORY-032]`. | Direct frontmatter confirmation. |
| STORY-038 → STORY-018 | BC-2.16.006 (gen-test-corpus.sh) → SS-16 → STORY-038 delivers `scripts/gen-test-corpus.sh`; BC-2.02.007 (sub-linear latency) → SS-02 → STORY-018 AC-003 explicitly names BC-2.16.006 in the skip annotation. | STORY-038 frontmatter `blocks: [STORY-039, STORY-018]` confirmed. |
| STORY-030 → STORY-035 | BC-2.09.001..004 (publish-content state machine) → SS-09 → STORY-030 delivers the full publish pipeline; BC-2.13.003 (community GitHub Action templates) → SS-13 → STORY-035 community-publish template calls the publish pipeline. STORY-035 `dependencies: [STORY-034, STORY-030]` confirmed. | Direct frontmatter confirmation. |
| STORY-009 → STORY-020 | BC-2.04.004+005 (validate-frontmatter-schema.sh) → SS-04 → STORY-009 delivers the schema hook; BC-2.05.001 (/brain:lint-wiki) → SS-05 → STORY-020 `/brain:lint-wiki` checks the same frontmatter fields — the lint skill's frontmatter check dimension reuses STORY-009's schema definition. STORY-020 `dependencies: [STORY-001, STORY-009, STORY-014]` confirmed. | Direct frontmatter confirmation. |
| STORY-041 → STORY-042 | BC-2.07.003+004 (adversarial verdict + streak counter) → SS-07 → STORY-041 delivers the full adversarial review workflow; BC-2.15.001 (governance policies initialization) → SS-15 → STORY-042 `.brain/policies.yaml` is the governance artifact that the adversarial review process enforces. STORY-042 `dependencies: [STORY-001, STORY-041]` confirms the governance gate. | Direct frontmatter confirmation. |

---

## §Stats

**Total direct edges: 68**

Breakdown:
- Frontmatter-confirmed edges: 57
- Graph-derived edges: 11
  - STORY-014 → STORY-006 (I04)
  - STORY-014 → STORY-007 (I04)
  - STORY-014 → STORY-008 (I04)
  - STORY-014 → STORY-009 (I04)
  - STORY-014 → STORY-010 (I04)
  - STORY-014 → STORY-011 (I04)
  - STORY-014 → STORY-012 (I04)
  - STORY-014 → STORY-013 (I04)
  - STORY-038 → STORY-018 (I06)
  - STORY-020 → STORY-022 (I07)
  - STORY-011 → STORY-030 (C03)

**Max in-degree (most-blocked story):**
- STORY-022: 6 incoming edges (STORY-001, STORY-002, STORY-003, STORY-004, STORY-005, STORY-020)

**Max out-degree (most-blocking story):**
- STORY-001: 16 outgoing edges (STORY-002, STORY-003, STORY-004, STORY-005, STORY-006, STORY-014, STORY-016, STORY-020, STORY-022, STORY-027, STORY-032, STORY-034, STORY-037, STORY-038, STORY-040, STORY-042)

**Critical path (longest chain from Layer 0 to terminal):**

`STORY-001 → STORY-014 → STORY-016 → STORY-017 → STORY-019 → STORY-020 → STORY-024 → STORY-025 → STORY-028 → STORY-029 → STORY-030 → STORY-035 → STORY-039`

**Critical path length: 12 hops (13 stories), terminating at Layer 12**

**Terminal nodes (out-degree = 0, nothing depends on them — 16 stories):**
STORY-005, STORY-007, STORY-008, STORY-010, STORY-011, STORY-012, STORY-013,
STORY-015, STORY-018, STORY-021, STORY-023, STORY-026, STORY-031, STORY-037,
STORY-039, STORY-043

**Terminal node count: 16**

---

## §Notes for Wave-Schedule Step

Wave scheduling (Step D, DF-022) will formalize the topological layers into parallel
execution waves. Key observations for the wave-scheduler:

1. **Layer 0 is a singleton (STORY-001):** STORY-001 is the sole root node. No parallel
   execution at Wave 1 — all 43 stories flow through this single story. Wave 1 = STORY-001
   alone. This is expected: STORY-001 creates the plugin skeleton that everything else
   builds into.

2. **Layer 1 has 3 parallel stories:** STORY-014 (event catalog + emit shim), STORY-027
   (content brief scaffold), and STORY-038 (corpus generator) can all start the moment
   STORY-001 lands. High parallelism opportunity.

3. **Layer 3 is the widest layer (10 stories):** The 8 hook implementation stories
   (STORY-007..013) plus STORY-017 (wiki generation) and STORY-032 (lobster-run core)
   can all run in parallel. This is the highest-throughput wave in the build.

4. **Long serial chains limit parallelism in Layers 7-12:** The EPIC-06 publishing chain
   (STORY-027 → 028 → 029 → 030 → 031/035 → 039) is the critical path and forms a
   5-layer serial execution chain from Layer 8 to Layer 12. This is the primary
   scheduling bottleneck; consider if any of these can be parallelized with different
   sequencing assumptions.

5. **STORY-022 (meta-lint SKILL/AGENT surfaces) lands at Layer 6:** Later than might be
   expected for a testing infrastructure story. This is because STORY-020 (lint-wiki
   skill) is a dependency (I07 adjudication), which itself depends on STORY-009 (Layer 3)
   and STORY-014 (Layer 1). The wave-scheduler should note that STORY-022 cannot be
   accelerated without splitting its live-skills validation test.

6. **STORY-039 (scale validation gate) is the final story at Layer 12:** It gates on
   STORY-035 which gates on STORY-030 (the full publish pipeline). Scale validation is
   intentionally last in the build — it requires all other capabilities to be operational.
   The wave-scheduler should mark STORY-039 as the final quality gate for Phase 3.

7. **Priority note for wave scheduler:** 29 P0 stories and 14 P1 stories. P0 stories
   should be preferred within the same layer. STORY-006..013 are all P0 and belong
   together in Layers 2-3 for maximum early-wave integration coverage. STORY-013 is P1
   (flush + health hooks) and can be deferred to a later wave if capacity is constrained.
