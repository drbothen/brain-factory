---
artifact_type: wave-schedule
version: "v0.1.2"
created: 2026-05-19
last_updated: 2026-05-19
authored_by: vsdd-factory:story-writer
inputs:
  - dependency-graph.md@v0.1.0
  - stories/STORY-INDEX.md@v0.3.2
  - behavioral-contracts/BC-INDEX.md@v0.1.14
  - architecture/ARCH-INDEX.md@v0.1.23
  - product-brief.md@v0.4.20
  - stories/epics.md@v0.1.1
total_waves: 11
total_stories: 43
total_points: 264
phase: phase-2-story-decomposition-step-d
phase_2_status: STEP-D-IN-PROGRESS
---

# brain-factory Wave Schedule

**11 waves — 43 stories — 264 points**

Source: dependency-graph.md v0.1.0 (canonical for all inter-story dependency claims).

---

## Changelog

### v0.1.2 — 2026-05-19 (F-PHASE2-ADV-PASS1-I04)

- **Input version refresh (I04):** `behavioral-contracts/BC-INDEX.md` updated v0.1.13 → v0.1.14; `stories/STORY-INDEX.md` updated v0.3.1 → v0.3.2. No wave content amended.

### v0.1.1 — 2026-05-19 (F-PHASE2-DECOMP-GATE-I02c+S01+S02)

- **W1 P0/P1 correction (I02c):** P0: 1→2, P1: 3→2 (STORY-001 and STORY-014 are both P0; STORY-027 and STORY-038 are both P1 per frontmatter).
- **W6 P0/P1 correction (I02c):** P0: 3→4, P1: 2→1 (STORY-020, STORY-034, STORY-041, STORY-005 are P0; STORY-037 is P1 per frontmatter).
- **Footer P0/P1 correction (I02c):** Total P0: 27→29, P1: 16→14 per full story frontmatter scan.
- **§P0 vs P1 Distribution removed (I02c):** Paragraph described a discrepancy that was caused by the incorrect table values; removed now that the table is correct.
- **Critical path 12-story → 13-story (S01):** Updated in §Convention (critical-path description) and §Critical-Path Summary. Correct chain is 13 stories: STORY-001, 014, 016, 017, 019, 020, 024, 025, 028, 029, 030, 035, 039.
- **W3 terminal nodes 5→6 (S02):** Added STORY-013 to terminal node list (007,008,010,011,012,013). STORY-013 has `terminal_node: true` in sprint-state.yaml per dep-graph.
- **Input version refresh:** BC-INDEX updated v0.1.12→v0.1.13; STORY-INDEX updated v0.3.0→v0.3.1.

---

## §Convention

### What is a Wave?

A wave is the primary unit of planned work in the brain-factory TDD pipeline. All
stories within a wave are dependency-safe: no story in the wave depends on another
story in the same wave (unless explicitly documented via `wave_position` ordering — see
below). In a multi-developer context, all stories in a wave could be implemented in
parallel. In the brain-factory solo-dev context, waves define focus units implemented
sequentially.

### Wave Granularity

Adjacent topological layers are collapsed into a single wave when ALL of the
following hold:

1. No story in a later layer within the proposed wave depends on a story in an earlier
   layer within the same proposed wave (or when such dependencies are documented with
   explicit `wave_position` ordering for solo-dev sequential execution within the wave).
2. The combined wave size remains manageable for the target team size (see Wave-Size
   Guidance below).
3. Collapsing the layers does not misrepresent implementation readiness (e.g., a story
   at Layer N that blocks many Layer N+1 stories should not be buried in the same wave
   as those dependents).

### Wave-Size Guidance

**Solo-dev / small-team context:** brain-factory is presently a solo-developer project.
For solo-dev, waves of 3-5 stories are the sweet spot. Waves larger than 6-7 stories
dilute focus. Waves of 1 story are acceptable when dictated by the dependency graph
(especially in the serial tail of the critical path). The parallelism benefit of larger
waves is less important than the focus benefit of smaller waves in the solo-dev context.

**Target range:** 3-6 stories / 20-40 points per wave (solo-dev).

### Wave-Position Ordering within a Wave

When a wave contains an intra-wave sequential chain (Story A must complete before
Story B within the same wave), this is captured via `wave_position` in sprint-state.yaml
rather than splitting into separate waves. The implementer works through the wave in
`wave_position` order. The `wave_position` ordering is advisory for solo-dev; it is
mandatory for CI gates.

This pattern is used in Wave 9 (publishing chain: STORY-028 → STORY-029 → STORY-030),
where the three-story chain forms a natural sequential sprint that does not benefit from
wave-splitting.

### Critical-Path Priority within Waves

