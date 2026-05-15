---
artifact_type: adversary-pass-report
pass_number: 13
cascade: brain-factory-product-brief-v0.4.7
target_file: .factory/specs/product-brief.md
target_version: 0.4.7
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 1/3
streak_after: 0/3 (RESET — Pass 13 FAIL after Pass 12 PASS)
created: 2026-05-15
author: vsdd-factory:adversary
finding_count_critical: 0
finding_count_important: 2
finding_count_suggestion: 0
finding_count_observation: 2
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: false
structural_fix_cascade_holds: true (all 3 grep tests clean)
new_findings_classification:
  - F-PASS13-I1: timeline-scope-count-drift (12-vs-13 polish skills)
  - F-PASS13-I2: gate-task-artifact-mismatch (.reference/README.md required at v0.1 gate but no task creates it)
---

# Adversarial Review — Pass 13

**Target file:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.7, 745 lines)
**Cascade:** BC-5.39.001 3-CLEAN convergence; brain-factory product brief
**Streak before:** 1/3
**Streak after:** **0/3 (RESET)**
**Verdict:** **FAIL** — 2 IMPORTANT findings (advance blocked; cascade resets)

---

## Critical Findings

(none)

---

## Important Findings

### F-PASS13-I1 [IMPORTANT] — Phase 3 timeline at line 538 says "13 polish skills + /brain:research" but Phase 2–3 polish skills are 12, not 13 — internal count contradiction

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** 538 (Timeline), conflicting with 379 (Scope header), 393-394 (Scope enumeration)
- **Confidence:** HIGH

**Evidence:**

Line 538 (Timeline, §Constraints): "Phase 3 (Author dogfood + pilot users, **13 polish skills + /brain:research** + perf integration): 8–12 weeks"

Line 379 (Scope): "Phase 2–3 polish skills (**12** — ship by v0.9; skills #18 `/brain:monthly-perf` and #22 `/brain:publish-content` ship early at v0.5 milestone per §Success Criteria v0.5 milestone):"

Line 393 (Scope): "Phase 2–3 new skill (**1** — ships by v0.9):"

Line 315 (v0.9 ship gate): "All 26 skills functionally complete... `llm-second-brain-phased-build-plan.md` §7.5; **skill count 25 + /brain:research = 26**"

Direct enumeration: skills 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 = 12 polish skills. Skill 26 = /brain:research. Phase 2-3 total ships = 12 + 1 = 13 skills.

The Timeline phrasing "**13 polish skills + /brain:research**" naturally sums to 14 skills (13 + 1), contradicting:
- The 12 polish skills count at line 379
- The 12 + 1 = 13 Phase 2-3 ship-count implicit at line 315
- The total 26 = 13 primitives + 12 polish + 1 new = 26

**Why IMPORTANT (not SUGGESTION):**

This is a numeric drift between two committed callsites within the same document. The Phase 3 phrasing "13 polish + /brain:research" cannot both be a strict count and consistent with §Scope's 12-polish lock. A reader implementing against §Timeline (line 538) would expect 13 polish skills, not 12. The drift is exactly the same defect class as Pass 7's F-PASS7-I1 (12→13 hooks sibling-sweep) but applied to skill counts — and the fix-burst that aligned hook counts did not sibling-sweep the parallel timeline phrasing for skill counts.

**Why this is fresh-context-novel:**

Pass 12's count table (line 186-196 of its report) verified `26 skills = 13 + 12 + 1 = 26` consistent against the Scope section but did NOT cross-check this against the Timeline phrasing at line 538. Pass 12 enumerated callsites for hook counts (line 188 of Pass 12 report includes line 538-adjacent callsites for hooks but not skills) but the Timeline's "13 polish skills" phrasing escaped both the structural-fix audits and the count-verification table.

**Fix options:**

1. Change line 538 to "Phase 3 (Author dogfood + pilot users, **12 polish skills + /brain:research** + perf integration)" — aligns to §Scope.
2. OR change to "**13 Phase 2-3 skills (12 polish + /brain:research)**" — preserves the 13 figure but qualifies it.
3. OR drop the redundant phrasing: "**Phase 3 (Author dogfood + pilot users, 13 polish/research skills + perf integration)**".

---

### F-PASS13-I2 [IMPORTANT] — v0.1 ship gate requires `.reference/README.md` (line 300) but bootstrap task (line 638) only creates `.reference/MANIFEST.md` — unsatisfiable gate item

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** 300 (v0.1 ship gate), 638 (Reference Repositories bootstrap task)
- **Confidence:** HIGH

**Evidence:**

