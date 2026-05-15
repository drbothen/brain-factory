---
artifact_type: adversary-pass-report
pass_number: 9
cascade: brain-factory-product-brief-v0.4.4
target_file: .factory/specs/product-brief.md
target_version: 0.4.4
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (Pass 9 FAIL)
created: 2026-05-15
author: vsdd-factory:adversary
finding_count_critical: 0
finding_count_important: 1
finding_count_suggestion: 2
finding_count_observation: 2
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: true
pass_8_fixes_verified_structural: 5
pass_8_fixes_paper_fixed: 1
pass_7_fixes_regressed: 1
---

# Adversarial Review — Pass 9

**Target file:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.4, 725 lines)
**Cascade:** BC-5.39.001 3-CLEAN convergence; brain-factory product brief
**Streak before:** 0/3
**Streak after:** **0/3** (Pass 9 FAIL — 1 IMPORTANT + 1 SUGGESTION-near-IMPORTANT)
**Paper-fix pattern this pass:** Partially detected. F-PASS8-S2 (line-count fixes) was paper-fixed: the brief's v0.4.4 changelog asserts the fix is applied (378→495) but the actual counts are still off by one because the original Pass 8 measurement was correct (496) and the brief substituted 495.

---

## Critical Findings

(none)

---

## Important Findings

### F-PASS9-I1 [IMPORTANT] — Self-Audit Checklist L722 line-number annotations for `/brain:research` and `Perplexity MCP` sibling-sweep are stale by ~9 lines; documents a sweep that does not match the file's actual content

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L722 (Self-Audit Checklist sibling-sweep bullet)
- **Confidence:** HIGH
- **Severity:** IMPORTANT (P1)

**Evidence:**

L722 (Self-Audit Checklist, the v0.4.4 addendum):

> v0.4.4: sibling-swept all `/brain:research` callsites — L261 (v0.1 gate item), L287 (v0.9 gate item), L365 (Scope §26), L475 (NOT-absorbed list), L508 (Phase 3 timeline), L652 (Open Question 8) — all consistent with v0.9 timing after this fix-burst. Sibling-swept all `Perplexity MCP` callsites — L365 (Scope §26) and v0.9 gate item both now reflect optional/opt-in framing.

Verified via Grep + direct Read of each cited line:

| L722 claim | Cited line actual content | Verdict |
|---|---|---|
| L261 — "v0.1 gate item" `/brain:research` callsite | "Plugin repo at `~/Dev/brain-factory` with full Phase 1 folder structure present" | **WRONG** — actual `/brain:research` v0.1 gate item is L270 |
| L287 — "v0.9 gate item" `/brain:research` callsite | "LinkedIn Posts API (Community Management) integration live and tested end-to-end" | **WRONG** — actual `/brain:research` v0.9 gate item is L297 |
| L365 — "Scope §26" `/brain:research` callsite | "`/brain:monthly-perf` — pull performance data from LinkedIn Posts API" | **WRONG** — actual Scope §26 `/brain:research` line is L375 |
| L475 — "NOT-absorbed list" `/brain:research` callsite | "**WASM hooks via factory-dispatcher.** Phase 4 / v1.0" | **WRONG** — actual NOT-absorbed list line is L485 |
| L508 — "Phase 3 timeline" `/brain:research` callsite | "**Self-VSDD:** brain-factory's own development follows the full 7-phase VSDD pipeline" | **WRONG** — actual Phase 3 timeline line is L519 |
| L652 — "Open Question 8" callsite | File has only 725 lines; L652 is inside Open Question 11 prose | **WRONG** — actual Open Question 8 is L663 |
| L365 — "Scope §26" Perplexity MCP callsite | "`/brain:monthly-perf`..." | **WRONG** — actual L375 |

Off by approximately 9–10 lines consistently. This is because v0.4.4's edits (changelog block, new `perplexity_mcp_status` frontmatter field, restructured v0.1+v0.9 gate items, new §510 Optional MCP integrations entry, new Open Question 12) shifted all subsequent content downward but the Self-Audit's "v0.4.4: sibling-swept" annotations record the line numbers from BEFORE those edits landed.

**Why IMPORTANT (not SUGGESTION):**

