---
artifact_type: pipeline-state
project: brain-factory
created: 2026-05-15
last_updated: 2026-05-15
mode: greenfield
phase: phase-1c-architecture-entry
phase_1a_status: CLOSED — cascade CONVERGED at Pass 23 on brief v0.4.15
phase_1b_status: COMPLETED — PRD v0.1.1 landed at commit 7935faa; 95 BCs + BC-INDEX + 4 supplements; consistency audit closed (5 findings: 4 closed, 1 OBSERVATION accepted)
phase_1c_status: APPROVED-READY-FOR-DISPATCH
session_continuity: clean-context-resume
canonical_state_doc: .factory/SESSION-HANDOFF.md
canonical_task_list: .factory/TASK-LIST.md
canonical_brief: .factory/specs/product-brief.md (v0.4.15, 802 lines, commit 9ff0504)
canonical_prd: .factory/specs/prd/index.md (v0.1.1, 535 lines, commit 7935faa)
canonical_bc_index: .factory/specs/behavioral-contracts/BC-INDEX.md (v0.1.0, 231 lines, commit 7935faa)
worktree_layout_note: .factory/ is a regular directory tracked on main with factory(...) conventional commits per SESSION-HANDOFF §10 standing directive (intentional pre-v0.1 state; NOT a regression)
---

# brain-factory Pipeline STATE

This is the canonical state-discovery entry point. Read it FIRST when starting any new orchestrator session.

## Current pipeline position

**Mode:** GREENFIELD (no existing implementation; planning artifacts in `docs/planning/` serve as Phase 0 equivalent).

**Phase:** 1c Architecture entry (APPROVED — proceed directly to dispatch).

**Top-of-stack action:** Orchestrator dispatches `vsdd-factory:architect` with the `/vsdd-factory:create-architecture` skill to produce architecture docs + ADRs from the 95 BCs in BC-INDEX.md.

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

**Structural summary:**
- 18 capability anchors (CAP-001 through CAP-018) in PRD §2
- 21 error scopes in error-taxonomy.md
- 26 skills in interface-definitions.md per SL-2
- 13 hook surfaces enumerated as BCs in ss-04
- `subsystem: SS-TBD` in all 95 BC frontmatter — architect assigns SS-NN canonical IDs in Phase 1c
- Single commit per fix burst (TD-VSDD-053 ✓), no AI attribution ✓
- Two consistency audits passed (one per commit; both fresh-context)

## What Phase 1c inherits from Phase 1b

The architect (Phase 1c) MUST inherit and apply these disciplines (their absence in architecture docs will surface as Phase 1d adversarial findings):

1. **Four-file gate** — Self-Audit Checklist runs `grep \bL[0-9]+\b ...` clean on brief + handoff + prd/index.md + BC-INDEX.md before any commit. Extend to FIVE-file when ARCH-INDEX.md lands; architect adds it.

2. **All 13 Phase 1a structural-fix disciplines** remain in force (catalog in brief v0.4.15 Changelog block).

3. **Production-grade default applies** (CLAUDE.md Canonical Principle). No blanket-coverage wording; no "pending architect review" for answerable questions.

4. **Single-commit-per-burst** (TD-VSDD-053) — one commit per logical burst; no multi-commit chains with "Stage 1" / "Stage 2" / "backfill" in consecutive subjects.

5. **NO AI attribution** — no `Co-Authored-By: Claude`, no robot emoji, no "Generated with Claude Code". NO `--no-verify`.

6. **NO blanket-coverage wording** — use scoped language: "extends X to cover Y", "scope-eliminates within this version's coverage (re-verify in subsequent passes)".

7. **Writing-technique principle** — never quote literal line-number tokens (capital-L followed immediately by digits) in spec content. Describe such defects in semantic terms.

8. **Citation shorthand sibling-sweep** — when citing docs, grep-verify ALL callsites after any shorthand change (e.g., `phased-build-plan.md §X` not `phased plan §X`).

9. **Architect MUST assign SS-NN canonical subsystem IDs** to all 95 BCs (replacing `subsystem: SS-TBD`). Coordinate with state-manager or product-owner to backfill BC frontmatter.

