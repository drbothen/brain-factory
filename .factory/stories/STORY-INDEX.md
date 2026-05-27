---
artifact_type: story-index
version: "0.4.3"
created: 2026-05-18
last_updated: 2026-05-27
authored_by: vsdd-factory:story-writer
total_stories: 43
total_points: 264
total_epics: 9
total_bcs_covered: 95
phase: phase-3-tdd-implementation
epics_completed: [EPIC-01, EPIC-02, EPIC-03, EPIC-04, EPIC-05, EPIC-06, EPIC-07, EPIC-08, EPIC-09]
epics_pending: []
inputs:
  - product-brief.md@v0.4.20
  - prd/index.md@v0.1.13
  - behavioral-contracts/BC-INDEX.md@v0.1.15
  - architecture/ARCH-INDEX.md@v0.1.23
  - architecture/verification-properties/VP-INDEX.md@v0.1.7
  - stories/epics.md@v0.1.3
  - prd/prd-supplements/nfr-catalog.md@v0.1.1
  - prd/prd-supplements/error-taxonomy.md@v0.1.2
---

# brain-factory Story Index

**43 stories across 9 completed epics. 95 BCs total project scope. 15 stories completed (STORY-001, STORY-002, STORY-003, STORY-006, STORY-007, STORY-008, STORY-009, STORY-010, STORY-011, STORY-012, STORY-013, STORY-014, STORY-016, STORY-027, STORY-038). 28 stories status: draft.**

> **Input-version freshness invariant (F-PHASE2-ADV-PASS2-S04):** Whenever an upstream input (brief, PRD, BC-INDEX, ARCH-INDEX, VP-INDEX, epics.md) is amended, this artifact's `inputs:` block MUST be refreshed in the same fix-burst chain. Stale `inputs:` references are a Pass-fail-class defect, not a cosmetic one.

---

## Changelog

### v0.4.3 — 2026-05-27 (STORY-013 delivery / POL-14 BC promotion — Wave 3 COMPLETE 8/8)