1. **This is the same defect class Pass 7 (F-PASS7-S2 / F-PASS5-S2) flagged twice for the v0.4.0–v0.4.2 line numbers** — at that time the Self-Audit's `gh auth login` annotations were off by 8 lines because v0.4.2 edits shifted content. The brief acknowledged this pattern at L66's v0.4.3 changelog entry: "(line numbers current as of v0.4.3 authorship; may shift in subsequent edits)." That parenthetical confession was carried forward verbatim into v0.4.4's annotation at L722. But the v0.4.4 annotation was authored DURING v0.4.4's own fix-burst — there are no "subsequent edits" that could have shifted the numbers. The annotation was wrong at the moment it was written.
2. The Self-Audit is the brief's own internal evidence that "I sibling-swept every callsite." If the cited line numbers do not match the file's actual content, the self-audit functions as **false attestation**: the audit-trail says the work was done, but a reader who follows the line-number breadcrumbs lands on unrelated content and cannot verify the claim.
3. **Same axis as Pass 7's F-PASS7-S2.** Pass 7 graded the L697 (v0.4.2) staleness as SUGGESTION because it was carrying forward old line numbers across an edit boundary. Pass 9 graded one tier higher because v0.4.4 introduced the same defect AT the moment of authorship, on a self-audit annotation that explicitly catalogues a sibling-sweep just performed. This is regression to a known defect class within the same release fix-burst — a process-discipline failure beyond a simple staleness drift.

**Fix options:**
1. Update L722 line-number citations to actual positions: L270, L297, L375, L485, L519, L663 for `/brain:research`; L375 + L297 for Perplexity MCP in Scope §26 and v0.9 gate respectively.
2. OR replace specific line numbers with grep-anchored references: "L containing `/brain:research <topic>` in §26 Scope" — durable against future edits.

---

## Suggestions

### F-PASS9-S1 [SUGGESTION] — Traceability artifact line-count citations remain off by one after v0.4.4's S2 fix-burst (paper-fix pattern)

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L695 (elicitation-notes.md "610-line"), L699 (stage-3-locks.md "171-line"), L703 (brief-research.md "495-line")
- **Confidence:** HIGH

**Evidence (file vs claim, re-verified via Read tool):**

| Artifact | Brief claim (v0.4.4) | Actual line count |
|---|---|---|
| elicitation-notes.md | "610-line" (L695) | **611** (file has 611 lines; Read tool reports 611) |
| stage-3-locks.md | "171-line" (L699) | **172** (file has 172 lines) |
| brief-research.md | "495-line" (L703) | **496** (file has 496 lines) |

The v0.4.4 changelog at L58 asserts:

> Updated Traceability line-count citation (F-PASS8-S2): brief-research.md 378→495 (verified via `wc -l`; elicitation-notes 610 and stage-3-locks 171 already accurate)

This is a **paper-fix**:
- Pass 8 measured 611/172/496. The brief substitutes 610/171/495. Pass 8 was correct.
- The claim "verified via `wc -l`" suggests `wc -l` was invoked; `wc -l` counts newlines (not lines), so a file with 611 content lines and a trailing newline returns "611" from `wc -l`. The brief's own Read-tool path returns 611 line count too.
- The off-by-one is suspicious because all three drift in the same direction (claim = actual−1), suggesting the author confused `wc -l` semantics with last-non-empty-line counting.

**Why SUGGESTION-grade not IMPORTANT:**
- Off-by-one line counts on supporting artifacts are not commitment-grade defects.
- BUT the changelog explicitly claims the fix was verified, which is false. This is the paper-fix pattern: changelog states "verified" but the verified value is wrong.

**Fix options:**
1. Update L695 "610-line" → "611-line"; L699 "171-line" → "172-line"; L703 "495-line" → "496-line".
2. OR drop specific line counts and use creation-date anchors only ("created 2026-05-14" / "created 2026-05-15") to eliminate drift recurrence.

---

### F-PASS9-S2 [SUGGESTION] — `/brain:init` scaffolds 7 topic categories but plan §A.2 also includes `highlights/` and `bookmarks/` sources subdirs; brief's v0.1 init scope is silent on these two

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L227 (Scalability §3), L457 (Scope "7 default topic categories")
- **Confidence:** MEDIUM

**Evidence:**

L227 (Scalability commitment, brief-side):
> `sources/` uses `sources/{topic}/` subdirectories (7 default categories: ai, health, psychology, productivity, business, books, podcasts; extensible).