Stories on the critical path (the 13-story chain
`STORY-001 → STORY-014 → STORY-016 → STORY-017 → STORY-019 → STORY-020 → STORY-024 →
STORY-025 → STORY-028 → STORY-029 → STORY-030 → STORY-035 → STORY-039`) must be
assigned `wave_position: 1` (first) within their wave. Finishing critical-path stories
first minimizes end-to-end schedule time.

### Terminal Node Candidates for Holdout Evaluation

Terminal nodes (out-degree = 0 in the dependency graph — 16 stories) are natural
holdout-evaluation candidates because completing a terminal node exercises a full
capability slice end-to-end. The 16 terminal nodes are:
STORY-005, STORY-007, STORY-008, STORY-010, STORY-011, STORY-012, STORY-013,
STORY-015, STORY-018, STORY-021, STORY-023, STORY-026, STORY-031, STORY-037,
STORY-039, STORY-043.

Waves that complete multiple terminal nodes are marked "holdout-eligible."

### Source-of-Truth Precedence

Wave assignment derives from dependency-graph.md v0.1.0. When wave assignment requires
reasoning about dependencies, the dep-graph is authoritative. Per-story `dependencies:`
and `blocks:` frontmatter fields are at-creation-time estimates that the dep-graph
supersedes (see dep-graph §Convention and CLAUDE.md Source-of-Truth Precedence rule).

---

## §Wave Inventory

---

### Wave 1 — Plugin Foundation (4 stories / 21 points)

**Wave goal:** Establish the plugin skeleton, event catalog infrastructure, content
publishing directories, and corpus generator script. Completing Wave 1 makes all 42
remaining stories buildable (every story depends on STORY-001 directly or transitively).

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-001 | 5 | P0 | EPIC-01 | Plugin repo structure, plugin.json, hooks.json.template | — | bats: plugin structure assertions |
| STORY-014 | 5 | P0 | EPIC-02 | Structured event catalog + hook-event-emit.sh shim | STORY-001 | bats: emit_event JSONL, catalog JSON |
| STORY-027 | 3 | P1 | EPIC-06 | Content brief directories + voice avoid-list file | STORY-001 | bats: directory existence, yaml fixture |
| STORY-038 | 8 | P1 | EPIC-08 | scripts/gen-test-corpus.sh reproducible corpus generator | STORY-001 | bats: corpus generation, hash stability |

**Wave critical-path note:** STORY-001 must be `wave_position: 1` — it creates the
plugin skeleton. STORY-014, STORY-027, and STORY-038 are mutually independent and can
follow in any order (positions 2-4). STORY-014 is critical-path; implement it
immediately after STORY-001.

**Wave dependencies:** None (STORY-001 has no predecessors).

**Wave exit criteria:** All 4 stories committed, all bats green, shellcheck clean,
meta-lint passes on plugin skeleton. STORY-001 bats confirms directory structure.
STORY-014 bats confirms hook-event-emit.sh emits valid JSONL. STORY-038 bats confirms
corpus generator produces stable hashes.

---

### Wave 2 — Core Init Skill + Quarantine + Defuddle (3 stories / 24 points)

**Wave goal:** Implement the first real skill (init), the first hook (quarantine-fetch),
and the Defuddle content-fetch wrapper. Completing Wave 2 gives the plugin its core
installation, source ingestion gateway, and manifest-write infrastructure.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-002 | 8 | P0 | EPIC-01 | /brain:init core — directory scaffold, templates, manifest.json | STORY-001 | bats: init end-to-end, manifest.json shape |
| STORY-006 | 8 | P0 | EPIC-02 | Quarantine corpus + quarantine-fetch.sh hook + /brain:quarantine-check | STORY-001, STORY-014 | bats: quarantine hook JSONL, exit codes |
| STORY-016 | 8 | P0 | EPIC-03 | Defuddle fetch wrapper + duplicate guard + atomic manifest-write helper | STORY-001, STORY-014 | bats: defuddle wrapper, manifest-write atomic |

**Wave critical-path note:** STORY-016 is critical-path (`wave_position: 1` recommended).
STORY-002 and STORY-006 are parallel with STORY-016 but should also start immediately
(both P0). All three stories are independent of each other within this wave.

**Wave dependencies:** All on Wave 1 (STORY-001 + STORY-014).

**Wave exit criteria:** All 3 stories committed, all bats green, `manifest-write.sh`
helper functional (STORY-016 AC verified), quarantine-fetch.sh exits with correct codes
(STORY-006 bats), `/brain:init` creates complete brain directory tree (STORY-002 bats).

---

### Wave 3 — Hook Enforcement Chain (8 stories / 32 points)

