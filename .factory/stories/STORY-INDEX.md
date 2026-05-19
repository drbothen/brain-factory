---
artifact_type: story-index
version: "0.1.0"
created: 2026-05-18
authored_by: vsdd-factory:story-writer
total_stories: 39
total_points: 237
phase: phase-2-story-decomposition-step-b
epics_completed: [EPIC-01, EPIC-02, EPIC-03, EPIC-04, EPIC-05, EPIC-06, EPIC-07, EPIC-08]
epics_pending: [EPIC-09]
---

# brain-factory Story Index

**39 stories across 8 completed epics. 95 BCs total project scope. All stories status: draft.**

---

## EPIC-01: Plugin Foundation and Scaffold (5 stories / 28 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-001 | Plugin repo structure, plugin.json manifest, and hooks.json.template | draft | 5 | P0 | BC-2.14.001, BC-2.14.003, BC-2.14.004, BC-2.14.005 |
| STORY-002 | /brain:init core scaffold — directory structure, templates, manifest.json, policies.yaml | draft | 8 | P0 | BC-2.01.001, BC-2.01.002, BC-2.01.004, BC-2.06.003, BC-2.06.004 |
| STORY-003 | /brain:init error handling, SLA assertion, and briefs/research/ scaffold | draft | 5 | P0 | BC-2.01.003, BC-2.01.005 |
| STORY-004 | /brain:health six-dimensional convergence skill | draft | 5 | P1 | BC-2.01.006 |
| STORY-005 | Plugin install from marketplace, tarball completeness, and /brain:upgrade-brain | draft | 5 | P0 | BC-2.14.002 |

---

## EPIC-02: Hook Enforcement Chain (10 stories / 44 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-006 | Quarantine corpus, quarantine-fetch.sh hook, and /brain:quarantine-check skill | draft | 8 | P0 | BC-2.04.001, BC-2.10.001, BC-2.10.002, BC-2.10.003 |
| STORY-007 | validate-source-immutability.sh: block overwrite of existing source records | draft | 3 | P0 | BC-2.04.002 |
| STORY-008 | validate-wikilink-integrity.sh and validate-index-log-coherence.sh: wiki structural integrity hooks | draft | 5 | P0 | BC-2.04.003, BC-2.04.006 |
| STORY-009 | validate-frontmatter-schema.sh: enforce embedding_status and all mandatory wiki/source fields | draft | 5 | P0 | BC-2.04.004, BC-2.04.005 |
| STORY-010 | validate-page-type-policy.sh and validate-voice-avoid-list.sh: wiki type path gate and voice advisory | draft | 3 | P0 | BC-2.04.007, BC-2.04.008 |
| STORY-011 | validate-source-id-citation.sh and validate-publish-state.sh: citation integrity and publish state machine | draft | 5 | P0 | BC-2.04.009, BC-2.04.010 |
| STORY-012 | enforce-kebab-case.sh and block-ai-attribution.sh: filename naming gate and AI attribution block | draft | 3 | P0 | BC-2.04.011, BC-2.04.012 |
| STORY-013 | flush-state-and-commit.sh and brain-health-check.sh: session Stop commit and SessionStart health banner | draft | 3 | P1 | BC-2.04.013, BC-2.04.014 |
| STORY-014 | Structured event catalog: scripts/event-catalog.json, hook-event-emit.sh shim, and BC-2.04.017 universal emission | draft | 5 | P0 | BC-2.04.015, BC-2.04.016, BC-2.04.017, BC-2.17.001, BC-2.17.002, BC-2.17.003, BC-2.17.004 |
| STORY-015 | Hook contract meta-lint expansion: performance budget, canonical I/O, fail-closed, and stream/credential enforcement | draft | 5 | P0 | BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.004, BC-2.18.005 |

---

## EPIC-03: Content Capture (URL + Source Ingest) (4 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-016 | Defuddle fetch wrapper, duplicate guard, and atomic manifest-write helper | draft | 8 | P0 | BC-2.02.001, BC-2.02.006 |
| STORY-017 | Wiki page generation pipeline, token JSONL logging, and 50K-token chunk warning | draft | 8 | P0 | BC-2.02.002, BC-2.02.003, BC-2.02.005 |
| STORY-018 | Sub-linear ingest latency gate: bats scale assertion at 1K and 10K pages | draft | 5 | P1 | BC-2.02.004, BC-2.02.007 |
| STORY-019 | Local source ingest: path validation, manifest delta, wiki generation, and partial-failure fan-out | draft | 8 | P0 | BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004 |

---

