---
artifact_type: adversary-pass-report
pass_number: 4
cascade: brain-factory-product-brief-v0.4.1
target_file: .factory/specs/product-brief.md
target_version: 0.4.1
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (RESET — Pass 4 FAIL)
created: 2026-05-15
author: vsdd-factory:adversary
inputs:
  - .factory/specs/product-brief.md (v0.4.1, 687 lines)
  - .factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1,2,3}.md
  - .factory/planning/elicitation-notes.md
  - .factory/planning/brief-research.md
  - .factory/planning/reference-repos.md
  - CLAUDE.md
  - docs/planning/llm-second-brain-plan.md (spot-checked §3.4)
finding_count_critical: 2
finding_count_important: 2
finding_count_suggestion: 3
finding_count_process_gap: 0
verdict: FAIL
paper_fix_pattern_observed: true
pass_3_blockers_resolved: 4
pass_3_blockers_paper_fixed: 2
---

# Adversary Pass 4 Report — brain-factory Product Brief v0.4.1

## Verdict

**FAIL.** The v0.4.1 fix-burst structurally resolved 4 of 6 Pass-3 blockers (F-NEW3-1 wiki types reconciled; F-NEW3-2 Liu/Nguyen reframed as wiki sizes; F-NEW3-4 wclaude arithmetic now matches bullet structure; F-PG3-1 self-audit bumped). However, **2 of 6 Pass-3 blockers remain paper-fixed**, not actually resolved: F-NEW3-3 (the "Stage 3 elicitation user-lock" disclosure introduces a NEW citation-form misrepresentation because the lock is not findable in `elicitation-notes.md`); F-NEW3-6 (the public-transition pre-v0.1 task contradicts the still-extant v0.1 gate item requiring authenticated `gh` for the wclaude clone — two adjacent v0.1 ship gate items now contradict each other). One NEW finding around `validate-frontmatter-schema.sh` hook scope mismatch was introduced by the v0.4.1 embedding_status fix. Streak resets to 0/3.

The paper-fix pattern Pass 3 detected (3 citation-form misrepresentations) is **still present in v0.4.1**: one of the Pass-3 fixes (F-NEW3-3) itself introduced a new citation-form issue, and another (F-NEW3-6) created an internal contradiction within the v0.1 gate enumeration.

---

## Pass 1 + Pass 2 + Pass 3 Resolution Audit