**Wave goal:** Implement the full hook enforcement chain: init error paths plus all 7
enforcement hooks (source immutability, wikilink integrity, frontmatter schema, page type
policy, source citation, publish state, filename/attribution). Completing Wave 3 locks
down the brain vault's integrity contracts.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-003 | 5 | P0 | EPIC-01 | /brain:init error handling, SLA assertion, briefs/research/ scaffold | STORY-001, STORY-002 | bats: error path exit codes, SLA bats |
| STORY-007 | 3 | P0 | EPIC-02 | validate-source-immutability.sh: block source overwrite | STORY-001, STORY-006, STORY-014 | bats: per-hook, exit 2 on overwrite |
| STORY-008 | 5 | P0 | EPIC-02 | validate-wikilink-integrity.sh + validate-index-log-coherence.sh | STORY-006, STORY-014 | bats: per-hook, broken link detection |
| STORY-009 | 5 | P0 | EPIC-02 | validate-frontmatter-schema.sh: embedding_status + mandatory fields | STORY-006, STORY-014 | bats: per-hook, schema validation |
| STORY-010 | 3 | P0 | EPIC-02 | validate-page-type-policy.sh + validate-voice-avoid-list.sh | STORY-006, STORY-014 | bats: per-hook, page-type gate + voice advisory |
| STORY-011 | 5 | P0 | EPIC-02 | validate-source-id-citation.sh + validate-publish-state.sh | STORY-006, STORY-014 | bats: per-hook, citation check + state machine |
| STORY-012 | 3 | P0 | EPIC-02 | enforce-kebab-case.sh + block-ai-attribution.sh | STORY-006, STORY-014 | bats: per-hook, filename gate + attribution block |
| STORY-013 | 3 | P1 | EPIC-02 | flush-state-and-commit.sh + brain-health-check.sh: Stop/Start hooks | STORY-006, STORY-014 | bats: per-hook, Stop commit + Start banner |

**Wave critical-path note:** No critical-path stories in this wave. All 8 stories are
parallel (no intra-wave dependencies). Implement in P0-first order. STORY-013 is P1 and
can be last if capacity is constrained.

**Wave dependencies:** STORY-003 depends on STORY-002 (W2). STORY-007..013 depend on
STORY-006 and STORY-014 (both W1/W2). All Wave 2 stories must be complete before
Wave 3 begins.

**Wave exit criteria:** All 8 hook scripts committed with per-hook bats suites green.
Each hook exits with correct POSIX exit code (0/1/2) per BC-2.04.015/016. Each hook
emits JSONL events matching event-catalog.json entries. shellcheck + shfmt clean on all
8 scripts.

---

### Wave 4 — Wiki Generation + Lobster Core + Health + Hook Meta-Lint (4 stories / 26 points)

**Wave goal:** Implement wiki page generation pipeline, lobster-run YAML parser/topo-sort,
the health skill's six dimensions, and the hook performance/canonical-I/O meta-lint
gates. Wave 4 closes out the content ingestion pipeline and the core automation runtime.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-017 | 8 | P0 | EPIC-03 | Wiki page generation pipeline + token JSONL logging + 50K-chunk warning | STORY-014, STORY-016 | bats: wiki gen output, JSONL log, chunk warn |
| STORY-032 | 8 | P0 | EPIC-07 | bin/lobster-run — YAML parsing, topological sort, exit-code contract | STORY-001, STORY-002 | bats: lobster-run topo-sort, exit codes |
| STORY-004 | 5 | P1 | EPIC-01 | /brain:health six-dimensional convergence skill | STORY-001, STORY-002, STORY-003 | bats: health skill, all 6 dimensions |
| STORY-015 | 5 | P0 | EPIC-02 | Hook meta-lint: performance budget, canonical I/O, fail-closed, credentials | STORY-001, STORY-014 | bats: meta-lint hook checks, budget assertions |

**Wave critical-path note:** STORY-017 is critical-path (`wave_position: 1`). STORY-032,
STORY-004, and STORY-015 are parallel with STORY-017 and with each other. Implement
STORY-017 first to unblock Wave 5's STORY-019.

**Wave dependencies:** STORY-017 depends on STORY-014 (W1) and STORY-016 (W2).
STORY-032 depends on STORY-001 (W1) and STORY-002 (W2). STORY-004 depends on STORY-001
(W1), STORY-002 (W2), and STORY-003 (W3). STORY-015 depends on STORY-001 (W1) and
STORY-014 (W1). All Wave 3 stories must be complete before Wave 4 begins.

