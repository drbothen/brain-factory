---
artifact_type: adversary-pass-report
pass_number: 17
cascade: brain-factory-product-brief-v0.4.11
target_file: .factory/specs/product-brief.md
target_version: 0.4.11
target_lines: 771
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (HOLD)
created: 2026-05-15
author: vsdd-factory:adversary
finding_count_critical: 0
finding_count_important: 1
finding_count_suggestion: 2
finding_count_observation: 2
finding_count_process_gap: 1
verdict: FAIL
paper_fix_pattern_observed: true
structural_fixes_holding: 7
prior_pass_fixes_holding: 18
prior_pass_fixes_regressed: 0
adversary_tool_profile_note: read-only (Read/Grep/Glob); report persisted by orchestrator via state-manager
---

# Adversarial Review — Pass 17

**Target file:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.11, 771 lines)
**Cascade:** BC-5.39.001 3-CLEAN convergence; brain-factory product brief
**Streak before:** 0/3
**Verdict:** **FAIL** (1 IMPORTANT, 2 SUGGESTION, 2 OBSERVATION; 1 process-gap tag overlapping I1)

---

## Section A — v0.4.11 fix verification

| Pass 16 finding | v0.4.11 claim | Verification method | Verdict |
|---|---|---|---|
| F-PASS16-I1 (`plan §A.4` → `phased-build-plan.md §A.4` at §6 Commitment) | Fixed at L286 (Scalability §6 Commitment) | Read L286 + Grep `phased-build-plan.md §A.4` in body; confirmed L286 reads "`wiki/*` and `sources/*` per phased-build-plan.md §A.4" | **VERIFIED** |
| F-PASS16-I2 (`Plugin plan §3.15` → `plugin-plan.md §3.15` at §Out-of-scope) | Fixed at L531 | Read L531 + Grep `plugin-plan.md §3.15` in body; confirmed L531 reads "plugin-plan.md §3.15 marks it OPTIONAL advanced" | **VERIFIED** |
| F-PASS16-I3 (ordinal cascade count → semantic label) | Fixed at L63 (v0.4.10 STRUCTURAL FIX heading) | Read L63; confirmed v0.4.10 heading reads "**STRUCTURAL FIX (Changelog audit-trail discipline):**" | **VERIFIED**; **but see F-PASS17-I1** for overreach in coverage claim |
| F-PASS16-S1 (frontmatter `cross_platform`) | Updated at L42 | Read L42; confirmed Git Bash now present | **VERIFIED** |
| F-PASS16-O1 (`plugin.json` + `hooks.json.template` in §Scope) | Added at L508, L509 | Grep confirmed both in §Scope deliverables AND gate rows | **VERIFIED** |

All five Pass 16 blocking-or-bundled fixes verified at line level. **paper_fix_pattern_observed: true** for F-PASS17-I1 (separate from these five).

## Section B — Structural-Fix Cascade Verification (7 disciplines)

| # | Discipline | Grep test | Result |
|---|---|---|---|
| 1 | v0.4.5 (L-numbers → grep-anchors) | `\bL[0-9]+\b` body | 0 matches | **PASS** |
| 2 | v0.4.6 (line-counts → creation-date anchors) | `\b[0-9]{3}-line\b` | 0 matches | **PASS** |
| 3 | v0.4.7 (per-version annotations) | `v0\.[34]\.\d+:` in Self-Audit | 0 matches | **PASS** |
| 4 | v0.4.8 (citation shorthand) | `(phased plan §\|plugin plan §)` body | only L74 (changelog historical record) | **PASS** |
| 5 | v0.4.8 (§Changelog notation) | `§Changelog` in body | only L75 (changelog historical record) | **PASS** |
| 6 | v0.4.10 (Changelog audit-trail discipline) | line-number citations in active Changelog entries | 0 active | **PASS** |
| 7a | v0.4.11 (semantic-label body callsites) | stale shorthand body callsites outside Changelog | 0 | **PASS** |
| 7b | v0.4.11 (Plugin/Phased plan body callsites outside Changelog) | 0 | **PASS** |
| 7c | v0.4.11 (semantic-label in Changelog STRUCTURAL FIX headings) | 6 hits, all descriptive parentheticals | **PASS** for entries that HAVE the heading; see F-PASS17-I1 for missing headings |

All seven discipline grep-tests PASS. F-PASS17-I1 reports a separate completeness gap.

## Section C — Pass 5–16 regression check

**18 prior-pass fixes preserved (Pass 7 through Pass 16); 0 regressed.** Full table in committed report below.

