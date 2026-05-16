---
artifact_type: pipeline-state
project: brain-factory
created: 2026-05-15
last_updated: 2026-05-16
mode: greenfield
phase: phase-1d-adversarial-spec-review
phase_1a_status: CLOSED — cascade CONVERGED at Pass 23 on brief v0.4.15
phase_1b_status: COMPLETED — PRD v0.1.1 landed at commit 7935faa; 95 BCs + BC-INDEX + 4 supplements; consistency audit closed (5 findings: 4 closed, 1 OBSERVATION accepted)
phase_1c_status: COMPLETED — architecture v0.1.1 + 95 BCs SS-NN backfilled + PRD v0.1.2 + BC-INDEX v0.1.1; consistency audit closed (7 findings: 6 actionable closed, 1 OBSERVATION expected-pending then resolved); five-file gate canonical; 64/64 P0 BC VP coverage achieved
phase_1d_status: IN-PROGRESS — cascade running; 7 passes complete; 14 fix-bursts complete; streak 0/3
session_continuity: clean-context-resume
canonical_state_doc: .factory/SESSION-HANDOFF.md
canonical_task_list: .factory/TASK-LIST.md
canonical_brief: .factory/specs/product-brief.md (v0.4.19, commit 1c0251c)
canonical_prd: .factory/specs/prd/index.md (v0.1.8, commit 1c0251c)
canonical_bc_index: .factory/specs/behavioral-contracts/BC-INDEX.md (v0.1.7, commit 1c0251c)
canonical_architecture: .factory/specs/architecture/ARCH-INDEX.md (v0.1.9, this commit) + 17 ADRs + 18 SS-NN designs + VP-INDEX v0.1.4 + 27 VPs
worktree_layout_note: .factory/ is a regular directory tracked on main with factory(...) conventional commits per SESSION-HANDOFF §10 standing directive (intentional pre-v0.1 state; NOT a regression)
---

# brain-factory Pipeline STATE

This is the canonical state-discovery entry point. Read it FIRST when starting any new orchestrator session.

## Current pipeline position

**Mode:** GREENFIELD (no existing implementation; planning artifacts in `docs/planning/` serve as Phase 0 equivalent).

**Phase:** 1d Adversarial spec review — IN PROGRESS (cascade running).

**Top-of-stack action:** Phase 1d BC-5.39.001 3-CLEAN cascade in progress. 7 passes complete, 14 fix-bursts complete, streak 0/3. Next action: dispatch Pass 8.

## Phase 1a Stage 5 — CLOSED

The brain-factory product brief reached BC-5.39.001 3-CLEAN convergence after 23 adversary passes and 15 fix-bursts:
- **Final brief:** `.factory/specs/product-brief.md` v0.4.15, 802 lines, commit 9ff0504
- **Convergence:** Streak 3/3 reached at Pass 22 on v0.4.14; preserved through post-convergence cleanup at Pass 23 on v0.4.15
- **Final pass report:** `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-23.md`
- **Cascade history:** Pass 1 (v0.2.0, 312 lines) through Pass 23 (v0.4.15, 802 lines)

## Phase 1b PRD entry — COMPLETED

