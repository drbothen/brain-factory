---
artifact_type: adversary-pass-report
pass_number: 8
cascade: brain-factory-product-brief-v0.4.3
target_file: .factory/specs/product-brief.md
target_version: 0.4.3
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (Pass 8 FAIL)
created: 2026-05-15
author: vsdd-factory:adversary
inputs:
  - .factory/specs/product-brief.md (v0.4.3, 711 lines)
  - .factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1..7}.md
  - .factory/planning/stage-3-locks.md
  - .factory/planning/reference-repos.md
  - .factory/planning/elicitation-notes.md
  - .factory/planning/brief-research.md
  - CLAUDE.md
  - docs/planning/llm-second-brain-{plan,phased-build-plan,plugin-plan}.md
finding_count_critical: 0
finding_count_important: 2
finding_count_suggestion: 4
finding_count_observation: 2
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: false
pass_7_fixes_verified: 5 (all)
pass_8_new_findings: 6 (2 IMPORTANT, 4 SUGGESTION)
---

# Adversarial Review — Pass 8

## Verdict

**FAIL.** 2 IMPORTANT structural findings (1 new contradiction, 1 new runtime-prerequisite gap), plus 4 SUGGESTION-grade citation/scope drifts and 2 observations. Pass 7's F-PASS7-I1 sibling-sweep fix is genuinely resolved across all three callsites (L194, L319, L582). Pass 7's S1-S4 suggestion fixes are all genuinely resolved (stage_3_locks frontmatter + Traceability subsection; self-audit line numbers refreshed; reverse-chronological changelog; §10.5 corrected for diff_count origin).

**However**, fresh-context surfaced two new defects 7 prior passes missed:

1. **F-PASS8-I1** — `/brain:research` is simultaneously asserted as a v0.1 ship-gate-tested item (L261) AND a Phase 2-3 skill that "ships by v0.9" (L364, item 26).
2. **F-PASS8-I2** — `/brain:research` requires "Perplexity MCP" runtime (L261, L365) but neither §Target Users prerequisites (L143) nor §Constraints toolchain (L485) lists Perplexity MCP as an operator dependency.

**Streak: stays at 0/3.** Dispatch product-owner for v0.4.4 fix-burst.

---

## Critical Findings

(none)

## Important Findings

### F-PASS8-I1 [IMPORTANT] — `/brain:research` v0.1 ship-gate vs v0.9 categorization contradiction

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L261 (v0.1 ship gate) vs L364-365 (Scope §26 skill)
- **Confidence:** HIGH
- **Severity:** IMPORTANT (P1)

**Evidence:**

L261 (v0.1 ship gate, under "### v0.1 ship gate (Phase 1 + Phase 2 exit)"):

> `/brain:research` successfully dispatches the `brain:researcher` specialist with Perplexity MCP and web search access, synthesizes findings on a sample topic, and outputs to both `wiki/` pages and `briefs/research/<topic>-research.md`.

L364-365 (Scope §26 skills):

> Phase 2–3 new skill (1 — ships by v0.9):
> 26. `/brain:research <topic>` — dispatches `brain:researcher` specialist…

L255 (v0.1 ship gate immediately above L261):

> **All 13** skills present as `SKILL.md` files (the Phase 0/1 primitives — exact match, not minimum).

The brief asserts at L255 that exactly 13 primitives ship at v0.1, enumerated at L336-348. `/brain:research` is NOT in the 13 primitives — it's item 26, explicitly labeled "Phase 2-3 new skill (ships by v0.9)" at L364. Yet the v0.1 ship gate at L261 includes a `/brain:research`-dispatches-successfully test, which cannot be satisfied if `/brain:research` is not implemented until v0.9.

**Why IMPORTANT:**