| Earlier finding | v0.4.11 status |
|---|---|
| Pass 7 F-PASS7-I1 (12→13 hook sibling-sweep) | STILL CORRECT |
| Pass 8 F-PASS8-I1, F-PASS8-I2 | STILL CORRECT |
| Pass 9 F-PASS9-I1 | STRUCTURALLY VERIFIED |
| Pass 10 F-PASS10-I1, F-PASS10-O2 | STRUCTURALLY/STILL VERIFIED |
| Pass 11 F-PASS11-I1 | STRUCTURALLY VERIFIED |
| Pass 12 F-PASS12-O1, F-PASS12-O2 | STILL CORRECT |
| Pass 13 F-PASS13-I1, F-PASS13-I2, F-PASS13-O1 | STILL CORRECT |
| Pass 14 F-PASS14-I1, F-PASS14-I2, F-PASS14-S1, F-PASS14-O1 | STILL CORRECT |
| Pass 15 F-PASS15-I1, F-PASS15-S1, F-PASS15-S2 | STILL CORRECT |
| Pass 16 F-PASS16-I1, F-PASS16-I2, F-PASS16-I3, F-PASS16-S1, F-PASS16-O1 | STILL CORRECT (all 5 verified Section A) |

## Section D — Standard cumulative checks

### Enumerated counts (11)

All 11 counts CONSISTENT across frontmatter ↔ body ↔ source-of-truth: 26 skills, 14 agents, 13 hooks, 19 GH Actions total (15 author-committed + 4 community-optional), 9 bats suites, 8 wclaude absorptions, 7 reference repos, 10 baseline policies, 6 wiki types.

### §Scope §Additional v0.x deliverables: gate-vs-scope symmetry audit

| Artifact in any gate | Present in §Additional v0.x deliverables? |
|---|---|
| `plugin.json` (v0.1 L303) | YES (L508) |
| `hooks.json.template` (v0.1 L306, v1.0 L372) | YES (L509) |
| Per-platform hooks.json variants | YES (L510) |
| `scripts/run-skill.mjs` | YES (L511) |
| `scripts/defuddle-fetch.mjs` | YES (L512) |
| `scripts/gen-test-corpus.sh` (v0.9 L362) | YES (L513) |
| LICENSE | YES (L514) |
| `.brain/STATE.md` | YES (L515) |
| `bin/lobster-run` | YES (L494) |
| `plugins/brain-factory/tests/local-dev-test.sh` | YES (L503) |
| `.reference/MANIFEST.md` + README.md | Documented in §Reference Repositories L664 (acceptable; lives in that section) |
| `policies.yaml` template (10 baseline policies) | YES (L497) |

**§Scope §Additional v0.x deliverables is symmetric with gate-referenced artifacts.** F-PASS16-O1 fix closed the asymmetry. No new gate-vs-scope drift instance.

### Citation accuracy spot-check (7 NEW samples)

| # | Citation | Source | Status |
|---|---|---|---|
| 1 | L498 → plan.md §3.3 (7 starter categories) | plan.md L189–L199 confirms 7 categories | VERIFIED |
| 2 | L286 → phased-build-plan.md §A.4 | phased-build-plan §A.4 L913 confirms hook contract | VERIFIED |
| 3 | L531 → plugin-plan.md §3.15 | plugin-plan.md L217 confirms "### 3.15 Worktree-Mounted State (Optional Advanced)" | VERIFIED |
| 4 | L218 → phased-build-plan.md §8.2.4 + §10.5 | L621 + L707 confirmed | VERIFIED |
| 5 | L308 → phased-build-plan.md §5.10, §6.5 | §5.10 exists | VERIFIED |
| 6 | L500 → phased-build-plan.md §A.10 | §A.10 L1337 confirmed | VERIFIED |
| 7 | L302 → phased-build-plan.md §5.11 | §5.11 L386 confirmed | VERIFIED |

7/7 citations VERIFIED. No new citation-accuracy defects.

---

## Critical Findings

(none)

---

## Important Findings

### F-PASS17-I1 [IMPORTANT, process-gap] — v0.4.11 changelog claim "All structural-fix headings in the Changelog now use semantic labels" is overbroad: two v0.4.8 changelog bullets lack STRUCTURAL FIX headings entirely

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L57 (overbroad claim); L74–L75 (v0.4.8 changelog block — missing STRUCTURAL FIX headings)
- **Confidence:** HIGH

**Evidence:**

L57 (v0.4.11 changelog) reads: "All structural-fix headings in the Changelog now use semantic labels rather than ordinal counts (F-PASS16-I3)."