**Wave exit criteria:** STORY-017 wiki generation produces conformant markdown with token
JSONL. STORY-032 `bin/lobster-run` passes topo-sort bats and handles cycle detection.
STORY-004 health skill passes all 6 dimension checks. STORY-015 meta-lint bats enforce
performance budget (BC-2.04.015).

---

### Wave 5 — Source Ingest + Lobster Headless + Token Write + Adversary Core (4 stories / 26 points)

**Wave goal:** Implement local source ingest with partial-failure fan-out, lobster-run
headless execution with 6 workflow YAMLs, token JSONL instrumentation wired into both
ingest skills, and the adversarial review core dispatch. Wave 5 completes the ingest
pipeline and automation orchestration backbone.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-019 | 8 | P0 | EPIC-03 | Local source ingest: path validation, manifest delta, wiki gen, partial-failure fan-out | STORY-014, STORY-016, STORY-017 | bats: local ingest, manifest delta, fan-out |
| STORY-033 | 5 | P0 | EPIC-07 | bin/lobster-run headless execution + six workflow YAML files | STORY-032 | bats: headless mode, YAML file validation |
| STORY-036 | 5 | P0 | EPIC-08 | Token JSONL instrumentation wired into ingest skills | STORY-017, STORY-019 | bats: JSONL log written, fields present |
| STORY-040 | 8 | P0 | EPIC-09 | Adversarial review core dispatch — cognitive diversity gate + four-agent validation | STORY-001, STORY-002 | bats: dispatch exit codes, verdict structure |

**Wave critical-path note:** STORY-019 is critical-path (`wave_position: 1`). STORY-033,
STORY-036, and STORY-040 are parallel with STORY-019 and with each other. Note:
STORY-036 depends on both STORY-017 and STORY-019; since STORY-019 is in this same
wave, STORY-036 must be implemented AFTER STORY-019 (implement STORY-036 with
`wave_position: 4`). STORY-033 and STORY-040 are fully independent of STORY-019 and
STORY-036 within this wave.

**Wave dependencies:** STORY-019 depends on STORY-014 (W1), STORY-016 (W2), STORY-017
(W4). STORY-033 depends on STORY-032 (W4). STORY-036 depends on STORY-017 (W4) and
STORY-019 (this wave — implement last). STORY-040 depends on STORY-001 (W1) and
STORY-002 (W2). All Wave 4 stories must be complete before Wave 5 begins.

**Wave exit criteria:** STORY-019 local ingest handles partial-failure fan-out correctly
per BC-2.03.002. STORY-033 headless mode runs 6 workflow YAMLs via `bin/lobster-run`.
STORY-036 JSONL instrumentation visible in ingest output. STORY-040 adversarial dispatch
invokes four-agent validation with correct cognitive diversity gate.

---

### Wave 6 — Install + Lint-Wiki + GH Templates + Health Alerts + Adversary Verdict (5 stories / 37 points)

**Wave goal:** Deliver the plugin install skill, the wiki lint seven-check pass, the
first batch of 6 GitHub Action templates, token budget alerts in the health skill, and
the adversarial verdict + streak counter. Wave 6 delivers the first user-visible
automation templates and the complete quality-gate workflow.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-005 | 5 | P0 | EPIC-01 | Plugin install from marketplace + tarball completeness + /brain:upgrade-brain | STORY-001, STORY-002, STORY-003, STORY-004 | bats: install, tarball integrity, upgrade |
| STORY-020 | 8 | P0 | EPIC-04 | /brain:lint-wiki seven-check health pass with O(n) index-first wikilink resolution | STORY-001, STORY-009, STORY-014 | bats: seven checks, O(n) wikilink resolution |
| STORY-034 | 8 | P0 | EPIC-07 | v0.1 core GH Action templates (6) + /brain:install-actions skill | STORY-033 | bats: template structure, install-actions |
| STORY-037 | 8 | P1 | EPIC-08 | Token budget alert in /brain:health + source immutability invariant + manifest chunks | STORY-036 | bats: health alert threshold, invariant check |
| STORY-041 | 8 | P0 | EPIC-09 | Adversarial verdict structure + streak counter + writescore multi-pass loop | STORY-040 | bats: verdict JSON schema, streak counter |

**Wave critical-path note:** STORY-020 is critical-path (it blocks STORY-024 in Wave 7,
which blocks the publishing chain). Implement STORY-020 first (`wave_position: 1`).
STORY-034 is also on the long EPIC-07 → STORY-039 critical path. STORY-005, STORY-037,
and STORY-041 are parallel.

**Wave dependencies:** STORY-005 depends on all EPIC-01 (STORY-001..004, W1-W4).
STORY-020 depends on STORY-001 (W1), STORY-009 (W3), STORY-014 (W1). STORY-034 depends
on STORY-033 (W5). STORY-037 depends on STORY-036 (W5). STORY-041 depends on
STORY-040 (W5). All Wave 5 stories must be complete before Wave 6 begins.

