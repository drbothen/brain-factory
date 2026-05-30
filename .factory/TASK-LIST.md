# TASK-LIST — brain-factory Session Snapshot

> Snapshot updated: 2026-05-30. **Phase 1a/1b/1c/1d CLOSED. Phase 2 CLOSED. Phase 3 IN PROGRESS — Waves 1+2+3 COMPLETE + GATES PASSED. Wave 4: 4/4 stories DELIVERED (STORY-017 PR#16, STORY-032 PR#17, STORY-004 PR#18, STORY-015 PR#19). Wave 4 integration gate PENDING.**
> **HOLDOUT-SCENARIOS ACCESS CONTROL: restricted — orchestrator MUST NOT pass `.factory/stories/holdout-scenarios.md` contents to story-writer, architect, adversary, implementer, or any Phase 2/3 agent other than holdout-evaluator (Phase 4).**
> **Resume on fresh context:** Read `.factory/STATE.md` FIRST, then `.factory/SESSION-HANDOFF.md`, then this file.
> See SESSION-HANDOFF.md "RESUME PROCEDURE FOR FRESH-CONTEXT ORCHESTRATOR" section for numbered resume steps.

## User Decisions Log

| Date | ID | Question | Decision |
|------|----|----------|----------|
| 2026-05-16 | UD-001 | Pass 11 architect work disposition (interrupted commit recovery) | Option A pre-authorized — commit architect's work as-is at a3a83b1 |
| 2026-05-16 | UD-002 | Convergence threshold per F-PASS12-O2 STRONG-ESCALATE (Pass 16 adversary recommendation) | **Option C** — continue cascade without discipline catalog freeze. NO convergence-by-stable-discipline-catalog. NO move to Phase 2 until BC-5.39.001 literal streak 3/3 achieved. Meta-rule self-violation class accepted as recurring pattern. |
| 2026-05-17 | UD-003 | F-PASS12-O2 3rd STRONG-ESCALATE (Pass 18 adversary recommendation): CRITICAL plateau at 5 passes + meta-rule self-violation at 8 recurrences both thresholds tripped; 3 options presented (a) continue, (b) carve-out exemption, (c) declare-converged-by-fiat | **Option (a) continue cascade** — same as UD-002; meta-rule self-violation class explicitly acknowledged as predictable recurring pattern; no pivot to carve-out or declare-converged-by-fiat |
| 2026-05-17 | UD-004 | F-PASS12-O2 4th escalation surfaced after 16-pass post-UD-003 evidence (Passes 16–31, ~48 commits, 20+ recurrences, CRITICAL=2 plateau extending to CRITICAL=3 at Pass 32, never advanced past streak 0/3) | **Option (a) continue** — user reaffirmed Option C strict protocol; cascade continues indefinitely until BC-5.39.001 literal streak 3/3; meta-rule self-violation class continues to be acknowledged as predictable recurring pattern; structural-resolution acceptable timeline open-ended |
| 2026-05-18 | UD-005 | Phase 1d CONVERGED at Pass 42 — Phase 2 transition decision; F-PASS40-O2 / F-PASS40-O3 / F-PASS41-O2 / F-PASS42-O2 process-gaps disposition | **Option: Proceed to Phase 2; defer all 4 inherited process-gaps** — human directive 2026-05-18 stated "we will be proceeding to Phase 2"; all 4 process-gaps documented as DEFERRED — NOT blocking Phase 2 |
| 2026-05-18 | UD-006 | Phase 2 Step B per-hook .bats convention — CLAUDE.md says one per-hook bats file; SS-18 v1.4 had consolidated hooks.bats | **CLAUDE.md wins** — per-hook bats canonical; cascade applied to brief v0.4.20 (NFR-019), SS-18 v1.5, BC-2.18.005 v1.2, and 11 affected stories |
| 2026-05-19 | UD-007 | Dep-graph supersession convention — dependency-graph.md canonical vs per-story frontmatter | **dependency-graph.md is CANONICAL for inter-story deps.** Per-story frontmatter `dependencies:`/`blocks:` are at-creation-time snapshots. Downstream agents (wave-scheduler, implementer, adversary, CI) consult dependency-graph.md, NOT per-story frontmatter. Asymmetry between frontmatter and graph is legitimate — consistency-validator MUST NOT flag these as defects. |
| 2026-05-19 | UD-008 | F-PHASE2-ADV-PASS1-I07 — frontmatter `blocks:` arrays asymmetric vs dep-graph — accept deferral or fix? | **DEFERRED per UD-007** — dep-graph supersession convention makes frontmatter blocks asymmetry a legitimate non-defect. Per-story frontmatter blocks/dependencies are at-creation-time snapshots. I07 DEFERRED. If Pass 2+ re-surfaces I07 with concrete implementer-blocking evidence, orchestrator reconsiders. |
| 2026-05-28 | UD-009 | STORY-004 LOCAL adversarial cascade — continue until BC-5.39.001 3-CLEAN convergence per strict protocol | User authorized strict BC-5.39.001 3-CLEAN convergence for STORY-004 LOCAL adversarial cascade (continue cascade until convergence or stop). Convergence achieved at Pass 20 commit abb9c71; PR #18 merged at af7c6addd3e63379b67f17a2dd7ea27d31b3b765 (2026-05-29). |
| 2026-05-30 | UD-010 | STORY-015 LOCAL adversarial cascade — continue until BC-5.39.001 3-CLEAN convergence per strict protocol | User authorized strict BC-5.39.001 3-CLEAN convergence for STORY-015 LOCAL adversarial cascade. Convergence achieved at Pass 8 (BC-5.39.001 3-CLEAN at Passes 6+7+8); 8 passes, 5 fix bursts. PR #19 merged at 20bedb7708660bc7a828a2d17c2e956fec8e301d (2026-05-30). 3 cross-story deferrals recorded: D-PASS8-CS-01 (validate-page-type-policy ERR trap), D-PASS8-CS-02 (quarantine-fetch ERR trap), D-PASS8-CS-03 (BC-2.04.016 PC2 stale verdict text) — routed to Wave 4 integration gate. |

## Phase 1d CLOSED (CONVERGED at Pass 42 commit 44cda58 — historical record)

BC-5.39.001 3-CLEAN literal streak 3/3 achieved: Pass 40 PASS (eef8402) + Pass 41 PASS (40e7c1e) + Pass 42 PASS (44cda58). 42 passes total (39 FAIL + 3 PASS). 68 fix-bursts. 24 disciplines codified. 13 sub-checks codified. CRITICAL trajectory ...→3→1→3→0→0→0. Phase 1d adversarial spec review cascade CLOSED. Phase 2 (Story Decomposition) AUTHORIZED per UD-005 (2026-05-18). Phase 2 Step B COMPLETED per UD-006 cascade (2026-05-18/19).

Inherited process-gaps DEFERRED per UD-005 (NOT blocking Phase 2): F-PASS40-O2 (F-PASS39-I3 hit-by-hit enumeration vs F-PASS37-O2 mirror tension), F-PASS40-O3 (historical Pass 35-37 closure-summary ordering inconsistency), F-PASS41-O2 (inherited F-PASS40-O2/O3), F-PASS42-O2 (inherited same). May be revisited during Phase 2 if relevant or post-Phase-2.

## TOP OF STACK (RESUME ENTRY POINT — Wave 4 COMPLETE — Integration Gate PENDING)

**Pipeline:** Phase 3 Wave 4 COMPLETE. 19/43 stories delivered (108/264 pts ≈ 41%). 44 BCs active.
**Next action:** Run Wave 4 integration gate (6-check: test suite, DTU skip, adversary fresh-context, demo evidence, holdout, state update).
**Last delivery:** STORY-015 PR #19 merged at 20bedb7708660bc7a828a2d17c2e956fec8e301d (2026-05-30).
**develop tip:** 20bedb7 (post-STORY-015-merge).
**main tip:** (this burst — post-STORY-015-delivery state-manager closure).
**Working tree:** clean; .factory/code-delivery/ + .factory/cycles/ + .factory/logs/ + .factory/planning/ untracked (expected).

**Wave 4 status (4/4 COMPLETE):**
- STORY-017 (P0 wiki page generation) — DONE — PR#16, merge_commit=b30dd35
- STORY-032 (P0 lobster-run runtime) — DONE — PR#17, merge_commit=d610cf0
- STORY-004 (P0 /brain:health skill + hook) — DONE — PR#18, merge_commit=af7c6ad
- STORY-015 (P0 hook meta-lint) — **DONE — PR#19, merge_commit=20bedb7**

**Wave 4 gate (PENDING):** standard 6-check integration gate per wave-gate skill. 3 cross-story deferrals to process during gate:
- D-PASS8-CS-01: validate-page-type-policy ERR trap plain-text output on crash (origin: STORY-015 Pass 8; owner: implementer; target: wave-gate review or Wave 5)
- D-PASS8-CS-02: quarantine-fetch ERR trap silent (no stdout on crash) (origin: STORY-015 Pass 8; owner: implementer; target: wave-gate review or Wave 5)
- D-PASS8-CS-03: BC-2.04.016 v1.4 PC2 stale `verdict` text (ADR-002 v2.0 updated to `continue`/`decision` but PC2 prose not swept) (origin: STORY-015 Pass 8; owner: product-owner; target: wave-gate or PO sweep)

**UD-007+UD-008 carry-forward note:** dependency-graph.md is CANONICAL for inter-story dependencies. Per-story frontmatter `dependencies:`/`blocks:` are at-creation-time snapshots. I07 (frontmatter blocks asymmetry) DEFERRED per UD-008. Downstream agents consult dep-graph, not frontmatter. Consistency-validator MUST NOT flag frontmatter-vs-dep-graph asymmetries as defects.

**HOLDOUT-SCENARIOS ACCESS CONTROL — RESTRICTED:** `.factory/stories/holdout-scenarios.md` has `access_control: restricted`. Orchestrator MUST NOT pass its contents to story-writer, architect, adversary, implementer, or any agent other than holdout-evaluator (Phase 4). DO NOT include holdout-scenarios.md in any Phase 2/3 agent context.

## Wave Implementation Status

### Wave 1: Plugin Foundation (COMPLETE — 4/4 stories — 21 pts — GATE PASSED)

| Story | Pts | PR | Merge Commit | Status |
|-------|-----|----|--------------|--------|
| STORY-001 | 5 | #1 | 35eaa67 | DONE |
| STORY-014 | 5 | #2 | 0c41fa5 | DONE |
| STORY-027 | 3 | #3 | bf3e62a | DONE |
| STORY-038 | 8 | #4 | 4e23dde | DONE |

### Wave 2: Core Init + Quarantine + Defuddle (COMPLETE — 3/3 stories — 24 pts — GATE PASSED 6/6)

| Story | Pts | PR | Merge Commit | Status |
|-------|-----|----|--------------|--------|
| STORY-016 | 8 | #5 | 4a8a8f3 | DONE |
| STORY-002 | 8 | #6 | 76e7f2b | DONE |
| STORY-006 | 8 | #7 | ce29e8f | DONE |

### Wave 3: Hook Enforcement Chain (COMPLETE — 8/8 stories — 32 pts — GATE PASSED 6/6)

| Story | Pts | PR | Merge Commit | Status |
|-------|-----|----|--------------|--------|
| STORY-003 | 5 | #8 | 2f13f97 | DONE |
| STORY-007 | 3 | #9 | 9cb5147 | DONE |
| STORY-008 | 5 | #10 | (see SESSION-HANDOFF) | DONE |
| STORY-009 | 5 | #11 | (see SESSION-HANDOFF) | DONE |
| STORY-010 | 3 | #12 | c79fcca | DONE |
| STORY-011 | 5 | #13 | 7cf0400 | DONE |
| STORY-012 | 3 | #14 | 50b54e0 | DONE |
| STORY-013 | 3 | #15 | 93af76d | DONE |

### Wave 4: Wiki Generation + Lobster + Health + Meta-Lint (COMPLETE — 4/4 stories — 26/26 pts — Integration Gate PENDING)

| Story | Pts | PR | Merge Commit | Status |
|-------|-----|----|--------------|--------|
| STORY-017 | 8 | #16 | b30dd35 | DONE |
| STORY-032 | 8 | #17 | d610cf0 | DONE |
| STORY-004 | 5 | #18 | af7c6ad | DONE (converged at Pass 20) |
| STORY-015 | 5 | #19 | 20bedb7 | **DONE (converged at Pass 8)** |

### Waves 5-11: PENDING (26 stories, 161 pts remaining)

See `.factory/stories/wave-schedule.md` for full schedule.

## Active Drift Items (DI) Register

- **DI-001** (F-P3-O01): BC `status: draft` vs `lifecycle_status: active` divergence — project-wide PO sweep, post-Wave-4 maintenance
- **DI-002** (F-P3-O02): `argument-hint: ""` vs Meta-Lint Contract — project-wide, post-Wave-4 maintenance
- **DI-005** (F-P6-S01): yq dim_detail shell-escape latent risk — follow-up story post-Wave-4
- **DI-006** (F-P6-O01): closure-validation grep gate process-codification — cycle-lessons sweep

**RETIRED DIs (during STORY-004 cascade):**
- DI-003 (BC-2.04.014 v1.5 ADR-002 alignment): closed in Pass 9 commit 50fa61c
- DI-004 (STORY-005 exit codes): closed in Pass 12 commit e8504ef
- DI-007 (tentative BC-2.04.014 exit-1 contradiction): VERIFIED REAL in Pass 15, then RESOLVED — same root finding closed by Pass-15 fix burst
- DI-008 (tentative token alert format): NOT ACTUALLY DRIFT — verified clean in Pass 14

## Cycle Lessons Codified (`.factory/cycles/v0.1-phase-3-impl/lessons.md`)

13 lessons codified. L1-L10 during STORY-004 LOCAL cascade. L11 post-STORY-004 (durability gap). L12-L13 post-STORY-015:

- L1: `shopt -s inherit_errexit` does NOT propagate `set -e` into bash functions invoked via if-conditional context
- L2: Paper-fix detection via test-writer-committed initially-failing tests
- L3: Fresh-context audits must include narrative prose review (Description, AC text, etc.)
- L4: Reconciliation must sweep WHOLE file in scope (applies recursively)
- L5: Slow-rotting spec drift treated as authoritative regardless of "scope" — close per Rule 4
- L6: BC supersedes story spec for contract semantics per Source-of-Truth precedence rule 1
- L7: BC Canonical Test Vector citations must reference actual `@test` declarations
- L8: Adversary tool dispatches must use absolute worktree paths (`/Users/.../worktrees/<STORY>/...`)
- L9: Bats JSON-shape assertions must use jq -e structural extraction, not substring matching
- L10: Benign dead-code observations don't reset the 3-CLEAN streak unless contract-violating
- L11: Harness `TaskCreate`/`TaskUpdate` tasks are ephemeral — orchestrator must mirror task state to TASK-LIST.md after every meaningful burst
- L12: Cascade paper-fix layers descend through architectural strata (BC text → test mechanism → fixture content → implementation); accept cascade depth as evidence BC-5.39.001 is working
- L13: vsdd-factory compute-input-hash tool has awk-termination bug on multi-file inputs; use manual CONCAT+sha256sum workaround

## Next Steps (in dependency order)

1. **Wave 4 integration gate (NEXT ACTION)** — 6-check standard gate (test suite, DTU skip, adversary fresh-context wave diff review, demo evidence, holdout, state update) per wave-gate skill. Process cross-story deferrals D-PASS8-CS-01/02/03 during gate review. Gate must PASS before Wave 5 dispatch.

2. **Wave 5: Source Ingest + Lobster Headless + Token Write + Adversary Core** — 4 stories, 26 pts. See sprint-state.yaml. Critical path: STORY-019 first (unblocks STORY-036).

## Phase 1d / Phase 2 Completion Record (historical — for audit trail only)

Phase 1a CLOSED (CONVERGED at Pass 22 on v0.4.14; post-convergence cleanup v0.4.15; Phase 1a Stage 6 administratively complete).
Phase 1b COMPLETED — PRD v0.1.1 at commit 7935faa; 95 BCs + BC-INDEX + 4 supplements.
Phase 1c COMPLETED — architecture v0.1.1 across 5 commits (b7679ee through d89ea4b).
Phase 1d CONVERGED — BC-5.39.001 3-CLEAN literal streak 3/3 achieved at Pass 42 commit 44cda58. 42 passes total (39 FAIL + 3 PASS). 68 fix-bursts. Phase 1d adversarial spec review CLOSED.
Phase 2 Steps A-G COMPLETED and CONVERGED — epics/stories/dep-graph/wave-schedule/holdout/consistency gate/adversarial-story-review all CLOSED. 43 stories, 264 pts, 11 waves. Phase 2 Step G converged at Pass 6 commit 543c588. Phase 2 CLOSED — Phase 3 AUTHORIZED.
Phase 3 Waves 1-3 COMPLETE + GATES PASSED (see Wave Implementation Status above).
Phase 3 Wave 4 COMPLETE (4/4 stories delivered — integration gate pending).
