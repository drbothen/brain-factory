---
artifact_type: adversary-pass-report
pass_number: 7
cascade: brain-factory-product-brief-v0.4.2-final
target_file: .factory/specs/product-brief.md
target_version: 0.4.2-final
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 2/3
streak_after: 0/3 (RESET — Pass 7 FAIL on convergence target)
created: 2026-05-15
author: vsdd-factory:adversary
inputs:
  - .factory/specs/product-brief.md (v0.4.2-final, 699 lines)
  - .factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1..6}.md
  - .factory/planning/stage-3-locks.md
  - .factory/planning/reference-repos.md
  - .factory/planning/elicitation-notes.md
  - docs/planning/llm-second-brain-plan.md (§§2.1, 3.3, 3.4)
  - docs/planning/llm-second-brain-phased-build-plan.md (§§5.11, 8.2.4, 8.3, 10.5, A.4)
  - CLAUDE.md
finding_count_critical: 0
finding_count_important: 1
finding_count_suggestion: 4
finding_count_observation: 1
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: false
pass_5_corroborations: 3
pass_6_corroborations: 1
pass_7_new_findings: 1
milestone: convergence-target-blocked-validates-3-clean-protocol
---

# Adversarial Review — Pass 7

## Verdict

**FAIL** — 1 IMPORTANT finding surfaces a structural internal contradiction in the v1.0 ship gate and adjacent prose. Pass 5 and Pass 6 both missed this. The brief commits to **13 hooks** for v0.x (explicit "12 → 13" adjustment in v0.1/v0.9 ship gates) but the v1.0 WASM-migration scope is stated as **12 hooks** in three independent callsites (L186, L311, L574). With L316 also committing to "bash hook scripts removed from tarball" at v1.0, the count contradiction is unresolvable in the spec as written — an implementer cannot tell whether `validate-publish-state.sh` is migrated to WASM, exempted, or whether the "12" is just a stale plan-quote awaiting sibling-sweep.

**Streak decision: RESET to 0/3.**

This is the exact same sibling-sweep failure pattern that the v0.4.2 fix-burst caught and resolved for the v0.1/v0.9 gate items (formerly Pass 4 F-NEW4-2 and F-NEW4-3). The fix-burst did NOT propagate the "12 → 13" adjustment to the v1.0 gate or to the Family Positioning / Future Infrastructure prose.

---

## Independent Findings (fresh-context scan, before reading Passes 5/6)

### Important Findings

#### F-PASS7-I1 [IMPORTANT] — v1.0 WASM-migration hook count is 12, but brief commits to 13 hooks; sibling-sweep gap from v0.4.2 fix-burst

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L186, L311, L574
- **Confidence:** HIGH
- **Severity:** IMPORTANT (P1)

**Evidence:**

The brief explicitly commits to 13 bash hooks for v0.x:
- L25 frontmatter: `hook_count_v0_x: 13`
- L246 (v0.1 ship gate): "All 13 hook scripts present... (Adjusted from `llm-second-brain-phased-build-plan.md` §5.11's 12 hooks: wclaude absorption adds `validate-publish-state.sh`; see §"13 bash hooks" for full list.)"
- L252 (v0.1 ship gate): "All 13 hooks fire on Write/Edit... (Adjusted from §5.11's 12 hooks...)"
- L278 (v0.9 quality bar): "All 13 hooks have bats coverage... (...the 13 covers the 12 from §A.4 plus `validate-publish-state.sh` from wclaude absorption)"
- L385–L402 (§Scope): "13 bash hooks: The 12 hooks from phased plan §A.4 [1–12] ... Plus 1 from wclaude absorption (bumps count 12 → 13): 13. `validate-publish-state.sh`"

But the v1.0 ship gate at L311 reads:
> "All **12** WASM hooks compile and pass parity test against bash equivalents (`diff_count = 0`). (`llm-second-brain-phased-build-plan.md` §8.3)"

