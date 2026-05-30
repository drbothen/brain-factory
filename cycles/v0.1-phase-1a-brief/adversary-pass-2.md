---
artifact_type: adversary-pass-report
pass_number: 2
cascade: brain-factory-product-brief-v0.3.0
target_file: .factory/specs/product-brief.md
target_version: 0.3.0
adversary_protocol: BC-5.39.001 3-CLEAN
streak: 0/3 (RESET after Pass 2 FAIL)
created: 2026-05-14
author: vsdd-factory:adversary (Pass 2)
inputs:
  - .factory/specs/product-brief.md (v0.3.0, 536 lines)
  - .factory/cycles/v0.1-phase-1a-brief/adversary-pass-1.md
  - .factory/planning/elicitation-notes.md
  - .factory/planning/brief-research.md
  - CLAUDE.md (post-amendment)
  - docs/planning/llm-second-brain-plan.md (spot-checked §3.3, §8.1–§8.18)
  - docs/planning/llm-second-brain-phased-build-plan.md (spot-checked §A.2, §5.11, §7.5, §8.2.4)
finding_count_critical: 1
finding_count_important: 3
finding_count_suggestion: 5
finding_count_process_gap: 0
verdict: FAIL
pass_1_resolution_audit: 10-of-12-RESOLVED-2-introduced-new-issues
---

## Adversary Pass 2 — brain-factory Product Brief v0.3.0

## Verdict

**FAIL.** v0.3.0 made substantial progress — all 4 Pass-1 CRITICAL findings appear genuinely resolved at the structural level — but the fix-burst introduced **1 NEW CRITICAL** (a smuggled v0.1 ship gate commitment), missed **1 substantive paper-fix risk** around the `briefs/research/` scope expansion that contradicts plan §A.2, and exhibits internal count drift in the wclaude-absorption section. Streak resets to 0/3.

---

## Pass 1 Findings — Resolution Audit

