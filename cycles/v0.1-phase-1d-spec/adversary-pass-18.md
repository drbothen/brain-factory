---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 18
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [p1 7C+12I+5S+4O, p2 4C+8I+3S+4O, p3 2C+4I+2S+2O, p4 3C+3I, p5 2C+3I, p6 2C+3I, p7 2C+3I, p8 1C+3I, p9 1C+2I, p10 2C+3I, p11 2C+3I, p12 2C+3I+2O, p13 2C+3I+2O, p14 1C+2I+2O, p15 1C+2I+1O, p16 1C+2I+2O, p17 1C+3I+1S+2O]
producing_agents:
  - pass-17 persist 87ebf2d
  - pass-17 architect b70fc7d
  - pass-17 PO 2f247fc
  - pass-17 state-mgr FINAL 6ed900d
---

# Adversary Pass 18 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 1
- IMPORTANT: 2
- SUGGESTIONS: 1
- OBSERVATIONS: 2 (1 [process-gap])
- Streak: 0/3 (reset by F-PASS18-C1 — 8th recurrence meta-rule self-violation class)
- NOVELTY: MEDIUM-LOW. Dominant class unchanged (meta-rule self-violation in the codifying burst, now at 8 recurrences; the codified discipline is now discipline #23 itself, which was self-violated in the very FINAL burst that codified its catalog entry). Genuinely novel: F-PASS18-I1 (Pass 17 architect's F-PASS17-S1 closure stated VP file ranges as "v1.0 through v1.3" naming only VP-012 at v1.3, leaving four VPs at v1.2 (VP-014, VP-021, VP-026, VP-027) unnamed in the per-file enumeration — same defect class as F-PASS17-S1 itself, applied at one-level-deeper granularity). Genuinely novel: F-PASS18-S1 (Pass 17 adversary's F-PASS17-S1 evidence section asserted "VP-014 has v1.3" which is factually wrong — VP-014 has v1.2 only; the adversary fabricated evidence).

Target: brief v0.4.19 + PRD v0.1.10 + BC-INDEX v0.1.9 + ARCH-INDEX v0.1.19 + VP-INDEX v0.1.6 + 27 VPs + 17 ADRs + 18 SS-NN + Pass 17 architect/PO/state-mgr FINAL closures.

Trajectory CRITICAL: 7→4→2→3→2→2→2→1→1→2→2→2→2→1→1→1→1→**1**. Plateau at 1 CRITICAL for 5th consecutive pass.

## Pass 17 Closure Verification

| Finding | Claim | Verified | Notes |
|---------|-------|----------|-------|
| F-PASS17-C1 per-sub-rule enumeration | v0.1.18 F-PASS16-C1 entry replaced with four per-sub-rule bullets | YES | ARCH-INDEX confirms the F-PASS16-C1 entry now has four bullets (one per sub-rule F-PASS15-C1/I1/I2/O1), each enumerating Incremental and Canonical-baseline scope text. Closure landed. |
| F-PASS17-S1 canonical-baseline rationale corrected | "at most v1.0 and v1.1/v1.2" replaced with per-artifact-type ranges (SS up to v1.4; ADR up to v1.2; VP up to v1.3) | YES (literal text replaced) BUT with one-level-deeper enumeration gap | ARCH-INDEX now reads "SS-NN files range v1.0 through v1.4 (SS-18 at v1.4); ADR files range v1.0 through v1.2 (ADR-004 + ADR-009 at v1.2); VP files range v1.0 through v1.3 (VP-012 at v1.3)". Verified factual: SS-18=v1.4, ADR-004/009=v1.2, VP-012=v1.3. However, the VP parenthetical names only VP-012 at v1.3 but does not name the four VPs at v1.2 (VP-014, VP-021, VP-026, VP-027) or VP-004 at v1.1 — see F-PASS18-I1. |
| F-PASS17-I3(a) bash sweep extension | sweep extended to PRD/supplements/BC-INDEX/95 BCs | YES | Independently verified: BC files have no `## Changelog` sections (only BC-INDEX does); PRD supplements have no `### v` entries. The `grep -q "^### v"` gate safely skips no-Changelog files. Closure landed correctly. |
| F-PASS17-I3(b) sibling-sweep to PRD/BC-INDEX | disciplines #22 + #23 mirrored into PRD index and BC-INDEX Self-Audit | YES | PRD index and BC-INDEX Self-Audits both contain mirrored discipline #22 and discipline #23 with dual scope. PRD v0.1.10; BC-INDEX v0.1.9; inherits_from re-pinned to prd@v0.1.10. |
| Discipline #23 codification | ARCH-INDEX Self-Audit Checklist entry + STATE.md catalog row + cross-doc mirrors | YES | ARCH-INDEX + STATE.md + SESSION-HANDOFF §6 + PRD + BC-INDEX all carry discipline #23 with dual scope. Wording converges across docs. |
| F-PASS17-I1 SESSION-HANDOFF §6 reconciliation | header "Pass 17 added — 23 total" with body=23 rows | YES | Header and body both at 23; STATE.md catalog ends at #23. Reconciliation complete. |
| F-PASS17-I1(c) TASK-LIST #116b narrative | "22 confirmed" replaces stale "21 confirmed" | YES | Correction landed. |
| F-PASS17-I2 fix-burst count re-derivation | 36 → 40 with footnote | YES | STATE.md and SESSION-HANDOFF cite 40; footnote enumerates 12+3+6+5+3+2+2+2+2+3=40. Arithmetic verified. |
| F-PASS17-O1 process-gap closure | discipline #23 codified across burst boundary (architect + state-mgr cooperated) | YES | Pass 17 architect codified #23 in ARCH-INDEX (b70fc7d); state-mgr FINAL added STATE.md catalog row. |
| F-PASS17-O2 STRONG-ESCALATE recommendation | flagged for orchestrator → human handoff | DEFERRED-TO-HUMAN | UD-002 Option C in effect; no human pivot. Status: awaiting Pass 18+ data. |

Closure assessment: 10 of 10 substantive closure items landed. Cleanest closure since Phase 1d began. **However**, the cleanness does NOT prevent NEW recurrence of meta-rule self-violation class in the very burst that did closures — see F-PASS18-C1.

## CRITICAL findings

### F-PASS18-C1 CRITICAL — Pass 17 state-mgr FINAL burst self-violated newly-codified discipline #23 in the very commit that added discipline #23 to STATE.md catalog; SESSION-HANDOFF §8 header claims "19 commits" while body has 25 rows; 8th recurrence of meta-rule self-violation class

**Files:** `.factory/SESSION-HANDOFF.md` — §8 header at "## 8. Recent session commits"; body table at the same section.

**Evidence:**

SESSION-HANDOFF.md §8 header (grep-anchored on "## 8. Recent session commits"): "## 8. Recent session commits (this session, 2026-05-16 — 19 commits)"

SESSION-HANDOFF.md §8 body table: row count is exactly 25 (Pass 11-17 commits all included). Header claims 19; body has 25; drift is 6 rows.

Discipline #23 incremental scope (codified in this same commit, ARCH-INDEX): "applied before any state-manager or architect burst that updates a section header containing a count claim. The header text MUST be reconciled with body count before commit."

The state-mgr FINAL burst added rows to §8 (Pass 17 architect b70fc7d row, PO 2f247fc row, the (this commit) row — three rows in this commit; prior commits added Pass 14/15/16 architect/state-mgr rows). All these additions accumulated under a stale "19 commits" header. State-mgr was the agent that codified discipline #23 into STATE.md catalog in this same commit; state-mgr was on-notice of the discipline.

Pass 18 dispatch explicitly pre-flagged this: "State-mgr Pass 17 FINAL flagged: SESSION-HANDOFF.md §8 'Recent session commits' header says 'this session, 2026-05-16 — 19 commits' but body has now grown to ~23+ rows after Pass 17 added 4 more. This is discipline #23 class drift (header-vs-body count) that state-mgr noticed but did NOT fix in scope (deferred as historical narrative)." Adversary confirms: this is NOT historical narrative — discipline #23 incremental scope binds the current burst.

**Defect class:** Meta-rule self-violation in the burst that codifies the meta-rule catalog. 8th recurrence (chain: F-PASS10-O1 → F-PASS11-C2 → F-PASS11-I2 → F-PASS13-I3 → F-PASS13-C2 → F-PASS15-I2 → F-PASS16-C1 → F-PASS17-C1 → **F-PASS18-C1 THIS PASS**).

**Counter-argument considered:** Could state-mgr's "historical narrative" framing be a legitimate exemption? The header HAS a count claim ("19 commits"). Discipline #23 binds "any section header containing a count claim." There is no carve-out for "historical-narrative count claims." Could the count be a frozen point-in-time snapshot? The header says "this session, 2026-05-16 — 19 commits" — but rows for Pass 14-17 commits added later in 2026-05-16 are in the table; the snapshot interpretation is broken by the body itself.

**Routing:** vsdd-factory:state-manager. (a) Update the §8 header to "this session, 2026-05-16 — 25 commits" (or current accurate row count after Pass 18 commits land), OR re-scope the header to a non-count-bearing form. Per CLAUDE.md production-grade default, precise count is preferred. (b) Codify in §8 a discipline-#23-implementation note about header-update-on-row-add. (c) Re-audit all other section headers in STATE.md and SESSION-HANDOFF for count-claim drift after this fix (canonical-baseline sweep of discipline #23 across operational state docs).

**Confidence:** HIGH.

## IMPORTANT findings

### F-PASS18-I1 IMPORTANT — Pass 17 architect's F-PASS17-S1 fix corrected the canonical-baseline rationale enumeration but left a one-level-deeper enumeration gap: the new VP range parenthetical names only VP-012 at v1.3 and silently omits the four VPs at v1.2 (VP-014, VP-021, VP-026, VP-027) and VP-004 at v1.1; same defect class as F-PASS17-S1 itself

**Files:** `.factory/specs/architecture/ARCH-INDEX.md` discipline #22 sub-rule Canonical-baseline scope paragraph.

**Evidence:**

ARCH-INDEX (grep-anchored on "VP files range v1.0 through v1.3"): "VP files range v1.0 through v1.3 (VP-012 at v1.3); no out-of-order violations found in any file."

VP frontmatter scan: of 27 VPs, 21 are at v1.0; VP-004 is at v1.1; VP-014, VP-021, VP-026, VP-027 are at v1.2; VP-012 is at v1.3.

The parenthetical "(VP-012 at v1.3)" claims to name the file at the MAX of the range but is incomplete: it lists only the v1.3 outlier, silently omitting the four VPs at v1.2 and VP-004 at v1.1. Per F-PASS15-I1 derived-cell-count enumeration discipline ("do not claim 'all three' unless ARCH-INDEX entry explicitly states all three had drift; enumerate specific cells"), the same enumeration discipline applies here.

Comparing SS and ADR parentheticals in same paragraph: "SS-NN files range v1.0 through v1.4 (SS-18 at v1.4)" — names only SS-18 but SS-02 is at v1.2 per the ARCH-INDEX v0.1.13 history. Also incomplete. "ADR files range v1.0 through v1.2 (ADR-004 + ADR-009 at v1.2)" — correct enumeration of MAX but does not name ADRs at v1.1 (ADR-003, ADR-006, ADR-010, ADR-012, ADR-013, ADR-016 per STATE.md).

**Defect class:** Same as F-PASS17-S1 (inaccurate enumeration in canonical-baseline scope claim) at one level deeper.

**Routing:** vsdd-factory:architect. Replace each parenthetical with complete enumeration:
- "SS-NN files range v1.0 through v1.4 (SS-02 at v1.2; SS-18 at v1.4; all others at v1.1)"
- "ADR files range v1.0 through v1.2 (ADR-003, ADR-006, ADR-010, ADR-012, ADR-013, ADR-016 at v1.1; ADR-004, ADR-009 at v1.2; all others at v1.0)"
- "VP files range v1.0 through v1.3 (VP-004 at v1.1; VP-014, VP-021, VP-026, VP-027 at v1.2; VP-012 at v1.3; all others at v1.0)"

Bump ARCH-INDEX v0.1.19 → v0.1.20.

**Confidence:** HIGH.

### F-PASS18-I2 IMPORTANT — Pass 17 state-mgr FINAL did not apply discipline #23 canonical-baseline sweep to operational state docs as the discipline #23 codification itself implied; canonical-baseline scope at ARCH-INDEX names only the SESSION-HANDOFF §6 instance and "36 fix-bursts" as F-PASS17-I2 closure items, but does NOT enumerate a sweep of all section headers across STATE.md + SESSION-HANDOFF + TASK-LIST

**Files:** `.factory/specs/architecture/ARCH-INDEX.md` discipline #23 canonical-baseline scope clause; `.factory/STATE.md` and `.factory/SESSION-HANDOFF.md` (un-swept headers).

**Evidence:**

Discipline #23 canonical-baseline scope text (grep-anchored on "Pass 17 canonical-baseline sweep identified"): "Pass 17 canonical-baseline sweep identified F-PASS16-I2 paper-fix in SESSION-HANDOFF §6 ('22 total' header over 19-row body); state-manager recommended to reconcile in Pass 17 FINAL burst. Also identified '36 fix-bursts' claim in STATE.md / SESSION-HANDOFF frontmatter that is not derivable from cascade-table body (F-PASS17-I2); state-manager recommended to re-derive from cascade table in Pass 17 FINAL burst."

The canonical-baseline scope enumeration lists exactly TWO findings, neither of which was the result of a systematic sweep. A proper canonical-baseline sweep (per discipline #10 dual-scope rationale: "one-time sweep over entire spec inventory at codification time") would require enumerating ALL section headers in STATE.md, SESSION-HANDOFF, and TASK-LIST that carry count claims. The §8 "19 commits" header drift (now F-PASS18-C1) is direct proof that the canonical-baseline sweep was NOT performed.

**Defect class:** Discipline #23 codification missed canonical-baseline scope sweep of operational state docs; canonical-baseline scope was reduced to "enumerate the two findings that motivated codification" rather than "systematic sweep at codification time per F-PASS10-O1."

**Counter-argument considered:** Could canonical-baseline scope be narrowly-bounded to "spec corpus only" and explicitly exclude operational state docs? Architect's codification text does not say this. Additionally, discipline #23 example list in ARCH-INDEX itself names "(M confirmed disciplines)" and "N fix-bursts complete" — both operational state doc patterns — suggesting operational state docs ARE in scope. Narrow-bound interpretation fails.

**Routing:** vsdd-factory:state-manager. (a) Run discipline #23 canonical-baseline sweep across STATE.md, SESSION-HANDOFF.md, TASK-LIST.md — find every section header containing a count claim; verify against body. Document outcomes. (b) Fix any drift found (F-PASS18-C1 is the known instance). (c) Sub-dispatch architect to update ARCH-INDEX discipline #23 Canonical-baseline scope text to include full operational state doc sweep results. ARCH-INDEX bump (v0.1.19 → v0.1.20 alongside F-PASS18-I1).

**Confidence:** HIGH.

## Suggestions

### F-PASS18-S1 SUGGESTION — Pass 17 adversary's F-PASS17-S1 evidence section asserted "VP-014 has v1.3" which is factually wrong; VP-014 is at v1.2 (verified via frontmatter grep); this was the adversary fabricating evidence about a verifiable fact, falling under F-PASS11-O1 adversary pre-flight verification discipline by analogy

**Files:** `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-17.md` F-PASS17-S1 Evidence section; `.factory/specs/architecture/verification-properties/VP-014-brain-init-scaffold.md` frontmatter.

**Evidence:**

Pass 17 report at F-PASS17-S1 Evidence (grep-anchored on "VP-014-brain-init-scaffold.md: v1.3"): "`VP-014-brain-init-scaffold.md`: v1.3, v1.2, v1.1."

VP-014 frontmatter: `version: "1.2"`. VP-014 Changelog: only two entries (v1.2 and v1.1). No v1.3 entry.

Pass 17 architect noticed this in their dispatch reply and corrected the discipline #22 rationale to reference VP-012 (not VP-014) as the v1.3 outlier. Architect fix is factually correct; adversary's Pass 17 Evidence section was the fabrication.

**Defect class:** Adversary evidence fabrication. F-PASS11-O1 (adversary pre-flight grep verification) is the codified analog — currently narrowly bound to "writing-tech recursion findings"; this incident suggests extending scope to "any factual evidence cite."

**Routing:** vsdd-factory:architect. Add a sentence to the F-PASS11-O1 sub-rule: "By extension: before citing factual evidence about file content (versions, frontmatter, Changelog entries, etc.) in any finding's Evidence section, the adversary MUST grep-verify the cited fact against the file. Citing an unverified fact as evidence is a fabrication-class defect even if the finding's conclusion is correct."

**Confidence:** HIGH.

## Observations

### F-PASS18-O1 [process-gap] — discipline #23 example text in ARCH-INDEX names "(M confirmed disciplines)" and "N fix-bursts complete" as count-claim header EXAMPLES — both of which describe headers in operational state docs (STATE.md / SESSION-HANDOFF), not in spec corpus; this proves the discipline's authorial intent included operational state docs, yet the canonical-baseline sweep at codification time did not cover them; the example-list-vs-sweep-scope mismatch is a process-gap for codification self-audit

**Files:** `.factory/specs/architecture/ARCH-INDEX.md` discipline #23 example text.

**Evidence:** ARCH-INDEX: "For any section header that contains a count claim (e.g., '(N total items)', '(M confirmed disciplines)', 'N fix-bursts complete'), verify the count matches the visible body item / row / list-entry count."

The example "(M confirmed disciplines)" matches the STATE.md phrasing ("23 confirmed committed disciplines"). The example "N fix-bursts complete" matches the STATE.md / SESSION-HANDOFF phrasing ("40 fix-bursts complete"). Both are operational-state-doc patterns.

**Defect class:** Codification self-audit process-gap. When codifying a new discipline, architect should derive canonical-baseline scope FROM example list, not narrow to motivating findings.

**Routing:** Add a Self-Audit Checklist sub-item under discipline #10 (Dual-scope discipline): "Canonical-baseline scope sweep coverage: when codifying a new discipline, architect MUST enumerate (in Canonical-baseline scope clause) the full inventory swept at codification time, not just motivating findings. The example list in sub-rule body is authoritative for scope: if an example references a file class, that class is in scope."

**Severity:** Process-gap, not blocking.

### F-PASS18-O2 — CRITICAL plateau at 1 has now held for 5 consecutive passes (P14, P15, P16, P17, P18); meta-rule self-violation class at 8th recurrence; this triggers F-PASS12-O2 3rd STRONG-ESCALATE per dispatch escalation rule ("if CRITICAL plateau extends to 5+ passes OR meta-rule self-violation hits 8+ recurrences, recommend 3rd escalation to human")

**Evidence:**

CRITICAL trajectory: 7→4→2→3→2→2→2→1→1→2→2→2→2→1→1→1→1→**1** (Pass 18). Plateau extended from 4 to 5 passes.

Meta-rule self-violation class history (now 8 recurrences): see F-PASS18-C1 chain.

Both F-PASS12-O2 escalation triggers from dispatch now met:
- CRITICAL plateau at 5 passes (≥ 5). ✓
- Meta-rule self-violation at 8 recurrences (≥ 8). ✓

**3rd STRONG-ESCALATE recommended per F-PASS12-O2.**

**Severity:** OBSERVATION. Triggers human re-escalation per F-PASS12-O2.

## Recommended Sequential Closure for Pass 18

1. state-mgr persist Pass 18 (THIS file).
2. **PAUSE for human re-escalation per F-PASS12-O2 — orchestrator MUST surface 3-option re-decision (Option C continue, Option B carve-out, Option C-prime declare-converged-by-fiat) before dispatching fix-bursts.**
3. (If human confirms Option C continue) architect F-PASS18-I1 + F-PASS18-S1 + F-PASS18-O1 — ARCH-INDEX v0.1.19 → v0.1.20.
4. (If human confirms Option C continue) PO mirror F-PASS18-S1 + F-PASS18-O1 into PRD/BC-INDEX if needed.
5. (If human confirms Option C continue) state-mgr FINAL — F-PASS18-C1 + F-PASS18-I2 + 8 sub-checks + Pass 18 cascade row + F-PASS18-O2 escalation flag.

## F-PASS12-O2 Escalation Assessment

**RECOMMEND 3rd STRONG ESCALATION to human (F-PASS12-O2 thresholds tripped per dispatch arming).**

Both arming thresholds met:
- CRITICAL plateau ≥ 5 passes: ACHIEVED.
- Meta-rule self-violation recurrence ≥ 8: ACHIEVED.

Three options re-presented under 5th-pass evidence:
- **(a) Continue cascade per UD-002 Option C** — accept that each pass will produce 1 self-violation CRITICAL + ~2 IMPORTANT, indefinitely. Phase 1d ends at unknown future pass with no literal 3/3.
- **(b) Adversary-discipline boundary call (offered Pass 17, not selected)** — declare "discipline-codifying bursts are exempt from the dual-scope-on-the-discipline-itself check." Closes cascade in 1-2 passes; creates new exemption that future adversaries must respect.
- **(c) Hard-cap declaration** — declare Phase 1d converged-by-fiat at this pass (or after one more clean cycle that does not introduce new CRITICAL); move to Phase 2. The 23 disciplines codified plus 5+ passes of stable plateau is sufficient evidence of spec robustness even without literal 3/3.

Re-confirm Option C, or pivot to (b), or pivot to (c), or other adjudication?

## Streak: 0/3 (reset by F-PASS18-C1 CRITICAL — 8th recurrence meta-rule self-violation class; CRITICAL plateau at 5 consecutive passes; 3rd STRONG-ESCALATE recommended per F-PASS12-O2)