And L186 (Family Positioning) reads:
> "The brain plugin's Phase 4 migration is a **12-hook** port — simpler than vsdd-factory's 52-hook migration."

And L574 (Future shared infrastructure) reads:
> "brain-factory's v1.0 migration is a **12-hook** WASM port — simpler than vsdd-factory's 52-hook migration..."

L316 commits to: "v1.0.0 tagged; CHANGELOG documents the bash-to-WASM migration; **bash hook scripts removed from tarball**." (Unqualified plural — implies ALL 13.)

**Contradiction:** If 13 bash hooks ship from v0.1 onward and all bash hook scripts are removed at v1.0, then there must be 13 WASM hooks, not 12. There is no statement that `validate-publish-state.sh` is exempted from WASM migration. The v1.0 gate item as written ("All 12 WASM hooks compile") is unachievable when 13 hooks exist and all must be migrated.

**Why this is IMPORTANT, not SUGGESTION:**

1. This is a **count contradiction** within commitment-grade prose, not a citation-form quibble. Counts are the brief's spine — the v0.4.2 self-audit checklist's L699 cross-checks all `locked_decisions` count fields against body, but the 13-vs-12 inconsistency for WASM migration was not flagged.
2. **3 callsites** (L186, L311, L574) consistently say "12" — this is not a one-off typo. It's a missed sibling-sweep when v0.4.2 propagated the "12 → 13" adjustment to v0.1 and v0.9 gates but stopped before v1.0.
3. **Same defect pattern Pass 4 caught and v0.4.2 fixed** for v0.1 ship gate (F-NEW4-2 wclaude gate contradiction; F-NEW4-3 validate-frontmatter-schema scope mismatch). Per the lessons codification axis ("Partial-Fix Regression Discipline"), the v0.4.2 fix-burst should have sibling-swept ALL callsites of the "12 hooks" plan-quote, including the v1.0 gate.
4. **Forward-impact:** An implementer reading the brief in Phase 1c (architecture) or Phase 4 (WASM migration) hits unresolvable spec ambiguity. They must escalate to the human to learn whether the 13th hook gets migrated, stays bash, or whether the count is just stale.

**Why prior passes (5, 6) missed it:**

- Pass 5's spot-check sampled the 5 v0.4.2-edited citations and did not re-check the v1.0 gate.
- Pass 6's spot-check also sampled different citations; F-PASS6-S1 caught the §8.3 vs §10.5 literal but did NOT cross-reference the "12 hooks" count quoted in the same v1.0 gate against the brief's own 13-hook commitment.
- Both prior passes' count-reconciliation tables verified "13 hooks" at L388–L399 + L402 = 13, but neither table cross-checked the v1.0 ship gate hook count against the v0.x commitment.

**Fix options:**
1. Update L311 to: "All 13 WASM hooks compile and pass parity test against bash equivalents (`diff_count = 0`). (Adjusted from `llm-second-brain-phased-build-plan.md` §8.3's 12 hooks: wclaude absorption adds `validate-publish-state.sh` to the migration scope; see §"13 bash hooks".)"
2. Update L186 and L574 from "12-hook port" → "13-hook port".
3. OR explicitly state that `validate-publish-state.sh` is bash-only (not migrated to WASM) — but L316's "bash hook scripts removed from tarball" must then be qualified, AND `hooks.json.template` wiring at L313 must be specified for the mixed bash/WASM case.

Option 1 is most consistent with the v0.4.2 process discipline.

### Suggestions (Pass 5 / Pass 6 corroborations — still present in unchanged brief)

#### F-PASS7-S1 [SUGGESTION, corroborates F-PASS5-S1] — `.factory/planning/stage-3-locks.md` missing from frontmatter `source_documents` and Traceability section

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L11–L15 (frontmatter), L658–L674 (Traceability)
- **Confidence:** HIGH