PRD v0.1.0 created by `vsdd-factory:product-owner` at commit 23e3a91. Fresh-context consistency-validator returned CONDITIONAL-GO with 5 findings. Fix-burst at commit 7935faa (PRD v0.1.0 → v0.1.1) closed 4 of 5 findings; F-1b-CV-05 (OBSERVATION: PRD doesn't enumerate 7 reference repos — brief is authoritative) accepted. Independent orchestrator verification of fix-burst claims: CLEAN.

**PRD package inventory (101 files total):**
- 1 PRD index: `.factory/specs/prd/index.md` (v0.1.1, 535 lines)
- 4 supplements: `error-taxonomy.md`, `nfr-catalog.md`, `interface-definitions.md`, `test-vectors.md`
- 95 BC files across 18 subsystems (ss-01:6, ss-02:7, ss-03:4, ss-04:17, ss-05:6, ss-06:4, ss-07:4, ss-08:4, ss-09:6, ss-10:3, ss-11:3, ss-12:4, ss-13:4, ss-14:5, ss-15:3, ss-16:6, ss-17:4, ss-18:5)
- 1 BC-INDEX: `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.0, 231 lines)

## Phase 1c Architecture entry — COMPLETED

Architecture v0.1.0 produced by `vsdd-factory:architect` at commit b7679ee. Fresh-context consistency-validator returned CONDITIONAL-GO with 7 findings. Architect fix-burst at commit 7e8f96f (architecture v0.1.0 → v0.1.1) closed 5 findings. Product-owner SS-NN sweep + BC-INDEX gate + PRD §7 RTM at commit cd6c3ba closed the remaining actionable finding (F-1c-CV-02). PO body sibling-sweep follow-up at commit 1a10e45 (TD-VSDD-060 closure). PO Architecture Module cell backfill at commit d89ea4b (Production-Grade Default Rule 6 closure). Independent orchestrator verification of all 4 fix-bursts: CLEAN.

**Architecture package inventory (64 files total):**
- 1 ARCH-INDEX: `.factory/specs/architecture/ARCH-INDEX.md` (v0.1.9, this commit)
- 17 ADRs: `ADR-001` through `ADR-017` (all `status: accepted`)
- 18 SS-NN subsystem designs: `SS-01` through `SS-18` (1:1 with ss-NN BC dirs; 1:1 with CAP-001..CAP-018)
- 1 VP-INDEX + 27 VPs: `VP-001` through `VP-027` (64/64 P0 BC coverage achieved)

## Phase 1d Adversarial Cascade — IN PROGRESS

| Pass | Verdict | Findings | Fix-burst SHAs | Streak after |
|------|---------|----------|----------------|--------------|
| 1 | FAIL | 7C+12I+5S+4O | f5adb81 (architect) + 034f0cc (PO) | 0/3 |
| 2 | FAIL | 4C+8I+3S+4O | 4fe045a (architect) + 5023852 (PO) | 0/3 |
| 3 | FAIL | 2C+4I+2S+2O | 2df98db (architect) + c6617bd (PO) | 0/3 |
| 4 | FAIL | 3C+3I | b68a52b (architect) + ee67abb (PO) | 0/3 |
| 5 | FAIL | 2C+3I | d588aa7 (architect) + 96a2a14 (PO) | 0/3 |
| 6 | FAIL | 2C+3I | 533d7db (state-manager persist) + 0827566 (architect) + e0e143c (PO) | 0/3 |
| 7 | FAIL | 2C+3I | 90acdbf (persist) + 7e60898 (architect) + 1c0251c (PO) + this commit (state-manager FINAL) | 0/3 |

New structural-fix disciplines introduced during Phase 1d cascade (additive to Phase 1a's 13):
- Pass 4: "sweep-by-canonical-pattern, not sweep-by-changed-token"
- Pass 5: "last_updated freshness check" (metadata freshness invariant on spec indices)
- Pass 6: "inherits_from chain integrity" + "broaden writing-technique gate to cover plain-prose line-N forms" + "operational state docs in freshness audit scope" (STATE.md, SESSION-HANDOFF, TASK-LIST)
- Pass 7: "pass-closure burst sequencing: state-manager refresh is FINAL commit, not intermediate" (F-PASS7-I2/O1) + "Option B parallel-burst hazard mitigation: state-manager FINAL re-pins all inherits_from to post-all-bursts parent versions" (ARCH-INDEX v0.1.8 §Versioning Policy amendment) + "writing-technique principle extended to plain-prose `line N` literals even in backticks" (F-PASS7-C1) + "Clause 2 gate sibling-sweep to brief + ARCH-INDEX Self-Audit Checklists" (F-PASS7-I3) + "narrative version cites converted to version-agnostic shorthand to scope-eliminate stale-cite class" (F-PASS7-I1 approach)

## What Phase 1d in-cascade carries from Phase 1b/1c

The adversary (Phase 1d) MUST inherit and apply these disciplines:

1. **Five-file gate** — Self-Audit Checklist `grep \bL[0-9]+\b ...` clean on brief + handoff + prd/index.md + BC-INDEX.md + ARCH-INDEX.md before any commit. Five-file gate is now canonical.

2. **All 13 Phase 1a structural-fix disciplines** remain in force (catalog in brief v0.4.15 Changelog block).

3. **Production-grade default applies** (CLAUDE.md Canonical Principle). No blanket-coverage wording; no "pending architect review" for answerable questions.

4. **Single-commit-per-burst** (TD-VSDD-053) — one commit per logical burst; no multi-commit chains with "Stage 1" / "Stage 2" / "backfill" in consecutive subjects.

5. **NO AI attribution** — no `Co-Authored-By: Claude`, no robot emoji, no "Generated with Claude Code". NO `--no-verify`.

6. **NO blanket-coverage wording** — use scoped language: "extends X to cover Y", "scope-eliminates within this version's coverage (re-verify in subsequent passes)".

7. **Writing-technique principle** — never quote literal line-number tokens (capital-L followed immediately by digits, or plain-prose `line N` in any context) in spec content. Describe such defects in semantic terms.

8. **Citation shorthand sibling-sweep** — when citing docs, grep-verify ALL callsites after any shorthand change.

9. **Adversarial 3-CLEAN protocol (BC-5.39.001)** — minimum 3 consecutive zero-blocking-finding fresh-context passes for cascade convergence.

10. **Adversary writes pass reports to `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-N.md`** (new cycle directory; create on first pass).

11. **After convergence, Phase 2 (Story Decomposition) is next** per CLAUDE.md Pipeline Authority — separate human gate or pre-authorization required.

12. **Operational state docs in freshness audit scope** (NEW — Pass 6): STATE.md, SESSION-HANDOFF.md, TASK-LIST.md are subject to the same last_updated/body-freshness invariants as spec indices. When running a freshness audit on spec indices after a fix-burst, also sweep these three operational docs.

13. **Pass-closure burst sequencing** (NEW — Pass 7): state-manager refresh is the FINAL commit of a pass-closure sequence, not an intermediate commit. The sequence is: persist → architect → PO → state-manager-FINAL. This ensures the state-manager sees all specialist bumps before recording final versions.

14. **Option B parallel-burst hazard mitigation** (NEW — Pass 7): In any pass-closure sequence with parallel or serialized specialist bursts, the state-manager FINAL burst re-pins all `inherits_from` fields to post-all-bursts parent versions. Architect and PO bursts each pin `inherits_from` at their own commit time; only the FINAL burst sees all post-all-bursts versions.

## What Phase 1b inherits from Phase 1a

The PRD writer (Phase 1b product-owner) MUST inherit and apply these disciplines (the Phase 1a cascade established them; their absence in the PRD will surface as Phase 1d adversarial findings):

1. **Two-file gate** — Self-Audit Checklist runs `grep \bL[0-9]+\b ...` clean on the new PRD (and the still-active SESSION-HANDOFF) before any commit. Use the v0.4.15-introduced two-file `for`-loop pattern, extended to cover the PRD file.

2. **Writing-technique principle** — never quote literal line-number tokens with the pattern of a capital-L followed immediately by digits. Describe line-number-anchor defects in semantic terms ("literal-line-number anchor", "line-prefixed token"). The grep gate cannot distinguish quoted-literal from active citation.

3. **Exclusion-list-extension protocol** — three-step procedure for adding legitimate prefixed tokens to the gate's exclusion list: (a) add to `grep -v` clause; (b) re-run gate; (c) record rationale in changelog. Do NOT work around the gate by reverting the writing-technique principle.

4. **13 structural-fix disciplines** (catalog in brief v0.4.15 Changelog block).

5. **No blanket-coverage wording** — never write "permanently eliminates", "at all callsites", "all entries", "all callsites" in spec content.

## Resume procedure (FRESH-CONTEXT ORCHESTRATOR — execute in order)

### Step 0 — Worktree health check (BLOCKING)

Run the factory-worktree-health skill via devops-engineer:
```
Agent(subagent_type="vsdd-factory:devops-engineer", prompt="cd /Users/jmagady/Dev/brain-factory && run the factory-worktree-health skill...")
```

Expected: the check will report `.factory/` is a regular directory tracked on `main` (NOT a canonical orphan-branch worktree). This is INTENTIONAL pre-v0.1 state per SESSION-HANDOFF §10 standing directive. Do NOT auto-restructure the layout.

### Step 1 — Read canonical state documents

In order:
1. `/Users/jmagady/Dev/brain-factory/CLAUDE.md` — project conventions, routing table, production-grade default principle
2. THIS FILE (STATE.md) — current pipeline position
3. `/Users/jmagady/Dev/brain-factory/.factory/SESSION-HANDOFF.md` — detailed handoff with cascade history, locked decisions, recent commits
4. `/Users/jmagady/Dev/brain-factory/.factory/TASK-LIST.md` — task ledger (Task #57 / Task #94 are top of stack)
5. `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` — Phase 1a deliverable (v0.4.19)
6. `/Users/jmagady/Dev/brain-factory/.factory/specs/prd/index.md` — Phase 1b deliverable (v0.1.8)
7. `/Users/jmagady/Dev/brain-factory/.factory/specs/behavioral-contracts/BC-INDEX.md` — BC sharding index (v0.1.7, 95 BCs across 18 subsystems)
8. `/Users/jmagady/Dev/brain-factory/.factory/specs/architecture/ARCH-INDEX.md` — Phase 1c deliverable (v0.1.9, 17 ADRs + 18 SS-NN designs + 27 VPs)

### Step 2 — Continue Phase 1d Adversarial spec review (cascade IN PROGRESS — pre-authorized 2026-05-15)

Phase 1d cascade is running. 7 passes complete (all FAIL), 14 fix-bursts applied, streak 0/3.

**Immediate next action:** Dispatch Pass 8.

Cascade inputs (current versions):
- Brief: `.factory/specs/product-brief.md` (v0.4.19)
- PRD: `.factory/specs/prd/index.md` (v0.1.8) + 4 supplements
- BC-INDEX: `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.7, 95 BCs across 18 subsystems)
- Architecture: `.factory/specs/architecture/ARCH-INDEX.md` (v0.1.9) + 17 ADRs + 18 SS-NN designs + VP-INDEX v0.1.4 + 27 VPs
- Planning context: `docs/planning/llm-second-brain-{plan,phased-build-plan,plugin-plan}.md` (immutable per brain-factory-001)
- Locked decisions: `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- Project conventions: `CLAUDE.md`

Pass reports: `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-N.md` (Passes 1–7 already written).

### Step 3 — After Phase 1d convergence

After 3-CLEAN cascade converges, Phase 2 (Story Decomposition) requires a separate human gate or pre-authorization per CLAUDE.md Pipeline Authority.

## Worktree layout — current durable state

`.factory/` is a REGULAR DIRECTORY tracked on `main` (NOT a canonical orphan-branch worktree). Factory artifacts are durably persisted on `main` via `factory(...)` conventional commits. This is intentional pre-v0.1 state per SESSION-HANDOFF §10 standing directive. Recent commits include:
- `1c0251c` — PO Phase 1d Pass 7 fixes: brief v0.4.18→v0.4.19, PRD v0.1.7→v0.1.8, BC-INDEX v0.1.6→v0.1.7
- `7e60898` — architect Phase 1d Pass 7 fixes: architecture v0.1.7→v0.1.8
- `90acdbf` — persist Phase 1d Pass 7 FAIL report (2C+3I)
- `e0e143c` — PO Phase 1d Pass 6 fixes: brief v0.4.17→v0.4.18, PRD v0.1.6→v0.1.7, BC-INDEX v0.1.5→v0.1.6
- `0827566` — architect Phase 1d Pass 6 fixes: architecture v0.1.6→v0.1.7, VP-INDEX v0.1.3→v0.1.4

Run `git -C /Users/jmagady/Dev/brain-factory log --oneline | head -30` to see the full commit history.

## Open questions for human (carried forward but NOT blocking Phase 1d)

These were surfaced during Phase 1a but deferred for human direction at appropriate phase boundaries:

1. **Worktree migration to canonical orphan-branch layout** — should `.factory/` migrate from regular-directory-on-main to orphan-branch worktree before v0.1? Currently working as-is; migration is structural housekeeping. Defer to Phase 2 prep or v0.1 release prep.

2. **Pass 19 escalation question (closed by convergence but worth re-evaluating)** — should we add a real `.factory/hooks/validate-changelog-anchors.sh` script with lefthook or factory-dispatcher pre-commit integration? DEFER-TO-PHASE-1D: this is a Phase 1d toolchain deliverable per the brief's commitments.

3. **Standing user directives (carry forward)** — see SESSION-HANDOFF §10 for the full list. Most relevant to Phase 1d:
   - "No pragmatic convergence. Fix all issues before build." (CLAUDE.md Canonical Principle)
   - "Keep following protocol" (consistently chosen at multiple BC-5.39.001 checkpoints)
   - NO AI attribution in commits

## Where to find the rest

- **Detailed handoff:** `.factory/SESSION-HANDOFF.md` (cascade history, locked decisions, recent commits, Phase 1b/1c completion details)
- **Task ledger:** `.factory/TASK-LIST.md` (Task #57 / #94 are top of stack — Phase 1d entry IN-PROGRESS + Pass 8 dispatch)
- **Adversary cascade reports (Phase 1a):** `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1..23}.md` (immutable historical record)
- **Adversary cascade reports (Phase 1d):** `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-{1..7}.md` (Passes 1–7 written)
- **Locked decisions:** `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- **Product brief (current):** `.factory/specs/product-brief.md` (v0.4.19)
- **PRD (current):** `.factory/specs/prd/index.md` (v0.1.8) + supplements
- **BC-INDEX (current):** `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.7, 95 BCs)
- **Architecture (current):** `.factory/specs/architecture/ARCH-INDEX.md` (v0.1.9) + 17 ADRs + 18 SS-NN designs + VP-INDEX v0.1.4 + 27 VPs
- **Project conventions:** `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
- **Planning artifacts (IMMUTABLE per brain-factory-001):** `docs/planning/llm-second-brain-{plan,phased-build-plan,plugin-plan}.md`, `docs/planning/vsdd-dispatcher-extraction-plan.md`