L457 (Scope "Additional v0.x deliverables"):
> **7 default topic categories** scaffolded by `/brain:init` in the target brain's `sources/` folder per `llm-second-brain-plan.md` §3.3: `ai`, `health`, `psychology`, `productivity`, `business`, `books`, `podcasts`.

Plan §3.3 (`docs/planning/llm-second-brain-plan.md` L189-199) enumerates exactly the 7 categories the brief cites. **However**, plan §A.2 (`docs/planning/llm-second-brain-plan.md` L291-300, the target folder structure) shows:
- `sources/{ai,health,psychology,productivity,business,books,podcasts,highlights,bookmarks}/`

plus L299: `│ ├── highlights/ .gitkeep # Readwise daily exports land here`
plus L300: `│ └── bookmarks/ .gitkeep # Raindrop.io daily exports land here`

The plan has two source-folder enumerations: §3.3 lists 7 user-facing topic categories, but §A.2 shows the scaffold creates 9 subdirs (7 topics + `highlights/` + `bookmarks/`). The brief's `/brain:init` commitment at L457 scaffolds only the 7 topics, omitting `highlights/` and `bookmarks/`. But the v0.5 GH Action templates `readwise-sync.yml` and `raindrop-sync.yml` (L437 enumeration) target exactly those two omitted subdirs — readwise writes to `sources/highlights/` and raindrop writes to `sources/bookmarks/` per plan §8.7–§8.7b.

**Forward-impact:** An implementer following the brief's `/brain:init` v0.1 scaffold creates 7 subdirs. Operator runs `readwise-sync.yml` at v0.5; the workflow writes to `sources/highlights/` which doesn't exist — silent path creation or failure depending on the tool's behavior.

This is the same class as the Pass 8 F-PASS8-S4 fix (drafts/to-publish/published flagged as brief-introduced extension) — but **inverted**: the brief OMITS plan §A.2 subdirs in one place while scope §A.2 includes them. The brief should either (a) explicitly scaffold 9 subdirs, OR (b) document that `highlights/` and `bookmarks/` are auto-created by the relevant v0.5 GH Action workflows.

**Fix options:**
1. Update L457 to scaffold all 9 subdirs (7 topics + highlights + bookmarks per plan §A.2).
2. OR add a note: "`highlights/` and `bookmarks/` source subdirs are created on-demand by `readwise-sync.yml` (v0.5) and `raindrop-sync.yml` (v0.5) respectively; not part of the v0.1 `/brain:init` scaffold."

---

## Observations

### F-PASS9-O1 [OBSERVATION] — v0.9 ship gate item at L297 for `/brain:research` runtime test depends on optional Perplexity MCP being either configured-OR-not without specifying which path is tested

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L297
- **Confidence:** MEDIUM