Independently verified: frontmatter `source_documents` at L11–L15 lists only the four `docs/planning/*.md` files; Traceability §Source planning documents at L658–L663 has the same four-row table. stage-3-locks.md (cited at L292 with section anchors) is not in either discovery surface. Brief is unchanged since Pass 5.

#### F-PASS7-S2 [SUGGESTION, corroborates F-PASS5-S2] — Self-Audit Checklist L697 stale line-number annotations

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L697
- **Confidence:** HIGH

Independently Grep-verified:
- "publicly-documented implementations" appears at L156 and L527 (not L149 and L515 as L697 claims).
- `gh auth login` / authenticated-gh appears at L264, L588, L600 (not L256, L576, L588 as L697 claims).

Brief is unchanged since Pass 5.

#### F-PASS7-S3 [SUGGESTION, corroborates F-PASS5-S3] — Changelog entries out of chronological order

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L53 (v0.4.0), L62 (v0.4.2), L69 (v0.4.1)
- **Confidence:** HIGH

Order is v0.4.0 → v0.4.2 → v0.4.1. v0.4.2 should be either at top (reverse-chron) or after v0.4.1 (chronological). Brief is unchanged since Pass 5.

#### F-PASS7-S4 [SUGGESTION, corroborates F-PASS6-S1] — `§8.3 (where 'diff_count = 0' originates)` is technically incorrect — literal originates in §10.5

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L160
- **Confidence:** HIGH

Independently verified via Grep against `docs/planning/llm-second-brain-phased-build-plan.md`:
- `diff_count = 0` appears EXACTLY ONCE in the entire file, at L711.
- L711 is inside §10.5 ("Phase 4 final gate", L707).
- §8.3 (L636–L643) contains the parity-test gate item ("All 12 WASM hooks compile and pass parity test against bash equivalents") but does NOT contain the literal string `diff_count = 0`.

Brief L160's claim that `diff_count = 0` "originates" in §8.3 is wrong. The fix is to change "§8.3" to "§10.5" or to compound the citation. (See also F-PASS7-I1 — the surrounding §8.3 hook-count number is also stale, providing a second reason to re-touch L160's source citation.)

### Observations

#### F-PASS7-O1 [OBSERVATION] — Three converged adversarial passes (5, 6, 7) all failed to cross-check v1.0-gate hook count against v0.x-committed hook count until Pass 7