| Prior finding | Status in v0.4.1 | Evidence (line numbers) |
|---|---|---|
| **Pass 1 F-1** (Node 20+ contradiction) | RESOLVED | Frontmatter L25; body L128, L465 — toolchain consistent |
| **Pass 1 F-2** (Defuddle scope) | RESOLVED | L438 `scripts/defuddle-fetch.mjs`; L511 wrapper documented |
| **Pass 1 F-3** (run-skill.mjs role) | RESOLVED | L437 `scripts/run-skill.mjs` headless runner |
| **Pass 1 F-4** (~70-90% token savings) | RESOLVED | L511 "approximately 70–90% fewer tokens" with §2.4 citation |
| **Pass 1 F-7** (GH Actions count = 19) | RESOLVED | 19 total enumerated at L394-L419 (6+9+4=19) |
| **Pass 2 F-NEW-1** (hook-perf bats in v0.1 gate) | RESOLVED | L251 explicit `tests/hook-performance.bats` gate item with 100ms p99 budget |
| **Pass 2 F-NEW-2** (wclaude absorption count 8) | RESOLVED | §Family Positioning (L166-175, 8 bullets), §Prior Art (L550, sums to 8), sibling table (L657, sums to 8) all consistent |
| **Pass 2 F-NEW-3** (`briefs/research/` plan §A.2) | RESOLVED | L246 "brief-introduced extension beyond plan §A.2's five enumerated `briefs/` subdirs"; L345 propagated; L632 propagated |
| **Pass 2 F-NEW-4** ("byte-identical" → "matching verdicts") | RESOLVED | L153 "matching verdicts (diff_count = 0)" with §8.2.4 and §8.3 cited correctly |
| **Pass 3 F-NEW3-1** (wiki types reconciled to plan §3.4) | RESOLVED | L203 enumerates "concepts, people, frameworks, syntheses, observations, questions" per plan §3.4 canonical. L426 templates list propagates. Explicit note at L203: "`sources/` is a Layer-2 directory — it is NOT a wiki type." |
| **Pass 3 F-NEW3-2** (Liu/Nguyen citation form) | RESOLVED | L152 "Jim Liu (Obsidian-based wiki grew to ~35 pages...)"; L539-540 "Liu's 6-month report (Obsidian; ~35-page wiki accumulated)" — 35/77 now correctly framed as wiki sizes (pages accumulated), not document lengths |
| **Pass 3 F-NEW3-3** (scale-test sourcing) | **PAPER-FIXED** | L284 adds "brief-introduced via Stage 3 elicitation user-lock" preamble — but the lock is not recorded in elicitation-notes.md. See F-NEW4-1 |
| **Pass 3 F-NEW3-4** (wclaude arithmetic 4+4=8 wrong) | RESOLVED | L166 "four validation agents (one absorption group) plus seven individual pattern-and-flag absorptions = eight total"; L657 sibling table mirrors "1 absorption group + 7 individual pattern absorptions" — matches the 8-bullet enumeration |
| **Pass 3 F-NEW3-5** (embedding_status mandatory-vs-additive) | PARTIALLY RESOLVED | L221 now consistently says "MUST include" + "`validate-frontmatter-schema.sh` hook enforces presence" + default `pending`. Contradiction with "additive" framing is gone. But introduces NEW hook-scope mismatch — see F-NEW4-3 |
| **Pass 3 F-NEW3-6** (wclaude public-transition) | **PAPER-FIXED** | L257 adds "Owner pre-v0.1 task: make drbothen/wclaude public" but L256 (the immediately preceding v0.1 gate item) still says "wclaude clone requires authenticated `gh`" — two adjacent v0.1 gate items now contradict each other. See F-NEW4-2 |
| **Pass 3 F-PG3-1** (Self-Audit bumped to v0.4.0/v0.4.1) | RESOLVED | L678 mentions "v0.4.0/v0.4.1 edits verified" and L687 cross-checks new fields including `wclaude_repo_status` |

**Net:** 4 of 6 Pass-3 blockers genuinely fixed; 2 paper-fixed; 1 partially resolved with new sub-issue. All Pass 1 and Pass 2 fixes remain intact.

---

## New Findings (introduced by v0.4.1 fix-burst)

### F-NEW4-1 [CRITICAL] — "Stage 3 elicitation user-lock" citation not findable in elicitation-notes.md

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L284 (v0.9 scale test source-attribution preamble)
- **Source claimed:** `elicitation-notes.md` Stage 3 user-lock
- **Confidence:** HIGH

L284 attempts to fix F-NEW3-3 by disclosing source attribution:
> "**Source attribution:** The following 6 pass criteria are **brief-introduced via Stage 3 elicitation user-lock** (user selected 'Discipline + measured v0.9 scale test' and 'Power-user scale: ~10K sources / ~40M words / ~10K wiki pages' — 10x Karpathy's reported scale per plan.md §2.1). The planning docs do NOT specify these exact numbers; the brief introduces them as production-grade SLAs derived from the user's locked scale target."

I ran `Grep -nE "scale|10K|10,000|40M|power"` against `elicitation-notes.md`. **The file contains zero matches for "10K", "10,000", "40M", "power-user", "scale target", "scale test", or "scale gate".** The only "scale" reference at L418/L570 is Karpathy's own reported scale (~100 sources, ~400K words, hundreds of pages) — not a 10x power-user lock by the user.

The brief's L284 citation form claims a lock occurred during Stage 3 elicitation. But the **persisted Stage 3 elicitation record contains no such lock**. Either:
- The lock occurred verbally and was not recorded in elicitation-notes.md (process gap: the F-NEW3-3 fix relied on an undocumented elicitation event)
- The lock did not occur and the brief is fabricating a source attribution (paper-fix masquerading as source attribution)
- The lock is recorded somewhere not in elicitation-notes.md (citation-form misrepresentation — cite must point to the actual persistence location)