Line 300 (v0.1 ship gate): "**`.reference/` directory bootstrapped** with 7 reference repos cloned ... **README at `.reference/README.md` documents what each is and how brain-factory ingests from it.** After the owner pre-v0.1 task below, all 7 clones use unauthenticated `gh`. `MANIFEST.md` at `.reference/MANIFEST.md` documents URL, license, cloned commit hash, and clone date for each repo."

Line 638 (Reference Repositories §devops-engineer bootstrap task): "**devops-engineer bootstrap task (Phase 1):** Clone the 7 repos into `.reference/`. Add `.reference/` to `.gitignore`. **Create `.reference/MANIFEST.md`** with one row per repo: Path | URL | License | Cloned commit (SHA) | Cloned date | Purpose."

The v0.1 ship gate at line 300 requires TWO artifacts:
- `.reference/README.md` (documents what each repo is and how brain-factory ingests from it)
- `.reference/MANIFEST.md` (URL, license, cloned commit, clone date)

The bootstrap task at line 638 commits to producing ONLY `.reference/MANIFEST.md`. No task creates `.reference/README.md`. Cross-reference against `.factory/planning/reference-repos.md` §7.2 (lines 327-356) — only MANIFEST.md schema is specified; no README.md mentioned.

This is an **unsatisfiable v0.1 ship gate item**: the gate requires an artifact that no committed task produces. Either:
- The gate item is overcommitting (drop the README.md requirement)
- The bootstrap task is undercommitting (add README.md creation to devops-engineer's bootstrap task)

**Why IMPORTANT (not SUGGESTION):**

This is a content gap with implementation impact. v0.1 release gating depends on `.reference/README.md` existing per line 300, but the implementation plan does not create it. At v0.1.0 release time, the gate fails — or the operator has to scramble to write a README that was never planned. The CLAUDE.md "Canonical Principle Self-Audit Checklist" item "Did I find a bug or gap in another AI's output and surface it as a question/advisory instead of fixing it in scope?" was checked No in the Self-Audit — but this gap was missed at the time of the v0.4.0 fix-burst (which added both the gate and the bootstrap task) and across all 12 subsequent passes.

**Why this is fresh-context-novel:**

No prior pass surfaced this gap. Pass 12 verified citation accuracy and count consistency but did not cross-check artifact deliverables between gate items and bootstrap tasks. Fresh-context perimeter sweep across §Success Criteria + §Reference Repositories surfaced the mismatch. This is exactly the kind of "sibling-sweep blast-radius" gap the Pass 7 sibling-sweep lesson warns about: the artifact list in one section did not propagate to the task list in another.

**Fix options:**

1. Update line 638 bootstrap task to include `Create .reference/README.md documenting per-repo purpose and brain-factory ingest usage` alongside MANIFEST.md creation.
2. OR drop the README.md requirement from line 300 gate, retaining only the MANIFEST.md requirement.
3. OR consolidate: keep README.md only, expand its schema to include the MANIFEST.md fields (URL, license, etc.).

---

## Suggestions

(none)

---

## Observations

### F-PASS13-O1 [OBSERVATION] — Citation Conventions block uses undeclared short-forms in body (confirmed Pass 12 F-PASS12-O1)

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** convention at 696; body callsites at 286, 294, 295, 300, 342, 402, 424, 475, 488
- **Confidence:** HIGH

Confirmed by independent re-derivation. Citation Conventions at line 696 declares "plan.md", "phased-build-plan.md", "plugin-plan.md" but body uses unhyphenated "phased plan §X" and "plugin plan §X" at 9 callsites. Intent recoverable; not a blocker.

### F-PASS13-O2 [OBSERVATION] — "§Changelog at top of brief" trailer references pseudo-section (confirmed Pass 12 F-PASS12-O2)

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** 736, 739, 743, 745
- **Confidence:** HIGH

Confirmed by independent re-derivation. Grep `^## ` returns 13 H2 sections; no `## Changelog`. The changelog appears as bold paragraph headers between frontmatter and Vision (lines 55-114). `§` notation is technically inaccurate but reader navigation cost is trivial.

---

## Structural Fix Verification (Pass 12 fixes still hold)

| Structural fix | Grep test | Result |
|---|---|---|
| v0.4.5: L-numbers → grep-anchors | `\bL[0-9]+\b` | 0 matches **PASS** |
| v0.4.6: line-counts → creation-date anchors | `\b[0-9]{3}-line\b` | 0 matches **PASS** |
| v0.4.7: per-version annotations → "see Changelog" | `v0\.[34]\.\d+:` in Self-Audit | 0 matches **PASS** |

All three structural fixes durable. No regression of structural-fix discipline.

---

## Count Verification (all 11 enumerated counts)

| Count | Frontmatter | Body | Verdict |
|---|---|---|---|
| 26 skills | line 27 (skill_count_v0_9) | Scope enumeration 13+12+1 = 26 | CONSISTENT (but see F-PASS13-I1 for Timeline drift) |
| 14 agents | line 28 | Scope enumeration 10+4 = 14 | CONSISTENT |
| 13 hooks | line 29 | Scope enumeration 12+1 = 13 | CONSISTENT across v0.1/v0.5/v0.9/v1.0 gates |
| 19 GH Actions | line 30 | 15+4 = 19 (lines 446-468) | CONSISTENT |
| 15 author-committed | line 31 | 6+9 = 15 (lines 446-462) | CONSISTENT |
| 4 community-optional | line 32 | 4 (lines 465-468) | CONSISTENT |
| 9 bats suites | (not frontmatter) | 8 functional + meta-lint = 9 (line 480) | CONSISTENT |
| 8 wclaude absorptions | wclaude_absorption keyword | 1 group + 7 individual = 8 (line 209, 600, 626, 711) | CONSISTENT |
| 7 reference repos | line 48 | 7 enumerated (line 622, 624-636) | CONSISTENT |
| 10 baseline policies | (not numeric) | line 144 + line 477 | CONSISTENT |
| 6 wiki types | (plan §3.4 cite) | concepts/people/frameworks/syntheses/observations/questions verified against plan.md L201-208 | CONSISTENT |

---

## Citation Verification (7 samples)

| # | Citation | Verified | Notes |
|---|---|---|---|
| 1 | phased-build-plan §10.5 `diff_count = 0` (line 196) | L711 contains literal `diff_count = 0` | ACCURATE |
| 2 | phased-build-plan §8.2.4 "verdicts must match" | L621 = "verdicts must match" | ACCURATE |
| 3 | phased-build-plan §8.3 12-hook baseline | L638 = "All 12 WASM hooks compile and pass parity test" | ACCURATE |
| 4 | brief-research.md §6.1 Medium API deprecated | L268-278 = §6.1 Medium API current state | ACCURATE |
| 5 | reference-repos.md §7.1 prism direct-clone | L315-325 = §7.1 confirms prism direct-clone pattern | ACCURATE |
| 6 | stage-3-locks.md SL-9 (§132), SL-10 (§144) | L132 = `## SL-9`; L144 = `## SL-10` | ACCURATE (§ notation for line/heading-number is a semantic stretch; recoverable) |
| 7 | plan.md §3.4 wiki types canonical | L201-208 = 6 wiki types matching brief | ACCURATE |

7/7 citations verified. No citation precision defects.

---

## Pass 7 Sibling-Sweep Lesson Verification (13 hooks)

| Gate | Callsite | Says "13"? |
|---|---|---|
| v0.1 ship gate | line 282 ("All 13 hook scripts present") | YES |
| v0.1 ship gate | line 288 ("All 13 hooks fire") | YES |
| v0.1 ship gate | line 294 ("13-hook set processes its sample payload") | YES |
| v0.5 milestone | (no hook count mention — not applicable) | N/A |
| v0.9 ship gate | line 314 ("All 13 hooks have bats coverage") | YES |
| v1.0 ship gate | line 348 ("All **13** WASM hooks compile") | YES |

13-hook sibling-sweep complete across v0.1, v0.9, v1.0 gates. No regression.

---

## Pass 8 Skill-Timing Lesson Verification (/brain:research v0.9)

| Callsite | Confirms v0.9? |
|---|---|
| line 289 (v0.1 gate) | YES — directory scaffolding only at v0.1; skill ships v0.9 |
| line 316 (v0.9 gate) | YES — runtime-dispatch validation at v0.9 |
| line 394 (Scope skill #26) | YES — "Phase 2–3 new skill (1 — ships by v0.9)" |
| line 529 (Constraints) | YES — "skill #26, ships v0.9" |

All `/brain:research` callsites consistent at v0.9.

---

## Pass 10 False-Attestation Lesson (changelog accuracy sample)

| Claim | Verification |
|---|---|
| v0.4.7: collapsed Self-Audit annotations (v0.3.0 through v0.4.6) | Grep `v0\.[34]\.\d+:` in Self-Audit returns 0 — ACCURATE |
| v0.4.6: disambiguated "plan §A.2" → "phased-build-plan §A.2" at 5 callsites | Grep `phased-build-plan §A\.2` body = lines 215, 289, 394, 476, 682 = 5 callsites — ACCURATE |
| v0.4.4 Traceability line-count update: brief-research 378→495 | brief-research.md L495 confirmed as last line — ACCURATE |

3/3 changelog claims verified accurate.

---

## Novelty Assessment

**Novelty: MODERATE.** Two genuinely new IMPORTANT findings via fresh-context independent re-derivation:

- **F-PASS13-I1** (Timeline-vs-Scope count drift): The 12-vs-13 polish skills inconsistency is the same defect class as Pass 7's 12-vs-13 hooks drift (F-PASS7-I1), but applied to a different count. The v0.4.3 fix-burst that resolved the hook drift did not sibling-sweep the parallel skill-count drift in §Timeline. This is exactly the Pass 7 sibling-sweep lesson resurfacing in an adjacent dimension that 12 passes missed.
- **F-PASS13-I2** (Unsatisfiable .reference/README.md gate): Gate-vs-task artifact mismatch that no prior pass surfaced. The defect was introduced in v0.4.0 (when both line 300 and line 638 were authored) and survived 13 passes because no review axis cross-checked "every required artifact in a gate item is covered by a task in an implementation section."

Both findings demonstrate the **Fresh-Context Compounding Value** lesson: pass 13's value increases because fresh context lets me see patterns that Pass 12 — anchored to its own assumptions about which sections to cross-reference — could not.

**Two OBSERVATIONs (F-PASS13-O1, F-PASS13-O2) duplicate Pass 12 findings.** They are not novel but confirmed by independent derivation.

---

## Streak Decision

**Streak: RESETS from 1/3 to 0/3.** 2 IMPORTANT findings exceed the "0 CRITICAL + 0 IMPORTANT → advance" gate.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 11 | FAIL (1 IMPORTANT) | 0/3 |
| Pass 12 | PASS (0 blockers) | 1/3 |
| **Pass 13** | **FAIL (2 IMPORTANT)** | **0/3 (RESET)** |

---

## Recommended Next Action

**Dispatch fix-burst for v0.4.8.** Two IMPORTANT findings require structural reconciliation:

1. **F-PASS13-I1 fix:** Reconcile Timeline (line 538) with Scope (line 379). Either change "13 polish skills + /brain:research" → "12 polish skills + /brain:research", or change to "13 Phase 2-3 skills (12 polish + /brain:research)".
2. **F-PASS13-I2 fix:** Reconcile v0.1 ship gate (line 300) with bootstrap task (line 638). Either add README.md to bootstrap task, or drop README.md from gate.

**Bundle the two OBSERVATIONS** (F-PASS13-O1 citation-shorthand drift, F-PASS13-O2 §Changelog pseudo-section) with the v0.4.8 fix-burst since the structural fixes anyway require touching the brief. These are not blocking but they are zero-cost to fix alongside.

After v0.4.8, dispatch Pass 14 with fresh context. Streak resumes from 0/3.

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.7
pass_number: 13
adversary_protocol: BC-5.39.001 3-CLEAN
finding_counts:
  critical: 0
  important: 2
  suggestion: 0
  observation: 2
  process_gap: 0
  total_blocking: 2
verdict: FAIL
streak_before: 1/3
streak_after: 0/3 (RESET)
critical_finding_ids: []
important_finding_ids: [F-PASS13-I1, F-PASS13-I2]
suggestion_finding_ids: []
observation_finding_ids: [F-PASS13-O1, F-PASS13-O2]  # both duplicate Pass 12
process_gap_finding_ids: []
paper_fix_pattern_observed: false
structural_fixes_still_holding: 3  # v0.4.5/v0.4.6/v0.4.7 all verified durable
prior_pass_fixes_still_holding: 13  # All Pass 5-11 fixes preserved
new_findings_classification:
  - F-PASS13-I1: timeline-scope-count-drift (12-vs-13 polish skills sibling-sweep gap; same defect class as F-PASS7-I1 hook count but applied to skills)
  - F-PASS13-I2: gate-task-artifact-mismatch (v0.1 gate requires .reference/README.md but bootstrap task only creates .reference/MANIFEST.md; unsatisfiable gate item)
  - F-PASS13-O1: citation-shorthand-coherence-gap (duplicate of F-PASS12-O1)
  - F-PASS13-O2: pseudo-section-reference (duplicate of F-PASS12-O2)
fresh_context_value_demonstrated: TRUE — two novel IMPORTANT findings surfaced via independent re-derivation that Pass 12 did not catch
recommended_next_action: dispatch fix-burst for v0.4.8 (fix F-PASS13-I1 + F-PASS13-I2; optionally bundle F-PASS13-O1 + F-PASS13-O2); then dispatch Pass 14 with fresh context
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/elicitation-notes.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/brief-research.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/reference-repos.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/CLAUDE.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-12.md
```