The 12-vs-13 hook count contradiction at L186/L311/L574 is structurally analogous to Pass-4 F-NEW4-2 (wclaude gate contradiction, a BLOCKER), F-NEW4-3 (validate-frontmatter-schema scope mismatch, a BLOCKER), and the pattern the v0.4.2 fix-burst was designed to systematically resolve via "sibling-sweep all callsites." Yet THREE adversary passes (5, 6, 7's pre-finding analysis) did not catch it because:

- Pass 5's count reconciliation table verified "13 hooks at L388-L399 + L402 = 13" — confirming the v0.x commitment but not cross-checking the v1.0 gate.
- Pass 6's count reconciliation duplicated Pass 5's table structure with the same scope.
- Pass 4's audit table marked the v1.0 gate citation "RESOLVED" without cross-checking the count inside the quoted plan-text against the brief's own adjusted count.

This is a methodological gap in the adversary's own count-cross-check axis, not a brief defect per se. The lesson for future adversary passes: when a count is explicitly "adjusted from plan-doc N to brief-doc M," ALL callsites that quote plan-doc N must be checked, including ship gates that may be paraphrasing the plan-quote. This is not flagged as `[process-gap]` because it's an adversary-prompt-level lesson, not a brain-factory-process lesson — but a future iteration of the adversary prompt could codify "count-adjustment audit axis: when a brief adjusts a plan count, sibling-sweep ALL callsites."

---

## Pass 5 + Pass 6 Cross-Reference

| Prior pass finding | Status in Pass 7 |
|---|---|
| F-PASS5-S1 (stage-3-locks.md frontmatter/traceability) | **CORROBORATED** (F-PASS7-S1) — still present |
| F-PASS5-S2 (stale self-audit line numbers) | **CORROBORATED** (F-PASS7-S2) — Grep-confirmed |
| F-PASS5-S3 (changelog order) | **CORROBORATED** (F-PASS7-S3) — unchanged |
| F-PASS6-S1 (§8.3 vs §10.5 diff_count origin) | **CORROBORATED** (F-PASS7-S4) — Grep-confirmed |
| F-PASS5-O1, O2, O3 (process-gap, multi-version audit log, convergence assessment) | CORROBORATED — observation-grade, non-blocking |
| F-PASS6-O1 (stage-3-locks.md frontmatter `total_locks: 10` vs 11 SLs) | OUT-OF-PERIMETER (sibling artifact) — not re-checked here |
| F-PASS6-O2 (Pass 4 closed F-NEW-2 incorrectly) | CORROBORATED — observation about prior-pass auditing |

**No prior-pass finding contradicted.** No prior-pass finding falsely retracted.

**New in Pass 7 (not in any prior pass):** F-PASS7-I1 — the 12-vs-13 WASM hook count contradiction at L186/L311/L574. This is a STRUCTURAL contradiction one severity tier above the citation-literal class of F-PASS6-S1.

---

## Citation Spot-Check (7 sampled, including diff_count verification)

| # | Citation | Source verified | Verdict |
|---|---|---|---|
| 1 | L160 → phased-plan §8.3 ("where `diff_count = 0` originates") | §8.3 (L636–L643) does NOT contain literal `diff_count = 0`; only §10.5 L711 contains it | **FAILED** (F-PASS7-S4) |
| 2 | L160 → phased-plan §8.2.4 ("verdicts must match") | §8.2.4 (L621): "verdicts must match" — verbatim | VERIFIED |
| 3 | L210 → plan §3.4 (6 wiki types: concepts/people/frameworks/syntheses/observations/questions) | plan.md §3.4 (L201–L208): exact 6 enumerated | VERIFIED |
| 4 | L292 → stage-3-locks.md §132 (SL-9), §144 (SL-10) | stage-3-locks.md L132 SL-9 verbatim; L144 SL-10 verbatim | VERIFIED |
| 5 | L264 → reference-repos.md §7.1 (prism direct-clone decision) | §7.1 at L315: "Submodule vs direct-clone decision" — exists | VERIFIED |
| 6 | L161 → plan.md §2.1 (Karpathy scale ~100/~400K/~hundreds) | plan.md L73: "~100 sources, ~400K words, ~hundreds of pages" verbatim | VERIFIED |
| 7 | L246, L252, L278 → phased-plan §5.11/§A.4 ("12 hooks" original) | phased-plan §A.4 enumerates 12 hooks (L917–L1110); §5.11 L386–L390 | VERIFIED |

**6 of 7 verified. 1 of 7 failed (F-PASS7-S4 same as F-PASS6-S1).**

---

## Multi-Instance Identifier Consistency Check

| Identifier | Callsites | Verdict |
|---|---|---|
| `Node 20+` | L25, L135, L147, L449, L450, L477, L694 | CONSISTENT — all reference Node 20+ as toolchain prerequisite |
| `validate-frontmatter-schema.sh` | L65, L74, L228, L259, L395, L690 | CONSISTENT — scope `wiki/*` and `sources/*` per plan §A.4; `embedding_status` applies to `wiki/*` only |
| `gh auth login` / authenticated-gh | L264, L588, L600, L697 | CONSISTENT (callsite text) — all coherent on pre-transition vs post-transition state; **but L697 audit-trail line numbers are stale** (F-PASS7-S2) |

No identifier drift on substance. One audit-trail-staleness on L697 (corroborated suggestion).

---

## Mandatory ↔ Gate Validation Pairing Check

| Mandatory commitment | Gate-validation pairing | Verdict |
|---|---|---|
| `embedding_status` mandatory in v0.1 (L228) | Bats positive + negative test at L259 (within `hooks.bats`, count unchanged at 9) | PAIRED CORRECTLY |
| 5-minute init SLA (L83 Vision; L250 v0.1 ship gate) | `assert_under_5_minutes` in `plugins/brain-factory/tests/local-dev-test.sh` (L250) | PAIRED CORRECTLY |

No new mandatory-vs-gate pairing gaps. Both Pass 5 and Pass 6 verified this; Pass 7 corroborates.

---

## Convergence Assessment

**The brief has NOT converged at v0.4.2-final.**

A genuine structural defect (F-PASS7-I1) was undetected for 6 prior adversarial passes because the count-reconciliation methodology used by Passes 4–6 verified the v0.x hook count in isolation, without cross-checking the v1.0 ship gate's quoted hook count against the brief's own adjustment. The defect is exactly the class the v0.4.2 fix-burst process discipline was designed to prevent (sibling-sweep miss when a count is adjusted from plan to brief).

**The fresh-context adversarial review pattern is working as designed:** even with two consecutive clean passes producing convergent-leaning narratives, a third independent pass found a structurally meaningful issue. This validates the BC-5.39.001 3-CLEAN protocol — the protocol exists specifically to catch defects that two passes might miss in correlation.

**Process-level concerns:** The brief is structurally near-converged on every other axis. The remaining defects are:
- 1 IMPORTANT structural contradiction (F-PASS7-I1) — fixable in a single fix-burst
- 4 SUGGESTION-grade defects (3 from Pass 5, 1 from Pass 6) — non-blocking propagation-gap cleanup

A v0.4.3 fix-burst that addresses F-PASS7-I1 (sibling-sweep L186/L311/L574 to "13") and the 4 corroborated suggestions (stage-3-locks.md frontmatter + traceability, stale line numbers in self-audit, changelog order, §8.3 → §10.5 citation) should converge in a single pass.

**Are locked commitments structurally implementable as written?** No — the v1.0 ship gate as written is unimplementable because "All 12 WASM hooks compile" cannot be satisfied when 13 hooks exist and all bash hook scripts are removed from the v1.0 tarball.

**Are there latent issues that surface in PRD/architecture?** Yes — F-PASS7-I1 surfaces in Phase 1c (architecture) when the WASM migration scope is enumerated. Without fix, the architecture phase inherits the ambiguity.

---

## Streak Decision

**Streak resets to 0/3.** A new 3-CLEAN cascade must begin after the v0.4.3 fix-burst lands.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 1 | FAIL (15) | 0/3 |
| Pass 2 | FAIL (4) | 0/3 |
| Pass 3 | FAIL (6) | 0/3 |
| Pass 4 | FAIL (4) | 0/3 |
| Pass 5 | PASS (0 blockers) | 1/3 |
| Pass 6 | PASS (0 blockers) | 2/3 |
| **Pass 7** | **FAIL (1 IMPORTANT)** | **0/3** |

---

## Top 3 Findings

1. **F-PASS7-I1 [IMPORTANT]** — Hook count `12` in v1.0 ship gate (L311), Family Positioning (L186), and Future shared infrastructure (L574) contradicts the brief's own v0.x commitment of `13` hooks. Sibling-sweep miss from the v0.4.2 fix-burst. Fix: change "12" → "13" at all three callsites (plus the implicit count in L311's WASM-migration parity test), with the same parenthetical adjustment-note structure used at L246/L252/L278.