10. **Architect produces ARCH-INDEX.md** as canonical sharding index over architecture docs + ADRs. PRD §7 RTM "Architecture Module" placeholders backfilled post-Phase-1c.

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
4. `/Users/jmagady/Dev/brain-factory/.factory/TASK-LIST.md` — task ledger (Task #56 is top of stack)
5. `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` — the converged Phase 1a deliverable (v0.4.15, 802 lines)
6. `/Users/jmagady/Dev/brain-factory/.factory/specs/prd/index.md` — the Phase 1b deliverable (v0.1.1, 535 lines)
7. `/Users/jmagady/Dev/brain-factory/.factory/specs/behavioral-contracts/BC-INDEX.md` — BC sharding index (v0.1.0, 231 lines, 95 BCs across 18 subsystems)

### Step 2 — Dispatch Phase 1c Architecture entry (NO FURTHER USER APPROVAL NEEDED — pre-authorized 2026-05-15)

Spawn `vsdd-factory:architect` with the `/vsdd-factory:create-architecture` skill. Inputs:
- PRD: `.factory/specs/prd/index.md` (v0.1.1) + 4 supplements
- BC-INDEX: `.factory/specs/behavioral-contracts/BC-INDEX.md` (95 BCs across 18 subsystems)
- Planning context: `docs/planning/llm-second-brain-{plan,phased-build-plan,plugin-plan}.md` (immutable per brain-factory-001)
- Locked decisions: `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- Project conventions: `CLAUDE.md`

Outputs:
- Architecture docs + ADRs under `.factory/specs/architecture/`
- ARCH-INDEX.md as canonical sharding index
- SS-NN canonical subsystem ID assignment to all 95 BCs (replacing `subsystem: SS-TBD`)
- PRD §7 RTM "Architecture Module" placeholder backfill

Disciplines to inherit: all items enumerated in "What Phase 1c inherits from Phase 1b" above.

### Step 3 — Phase 1d (Adversarial spec review)

After architecture lands and self-audits pass, dispatch a fresh BC-5.39.001 3-CLEAN cascade against PRD v0.1.1 + architecture together per CLAUDE.md Pipeline Authority. Expect another multi-pass cascade — the writing-technique principle and structural-fix disciplines should significantly reduce defect surface area compared to Phase 1a.

## Worktree layout — current durable state

`.factory/` is a REGULAR DIRECTORY tracked on `main` (NOT a canonical orphan-branch worktree). Factory artifacts are durably persisted on `main` via `factory(...)` conventional commits. This is intentional pre-v0.1 state per SESSION-HANDOFF §10 standing directive. Recent commits include:
- `7935faa` — PRD v0.1.1 fix-burst (consistency audit closed; Phase 1c authorized)
- `23e3a91` — PRD v0.1.0 initial creation
- `8228adc` — Pass 23 PASS persistence
- `9ff0504` — v0.4.15 post-convergence cleanup (brief)

Run `git -C /Users/jmagady/Dev/brain-factory log --oneline | head -30` to see the full commit history.

## Open questions for human (carried forward but NOT blocking Phase 1c)

These were surfaced during Phase 1a but deferred for human direction at appropriate phase boundaries:

1. **Worktree migration to canonical orphan-branch layout** — should `.factory/` migrate from regular-directory-on-main to orphan-branch worktree before v0.1? Currently working as-is; migration is structural housekeeping. This question is no more urgent post-Phase-1b than it was pre-Phase-1b. Defer to Phase 2 prep or v0.1 release prep.

2. **Pass 19 escalation question (closed by convergence but worth re-evaluating)** — should we add a real `.factory/hooks/validate-changelog-anchors.sh` script with lefthook or factory-dispatcher pre-commit integration? The Phase 1a cascade reached convergence WITHOUT this escalation. DEFER-TO-PHASE-1D: this is a Phase 1d toolchain deliverable per the brief's commitments.

3. **Standing user directives (carry forward)** — see SESSION-HANDOFF §10 for the full list. Most relevant to Phase 1c:
   - "No pragmatic convergence. Fix all issues before build." (CLAUDE.md Canonical Principle)
   - "Keep following protocol" (consistently chosen at multiple BC-5.39.001 checkpoints)
   - NO AI attribution in commits

## Where to find the rest

- **Detailed handoff:** `.factory/SESSION-HANDOFF.md` (cascade history, locked decisions, recent commits, structural-fix cascade detail, Phase 1b completion details)
- **Task ledger:** `.factory/TASK-LIST.md` (Task #56 is top of stack — Phase 1c Architecture entry, APPROVED-READY-FOR-DISPATCH)
- **Adversary cascade reports:** `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1..23}.md` (immutable historical record)
- **Locked decisions:** `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- **Product brief (final):** `.factory/specs/product-brief.md` (v0.4.15, 802 lines)
- **PRD (current):** `.factory/specs/prd/index.md` (v0.1.1, 535 lines) + supplements
- **BC-INDEX (current):** `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.0, 231 lines, 95 BCs)
- **Project conventions:** `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
- **Planning artifacts (IMMUTABLE per brain-factory-001):** `docs/planning/llm-second-brain-{plan,phased-build-plan,plugin-plan}.md`, `docs/planning/vsdd-dispatcher-extraction-plan.md`