**Wave exit criteria:** STORY-005 tarball install validated. STORY-020 O(n) wikilink
resolution bats green (BC-2.05.005 index-first algorithm). STORY-034 six GH Action
templates present and structurally valid. STORY-037 health skill emits alert when token
log exceeds budget. STORY-041 adversarial streak counter resets to 0 on any finding.

**Holdout eligible:** Wave 6 completion enables holdout scenarios for EPIC-01 (install
flow), EPIC-02 (hook chain), EPIC-04 (lint-wiki), and EPIC-07 initial templates.

---

### Wave 7 — Bats Scale Harness + Rename + Meta-Lint SKILL/AGENT + Connect + Inbox + Policies Init (6 stories / 33 points)

**Wave goal:** Complete the sub-linear bats scale gate, rename-page atomic backlink skill,
meta-lint SKILL/AGENT validation surface, cross-domain connection discovery, inbox routing,
and governance policies initialization. Wave 7 closes out the first half of the dependency
graph and enables the synthesis and publishing chain.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-018 | 5 | P1 | EPIC-03 | Sub-linear ingest latency gate: bats scale assertion at 1K and 10K pages | STORY-017, STORY-038 | bats: T(1K) < 20s, T(10K) unskipped |
| STORY-021 | 5 | P0 | EPIC-04 | /brain:rename-page — atomic backlink propagation with existence + slug guards | STORY-020 | bats: rename + backlink update, guard failures |
| STORY-022 | 8 | P0 | EPIC-04 | meta-lint.bats SKILL.md and AGENT.md validation surfaces | STORY-001..005, STORY-020 | bats: meta-lint SKILL/AGENT checks |
| STORY-024 | 5 | P1 | EPIC-05 | /brain:connect — cross-domain connection discovery | STORY-019, STORY-020 | bats: connection discovery, manifest reads |
| STORY-026 | 5 | P1 | EPIC-05 | /brain:process-inbox — inbox classification and wiki routing | STORY-019, STORY-020 | bats: inbox routing, lint-wiki call |
| STORY-042 | 5 | P1 | EPIC-09 | Governance policies initialization — .brain/policies.yaml with 10 baseline policies | STORY-001, STORY-041 | bats: policies.yaml shape, 10 policies |

**Wave critical-path note:** STORY-024 is critical-path (blocks STORY-025 in Wave 8,
which is on the publishing chain). Implement STORY-024 first (`wave_position: 1`).
STORY-022 has the highest in-degree (6 incoming edges) and is a quality gate — implement
second. Remaining stories are parallel.

**Wave dependencies:** STORY-018 depends on STORY-017 (W4) and STORY-038 (W1).
STORY-021 depends on STORY-020 (W6). STORY-022 depends on STORY-001..005 (W1-W6) and
STORY-020 (W6). STORY-024 depends on STORY-019 (W5) and STORY-020 (W6). STORY-026
depends on STORY-019 (W5) and STORY-020 (W6). STORY-042 depends on STORY-001 (W1) and
STORY-041 (W6). All Wave 6 stories must be complete before Wave 7 begins.

**Wave exit criteria:** STORY-018 T(1K) bats assertion green; T(10K) skip annotation
removed (gen-test-corpus.sh from W1 available). STORY-021 atomic rename with backlink
propagation bats verified. STORY-022 meta-lint iterates 26 SKILL.md files including
STORY-020's lint-wiki SKILL.md. STORY-024 connection discovery reads manifest correctly.
STORY-026 inbox routing calls /brain:lint-wiki for created pages. STORY-042 .brain/
policies.yaml created with 10 baseline policies.

**Holdout eligible:** Wave 7 completion enables holdout scenarios for EPIC-03 (ingest
scale), EPIC-04 (rename + meta-lint), and EPIC-05 (connection + inbox).

---

### Wave 8 — Hook Meta-Lint + Synthesize + Policy Ops (3 stories / 18 points)

**Wave goal:** Complete the hook-script meta-lint surface (bats completeness gate),
the synthesis skill (weekly thesis from connection layer), and governance policy
management operations. Wave 8 closes the meta-testing and synthesis layers.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-023 | 8 | P0 | EPIC-04 | meta-lint.bats hook script + cross-cutting surfaces + per-hook bats completeness gate | STORY-022 | bats: hook surface checks, completeness gate |
| STORY-025 | 5 | P1 | EPIC-05 | /brain:synthesize — weekly thesis from connection layer | STORY-024 | bats: synthesis output, weekly thesis shape |
| STORY-043 | 5 | P1 | EPIC-09 | /brain:policy-add + /brain:policy-registry-validate | STORY-042 | bats: policy-add idempotent, validate exit codes |