2. **F-PASS7-S4 [SUGGESTION, corroborates F-PASS6-S1]** — L160 cites `§8.3 (where 'diff_count = 0' originates)` but the literal `diff_count = 0` originates in §10.5 of the phased build plan. Fix: change "§8.3" → "§10.5" or compound to "§8.3 (parity-test exit gate) and §10.5 (literal pass-criterion `diff_count = 0`)".

3. **F-PASS7-S1 [SUGGESTION, corroborates F-PASS5-S1]** — `.factory/planning/stage-3-locks.md` (created during v0.4.2 fix-burst, cited at L292 with section anchors) is not in frontmatter `source_documents` (L11–L15) or Traceability §Source planning documents table (L658–L663). Discovery-surface gap. Fix: add a `stage_3_locks: .factory/planning/stage-3-locks.md` frontmatter field (or expand `source_documents`) AND add a row to the Traceability table.

---

## Summary

Pass 7 finds **1 IMPORTANT + 4 SUGGESTIONS (3 Pass-5-corroborated + 1 Pass-6-corroborated) + 1 OBSERVATION**.

The 1 IMPORTANT finding (F-PASS7-I1) is a genuine NEW structural defect that survived 6 prior adversarial passes. It is a sibling-sweep miss from the v0.4.2 fix-burst: the "12 hooks → 13 hooks" adjustment was propagated to v0.1 and v0.9 ship gate items but not to the v1.0 ship gate (L311), Family Positioning prose (L186), or Future shared infrastructure prose (L574). With L316 committing to "bash hook scripts removed from tarball" at v1.0, the count contradiction is unresolvable in the spec as written.