- **STORY-013 status:** `draft` → `completed` (PR #15 merged to develop, commit 93af76d). BC-2.04.013, BC-2.04.014 promoted `draft` → `active` per POL-14.
- **Delivery summary:** flush-state-and-commit.sh (Stop lifecycle, git auto-commit, brain(auto): prefix, worktree detection, STATE.md session-close update) + brain-health-check.sh (SessionStart lifecycle, STATE.md YAML parsing, GREEN/RED/UNREADABLE banner, red_dimensions event field). Red Gate: 21 failing → 42 total tests (21 flush + 21 health). Adversary: 5 passes, 2 fix cycles, BC-5.39.001 3-CLEAN at passes 3-4-5. Trajectory: 3→2→0→0→0.
- **Wave 3 COMPLETE:** 8/8 stories delivered (32/32 points). Wave 3 integration gate next.

### v0.4.2 — 2026-05-27 (STORY-012 delivery / POL-14 BC promotion — Wave 3 progress 7/8)

- **STORY-012 status:** `draft` → `completed` (PR #14 merged to develop, commit 50b54e0). BC-2.04.011, BC-2.04.012 promoted `draft` → `active` per POL-14.
- **Delivery summary:** enforce-kebab-case.sh (PreToolUse, basename regex, 7-item exception list, E-NAMING-001) + block-ai-attribution.sh (PreToolUse on Bash, 3 forbidden patterns, E-ATTR-001). Red Gate: 25 failing → 43 total tests (26 kebab + 17 attribution). Adversary: 4 passes, 1 fix cycle, BC-5.39.001 3-CLEAN at passes 2-3-4. Trajectory: 4→0→0→0.
- **Wave 3 progress:** 7/8 stories delivered (29/32 points). Next: STORY-013 (flush-state-and-commit.sh + brain-health-check.sh, 3 points).

### v0.4.1 — 2026-05-27 (STORY-011 delivery / POL-14 BC promotion — Wave 3 progress 6/8)

- **STORY-011 status:** `draft` → `completed` (PR #13 merged to develop, commit 7cf0400). BC-2.04.009, BC-2.04.010 promoted `draft` → `active` per POL-14.
- **Delivery summary:** validate-source-id-citation.sh (manifest.json lookup, source_ids YAML parsing, E-WIKI-007/008) + validate-publish-state.sh (draft→ready→published state machine, git-based prior state, E-PUBLISH-001/002). Red Gate: 41 failing → 48 total tests. Adversary: 4 passes, 1 fix cycle, BC-5.39.001 3-CLEAN at passes 2-3-4. Trajectory: 5→0→0→0.
- **Wave 3 progress:** 6/8 stories delivered (26/32 points). Next: STORY-012 (enforce-kebab-case.sh + block-ai-attribution.sh, 3 points).

### v0.4.0 — 2026-05-27 (STORY-010 delivery / POL-14 BC promotion — Wave 3 progress 5/8)

- **STORY-010 status:** `draft` → `completed` (PR #12 merged to develop, commit c79fcca). BC-2.04.007, BC-2.04.008 promoted `draft` → `active` per POL-14.
- **Delivery summary:** validate-page-type-policy.sh (exit 2, 6 valid wiki types, E-WIKI-005/E-WIKI-006) + validate-voice-avoid-list.sh (exit 0 always, systemMessage advisory, 30-term check). Red Gate: 43 failing → 53 total tests. Adversary: 5 passes, 2 fix cycles, BC-5.39.001 3-CLEAN at passes 3-4-5. Trajectory: 8→2→0→0→0.
- **Wave 3 progress:** 5/8 stories delivered (21/32 points). Next: STORY-011 (validate-source-citation.sh, 5 points).

### v0.3.9 — 2026-05-26 (STORY-006 delivery / POL-14 BC promotion — Wave 2 COMPLETE)

- **STORY-006 status:** `draft` → `completed` (PR #7 merged to develop, commit 139b05f). BC-2.04.001, BC-2.10.001, BC-2.10.002, BC-2.10.003 promoted `draft` → `active` per POL-14.
- **Delivery summary:** quarantine-fetch.sh (PreToolUse hook, fail-closed, SSRF guard, trap ERR), quarantine.mjs (4 patterns + --check CLI), quarantine-check SKILL.md. 41 Red Gate tests → 64 total. Adversary: 9 passes, 3-CLEAN at passes 7-8-9, 2 fix cycles. Security: fail-closed on ALL paths, SSRF --proto guard, jq-based JSON, credential masking, no eval.
- **Wave 2 COMPLETE:** 3/3 stories delivered (24/24 points). Wave 2 integration gate next.

### v0.3.8 — 2026-05-26 (STORY-002 delivery / POL-14 BC promotion — Wave 2 progress 2/3)

- **STORY-002 status:** `draft` → `completed` (PR #6 merged to develop, commit 1665a92). BC-2.01.001, BC-2.01.004, BC-2.06.003, BC-2.06.004 promoted `draft` → `active` per POL-14.
- **Delivery summary:** run.sh (175 lines, scaffold 26 dirs + 14 template files + manifest.json), SKILL.md (full 6-section), 14 templates. 55 Red Gate tests → 61 total. Adversary: 4 passes, 3-CLEAN at passes 2-3-4. Deferred: test file naming spec drift (init.bats vs integration.bats) — wave gate scope.
- **Wave 2 COMPLETE:** 3/3 stories delivered (24/24 points). Wave 2 integration gate next.

### v0.3.7 — 2026-05-26 (STORY-038 delivery / POL-14 BC promotion — Wave 1 COMPLETE)

- **STORY-038 status:** `draft` → `completed` (PR #4 merged to develop, commit d18d50f). BC-2.16.006 promoted `draft` → `active` per POL-14.
- **Delivery summary:** 308-line gen-test-corpus.sh with LCG PRNG (no $RANDOM), O(n) manifest builder, EXIT trap cleanup. 10 bats tests. Adversary: 9 passes, 4 fix commits. CI fix: portable awk body extraction + curl-based shellcheck install.
- **Wave 1 COMPLETE:** 4/4 stories delivered (21/21 points). Wave 1 integration gate pending.

### v0.3.6 — 2026-05-25 (STORY-027 delivery / POL-14 BC promotion)

- **STORY-027 status:** `draft` → `completed` (PR #3 merged to develop, commit 00ebfa7). BC-2.08.004, BC-2.09.005 promoted `draft` → `active` per POL-14.
- **Adversary convergence:** 5 passes, 0 fix cycles, 3-CLEAN achieved.
- **Wave 1 progress:** 3/4 stories complete (13/21 points). Next: STORY-038 (gen-test-corpus.sh, final Wave 1 story).

### v0.3.5 — 2026-05-25 (STORY-014 delivery / POL-14 BC promotion)

- **STORY-014 status:** `draft` → `completed` (PR #2 merged to develop, commit 1a1874f). BC-2.04.017, BC-2.17.001, BC-2.17.002 promoted `draft` → `active` per POL-14.
- **Wave 1 progress:** 2/4 stories complete (10/21 points). Next: STORY-027 and STORY-038 (both depend only on STORY-001, which is complete).

### v0.3.4 — 2026-05-25 (STORY-001 delivery / POL-14 BC promotion)

- **STORY-001 status:** `draft` → `completed` (PR #1 merged to develop, commit 92c618a). BC-2.14.003, BC-2.14.004, BC-2.14.005 promoted `draft` → `active` per POL-14.
- **Phase field:** updated to `phase-3-tdd-implementation` (Phase 2 closed; Phase 3 active).

### v0.3.3 — 2026-05-19 (F-PHASE2-ADV-PASS2-I03+S04)

- **Input version refresh (I03):** `prd/index.md` v0.1.12 → v0.1.13; `behavioral-contracts/BC-INDEX.md` v0.1.14 → v0.1.15; `stories/epics.md` v0.1.1 → v0.1.3. No story content amended.
- **S04 invariant comment added:** Input-version freshness rule codified in artifact header per F-PHASE2-ADV-PASS2-S04.

### v0.3.2 — 2026-05-19 (F-PHASE2-ADV-PASS1-I04)

- **Input version refresh (I04):** `behavioral-contracts/BC-INDEX.md` updated v0.1.13 → v0.1.14 (current). No story content amended.

### v0.3.1 — 2026-05-19 (F-PHASE2-DECOMP-GATE-I02a)

- **Input version refresh (I02a):** `behavioral-contracts/BC-INDEX.md` updated v0.1.12 → v0.1.13 (PO bump at c123e51). `stories/epics.md` updated v0.1.0 → v0.1.1 (story-writer bump). All other inputs confirmed current.

### v0.3.0 — 2026-05-18 (F-PHASE2-CONSISTENCY-I01-I03 closeout)

- **STORY-014 BC correction (I01):** Row corrected from `[BC-2.04.015, BC-2.04.016, BC-2.04.017, BC-2.17.001..004]` to `[BC-2.04.017, BC-2.17.001, BC-2.17.002]` per authoritative frontmatter.
- **STORY-015 BC correction (I01):** Row corrected from `[BC-2.18.001..005]` to `[BC-2.04.015, BC-2.04.016, BC-2.17.003, BC-2.17.004]` per authoritative frontmatter. BC-2.18.001..005 retained under EPIC-04 (STORY-022/023) only.
- **BC migration corrections (I02):** BC-2.01.002 moved from STORY-002 to STORY-003; BC-2.14.001 moved from STORY-001 to STORY-005; BC-2.02.004 moved from STORY-018 to STORY-016.
- **EPIC-02 point total correction (I03):** 44 → 45 (actual sum of STORY-006..015). Grand total 263 → 264. Coverage footer and frontmatter `total_points` corrected in all three locations.
- **Full rebuild:** All BC rows, coverage footer, and reverse map rebuilt from authoritative story frontmatter. BC reverse map (95 entries) added.
- **Per-priority subtotals added:** P0=29, P1=14, P2=0.

---

## EPIC-01: Plugin Foundation and Scaffold (5 stories / 28 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-001 | Plugin repo structure, plugin.json manifest, and hooks.json.template | completed | 5 | P0 | BC-2.14.003, BC-2.14.004, BC-2.14.005 | — |
| STORY-002 | /brain:init core scaffold — directory structure, templates, manifest.json, policies.yaml | completed | 8 | P0 | BC-2.01.001, BC-2.01.004, BC-2.06.003, BC-2.06.004 | PR #6 merged 1665a92 (2026-05-26) |
| STORY-003 | /brain:init error handling, SLA assertion, and briefs/research/ scaffold | draft | 5 | P0 | BC-2.01.002, BC-2.01.003, BC-2.01.005 | — |
| STORY-004 | /brain:health six-dimensional convergence skill | draft | 5 | P1 | BC-2.01.006 | — |
| STORY-005 | Plugin install from marketplace, tarball completeness, and /brain:upgrade-brain | draft | 5 | P0 | BC-2.14.001, BC-2.14.002 | — |

---

## EPIC-02: Hook Enforcement Chain (10 stories / 45 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-006 | Quarantine corpus, quarantine-fetch.sh hook, and /brain:quarantine-check skill | completed | 8 | P0 | BC-2.04.001, BC-2.10.001, BC-2.10.002, BC-2.10.003 | PR #7 (139b05f) |
| STORY-007 | validate-source-immutability.sh: block overwrite of existing source records | draft | 3 | P0 | BC-2.04.002 | — |
| STORY-008 | validate-wikilink-integrity.sh and validate-index-log-coherence.sh: wiki structural integrity hooks | draft | 5 | P0 | BC-2.04.003, BC-2.04.006 | — |
| STORY-009 | validate-frontmatter-schema.sh: enforce embedding_status and all mandatory wiki/source fields | draft | 5 | P0 | BC-2.04.004, BC-2.04.005 | — |
| STORY-010 | validate-page-type-policy.sh and validate-voice-avoid-list.sh: wiki type path gate and voice advisory | completed | 3 | P0 | BC-2.04.007, BC-2.04.008 | — |
| STORY-011 | validate-source-id-citation.sh and validate-publish-state.sh: citation integrity and publish state machine | completed | 5 | P0 | BC-2.04.009, BC-2.04.010 | PR #13 merged 7cf0400 (2026-05-27) |
| STORY-012 | enforce-kebab-case.sh and block-ai-attribution.sh: filename naming gate and AI attribution block | completed | 3 | P0 | BC-2.04.011, BC-2.04.012 | PR #14 merged 50b54e0 (2026-05-27) |
| STORY-013 | flush-state-and-commit.sh and brain-health-check.sh: session Stop commit and SessionStart health banner | completed | 3 | P1 | BC-2.04.013, BC-2.04.014 | PR #15 merged 93af76d (2026-05-27) |
| STORY-014 | Structured event catalog: scripts/event-catalog.json, hook-event-emit.sh shim, and BC-2.04.017 universal emission | completed | 5 | P0 | BC-2.04.017, BC-2.17.001, BC-2.17.002 | — |
| STORY-015 | Hook contract meta-lint expansion: performance budget, canonical I/O, fail-closed, and stream/credential enforcement | draft | 5 | P0 | BC-2.04.015, BC-2.04.016, BC-2.17.003, BC-2.17.004 | — |

---

## EPIC-03: Content Capture (URL + Source Ingest) (4 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-016 | Defuddle fetch wrapper, duplicate guard, and atomic manifest-write helper | completed | 8 | P0 | BC-2.02.001, BC-2.02.004, BC-2.02.006 | PR #5 merged 7e94ec0 (2026-05-26) |
| STORY-017 | Wiki page generation pipeline, token JSONL logging, and 50K-token chunk warning | draft | 8 | P0 | BC-2.02.002, BC-2.02.003, BC-2.02.005 | — |
| STORY-018 | Sub-linear ingest latency gate: bats scale assertion at 1K and 10K pages | draft | 5 | P1 | BC-2.02.007 | — |
| STORY-019 | Local source ingest: path validation, manifest delta, wiki generation, and partial-failure fan-out | draft | 8 | P0 | BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004 | — |

---

## EPIC-04: Wiki Layer and Meta-Lint (4 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-020 | /brain:lint-wiki seven-check health pass with O(n) index-first wikilink resolution | draft | 8 | P0 | BC-2.05.001, BC-2.05.002, BC-2.05.005, BC-2.05.006 | — |
| STORY-021 | /brain:rename-page atomic backlink propagation with existence and slug guards | draft | 5 | P0 | BC-2.05.003, BC-2.05.004 | — |
| STORY-022 | meta-lint.bats SKILL.md and AGENT.md validation surfaces | draft | 8 | P0 | BC-2.18.001, BC-2.18.003 | — |
| STORY-023 | meta-lint.bats hook script and cross-cutting surfaces plus per-hook bats completeness gate | draft | 8 | P0 | BC-2.18.002, BC-2.18.004, BC-2.18.005 | — |

---

## EPIC-05: Knowledge Synthesis (3 stories / 15 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-024 | /brain:connect skill — cross-domain connection discovery | draft | 5 | P1 | BC-2.11.001 | — |
| STORY-025 | /brain:synthesize skill — weekly thesis from connection layer | draft | 5 | P1 | BC-2.11.002 | — |
| STORY-026 | /brain:process-inbox skill — inbox classification and wiki routing | draft | 5 | P1 | BC-2.11.003 | — |

---

## EPIC-06: Content Brief, Writing, and Publishing (5 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-027 | Content brief scaffold — publishing directories + voice avoid-list file | completed | 3 | P1 | BC-2.08.004, BC-2.09.005 | — |
| STORY-028 | /brain:brief skill — ONE THING / PROOF / TRANSFORMATION content brief | draft | 5 | P0 | BC-2.08.001 | — |
| STORY-029 | /brain:write skill — full piece in author's voice + companion posts + hero prompt | draft | 8 | P0 | BC-2.08.002, BC-2.08.003 | — |
| STORY-030 | /brain:publish-content — state machine, LinkedIn API, scheduling, and finalize flow | draft | 8 | P0 | BC-2.09.001, BC-2.09.002, BC-2.09.003, BC-2.09.004 | — |
| STORY-031 | /brain:monthly-perf — performance analytics from LinkedIn Posts API and token logs | draft | 5 | P1 | BC-2.09.006 | — |

---

## EPIC-07: Lobster Runtime and GitHub Action Templates (4 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-032 | bin/lobster-run — YAML parsing, topological sort, and exit-code contract | draft | 8 | P0 | BC-2.12.001, BC-2.12.002 | — |
| STORY-033 | bin/lobster-run headless execution + six workflow YAML files | draft | 5 | P0 | BC-2.12.003, BC-2.12.004 | — |
| STORY-034 | v0.1 core GH Action templates (6) and /brain:install-actions skill | draft | 8 | P0 | BC-2.13.001 | — |
| STORY-035 | scripts/lib/api-retry.sh canonical implementation, v0.5 GH Action templates (9), and community-optional templates (4) | draft | 8 | P1 | BC-2.13.002, BC-2.13.003, BC-2.13.004 | — |

---

## EPIC-08: Scale-Aware Architecture and Observability (4 stories / 34 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-036 | Token JSONL instrumentation wired into ingest skills | draft | 5 | P0 | BC-2.16.001 | — |
| STORY-037 | Token budget alert in /brain:health, source immutability invariant, and manifest chunks schema | draft | 8 | P1 | BC-2.16.002, BC-2.06.001, BC-2.06.002 | — |
| STORY-038 | scripts/gen-test-corpus.sh — reproducible synthetic corpus generator | completed | 8 | P1 | BC-2.16.006 | — |
| STORY-039 | Scale validation gate: GH Actions throughput, memory budget, and per-ingest cost at 10K corpus | draft | 13 | P1 | BC-2.16.003, BC-2.16.004, BC-2.16.005 | — |

---

## EPIC-09: Plugin Packaging and Governance (4 stories / 26 points)

| Story ID | Title | Status | Points | Priority | BCs | Depends On |
|----------|-------|--------|--------|----------|-----|------------|
| STORY-040 | Adversarial review core dispatch — cognitive diversity gate and four-agent validation | draft | 8 | P0 | BC-2.07.001, BC-2.07.002 | — |
| STORY-041 | Adversarial review structured verdict, streak counter, and multi-pass writescore revision loop | draft | 8 | P0 | BC-2.07.003, BC-2.07.004 | — |
| STORY-042 | Governance policies initialization — .brain/policies.yaml with 10 baseline policies | draft | 5 | P1 | BC-2.15.001 | — |
| STORY-043 | Policy registry management — /brain:policy-add and /brain:policy-registry-validate | draft | 5 | P1 | BC-2.15.002, BC-2.15.003 | — |

---

## Coverage Verification Footer

| Epic | Stories | Points | Running Story Total | Running Point Total |
|------|---------|--------|---------------------|---------------------|
| EPIC-01 | 5 | 28 | 5 | 28 |
| EPIC-02 | 10 | 45 | 15 | 73 |
| EPIC-03 | 4 | 29 | 19 | 102 |
| EPIC-04 | 4 | 29 | 23 | 131 |
| EPIC-05 | 3 | 15 | 26 | 146 |
| EPIC-06 | 5 | 29 | 31 | 175 |
| EPIC-07 | 4 | 29 | 35 | 204 |
| EPIC-08 | 4 | 34 | 39 | 238 |
| EPIC-09 | 4 | 26 | 43 | 264 |
| **TOTAL (epics 1–9)** | **43** | **264** | — | — |

---

## Per-Priority Subtotals

| Priority | Stories | Notes |
|----------|---------|-------|
| P0 | 29 | Must-have for v0.1 launch |
| P1 | 14 | High-value, ship in v0.1 if capacity allows |
| P2 | 0 | None in scope |
| **Total** | **43** | — |

---

## BC to Story Reverse Map

95 entries. Every BC appears exactly once. Sorted by BC ID.

| BC ID | Story |
|-------|-------|
| BC-2.01.001 | STORY-002 |
| BC-2.01.002 | STORY-003 |
| BC-2.01.003 | STORY-003 |
| BC-2.01.004 | STORY-002 |
| BC-2.01.005 | STORY-003 |
| BC-2.01.006 | STORY-004 |
| BC-2.02.001 | STORY-016 |
| BC-2.02.002 | STORY-017 |
| BC-2.02.003 | STORY-017 |
| BC-2.02.004 | STORY-016 |
| BC-2.02.005 | STORY-017 |
| BC-2.02.006 | STORY-016 |
| BC-2.02.007 | STORY-018 |
| BC-2.03.001 | STORY-019 |
| BC-2.03.002 | STORY-019 |
| BC-2.03.003 | STORY-019 |
| BC-2.03.004 | STORY-019 |
| BC-2.04.001 | STORY-006 |
| BC-2.04.002 | STORY-007 |
| BC-2.04.003 | STORY-008 |
| BC-2.04.004 | STORY-009 |
| BC-2.04.005 | STORY-009 |
| BC-2.04.006 | STORY-008 |
| BC-2.04.007 | STORY-010 |
| BC-2.04.008 | STORY-010 |
| BC-2.04.009 | STORY-011 |
| BC-2.04.010 | STORY-011 |
| BC-2.04.011 | STORY-012 |
| BC-2.04.012 | STORY-012 |
| BC-2.04.013 | STORY-013 |
| BC-2.04.014 | STORY-013 |
| BC-2.04.015 | STORY-015 |
| BC-2.04.016 | STORY-015 |
| BC-2.04.017 | STORY-014 |
| BC-2.05.001 | STORY-020 |
| BC-2.05.002 | STORY-020 |
| BC-2.05.003 | STORY-021 |
| BC-2.05.004 | STORY-021 |
| BC-2.05.005 | STORY-020 |
| BC-2.05.006 | STORY-020 |
| BC-2.06.001 | STORY-037 |
| BC-2.06.002 | STORY-037 |
| BC-2.06.003 | STORY-002 |
| BC-2.06.004 | STORY-002 |
| BC-2.07.001 | STORY-040 |
| BC-2.07.002 | STORY-040 |
| BC-2.07.003 | STORY-041 |
| BC-2.07.004 | STORY-041 |
| BC-2.08.001 | STORY-028 |
| BC-2.08.002 | STORY-029 |
| BC-2.08.003 | STORY-029 |
| BC-2.08.004 | STORY-027 |
| BC-2.09.001 | STORY-030 |
| BC-2.09.002 | STORY-030 |
| BC-2.09.003 | STORY-030 |
| BC-2.09.004 | STORY-030 |
| BC-2.09.005 | STORY-027 |
| BC-2.09.006 | STORY-031 |
| BC-2.10.001 | STORY-006 |
| BC-2.10.002 | STORY-006 |
| BC-2.10.003 | STORY-006 |
| BC-2.11.001 | STORY-024 |
| BC-2.11.002 | STORY-025 |
| BC-2.11.003 | STORY-026 |
| BC-2.12.001 | STORY-032 |
| BC-2.12.002 | STORY-032 |
| BC-2.12.003 | STORY-033 |
| BC-2.12.004 | STORY-033 |
| BC-2.13.001 | STORY-034 |
| BC-2.13.002 | STORY-035 |
| BC-2.13.003 | STORY-035 |
| BC-2.13.004 | STORY-035 |
| BC-2.14.001 | STORY-005 |
| BC-2.14.002 | STORY-005 |
| BC-2.14.003 | STORY-001 |
| BC-2.14.004 | STORY-001 |
| BC-2.14.005 | STORY-001 |
| BC-2.15.001 | STORY-042 |
| BC-2.15.002 | STORY-043 |
| BC-2.15.003 | STORY-043 |
| BC-2.16.001 | STORY-036 |
| BC-2.16.002 | STORY-037 |
| BC-2.16.003 | STORY-039 |
| BC-2.16.004 | STORY-039 |
| BC-2.16.005 | STORY-039 |
| BC-2.16.006 | STORY-038 |
| BC-2.17.001 | STORY-014 |
| BC-2.17.002 | STORY-014 |
| BC-2.17.003 | STORY-015 |
| BC-2.17.004 | STORY-015 |
| BC-2.18.001 | STORY-022 |
| BC-2.18.002 | STORY-023 |
| BC-2.18.003 | STORY-022 |
| BC-2.18.004 | STORY-023 |
| BC-2.18.005 | STORY-023 |