The v0.4.8 changelog block (L71–L75) contains four bullets:
- L72: Phase 3 Timeline reconciliation (content fix)
- L73: .reference/README.md addition (content fix)
- L74: **Sibling-swept "phased plan §X" → "phased-build-plan §X"** (structural-discipline work — citation-shorthand drift class eliminated)
- L75: **Removed § notation from "Changelog" trailers** (structural-discipline work — §Changelog notation drift class eliminated)

L74 and L75 are documented in SESSION-HANDOFF.md §5 as the v0.4.8 row of the structural-fix table — but they DO NOT use the `**STRUCTURAL FIX (...):**` heading format in the brief Changelog.

This means the v0.4.11 claim "all structural-fix headings now use semantic labels" is technically true for headings that exist, but FALSE for completeness — two structural fixes exist in the brief without STRUCTURAL FIX headings at all.

**Why IMPORTANT (not OBSERVATION):**

The v0.4.11 fix-burst commits to a COMPREHENSIVE coverage claim ("all structural-fix headings"). Per the Canonical Principle's production-grade default, claiming completeness that isn't complete is a paper-fix smell (TD-VSDD-059). The fix renamed the v0.4.10 entry but didn't back-fill the v0.4.8 STRUCTURAL FIX headings the cascade record requires.

Severity per S-7.01 Partial-Fix Regression Discipline: blast radius = 1 file with 2 missing labels. Combined with cross-document coherence gap (handoff §5 + brief Changelog disagree on whether v0.4.8 is structural-fix), this is HIGH-severity → IMPORTANT.

**Why this is fresh-context-novel:**

Pass 16 caught the v0.4.10 ordinal mis-count (`(4th in cascade)`). The recommended fix was semantic-label replacement — which v0.4.11 applied NARROWLY to that single entry. Pass 17 re-derives the full cascade enumeration and discovers two structural fixes the brief never explicitly labels. The recurrence pattern (Pass 16 found "at all callsites" was incomplete; Pass 17 finds "all headings" is incomplete) demonstrates the audit-trail-vocabulary-drift defect class needs a structural counter.

**Tag: [process-gap]** — There is no machine-greppable verification of "every structural-fix changelog bullet uses the STRUCTURAL FIX heading format." Absent this enforcement, audit-trail vocabulary keeps drifting.

**Fix options:**

1. **Promote both v0.4.8 bullets to STRUCTURAL FIX headings (RECOMMENDED, production-grade):**
   - L74 → `**STRUCTURAL FIX (Citation shorthand sibling-sweep — historical, partial):** ...`. NOTE: include caveat that this sibling-sweep was incomplete; F-PASS16-I1/I2 surfaced 2 residual callsites that v0.4.11 closed with grep-verification.
   - L75 → `**STRUCTURAL FIX (§Changelog notation cleanup):** ...`
   - Amend L57 to reflect the back-fill is complete.

2. **Narrow the L57 claim** (paper-fix; weaker): Change "All structural-fix headings in the Changelog now use semantic labels" → "All ordinal-counted structural-fix headings have been replaced with semantic labels".

3. **Reconcile SESSION-HANDOFF.md §5 with brief Changelog** (orthogonal but related; covered by F-PASS17-O1).

Option 1 is the production-grade fix.

---

## Suggestions

### F-PASS17-S1 [SUGGESTION] — L351 uses `§132` and `§144` as line-number anchors for stage-3-locks.md, violating both the brief's Citation Conventions block and the v0.4.5 L-number → grep-anchor structural discipline

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Line:** 351
- **Confidence:** HIGH

**Evidence:**

L351 reads: "...recorded in `.factory/planning/stage-3-locks.md` (Stage 3 locks artifact created 2026-05-15; SL-9 at §132, SL-10 at §144):"

stage-3-locks.md uses H2 headings (`## SL-9 — Scalability scope...`, `## SL-10 — Scale target...`). The actual line numbers are L132 and L144. The brief uses §-notation for these LINE references — but the brief's Citation Conventions block at L722 explicitly establishes § as SECTION marker, not line marker.

Three compounding issues:
1. **Convention violation:** § = section per the brief's own convention. `§132` for line 132 violates this.
2. **Brittle anchor:** Line numbers drift when files are edited; SL-N IDs are stable.
3. **Structural-fix discipline violation:** v0.4.5 STRUCTURAL FIX eliminated L-number references from §Self-Audit. The §-prefix here masks the same defect-class behind a notation that looks structural.

**Why SUGGESTION:**

Targets are unambiguous — SL-9/SL-10 named in same sentence. Reader can find them. But it IS a structural-discipline regression that should be cleaned up.