1. This is a real internal contradiction between two commitment-grade gate-item statements. An implementer cannot satisfy both L255 ("All 13 primitives — exact match, not minimum") AND L261 (`/brain:research` works at v0.1) without expanding the primitives to 14 (which contradicts L255's "exact match").
2. **3 passes (5/6/7) all converged on the consistency of skills enumeration but didn't cross-check v0.1 gate items against skill-list timing.** Same class as Pass 7 F-PASS7-I1: a fact stated correctly in one section, contradicted in an adjacent section.
3. Forward-impact: Phase 1 implementer cannot determine whether `/brain:research` is in-scope for v0.1.0 tag.

**Fix options:**
1. Remove L261 entirely (`/brain:research` becomes a v0.9-only gate item, not v0.1).
2. OR move `/brain:research` to the Phase 0/1 primitives list (rename "13 → 14 primitives," sibling-sweep all callsites of "13 skills" / "All 13 skills" at L91, L255, L335).
3. OR clarify L261 to test `briefs/research/` directory scaffolding only (the `/brain:init` extension), removing the runtime-dispatch claim.

Option 1 is most consistent with the rest of the brief.

---

### F-PASS8-I2 [IMPORTANT] — `/brain:research` Perplexity MCP runtime prerequisite undocumented in §Target Users or §Constraints

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L261, L365 (require Perplexity MCP) vs L143, L485 (operator prerequisites omit it)
- **Confidence:** HIGH
- **Severity:** IMPORTANT (P1)

**Evidence:**

L261: "/brain:research successfully dispatches the brain:researcher specialist with **Perplexity MCP and web search access**…"
L365: "/brain:research <topic> — dispatches brain:researcher specialist with **Perplexity MCP and web search access**…"

L143 (Target Users §Phase 3+ general operators): "Requires: Claude Code installed, ANTHROPIC_API_KEY, git and GitHub, Node 20+ for Defuddle CLI and scripts/run-skill.mjs."

L485 (Constraints §Technical, Toolchain prerequisites): "bash 4+, jq, yq, awk, bats, shellcheck, shfmt, Node 20+. Node 20+ is required for Defuddle CLI…"

Stage 3 lock SL-5 (`.factory/planning/stage-3-locks.md` §84-93) authorizes /brain:research as the 26th skill but does NOT mention Perplexity MCP as a prerequisite.

**Why IMPORTANT:**

1. v0.9 operators expecting `/brain:research` to work out-of-box will hit a runtime failure if they haven't configured Perplexity MCP. This is exactly the "v0.x is pure bash + jq + yq + awk + Node 20+" claim being silently violated.
2. The Non-Users section (L149-156) doesn't exclude "operators without Perplexity MCP configured" — so they're implicitly admitted as supported users.
3. Perplexity is a paid service. Adding it as a prerequisite has business-model implications absent from §Constraints.

**Fix options:**
1. Add Perplexity MCP to operator prerequisites at L143 and toolchain at L485, with a note that it's required for `/brain:research`.
2. OR explicitly make Perplexity MCP optional and degrade `/brain:research` to web-search-only mode when MCP is absent.
3. OR add an Open Question for "lock Perplexity MCP requirement before v0.9."

Option 2 is most aligned with the brief's "fully self-contained at runtime" claim for brain-factory (L371).

---

## Suggestions

### F-PASS8-S1 [SUGGESTION] — Sibling-sweep miss: L678 says "preserved through v0.4.2" but v0.4.3 also preserves this state

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L678 (Traceability §Sibling references thought-leadership row)
- **Confidence:** HIGH

**Evidence:**

L678: "…v0.2.0+ brief demotes Medium to reference extension (deprecated API, **preserved through v0.4.2**) and commits LinkedIn as the sole core v0.x platform…"

The phrase "preserved through v0.4.2" implies that the Medium-demotion state held through v0.4.2 but the reader cannot tell from this prose whether it's still preserved at v0.4.3. In fact, v0.4.3 also preserves this state — the changelog at L54-59 makes no mention of Medium being re-promoted. This is the exact same staleness pattern v0.4.2 swept ("v0.3.1" → "v0.4.2" per L66's changelog entry).

**Fix:**
- Change "preserved through v0.4.2" → "preserved through v0.4.3" (sibling-sweep continuation).
- OR change to version-agnostic phrasing: "demotes Medium to reference extension (deprecated API, current-version-preserved)" to avoid recurring staleness on every release.

---

### F-PASS8-S2 [SUGGESTION] — Artifact line-count citations drift across three Traceability entries

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L682 (elicitation-notes.md "610-line"), L686 (stage-3-locks.md "171-line"), L690 (brief-research.md "378-line")
- **Confidence:** HIGH

**Evidence (file vs claim):**

| Artifact | Brief claim | Actual line count |
|---|---|---|
| elicitation-notes.md | "610-line" (L682) | 611 lines |
| stage-3-locks.md | "171-line" (L686) | 172 lines |
| brief-research.md | "378-line" (L690) | 496 lines |

The brief-research.md drift is significant: 378 → 496 is a 31% undercount. This claim was carried through v0.4.0+ and never re-verified.

