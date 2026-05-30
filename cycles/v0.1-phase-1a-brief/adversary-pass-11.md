---
artifact_type: adversary-pass-report
pass_number: 11
cascade: brain-factory-product-brief-v0.4.6
target_file: .factory/specs/product-brief.md
target_version: 0.4.6
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3
created: 2026-05-15
author: vsdd-factory:adversary
finding_count_critical: 0
finding_count_important: 1
finding_count_suggestion: 1
finding_count_observation: 2
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: false
v0_4_6_body_fixes_structurally_verified: 4
v0_4_6_self_audit_attestation_missing: 1
cascade_pattern: each-structural-fix-eliminates-defect-class-but-exposes-next-meta-layer
---

# Adversarial Review — Pass 11

**Target file:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.6, 739 lines per dispatch)
**Cascade:** BC-5.39.001 3-CLEAN convergence; brain-factory product brief
**Streak before:** 0/3 (first pass of new attempt at v0.4.6)
**Streak after:** **0/3** (Pass 11 FAIL — 1 IMPORTANT)
**Verdict:** FAIL

---

## Critical Findings

(none)

---

## Important Findings

### F-PASS11-I1 [IMPORTANT] — Self-Audit Checklist is stale at v0.4.5; the v0.4.6 edits are not attested anywhere in the checklist itself

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** Self-Audit Checklist (§Self-Audit Checklist, lines 730, 737, 739) — last attestation is v0.4.5 only
- **Confidence:** HIGH
- **Severity:** IMPORTANT (P1)

**Evidence:**

Frontmatter (line 6): `version: 0.4.6`
Changelog (line 55-59): Acknowledges 4 substantive v0.4.6 edits, including a STRUCTURAL FIX that dropped specific line counts from Traceability, plus Q#2 sibling-sweep, plan §A.2 disambiguation at 5 callsites, and v0.5 early-ship notes.

Self-Audit Checklist verification:

| Self-audit bullet | Last version annotated |
|---|---|
| Line 730 (rationalization audit; final parenthetical) | "...v0.4.5: structural fix for stale-line-number defect class applied; all 5 changes are clarifications or framing fixes — no count changes; Open Question #12 reframed to genuine open dimension; highlights/bookmarks scaffold clarified; v0.9 gate path locked.)" |
| Line 737 (sibling-sweep audit) | "v0.4.5: sibling-swept Open Question #12 (reframed from resolved-decision to open-dimension); v0.9 ship gate `/brain:research` item (added gate-path lock); §Scope 'Additional v0.x deliverables' 7-topic-categories item..." |
| Line 739 (frontmatter ↔ body coherence) | "**Yes — v0.4.5 edits.** ... v0.4.5: no new frontmatter fields introduced; all 5 changes are body-section edits..." |

NONE of the three self-audit bullets contain a "v0.4.6:" annotation. Critical defects in the v0.4.6 audit trail:

1. **No attestation that the v0.4.6 STRUCTURAL FIX (dropping Traceability line counts) was sibling-swept.** Line 737 (the sibling-sweep audit bullet) should record this as a discipline-axis fix. Instead it terminates at v0.4.5.
2. **No attestation that Q#2 was sibling-swept to match Q#8/Q#12 pattern.** The dispatch identified F-PASS10-S1 as a v0.4.6 fix item; the body change is present (line 664) but the self-audit doesn't record the sweep.
3. **No attestation that "plan §A.2" → "phased-build-plan §A.2" was sibling-swept across 5 callsites.** This is a canonical-identifier change exactly matching the discipline that line 737 commits to: "sibling-sweep all callsites when I changed a hook signature, exit-code semantic, or canonical identifier." Citation shorthand is a canonical identifier.
4. **No attestation that v0.4.6's frontmatter ↔ body coherence holds.** Line 739 still says "Yes — v0.4.5 edits." Version 0.4.6 frontmatter (`version: 0.4.6`) is now uncovered by the coherence audit.

