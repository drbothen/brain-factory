---
artifact_type: pipeline-state
project: brain-factory
created: 2026-05-15
last_updated: 2026-05-15
mode: greenfield
phase: phase-1b-prd-entry
phase_1a_status: CLOSED — cascade CONVERGED at Pass 23 on brief v0.4.15
phase_1b_status: APPROVED-READY-FOR-DISPATCH (user-authorized 2026-05-15)
session_continuity: clean-context-resume
canonical_state_doc: .factory/SESSION-HANDOFF.md
canonical_task_list: .factory/TASK-LIST.md
canonical_brief: .factory/specs/product-brief.md (v0.4.15, 802 lines, commit 9ff0504)
worktree_layout_note: .factory/ is a regular directory tracked on main with factory(...) conventional commits per SESSION-HANDOFF §10 standing directive (intentional pre-v0.1 state; NOT a regression)
---

# brain-factory Pipeline STATE

This is the canonical state-discovery entry point. Read it FIRST when starting any new orchestrator session.

## Current pipeline position

**Mode:** GREENFIELD (no existing implementation; planning artifacts in `docs/planning/` serve as Phase 0 equivalent).

**Phase:** 1b PRD entry (USER-APPROVED — proceed directly to dispatch).

**Top-of-stack action:** Orchestrator dispatches `vsdd-factory:product-owner` with the `/vsdd-factory:create-prd` skill to elaborate brief v0.4.15 into a PRD with behavioral contracts (BCs).

## Phase 1a Stage 5 — CLOSED

The brain-factory product brief reached BC-5.39.001 3-CLEAN convergence after 23 adversary passes and 15 fix-bursts:
- **Final brief:** `.factory/specs/product-brief.md` v0.4.15, 802 lines, commit 9ff0504
- **Convergence:** Streak 3/3 reached at Pass 22 on v0.4.14; preserved through post-convergence cleanup at Pass 23 on v0.4.15
- **Final pass report:** `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-23.md`
- **Cascade history:** Pass 1 (v0.2.0, 312 lines) through Pass 23 (v0.4.15, 802 lines)

## What Phase 1b inherits from Phase 1a

The PRD writer (Phase 1b product-owner) MUST inherit and apply these disciplines (the Phase 1a cascade established them; their absence in the PRD will surface as Phase 1d adversarial findings):

1. **Two-file gate** — Self-Audit Checklist runs `grep \bL[0-9]+\b ...` clean on the new PRD (and the still-active SESSION-HANDOFF) before any commit. Use the v0.4.15-introduced two-file `for`-loop pattern, extended to cover the PRD file.

2. **Writing-technique principle** — never quote literal line-number tokens with the pattern of a capital-L followed immediately by digits. Describe line-number-anchor defects in semantic terms ("literal-line-number anchor", "line-prefixed token"). The grep gate cannot distinguish quoted-literal from active citation.

3. **Exclusion-list-extension protocol** — three-step procedure for adding legitimate prefixed tokens to the gate's exclusion list: (a) add to `grep -v` clause; (b) re-run gate; (c) record rationale in changelog. Do NOT work around the gate by reverting the writing-technique principle.

4. **13 structural-fix disciplines** (catalog in brief v0.4.15 Changelog block):
   - v0.4.5: grep-anchors replace line-number references in Self-Audit Checklist
   - v0.4.6: creation-date anchors replace volatile line-count references in Traceability
   - v0.4.7: per-version-attestation collapse to canonical Changelog pointer
   - v0.4.8: citation shorthand sibling-sweep (`phased plan §X` → `phased-build-plan.md §X`; `plugin plan §X` → `plugin-plan.md §X`)
   - v0.4.8: §Changelog notation cleanup
   - v0.4.10: Changelog audit-trail discipline (semantic anchors only)
   - v0.4.11: semantic-label discipline + grep-verified citation sweep (no ordinal cascade counts)
   - v0.4.12: audit-trail completeness (every structural-fix bullet uses STRUCTURAL FIX heading)
   - v0.4.13: Self-Audit Checklist enforcement gate at write-time
   - v0.4.14: writing-technique principle + gate hardening (self-reference exclusion)
   - v0.4.15: gate-coverage extension to handoff (two-file `for`-loop)
   - v0.4.15: exclusion-list-extension protocol NOTE
   - v0.4.15: audit-trail wording calibration (scoped equivalents replace absolute-immutability claims)