**Why this matters:**

Citation-precision is a brief discipline. Approximate line counts that disagree with reality erode reader trust in other numeric claims. This is the same class of drift as Pass 6/7's "§8.3 → §10.5" `diff_count = 0` literal — citation to a specific section/length should be re-verified when the underlying artifact grows.

**Fix:**
- Update L682 "610-line" → "611-line".
- Update L686 "171-line" → "172-line".
- Update L690 "378-line" → "496-line".
- OR remove specific line counts and replace with version anchors (e.g., "elicitation-notes.md created 2026-05-14") to avoid drift.

---

### F-PASS8-S3 [SUGGESTION] — `validate-publish-state.sh` scope at L410 is vague compared to other 12 hooks

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L410
- **Confidence:** HIGH

**Evidence:**

L410: "`validate-publish-state.sh` (PostToolUse, Write|Edit on **content publishing artifacts** — enforces draft → ready → published frontmatter state machine)"

Compare to the 12 other hooks at L396-407, which use precise glob scopes:
- L400: `Write|Edit on sources/*`
- L401: `Write|Edit on wiki/*`
- L402: `Write|Edit on wiki/index or log.md`
- L403: `Write|Edit on wiki/* or sources/*`
- L404: `Write|Edit on wiki/*`
- L405: `Write|Edit on briefs/content/*-draft.md`
- L406: `Write|Edit on wiki/*`

"Content publishing artifacts" is the only fuzzy scope in the 13-hook list. From L187's wclaude absorption, this means `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` — but the brief doesn't make this explicit at L410. An implementer would have to cross-reference to L187 to derive the matcher glob.

**Fix:**
- Change L410 scope to explicit glob: `Write|Edit on drafts/*|to-publish/*|published/*` (or whatever the precise glob is per the wclaude pattern).

---

### F-PASS8-S4 [SUGGESTION] — Folder-structure extension `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` not flagged as brief-introduced extension

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L187 (introduces extension), L365 (compare: `briefs/research/` flagged as extension)
- **Confidence:** MEDIUM

**Evidence:**

Plan §A.2 (`docs/planning/llm-second-brain-phased-build-plan.md` L803-821) enumerates the target folder structure with `published/` (single, no platform subdirs). The brief at L187 introduces `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` as wclaude-absorbed directory structure — three extensions beyond plan §A.2 baseline.

By contrast, the brief at L261 and L365 explicitly flags `briefs/research/` as "a brief-introduced extension beyond plan §A.2's five enumerated `briefs/` subdirs."

Inconsistency: similar brief-extensions to the target folder structure are sometimes flagged, sometimes not.

**Fix:**
- Add a parenthetical at L187 noting that `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` extend plan §A.2's `published/` baseline as brief-introduced wclaude-absorbed directory structure.
- OR at L194 (Family Positioning summary), add a single line documenting the folder-structure extensions adopted alongside the hook count adjustment.

---

## Observations

### F-PASS8-O1 [OBSERVATION] — Writescore threshold value undefined; not in §Open Questions

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L184 ("score threshold baked into `/brain:adversary-review`")
- **Confidence:** MEDIUM

L184 commits to "multi-pass revision with score threshold baked into /brain:adversary-review" but does not specify the threshold value. The §Open Questions section (L634-658) does not list this as deferred. Question: at what writescore does the multi-pass loop terminate? This is an implementer-blocking detail that should either be locked in the brief or flagged as an Open Question.

This is OBSERVATION-grade rather than SUGGESTION because the implementer can interpret "score threshold" as a configurable policy via `.brain/policies.yaml`, but the brief doesn't say so. If the threshold is operator-configurable, the brief should say so.

---

### F-PASS8-O2 [OBSERVATION] — "Adversary PASS" criterion undefined for L262 v0.1 ship-gate item

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L262
- **Confidence:** LOW

L262: "Adversary PASS on a sample brief produced by `/brain:brief`."