**Why this matters:** This is the same citation-form misrepresentation pattern Pass 3 caught (F-NEW3-1, F-NEW3-2, F-NEW3-3). The fix-burst replaced one citation-form misrepresentation with another. A reader trying to validate that the user did lock "Power-user scale: ~10K sources" will follow the citation, look in elicitation-notes.md, find nothing, and conclude the brief is making up source attribution.

The fact that L284 explicitly says "The planning docs do NOT specify these exact numbers" is correct disclosure of the gap, but invoking "Stage 3 elicitation user-lock" as the source without that lock being findable in the elicitation record is the misrepresentation. A real fix would cite the actual lock location (a session log? a separate stage-3-lock.md? the brief prompt §scale-lock?) or say "brief-introduced with user-confirmation pending re-record in elicitation-notes.md."

**Fix:** Either (a) update `elicitation-notes.md` to record the Stage 3 scale-target lock and cite the specific section/Q-number, (b) replace "Stage 3 elicitation user-lock" with the actual lock document (e.g., "brief-prompt §scale-target-lock" if that's where it lives), or (c) downgrade to "brief-introduced, awaiting Stage 3 confirmation re-record."

### F-NEW4-2 [CRITICAL] — Two adjacent v0.1 ship gate items contradict each other on wclaude visibility

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L256 and L257 (both inside v0.1 ship gate enumeration)
- **Confidence:** HIGH

L256 (v0.1 ship gate criterion):
> "wclaude clone requires authenticated `gh` (`gh repo clone drbothen/wclaude`) — this requirement documented in the MANIFEST."

L257 (v0.1 ship gate criterion, immediately following):
> "**Owner pre-v0.1 task: make drbothen/wclaude public.** Run `gh repo edit drbothen/wclaude --visibility public` **before tagging v0.1.0**."

These two items are **mutually exclusive** as written:

- If L257 holds (wclaude is made public **before** the v0.1.0 tag is cut), then at the moment v0.1.0 ships, `gh repo clone drbothen/wclaude` does **NOT** require authentication. L256's "authenticated `gh`" requirement is false at v0.1 ship time.
- If L256 holds (wclaude is still private and clone requires authentication at v0.1 ship time), then L257's pre-v0.1 task was not run before tagging — the v0.1 ship gate has not been satisfied.

The F-NEW3-6 fix added L257 to address the contributor-reproducibility blocker, but **did not update L256 to reflect the post-transition state**. After the public-transition runs, the MANIFEST entry should say "wclaude is public; clone with unauthenticated `gh`" — not "wclaude clone requires authenticated `gh`."

Additionally, L576 (Reference Repositories §2 wclaude entry) has a more nuanced phrasing: "currently private as of May 2026; public-transition committed as v0.1 ship gate task — **after transition, `gh repo clone drbothen/wclaude` works without owner credentials**". L576 correctly reflects the post-transition state, but L256 in the v0.1 ship gate still uses pre-transition phrasing. **The v0.1 gate enumeration is internally inconsistent.**

L588 (devops-engineer bootstrap task) also still says "wclaude clone requires `gh auth login` with owner credentials" — same pre-transition phrasing as L256, contradicting the post-transition state at L576 and L257.

**Sibling-sweep failure:** The F-NEW3-6 fix added the public-transition task but did not sibling-sweep the dependent statements at L256, L588, L657. The blast radius (L256, L257, L576, L588, L657) was not fully propagated.

**Fix:** Reword L256 to reflect the post-transition state: "`.reference/` directory bootstrapped with 7 reference repos cloned (vsdd-factory, wclaude (public post-transition per next gate item), defuddle, obsidian-skills, quartz, karpathy-llm-wiki, llm-wiki-skill). Clones use unauthenticated `gh` once wclaude transition is complete." Apply the same fix to L588 devops-engineer bootstrap text.

### F-NEW4-3 [IMPORTANT] — `validate-frontmatter-schema.sh` hook scope mismatch between §Scalability and §Hooks enumeration

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L221 (Scalability §6 hook commitment) vs L383 (13-hooks enumeration)
- **Confidence:** HIGH

L221 (Scalability §6 embedding_status commitment):
> "**`validate-frontmatter-schema.sh` hook enforces presence** (PostToolUse on Write|Edit to `wiki/*.md`)"

L383 (Scope §13 bash hooks enumeration, hook #8):
> "`validate-frontmatter-schema.sh` (PostToolUse, Write|Edit on **wiki/* or sources/***)"

The two scopes don't match:
- L221 says the hook fires on `wiki/*.md` only.
- L383 says the hook fires on `wiki/*` **or** `sources/*`.

This creates two contradictory implementations:
1. If L221 is authoritative (wiki/*.md only), then L383's matcher is wrong and the hook list overcounts file-scope.
2. If L383 is authoritative (wiki/* or sources/*), then the hook also fires on `sources/*` writes — and the brief never specifies whether `embedding_status` is required in source-file frontmatter (L221 only mandates it for wiki pages). The hook would then either: (a) fail every source-file write with a missing-embedding_status error, OR (b) the hook enforces something different on source files than on wiki files — but the brief is silent on what.

Additionally, the v0.4.1 fix made `embedding_status` mandatory on **every wiki page from v0.1 onward**, but the v0.1 ship gate (L237-L257) contains no item that validates `validate-frontmatter-schema.sh` actually enforces `embedding_status` presence. The hook-perf bats test at L251 covers performance budget, not field-presence. A new mandatory-field commitment without a gate item to validate it is a smuggled commitment.

**Fix:** (a) Reconcile L221 and L383 — pick one canonical scope. If wiki+sources, specify what `validate-frontmatter-schema.sh` enforces on each scope (presumably different field sets per layer). (b) Add a v0.1 ship gate criterion: "`validate-frontmatter-schema.sh` rejects wiki page writes lacking `embedding_status` frontmatter field (positive + negative bats coverage at v0.1)."

### F-NEW4-4 [IMPORTANT] — Hook performance budget bats test scope doesn't account for embedding_status check overhead

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L197 (Scalability §2 hook-perf commitment) and L251 (v0.1 ship gate hook-perf test)
- **Confidence:** MEDIUM

L197 commits:
> "Hook performance budget: every hook in the 13-hook set processes its sample payload in under 100ms p99 — asserted in `tests/hook-performance.bats` as a v0.1 ship gate."

L251 commits:
> "every hook in the 13-hook set processes its sample payload in under 100ms p99."

These commitments were made **before** the v0.4.1 fix made `embedding_status` mandatory and gave `validate-frontmatter-schema.sh` a new responsibility. The pre-v0.4.1 hook checked some subset of frontmatter; the v0.4.1 hook also checks `embedding_status` presence. The 100ms p99 budget was set against the prior hook scope and was not re-validated against the new mandatory-field check.

This is unlikely to push the hook over 100ms (a single field-presence check via yq is fast), but the brief doesn't explicitly re-confirm the budget against the expanded hook scope. This is a smaller version of the F-NEW-1 paper-fix pattern from Pass 2: a commitment was changed without the dependent gate being re-validated.

**Fix:** Add a brief disclosure: "Note: the 100ms p99 budget at L251 is asserted against the v0.4.1 hook scope (which includes `embedding_status` presence-check for `validate-frontmatter-schema.sh`); budget was re-validated post-fix."

---

## Suggestions (non-blocking)

- **F-S4-1 [SUGGESTION]:** L256 v0.1 ship gate says "Cloned via direct clone — not git submodules — matching prism's `.references/` pattern". The phrase "matching prism's" is a forward-reference to a verification not made in this document. Either (a) inline the prism check evidence (or remove "matching prism's" and just say "direct clones, not git submodules"), or (b) cite `.factory/planning/reference-repos.md` §1.4 if that's where the prism check is recorded.

- **F-S4-2 [SUGGESTION]:** L515 says "7 public implementations as of May 2026" but L149 says "7 public implementations as of May 2026 — including three Claude Code skill packages..., Farzapedia (Karpathy-endorsed, private repo / gist public), Spisak's reference implementation, nashsu's desktop application, and rohitg00's v2 gist". Enumerating Farzapedia as one of the "7 public implementations" while parenthetically noting its repo is private is a small framing tension — Farzapedia is partially public (only the gist) but not the implementation itself. Consider rewording to "7 publicly-documented implementations" or "7 known implementations (Farzapedia public via gist only)".

- **F-S4-3 [SUGGESTION]:** L658 sibling references table still references "v0.2.0+ brief demotes Medium to reference extension (deprecated API, preserved through v0.3.1)". The phrase "preserved through v0.3.1" is now stale at v0.4.1 — should be "preserved through v0.4.1" or "still preserved at v0.4.1". Same staleness pattern as Pass-2 F-S-3.

---

## Count Reconciliation

| Claim | Stated | Verified | Status |
|---|---|---|---|
| 26 skills | 26 (13 + 12 + 1) | 26 (L315–L345 enumeration) | PASS |
| 14 agents | 14 (10 + 4) | 14 (L353–L369 enumeration) | PASS |
| 13 hooks | 13 (12 + 1) | 13 (L376–L390 enumeration) | PASS |
| 19 GH Actions | 19 (15 + 4) | 19 (L396–L419 enumeration) | PASS |
| 10 policies | 10 | 10 (L428) | PASS |
| 9 bats suites | 9 (8 functional + meta-lint) | 9 (L431) | PASS |
| 7 topic categories | 7 (ai/health/psych/prod/biz/books/podcasts) | 7 (L427) | PASS |
| 8 wclaude absorptions | 8 (1 group + 7 individual) | 8 (L166-175, 8 bullets); L657 sums to 1+7=8; L550 summary sums to 8 | PASS |
| 7 reference repos cloned | 7 | 7 (L572-586) | PASS (with anthropics/claude-code as deferred-optional 8th at L588) |
| 6 wiki types | 6 (concepts/people/frameworks/syntheses/observations/questions) | 6 (L203, L426 templates list) | PASS (now consistent with plan §3.4 — F-NEW3-1 resolved) |
| 7 Karpathy implementations | 7 | 7 (L149: Astro-Han + lewislulu + kfchou + Farzapedia + Spisak + nashsu + rohitg00) | PASS |

All counts reconcile. F-NEW3-1's structural fix is genuine.

---

## Citation Spot-Check Audit (5 NEW or recently-edited v0.4.1 citations)

| # | Citation in Brief | Source | Verdict |
|---|---|---|---|
| 1 | L284 "brief-introduced via Stage 3 elicitation user-lock" → elicitation-notes.md | elicitation-notes.md | **FAILS** — no "10K", "10,000", "40M", "power-user", "scale target", "scale test", or "scale gate" matches in elicitation-notes.md. Lock not findable. See F-NEW4-1 |
| 2 | L203 "6 wiki types per plan.md §3.4: concepts, people, frameworks, syntheses, observations, questions" | plan.md §3.4 (L201-208) | VERIFIED — exact match to plan §3.4 canonical list |
| 3 | L152, L539-540 "Liu... 35-page wiki accumulated; Nguyen... 77-page wiki" | brief-research.md §2.3 (L128-129) | VERIFIED — source frames 35/77 as wiki page counts, brief now matches |
| 4 | L256-L257 wclaude pre-v0.1 public transition gate | reference-repos.md §1.2 (L77-94) | PARTIAL — public-transition task itself is consistent with reference-repos.md's framing (private, owner-confirmed), but L256-L257 are internally contradictory as v0.1 ship gate criteria. See F-NEW4-2 |
| 5 | L221 "validate-frontmatter-schema.sh hook enforces presence (PostToolUse on Write|Edit to wiki/*.md)" | brief L383 (same hook, different scope claim) | **FAILS** — same hook, two different scopes (wiki/* only vs wiki/* or sources/*) within the same document. See F-NEW4-3 |

**Citation failures: 2 of 5** (citations 1 and 5). One is an external-source-attribution misrepresentation; one is an internal-self-citation inconsistency. The paper-fix pattern Pass 3 detected (3 citation-form misrepresentations) has dropped from 3 to 1 external-source case but added 1 internal-self-citation case — net pattern still present.

---

## Locked-Decision Coverage (post-v0.4.1)

All 25 frontmatter `locked_decisions` fields reviewed:

- `primary_user`, `secondary_user`, `mvp_target`, `v1_commitment` — verified against §Vision and §Target Users
- `toolchain: bash + jq + yq + awk + bats + shellcheck + shfmt + Node 20+` — verified L465; consistent
- `skill_count_v0_9: 26` / `agent_count_v0_9: 14` / `hook_count_v0_x: 13` — verified against enumerations
- `gh_action_count_total: 19` / `committed: 15` / `community_optional: 4` — verified against L394-L419
- `lobster_runtime: bash-interpreter-in-v0_x` — verified L423
- `self_vsdd: full-7-phase-in-v0_x` — verified L278, L478
- `publish_platforms`, `v0_x_committed_platforms`, `medium_v0_x_status`, `perf_tracking`, `content_types_v0_x` — verified
- `marketplace: drbothen/claude-mp` — verified L162, L252, L500
- `license: MIT` — verified L500
- `cross_platform` — verified L479
- `wclaude_absorption: patterns-and-agents-merged-into-existing-plan` — verified §Family Positioning + §Prior Art
- `wclaude_repo_status: transitioning-private-to-public-before-v0.1` — verified L164, L257, L576 — but L256 and L588 contain stale pre-transition phrasing. **Frontmatter-body coherence DRIFT** on this field (see F-NEW4-2)
- `scale_target_v0_9: power-user (~10000 sources / ~40M words / ~10000 wiki pages)` — verified at L154, L185, L480 — but the locked decision itself has no citation to the elicitation record (see F-NEW4-1)
- `scale_test_v0_9_gate: required` — verified at L282-L293 — criteria themselves have citation-form gap (see F-NEW4-1)
- `team_brain_scale: out-of-scope-v0_x-and-v1_0` — verified L452, L481
- `reference_repo_count: 7` — verified L256, L572
- `reference_repo_layout: .reference/ (singular, direct clones not git submodules)` — verified L570

**Frontmatter-body drift detected on:** `wclaude_repo_status` (L256 and L588 still reflect pre-transition state, contradicting L257 which commits to the transition). This is F-NEW4-2.

---

## Streak Decision

**RESET to 0/3.**

2 CRITICAL (F-NEW4-1 Stage 3 lock citation misrepresentation; F-NEW4-2 internal v0.1 gate contradiction) + 2 IMPORTANT (F-NEW4-3 hook scope mismatch; F-NEW4-4 hook-perf budget not re-validated against new scope). BC-5.39.001 requires zero (CRITICAL + IMPORTANT) findings for streak advancement.

**The paper-fix pattern Pass 3 flagged has continued into v0.4.1.** The F-NEW3-3 fix introduced a new citation-form misrepresentation (Stage 3 lock not findable in elicitation-notes.md). The F-NEW3-6 fix introduced an internal contradiction (L256 vs L257 within the same v0.1 ship gate enumeration). Two of six Pass-3 fixes are surface-level edits that don't structurally resolve the underlying issue.

---

## Top 3 Findings (one-line each)

1. **F-NEW4-1 [CRITICAL]** — L284 cites "Stage 3 elicitation user-lock" for the v0.9 scale-test criteria, but the lock is not findable in `elicitation-notes.md` (zero matches for "10K", "power-user", "scale target"). Same citation-form misrepresentation pattern Pass 3 caught — F-NEW3-3 fix replaced one paper-fix with another.
2. **F-NEW4-2 [CRITICAL]** — L256 ("wclaude clone requires authenticated `gh`") and L257 ("Owner pre-v0.1 task: make drbothen/wclaude public before tagging v0.1.0") are two adjacent v0.1 ship gate criteria that contradict each other. After the L257 task runs, L256's authentication requirement is false. Sibling-sweep failure: L588 also still reflects pre-transition state.
3. **F-NEW4-3 [IMPORTANT]** — `validate-frontmatter-schema.sh` hook scope is "Write|Edit to `wiki/*.md`" at L221 but "Write|Edit on `wiki/* or sources/*`" at L383 — same hook, two different scope claims within the same document. The v0.4.1 fix to make `embedding_status` mandatory didn't reconcile these.

---

## Summary

**Pass 4 FAIL.** v0.4.1's fix-burst (+6 lines net over v0.4.0) genuinely resolved 4 of 6 Pass-3 blockers (F-NEW3-1 wiki types canonical to plan §3.4; F-NEW3-2 Liu/Nguyen reframed as wiki sizes; F-NEW3-4 wclaude arithmetic 1+7=8 consistent; F-PG3-1 self-audit bumped to v0.4.1). But **2 of 6 are paper-fixed**: F-NEW3-3 replaced one citation-form gap with another (Stage 3 elicitation lock not findable in elicitation-notes.md), and F-NEW3-6 created a new internal contradiction within the v0.1 ship gate (L256 vs L257) plus a sibling-sweep failure at L588. F-NEW3-5 (embedding_status mandatory-vs-additive) was partially resolved but introduced a new hook-scope mismatch (L221 vs L383) and a smuggled gate commitment (the new mandatory field has no v0.1 gate validation).

Pass 1 and Pass 2 fixes all remain intact. All quantitative counts (26 skills, 14 agents, 13 hooks, 19 GH Actions, 10 policies, 9 bats suites, 7 topic categories, 8 wclaude absorptions, 7 reference repos, 6 wiki types per plan §3.4, 7 Karpathy implementations) reconcile correctly. The structural improvements are real; the residual issues are at the citation-form and sibling-sweep level.

The paper-fix pattern Pass 3 detected — surface edits that don't structurally resolve the underlying issue — is **still active in v0.4.1**. Each round's fix-burst is introducing at least one new defect of the same class it was trying to fix.

Streak resets to 0/3. Recommend a focused v0.4.2 fix-burst:
- F-NEW4-1: Either update `elicitation-notes.md` to record the Stage 3 scale-target lock with specific Q-number, OR replace "Stage 3 elicitation user-lock" with the actual lock source location (brief prompt? session log?), OR downgrade to "brief-introduced with user-confirmation pending re-record in elicitation-notes.md."
- F-NEW4-2: Reword L256 to reflect post-transition state ("wclaude clone uses unauthenticated `gh` once public-transition is complete"); update L588 devops-engineer bootstrap text to the same; ensure all wclaude-clone-related items in the v0.1 ship gate enumeration are consistent with L257's pre-transition commitment.
- F-NEW4-3: Reconcile L221 and L383 — pick one canonical scope for `validate-frontmatter-schema.sh`. If both wiki/* and sources/*, specify what fields the hook enforces on each scope.
- F-NEW4-4: Add a v0.1 ship gate criterion that validates `validate-frontmatter-schema.sh` rejects wiki page writes lacking `embedding_status` frontmatter field (positive + negative bats coverage at v0.1).

Total fix surface: probably 20-40 lines of changes. After fix-burst, dispatch Pass 5 with fresh context.

---

## Structured Summary for Orchestrator

```yaml
target_file: .factory/specs/product-brief.md
target_version: 0.4.1
pass_number: 4
finding_counts:
  critical: 2
  important: 2
  suggestion: 3
  process_gap: 0
  total_blocking: 4
verdict: FAIL
streak_before: 0/3
streak_after: 0/3 (RESET)
recommended_next_action: dispatch vsdd-factory:product-owner for surgical v0.4.2 fix-burst (F-NEW4-1 through F-NEW4-4), then Pass 5 adversary dispatch with fresh context
critical_finding_ids: [F-NEW4-1, F-NEW4-2]
important_finding_ids: [F-NEW4-3, F-NEW4-4]
suggestion_finding_ids: [F-S4-1, F-S4-2, F-S4-3]
process_gap_finding_ids: []
paper_fix_pattern_observed: true
paper_fix_evidence: "v0.4.1 fix-burst resolved 4 of 6 Pass-3 blockers structurally but paper-fixed 2 — F-NEW3-3 fix introduced a new citation-form misrepresentation (Stage 3 elicitation lock not findable in elicitation-notes.md); F-NEW3-6 fix introduced an internal v0.1 gate contradiction (L256 still requires authenticated gh after L257 commits to making wclaude public before v0.1 tag); F-NEW3-5 fix introduced a new hook-scope mismatch (L221 vs L383) and a smuggled gate commitment (mandatory field with no v0.1 validation)"
pass_3_blockers_resolved: 4
pass_3_blockers_paper_fixed: 2
new_paper_fix_findings: [F-NEW4-1, F-NEW4-2, F-NEW4-3]
sibling_sweep_failures:
  - "F-NEW4-2: F-NEW3-6 fix updated L257 and L576 but did not update L256 and L588"
```