**Wave critical-path note:** STORY-025 is critical-path (blocks STORY-028 in Wave 9,
the start of the publishing chain). Implement STORY-025 first (`wave_position: 1`).
STORY-023 and STORY-043 are parallel with STORY-025 and with each other.

**Wave dependencies:** STORY-023 depends on STORY-022 (W7). STORY-025 depends on
STORY-024 (W7). STORY-043 depends on STORY-042 (W7). All Wave 7 stories must be
complete before Wave 8 begins.

**Wave exit criteria:** STORY-023 per-hook bats completeness gate passes (every hook
in `hooks/` has a corresponding `.bats` file). STORY-025 weekly thesis skill produces
structured output from STORY-024's connection layer. STORY-043 policy-add is idempotent
and policy-registry-validate exits 0/2 correctly.

**Holdout eligible:** Wave 8 completion enables holdout scenarios for EPIC-04 (full
meta-lint surface), EPIC-05 (synthesis), and EPIC-09 (governance).

---

### Wave 9 — Brief Skill + Write Skill + Publish Pipeline (3 stories / 21 points)

**Wave goal:** Implement the full content-production pipeline: content brief (ONE THING /
PROOF / TRANSFORMATION), full-piece writing in author's voice with companion posts, and
the publish-content state machine with LinkedIn API integration. Wave 9 is the critical
publishing chain; implement sequentially in wave_position order.

**Note on intra-wave sequencing:** This wave contains an explicit dependency chain:
STORY-028 → STORY-029 → STORY-030. For solo-dev, implement in `wave_position` order
(1=STORY-028, 2=STORY-029, 3=STORY-030). Do NOT begin STORY-029 until STORY-028's bats
are green. Do NOT begin STORY-030 until STORY-029's bats are green.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves or earlier in wave) | Test Surface |
|----------|--------|----------|------|------|----------------------------------------------|--------------|
| STORY-028 | 5 | P0 | EPIC-06 | /brain:brief — ONE THING / PROOF / TRANSFORMATION content brief | STORY-027 (W1), STORY-025 (W8) | bats: brief file shape, fields present |
| STORY-029 | 8 | P0 | EPIC-06 | /brain:write — full piece in author's voice + companion posts + hero prompt | STORY-028 (this wave) | bats: write output shape, companion posts |
| STORY-030 | 8 | P0 | EPIC-06 | /brain:publish-content — state machine, LinkedIn API, scheduling, finalize flow | STORY-029 (this wave), STORY-027 (W1) | bats: state machine transitions, API mock |

**Wave critical-path note:** STORY-028 is critical-path (`wave_position: 1`, must be
first). STORY-029 is critical-path (`wave_position: 2`). STORY-030 is critical-path
(`wave_position: 3`, must be last). These are sequential; no parallelism within this
wave.

**Wave dependencies:** STORY-028 depends on STORY-027 (W1) and STORY-025 (W8).
STORY-029 depends on STORY-028 (this wave). STORY-030 depends on STORY-029 (this wave)
and STORY-027 (W1). All Wave 8 stories must be complete before Wave 9 begins.

**Wave exit criteria:** STORY-028 brief file passes schema bats. STORY-029 write output
includes full piece, companion posts, and hero prompt. STORY-030 state machine enforces
`draft → ready → published` transitions (BC-2.09.001) and LinkedIn API mock bats green.

**Holdout eligible:** Wave 9 completion enables holdout scenarios for EPIC-06 (full
content production pipeline). This is a major user-visible capability milestone.

---

### Wave 10 — Monthly Perf + API-Retry Templates (2 stories / 13 points)

**Wave goal:** Complete the performance analytics skill and the v0.5 / community GitHub
Action template set with canonical api-retry script. Wave 10 closes out the analytics
and automation template layers.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-031 | 5 | P1 | EPIC-06 | /brain:monthly-perf — LinkedIn Posts API analytics + token logs | STORY-030 (W9) | bats: monthly-perf output, token log reads |
| STORY-035 | 8 | P1 | EPIC-07 | api-retry.sh canonical impl + v0.5 GH Action templates (9) + community templates (4) | STORY-034 (W6), STORY-030 (W9) | bats: api-retry retry logic, template structure |

**Wave critical-path note:** STORY-035 is critical-path (blocks STORY-039 in Wave 11,
the final scale gate). Implement STORY-035 first (`wave_position: 1`). STORY-031 is
independent of STORY-035 and can be implemented in parallel (for multi-dev) or after
(for solo-dev).

