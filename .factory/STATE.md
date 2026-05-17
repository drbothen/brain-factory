---
artifact_type: pipeline-state
project: brain-factory
created: 2026-05-15
last_updated: 2026-05-17
mode: greenfield
phase: phase-1d-adversarial-spec-review
phase_1a_status: CLOSED — cascade CONVERGED at Pass 23 on brief v0.4.15
phase_1b_status: COMPLETED — PRD v0.1.1 landed at commit 7935faa; 95 BCs + BC-INDEX + 4 supplements; consistency audit closed (5 findings: 4 closed, 1 OBSERVATION accepted)
phase_1c_status: COMPLETED — architecture v0.1.1 + 95 BCs SS-NN backfilled + PRD v0.1.2 + BC-INDEX v0.1.1; consistency audit closed (7 findings: 6 actionable closed, 1 OBSERVATION expected-pending then resolved); five-file gate canonical; 64/64 P0 BC VP coverage achieved
phase_1d_status: IN-PROGRESS — Pass 20 CLOSED; 20 passes complete (all FAIL); 46 fix-bursts complete; streak 0/3; UD-003 in effect; no re-escalation Pass 20 per UD-003
session_continuity: ACTIVE-CASCADE — Pass 20 closed; resume by dispatching Pass 21 adversary per BC-5.39.001 chat-only protocol; no catalog freeze per UD-002/UD-003
canonical_state_doc: .factory/STATE.md
canonical_task_list: .factory/TASK-LIST.md
canonical_brief: .factory/specs/product-brief.md (v0.4.19, commit 1c0251c)
canonical_prd: .factory/specs/prd/index.md (v0.1.10, commit 2f247fc)
canonical_bc_index: .factory/specs/behavioral-contracts/BC-INDEX.md (v0.1.9, commit 2f247fc)
canonical_architecture: .factory/specs/architecture/ARCH-INDEX.md (v0.1.22, commit 9734b40) + 17 ADRs (6 at v1.1, 2 at v1.2, 9 at v1.0) + 18 SS-NN (16 at v1.1, SS-02 at v1.2, SS-18 at v1.4) + VP-INDEX v0.1.6 + 27 VPs (4 at v1.2: VP-014/021/026/027; VP-004 at v1.1; VP-012 at v1.3; 21 at v1.0)
worktree_layout_note: .factory/ is a regular directory tracked on main with factory(...) conventional commits per SESSION-HANDOFF §10 standing directive (intentional pre-v0.1 state; NOT a regression)
---

# brain-factory Pipeline STATE

This is the canonical state-discovery entry point. Read it FIRST when starting any new orchestrator session.

---

## Pass 20 CLOSED — Pass 21 next-action