The fresh-context different-model adversarial review pattern functioned as designed: Pass 7's independent assessment caught a structural issue that two consecutive clean passes (5, 6) missed via correlated sampling strategy.

**Recommended next action:**

1. Dispatch `product-owner` for a v0.4.3 fix-burst addressing:
   - **F-PASS7-I1 (BLOCKER)**: sibling-sweep "12 hooks" → "13 hooks" at L186, L311, L574 with explicit adjustment parenthetical matching L246/L252/L278 style; verify L316 is consistent ("bash hook scripts removed from tarball" should remain).
   - **F-PASS7-S1**: add stage-3-locks.md to frontmatter and Traceability.
   - **F-PASS7-S2**: update L697 line-number annotations to current positions (L156/L527 for "publicly-documented"; L264/L588/L600 for `gh auth login`).
   - **F-PASS7-S3**: reorder changelog entries chronologically (v0.4.0 → v0.4.1 → v0.4.2) or reverse-chron.
   - **F-PASS7-S4**: change L160 citation from "§8.3" → "§10.5" (or compound).
2. After fix-burst lands as v0.4.3, dispatch Pass 8 with fresh context to begin a new 3-CLEAN cascade from streak 0/3.

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.2-final
pass_number: 7
finding_counts:
  critical: 0
  important: 1
  suggestion: 4
  observation: 1
  process_gap: 0
  total_blocking: 1
verdict: FAIL
streak_before: 2/3
streak_after: 0/3
recommended_next_action: dispatch product-owner v0.4.3 fix-burst; sibling-sweep "12 hooks" → "13 hooks" at L186/L311/L574 with adjustment parenthetical; apply 4 corroborated suggestions; then dispatch Pass 8 to begin a new 3-CLEAN cascade
critical_finding_ids: []
important_finding_ids: [F-PASS7-I1]
suggestion_finding_ids: [F-PASS7-S1, F-PASS7-S2, F-PASS7-S3, F-PASS7-S4]
observation_finding_ids: [F-PASS7-O1]
process_gap_finding_ids: []
paper_fix_pattern_observed: false
pass_5_corroborations: 3
pass_6_corroborations: 1
pass_7_new_findings: 1
cascade_convergence_assessment: structurally-near-convergent-with-one-newly-surfaced-sibling-sweep-gap; v0.4.3 fix-burst should converge in single pass
new_findings_classification: structural-sibling-sweep-miss (count adjustment 12 → 13 not propagated to v1.0 gate / family positioning / future infrastructure prose)
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/reference-repos.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-5.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-6.md
```