**Wave dependencies:** STORY-031 depends on STORY-030 (W9). STORY-035 depends on
STORY-034 (W6) and STORY-030 (W9). All Wave 9 stories must be complete before Wave 10
begins.

**Wave exit criteria:** STORY-031 monthly-perf reads LinkedIn Posts API data and token
logs correctly. STORY-035 api-retry.sh implements exponential backoff with correct
exit-code contract. 9 v0.5 templates and 4 community-optional templates structurally
valid.

**Holdout eligible:** Wave 10 completion enables holdout scenarios for EPIC-06 (analytics)
and EPIC-07 (full template suite including v0.5 and community templates).

---

### Wave 11 — Scale Validation Gate (1 story / 13 points)

**Wave goal:** Run the final scale validation gate: GH Actions throughput at 10K corpus,
memory budget compliance, and per-ingest cost assertion. Wave 11 is the Phase 3 quality
gate; passing it is the prerequisite for Phase 4 holdout evaluation of the full system.

| Story ID | Points | Priority | Epic | Goal | Depends On (prior waves) | Test Surface |
|----------|--------|----------|------|------|--------------------------|--------------|
| STORY-039 | 13 | P1 | EPIC-08 | Scale validation gate: GH Actions throughput, memory budget, per-ingest cost at 10K | STORY-034 (W6), STORY-035 (W10), STORY-036 (W5), STORY-038 (W1) | bats: throughput bats, memory budget, cost assertion |

**Wave critical-path note:** STORY-039 is the sole terminal story of the critical path
and the highest-complexity story (13 points) in the project. It is the final quality
gate and must be the last story delivered in Phase 3.

**Wave dependencies:** STORY-039 depends on STORY-034 (W6), STORY-035 (W10), STORY-036
(W5), and STORY-038 (W1). All Wave 10 stories must be complete before Wave 11 begins.

**Wave exit criteria:** STORY-039 bats pass: GH Actions throughput at 10K corpus within
budget, memory below BC-2.16.004 ceiling, per-ingest cost within BC-2.16.005 limit.
Phase 3 complete. Phase 4 holdout evaluation authorized.

---

## §Wave-Layer Mapping

| Wave | Topo Layers Absorbed | Stories in Wave | Points |
|------|---------------------|-----------------|--------|
| W1 | L0, L1 | 4 | 21 |
| W2 | L2 | 3 | 24 |
| W3 | L3 (hook subset: STORY-003, 007-013) | 8 | 32 |
| W4 | L3 (non-hook: STORY-017, 032) + L4 (light: STORY-004, 015) | 4 | 26 |
| W5 | L4 (main: STORY-019, 033, 036, 040) | 4 | 26 |
| W6 | L5 | 5 | 37 |
| W7 | L6 | 6 | 33 |
| W8 | L7 | 3 | 18 |
| W9 | L8 + L9 + L10 (sequential chain) | 3 | 21 |
| W10 | L11 | 2 | 13 |
| W11 | L12 | 1 | 13 |
| **Total** | **13 layers → 11 waves** | **43** | **264** |

**Layer-to-wave consolidation decisions:**

- **L0+L1 → W1:** L0 (STORY-001) and L1 (STORY-014, STORY-027, STORY-038) merged because
  L1 stories depend only on STORY-001 and can start the moment it completes. Wave-size
  (4 stories, 21pts) is lean, ideal for Wave 1 momentum.

- **L3 split → W3 + W4:** Layer 3 has 10 stories (48pts) — too large for solo-dev focus.
  Split by theme: W3 takes the 8 hook-enforcement stories (STORY-003, 007-013) which form
  a natural thematic unit. W4 takes the 2 remaining L3 stories (STORY-017 wiki-gen and
  STORY-032 lobster-run) which are architecturally distinct from the hook chain, plus 2
  lightweight L4 stories (STORY-004 health and STORY-015 hook-meta-lint) that have their
  L4 prereqs satisfied by the W1-W3 outputs.

- **L4 split → W4 + W5:** Layer 4 has 6 stories (36pts). Two lightweight stories
  (STORY-004 and STORY-015) are absorbed into W4 for thematic grouping. The 4 remaining
  L4 stories (STORY-019, 033, 036, 040) form W5.

- **L8 + L9 + L10 → W9:** The three-layer sequential chain STORY-028 → STORY-029 →
  STORY-030 is collapsed into one wave because (a) all three are on the critical path
  with no branching, (b) for solo-dev this is one focused sprint, and (c) splitting into
  three 1-story waves would add overhead without benefit. Intra-wave `wave_position`
  ordering (1, 2, 3) enforces the sequential constraint within the sprint-state.yaml.

---

## §Wave Summary Stats