**Fix options:**

1. **(Recommended)** "(Stage 3 locks artifact created 2026-05-15; see §SL-9 and §SL-10):"
2. "(Stage 3 locks artifact created 2026-05-15; SL-9 'Scalability scope' and SL-10 'Scale target'):"

### F-PASS17-S2 [SUGGESTION] — Frontmatter `cross_platform` has nested-parenthetical structure that hurts machine-parseability

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Line:** 42
- **Confidence:** MEDIUM

**Evidence:**

L42: `cross_platform: macOS + Linux + (Windows via Git Bash or WSL2) (native Windows = v1.0)`

Two adjacent parentheticals in a single YAML string. Acceptable as narrative; harder to parse.

**Fix options:**

1. **(Recommended)** Flatten: `cross_platform: macOS + Linux + Git-Bash + WSL2 (native Windows = v1.0)`
2. Convert to YAML structured value (more invasive).

---

## Observations

### F-PASS17-O1 [OBSERVATION] — SESSION-HANDOFF.md §5 enumerates 6 structural-fix versions; brief Changelog has STRUCTURAL FIX headings for 5 versions (with v0.4.11 contributing 2 of its 6 headings)

- **Files:** SESSION-HANDOFF.md §5; product-brief.md Changelog block
- **Confidence:** HIGH for discrepancy

**Evidence:**

Handoff §5 rows: v0.4.5 / v0.4.6 / v0.4.7 / v0.4.8 / v0.4.10 / v0.4.11 = 6 versions.

Brief Changelog STRUCTURAL FIX headings: L56 (v0.4.11) + L57 (v0.4.11) + L63 (v0.4.10) + L78 (v0.4.7) + L84 (v0.4.6) + L90 (v0.4.5) = 6 headings across 5 versions (v0.4.8 has none).

Cross-document coherence gap at v0.4.8.

**Fix:** Resolved as part of F-PASS17-I1 Option 1 (promote v0.4.8 bullets to STRUCTURAL FIX form). One canonical source-of-truth.

### F-PASS17-O2 [OBSERVATION] — SESSION-HANDOFF.md §5 v0.4.11 row inaccurately claims "back-applied to v0.4.5/v0.4.6/v0.4.7" — those entries already had semantic labels before v0.4.11

- **Files:** SESSION-HANDOFF.md §5 v0.4.11 row; product-brief.md L78, L84, L90
- **Confidence:** HIGH

**Evidence:**

Handoff §5 v0.4.11 row description: "Semantic labels replace ordinal cascade counts (and back-applied to v0.4.5/v0.4.6/v0.4.7) + grep-verified citation shorthand sibling-sweep"

Brief Changelog:
- L78 (v0.4.7): `**STRUCTURAL FIX (Per-version attestation collapse):**` — semantic-label format already.
- L84 (v0.4.6): `**STRUCTURAL FIX (Line-count → creation-date anchors):**` — already.
- L90 (v0.4.5): `**STRUCTURAL FIX (L-numbers → grep-anchors):**` — already.

There was nothing to "back-apply" — those three entries already used semantic labels in v0.4.10.

**Fix:**

1. Amend handoff §5 v0.4.11 row description: remove "(and back-applied to v0.4.5/v0.4.6/v0.4.7)" claim. Replace with accurate description: "Semantic labels replace ordinal cascade count in v0.4.10 entry + grep-verified citation shorthand sibling-sweep at 2 callsites (F-PASS16-I1/I2/I3 closure)".

---

## Section F — Forbidden-pattern sweep

| Forbidden pattern | Result |
|---|---|
| `eval ` (code samples) | No active code with `eval` |
| `.claude/templates/` hardcoded | L542 (prohibition reference only) — OK |
| `Co-Authored-By: Claude` | L544 (prohibition reference only) — OK |
| Robot emoji 🤖 | Not found |
| "TODO for architect" / similar | L764 (Self-Audit prohibition) — OK |
| "MVP" / "for now" / "good enough" / "we can fix later" | L7 (target_release label), L333/L366 (legit ship-gate labels), L762 (prohibition) — OK |

**No forbidden-pattern violations.**

---

## Novelty Assessment

**Novelty: MODERATE.**

- F-PASS17-I1 surfaces an audit-trail completeness gap recursively from the v0.4.11 fix's own coverage claim. Same defect-pattern class as Pass 16's "at all callsites" gap, applied to v0.4.11's "all structural-fix headings" claim.
- F-PASS17-S1 is genuinely novel — no prior pass swept §Scope §v0.9 ship gate body for §-as-line-number drift.
- F-PASS17-S2 refines Pass 16's correct Git-Bash addition.
- F-PASS17-O1/O2 are cross-document coherence findings.