## EPIC-04: Wiki Layer and Meta-Lint (4 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-020 | /brain:lint-wiki seven-check health pass with O(n) index-first wikilink resolution | draft | 8 | P0 | BC-2.05.001, BC-2.05.002, BC-2.05.005, BC-2.05.006 |
| STORY-021 | /brain:rename-page atomic backlink propagation with existence and slug guards | draft | 5 | P0 | BC-2.05.003, BC-2.05.004 |
| STORY-022 | meta-lint.bats SKILL.md and AGENT.md validation surfaces | draft | 8 | P0 | BC-2.18.001, BC-2.18.003 |
| STORY-023 | meta-lint.bats hook script and cross-cutting surfaces plus 9-suite completeness gate | draft | 8 | P0 | BC-2.18.002, BC-2.18.004, BC-2.18.005 |

---

## EPIC-05: Knowledge Synthesis (3 stories / 15 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-024 | /brain:connect skill — cross-domain connection discovery | draft | 5 | P1 | BC-2.11.001 |
| STORY-025 | /brain:synthesize skill — weekly thesis from connection layer | draft | 5 | P1 | BC-2.11.002 |
| STORY-026 | /brain:process-inbox skill — inbox classification and wiki routing | draft | 5 | P1 | BC-2.11.003 |

---

## EPIC-06: Content Brief, Writing, and Publishing (5 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-027 | Content brief scaffold — publishing directories + voice avoid-list file | draft | 3 | P1 | BC-2.08.004, BC-2.09.005 |
| STORY-028 | /brain:brief skill — ONE THING / PROOF / TRANSFORMATION content brief | draft | 5 | P0 | BC-2.08.001 |
| STORY-029 | /brain:write skill — full piece in author's voice + companion posts + hero prompt | draft | 8 | P0 | BC-2.08.002, BC-2.08.003 |
| STORY-030 | /brain:publish-content — state machine, LinkedIn API, scheduling, and finalize flow | draft | 8 | P0 | BC-2.09.001, BC-2.09.002, BC-2.09.003, BC-2.09.004 |
| STORY-031 | /brain:monthly-perf — performance analytics from LinkedIn Posts API and token logs | draft | 5 | P1 | BC-2.09.006 |

---

## EPIC-07: Lobster Runtime and GitHub Action Templates (4 stories / 29 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-032 | bin/lobster-run — YAML parsing, topological sort, and exit-code contract | draft | 8 | P0 | BC-2.12.001, BC-2.12.002 |
| STORY-033 | bin/lobster-run headless execution + six workflow YAML files | draft | 5 | P0 | BC-2.12.003, BC-2.12.004 |
| STORY-034 | v0.1 core GH Action templates (6) and /brain:install-actions skill | draft | 8 | P0 | BC-2.13.001 |
| STORY-035 | scripts/lib/api-retry.sh canonical, v0.5 GH Action templates (9), community templates (4) | draft | 8 | P1 | BC-2.13.002, BC-2.13.003, BC-2.13.004 |

---

## EPIC-08: Scale-Aware Architecture and Observability (4 stories / 34 points)

| Story ID | Title | Status | Points | Priority | BCs |
|----------|-------|--------|--------|----------|-----|
| STORY-036 | Token JSONL instrumentation wired into ingest skills | draft | 5 | P0 | BC-2.16.001 |
| STORY-037 | Token budget alert in /brain:health, source immutability invariant, and manifest chunks schema | draft | 8 | P1 | BC-2.16.002, BC-2.06.001, BC-2.06.002 |
| STORY-038 | scripts/gen-test-corpus.sh — reproducible synthetic corpus generator | draft | 8 | P1 | BC-2.16.006 |
| STORY-039 | Scale validation gate: GH Actions throughput, memory budget, and per-ingest cost at 10K corpus | draft | 13 | P1 | BC-2.16.003, BC-2.16.004, BC-2.16.005 |

---

## Coverage Verification Footer

| Epic | Stories | Points | Running Story Total | Running Point Total |
|------|---------|--------|---------------------|---------------------|
| EPIC-01 | 5 | 28 | 5 | 28 |
| EPIC-02 | 10 | 44 | 15 | 72 |
| EPIC-03 | 4 | 29 | 19 | 101 |
| EPIC-04 | 4 | 29 | 23 | 130 |
| EPIC-05 | 3 | 15 | 26 | 145 |
| EPIC-06 | 5 | 29 | 31 | 174 |
| EPIC-07 | 4 | 29 | 35 | 203 |
| EPIC-08 | 4 | 34 | 39 | 237 |
| **TOTAL (epics 1–8)** | **39** | **237** | — | — |

Note: EPIC-09 stories are pending the final Step B burst.