L297 reads:
> `/brain:research <topic>` (skill #26, Phase 2-3 polish) successfully dispatches the `brain:researcher` specialist with the configured research backend (web search by default; Perplexity MCP if operator opted in via `.brain/policies.yaml`), synthesizes findings on a sample topic, and outputs to both `wiki/` pages and `briefs/research/<topic>-research.md`.

The phrase "the configured research backend (web search by default; Perplexity MCP if operator opted in)" introduces a forking gate criterion. Two scenarios produce a "successful dispatch":
- Operator A has not opted in: gate validates web-search path
- Operator B has opted in to Perplexity: gate validates MCP path

The gate doesn't specify which path is tested. If the author ships the v0.9 release after testing only the default web-search backend, the Perplexity MCP path remains untested at ship time. Conversely, if only the Perplexity path is tested, the web-search default path goes unverified despite being the documented default for all v0.9 operators.

This is OBSERVATION-grade because it's a definition-of-done ambiguity for an optional code path, not a structural contradiction. But it should be locked: either both paths must be tested, or one is canonical for the gate.

---

### F-PASS9-O2 [OBSERVATION] — Open Question #12 (web-search vs Perplexity MCP tradeoff) is structured as a self-resolved decision, not an open question

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** L671

L671:
> **Default research backend quality tradeoff: web-search vs. Perplexity MCP.** Locked decision: web-search is default; Perplexity MCP is opt-in via `.brain/policies.yaml` (skill #26, ships v0.9). Future evaluation may reverse the default if Perplexity quality proves dramatically better at scale during Phase 3 dogfood. Lock-status: web-search-default committed for v0.9; opt-in reversal requires explicit human decision post-Phase 3 evaluation.

The entry starts "Locked decision: ..." and ends "Lock-status: ... committed." This is not an Open Question — it's a locked decision documented in the wrong section. Compare to Q8 (L663) which uses the strike-through pattern to mark a resolved question while keeping it visible. Q12 should either:
- Move to a "Resolved Decisions" section, OR
- Use the strike-through resolved pattern with the actual unresolved question being only "post-Phase 3 backend evaluation criteria not yet defined," OR
- Be reframed to state the genuinely open dimension (e.g., "What measurable criteria during Phase 3 dogfood would trigger a reversal of the default to Perplexity?").

This pattern muddies the §Open Questions section's contract that "each has a clear ownership path and will be resolved before the phase that requires them" (L646).

---

## Novelty Assessment

**Novelty: MEDIUM-HIGH.** One new IMPORTANT finding (F-PASS9-I1) of the same defect class Pass 7 flagged for v0.4.2 line-number staleness, but **regressed during the v0.4.4 fix-burst itself** — not carried forward from a prior version. The Self-Audit at L722 is the brief's own audit trail for "I sibling-swept every `/brain:research` callsite during v0.4.4," and six of the six cited line numbers are wrong as-of-authorship.

One SUGGESTION-grade finding (F-PASS9-S1) confirms Pass 8 F-PASS8-S2 was paper-fixed: changelog claims "verified via `wc -l`," but the values written are off-by-one in the same direction for all three artifacts, suggesting confusion about `wc -l` semantics rather than verification.

One SUGGESTION-grade finding (F-PASS9-S2) surfaces a new plan-§A.2-vs-brief drift: `highlights/` and `bookmarks/` source subdirs documented in plan §A.2 are omitted from the brief's v0.1 `/brain:init` scaffold commitment despite being targets of v0.5 GH Action templates.

Two OBSERVATION-grade items (Perplexity MCP gate-criterion ambiguity, Q12 mis-categorized as Open Question).

**Genuinely new ground: yes.** The Self-Audit-line-number-regression-introduced-by-fix-burst is structurally distinct from Pass 7's v0.4.2 carryover staleness, even though they share the defect class.

**Compared to Pass 8:** Pass 8's F-PASS8-I1 (research timing) is genuinely structurally fixed. Pass 8's F-PASS8-I2 (Perplexity optional) is genuinely structurally fixed. Pass 8's F-PASS8-S3 (validate-publish-state scope) is verified clean at L420. Pass 8's F-PASS8-S4 (drafts/{platform} extension flag) is verified clean at L196. F-PASS8-S1 (version-agnostic phrasing) verified clean at L691. **F-PASS8-S2 (line-count refresh) is paper-fixed** — the only Pass 8 finding not structurally resolved.

---

## Pass 8 Fix Verification

| Pass 8 finding | v0.4.4 fix | Verification |
|---|---|---|
| F-PASS8-I1 (/brain:research v0.1-vs-v0.9 contradiction) | L270 changed to scaffolding-only commitment; L297 new v0.9 gate item; L375 §26 unambiguously v0.9 | **STRUCTURALLY VERIFIED.** No remaining v0.1 runtime claim. |
| F-PASS8-I2 (Perplexity MCP optional) | L50 frontmatter; L297 "configured research backend"; L375 default-web-search; L510 Optional MCP integrations; L671 Open Q12 | **STRUCTURALLY VERIFIED.** All callsites support optional/opt-in framing. L143 Target Users prerequisites no longer needs Perplexity (correct). |
| F-PASS8-S1 (preserved through v0.4.2) | L691 now reads "state preserved through the current version" | **STRUCTURALLY VERIFIED.** |
| F-PASS8-S2 (line-count refresh) | L695 "610-line"; L699 "171-line"; L703 "495-line" | **PAPER-FIXED.** Values still off by one (actual: 611/172/496). See F-PASS9-S1. |
| F-PASS8-S3 (validate-publish-state.sh scope) | L420 now uses explicit glob `drafts/{platform}/*.md`, `to-publish/{platform}/*.md`, `published/{platform}/*.md` | **STRUCTURALLY VERIFIED.** |
| F-PASS8-S4 (drafts/{platform} extension flag) | L196 now flags "as a brief-introduced extension beyond plan §A.2's simpler `published/` baseline" | **STRUCTURALLY VERIFIED.** |

5 of 6 Pass 8 fixes verified structurally. 1 of 6 paper-fixed (F-PASS8-S2).

---

## Pass 7 Fix Regression Check

| Pass 7 finding | Current v0.4.4 status |
|---|---|
| F-PASS7-I1 (12-vs-13 hook count at L186/L311/L574) | **STILL CORRECT.** L203 says 13-hook port; L329 says All 13 WASM hooks; L593 says 13-hook port. Adjustment parentheticals consistent. |
| F-PASS7-S1 (stage_3_locks frontmatter + Traceability) | **STILL CORRECT.** L20 frontmatter present; L697-699 Traceability subsection present. |
| F-PASS7-S2 (stale Self-Audit line numbers) | **REGRESSED — see F-PASS9-I1.** The v0.4.4-authored sibling-sweep annotation at L722 has the same defect class for new callsites. |
| F-PASS7-S3 (reverse-chronological changelog) | **STILL CORRECT.** L55 (v0.4.4) → L63 (v0.4.3) → L70 (v0.4.2) → L77 (v0.4.1) → L87 (v0.4.0). |
| F-PASS7-S4 (§8.3 → §10.5 citation) | **STILL CORRECT.** L177 cites "§8.2.4 ("verdicts must match") and §10.5 (where the literal pass-criterion `diff_count = 0` appears)". |

4 of 5 Pass 7 fixes preserved; 1 of 5 regressed within the same defect class.

---

## Count Adjustment Sibling-Sweep Audit (Pass 9 stress-test)

| Adjustment | Plan-doc baseline | Brief value | Callsites verified |
|---|---|---|---|
| 12 → 13 hooks | §A.4 (12), §5.11 (12), §7.5 (12), §8.3 (12) | 13 (frontmatter, all 4 gates, Family Positioning, Future Infrastructure) | **CONSISTENT** — L29, L203, L263, L269, L275, L295, L329, L403, L593 |
| 25 → 26 skills | plugin plan §5 ("25 skills") | 26 (25 + /brain:research) | **CONSISTENT** — L27, L296, L343, L678 (plan-doc-original at L678) |
| 10 → 14 agents | plugin plan §6 ("10 agents") | 14 (10 + 4 wclaude) | **CONSISTENT** — L28, L192, L379, L381, L577, L678 (plan-doc-original) |
| 19 GH Actions | plan §8.1-§8.18 (6+9+4) | 19 (6+9+4) | **CONSISTENT** — L30-32, L286, L424-449 |

No count-adjustment sibling-sweep defects. Pass 7 lesson preserved.

---

## Multi-Callsite Identifier Coherence Check

| Identifier | Callsites verified | Verdict |
|---|---|---|
| `/brain:research` | L270 (v0.1 scaffold), L297 (v0.9 runtime gate), L375 (§26 Scope), L485 (NOT-absorbed list), L519 (Phase 3 timeline), L663 (Q8), L671 (Q12) | **COHERENT.** All callsites consistent with "ships v0.9; v0.1 scaffolds directory only." |
| `Perplexity MCP` | L50 (frontmatter), L57 (changelog), L297 (v0.9 gate optional), L375 (§26 opt-in), L510 (Optional MCP), L671 (Q12) | **COHERENT.** All callsites consistent with "optional opt-in, web-search default." |
| `validate-publish-state.sh` | L195 (absorption), L295 (v0.9 bats), L329 (v1.0 WASM), L420 (hook spec) | **COHERENT.** |
| `briefs/research/` | L56 (changelog), L270 (v0.1 scaffold), L297 (v0.9 output target), L375 (§26 extension), L663 (Q8 resolved note) | **COHERENT.** |

---

## Citation Spot-Check (7 sampled, including v0.4.4-new citations)

| # | Citation | Source verified | Verdict |
|---|---|---|---|
| 1 | L297 → "Perplexity MCP if operator opted in via `.brain/policies.yaml`" | `.brain/policies.yaml` is the brain-side policy file per plugin plan §10; consistent | VERIFIED |
| 2 | L177 → phased-plan §10.5 (`diff_count = 0` literal) | phased-plan §10.5 L711 contains `diff_count = 0` (Pass 7/8 verified) | VERIFIED |
| 3 | L457 → plan.md §3.3 (7 topic categories) | plan.md §3.3 L189-199 enumerates exactly 7 categories | VERIFIED |
| 4 | L457 vs plan §A.2 (9 source subdirs: 7 topics + highlights + bookmarks) | plan §A.2 L291-300 shows 9 subdirs incl. highlights, bookmarks | **DRIFT** (F-PASS9-S2) |
| 5 | L695 → "elicitation-notes.md — 610-line" | Actual: 611 lines | **FAILED** (F-PASS9-S1) |
| 6 | L699 → "stage-3-locks.md — 171-line" | Actual: 172 lines | **FAILED** (F-PASS9-S1) |
| 7 | L703 → "brief-research.md — 495-line" | Actual: 496 lines | **FAILED** (F-PASS9-S1) |

3 verified, 4 failed (1 drift, 3 line-count off-by-ones).

---

## Convergence Assessment

**The brief has NOT converged at v0.4.4.**

A genuine IMPORTANT defect (F-PASS9-I1, self-audit-line-number-regression-introduced-by-fix-burst) was undetected because Pass 8's fix verification focused on the structural defects F-PASS8-I1 and I2, not on the self-audit annotations the fix-burst wrote about itself.

**The fresh-context adversarial review pattern is working as designed:** Pass 9's independent assessment found a regression of the same defect class Pass 7 caught. The brief is now structurally near-converged on every other axis. The remaining defects are:
- 1 IMPORTANT defect (F-PASS9-I1) — self-audit line-number staleness in v0.4.4-authored annotation
- 2 SUGGESTION defects (line-count off-by-one paper-fix, sources subdir scope drift)
- 2 OBSERVATIONS

A v0.4.5 fix-burst addressing F-PASS9-I1 + F-PASS9-S1 + F-PASS9-S2 should converge in a single pass.

**Process gap candidate (not flagged as [process-gap]):** The Self-Audit Checklist's line-number annotations have failed staleness verification in 3 consecutive passes (Pass 5, Pass 7, Pass 9). The recurring pattern suggests the Self-Audit format itself is structurally fragile against edit-induced line shifts. A durable fix would replace line-number citations with grep-anchored references. But this is a brief-format choice for the author/orchestrator to make, not a brain-factory engine concern.

---

## Streak Decision

**Streak: stays at 0/3.**

1 IMPORTANT finding (F-PASS9-I1) is blocker-grade. Per the protocol, ANY blocker findings → streak stays at 0/3, dispatch product-owner fix-burst.

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
| **Pass 9** | **FAIL (1 IMPORTANT)** | **0/3** |

---

## Top 3 Findings

1. **F-PASS9-I1 [IMPORTANT]** — Self-Audit Checklist at L722 cites L261/L287/L365/L475/L508/L652 for v0.4.4's `/brain:research` and Perplexity MCP sibling-sweep; ALL SIX line numbers are wrong by ~9 lines (actual: L270/L297/L375/L485/L519/L663). The annotation was authored DURING v0.4.4's fix-burst — there are no subsequent edits that could excuse the drift. Same defect class as Pass 7 F-PASS7-S2 but introduced AT-AUTHORSHIP rather than carried forward. Fix: update line numbers to current positions, OR replace with grep-anchored references.

2. **F-PASS9-S1 [SUGGESTION]** — Pass 8 F-PASS8-S2 fix is paper-fixed. The v0.4.4 changelog (L58) claims "verified via `wc -l`" for line counts, but the values written (610/171/495) are off by one against actual file counts (611/172/496) in all three Traceability artifact entries. The off-by-one direction is consistent, suggesting `wc -l` semantic confusion (file with N content lines and a trailing newline gives `wc -l` = N, not N−1). Fix: write 611/172/496, OR drop line counts entirely.

3. **F-PASS9-S2 [SUGGESTION]** — Plan §A.2 shows 9 source subdirs (7 topics + `highlights/` + `bookmarks/`) but brief L457 commits `/brain:init` to scaffold only 7 topic categories. The v0.5 GH Action templates `readwise-sync.yml` and `raindrop-sync.yml` target the missing two subdirs. Operator path: v0.1 scaffolds 7 subdirs; v0.5 readwise-sync writes to non-existent `sources/highlights/` → silent path creation or failure. Fix: scaffold 9 subdirs at v0.1, OR explicitly document on-demand creation by v0.5 workflows.