Note: Pass 1 report persisted at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-1.md` is a metadata stub (per its own preamble: "full verbatim content is in the orchestrator session log"). I audit against the substantive content keys in the Pass-2 dispatch prompt, cross-referenced to the persisted F-IDs where they map.

| Pass-1 Issue (per dispatch prompt) | Status | Evidence (v0.3.0 line numbers) | New issue? |
|---|---|---|---|
| **F-1/F-2/F-8/F-16 (GH Action count 19=15+4)** | **RESOLVED** | Frontmatter L29–31; Scope enumeration L301–326 (19 items); v0.5 milestone L180 (9+4=13); Self-audit L527 (19=15+4). All 19 names cited with plan.md §-numbers. Arithmetic verifies. No "22" leftover except a single self-audit reference at L527 documenting the v0.2→v0.3 correction (acceptable as historical record). | None |
| **F-3 (CLAUDE.md Node 20+ alignment)** | **RESOLVED** | CLAUDE.md line 5 now reads "Node 20+ is required at the operator's machine." Brief frontmatter L25 `toolchain: bash + jq + yq + awk + bats + shellcheck + shfmt + Node 20+`; body L371 explicitly states Node 20+ as toolchain prerequisite. Consistent. | None |
| **F-4 (hook citation "Adjusted from §5.11's 12" at L161/L167/L189)** | **RESOLVED** | L161 and L167 use the verbatim "Adjusted from §5.11's 12" pattern. L189 uses parallel wording: "the 13 covers the 12 from §A.4 plus `validate-publish-state.sh`". L189 cites §7.5 not §5.11 (different source section for v0.9 gate), so the parallel-but-different phrasing is correct and structurally faithful. | None |
| **F-5 (7-phase VSDD vs 6-dim brain disambiguation)** | **RESOLVED** | L197 uses "7-phase VSDD-pipeline convergence" with explicit phase enumeration; L384 uses "full 7-phase VSDD pipeline"; "six-dimensional convergence" preserved at L70, L112, L224, L347 for brain-level. No remaining conflation. | None |
| **F-7 (aspirational language: "approximately 200-line", "target <100ms", "target <50K tokens")** | **PARTIALLY_RESOLVED → introduces NEW critical** | L382 changed "target <100ms" → "Performance budget: <100ms; v0.1 ship gate includes a bats test asserting tail latency under load." But the v0.1 ship gate at L159–177 contains NO such bats test criterion. **Smuggled commitment** — see F-NEW-1 below. L383 token budget rewording is clean. The "approximately 200-line" reference is no longer present. | YES — see F-NEW-1 |
| **F-9 (Medium extension Phase-1c prerequisite explicit)** | **RESOLVED** | L183: "Prerequisite: the extension schema (hook contract + frontmatter schema) MUST be locked in Phase 1c architecture before this milestone can be claimed." Unambiguous. Also surfaced as Open Question 7 (L479) with same locking constraint. | None |
| **F-10 (agent ownership disclaimer before list)** | **RESOLVED** | L258: "All 14 agents below ship in the brain-factory plugin tarball and use the `brain:*` namespace... brain-factory is fully self-contained at runtime." | None |
| **F-11 (Open Question 8 `/brain:research` dual-output cleanup)** | **RESOLVED** (struck-through is sufficient) | L481 strike-through with explicit "Resolved (v0.3.0 brief, user-confirmed)" resolution marker. Adequate for traceability; full removal would lose context. | None |
| **F-12 (model family inline definition)** | **RESOLVED** | L125 (Value Proposition): "in brain-factory v0.x: Opus and Sonnet are different families for adversary-review purposes; both Anthropic; cognitive diversity does not require a second vendor." Identical phrasing repeated L380 (Constraints/Technical). Faithful to plugin plan §3 line 173 (which uses Opus/Sonnet as the canonical example of "different model families"). | None |
| **F-13 (7-phase enumeration in v0.9 ship gate including Phase 5/6)** | **RESOLVED** | L197 enumerates: "1: spec crystallization with sub-phases 1a domain / 1b PRD / 1c architecture / 1d adversarial spec review; 2: story decomposition; 3: TDD implementation; 4: holdout evaluation; **5: adversarial refinement; 6: formal hardening**; 7: 7-dimensional convergence assessment". | None |
| **F-15 (10 baseline policies in `policies-yaml-template.yaml` explicit)** | **RESOLVED** | L333: "The `policies-yaml-template.yaml` template at `${CLAUDE_PLUGIN_ROOT}/templates/policies-yaml-template.yaml` ships pre-populated with the 10 baseline policies enumerated in plugin plan §10.2." | None |
| **F-21 (5-minute SLA: `assert_under_5_minutes` in v0.1 gate)** | **RESOLVED** | L165: "the v0.1 ship gate adds an explicit timer assertion (`assert_under_5_minutes`) to the local-dev test script in `plugins/brain-factory/tests/local-dev-test.sh`, supplementing phased plan §5.11's exit criteria. This is a new addition to the gate, not a re-citation." Explicit and well-disclosed. | None |
| **F-22 (Tavily, Context7 removed from `/brain:research` body)** | **RESOLVED** | L168, L252: only "Perplexity MCP and web search access" remains. No occurrences of "Tavily" or "Context7" in the brief. `briefs/research/` scaffold documented at L168, L252, L481, L334 — but see F-NEW-3 for §A.2 issue. | Partial — see F-NEW-3 |

Net: All 12 Pass-1 issues from the dispatch prompt are structurally addressed. One (F-7) introduced a new critical; one (F-22) introduced a partial scope-expansion contradiction (F-NEW-3 below).

---

## New Findings (v0.3.0 introduced or missed by Pass 1)

### F-NEW-1 [CRITICAL] — Smuggled v0.1 ship gate commitment (hook performance bats test)

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L382 (constraint claim); L159–L177 (v0.1 ship gate, where the criterion is missing)
- **Confidence:** HIGH

L382 (Constraints/Technical) asserts:
> "Hook performance budget. Performance budget: <100ms; **v0.1 ship gate includes a bats test asserting tail latency under load**. Wikilink validation across a 500+ page wiki may require incremental design."

But the v0.1 ship gate enumerated at lines 159–177 contains 18 criteria, **none of which** mention a tail-latency bats test, hook performance assertion, or anything resembling "asserting tail latency under load."

This is a paper-fix of F-7 (aspirational `target <100ms` language tightened) that introduces a phantom v0.1 commitment. The constraint at L382 promises an exit-gate test that the gate itself doesn't list. An implementer reading the gate alone will not know this test is required. A test-writer reading the gate alone won't write it.

**Fix:** Either (a) add an explicit bullet to the v0.1 ship gate enumerating the test (consistent with the F-21 pattern at L165 where the `assert_under_5_minutes` is disclosed in the gate itself), or (b) soften L382's claim to "Performance budget is <100ms; bats test for tail-latency is targeted for Phase 1+ but not required for v0.1 cut."

This is the same paper-fix smell that drove F-21's careful disclosure. Apply the same discipline here.

### F-NEW-2 [IMPORTANT] — wclaude absorption count drift between §Value Proposition and §Prior Art

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L136 (Value Proposition), L441 (Prior Art)
- **Confidence:** HIGH

L136 (Value Proposition / Family positioning) opens with:
> "**Four** wclaude content-publishing plugin patterns are absorbed directly into brain-factory's v0.x agent roster and skill surface..."

The following bullets at L138–L145 list **8 items**:
1. Four validation agents
2. Writescore + revision-loop
3. `--finalize --url` flag
4. Frontmatter state machine
5. Directory structure
6. `--companion-posts` flag
7. `--schedule <date>` flag
8. `--hero-prompt` flag

L441 (Prior Art / "Content lifecycle patterns absorbed from wclaude") lists only **5 items** (omits the three `--*` flags on existing skills).

Three readings of "what is absorbed from wclaude" coexist in the brief:
- "Four" (L136 prose)
- "Eight" (L138–L145 bullet list immediately following)
- "Five" (L445–L449 Prior Art bullet list)

This is an internal contradiction that confuses scope. A reader trying to understand the wclaude-absorption surface gets three different answers depending on which section they read first.

**Fix:** Pick one canonical inventory (probably 5 or 8 depending on whether flag-on-existing-skill counts as a pattern absorption). Reconcile both sections to that canonical inventory. The "Four" prose-sentence at L136 should be replaced with the canonical count.

### F-NEW-3 [IMPORTANT] — `briefs/research/` directory contradicts plan §A.2 folder structure without explicit acknowledgment

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L168, L252, L481 (commitments to scaffold `briefs/research/`); plan §A.2 (`docs/planning/llm-second-brain-phased-build-plan.md:811`)
- **Confidence:** HIGH

Plan §A.2 enumerates the canonical brain folder structure:
```
├── briefs/{daily,weekly,monthly,content,decisions}/
```

This is 5 subdirectories — no `research/`.

The brief commits at three locations that `/brain:init` scaffolds `briefs/research/`:
- L168 (v0.1 ship gate): "outputs to both `wiki/` pages and `briefs/research/<topic>-research.md`. (The `briefs/research/` directory is created by `/brain:init` as part of the scaffold.)"
- L252 (Skill 26): "The `briefs/research/` directory is created by `/brain:init` as part of the scaffold (**extending the target brain's folder structure per plan §A.2 `briefs/` directory**)."
- L481 (Open Q 8 resolution): "The `briefs/research/` directory is created by `/brain:init` as part of the scaffold."

The parenthetical at L252 — "extending the target brain's folder structure per plan §A.2 `briefs/` directory" — is misleading. §A.2 does NOT include `research/`; the brief is adding a 6th subdirectory not in the source. Saying "per plan §A.2" implies §A.2 sanctions the addition, when in fact §A.2 only has 5 subdirs.

This is a citation that doesn't support its claim. Either:
- (a) Strike "per plan §A.2 `briefs/` directory" and clearly mark `briefs/research/` as a brain-factory-introduced subdirectory beyond the plan's canonical 5, OR
- (b) Acknowledge: "extending the target brain's folder structure beyond plan §A.2's enumerated {daily, weekly, monthly, content, decisions} subdirs to include `research/`."

CLAUDE.md "brain-factory-001" rule: "Planning artifacts are immutable... Mid-pipeline changes go to `.factory/` specs, not back-propagated to planning artifacts." That permits the brief to extend the spec. But the citation form must be honest about it.

### F-NEW-4 [IMPORTANT] — §8.2.4 citation overstates source ("byte-identical stdout" not in source)

- **File:** `.factory/specs/product-brief.md` L126
- **Source:** `docs/planning/llm-second-brain-phased-build-plan.md:621`
- **Confidence:** HIGH

Brief L126:
> "v1.0 migrates to WASM via the shared factory-dispatcher with parity tests (each WASM hook receives identical stdin payloads as the bash equivalent and must emit **byte-identical stdout**, per `llm-second-brain-phased-build-plan.md` §8.2.4)"

Plan §8.2.4 actually says:
> "8.2.4 Add a parity test: run both bash hook and WASM hook against the same payloads; **verdicts must match**."

"Verdicts must match" is not the same as "byte-identical stdout." A bash hook may emit JSON like `{"status":"ok","trace":"abc","ts":1234567890}`; the WASM hook emitting `{"status":"ok","trace":"abc","ts":1234567891}` has matching verdicts but different bytes (different timestamps, different trace UUIDs). The brief's "byte-identical" is a stricter commitment than the planning doc makes.

Also: brief §v1.0 ship gate L206 also references "diff_count = 0" — that wording IS supported by plan §711 "parity test diff_count = 0." But L126's "byte-identical stdout" overstates §8.2.4 specifically.

**Fix:** Reword L126 from "must emit byte-identical stdout" to "must emit matching verdicts (diff_count = 0)" — consistent with both §8.2.4 ("verdicts must match") and §711 ("diff_count = 0"), and not overstating either.

---

## Product-Owner Flagged Items

### Item 1: Open Question 8 cleanup — strike-through resolution

**Assessment:** The strike-through with explicit "Resolved (v0.3.0 brief, user-confirmed)" tag at L481 is **adequate**. Recommendation is to KEEP the struck-through entry as-is for traceability — full removal would erase the historical decision context that the resolution rests on. The current form is clean.

### Item 2: 7 topic categories citation accuracy

**Assessment:** **VERIFIED.** Plan.md §3.3 (line 189 onward) and plan.md L442 both enumerate exactly: `ai, health, psychology, productivity, business, books, podcasts`. The brief at L334 enumerates the same 7 in the same order. Citation accurate. **No finding.**

### Item 3: §8.2.4 parity test citation accuracy

**Assessment:** **FAILS.** §8.2.4 says "verdicts must match." The brief paraphrases this as "byte-identical stdout" — stricter than the source. See **F-NEW-4** above.

---

## Count Reconciliation

| Claim | Stated | Verified | Status |
|---|---|---|---|
| 26 skills | 26 (13 primitives + 12 polish + 1 research) | 26 (L222–L252 enumeration) | PASS |
| 14 agents | 14 (10 brain + 4 wclaude) | 14 (L260–L276 enumeration) | PASS |
| 13 hooks | 13 (12 from §A.4 + 1 from wclaude) | 13 (L283–L297 enumeration) | PASS |
| 19 GH Actions | 19 (6 v0.1 + 9 v0.5 + 4 community = 15+4) | 19 (L303–L326 enumeration; all cite §8.X in plan.md) | PASS |
| 10 policies | 10 baseline | 10 (L335) | PASS |
| 6 wiki page types | 6 (concepts/people/frameworks/syntheses/observations/questions) | 6 (consistent with plan §3.4) | PASS |
| 7 topic categories | 7 (ai/health/psychology/productivity/business/books/podcasts) | 7 (verified vs plan.md L189, L442) | PASS |
| ~20 templates | ~20 (CLAUDE.md + 6 wiki + 3 source + 5 brief + 1 policies + 1 STATE + 1 manifest + GH Actions) | Approximately 19+ (counts depend on whether GH Action templates count as 1 directory or 19 individual templates) | WARN — slightly fuzzy; using "~20" so soft commitment |
| 13–17 weeks v0.x | 1 + 3 + 1 + (8 to 12) | 13 to 17 ✓ | PASS |
| 8 bats suites | 8 (skills/hooks/templates/policies/adversary/quarantine/integration/upgrade) + meta-lint | L338 = "8 ... Plus `meta-lint.bats`"; L439 = "8+ bats suites" — minor inconsistency between "8" and "8+" but reconcilable | WARN — minor; see F-S-2 |
| 16 lifted principles | 16 (plugin plan §3.1–§3.16) | 16 verified (plugin plan L110–L223) | PASS |
| 4 wclaude validation agents | 4 (voice-analyzer, content-structure-reviewer, frontmatter-validator, platform-compliance-checker) | 4 but the umbrella "wclaude absorption count" drifts between 4/5/8 — see F-NEW-2 | WARN — inner consistency broken |

---

## Citation Spot-Check Audit (10 NEW citations introduced or modified in v0.3.0)

| # | Citation in Brief | Source | Verdict |
|---|---|---|---|
| 1 | "19 GH Action templates (15 + 4)" with §8.X enumeration | plan.md §8.1–§8.18 + §8.7b | VERIFIED — all 19 names and section numbers match |
| 2 | "7 default topic categories" → plan.md §3.3 | plan.md §3.3 (L189) | VERIFIED |
| 3 | "byte-identical stdout per §8.2.4" | phased-plan §8.2.4 (L621) | FAILS — source says "verdicts must match", not byte-identical (see F-NEW-4) |
| 4 | "diff_count = 0 per §8.3" at L206 | phased-plan §8.3 + §711 | VERIFIED |
| 5 | "extending §A.2 `briefs/` directory" with `briefs/research/` | phased-plan §A.2 (L811) | MISLEADING — §A.2 has 5 subdirs, none `research/` (see F-NEW-3) |
| 6 | "`policies-yaml-template.yaml` pre-populated with 10 policies per plugin plan §10.2" | plugin plan §10.2 | VERIFIED (§10.2 table 1–10) |
| 7 | "Cross-platform: Windows-via-Git-Bash or WSL2" at L192 | phased-plan §7.5 (L578) | PARTIAL — §7.5 says "Windows-via-Git-Bash" only; brief adds "or WSL2" (minor expansion, consistent with §5.6/§6.5 elsewhere in plan) |
| 8 | "Opus and Sonnet are different families for adversary-review purposes" | plugin plan §3 L173 | VERIFIED — source uses Opus/Sonnet as the canonical "different model family" example |
| 9 | "16 lifted principles" at L439 | plugin plan §3.1–§3.16 | VERIFIED |
| 10 | "Phase 7: 7-dimensional convergence assessment" at L197 | CLAUDE.md L57 | VERIFIED |

**Citation failures: 2 of 10** (citations 3 and 5). Both are paper-fix variants — F-7 fix and F-22 fix introduced new misalignments.

---

## Comments on Locked-Decision Coverage (post-amendment)

The locked-decisions frontmatter (L20–L42) was reviewed against body content:

- `skill_count_v0_9: 26` — verified at L222–L252
- `agent_count_v0_9: 14` — verified at L260–L276
- `hook_count_v0_x: 13` — verified at L283–L297
- `gh_action_count_total: 19` — verified at L301–L326 (6+9+4=19)
- `gh_action_count_committed: 15 (6 in v0.1, 9 in v0.5)` — verified
- `gh_action_count_community_optional: 4` — verified
- `self_vsdd: full-7-phase-in-v0_x` — verified at L197, L384
- `toolchain: bash + jq + yq + awk + bats + shellcheck + shfmt + Node 20+` — verified at L371; CLAUDE.md L5 amended to align
- `medium_v0_x_status: reference-extension-not-core` — verified at L183, L357, L487
- `v0_x_committed_platforms: [LinkedIn]` — verified at L181, L340

All frontmatter locked decisions align with body content. No frontmatter-body drift detected.

**Internal contradiction check:** L507 (Sibling references table) still references "v0.2.0 brief demotes Medium" — this is historical text not updated to "v0.3.0 brief still has Medium demoted." Minor narrative staleness; not load-bearing.

---

## Streak Decision

**RESET to 0/3.**

1 CRITICAL (F-NEW-1) + 3 IMPORTANT (F-NEW-2, F-NEW-3, F-NEW-4) findings. BC-5.39.001 requires zero (CRITICAL + IMPORTANT) findings for streak advancement. Streak does NOT advance.

**Recommended next action:** dispatch product-owner for a targeted v0.3.1 fix-burst addressing F-NEW-1 through F-NEW-4. Each fix is small and surgical:
- F-NEW-1: add one bullet to v0.1 ship gate criteria, OR soften L382's claim
- F-NEW-2: reconcile wclaude-absorption count between L136 and L441; pick one canonical inventory
- F-NEW-3: fix L252 parenthetical to acknowledge `research/` as a brain-factory addition beyond plan §A.2
- F-NEW-4: reword L126 "byte-identical stdout" to "matching verdicts (diff_count = 0)"

Plus suggestion-grade items (F-S-1 to F-S-5 below) at product-owner's discretion.

---

## Suggestions (non-blocking)

- **F-S-1 [SUGGESTION]:** L162 says "At least 13 skills present as `SKILL.md` files (the Phase 0/1 primitives)." "At least 13" is looser than the exact-13 commitment elsewhere; consider tightening to "All 13 Phase 0/1 primitive skills present" — more honest about what the v0.1 gate requires.
- **F-S-2 [SUGGESTION]:** L338 ("8 bats test suites" + meta-lint = 9) vs L439 ("8+ bats suites"). Reconcile to a single count, probably "9 bats suites including meta-lint" or "8 functional bats suites plus meta-lint."
- **F-S-3 [SUGGESTION]:** L507 sibling-reference text "v0.2.0 brief demotes Medium" is now historically stale (we're at v0.3.0). Either update or strike the version reference, OR add a note that the demotion is preserved in v0.3.0.
- **F-S-4 [SUGGESTION]:** L82 ("approximately 10 seconds") and L412 ("~100 sources, ~400K words") — verbatim citations from planning docs with `~`/`approximately`. Acceptable as quotations but consider whether to explicitly mark them as "Reported by [source]" rather than as brain-factory commitments. The F-7 sweep didn't catch these because they're descriptive, not commitments — but the smell pattern is identical.
- **F-S-5 [SUGGESTION]:** Open Question 2 (L469) says "Lock the default [adversary model] before Phase 1 spec crystallization" — but L380 already commits to "Opus and Sonnet are different families." The constraint at L380 is partly resolving OQ-2 inline. Consider either striking OQ-2 down to just "configurable via policies.yaml" (since the default is locked) or relaxing L380 to "the default in v0.x is Opus+Sonnet, configurable via `.brain/policies.yaml`."

---

## Top 3 Findings (one-line each)

1. **F-NEW-1 [CRITICAL]** — L382 promises a v0.1 ship gate bats test ("tail latency under load") that is not listed in the v0.1 ship gate enumeration (L159–L177). Paper-fix of F-7.
2. **F-NEW-3 [IMPORTANT]** — `briefs/research/` is committed at three locations as a `/brain:init` scaffold, but plan §A.2 enumerates only 5 `briefs/` subdirs (no `research/`); L252 citation "per plan §A.2" is misleading.
3. **F-NEW-2 [IMPORTANT]** — wclaude-absorption count drifts between "Four" (L136), 8 bullets (L138–L145), and 5 bullets (L445–L449) — three readings of the same absorption surface.

---

## Summary

**Pass 2 FAIL.** v0.3.0 made meaningful progress on Pass-1 issues — all 12 substantive Pass-1 issues from the dispatch prompt are at least structurally addressed, with 10 fully RESOLVED. But the fix-burst introduced **1 NEW CRITICAL** (smuggled v0.1 gate commitment around hook performance latency) and **3 NEW IMPORTANT** findings (wclaude count drift, `briefs/research/` plan §A.2 contradiction, §8.2.4 "byte-identical" overstatement). The frontmatter body coherence is solid: all locked-decision counts (26 skills, 14 agents, 13 hooks, 19 GH Actions, 10 policies) propagate consistently. The 7-phase / 6-dim disambiguation is clean. CLAUDE.md and brief are now in toolchain alignment. The Pass-1 paper-fix risk has materialized in exactly the location flagged by F-7 (the hook-performance commitment language) — the fix renamed `target <100ms` to `Performance budget: <100ms; v0.1 ship gate includes a bats test...` but did not add the test to the gate enumeration. Streak resets to 0/3. Recommend a focused v0.3.1 fix-burst addressing the 4 substantive findings (each is small and surgical, well under 50 lines of changes total), then Pass 3 dispatch.

---

**Final finding counts:**
- CRITICAL: 1 (F-NEW-1)
- IMPORTANT: 3 (F-NEW-2, F-NEW-3, F-NEW-4)
- SUGGESTION: 5 (F-S-1 through F-S-5)
- PROCESS-GAP: 0
- **Total blocking (CRITICAL + IMPORTANT): 4**

**Verdict:** FAIL
**Streak:** 0/3 (reset)
**Recommended next action:** dispatch `vsdd-factory:product-owner` for surgical v0.3.1 fix-burst targeting F-NEW-1 through F-NEW-4 (and optionally F-S-1 through F-S-5); then dispatch Pass 3 adversary with fresh context.
