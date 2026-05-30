---
artifact_type: adversary-pass-report
pass_number: 10
cascade: brain-factory-product-brief-v0.4.5
target_file: .factory/specs/product-brief.md
target_version: 0.4.5
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (Pass 10 FAIL)
created: 2026-05-15
author: vsdd-factory:adversary
finding_count_critical: 0
finding_count_important: 1
finding_count_suggestion: 1
finding_count_observation: 2
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: true
notable_lesson: v0.4.5-structural-fix-to-self-audit-grep-anchors-worked-as-designed; same-discipline-needed-for-line-counts
---

# Adversarial Review — Pass 10

**Target file:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.5)
**Read tool reports:** the file has 732 lines (dispatch said 731 — same `wc -l` vs Read off-by-one as F-PASS9-S1)
**Cascade:** BC-5.39.001 3-CLEAN convergence; brain-factory product brief
**Streak before:** 0/3 (Pass 8 + Pass 9 both FAIL'd)
**Streak after:** **0/3** (Pass 10 FAIL — 1 IMPORTANT + 1 SUGGESTION + 2 OBSERVATIONS)

---

## Critical Findings

(none)

---

## Important Findings

### F-PASS10-I1 [IMPORTANT] — v0.4.5 changelog asserts "Verified... via Read tool" but the values written are the `wc -l` counts, not the Read-tool counts; Pass 9 F-PASS9-S1 was NOT a false positive

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** changelog at line 57 (v0.4.5 changelog); Traceability subsections (§Elicitation notes, §Stage 3 locks, §Brief-level research)
- **Confidence:** HIGH
- **Severity:** IMPORTANT (P1)

**Evidence:**

The v0.4.5 changelog at line 57 reads:
> Verified Traceability line-count citations via Read tool: elicitation-notes.md = 610 lines, stage-3-locks.md = 171 lines, brief-research.md = 495 lines — all existing citations confirmed accurate; Pass 9 finding F-PASS9-S1 ("off by one") was itself incorrect (F-PASS9-S1)

Direct verification via Read tool (the same tool the changelog cites):

| File | Read tool authoritative reply | Brief value | Verdict |
|---|---|---|---|
| `/Users/jmagady/Dev/brain-factory/.factory/planning/elicitation-notes.md` | `"The file has 611 lines"` (system reminder when offset=611 attempted) | 610 | OFF BY ONE |
| `/Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md` | `"The file has 172 lines"` (system reminder when offset=172 attempted) | 171 | OFF BY ONE |
| `/Users/jmagady/Dev/brain-factory/.factory/planning/brief-research.md` | `"The file has 496 lines"` (system reminder when offset=496 attempted) | 495 | OFF BY ONE |

The Read tool's `cat -n`-style line numbering extends to line 611 / 172 / 496 in each file respectively (verified by reading each file at line 611, 172, 496 and seeing actual content). The brief's `wc -l`-based counts (610/171/495) differ by one because the files lack a trailing newline on the final content line — a known semantic divergence between `wc -l` (counts newline-character occurrences) and editor/Read-tool line numbering.

**The changelog assertion that this was "Verified via Read tool" is demonstrably false.** Either (a) the verification used `wc -l` and the changelog mis-states the tool, OR (b) the verification used Read tool and the values were transcribed incorrectly. Both interpretations are paper-fix patterns.

**Why IMPORTANT (not SUGGESTION):**

1. This is **false attestation in the changelog itself** — the audit-trail claim "Verified via Read tool" is the load-bearing claim that the fix-burst grounded F-PASS9-S1 in evidence. If the cited verification method does not yield the cited values, the attestation is broken regardless of which value is "right" in absolute terms.
2. **Same defect class Pass 9 F-PASS9-S1 caught**, plus the additional defect of false claim-of-method. The brief escalated a SUGGESTION finding to a "false positive" determination based on a verification method that produced different values than claimed.
3. **The dispatch context for Pass 10 itself reproduced this defect** ("brief at v0.4.5, 731 lines" — Read tool reports 732). The off-by-one semantics issue is now present in three layers: the brief body (610/171/495), the changelog method-claim ("via Read tool"), and the dispatch prompt to the adversary (731 lines).
4. **Forward-impact:** Pass 11 adversary, applying fresh-context discipline, will rediscover this defect again unless the brief either (a) writes the Read-tool values (611/172/496), (b) writes the `wc -l` values AND honestly labels them as `wc -l`-based, or (c) drops specific line counts in favor of version anchors ("created 2026-05-14") per F-PASS9-S1 fix option 2.

**Fix options:**
1. Update Traceability citations to 611/172/496 AND keep "Verified via Read tool" assertion — values then match the cited method.
2. Update the changelog to "Verified via `wc -l`" AND retain 610/171/495 values; explicitly note that Read-tool reports a different count due to trailing-newline semantics — values then match the cited method.
3. Drop specific line-count citations entirely; replace with creation-date anchors ("created 2026-05-14") which eliminates the recurring drift class — same option Pass 9 suggested.

Option 3 is structurally equivalent to the v0.4.5 line-number-to-grep-anchor structural fix already applied to the Self-Audit Checklist. Applying the same discipline to Traceability citations eliminates the entire defect class.

---

## Suggestions

### F-PASS10-S1 [SUGGESTION] — Open Question #2 retains "Lock-status: RESOLVED" pattern that v0.4.5 fix-burst reframed for Q12 but did NOT sibling-sweep to Q2

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** Open Question #2 at line 658
- **Confidence:** HIGH

**Evidence:**

Line 658 (Open Question #2):
> 2. **Adversary model defaults.** Adversary model defaults are locked in v0.x as Opus producer + Sonnet adversary (or vice-versa for different-family rotation). Operators MAY override via `.brain/policies.yaml`. **Lock-status: RESOLVED in v0.3.1.** (`llm-second-brain-phased-build-plan.md` §13 #6; elicitation-notes.md Q-5)

Compare to:
- Open Question #8 (line 670): uses `~~strikethrough~~` formatting plus "**Resolved (v0.3.0 brief, user-confirmed).**" — the canonical "resolved-but-visible" pattern
- Open Question #12 (line 678): reframed in v0.4.5 from "Lock-status: ... committed" to "**Open dimension:** what measurable criteria... would trigger this reversal?" — converting a self-resolved entry into a genuine open question

Pass 9 F-PASS9-O2 identified Q12 as a "self-resolved decision documented in the wrong section" and prescribed three fix options: (a) move to a Resolved Decisions section, (b) use strikethrough resolved pattern, or (c) reframe to expose the genuinely-open dimension. The v0.4.5 fix-burst applied option (c) to Q12 — but did not sibling-sweep Q2, which exhibits the exact same defect pattern.

The Open Questions contract at line 654 reads:
> These questions remain open. None are placeholder deferrals — each has a clear ownership path and will be resolved before the phase that requires them.

Q2 violates this contract: it is NOT open. It is resolved. The "Lock-status: RESOLVED in v0.3.1" assertion makes it explicit.

**Why SUGGESTION (not IMPORTANT):**

The pattern is unambiguously a sibling-sweep miss from the v0.4.5 fix-burst — exactly the discipline lapse Pass 7 F-PASS7-I1 and the v0.4.3 fix-burst were designed to systematically prevent. The defect is one-line scope, well-bounded, and identical in shape to the Q12 fix already applied. But it does not block implementation: the reader can determine that Q2 is resolved by reading the entry. Compared to F-PASS10-I1's false-attestation severity, this is one tier below.

**Fix options:**
1. Apply strikethrough + "Resolved (vX.Y)" framing to Q2 matching Q8's pattern.
2. OR move Q2 to a new "Resolved Decisions" subsection above Open Questions.
3. OR reframe Q2 to expose a genuinely-open dimension (e.g., "What policy-override syntax should `.brain/policies.yaml` accept for operator override of model defaults?" — if any such genuine question remains).

---

## Observations

### F-PASS10-O1 [OBSERVATION] — "ship by v0.9" framing in Phase 2-3 polish skills section creates timing ambiguity for `/brain:publish-content` (skill #22), which v0.5 milestone requires operational

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** skill #22 at line 376 (in "Phase 2-3 polish skills (12 — ship by v0.9)" subsection); v0.5 milestone at line 294
- **Confidence:** MEDIUM

**Evidence:**

Line 367: "Phase 2–3 polish skills (12 — ship by v0.9):"
Line 376 (skill #22): `/brain:publish-content <file>` — publishing orchestrator...

Line 294 (v0.5 milestone): "LinkedIn Posts API (Community Management) integration live and tested end-to-end: at least one post published to LinkedIn via `/brain:publish-content`."

For the v0.5 milestone to be claimable, `/brain:publish-content` must be functional at v0.5 — not v0.9. The "Phase 2-3 polish skills (12 — ship by v0.9)" framing reads naturally as "all 12 must be present at v0.9" but is also compatible with "individual skills land throughout Phase 2-3 and v0.5 may have some early-shipped." Similarly, `/brain:monthly-perf` (skill #18, line 372) is also required operational at v0.5 (line 297).

The brief doesn't explicitly state which of the 12 Phase 2-3 polish skills ship at v0.5 versus throughout Phase 3. An implementer reading just §Scope would have a different timing model than one reading §v0.5 milestone.

**Why OBSERVATION (not SUGGESTION):**

The v0.5 milestone section is internally consistent and unambiguous about which skills are required there. The "by v0.9" framing in §Scope is reasonable for the latest-ship-date semantics. This is a soft framing issue, not a defect, but resolving it would prevent confusion for implementers reading §Scope in isolation.

**Fix options:**
1. Add a parenthetical at line 367: "(12 — ship by v0.9; subset listed below ship at v0.5 milestone: skills #18, #22)".
2. OR add cross-references on skills #18 and #22 noting their v0.5 timing.

---

### F-PASS10-O2 [OBSERVATION] — "plan §A.2" citation is ambiguous between the two planning docs that each have an §A.2; brief uses it for both folder-structure (phased-build-plan §A.2) and prompt-injection-patterns (plan.md §A.2) contexts

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** line 203, line 382, line 464, line 670 (all reference "plan §A.2" with folder-structure intent)
- **Confidence:** MEDIUM

**Evidence:**

Verified against the two planning docs:
- `docs/planning/llm-second-brain-plan.md` §A.2 (line 2177) = "Prompt-injection patterns to strip in `/quarantine-check`"
- `docs/planning/llm-second-brain-phased-build-plan.md` §A.2 (line 803) = "Target folder structure" (containing the 9-source-subdir layout, 5-briefs-subdir layout, etc.)

The brief uses "plan §A.2" at four call-sites in folder-structure contexts (lines 203, 382, 464, 670) — semantically these should resolve to phased-build-plan §A.2. But "plan.md" (line 234, line 318, line 321, line 464, line 546, etc.) without qualification typically refers to `llm-second-brain-plan.md` based on Traceability §Source planning documents at lines 686-691.

Line 464 in particular reads "per plan §A.2's full 9-subdir layout" — the "9-subdir layout" content only exists in phased-build-plan §A.2 at line 803-821, NOT in plan.md §A.2. The brief's citation shorthand is non-unique and an implementer cross-referencing might land on the wrong artifact.

**Why OBSERVATION (not SUGGESTION):**

This is a citation precision issue across multiple call-sites. The intent is recoverable by content cross-reference. But the brief's own §Traceability lists FOUR planning docs, and "plan §A.2" matches two of them. A reader following the citation breadcrumb has a 50/50 disambiguation at each call-site.

**Fix options:**
1. Sibling-sweep "plan §A.2" → "phased-build-plan §A.2" at lines 203, 382, 464, 670 wherever folder-structure intent applies.
2. OR add a "citation conventions" note at the top of the brief specifying that bare "plan" refers to phased-build-plan and bare "plan.md" refers to llm-second-brain-plan.md.

---

## Pass 9 Fix Verification (regression check)

| Pass 9 finding | v0.4.5 fix | Verification |
|---|---|---|
| F-PASS9-I1 (Self-Audit line-numbers stale) | Replaced all line-number refs in §Self-Audit Checklist with grep-anchored semantic references; refreshed all v0.4.X annotations | **STRUCTURALLY VERIFIED.** Grep for `L\d+` pattern in Self-Audit Checklist section (lines 718-731) returns ZERO matches. The structural fix is durable against future edits. |
| F-PASS9-S1 (line-count off-by-one) | Asserted values 610/171/495 are correct; claimed "Verified via Read tool" | **PAPER-FIXED + FALSE ATTESTATION.** Read tool authoritatively reports 611/172/496. Changelog claim is demonstrably false. **See F-PASS10-I1.** Pass 9 was correct; v0.4.5 product-owner's "rigorous verification" used `wc -l` (which counts newline chars), not Read tool, despite the changelog claim. |
| F-PASS9-S2 (highlights/bookmarks scope) | Added explicit on-demand note at line 464 ("Two additional source subdirs (`highlights/` and `bookmarks/`) are created on-demand by the v0.5 GH Action templates...") | **STRUCTURALLY VERIFIED.** Citation to "plan §A.2's full 9-subdir layout" is technically ambiguous (see F-PASS10-O2) but the on-demand framing resolves the original drift. |
| F-PASS9-O1 (v0.9 backend path ambiguity) | Locked v0.9 gate to default web-search path; Perplexity MCP opt-in path tested separately in Phase 3 dogfood | **STRUCTURALLY VERIFIED.** Line 304 now reads "The v0.9 ship gate tests the default web-search backend path (i.e., operator has NOT opted in to Perplexity MCP)". |
| F-PASS9-O2 (Q12 self-resolved) | Reframed Q12 to "Open dimension: what measurable criteria... would trigger this reversal?" | **STRUCTURALLY VERIFIED at Q12; SIBLING-SWEEP MISS at Q2.** Q2 retains the identical "Lock-status: RESOLVED" pattern. See F-PASS10-S1. |

**3 of 5 Pass 9 fixes verified structurally. 1 of 5 paper-fixed (F-PASS9-S1 → F-PASS10-I1). 1 of 5 sibling-sweep miss (F-PASS9-O2 fix not propagated to Q2).**

---

## Earlier-Pass Regression Check

| Earlier finding | Current v0.4.5 status |
|---|---|
| Pass 7 F-PASS7-I1 (12→13 hooks at L186/L311/L574) | **STILL CORRECT.** Verified 13-hook callsites at lines 210, 270, 276, 282, 302, 336 with adjustment parentheticals. Line 412 correctly says "The 12 hooks from phased plan §A.4" (plan-doc-baseline reference) and line 426 adds "Plus 1 from wclaude absorption (bumps count 12 → 13)" — the structural framing is intact. |
| Pass 8 F-PASS8-I1 (/brain:research v0.1-vs-v0.9 timing) | **STILL CORRECT.** Line 277 commits v0.1 ship gate to `briefs/research/` scaffolding only; line 304 commits v0.9 ship gate to runtime-dispatch testing; line 382 (skill #26) clearly labels as "ships by v0.9". |
| Pass 8 F-PASS8-I2 (Perplexity MCP optional) | **STILL CORRECT.** Line 304 specifies default-web-search; line 382 confirms opt-in; line 517 documents in Constraints; frontmatter `perplexity_mcp_status` lock present at line 50. |
| Pass 6 F-PASS6-S1 / Pass 7 F-PASS7-S4 (§8.3 → §10.5 citation) | **STILL CORRECT.** Line 184 cites "§8.2.4 ("verdicts must match") and §10.5 (where the literal pass-criterion `diff_count = 0` appears)". |
| Pass 3 fix: 6 wiki types per plan §3.4 | **STILL CORRECT.** Line 234 enumerates: "concepts, people, frameworks, syntheses, observations, questions"; line 463 cross-references "6 wiki page type templates — one per wiki type". |

**All earlier-pass fixes preserved. No regression observed in count discipline, citation discipline, or structural commitments other than F-PASS10-I1's residual line-count paper-fix.**

---

## Count Adjustment Sibling-Sweep Audit

| Adjustment | Plan-doc baseline | Brief value | Callsites verified |
|---|---|---|---|
| 12 → 13 hooks | phased-build-plan §A.4 (12), §5.11 (12), §7.5 (12), §8.3 (12) | 13 | **CONSISTENT.** Frontmatter line 29; all 4 gates (lines 210, 270, 276, 282, 302, 336); §Scope §13-hooks list at line 410. |
| 25 → 26 skills | plugin plan §5 ("25 skills") | 26 | **CONSISTENT.** Frontmatter line 27; Vision line 107; v0.9 gate line 303; Scope line 350-382. |
| 10 → 14 agents | plugin plan §6 ("10 agents") | 14 | **CONSISTENT.** Frontmatter line 28; Family Positioning line 199; Scope agents list lines 386-407. |
| 19 GH Actions | plan.md §8.1-§8.18 (6+9+4) | 19 | **CONSISTENT.** Frontmatter lines 30-32; Vision line 107; v0.5 milestone line 293; Scope line 431-457. |

No count-adjustment sibling-sweep defects beyond the Q2 / Q12 strikethrough-pattern miss (F-PASS10-S1).

---

## Citation Spot-Check (7 sampled, including v0.4.5-touched citations)

| # | Citation | Source verified | Verdict |
|---|---|---|---|
| 1 | Line 184 → phased-plan §8.2.4 + §10.5 (`diff_count = 0`) | phased-plan §10.5 contains literal `diff_count = 0`; §8.2.4 contains "verdicts must match" | VERIFIED |
| 2 | Line 317 → stage-3-locks.md §132 (SL-9), §144 (SL-10) | stage-3-locks.md L132 = `## SL-9 — Scalability scope`; L144 = `## SL-10 — Scale target` | VERIFIED |
| 3 | Line 234 → plan.md §3.4 (6 wiki types) | plan.md §3.4 at L201 enumerates 6 types | VERIFIED |
| 4 | Line 464 → plan §A.2 (9-subdir layout) | Ambiguous: plan.md §A.2 is prompt-injection-patterns (line 2177); phased-build-plan §A.2 (line 803) has 9-subdir layout. Content intent matches phased-build-plan. | **AMBIGUOUS** (F-PASS10-O2) |
| 5 | Line 702 → elicitation-notes.md (610-line) | Read tool: 611 lines | **FAILED** (F-PASS10-I1) |
| 6 | Line 706 → stage-3-locks.md (171-line) | Read tool: 172 lines | **FAILED** (F-PASS10-I1) |
| 7 | Line 710 → brief-research.md (495-line) | Read tool: 496 lines | **FAILED** (F-PASS10-I1) |

**3 verified, 1 ambiguous (F-PASS10-O2), 3 failed (F-PASS10-I1).**

---

## Self-Audit Checklist Structural-Fix Audit (Pass 10 specific)

Per the dispatch instruction: "F-PASS9-I1 STRUCTURAL FIX: Grep §Self-Audit Checklist for any `L<number>` pattern. ZERO matches expected."

Verification: Grep'd lines 718-731 (Self-Audit Checklist section) for `L\d+` regex. **ZERO MATCHES.** Structural fix is durable.

The structural fix replaced specific line-number citations with semantic anchors such as:
- "§Reference Repositories devops-engineer bootstrap entry"
- "§Family Positioning competing-implementations paragraph"
- "v0.1 ship gate `.reference/` bootstrap item"
- "Open Question #8 resolved annotation"

These anchors survive line-shift edits because they reference durable section names rather than ephemeral positions. The methodology change is correct and addresses the recurring "stale-line-number-after-edit" defect class that Passes 5, 7, and 9 each caught.

**The structural fix introduced one new defect class:** ambiguous "plan §A.2" citations (F-PASS10-O2). But this defect class predates the v0.4.5 fix-burst — the citation pattern existed before v0.4.5 and was not introduced by the structural fix. Verified by Grep against v0.4.4 content trail.

---

## Multi-Callsite Identifier Coherence Check

| Identifier | Callsites | Verdict |
|---|---|---|
| `/brain:research` | line 277 (v0.1 scaffold), line 304 (v0.9 runtime), line 382 (§26 Scope), line 492 (NOT-absorbed), line 526 (Phase 3 timeline), line 670 (Q8 resolved) | **COHERENT** — all consistent with v0.9 timing |
| `Perplexity MCP` | line 50 (frontmatter), line 64 (changelog), line 304 (v0.9 gate), line 382 (§26 opt-in), line 517 (Constraints), line 678 (Q12 reframed) | **COHERENT** — all consistent with optional/opt-in framing |
| `validate-publish-state.sh` | line 202 (absorption), line 302 (v0.9 bats), line 336 (v1.0 WASM), line 427 (hook spec) | **COHERENT** |
| `13-hook port` / `13 bash hooks` | lines 29, 210, 270, 276, 282, 302, 336, 410, 426, 600 | **COHERENT** with adjustment parentheticals where applicable |

---

## Convergence Assessment

**The brief has NOT converged at v0.4.5.**

The v0.4.5 fix-burst applied an excellent structural fix (line-number → grep-anchored references in Self-Audit Checklist) — this is the kind of root-cause fix that eliminates an entire defect class rather than patching individual instances. The structural-fix discipline is sound.

However, the fix-burst introduced a **new false-attestation defect** (F-PASS10-I1) by claiming "Verified via Read tool" when the values cited are `wc -l`-derived. This is a paper-fix at a more subtle level than prior paper-fixes: the fix asserts that prior adversary review (Pass 9) was wrong rather than addressing the underlying counting-semantics ambiguity. Pass 9's measurement (via Read tool) was correct; v0.4.5's measurement (via `wc -l`) is also correct under different semantics. The DEFECT is the changelog claim that the tool was Read when it was `wc -l`.

Additionally, the Q12 reframing (F-PASS9-O2 fix) was not sibling-swept to Q2 (F-PASS10-S1). This is the same fix-burst-misses-siblings discipline failure that Pass 7 F-PASS7-I1 caught and that the brief's own self-audit at line 729 specifically commits to preventing.

**The remaining defects are:**
- 1 IMPORTANT defect (F-PASS10-I1) — false-attestation in v0.4.5 changelog re: line-count verification method
- 1 SUGGESTION defect (F-PASS10-S1) — Q2 retains the "Lock-status: RESOLVED" pattern that the v0.4.5 fix-burst reframed for Q12 but did not sibling-sweep
- 2 OBSERVATIONS (timing ambiguity for v0.5-required skills; "plan §A.2" citation ambiguity)

A v0.4.6 fix-burst addressing F-PASS10-I1 + F-PASS10-S1 should converge in a single pass.

**Process-gap candidate (not flagged as [process-gap]):** The line-count citation has now been an adversary-finding subject across THREE consecutive passes (Pass 8 F-PASS8-S2, Pass 9 F-PASS9-S1, Pass 10 F-PASS10-I1) without structural resolution. The recurring pattern suggests the line-count citation format itself is fragile against measurement-tool divergence (`wc -l` vs Read tool). The durable fix is the same one applied to Self-Audit Checklist in v0.4.5: replace specific line counts with creation-date anchors that don't drift. This is not a brain-factory engine concern — it's a brief authoring convention — so not flagged `[process-gap]`.

---

## Streak Decision

**Streak: stays at 0/3.**

1 IMPORTANT finding (F-PASS10-I1) is blocker-grade. Per protocol: ANY blocker findings → streak stays at 0/3, dispatch product-owner fix-burst.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 1 | FAIL (15) | 0/3 |
| Pass 2 | FAIL (4) | 0/3 |
| Pass 3 | FAIL (6) | 0/3 |
| Pass 4 | FAIL (4) | 0/3 |
| Pass 5 | PASS (0 blockers) | 1/3 |
| Pass 6 | PASS (0 blockers) | 2/3 |
| Pass 7 | FAIL (1 IMPORTANT) | 0/3 (RESET) |
| Pass 8 | FAIL (2 IMPORTANT) | 0/3 |
| Pass 9 | FAIL (1 IMPORTANT) | 0/3 |
| **Pass 10** | **FAIL (1 IMPORTANT)** | **0/3** |

---

## Novelty Assessment

**Novelty: MEDIUM-HIGH.**

F-PASS10-I1 is a NEW defect class: paper-fix that escalates "false positive" status onto a prior adversary finding by citing a verification method that produces values matching the brief's claim but not the cited method. The defect could only be caught by independently verifying the cited method (Read tool) against the cited values. Pass 9 correctly identified the off-by-one; the v0.4.5 fix-burst's "rigorous wc -l + xxd verification" (mentioned in the dispatch context) used a different tool than the changelog claims, and the changelog's "via Read tool" claim is false.

F-PASS10-S1 is a sibling-sweep miss in the same fix-burst that applied F-PASS9-O2 → Q12 reframing. The Q2 / Q12 asymmetry is structurally identical to Pass 7's 12 → 13 hook count sibling-sweep miss.

F-PASS10-O1 and F-PASS10-O2 are observation-grade soft framing issues — neither blocks implementation.

**Genuinely new ground: yes.**
- F-PASS10-I1: novel meta-finding (a fix-burst's "false positive" attribution itself being incorrect, with false-attestation in the changelog).
- F-PASS10-S1: sibling-sweep gap on the Open Question resolved-pattern axis.
- F-PASS10-O2: bidirectional plan-doc citation ambiguity — "plan §A.2" matches two artifacts. Has existed across multiple versions but was not previously flagged because passes focused on within-section consistency, not cross-doc disambiguation.

**Compared to Pass 9:** Pass 9 found 1 IMPORTANT (F-PASS9-I1 self-audit line numbers) + 2 SUGGESTION (F-PASS9-S1 line-count, F-PASS9-S2 highlights/bookmarks) + 2 OBSERVATION (F-PASS9-O1 backend path, F-PASS9-O2 Q12). Of these, 3 are structurally fixed in v0.4.5; 1 is paper-fixed and resurfaces here (F-PASS9-S1 → F-PASS10-I1); 1 is sibling-sweep-incomplete (F-PASS9-O2 → F-PASS10-S1).

**The fresh-context different-model adversarial review pattern is working as designed.** Pass 10's independent verification of the v0.4.5 changelog's "Verified via Read tool" claim against the actual Read tool output exposed a defect that would have been invisible to any reviewer relying on the changelog assertion at face value.

---

## Top 3 Findings

1. **F-PASS10-I1 [IMPORTANT]** — The v0.4.5 changelog at line 57 asserts line-count citations were "Verified via Read tool" yielding 610/171/495. Direct Read tool authoritative replies for the three Traceability artifacts (elicitation-notes.md, stage-3-locks.md, brief-research.md) return 611/172/496. The values are `wc -l`-derived (off by one due to no trailing newline), not Read-tool-derived. Pass 9 F-PASS9-S1 was CORRECT, not a false positive. **Fix:** either update Traceability values to 611/172/496 and retain "via Read tool" claim, OR update changelog to "via wc -l" and retain 610/171/495 with a tool-divergence note, OR drop specific counts and use creation-date anchors (option 3 is structurally analogous to the v0.4.5 line-number-to-grep-anchor fix already applied to Self-Audit Checklist).

2. **F-PASS10-S1 [SUGGESTION]** — Open Question #2 at line 658 retains the "Lock-status: RESOLVED in v0.3.1" pattern that the v0.4.5 fix-burst reframed for Q12 (per F-PASS9-O2). Q8 uses strikethrough; Q12 was reframed to an open dimension; Q2 retains the resolved-not-strikethrough pattern. Sibling-sweep miss in the same fix-burst that addressed Q12. **Fix:** apply strikethrough + resolved framing matching Q8, OR reframe to expose a genuinely open dimension matching Q12's new shape.

3. **F-PASS10-O2 [OBSERVATION]** — "plan §A.2" citation is ambiguous: `llm-second-brain-plan.md` §A.2 is "Prompt-injection patterns" (line 2177); `llm-second-brain-phased-build-plan.md` §A.2 is "Target folder structure" with the 9-source-subdir layout (line 803). Brief uses "plan §A.2" at four call-sites (lines 203, 382, 464, 670) with folder-structure intent — all resolving to phased-build-plan §A.2, not plan.md §A.2. **Fix:** sibling-sweep to "phased-build-plan §A.2" at affected call-sites, OR add a citation-shorthand convention note at brief top.

---

## Recommended Next Action

1. **Dispatch product-owner** for a v0.4.6 fix-burst addressing:
   - **F-PASS10-I1 (BLOCKER):** Reconcile the line-count citation method-claim divergence. Recommended option: apply the same root-cause discipline used for the v0.4.5 Self-Audit Checklist structural fix — drop specific line counts in favor of creation-date anchors at lines 702, 706, 710. This eliminates the defect class permanently.
   - **F-PASS10-S1:** Apply Q12-style reframing (or Q8-style strikethrough) to Q2 at line 658.
   - **F-PASS10-O2:** Sibling-sweep "plan §A.2" → "phased-build-plan §A.2" where folder-structure intent applies (lines 203, 382, 464, 670).
   - **F-PASS10-O1:** OPTIONAL — add cross-reference notes on skills #18 and #22 noting their v0.5 timing within the "ship by v0.9" subsection.
2. After fix-burst lands as v0.4.6, dispatch Pass 11 with fresh context to begin a new 3-CLEAN cascade.

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.5
target_line_count_read_tool: 732
target_line_count_wc_l: 731  # dispatch said 731 — same off-by-one as F-PASS10-I1
pass_number: 10
adversary_protocol: BC-5.39.001 3-CLEAN
finding_counts:
  critical: 0
  important: 1
  suggestion: 1
  observation: 2
  process_gap: 0
  total_blocking: 1
verdict: FAIL
streak_before: 0/3
streak_after: 0/3
critical_finding_ids: []
important_finding_ids: [F-PASS10-I1]
suggestion_finding_ids: [F-PASS10-S1]
observation_finding_ids: [F-PASS10-O1, F-PASS10-O2]
process_gap_finding_ids: []
paper_fix_pattern_observed: true
pass_9_fixes_structurally_verified: 3
pass_9_fixes_paper_fixed: 1  # F-PASS9-S1 resurfaces as F-PASS10-I1
pass_9_fixes_sibling_sweep_incomplete: 1  # F-PASS9-O2 fix applied to Q12 but not Q2
pass_8_fixes_still_holding: 2  # F-PASS8-I1, F-PASS8-I2
pass_7_fixes_still_holding: 1  # F-PASS7-I1 (12→13 hooks)
new_findings_classification: false-attestation-in-changelog (line-count verification method mis-claimed) + sibling-sweep-miss (Q12 reframe not propagated to Q2) + citation-shorthand-ambiguity (plan §A.2 matches two artifacts)
cascade_convergence_assessment: structurally-near-converged-with-one-blocker; v0.4.6 fix-burst should converge in single pass
structural_fix_evaluation: v0.4.5 line-number-to-grep-anchor structural fix is sound; durable against future edits; introduced no new defects within Self-Audit Checklist scope
recommended_next_action: dispatch product-owner v0.4.6 fix-burst addressing F-PASS10-I1 (line-count method-claim divergence; apply same drop-specific-values discipline used for Self-Audit Checklist), F-PASS10-S1 (Q2 sibling-sweep), F-PASS10-O2 (plan §A.2 citation precision); then dispatch Pass 11
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/elicitation-notes.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/brief-research.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/reference-repos.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/vsdd-dispatcher-extraction-plan.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-7.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-8.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-9.md
```