**Why IMPORTANT (not SUGGESTION):**

1. **Same defect class as F-PASS9-I1** — stale Self-Audit Checklist after edits. F-PASS9-I1 was the trigger for the v0.4.5 STRUCTURAL FIX (line-number → grep-anchored references). That structural fix solved the L-number drift class. But the NEW class introduced here is a more fundamental one: the audit checklist is not being refreshed at all for each new version. The grep-anchor structural fix prevents in-attestation line-number drift but does nothing to address missing per-version attestations.
2. **The v0.4.6 fix-burst added the v0.5 early-ship cross-reference to skill #18/#22 (a sibling-sweep on timing semantics) but the discipline-trail of "sibling-swept Phase 2-3 polish skill header" is absent from line 737.** This is exactly the discipline that the brief's own Pass 7 F-PASS7-I1 lesson committed to enforcing.
3. **Self-attestation gap is the same shape as F-PASS10-I1** (false attestation in changelog re: tool-method). The v0.4.6 fix-burst correctly applied the structural fix, but the self-audit trail asserts compliance only as of v0.4.5 — so the most recent fix-burst is unaudited by the brief's own quality bar. A reader running the brief's self-audit cannot confirm v0.4.6 compliance from the checklist.
4. **Forward-impact:** Pass 12 fresh-context will rediscover this. Each pass increments the version-attestation gap unless the self-audit is structurally refreshed with each fix-burst.

**Why this is structurally interesting:**

The v0.4.5 STRUCTURAL FIX (grep-anchored references) eliminated stale-L-number drift. The v0.4.6 STRUCTURAL FIX (creation-date anchors instead of line counts) eliminated wc-l-vs-Read-tool drift. Both are excellent root-cause discipline. **But neither addresses the meta-issue:** the Self-Audit Checklist accumulates by appending per-version annotations, and the fix-burst that adds v0.X.Y edits must also append a `v0.X.Y:` annotation to each relevant bullet. The structural fix for THIS class would be to either (a) replace per-version-appended annotations with a single "see Changelog" reference, OR (b) enforce a fix-burst protocol where every body edit MUST be paired with a self-audit annotation update — i.e., make the audit-trail update structural rather than habitual.

**Fix options:**