**Pass 20 closure summary:** Pass 20 adversary persisted at commit f3e7ca2 (FAIL — 1 CRITICAL + 2 IMPORTANT + 2 SUGGESTIONS + 2 OBSERVATIONS). Architect burst 9734b40 closed F-PASS20-C1 (replaced F-PASS19-O1 canonical-baseline scope clause with actual 15-prior-burst sweep enumeration; sweep result: 2 same-commit-sibling-violations found post-F-PASS18-O1 codification — Pass 18 a73b64a and Pass 19 9172878, both closed) + F-PASS20-I2 (removed circular self-validation carve-out from F-PASS19-O1 inline self-check). ARCH-INDEX bumped to v0.1.22. NO PO burst (F-PASS11-O1 + discipline #10 still not mirrored to PRD/BC-INDEX). State-mgr FINAL ✓ (this commit) closed F-PASS20-I1 (§5 reconciliation rationale corrected — "13" WAS substantiable as individual STRUCTURAL FIX entry count in brief Changelog; row-count-canonical choice documented) + F-PASS20-S1 (§5 v0.4.8 and v0.4.12 rows extended to mention omitted structural fixes). CRITICAL count held at 1 for 7th consecutive pass — F-PASS20-O2 observation; NO re-escalation per UD-003.

**User decision (UD-002):** OPTION C in effect — continue cascade without discipline catalog freeze. No convergence-by-stable-discipline-catalog interpretation. No move to Phase 2 until BC-5.39.001 literal streak 3/3 achieved. User accepts that meta-rule self-violation class may recur in future passes.

**User decision (UD-003):** OPTION (a) reaffirmed on 2026-05-17 — continue cascade per UD-002; same Option C policy; 5-pass plateau and 8-recurrence evidence does not change the human directive. 3rd STRONG-ESCALATE resolved; F-PASS12-O2 escalation clock reset.

**Top-of-stack action:** Dispatch Pass 21 adversary (chat-only per F-PASS12-O1; no catalog freeze per UD-002/UD-003). Continue cascade until BC-5.39.001 literal streak 3/3.

---

## Resume procedure for FRESH-CONTEXT ORCHESTRATOR

**Read these documents IN ORDER before dispatching any agent:**

1. `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
2. `/Users/jmagady/Dev/brain-factory/.factory/STATE.md` (this file)
3. `/Users/jmagady/Dev/brain-factory/.factory/SESSION-HANDOFF.md`
4. `/Users/jmagady/Dev/brain-factory/.factory/TASK-LIST.md`
5. `/Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1d-spec/adversary-pass-20.md` (most recent findings — Pass 20 CLOSED; Pass 21 adversary is next-action)

**Pre-dispatch verification:**
- Confirm HEAD = this commit (Pass 20 state-mgr FINAL) via `git log --oneline -1`
- Confirm no uncommitted changes via `git status --short`

**Resume steps (in order):**

1. Dispatch Pass 21 adversary per BC-5.39.001 cascade protocol (chat-only per F-PASS12-O1; no catalog freeze per Option C / UD-002/UD-003).
2. Continue cascade per Option C until BC-5.39.001 literal streak 3/3 achieved.

---

## Current pipeline position

**Mode:** GREENFIELD (no existing implementation; planning artifacts in `docs/planning/` serve as Phase 0 equivalent).

**Phase:** 1d Adversarial spec review — IN-PROGRESS.

## Phase 1a Stage 5 — CLOSED

The brain-factory product brief reached BC-5.39.001 3-CLEAN convergence after 23 adversary passes and 15 fix-bursts:
- **Final brief:** `.factory/specs/product-brief.md` v0.4.15, 802 lines, commit 9ff0504
- **Convergence:** Streak 3/3 reached at Pass 22 on v0.4.14; preserved through post-convergence cleanup at Pass 23 on v0.4.15
- **Final pass report:** `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-23.md`

## Phase 1b PRD entry — COMPLETED

PRD v0.1.1 landed at commit 7935faa. 95 BCs across 18 subsystems, 1 BC-INDEX, 4 supplements. Consistency audit CONDITIONAL-GO; 4 of 5 findings closed. Independent orchestrator verification: CLEAN.

## Phase 1c Architecture entry — COMPLETED

Architecture v0.1.1 landed via 5 commits (b7679ee through d89ea4b). ARCH-INDEX + 17 ADRs + 18 SS-NN designs + 27 VPs (64/64 P0 BC coverage). Five-file gate canonical. Independent orchestrator verification: CLEAN.

## Phase 1d Adversarial Cascade — IN-PROGRESS

| Pass | Verdict | Findings | Persist SHA | Fix-burst SHAs | Streak after |
|------|---------|----------|-------------|----------------|--------------|
| 1 | FAIL | 7C+12I+5S+4O | 484bc05 | architect f5adb81 + PO 034f0cc | 0/3 |
| 2 | FAIL | 4C+8I+3S+4O | 15eee88 | architect 4fe045a + PO 5023852 | 0/3 |
| 3 | FAIL | 2C+4I+2S+2O | c3f32db | architect 2df98db + PO c6617bd | 0/3 |
| 4 | FAIL | 3C+3I | 984f9d6 | architect b68a52b + PO ee67abb | 0/3 |
| 5 | FAIL | 2C+3I | ba8ea7f | architect d588aa7 + PO 96a2a14 | 0/3 |
| 6 | FAIL | 2C+3I | 533d7db | architect 0827566 + PO e0e143c | 0/3 |
| 7 | FAIL | 2C+3I | 90acdbf | architect 7e60898 + PO 1c0251c + state-mgr FINAL fd033d1 | 0/3 |
| 8 | FAIL | 1C+3I | a6917e4 | architect bf34582 + state-mgr FINAL 35fd7c2 | 0/3 |
| 9 | FAIL | 1C+2I | 3296100 | architect 8c7dc97 + state-mgr FINAL 47824c4 | 0/3 |
| 10 | FAIL | 2C+3I | 5a61476 | architect cc9ba18 + state-mgr FINAL c468276 | 0/3 |
| 11 | FAIL | 2C+3I | 63cf130 | architect a3a83b1 + 343c378 (header correction) + c35de6f (inventory correction) + state-mgr FINAL e37f1e3 + 7ea3f71 (back-fill) | 0/3 |
| 12 | FAIL | 2C+3I+2O | a58de7e | architect 71c51b3 + PO ecbe056 + state-mgr FINAL 0781716 | 0/3 |
| 13 | FAIL | 2C+3I+2O | a2fab66 | architect 52b7f19 + state-mgr FINAL d3016a3 | 0/3 |
| 14 | FAIL | 1C+2I+2O | ace7b4b | architect 07466a4 + state-mgr FINAL 2bf91af | 0/3 |
| 15 | FAIL | 1C+2I+1O | 65633ef | architect 7af2546 + state-mgr FINAL a603c03 | 0/3 |
| 16 | FAIL | 1C+2I+2O | 8aefca8 | architect 2a1f543 + state-mgr FINAL 24e229d | 0/3 |
| 17 | FAIL | 1C+3I+1S+2O | 87ebf2d | architect b70fc7d + PO 2f247fc + state-mgr FINAL 6ed900d | 0/3 |
| 18 | FAIL | 1C+2I+1S+2O | 1d56d20 | architect a73b64a + state-mgr FINAL 47d12c7 | 0/3 |
| 19 | FAIL | 1C+2I+1S+2O | dbac4cf | architect 9172878 + state-mgr FINAL 82341f3 | 0/3 |
| 20 | FAIL | 1C+2I+2S+2O | f3e7ca2 | architect 9734b40 + state-mgr FINAL ✓ (this commit) | 0/3 |

**CRITICAL trajectory (CRITICAL count):** 7→4→2→3→2→2→2→1→1→2→2→2→2→1→1→1→1→1→1→1. CRITICAL plateau at 1 for 7 consecutive passes (Pass 14, Pass 15, Pass 16, Pass 17, Pass 18, Pass 19, Pass 20).

## 23 Structural-Fix Disciplines Codified During Phase 1d

Inherited from Phase 1a (10 confirmed structural-fix disciplines — see brief v0.4.19 Changelog or SESSION-HANDOFF §5; first structural-fix discipline emerged at v0.4.5; v0.4.1 through v0.4.4 and v0.4.9 had no STRUCTURAL FIX labels).

Phase 1d additions (23 confirmed committed disciplines):
1. (Pass 4) Sweep-by-canonical-pattern — for canonical-target patterns (tests/X.bats), sweep both positive (present) and negative (deprecated absent)
2. (Pass 5) last_updated freshness check — last_updated >= max(changelog date)
3. (Pass 6) inherits_from chain integrity — child references parent's current version per Option B (pin-at-burst-end)
4. (Pass 6) Plain-prose `line N` Clause 2 gate — sibling to L-prefixed Clause 1 gate
5. (Pass 7) Sequential pass-closure discipline — bursts run sequentially (persist → architect → PO → state-mgr FINAL), not parallel; Option B parallel-burst hazard mitigation
6. (Pass 8) Operational state doc path-currency check — test -e on every cited path
7. (Pass 9) In-document title-cell sibling-sweep — within ARCH-INDEX, Doc Map cells match VP-INDEX Summary cells
8. (Pass 10) Dual-scope discipline — every codified discipline declares incremental scope + canonical-baseline scope (one-time sweep at codification)
9. (Pass 11) Timestamp tri-partite semantic (created / timestamp / last_updated) + canonical-baseline sweep (F-PASS11-C1/I3)
10. (Pass 11) Retroactive dual-scope audit on codification of any new meta-rule (F-PASS11-C2)
11. (Pass 11) Adversary pre-flight grep verification before flagging writing-tech recursion findings (F-PASS11-O1)
12. (Pass 12) SS-NN Changelog discipline tightened to trigger on ANY content edit, not just version > 1.0 (F-PASS12-I2)
13. (Pass 12) Adversary dispatch chat-only protocol — read-only adversary cannot Write or Commit; orchestrator must dispatch with chat-output only instructions and route persistence via state-manager (F-PASS12-O1)
14. (Pass 13) Architecture artifact Changelog discipline extended to all SS/ADR/VP artifact types — same trigger (content-edit detected via timestamp > created), same Changelog-section requirement; bash sweep updated to cover all three artifact types (F-PASS13-C2)
15. (Pass 13) Count balance check Self-Audit sub-rule — for any count claim in a canonical-baseline-scope clause (N bumped / M retained), verify N + M = total artifact count cited in the same clause before commit (F-PASS13-C1)
16. (Pass 13) Cascade table FINAL-marker format change — state-mgr FINAL rows no longer carry self-SHA placeholder; use textual marker "state-mgr FINAL ✓ (this commit)" instead; self-SHA back-fill bursts eliminated going forward (F-PASS13-I1 closure)
17. (Pass 14) Changelog reconstruction enumeration discipline — when back-filling a Changelog section, grep ARCH-INDEX for target file ID first; one bullet per modification; no invented attributions; insufficient-attribution acknowledged rather than fabricated (F-PASS14-C1)
18. (Pass 15) Changelog amendments count as body modifications requiring version bump (F-PASS15-C1 clarification of F-PASS13-C2)
19. (Pass 15) Derived-cell-count enumeration discipline — cite SPECIFIC cells from ARCH-INDEX entries, not "all three" claims (F-PASS15-I1)
20. (Pass 15) Initial-creation content discipline — F-PASS14-C1 enumeration targets POST-CREATION modifications only; initial-creation content reflecting parent-document decisions does NOT require attribution (F-PASS15-I2)
21. (Pass 15) Bash sweep timestamp-invariant check — `timestamp >= created` enforcement (F-PASS15-O1)
22. (Pass 16) Changelog version-monotonicity check — Changelog entries MUST appear in strict descending semver order; bash sweep `grep -nE '^### v' "$f" | awk '{print $2}' | sort -rV -c` exits 0 if descending; applies to ARCH-INDEX, VP-INDEX, all SS-NN/ADR/VP files with Changelog sections, AND PRD/supplements/BC-INDEX/95 BC files (F-PASS16-I1 closure; bash sweep extended to PRD/BC scope by F-PASS17-I3(a/b) in ARCH-INDEX v0.1.19 commit b70fc7d + PRD v0.1.10 + BC-INDEX v0.1.9 via PO commit 2f247fc)
23. (Pass 17) Header-vs-body count check — for any section header containing a count claim, verify the count matches body row/item count (F-PASS17-I1 closure; codified in ARCH-INDEX v0.1.19 commit b70fc7d; mirrored into PRD v0.1.10 + BC-INDEX v0.1.9 via PO commit 2f247fc). Canonical-baseline sweep across STATE.md + SESSION-HANDOFF + TASK-LIST completed Pass 18 FINAL — 5 count-bearing headers checked, 1 drift instance fixed (§8 "19 commits" → "28 commits"), 1 pre-existing gap noted (§5 "13 confirmed disciplines" header over 10-row table, root cause: Phase 1a disciplines prior to v0.4.5 missing from table body), all other headers clean post-burst.

## TD-VSDD-053-spirit Advisories (corrective-burst-within-pass pattern)

Phase 1d has produced "corrective burst within same logical pass" sequences that survive the single-commit-chain hook detector (no banned theme word) but violate TD-VSDD-053 in spirit. Documented audit trail (not retroactively rebased):

- Pass 11: architect a3a83b1 → 343c378 (missing changelog header correction) → c35de6f (hallucinated inventory correction); state-mgr e37f1e3 → 7ea3f71 (back-fill self-SHA). 5 commits in one logical Pass 11 cycle.
- Pass 12: clean (1 architect + 1 PO + 1 state-mgr FINAL = 3 commits, one per agent role).
- Pass 13: clean (1 architect + 1 state-mgr FINAL = 2 commits, one per agent role).
- Pass 14: clean (1 adversary persist + 1 architect + 1 state-mgr FINAL = 3 commits).
- Pass 15: clean (1 adversary persist + 1 architect + 1 state-mgr FINAL = 3 commits).
- Pass 16: clean (1 adversary persist 8aefca8 + 1 architect 2a1f543 + 1 state-mgr FINAL 24e229d = 3 commits, one per agent role).
- Pass 17: clean (1 adversary persist 87ebf2d + 1 architect b70fc7d + 1 PO 2f247fc + 1 state-mgr FINAL ✓ (this commit) = 4 commits, one per agent role).

Going-forward orchestrator discipline: dispatch agents with explicit single-commit-per-burst instructions; verify draft outputs before commit to avoid corrective bursts.

## state-manager FINAL discipline (9 sub-checks)

Before committing, state-manager FINAL MUST run:
- (a) inherits_from re-pin to post-all-bursts parent versions
- (b) path-currency check via `test -e` on all cited .factory/specs/ paths
- (c) absolute-quantity audit — verify counts match actual artifact state
- (d) cited-SHA verification — confirm all commit SHAs cited in state docs exist
- (e) changelog factual-accuracy spot-check — scan for corrective-NOTE pattern
- (f) in-document title-cell sibling-sweep — ARCH-INDEX Document Map vs VP-INDEX Summary
- (g) dual-scope discipline verification — every newly codified discipline declares both scopes
- (h) adversary pre-flight verification — confirm the adversary pre-flight discipline is correctly stated (incremental + canonical-baseline scopes declared) in ARCH-INDEX Self-Audit Checklist (F-PASS11-O1)
- (i) F-PASS19-O1 same-commit-sibling-check self-applied — every count claim written in this burst matches body INCLUDING this commit's additions (discipline #23 header-vs-body)

## Open questions for human

1. **Worktree migration** — should `.factory/` migrate from regular-directory-on-main to orphan-branch worktree before v0.1? Defer to Phase 2 prep or v0.1 release prep.

2. **Pass 19 escalation (validate-changelog-anchors hook)** — DEFER-TO-PHASE-1D (already deferred; no action needed now).

3. **Phase 1d convergence threshold** — RESOLVED via UD-002 (2026-05-16): Option C selected. Continue cascade without discipline catalog freeze. No convergence-by-stable-discipline-catalog interpretation. Require BC-5.39.001 literal streak 3/3.

## User Decisions Log

| Date | Decision ID | Question | Decision |
|------|-------------|----------|----------|
| 2026-05-16 | UD-001 | Pass 11 architect work disposition (interrupted commit recovery) | Option A pre-authorized — commit architect's work as-is at a3a83b1 |
| 2026-05-16 | UD-002 | Convergence threshold per F-PASS12-O2 (Pass 16 adversary STRONG-ESCALATE recommendation) | **Option C** — continue cascade without discipline catalog freeze. NO convergence-by-stable-discipline-catalog. NO move to Phase 2 until BC-5.39.001 literal streak 3/3 achieved. Accept that meta-rule self-violation may recur. |
| 2026-05-17 | UD-003 | F-PASS12-O2 3rd STRONG-ESCALATE (Pass 18 adversary recommendation): CRITICAL plateau at 5 passes + meta-rule self-violation at 8 recurrences both thresholds tripped; 3 options presented (a) continue, (b) carve-out exemption, (c) declare-converged-by-fiat | **Option (a) continue cascade** — same as UD-002; meta-rule self-violation class explicitly acknowledged as predictable recurring pattern; no pivot to carve-out or declare-converged-by-fiat |

## Pass 11 Recovery Note (historical)

Pass 11 architect work was interrupted mid-commit on 2026-05-16 and recovered via Option A pre-authorized commit at SHA a3a83b1; cascade resumed without re-running architect work. Pass 11 state-mgr FINAL closed this burst. Pass 11 also produced two corrective bursts within the architect role (343c378, c35de6f) — see TD-VSDD-053-spirit advisory section above.

## Where to find the rest

- **Detailed handoff:** `.factory/SESSION-HANDOFF.md`
- **Task ledger:** `.factory/TASK-LIST.md`
- **Adversary cascade reports (Phase 1d):** `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-{1..20}.md` (Passes 1–20 written)
- **Locked decisions:** `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- **Product brief:** `.factory/specs/product-brief.md` (v0.4.19)
- **PRD:** `.factory/specs/prd/index.md` (v0.1.10) + supplements
- **BC-INDEX:** `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.9, 95 BCs)
- **Architecture:** `.factory/specs/architecture/ARCH-INDEX.md` (v0.1.22, commit 9734b40) + 17 ADRs (6 at v1.1 + 2 at v1.2 = 8 with Changelog) + 18 SS-NN (all at v1.1+) + VP-INDEX v0.1.6 + 27 VPs (4 at v1.2 + VP-004 at v1.1 + VP-012 at v1.3 = 6 with Changelog)
- **Project conventions:** `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
