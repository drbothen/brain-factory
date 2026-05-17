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
phase_1d_status: IN-PROGRESS — Pass 28 CLOSED; 28 passes complete (24 FAIL with CRITICAL, 4 FAIL no CRITICAL — Pass 28 CRITICAL=1); 55 fix-bursts complete; streak 0/3; CRITICAL=1 (14th recurrence meta-rule self-violation class — regex-as-definition fallacy in sub-check (i) known-list coverage); UD-003 in effect
session_continuity: ACTIVE-CASCADE — Pass 28 closed; resume by dispatching Pass 29 adversary — 8th 1/3-streak candidate
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

## Pass 28 CLOSED — Pass 29 next-action

**Pass 20 closure summary:** Pass 20 adversary persisted at commit f3e7ca2 (FAIL — 1 CRITICAL + 2 IMPORTANT + 2 SUGGESTIONS + 2 OBSERVATIONS). Architect burst 9734b40 closed F-PASS20-C1 (replaced F-PASS19-O1 canonical-baseline scope clause with actual 15-prior-burst sweep enumeration; sweep result: 2 same-commit-sibling-violations found post-F-PASS18-O1 codification — Pass 18 a73b64a and Pass 19 9172878, both closed) + F-PASS20-I2 (removed circular self-validation carve-out from F-PASS19-O1 inline self-check). ARCH-INDEX bumped to v0.1.22. NO PO burst (F-PASS11-O1 + discipline #10 still not mirrored to PRD/BC-INDEX). State-mgr FINAL 68025cd closed F-PASS20-I1 (§5 reconciliation rationale corrected — "13" WAS substantiable as individual STRUCTURAL FIX entry count in brief Changelog; row-count-canonical choice documented) + F-PASS20-S1 (§5 v0.4.8 and v0.4.12 rows extended to mention omitted structural fixes). CRITICAL count held at 1 for 7th consecutive pass — F-PASS20-O2 observation; NO re-escalation per UD-003.

**Pass 21 closure summary:** Pass 21 adversary persisted at commit e60e185 (FAIL — 0 CRITICAL + 1 IMPORTANT + 1 SUGGESTION + 2 OBSERVATIONS). CRITICAL PLATEAU BROKEN at 7 passes — first zero-CRITICAL pass since Phase 1d cascade began. NO architect burst (F-PASS21-I1 + F-PASS21-S1 both state-manager-routed). NO PO burst (F-PASS21-O2 accepted as OBSERVATION — meta-rules not mirrored to PRD/BC-INDEX confirmed out-of-scope). State-mgr FINAL 926d5cc closed F-PASS21-I1 (3 stale `(this commit)` markers in narrative prose replaced with actual SHAs across STATE.md + SESSION-HANDOFF + TASK-LIST; §9 resume verification rephrased to push reader to authoritative source) + F-PASS21-S1 (§5 v0.4.8 + v0.4.12 drift class columns extended to symmetric two-class format) + codified NEW discipline #24 (Stale-temporal-marker grep sub-check; both scopes declared) + added sub-check (j) to state-mgr FINAL discipline list (now 10 sub-checks).

**Pass 22 closure summary:** Pass 22 adversary persisted at commit 1b02a98 (FAIL — 0 CRITICAL + 2 IMPORTANT + 1 SUGGESTION + 2 OBSERVATIONS). 2nd consecutive zero-CRITICAL pass — plateau-broken state holds. NO architect burst (F-PASS22-I1 + F-PASS22-I2 + F-PASS22-S1 + F-PASS22-O1 all state-manager-routed). NO PO burst. State-mgr FINAL 04a0ee9 closed F-PASS22-I1 (broadened discipline #24 regex from narrow `\(this commit\)|HEAD = this commit` to full deictic-class `\(this commit\)|\(this burst\)|\bthis commit\b|\bthis burst\b` (word boundaries match across `in this commit`, `in this burst`, and variants); codified explicit exemptions for cascade-table rows + §8 commit-row-ledger + definitional self-references; per-marker enumeration of 9 stale deictics replaced with actual SHAs) + F-PASS22-I2 (§13 prose updated from "All 20 passes" to "All 22 passes" after Pass 22 row added; discipline #23 sweep methodology extended to prose-paragraph count claims) + F-PASS22-S1 (discipline #24 canonical-baseline scope now per-marker enumeration per discipline #19) + F-PASS22-O1 (§8 commit-row-ledger scope codified explicitly in discipline #24 exemptions) + extended sub-check (i) to bind derived enumeration claims.

**Pass 23 closure summary:** Pass 23 adversary persisted at commit 2463acb (FAIL — 0 CRITICAL + 2 IMPORTANT + 1 SUGGESTION + 2 OBSERVATIONS). 3rd consecutive zero-CRITICAL pass — plateau-broken state holds. NO architect burst (F-PASS23-I1 + F-PASS23-I2 + F-PASS23-S1 + F-PASS23-O1 all state-manager-routed). NO PO burst. State-mgr FINAL closes F-PASS23-I1 (§8 Pass 21 state-mgr FINAL self-row back-filled to `926d5cc`; exemption (b) scope clarified — CURRENT self-row only; sub-check (k) codified to enforce prior-row back-fill) + F-PASS23-I2 (SESSION-HANDOFF §13 'Pass reports' line referencing adversary-pass-{1..N}.md brace-glob corrected; discipline #23 sweep methodology extended to path-glob count expressions; sub-check (i) extended) + F-PASS23-S1 (discipline #24 regex narrative canonicalized to byte-identical form `\(this commit\)|\(this burst\)|\bthis commit\b|\bthis burst\b` across STATE.md + SESSION-HANDOFF; discipline #19 extended — regex/pattern descriptions MUST be byte-identical) + F-PASS23-O1 (Option (i) adjudicated: accept over-permissive exemption + false-negative risk documented explicitly in discipline #24).

**Pass 24 closure summary:** Pass 24 adversary persisted at commit bef4508 (FAIL — 1 CRITICAL + 1 IMPORTANT + 2 SUGGESTIONS + 2 OBSERVATIONS). Plateau-broken state ENDED — CRITICAL=1 (11th recurrence meta-rule self-violation). NO architect burst. NO PO burst. State-mgr FINAL closes F-PASS24-C1 (exemption (c) grep extended from `sub-check \(j\)` to `sub-check \([jk]\)` + future-sub-check extension requirement codified in discipline #24 + sub-check (k) rewritten to avoid literal deictic markers in its body) + F-PASS24-I1 (Pass 23 closure narrative line-number citations replaced with semantic anchors across STATE.md + SESSION-HANDOFF + TASK-LIST) + F-PASS24-S1 (discipline #19 extension clarified: "byte-identical" applies to regex VALUE between backticks, not wrapper sentence) + F-PASS24-S2 (sub-check (k) body rewritten; cardinality constraint folded into sub-check (k) as standalone verification) + F-PASS24-O2 (sub-check audit trail codified: commit-body summary line required).

**Pass 25 closure summary:** Pass 25 adversary persisted at commit 42d8f55 (FAIL — 1 CRITICAL + 2 IMPORTANT + 1 SUGGESTION + 2 OBSERVATIONS). CRITICAL=1 for 2nd consecutive pass post-plateau-end (12th recurrence meta-rule self-violation class). 4th 1/3-streak candidate MISSED. NO architect burst. NO PO burst. State-mgr FINAL 0a7d54c closes F-PASS25-C1(a) (exemption (a) regex fixed — replaced structurally-broken `^[^|]*| state-mgr FINAL ✓ (this commit)` with substring match `state-mgr FINAL ✓ (this commit)` requiring no anchor; cascade-table rows correctly exempted regardless of column depth) + F-PASS25-C1(b) (F-PASS13-I1 descriptive narrative in SESSION-HANDOFF back-filled to paraphrase without literal deictic markers — three narrative sentences rewritten) + F-PASS25-C1(c) (anti-carve-out clause codified in discipline #24: PASS marks may ONLY be emitted when the discipline-defined PASS condition is met; "pre-existing residuals" is not a permitted justification) + F-PASS25-I1 (Pass 24 closure narrative corrected — sub-check (k) body DOES still contain literal `(this commit)` in grep argument as definitional necessity; closure narrative now accurately states this and confirms exemption (c) handles the false-positive via `sub-check \([jk]\)` filter) + F-PASS25-I2 (current_streak frontmatter rephrased — streak has been 0/3 for all 25 Phase 1d passes, never advanced) + F-PASS25-S1 (audit-trail format canonicalized: status values PASS/FAIL/NA with explicit active-pass count and NA list) + F-PASS25-O2 (anti-carve-out clause addresses process-gap; subsumed by F-PASS25-C1(c)).

**Pass 26 closure summary:** Pass 26 adversary persisted at commit 05015cb (FAIL — 0 CRITICAL + 3 IMPORTANT + 1 SUGGESTION + 2 OBSERVATIONS). CRITICAL=0 — meta-rule self-violation class did NOT recur. 5th 1/3-streak candidate MISSED. NO architect burst. NO PO burst. State-mgr FINAL a3a72f7 closes F-PASS26-I1 (TASK-LIST §15 TOP OF STACK header updated to Pass 26 CLOSED / Pass 27 next-action) + F-PASS26-I2 (SESSION-HANDOFF §6 header parametrization updated to Pass 25 as most recent discipline-modifying pass — NOTE: self-violated by burst; corrected at Pass 27 F-PASS27-C1) + F-PASS26-I3 (TASK-LIST task #127a pending back-fill annotation replaced with confirmed SHA bc479e1 back-filled by Pass 25 state-mgr FINAL 0a7d54c) + F-PASS26-S1 (§3c F-PASS25-C1(b) closure narrative enumerated to 3 specific SESSION-HANDOFF locations) + F-PASS26-O1 (TASK-LIST task #125a SHA placeholder 926d5cc-followup replaced with 04a0ee9; sub-check (d) extended to TASK-LIST.md SHA-shaped placeholders) + F-PASS26-O2 (sub-check (i) extended to cover parameterized-narrative headers — pattern CLOSED-PARTIAL; burst self-violated extension; corrected at Pass 27).

**Pass 27 closure summary:** Pass 27 adversary persisted at commit 139dc14 (FAIL — 1 CRITICAL + 3 IMPORTANT + 0 SUGGESTIONS + 1 OBSERVATION). CRITICAL=1 — 13th recurrence meta-rule self-violation class (parameterized-header self-violation). 6th 1/3-streak candidate MISSED. NO architect burst. NO PO burst. State-mgr FINAL cea6553 closes F-PASS27-C1 (SESSION-HANDOFF §6 header corrected to Pass 27; F-PASS26-O2 two-form definitional drift canonicalized to single primary criterion "current pass number at the time of the state-mgr FINAL burst"; sub-check (i) extended with broadened pattern regex `\(Pass [0-9]+ (—|CLOSED|IN-PROGRESS|next-action)`; parameterized-header sweep across STATE.md + SESSION-HANDOFF + TASK-LIST) + F-PASS27-I1 (STATE.md §94 updated to Pass 27 CLOSED; sub-check (i) pattern broadened to cover full (Pass N VERB) family) + F-PASS27-I2 (SESSION-HANDOFF §3 Phase 1d status bullet updated to Pass 27 values: 54 fix-bursts, 13th recurrence) + F-PASS27-I3 (STATE.md frontmatter count-balance arithmetic corrected: zero-CRITICAL passes verified as 4 at positions 21+22+23+26; corrected from "23 FAIL with CRITICAL, 3 FAIL no CRITICAL" to "22 FAIL with CRITICAL, 4 FAIL no CRITICAL" — both counts changed: CRITICAL 23→22, no-CRITICAL 3→4; sub-check (c) extended to verify BOTH N+M=total AND individual N and M accuracy for paired count claims) + F-PASS27-O1 (addressed by C1 canonicalization; new meta-note codified in sub-check (i) extension: primary-criterion phrasing MUST be byte-identical).

**Pass 28 closure summary:** Pass 28 adversary persisted at commit b1b3fd4 (FAIL — 1 CRITICAL + 2 IMPORTANT + 0 SUGGESTIONS + 2 OBSERVATIONS). CRITICAL=1 — 14th recurrence meta-rule self-violation class (regex-as-definition fallacy: sub-check (i) broadened regex covers only 2 of 5 known parameterized headers; missed stale SESSION-HANDOFF:94 in the same Pass 27 burst that broadened the regex). 7th 1/3-streak candidate MISSED. NO architect burst. NO PO burst. State-mgr FINAL closes F-PASS28-C1 (SESSION-HANDOFF:94 updated to Pass 28 CLOSED / dispatch Pass 29; sub-check (i) broadened to semantic-intent authority with known-list of 5 parameterized headers + complementary semantic grep `Pass [0-9]+ ` requiring manual verification; regex demoted from definition to convenience subset) + F-PASS28-I1 (known-list of 5 parameterized headers codified byte-identically) + F-PASS28-I2 (STATE.md line 44 F-PASS27-I3 description reconciled byte-identical with SESSION-HANDOFF:157 — corrected from ambiguous single-count-change description to accurate both-counts-changed description: CRITICAL 23→22, no-CRITICAL 3→4) + F-PASS28-O1 (exemption (c) extended with alternation `^\| (.*?) \| (adversary|spec|state) \|` to explicitly exempt §8 commit-row-ledger data rows; sub-check (j) re-run and verified clean) + F-PASS28-O2 (14th recurrence logged; NO re-escalation per UD-003).

**User decision (UD-002):** OPTION C in effect — continue cascade without discipline catalog freeze. No convergence-by-stable-discipline-catalog interpretation. No move to Phase 2 until BC-5.39.001 literal streak 3/3 achieved. User accepts that meta-rule self-violation class may recur in future passes.

**User decision (UD-003):** OPTION (a) reaffirmed on 2026-05-17 — continue cascade per UD-002; same Option C policy; 5-pass plateau and 8-recurrence evidence does not change the human directive. 3rd STRONG-ESCALATE resolved; F-PASS12-O2 escalation clock reset.

**Top-of-stack action:** Dispatch Pass 29 adversary (chat-only per F-PASS12-O1; no catalog freeze per UD-002/UD-003). Pass 29 is the 8th 1/3-streak candidate — if Pass 29 finds 0C+0I, streak advances to 1/3. Continue cascade until BC-5.39.001 literal streak 3/3.

---

## Resume procedure for FRESH-CONTEXT ORCHESTRATOR

**Read these documents IN ORDER before dispatching any agent:**

1. `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
2. `/Users/jmagady/Dev/brain-factory/.factory/STATE.md` (this file)
3. `/Users/jmagady/Dev/brain-factory/.factory/SESSION-HANDOFF.md`
4. `/Users/jmagady/Dev/brain-factory/.factory/TASK-LIST.md`
5. `/Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1d-spec/adversary-pass-28.md` (most recent findings — Pass 28 CLOSED; Pass 29 adversary is next-action)

**Pre-dispatch verification:**
- Confirm HEAD = Pass 28 state-mgr FINAL via `git log --oneline -1` (expected subject: `factory(state): Phase 1d Pass 28 FINAL ...`)
- Confirm no uncommitted changes via `git status --short`

**Resume steps (in order):**

1. Dispatch Pass 29 adversary per BC-5.39.001 cascade protocol (chat-only per F-PASS12-O1; no catalog freeze per Option C / UD-002/UD-003). Pass 29 is the 8th 1/3-streak candidate.
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

## Phase 1d Adversarial Cascade — IN-PROGRESS (Pass 28 CLOSED)

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
| 20 | FAIL | 1C+2I+2S+2O | f3e7ca2 | architect 9734b40 + state-mgr FINAL 68025cd | 0/3 |
| 21 | FAIL | 0C+1I+1S+2O | e60e185 | state-mgr FINAL 926d5cc | 0/3 |
| 22 | FAIL | 0C+2I+1S+2O | 1b02a98 | state-mgr FINAL ✓ 04a0ee9 | 0/3 |
| 23 | FAIL | 0C+2I+1S+2O | 2463acb | state-mgr FINAL ✓ 3388678 | 0/3 |
| 24 | FAIL | 1C+1I+2S+2O | bef4508 | state-mgr FINAL ✓ bc479e1 | 0/3 |
| 25 | FAIL | 1C+2I+1S+2O | 42d8f55 | state-mgr FINAL ✓ 0a7d54c | 0/3 |
| 26 | FAIL | 0C+3I+1S+2O | 05015cb | state-mgr FINAL ✓ a3a72f7 | 0/3 |
| 27 | FAIL | 1C+3I+0S+1O | 139dc14 | state-mgr FINAL ✓ cea6553 | 0/3 |
| 28 | FAIL | 1C+2I+0S+2O | b1b3fd4 | state-mgr FINAL ✓ (this commit) | 0/3 |

**CRITICAL trajectory (CRITICAL count):** 7→4→2→3→2→2→2→1→1→2→2→2→2→1→1→1→1→1→1→1→0→0→0→1→1→0→1→1. CRITICAL plateau at 1 for 7 consecutive passes (Pass 14..Pass 20); BROKEN at Pass 21 (zero CRITICAL); plateau-broken state held 3 consecutive passes (Pass 21, Pass 22, Pass 23); ENDED at Pass 24 (CRITICAL=1, F-PASS24-C1 11th recurrence); CONTINUED at Pass 25 (CRITICAL=1, F-PASS25-C1 12th recurrence); RETURNED TO ZERO at Pass 26 (meta-rule self-violation class did NOT recur); RETURNED TO 1 at Pass 27 (F-PASS27-C1 13th recurrence — parameterized-header self-violation); HELD AT 1 at Pass 28 (F-PASS28-C1 14th recurrence — regex-as-definition fallacy in sub-check (i) known-list coverage).

## 24 Structural-Fix Disciplines Codified During Phase 1d

Inherited from Phase 1a (10 confirmed structural-fix disciplines — see brief v0.4.19 Changelog or SESSION-HANDOFF §5; first structural-fix discipline emerged at v0.4.5; v0.4.1 through v0.4.4 and v0.4.9 had no STRUCTURAL FIX labels).

Phase 1d additions (24 confirmed committed disciplines):
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
24. (Pass 21, broadened Pass 22 F-PASS22-I1, F-PASS23-S1/I1/O1, exemption (c) extended F-PASS24-C1, exemption (a) fixed F-PASS25-C1(a), anti-carve-out codified F-PASS25-C1(c)) Stale-temporal-marker grep state-mgr FINAL sub-check — narrative prose in operational state docs (STATE.md, SESSION-HANDOFF, TASK-LIST) MUST NOT contain any deictic temporal marker: `(this commit)`, `(this burst)`, `this commit`, `this burst`, `in this commit`, `in this burst`, or any variant. Use actual SHAs only. EXEMPTIONS (codified Pass 22 F-PASS22-O1 + F-PASS22-I1; exemption (b) scope clarified F-PASS23-I1; exemption (a) fixed F-PASS25-C1(a)): (a) cascade-table rows: lines containing the substring `state-mgr FINAL ✓ (this commit)` — substring match, no anchor required (F-PASS25-C1(a) fix: the prior anchored regex `^[^|]*| state-mgr FINAL ✓ (this commit)` was structurally broken because cascade-table rows place the FINAL-marker cell 4-5 columns deep, not at position 2; substring match correctly exempts all cascade-table rows regardless of column depth); (b) §8 commit-row-ledger CURRENT state-mgr FINAL self-row ONLY (line format `| (this commit) | state | ... |`); the textual marker is used AT AUTHORING TIME by the state-mgr FINAL burst writing its own row. Prior state-mgr FINAL rows in §8 MUST be back-filled to their actual SHA as part of the next state-mgr FINAL burst (per F-PASS23-I1 closure). Sub-check (k) enforces back-fill. NOTE F-PASS23-O1 risk (Option i accepted): exemption (c) grep is intentionally over-permissive — excludes ANY line containing those strings, not only the definition body. This creates a false-negative surface: future stale-marker bugs appearing in narrative prose that incidentally mentions discipline #24 will be silently exempted. Mitigation: manual review of sub-check (j) results retains adversary-detected drift as catch-net. If false-negative bugs surface in practice, upgrade to sentinel-comment-bounded exemption. (c) definitional self-references about the deictic-marker class itself (the body of disciplines #16, #24, and sub-checks (j)/(k) — this very sub-rule, its sub-check definitions, and the F-PASS13-I1 historical narrative in §6 discipline table). NOTE F-PASS24-C1: exemption (c) grep extended from `sub-check \(j\)` to `sub-check \([jk]\)` to cover both sub-check (j) and sub-check (k) body text. When adding any new sub-check (l), (m), etc. to the state-mgr FINAL discipline list, the addition MUST be reflected in exemption (c) grep in the SAME burst, per F-PASS24-C1 closure. Canonical regex (byte-identical across all narrative locations per F-PASS23-S1): `\(this commit\)|\(this burst\)|\bthis commit\b|\bthis burst\b`. NOTE F-PASS24-S1 clarification: "byte-identical" in discipline #19 extension applies to the regex VALUE (the regex itself, character-for-character between backticks), NOT to the wrapper-sentence narrative introducing the regex. The wrapper sentence may vary in form but the regex value MUST be identical. ANTI-CARVE-OUT CLAUSE (F-PASS25-C1(c)): PASS marks (`j:PASS`) may ONLY be emitted when the discipline-defined PASS condition is met. For sub-check (j) PASS = grep returns EMPTY after exemptions. If sub-check (j) returns un-exempted hits, the audit MUST emit `j:FAIL` and the burst MUST NOT be committed until either (1) hits are fixed structurally, OR (2) exemptions (a)/(b)/(c) are extended in the SAME BURST to cover the hits AND the discipline #24 codification text reflects the extension. Documenting un-exempted hits as "pre-existing structural residuals", "unchanged from prior passes", or "consistent with F-PASS23-O1 accepted false-negative surface" is NOT a permitted PASS justification. F-PASS23-O1 accepted false-NEGATIVE risk (hits not flagged); it did NOT accept false-POSITIVE certification (hits flagged but claimed PASS). Incremental scope: applied before every state-manager commit. Sub-check (j) grep (fixed F-PASS25-C1(a)): `grep -nE '\(this commit\)|\(this burst\)|\bthis commit\b|\bthis burst\b' .factory/STATE.md .factory/SESSION-HANDOFF.md .factory/TASK-LIST.md | grep -v 'state-mgr FINAL ✓ (this commit)' | grep -v '^[^|]*| (this commit) | state ' | grep -vE 'discipline #(16|24)|sub-check \([jk]\)|MUST NOT contain'` — must return empty; any remaining hits are stale-marker defects requiring replacement with actual SHAs. Canonical-baseline scope: Pass 22 F-PASS22-I1 broadening triggered by Pass 21 codification using narrow regex that missed 8 class-variant deictics in same commit (926d5cc). Per-marker enumeration of Pass 22 fix-burst replacements: (1) STATE.md Pass 21 closure summary line containing `(this burst)` → replaced with `926d5cc`; (2) SESSION-HANDOFF.md §13 closing paragraph line containing `in this commit (state-mgr FINAL)` → replaced with `926d5cc`; (3) SESSION-HANDOFF.md §8 row → adjudicated per F-PASS22-O1 Option (a): §8-commit-row-ledger exemption codified; row text left as `| (this commit) | state | ... |` (textual marker per exemption clause (b)); (4) SESSION-HANDOFF.md Pass 21 closure note line containing `(this burst)` → replaced with `926d5cc`; (5) SESSION-HANDOFF.md fix-burst count note line containing `this commit` (no parens) → replaced with `926d5cc`; (6) SESSION-HANDOFF.md frontmatter current_pass_number line containing `this commit` → replaced with fixed descriptor; (7) SESSION-HANDOFF.md §3c heading line containing `(Pass 21 this burst)` → replaced with `(Pass 21 - commit 926d5cc)`; (8) TASK-LIST.md header line containing `this commit` → replaced with `926d5cc`; (9) TASK-LIST.md task #57 cell containing `this commit` → replaced with `926d5cc`. Total: 9 deictic markers swept; §8-row scope extension codified; definitional self-reference exemption codified. Sub-check (j) added at Pass 21; total sub-checks now 10. Pass 23 F-PASS23-S1: narrative descriptions byte-canonicalized to `\(this commit\)|\(this burst\)|\bthis commit\b|\bthis burst\b` across all locations. Discipline #19 extended: regex/pattern descriptions MUST be byte-identical across all narrative locations (no paraphrase for pattern specifications). Pass 24 F-PASS24-S1 clarification: "byte-identical" applies to regex VALUE only (not wrapper sentence). Pass 25 F-PASS25-C1(a): exemption (a) regex fixed from anchored form to substring match.

## TD-VSDD-053-spirit Advisories (corrective-burst-within-pass pattern)

Phase 1d has produced "corrective burst within same logical pass" sequences that survive the single-commit-chain hook detector (no banned theme word) but violate TD-VSDD-053 in spirit. Documented audit trail (not retroactively rebased):

- Pass 11: architect a3a83b1 → 343c378 (missing changelog header correction) → c35de6f (hallucinated inventory correction); state-mgr e37f1e3 → 7ea3f71 (back-fill self-SHA). 5 commits in one logical Pass 11 cycle.
- Pass 12: clean (1 architect + 1 PO + 1 state-mgr FINAL = 3 commits, one per agent role).
- Pass 13: clean (1 architect + 1 state-mgr FINAL = 2 commits, one per agent role).
- Pass 14: clean (1 adversary persist + 1 architect + 1 state-mgr FINAL = 3 commits).
- Pass 15: clean (1 adversary persist + 1 architect + 1 state-mgr FINAL = 3 commits).
- Pass 16: clean (1 adversary persist 8aefca8 + 1 architect 2a1f543 + 1 state-mgr FINAL 24e229d = 3 commits, one per agent role).
- Pass 17: clean (1 adversary persist 87ebf2d + 1 architect b70fc7d + 1 PO 2f247fc + 1 state-mgr FINAL 6ed900d = 4 commits, one per agent role).

Going-forward orchestrator discipline: dispatch agents with explicit single-commit-per-burst instructions; verify draft outputs before commit to avoid corrective bursts.

## state-manager FINAL discipline (11 sub-checks + audit-trail requirement)

Before committing, state-manager FINAL MUST run:
- (a) inherits_from re-pin to post-all-bursts parent versions
- (b) path-currency check via `test -e` on all cited .factory/specs/ paths
- (c) absolute-quantity audit — verify counts match actual artifact state; extended F-PASS27-I3: for any paired count claim of the form "N + M = total" (e.g., "N FAIL with CRITICAL, M FAIL no CRITICAL"), verify BOTH that N + M = total AND that N and M individually match actual artifact counts — arithmetic validity does not imply individual accuracy
- (d) cited-SHA verification — confirm all commit SHAs cited in state docs exist; scope includes TASK-LIST.md; strings matching pattern `[0-9a-f]{7,}(-followup|-placeholder|-TBD)` are SHA-shaped placeholders and are defects requiring back-fill (F-PASS26-O1 extension)
- (e) changelog factual-accuracy spot-check — scan for corrective-NOTE pattern
- (f) in-document title-cell sibling-sweep — ARCH-INDEX Document Map vs VP-INDEX Summary
- (g) dual-scope discipline verification — every newly codified discipline declares both scopes
- (h) adversary pre-flight verification — confirm the adversary pre-flight discipline is correctly stated (incremental + canonical-baseline scopes declared) in ARCH-INDEX Self-Audit Checklist (F-PASS11-O1)
- (i) F-PASS19-O1 same-commit-sibling-check self-applied — every count claim AND every derived enumeration claim YOU write — INCLUDING path-glob count expressions like `{1..N}.md`, prose-paragraph counts like 'All N passes', and any other count-encoding string — satisfies discipline #19 (cite SPECIFIC items not aggregates) AND discipline #23 (header matches body count including this burst's additions); discipline #24 scope clause uses per-marker enumeration (not aggregate count) for each replaced temporal-deictic instance; §13 prose paragraph pass-count claim matches table row count (F-PASS22-I2 extension); extended F-PASS23-I2: path-glob count expressions also covered; extended F-PASS26-O2 (canonicalized primary criterion F-PASS27-C1(b); pattern broadened F-PASS27-I1(b); broadened to SEMANTIC-INTENT AUTHORITY F-PASS28-C1/I1): DISCIPLINE'S AUTHORITY: semantic — every parameterized-narrative reference to Pass N status (closed / next-action / in-progress / etc.) MUST reflect the current pass number at the time of the state-mgr FINAL burst. CANONICAL PRIMARY CRITERION (byte-identical): "current pass number at the time of the state-mgr FINAL burst." The regex `\(Pass [0-9]+ (—|CLOSED|IN-PROGRESS|next-action)` is a CONVENIENCE SUBSET only — it captures parenthetical-form headers but NOT plain-prose-heading-form or dash-prose-form headers. KNOWN-LIST AUTHORITY (F-PASS28-I1; 5 parameterized headers; review ALL 5 at every burst): (1) STATE.md heading: `## Pass N CLOSED — Pass N+1 next-action`; (2) STATE.md heading: `## Phase 1d Adversarial Cascade — IN-PROGRESS (Pass N CLOSED)`; (3) SESSION-HANDOFF heading: `### Step 3 — Pass N is CLOSED; dispatch Pass N+1`; (4) SESSION-HANDOFF heading: `## 6. Phase 1d disciplines (Pass N — ...)`; (5) TASK-LIST heading: `## TOP OF STACK (RESUME ENTRY POINT — Pass N CLOSED; Pass N+1 next-action)`. COMPLEMENTARY SEMANTIC GREP: `grep -nE 'Pass [0-9]+ ' .factory/STATE.md .factory/SESSION-HANDOFF.md .factory/TASK-LIST.md` — each hit must be manually verified as either (1) current pass reference (must match current N), (2) historical reference in closure narrative explicitly pegged to a specific past pass, or (3) exempted context. NOTE F-PASS27-C1(b) canonicalization: prior Form B in SESSION-HANDOFF ("most recent pass that contributed a body note") was retired as primary criterion — Form A is unambiguous. The invented Form C ("most recent discipline-modifying pass") was never codified and is explicitly rejected. NOTE F-PASS27-O1: discipline-extension primary-criterion phrasing MUST be byte-identical across all codification locations
- (j) stale-temporal-marker grep (broadened F-PASS22-I1; exemption (c) extended F-PASS24-C1; exemption (a) fixed F-PASS25-C1(a); exemption (c) extended F-PASS28-O1) — `grep -nE '\(this commit\)|\(this burst\)|\bthis commit\b|\bthis burst\b' .factory/STATE.md .factory/SESSION-HANDOFF.md .factory/TASK-LIST.md | grep -v 'state-mgr FINAL ✓ (this commit)' | grep -v '^[^|]*| (this commit) | state ' | grep -vE 'discipline #(16|24)|sub-check \([jk]\)|MUST NOT contain' | grep -vE '^\| (.*?) \| (adversary|spec|state) \|'` — must return empty; any remaining hits are stale-marker defects requiring replacement with actual SHAs (discipline #24). EXEMPTIONS: (a) cascade-table rows: lines containing the substring `state-mgr FINAL ✓ (this commit)` — substring match (no anchor); this form correctly exempts cascade-table rows regardless of column depth (F-PASS25-C1(a) fix; prior anchored regex `^[^|]*| state-mgr FINAL ✓ (this commit)` was structurally broken — first pipe anchor required marker in position 2 but cascade-table rows place it 4-5 columns deep); (b) §8 commit-row-ledger CURRENT state-mgr FINAL self-row ONLY (line format `| (this commit) | state ...`); (c) definitional self-references about the deictic-marker class itself (body of disciplines #16, #24, and sub-checks (j)/(k) — covers F-PASS13-I1 historical narrative; covered by `discipline #(16|24)|sub-check \([jk]\)` filter) AND §8 commit-row-ledger historical data rows (F-PASS28-O1 extension: rows matching `^\| (.*?) \| (adversary|spec|state) \|` are §8 ledger rows whose narrative cells may contain quoted deictic strings as historical closure-narrative content; these are NOT current-burst stale markers and must be systematically exempted). NOTE F-PASS24-C1: exemption (c) grep extended from `sub-check \(j\)` to `sub-check \([jk]\)` to cover both sub-checks (j) and (k) body text. When adding any new sub-check (l), (m), etc. to this discipline list, the addition MUST be reflected in exemption (c) grep in the same burst, per F-PASS24-C1 closure. ANTI-CARVE-OUT CLAUSE (F-PASS25-C1(c)): PASS marks (`j:PASS`) may ONLY be emitted when the discipline-defined PASS condition is met. For sub-check (j) PASS = grep returns EMPTY after exemptions. If sub-check (j) returns un-exempted hits, the audit MUST emit `j:FAIL` and the burst MUST NOT be committed until either (1) hits are fixed structurally, OR (2) exemptions (a)/(b)/(c) are extended in the SAME BURST to cover the hits AND the discipline #24 codification text reflects the extension. Documenting un-exempted hits as "pre-existing structural residuals", "unchanged from prior passes", or "consistent with F-PASS23-O1 accepted false-negative surface" is NOT a permitted PASS justification. F-PASS23-O1 accepted false-NEGATIVE risk (hits not flagged); it did NOT accept false-POSITIVE certification (hits flagged but claimed PASS).
- (k) §8 prior-row back-fill — verify that the §8 commit-row-ledger in SESSION-HANDOFF.md contains exactly ONE row whose type-cell reads `state` and whose SHA-cell is the current-burst deictic marker (per discipline #24 exemption (b)). All prior state-mgr FINAL rows in §8 MUST already be back-filled to their actual SHAs. Verification: run `grep -nE '^\| \(this commit\) \| state ' .factory/SESSION-HANDOFF.md`; if result count is greater than 1, back-fill the excess rows before committing. If result count is 0 and this is a state-mgr FINAL burst, the §8 self-row is missing (defect). (F-PASS23-I1 closure; sub-check (k) body rewritten F-PASS24-C1 + F-PASS24-S2 adjudication to avoid literal deictic in defining text)

**Sub-check audit-trail requirement (F-PASS24-O2; format canonicalized F-PASS25-S1):** state-mgr FINAL commit messages MUST include a sub-check summary line in the commit body. Canonical format: `state-checks: a:<status> b:<status> c:<status> d:<status> e:<status> f:<status> g:<status> h:<status> i:<status> j:<status> k:<status> — <N>/<N> active passed (<M> NA: <list>)` where status is `PASS`, `FAIL`, or `NA`. Example (hypothetical): `state-checks: a:NA b:PASS c:PASS d:PASS e:NA f:NA g:NA h:NA i:PASS j:PASS k:PASS — 6/6 active passed (5 NA: a,e,f,g,h)`. Missing summary OR any non-PASS/NA status = unverified burst. The prior format using tick glyphs (✓/NA✓) is retired; the new format with explicit status labels is canonical.

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

Pass 11 architect work was interrupted mid-commit on 2026-05-16 and recovered via Option A pre-authorized commit at SHA a3a83b1; cascade resumed without re-running architect work. Pass 11 state-mgr FINAL (e37f1e3 + back-fill 7ea3f71) closed the Pass 11 burst. Pass 11 also produced two corrective bursts within the architect role (343c378, c35de6f) — see TD-VSDD-053-spirit advisory section above.

## Where to find the rest

- **Detailed handoff:** `.factory/SESSION-HANDOFF.md`
- **Task ledger:** `.factory/TASK-LIST.md`
- **Adversary cascade reports (Phase 1d):** `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-{1..28}.md` (Passes 1–28 written)
- **Locked decisions:** `.factory/planning/stage-3-locks.md` (SL-1 through SL-11)
- **Product brief:** `.factory/specs/product-brief.md` (v0.4.19)
- **PRD:** `.factory/specs/prd/index.md` (v0.1.10) + supplements
- **BC-INDEX:** `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.9, 95 BCs)
- **Architecture:** `.factory/specs/architecture/ARCH-INDEX.md` (v0.1.22, commit 9734b40) + 17 ADRs (6 at v1.1 + 2 at v1.2 = 8 with Changelog) + 18 SS-NN (all at v1.1+) + VP-INDEX v0.1.6 + 27 VPs (4 at v1.2 + VP-004 at v1.1 + VP-012 at v1.3 = 6 with Changelog)
- **Project conventions:** `/Users/jmagady/Dev/brain-factory/CLAUDE.md`