| Wave | Stories | Points | P0 | P1 | P2 | Critical-Path | Terminal Nodes | Deps on Prior Waves |
|------|---------|--------|----|----|----|--------------:|---------------:|---------------------|
| W1 | 4 | 21 | 2 | 2 | 0 | 2 (001, 014) | 0 | None |
| W2 | 3 | 24 | 3 | 0 | 0 | 1 (016) | 0 | W1 |
| W3 | 8 | 32 | 7 | 1 | 0 | 0 | 6 (007,008,010,011,012,013) | W1, W2 |
| W4 | 4 | 26 | 3 | 1 | 0 | 1 (017) | 0 | W1, W2, W3 |
| W5 | 4 | 26 | 4 | 0 | 0 | 1 (019) | 0 | W1, W2, W4 |
| W6 | 5 | 37 | 4 | 1 | 0 | 1 (020) | 1 (005) | W1-W5 |
| W7 | 6 | 33 | 2 | 4 | 0 | 1 (024) | 3 (018,021,026) | W1-W6 |
| W8 | 3 | 18 | 1 | 2 | 0 | 1 (025) | 2 (023,043) | W7 |
| W9 | 3 | 21 | 3 | 0 | 0 | 3 (028,029,030) | 0 | W1, W8 |
| W10 | 2 | 13 | 0 | 2 | 0 | 1 (035) | 2 (031,037) | W6, W9 |
| W11 | 1 | 13 | 0 | 1 | 0 | 1 (039) | 1 (039) | W1, W5, W6, W10 |
| **Total** | **43** | **264** | **29** | **14** | **0** | **13** | **16** | — |

_Note: P0/P1 per STORY-INDEX v0.3.1. Terminal node count per dep-graph §Stats._

---

## §Scheduling Notes

### Wave 1 Recommendation

Wave 1 is deliberately lean (4 stories, 21pts). STORY-001 alone establishes the plugin
skeleton — all 42 downstream stories build into it. Ship Wave 1 quickly to validate the
scaffold before investing in the 42 downstream stories.

**Recommended within-wave implementation order:** STORY-001 (first, always), then
STORY-014 (critical-path, event catalog), then STORY-027 and STORY-038 in parallel.

### Holdout-Eligibility Map

| Wave Completion | Holdout-Eligible Capabilities |
|-----------------|-------------------------------|
| After W3 | Hook enforcement chain (all 7 hooks, EPIC-02) |
| After W6 | Install flow, lint-wiki, v0.1 GH Action templates, adversarial review |
| After W7 | Ingest scale gate, rename-page, meta-lint, connection discovery, inbox routing |
| After W8 | Full meta-lint surface, synthesis, governance |
| After W9 | Full content production pipeline (brief → write → publish) |
| After W10 | Analytics, full v0.5 + community template suite |
| After W11 | Scale validation gate — full Phase 3 complete, Phase 4 authorized |

The earliest meaningful holdout checkpoint is after W3 (hook chain closed). The most
significant user-facing capability milestone is after W9 (full publishing pipeline).

### Wave 3 Size Note

Wave 3 has 8 stories (32pts) — the largest wave in the schedule. This is intentional:
the 7 hook enforcement scripts (STORY-007..013) are architecturally homogeneous (same
bats pattern, same JSONL emission contract, same exit-code semantics per BC-2.04.015/016),
making them a natural batch. A solo developer familiar with the pattern from STORY-006
(W2) can implement all 7 in rapid succession. If the team prefers smaller focus units,
Wave 3 can be split into W3a (STORY-003, 007, 008, 009 — 18pts) and W3b (STORY-010,
011, 012, 013 — 14pts) without violating any dependency constraint.

### Waves 9-11: The Publishing Tail

The final three waves (W9-W11, 7 stories, 47pts) form a serial execution tail on the
critical path. No parallelism is available within this tail (each wave depends on the
prior). For a multi-developer team, this serial dependency would be the primary
schedule bottleneck. For solo-dev, the sequential nature is expected and the waves are
sized appropriately (3-2-1 stories).

### Critical-Path Summary

The 13-story critical path runs through all 11 waves:

```
STORY-001 (W1) → STORY-014 (W1) → STORY-016 (W2) → STORY-017 (W4) →
STORY-019 (W5) → STORY-020 (W6) → STORY-024 (W7) → STORY-025 (W8) →
STORY-028 (W9) → STORY-029 (W9) → STORY-030 (W9) → STORY-035 (W10) → STORY-039 (W11)
```

Each critical-path story is assigned `wave_position: 1` within its wave (or explicit
early positions in W9's sequential chain). Finishing critical-path stories first in each
wave minimizes the end-to-end Phase 3 timeline.