5. **No blanket-coverage wording** — never write "permanently eliminates", "at all callsites", "all entries", "all callsites" in spec content. The cascade caught FOUR levels of recursion driven by overstated coverage claims. Use scoped language: "extends the X to cover Y", "scope-eliminates within this version's coverage", "re-verify in subsequent passes".

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
4. `/Users/jmagady/Dev/brain-factory/.factory/TASK-LIST.md` — task ledger (Task #54 is the only pending task)
5. `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` — the converged Phase 1a deliverable (v0.4.15, 802 lines)
6. `/Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-23.md` — the most recent adversary report (post-convergence verification PASS)

### Step 2 — Dispatch Phase 1b PRD entry (NO FURTHER USER APPROVAL NEEDED — already authorized)

Spawn `vsdd-factory:product-owner` with the `/vsdd-factory:create-prd` skill. Suggested prompt skeleton:

> cd /Users/jmagady/Dev/brain-factory && create the brain-factory PRD per the `/vsdd-factory:create-prd` skill. Inputs:
> - Brief: `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.15, 802 lines, the converged Phase 1a deliverable)
> - Domain context: `/Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md`, `llm-second-brain-phased-build-plan.md`, `llm-second-brain-plugin-plan.md` (immutable design source-of-truth per brain-factory-001)
> - Locked decisions: `/Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
> - Project conventions: `/Users/jmagady/Dev/brain-factory/CLAUDE.md` (routing table, production-grade default, structural-fix disciplines)
>
> Outputs:
> - PRD with behavioral contracts (BC-S.SS.NNN format), error taxonomy, edge case catalog. Write to `.factory/specs/prd.md` (or sharded under `.factory/specs/prd/` per the create-prd skill's defaults).
>
> Disciplines to inherit from Phase 1a Stage 5 cascade (per STATE.md):
> - Writing-technique principle (never quote literal line-number tokens in the format of a capital-L followed immediately by digits; use semantic terms when describing line-number anchor defects)
> - Two-file gate Self-Audit Checklist item (extend to cover the PRD too — three-file `for`-loop covering brief, handoff, AND new PRD)
> - Exclusion-list-extension protocol
> - No blanket-coverage wording in changelog entries; use scoped language
>
> Commit discipline (NON-NEGOTIABLE per CLAUDE.md):
> - Single-commit-per-burst (TD-VSDD-053)
> - NO `Co-Authored-By: Claude`, NO robot emoji, NO "Generated with Claude Code"
> - NO `--no-verify`
> - Commit on `main`

### Step 3 — Phase 1c (Architecture)

After PRD lands and self-audits pass, dispatch `vsdd-factory:architect` with the `/vsdd-factory:create-architecture` skill to produce architecture docs + ADRs from the PRD's BCs.

### Step 4 — Phase 1d (Adversarial spec review)

Dispatch a fresh BC-5.39.001 3-CLEAN cascade against the PRD + architecture per CLAUDE.md Pipeline Authority. Expect another multi-pass cascade — the writing-technique principle and gate disciplines should significantly reduce defect surface area compared to Phase 1a.

## Worktree layout — current durable state

`.factory/` is a REGULAR DIRECTORY tracked on `main` (NOT a canonical orphan-branch worktree). Factory artifacts are durably persisted on `main` via `factory(...)` conventional commits. This is intentional pre-v0.1 state per SESSION-HANDOFF §10 standing directive. Recent commits include:
- `8228adc` — Pass 23 PASS persistence
- `9ff0504` — v0.4.15 post-convergence cleanup (brief)
- `2d68e09` — Pass 22 CASCADE CONVERGED persistence

Run `git -C /Users/jmagady/Dev/brain-factory log --oneline | head -30` to see the full cascade commit history.

## Open questions for human (carried forward but NOT blocking Phase 1b)

These were surfaced during Phase 1a but deferred for human direction at appropriate phase boundaries:

1. **Worktree migration to canonical orphan-branch layout** — should `.factory/` migrate from regular-directory-on-main to orphan-branch worktree before v0.1? Currently working as-is; migration is structural housekeeping. Defer to Phase 2 prep or v0.1 release prep.

2. **Pass 19 escalation question (closed by convergence but worth re-evaluating in Phase 1b)** — should we add a real `.factory/hooks/validate-changelog-anchors.sh` script with lefthook or factory-dispatcher pre-commit integration? The Phase 1a cascade reached convergence WITHOUT this escalation (writing-technique principle + cultural-checklist enforcement proved sufficient). However, the script would be a Phase 1d toolchain deliverable per the brief's commitments. Defer until Phase 1d toolchain bootstrap.

3. **Standing user directives (carry forward to Phase 1b)** — see SESSION-HANDOFF §10 for the full list. Most relevant to Phase 1b:
   - "No pragmatic convergence. Fix all issues before build." (CLAUDE.md Canonical Principle)
   - "Keep following protocol" (consistently chosen at multiple BC-5.39.001 checkpoints)
   - NO AI attribution in commits

## Where to find the rest

- **Detailed handoff:** `.factory/SESSION-HANDOFF.md` (cascade history, locked decisions, recent commits, structural-fix cascade detail, every defect class surfaced)
- **Task ledger:** `.factory/TASK-LIST.md` (Task #54 is the only pending — Phase 1b PRD entry, USER-APPROVED)
- **Adversary cascade reports:** `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1..23}.md` (immutable historical record)
- **Locked decisions:** `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- **Product brief (final):** `.factory/specs/product-brief.md` (v0.4.15, 802 lines)
- **Project conventions:** `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
- **Planning artifacts (IMMUTABLE per brain-factory-001):** `docs/planning/llm-second-brain-{plan,phased-build-plan,plugin-plan}.md`, `docs/planning/vsdd-dispatcher-extraction-plan.md`