1. Append `v0.4.6:` annotations to lines 730, 737, 739 recording the 4 v0.4.6 fixes (Traceability structural fix; Q#2 sibling-sweep; plan §A.2 disambiguation across 5 callsites; v0.5 early-ship cross-reference for skills #18/#22).
2. OR (structural) — collapse the per-version annotation list in each bullet to a single sentence: "All version-by-version fix-burst details recorded in §Changelog at top of brief" — making the checklist version-agnostic and eliminating this drift class entirely.

Option 2 is structurally analogous to the v0.4.5 grep-anchor fix and the v0.4.6 creation-date anchor fix — same discipline pattern: eliminate drift-prone content from the audit-trail itself.

---

## Suggestions

### F-PASS11-S1 [SUGGESTION] — v0.4.6 changelog claims "Disambiguated 'plan §A.2' → 'phased-build-plan §A.2' at 4 callsites" but the actual count is 5 callsites

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** changelog (line 58); body callsites (lines 209, 283, 388, 470, 676)
- **Confidence:** HIGH

**Evidence:**

Line 58 (v0.4.6 changelog):
> Disambiguated "plan §A.2" → "phased-build-plan §A.2" at 4 callsites; added Citation Conventions note (F-PASS10-O2)

Grep `phased-build-plan §A\.2` in body (excluding the changelog at line 58):
- Line 209: `drafts/{platform}/` extension framing
- Line 283: `/brain:init` scaffolds `briefs/research/` subdirectory
- Line 388: §Scope skill #26 `/brain:research` description ("extends... beyond phased-build-plan §A.2's enumerated `briefs/{daily,weekly,monthly,content,decisions}/` subdirs")
- Line 470: §Scope additional deliverables 7-topic-categories ("per phased-build-plan §A.2's full 9-subdir layout")
- Line 676: Open Question #8 (resolved annotation: "phased-build-plan §A.2's five enumerated `briefs/` subdirs")

**Total: 5 callsites, not 4.**

The discrepancy is minor in impact: the sweep is correctly applied across all 5 body callsites. But the changelog under-counts. Pass 10 F-PASS10-O2 identified the 4 ambiguous "plan §A.2" callsites at lines 203, 382, 464, 670 of v0.4.5 — but missed line 676 (which already referred to the planning doc as "phased-build-plan §A.2's five enumerated" but the surrounding history is unclear). The v0.4.6 fix-burst then anchored its claim to Pass 10's count.

**Why SUGGESTION (not IMPORTANT):**

The disambiguation is structurally complete (all 5 body callsites now correctly use "phased-build-plan §A.2"). Only the changelog's counting claim is off-by-one. This is not a contradiction with implementation behavior — purely an attestation precision issue analogous to F-PASS10-I1's class but less material because no downstream artifact relies on the count.

**Fix options:**

1. Update changelog line 58 from "4 callsites" to "5 callsites" (or "at all callsites").
2. OR remove the specific count: "Disambiguated 'plan §A.2' → 'phased-build-plan §A.2' at all body callsites with folder-structure intent".

Option 2 is preferable per the drift-eliminate discipline — same pattern as the Traceability structural fix.

---

## Observations

### F-PASS11-O1 [OBSERVATION] — Open Questions section preamble "These questions remain open" contradicts Q#2 (resolved) and Q#8 (resolved); the section has carried this implicit contradiction through 10+ passes

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** preamble (line 660); Q#2 (line 664); Q#8 (line 676)
- **Confidence:** MEDIUM

**Evidence:**

Line 660 (section preamble):
> These questions remain open. None are placeholder deferrals — each has a clear ownership path and will be resolved before the phase that requires them.

Q#2 (line 664): `~~...~~ **Resolved (v0.3.1 brief, user-confirmed):**`
Q#8 (line 676): `~~...~~ **Resolved (v0.3.0 brief, user-confirmed).**`

The preamble says "remain open" but two of 12 entries are explicitly resolved. The strikethrough pattern is the visible-history convention but contradicts the preamble's open-only framing. Pass 10 caught only the Q#2/Q#8/Q#12 inter-entry asymmetry; the preamble-vs-resolved-entries contradiction is a different defect — present since v0.3.0 — and structurally affects how a reader interprets the section.

**Why OBSERVATION (not SUGGESTION):**

The convention is visually clear (strikethrough = resolved-but-visible). An attentive reader does not get confused. But the preamble assertion ("remain open") is technically false. A strict reader auditing for accuracy would catch this. The fix is one-sentence: add to the preamble "Resolved entries retained with strikethrough for traceability; only un-struck entries are open."

**Fix options:**

1. Update preamble at line 660 to: "These questions are tracked here. Resolved entries retain strikethrough + Resolved annotation for traceability; un-struck entries are open. Each open entry has a clear ownership path and will be resolved before the phase that requires them."
2. OR move resolved entries (Q#2, Q#8) to a separate "Resolved Decisions" subsection above Open Questions — making the section heading semantically accurate.

---

### F-PASS11-O2 [OBSERVATION] — Self-Audit checklist line 739 misuses "locked_decisions" framing for `stage_3_locks` (which is a top-level metadata field, not under the `locked_decisions:` block)

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** frontmatter (line 20 `stage_3_locks:` is a top-level field, NOT inside `locked_decisions:`); self-audit (line 739)
- **Confidence:** MEDIUM

**Evidence:**

Frontmatter structure:
- Line 20: `stage_3_locks: .factory/planning/stage-3-locks.md` — TOP-LEVEL field
- Line 21: `locked_decisions:` — block header
- Lines 22-50: indented block of locked_decisions fields

Self-Audit line 739: "Did I cross-check every `locked_decisions` field in frontmatter against the body section that implements it... **Yes — v0.4.5 edits.** ... New v0.4.3 field: `stage_3_locks: .factory/planning/stage-3-locks.md` verified against §Traceability §Stage 3 locks subsection."

The self-audit attributes `stage_3_locks` to "locked_decisions" verification but the field is at the YAML root level alongside `artifact_type`, `project`, `phase`, `version`, etc. — not inside the `locked_decisions:` block.

The same minor mis-attribution applies to other top-level fields the self-audit doesn't audit (e.g., `source_documents`, `sibling_references`, `elicitation_notes`).

**Why OBSERVATION:**

The verification claim itself is correct — stage-3-locks.md IS cited in §Traceability §Stage 3 locks subsection (line 714). The mis-attribution is whether the field is "under locked_decisions" or "at top level". Pure framing issue; the substantive coverage holds.

**Fix options:**

1. Move `stage_3_locks` under `locked_decisions:` block (treats it as a locked decision).
2. OR amend self-audit bullet language: "cross-check every locked_decisions field AND top-level reference field in frontmatter against the body section that implements it."

---

## v0.4.6 Fix Verification (regression check)

| Pass 10 finding | v0.4.6 fix claim | Verification |
|---|---|---|
| F-PASS10-I1 (Traceability line counts; false-attestation) | STRUCTURAL FIX: dropped specific line counts; replaced with creation-date anchors | **STRUCTURALLY VERIFIED.** Grep `\b[0-9]{3}-line\b` in §Traceability returns ZERO matches in artifact-citation contexts. The 610/171/495 values appear ONLY in v0.4.4 and v0.4.5 historical changelog entries (lines 63, 71). Creation-date anchors at lines 710, 714, 718 verified. Same discipline as v0.4.5 grep-anchor structural fix to Self-Audit. |
| F-PASS10-S1 (Q#2 strikethrough sibling-sweep) | Applied Q#8-style strikethrough + Resolved annotation | **STRUCTURALLY VERIFIED.** Line 664 now reads `~~**Adversary model defaults.**...~~ **Resolved (v0.3.1 brief, user-confirmed):** Lock = Opus producer + Sonnet adversary by default; operator override via .brain/policies.yaml`. Pattern matches Q#8. |
| F-PASS10-O2 (plan §A.2 ambiguity) | Disambiguated at 4 callsites + Citation Conventions block | **STRUCTURALLY VERIFIED (but under-counted; see F-PASS11-S1).** All 5 body callsites use `phased-build-plan §A.2`. Citation Conventions block added at line 690. The changelog claim of "4 callsites" is undercount; sweep itself is complete at 5 sites. |
| F-PASS10-O1 (v0.5 early-ship timing) | Added v0.5 timing notes for skills #18 and #22 | **STRUCTURALLY VERIFIED.** Line 373 header now reads: "Phase 2–3 polish skills (12 — ship by v0.9; skills #18 `/brain:monthly-perf` and #22 `/brain:publish-content` ship early at v0.5 milestone per §Success Criteria v0.5 milestone)". |

**4 of 4 Pass 10 body-fixes verified structurally. 1 of 4 changelog-attestation off-by-one (F-PASS11-S1). 0 of 4 self-audit attestation updates (F-PASS11-I1).**

---

## Earlier-Pass Regression Check (Pass 5-9 fixes still holding?)

| Earlier finding | Current v0.4.6 status |
|---|---|
| Pass 7 F-PASS7-I1 (12→13 hooks at multiple callsites) | **STILL CORRECT.** Verified 13-hook callsites at lines 216, 276, 282, 288, 308, 342 with adjustment parentheticals. Line 418 correctly says "The 12 hooks from phased plan §A.4" (plan-doc baseline reference); line 432 "Plus 1 from wclaude absorption (bumps count 12 → 13)". |
| Pass 8 F-PASS8-I1 (/brain:research v0.1-vs-v0.9 timing) | **STILL CORRECT.** Line 283 commits v0.1 to `briefs/research/` scaffolding only; line 310 commits v0.9 to runtime-dispatch; line 388 (skill #26) labels as "ships by v0.9". |
| Pass 8 F-PASS8-I2 (Perplexity MCP optional) | **STILL CORRECT.** Frontmatter `perplexity_mcp_status: optional-opt-in-research-backend (v0.9+; web-search is default)` at line 50; v0.9 gate at line 310; §Scope #26 at line 388; Constraints note at line 523. |
| Pass 9 F-PASS9-I1 (Self-Audit Checklist L-number drift) | **STRUCTURALLY VERIFIED.** Grep `\bL[0-9]+\b` in §Self-Audit Checklist (lines 726-739) returns ZERO matches. The grep-anchor structural fix is durable. |
| Pass 6 F-PASS6-S1 / Pass 7 F-PASS7-S4 (§8.3 → §10.5 citation for `diff_count = 0`) | **STILL CORRECT.** Line 190 cites "§8.2.4 ("verdicts must match") and §10.5 (where the literal pass-criterion `diff_count = 0` appears)". |
| Pass 3 fix (6 wiki types per plan §3.4) | **STILL CORRECT.** Line 240 enumerates: "concepts, people, frameworks, syntheses, observations, questions"; line 469 cross-references "6 wiki page type templates — one per wiki type". |

**All earlier-pass fixes preserved. No regression observed.**

---

## Standard Cumulative Checks

### Enumerated counts (all 11)

| Count | Frontmatter | Body callsites | Verdict |
|---|---|---|---|
| 26 skills | line 27 (`skill_count_v0_9: 26`) | line 113 (Vision); line 309 (v0.9 gate); §Scope lines 356-388 (13+12+1=26) | **CONSISTENT** |
| 14 agents | line 28 (`agent_count_v0_9: 14`) | line 205 (Family Positioning); §Scope lines 392-412 (10+4=14) | **CONSISTENT** |
| 13 hooks | line 29 (`hook_count_v0_x: 13`) | lines 216, 276, 282, 288, 308, 342, 416, 432, 606 | **CONSISTENT** with adjustment parentheticals |
| 19 GH Actions total | line 30 | lines 113, 299, 437 | **CONSISTENT** |
| 15 author-committed | line 31 | line 113; §Scope lines 437-456 (6+9=15) | **CONSISTENT** |
| 4 community-optional | line 32 | line 113; §Scope lines 458-462 | **CONSISTENT** |
| 9 bats suites | (not in frontmatter; cited in self-audit) | line 289 ("within the existing 9-suite bats coverage"); line 474 (8+1=9) | **CONSISTENT** |
| 8 wclaude absorptions | (not numeric; `wclaude_absorption: patterns-and-agents-merged-into-existing-plan`) | line 203 ("Eight wclaude... = eight total absorption items"); lines 205-212 enumeration (4+7=8 — one absorption group counts as 1) | **CONSISTENT** |
| 7 reference repos | line 48 (`reference_repo_count: 7`) | line 599 ("7 publicly-documented implementations"); §Reference Repositories lines 618-630 (numbered 1-7) | **CONSISTENT** |
| 10 baseline policies | (not numeric; line 471) | line 471; CLAUDE.md self-audit | **CONSISTENT** |
| 6 wiki types | (line 240) | line 240; line 469 ("6 wiki page type templates") | **CONSISTENT** |

### Citation accuracy spot-check (7 samples)

| # | Citation | Source verified | Verdict |
|---|---|---|---|
| 1 | Line 190 → phased-plan §8.2.4 + §10.5 (`diff_count = 0`) | phased-plan §10.5 contains literal `diff_count = 0`; §8.2.4 contains "verdicts must match" | VERIFIED |
| 2 | Line 323 → stage-3-locks.md §132 (SL-9), §144 (SL-10) | stage-3-locks.md L132 = `## SL-9 — Scalability scope`; L144 = `## SL-10 — Scale target` | VERIFIED |
| 3 | Line 240 → plan.md §3.4 (6 wiki types) | plan.md §3.4 at L201 enumerates 6 types | VERIFIED |
| 4 | Line 470 → phased-build-plan §A.2 (9-subdir layout) | phased-build-plan §A.2 at L803 contains 9-subdir layout | VERIFIED (v0.4.6 disambiguation fixed Pass 10 F-PASS10-O2) |
| 5 | Line 467 → llm-second-brain-plan.md §3.3 (7 topic categories) | plan.md §3.3 at L189 enumerates topic categories | VERIFIED |
| 6 | Line 690 Citation Conventions (3 plans) | All 3 plans exist at the cited paths | VERIFIED |
| 7 | Line 710 → elicitation-notes.md (created 2026-05-14, §1-§10 cited) | elicitation-notes.md exists; sections 1-10 verified earlier | VERIFIED (creation-date anchor; no line-count drift class) |

**7/7 verified. No citation defects in v0.4.6.**

### Frontmatter ↔ body coherence

All 26 `locked_decisions:` fields cross-checked against body sections in prior passes; v0.4.6 introduces no new frontmatter fields. Only self-audit attestation gap (F-PASS11-I1) and minor mis-attribution (F-PASS11-O2). No semantic coherence defects.

---

## Multi-Callsite Identifier Coherence Check (v0.4.6 specific)

| Identifier | Callsites | Verdict |
|---|---|---|
| `phased-build-plan §A.2` | lines 209, 283, 388, 470, 676 | **COHERENT** — all 5 body callsites disambiguated |
| `creation-date anchor` (Traceability) | line 710 (created 2026-05-14), line 714 (created 2026-05-15), line 718 (created 2026-05-14) | **COHERENT** — line-count drift class eliminated |
| Q#2 / Q#8 strikethrough pattern | lines 664 (Q#2), 676 (Q#8) | **COHERENT** — both use `~~...~~` + Resolved annotation |
| Q#12 open-dimension pattern | line 684 | **COHERENT** — distinct from Q#2/Q#8 (genuinely open) |
| v0.5 early-ship skills #18 + #22 | line 373 (Phase 2-3 polish skills header) | **COHERENT** — header explicitly names #18 and #22 as v0.5 ships |

---

## Convergence Assessment

The brief has **NOT** converged at v0.4.6.

The v0.4.6 fix-burst applied another excellent structural fix (Traceability creation-date anchors), matching the v0.4.5 grep-anchor discipline. **The structural-fix discipline is working as designed** — Pass 9 caught an L-number drift class; v0.4.5 eliminated it. Pass 10 caught a wc-l-vs-Read-tool drift class; v0.4.6 eliminated it. Each structural fix removes a defect class permanently rather than patching individual instances. This is excellent root-cause discipline.

**However**, the fix-burst itself introduced a new defect: **the Self-Audit Checklist is not refreshed with each fix-burst.** This was masked by prior passes because the L-number drift (F-PASS9-I1) was the more salient issue. Now that the L-numbers are gone, the per-version attestation gap is visible: v0.4.6 edits land but the checklist's per-version annotations terminate at v0.4.5.

The remaining defects are:
- **1 IMPORTANT (F-PASS11-I1)** — Self-Audit Checklist stale at v0.4.5; v0.4.6 edits not attested
- **1 SUGGESTION (F-PASS11-S1)** — v0.4.6 changelog count claim (4 callsites) off by one (actual: 5)
- **2 OBSERVATIONS (F-PASS11-O1, F-PASS11-O2)** — Open Questions preamble vs resolved entries; minor self-audit framing for top-level metadata fields

A v0.4.7 fix-burst addressing F-PASS11-I1 + F-PASS11-S1 should converge in a single pass. The structural fix for F-PASS11-I1 (option 2: collapse per-version annotations to a "see Changelog" reference) would eliminate this entire defect class — same root-cause discipline as v0.4.5 and v0.4.6 structural fixes.

**Process-gap candidate (not flagged as [process-gap]):** The Self-Audit Checklist has now exhibited "stale-after-fix-burst" pattern across at least 2 passes (Pass 9 L-numbers, Pass 11 per-version-attestation). The recurring pattern suggests the audit-trail's per-version-annotation format itself is fragile. Same family of defect as the line-count and L-number classes already addressed by structural fix. Not flagged `[process-gap]` because it is a brief-authoring discipline, not an engine-level concern; the proposed fix is local to this brief.

---

## Streak Decision

**Streak: stays at 0/3.**

1 IMPORTANT finding (F-PASS11-I1) is blocker-grade. Per protocol: ANY blocker findings → streak stays at 0/3, dispatch product-owner fix-burst.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 1-4 | FAIL (15/4/6/4 blockers) | 0/3 |
| Pass 5 | PASS | 1/3 |
| Pass 6 | PASS | 2/3 |
| Pass 7 | FAIL (1 IMPORTANT) | 0/3 (RESET) |
| Pass 8 | FAIL (2 IMPORTANT) | 0/3 |
| Pass 9 | FAIL (1 IMPORTANT) | 0/3 |
| Pass 10 | FAIL (1 IMPORTANT) | 0/3 |
| **Pass 11** | **FAIL (1 IMPORTANT)** | **0/3** |

---

## Novelty Assessment

**Novelty: MEDIUM.**

F-PASS11-I1 is a NEW defect class at the meta level: per-version-attestation drift in the Self-Audit Checklist. This was masked by F-PASS9-I1 (L-number drift, same checklist), so prior passes that focused on L-number staleness did not surface the underlying "checklist is not refreshed per version" issue. Once the L-numbers were eliminated by v0.4.5's structural fix, the underlying attestation-gap class became visible.

F-PASS11-S1 is a NEW defect class: changelog count-claim off by one. Same family as F-PASS10-I1 (false-attestation in changelog) but minor in impact because the sweep itself is structurally complete.

F-PASS11-O1 is a NEW finding: Open Questions section preamble contradicts the strikethrough-resolved convention. Has existed since v0.3.0 but was never previously surfaced because each prior pass focused on within-question consistency rather than preamble-vs-content coherence. Pass 11 fresh-context discipline exposed this.

F-PASS11-O2 is a NEW micro-finding on frontmatter taxonomy framing.

**Genuinely new ground: yes.**
- F-PASS11-I1: novel meta-finding (audit-trail-not-refreshed-per-fix-burst).
- F-PASS11-S1: changelog count-claim off-by-one (sub-class of false-attestation).
- F-PASS11-O1: section-preamble vs entry-state contradiction (latent since v0.3.0; surfaced via fresh-context).
- F-PASS11-O2: top-level-metadata vs locked-decisions taxonomy framing in self-audit.

**Compared to Pass 10:** Pass 10 found 1 IMPORTANT (F-PASS10-I1 false-attestation) + 1 SUGGESTION (F-PASS10-S1 Q2 sibling-sweep) + 2 OBSERVATIONS. All 4 are structurally fixed in v0.4.6 (with F-PASS11-S1 noting the changelog count-claim drift in the v0.4.6 disambiguation fix). The defect surface area has narrowed: Pass 10 had 4 actionable findings; Pass 11 has 4 findings of which only 1 is blocker-grade. The structural-fix trajectory is working — each pass eliminates a defect class permanently.

**The fresh-context different-model adversarial review pattern is working as designed.** Pass 11's independent fresh re-derivation of the Self-Audit Checklist's per-version attestation pattern, against the actual content of the latest changelog block, exposed a defect that an iterative reviewer carrying state from Pass 10 would have rolled past.

---

## Top 3 Findings

1. **F-PASS11-I1 [IMPORTANT]** — Self-Audit Checklist stale at v0.4.5; v0.4.6 edits not attested in lines 730, 737, or 739. The most recent fix-burst is unaudited by the brief's own self-audit. **Fix:** either append `v0.4.6:` annotations to each affected bullet, OR (structural) collapse per-version annotations to a single "see Changelog at top of brief" reference — eliminating the per-version-attestation drift class permanently.

2. **F-PASS11-S1 [SUGGESTION]** — v0.4.6 changelog at line 58 claims "Disambiguated 'plan §A.2' → 'phased-build-plan §A.2' at 4 callsites" but the actual count is 5 callsites (lines 209, 283, 388, 470, 676). The disambiguation sweep is structurally complete; only the changelog count-claim is off by one. **Fix:** update to "5 callsites" or drop the specific count.

3. **F-PASS11-O1 [OBSERVATION]** — Open Questions section preamble at line 660 says "These questions remain open" but Q#2 (line 664) and Q#8 (line 676) are explicitly Resolved with strikethrough. The strikethrough-retained-for-traceability convention is unstated. **Fix:** add a single sentence to the preamble explaining the convention, OR move resolved entries to a separate "Resolved Decisions" subsection.

---

## Recommended Next Action

1. **Dispatch product-owner** for a v0.4.7 fix-burst addressing:
   - **F-PASS11-I1 (BLOCKER):** Refresh Self-Audit Checklist with v0.4.6 attestations at lines 730, 737, 739. Recommended option: apply the same structural-fix discipline used in v0.4.5 (grep-anchors) and v0.4.6 (creation-date anchors) — replace per-version-appended annotations with a single "v0.4.X fix-burst details recorded in §Changelog block at top of brief" reference. This eliminates the per-version-attestation drift class permanently.
   - **F-PASS11-S1:** Update changelog line 58 from "4 callsites" to "5 callsites" (or drop the specific count).
   - **F-PASS11-O1 (OPTIONAL):** Add a single sentence to Open Questions preamble explaining the strikethrough convention.
   - **F-PASS11-O2 (OPTIONAL):** Minor self-audit framing adjustment for `stage_3_locks` (top-level field vs locked_decisions block).
2. After fix-burst lands as v0.4.7, dispatch Pass 12 with fresh context to continue the 3-CLEAN cascade attempt (streak 0/3).

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.6
pass_number: 11
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
important_finding_ids: [F-PASS11-I1]
suggestion_finding_ids: [F-PASS11-S1]
observation_finding_ids: [F-PASS11-O1, F-PASS11-O2]
process_gap_finding_ids: []
paper_fix_pattern_observed: false
v0_4_6_body_fixes_structurally_verified: 4
v0_4_6_changelog_attestation_off_by_one: 1
v0_4_6_self_audit_attestation_missing: 1
pass_10_fixes_still_holding: 4
pass_9_fixes_still_holding: 1
pass_8_fixes_still_holding: 2
pass_7_fixes_still_holding: 1
new_findings_classification: per-version-attestation-drift-in-self-audit-checklist (meta-level) + changelog-count-claim-off-by-one (sub-class of false-attestation) + section-preamble-vs-entry-state-contradiction (latent since v0.3.0) + frontmatter-taxonomy-framing
cascade_convergence_assessment: structurally-near-converged-with-one-blocker; v0.4.7 fix-burst should converge in single pass; structural-fix trajectory (v0.4.5 grep-anchors -> v0.4.6 creation-date-anchors -> v0.4.7 collapse-per-version-attestations) is the durable resolution path
structural_fix_evaluation: v0.4.6 creation-date-anchor structural fix is sound and durable; eliminated the wc-l-vs-Read-tool drift class permanently; introduced no new in-Traceability defects
recommended_next_action: dispatch product-owner v0.4.7 fix-burst addressing F-PASS11-I1 (Self-Audit Checklist per-version-attestation refresh; apply collapse-to-Changelog-reference structural fix), F-PASS11-S1 (changelog count-claim correction); then dispatch Pass 12
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/elicitation-notes.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/brief-research.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/reference-repos.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plugin-plan.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-8.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-9.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-10.md
```