**Fresh-Context Compounding Value strongly demonstrated:** Pass 17 surfaces a meta-pattern — fixes that announce broad coverage often deliver narrow coverage. Pass 16 caught it once (sibling-sweep); Pass 17 catches it again (structural-fix labels) — recurring class warrants a structural counter.

---

## Streak Decision

**Streak: stays at 0/3 (FAIL).** 1 IMPORTANT (F-PASS17-I1) exceeds the gate.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 12 | PASS | 1/3 |
| Pass 13 | FAIL (2 IMPORTANT) | 0/3 (RESET) |
| Pass 14 | FAIL (2 IMPORTANT) | 0/3 |
| Pass 15 | FAIL (1 IMPORTANT) | 0/3 |
| Pass 16 | FAIL (3 IMPORTANT) | 0/3 |
| **Pass 17** | **FAIL (1 IMPORTANT)** | **0/3** |

**Convergence trajectory:** Pass 17's 1 IMPORTANT is the smallest blocker count since Pass 15. Cascade converging on meta-language drift in the audit trail itself. Pass 18 either PASSES or surfaces a final novel cross-document coherence finding.

---

## Recommended Next Action

**Dispatch fix-burst for v0.4.12.**

1. **F-PASS17-I1 (IMPORTANT, blocking, [process-gap]):** Promote v0.4.8 changelog bullets at L74 and L75 to `**STRUCTURAL FIX (semantic-label):**` form. Amend L57 to be accurate after back-fill.

2. **F-PASS17-S1 (SUGGESTION, recommended bundle):** Replace L351 `§132`/`§144` with `§SL-9` and `§SL-10` semantic anchors.

3. **F-PASS17-S2 (SUGGESTION, optional bundle):** Flatten L42 cross_platform: `macOS + Linux + Git-Bash + WSL2 (native Windows = v1.0)`.

4. **F-PASS17-O2 (OBSERVATION, handoff cleanup — state-manager scope):** Amend SESSION-HANDOFF.md §5 v0.4.11 row to remove the inaccurate "back-applied to v0.4.5/v0.4.6/v0.4.7" claim.

After v0.4.12, dispatch Pass 18 fresh-context. Streak resumes from 0/3.

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.11
target_lines: 771
pass_number: 17
adversary_protocol: BC-5.39.001 3-CLEAN
finding_counts:
  critical: 0
  important: 1
  suggestion: 2
  observation: 2
  process_gap: 1
  total_blocking: 1
verdict: FAIL
streak_before: 0/3
streak_after: 0/3 (no change — blocker count > 0)
critical_finding_ids: []
important_finding_ids: [F-PASS17-I1]
suggestion_finding_ids: [F-PASS17-S1, F-PASS17-S2]
observation_finding_ids: [F-PASS17-O1, F-PASS17-O2]
process_gap_finding_ids: [F-PASS17-I1]
paper_fix_pattern_observed: true
pass_16_fixes_verified: 5
structural_fixes_still_holding: 7
prior_pass_fixes_still_holding: 18
prior_pass_fixes_regressed: 0
new_findings_classification:
  - F-PASS17-I1: v0.4.11 audit-trail claim "all structural-fix headings" is overbroad — 2 v0.4.8 bullets lack STRUCTURAL FIX heading; process-gap
  - F-PASS17-S1: L351 §132/§144 is line-number masquerading as section anchor; violates Citation Conventions + v0.4.5 discipline
  - F-PASS17-S2: cross_platform frontmatter has redundant nested parentheticals
  - F-PASS17-O1: cross-document coherence — handoff §5 vs brief Changelog disagree on v0.4.8 structural-fix status
  - F-PASS17-O2: handoff §5 v0.4.11 row "back-applied" claim is inaccurate
recommended_next_action: |
  v0.4.12 fix-burst. Promote v0.4.8 changelog bullets (L74/L75) to STRUCTURAL FIX
  form; amend L57; bundle F-PASS17-S1 (§ line-number cleanup at L351) + F-PASS17-S2
  (cross_platform flatten). State-manager corrects handoff §5 v0.4.11 row in the
  Pass 17 persistence commit (F-PASS17-O2).
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-16.md
  - /Users/jmagady/Dev/brain-factory/.factory/SESSION-HANDOFF.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plugin-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plan.md
tool_profile_note: |
  Pass 17 adversary profile is read-only (Read/Grep/Glob). Report persisted by
  orchestrator via state-manager dispatch.
```