What is the precise criterion that defines "PASS"? An exit code? A score threshold? A "no CRITICAL findings" verdict? The brief defines adversary review (§Core differentiator #2) but does not specify the binary PASS/FAIL criterion.

This is LOW-confidence because operationally "PASS" in an adversary-review context typically means "no blocker findings" — a defensible default. But it's underspecified for a ship-gate test.

---

## Novelty Assessment

**Novelty: MEDIUM-HIGH.** Two new IMPORTANT findings (F-PASS8-I1, F-PASS8-I2) that 7 prior adversarial passes missed. Both relate to `/brain:research` — the v0.9 skill added in v0.3.0 (per L367 brief prompt). The Pass 7 lesson ("rigorous sibling-sweep on counts adjusted-from-plan-to-brief") applied cleanly to F-PASS7-I1, but did NOT extend to checking that a brief-introduced skill is consistently timed across the brief's own gate items.

Four SUGGESTION-grade findings (line-count drifts, stale version tag, vague scope, unflagged extension). These are propagation-discipline misses, not structural defects.

Two OBSERVATION-grade items (writescore threshold, adversary PASS criterion).

The fresh-context adversarial review pattern is functioning as designed. Pass 8 found 2 IMPORTANT defects from a baseline of 7 prior independent reviews. The streak reset to 0/3 after Pass 7 was correct — these defects existed at v0.4.2 and v0.4.3 alike.

---

## Pass 7 Fix Verification

| Pass 7 finding | v0.4.3 fix | Verification |
|---|---|---|
| F-PASS7-I1 (12 → 13 sibling-sweep at L186/L311/L574) | Applied at L194, L319, L582 | **VERIFIED.** All three callsites now say "13-hook" with adjustment parenthetical matching v0.1/v0.9 gate pattern. |
| F-PASS7-S1 (stage-3-locks.md in frontmatter + Traceability) | Added `stage_3_locks` at L20; Traceability subsection at L684-686 | **VERIFIED.** |
| F-PASS7-S2 (stale self-audit line numbers) | Self-audit L709 updated to "L272, L596, L608" for `gh auth login`; "L164 and L535" for "publicly-documented" | **VERIFIED.** Grep-confirmed L272 has authenticated-gh content; L596, L608 have pre-transition disclaimers; L164, L535 contain "publicly-documented." |
| F-PASS7-S3 (changelog order) | Reordered reverse-chronological: v0.4.3 → v0.4.2 → v0.4.1 → v0.4.0 at L54/L61/L68/L78 | **VERIFIED.** |
| F-PASS7-S4 (§8.3 → §10.5) | L168 cites "§10.5 (where the literal pass-criterion `diff_count = 0` appears)" | **VERIFIED.** Phased plan §10.5 L711 contains literal `diff_count = 0`. |

**All Pass 7 fixes verified resolved.** No regression introduced by the v0.4.3 fix-burst (no over-correction observed). The new adjustment parentheticals at L194 and L582 are accurate (§8.3 is the right citation for the 12-hook baseline reference, since §8.3 L638 enumerates "All 12 WASM hooks").

---

## Count Adjustment Sibling-Sweep Audit (per Pass 8 stress-test)

| Adjustment | Plan-doc baseline | Brief value | Callsites verified |
|---|---|---|---|
| 12 → 13 hooks | §A.4 (12), §5.11 (12), §7.5 (12), §8.3 (12) | 13 (frontmatter, Vision, all 4 gates, all 3 prose mentions) | **CONSISTENT** — L194, L254, L260, L286, L319, L395-410, L582; adjustment parentheticals present; "12" appears only in plan-doc-list context |
| 6 → 19 GH Actions | plan §8.1-§8.18 (6+9+4 enumeration) | 19 (6+9+4 split) | **CONSISTENT** — L30-32, L91, L277, L414-441 |
| 25 → 26 skills | plugin plan §5 ("25 skills") | 26 (25 + /brain:research) | **CONSISTENT** — L27, L91, L287, L333, L669 (plan-doc-original) |
| 10 → 14 agents | plugin plan §6 ("10 agents") | 14 (10 + 4 wclaude) | **CONSISTENT** — L28, L91, L183, L369-389, L566, L669 (plan-doc-original) |

No count-adjustment sibling-sweep defects. The Pass 7 lesson has been applied cleanly.

---

## Streak Decision

**Streak: stays at 0/3.**

2 IMPORTANT findings (F-PASS8-I1, F-PASS8-I2) are blocker-grade. Per the protocol, ANY blocker findings → streak stays at 0/3, dispatch product-owner fix-burst.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 1 | FAIL (15 blockers) | 0/3 |
| Pass 2 | FAIL (4 blockers) | 0/3 |
| Pass 3 | FAIL (6 blockers) | 0/3 |
| Pass 4 | FAIL (4 blockers) | 0/3 |
| Pass 5 | PASS (0 blockers) | 1/3 |
| Pass 6 | PASS (0 blockers) | 2/3 |
| Pass 7 | FAIL (1 IMPORTANT) | 0/3 (RESET) |
| **Pass 8** | **FAIL (2 IMPORTANT)** | **0/3** |

---

## Top 3 Findings

1. **F-PASS8-I1 [IMPORTANT]** — `/brain:research` is asserted as a v0.1 ship-gate-tested item (L261) AND as a Phase 2-3 v0.9-shipped skill (L364). One must be wrong. Fix: remove L261 v0.1 gate item or move /brain:research to v0.1 primitives (with 13 → 14 sibling-sweep).

2. **F-PASS8-I2 [IMPORTANT]** — `/brain:research` requires "Perplexity MCP" at L261, L365 but Perplexity MCP is absent from §Target Users prerequisites (L143) and §Constraints toolchain (L485). Fix: add Perplexity MCP to operator prerequisites, OR make MCP optional and degrade to web-search-only when absent, OR add as Open Question.

3. **F-PASS8-S2 [SUGGESTION]** — Three Traceability artifact line-count citations are drifted: elicitation-notes.md claimed "610-line" (actual 611), stage-3-locks.md claimed "171-line" (actual 172), brief-research.md claimed "378-line" (actual 496 — 31% undercount). Fix: update line-counts or replace with version-anchor framing.

---

## Recommended Next Action

1. **Dispatch product-owner** for a v0.4.4 fix-burst addressing:
   - **F-PASS8-I1 (BLOCKER):** Reconcile `/brain:research` timing. Recommended: remove the v0.1 ship-gate item at L261 entirely (replace with a v0.9 gate item under "### v0.9 ship gate"). The `briefs/research/` directory scaffolding at v0.1 (per L261's parenthetical) is independent of the skill's runtime availability and can remain as a v0.1 init-skill scaffold commitment.
   - **F-PASS8-I2 (BLOCKER):** Document Perplexity MCP requirement. Recommended option: make Perplexity MCP optional in the brief's primary commitment (web-search-only mode fallback) and lock the MCP-promotion criterion as a new Open Question item before v0.9 milestone.
   - **F-PASS8-S1:** Sibling-sweep L678 "preserved through v0.4.2" → "preserved through v0.4.4" OR version-agnostic phrasing.
   - **F-PASS8-S2:** Refresh artifact line counts at L682, L686, L690.
   - **F-PASS8-S3:** Specify validate-publish-state.sh glob scope at L410 explicitly.
   - **F-PASS8-S4:** Flag the `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` extensions to plan §A.2 at L187 (or L194).
2. After fix-burst lands as v0.4.4, dispatch Pass 9 with fresh context.

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.3
pass_number: 8
finding_counts:
  critical: 0
  important: 2
  suggestion: 4
  observation: 2
  process_gap: 0
  total_blocking: 2
verdict: FAIL
streak_before: 0/3
streak_after: 0/3
recommended_next_action: dispatch product-owner v0.4.4 fix-burst addressing F-PASS8-I1 (research-skill v0.1-vs-v0.9 contradiction), F-PASS8-I2 (Perplexity MCP undocumented prerequisite), plus 4 suggestion-grade refinements; then dispatch Pass 9 to begin a new 3-CLEAN cascade
critical_finding_ids: []
important_finding_ids: [F-PASS8-I1, F-PASS8-I2]
suggestion_finding_ids: [F-PASS8-S1, F-PASS8-S2, F-PASS8-S3, F-PASS8-S4]
observation_finding_ids: [F-PASS8-O1, F-PASS8-O2]
process_gap_finding_ids: []
paper_fix_pattern_observed: false
pass_7_fixes_verified: 5 (all)
pass_8_new_findings: 6 (2 IMPORTANT, 4 SUGGESTION)
pass_8_corroborations_from_prior: 0 (all prior findings genuinely resolved)
cascade_convergence_assessment: structurally-converged-on-count-discipline; two-new-defects-on-research-skill-internal-timing; one-pass fix-burst-should-converge
new_findings_classification: research-skill-internal-contradiction (v0.1 gate vs v0.9 categorization) + runtime-prerequisite-gap (Perplexity MCP not in §Target Users prerequisites) + minor-citation-drift (artifact line-counts, stale version tag, vague hook scope, unflagged folder extension)
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/elicitation-notes.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/brief-research.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/reference-repos.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plugin-plan.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-7.md
```
