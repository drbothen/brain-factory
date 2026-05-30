---
artifact_type: adversary-pass-report
pass_number: 3
cascade: brain-factory-product-brief-v0.4.0
target_file: .factory/specs/product-brief.md
target_version: 0.4.0
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (RESET — Pass 3 FAIL)
created: 2026-05-15
author: vsdd-factory:adversary
inputs:
  - .factory/specs/product-brief.md (v0.4.0, 681 lines)
  - .factory/cycles/v0.1-phase-1a-brief/adversary-pass-1.md
  - .factory/cycles/v0.1-phase-1a-brief/adversary-pass-2.md
  - .factory/planning/reference-repos.md
  - .factory/planning/brief-research.md
  - CLAUDE.md (Node 20+ amended)
  - docs/planning/llm-second-brain-plan.md (spot-checked §3.3, §3.4, §2.1)
  - docs/planning/llm-second-brain-phased-build-plan.md (spot-checked §A.2, §5.11, §A.4)
finding_count_critical: 2
finding_count_important: 4
finding_count_suggestion: 4
finding_count_process_gap: 1
verdict: FAIL
paper_fix_pattern_observed: true
---

# Adversary Pass 3 Report — brain-factory Product Brief v0.4.0

## Verdict

**FAIL.** Pass 2 fixes are structurally intact — F-NEW-1 (hook-performance bats test) propagated to v0.1 ship gate L241; F-NEW-2 (wclaude count 8) reconciled across §Family Positioning, §Prior Art, sibling table; F-NEW-3 (`briefs/research/` framing as brain-factory extension) clean at L236, L331, L625; F-NEW-4 ("matching verdicts" not "byte-identical") clean at L143. But the v0.4.0 expansion (+140 lines) introduced **2 NEW CRITICAL findings** and **4 NEW IMPORTANT findings**. The most severe is a wiki-types enumeration contradiction with plan §3.4 that would mislead implementers (F-NEW3-1). Streak resets to 0/3.

---

## Pass 1 + Pass 2 Resolution Audit

| Prior finding | Status in v0.4.0 | Evidence |
|---|---|---|
| **Pass 1 F-1** (Node 20+ contradiction) | RESOLVED | Frontmatter L25 `toolchain: ...+ Node 20+`; CLAUDE.md aligned |
| **Pass 1 F-2** (Defuddle scope) | RESOLVED | L451 `scripts/defuddle-fetch.mjs`; L497 wrapper documented |
| **Pass 1 F-3** (run-skill.mjs role) | RESOLVED | L423 `scripts/run-skill.mjs` headless runner for GH Actions |
| **Pass 1 F-4** (~70-90% token savings) | RESOLVED | L497 "approximately 70–90% fewer tokens" with §2.4 citation |
| **Pass 1 F-7** (GH Actions count) | RESOLVED | 19 total enumerated at L382–L405 (6+9+4=19) |
| **Pass 2 F-NEW-1** (hook-perf bats in v0.1 gate) | RESOLVED | L241 adds explicit `tests/hook-performance.bats` gate item with 100ms p99 budget |
| **Pass 2 F-NEW-2** (wclaude absorption count 8) | PARTIALLY RESOLVED | §Family Positioning bullets (8), §Prior Art bullets (8), sibling table (8). But parenthetical arithmetic "(4 + 4)" wrong — see F-NEW3-4 below |
| **Pass 2 F-NEW-3** (`briefs/research/` plan §A.2) | RESOLVED | L236 "brief-introduced extension beyond plan §A.2's five enumerated `briefs/` subdirs"; L331 propagated; L625 propagated |
| **Pass 2 F-NEW-4** ("byte-identical" → "matching verdicts") | RESOLVED | L143 reworded to "matching verdicts (diff_count = 0)" with both §8.2.4 and §8.3 cited correctly |

**Net:** 4 prior CRITICAL + 4 prior IMPORTANT all resolved. F-NEW-2 (wclaude count) carries a residual arithmetic-decomposition error reported below as new F-NEW3-4.

---

## New Findings (introduced by v0.4.0 expansion)

### F-NEW3-1 [CRITICAL] — Wiki types enumeration contradicts plan §3.4

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L193 (Scalability Design Principles §3 — "6 wiki types: concepts, entities, sources, synthesis, projects, reflections")
- **Source:** `docs/planning/llm-second-brain-plan.md:203-208`
- **Confidence:** HIGH

The brief's new Scalability Design Principles §3 (L193) commits to wiki taxonomy:
> "`wiki/` uses `wiki/{type}/{slug}.md` (6 wiki types: concepts, entities, sources, synthesis, projects, reflections)"

Plan §3.4 explicitly enumerates the 6 wiki types as:
> "`concepts/`, `people/`, `frameworks/`, `syntheses/`, `observations/`, `questions/`"

These are **different sets**. Only `concepts/` overlaps. The brief replaces 5 of the 6 plan-canonical types with an entirely different taxonomy that appears borrowed from a competing implementation (NicholasSpisak/second-brain uses `sources/`, `entities/`, `concepts/`, `synthesis/`; or nashsu/llm_wiki uses `entities/`, `concepts/`, `sources/`, `synthesis/`, `comparisons/`, `queries/`).

Additionally, **internal contradiction within the brief**: L193 names `sources` as a wiki type at `wiki/{type}/{slug}.md`, but `sources/` is a separate LAYER 2 directory holding immutable source records (L193 also commits to `sources/{topic}/`). Same word, two incompatible roles: cannot be both a top-level layer AND a wiki type.

**Compounding contradiction with the traceability table at L641:** the traceability table cites plan.md §3.1–3.7 for "six wiki types" — implying the brief's 6 types are sourced from the plan. They are not. This is the same citation-form misrepresentation pattern Pass 1 and Pass 2 caught: the brief claims plan support that the plan does not provide.

**Implementer impact:** Phase 1b BC writers depend on the brief's enumeration to scaffold `wiki/{type}/` subdirectories. If the brief specifies `entities/sources/synthesis/projects/reflections` while the plan specifies `people/frameworks/syntheses/observations/questions`, every wiki-type-related BC will be wrong. `/brain:ingest-url` skill body cannot route into both taxonomies. `/brain:init` cannot scaffold both. The Scalability §3 commitment promises "this layout can handle 10K+ files with no structural change" — but the layout itself is inconsistent with the methodology source.

**Fix:** Reconcile L193's wiki taxonomy with plan §3.4's canonical 6 types, OR document explicitly (like the `briefs/research/` case at L236) that brain-factory is **extending** plan §3.4 with a different taxonomy as a deliberate scope choice. The current form is silent substitution.

### F-NEW3-2 [CRITICAL] — Liu/Nguyen citation form misrepresents source nature

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L142 ("Liu 35-page audit; Nguyen 77-page production report"); L525 ("Liu (35-page audit, ~6 months with Obsidian)"); L526 ("Nguyen (77-page production report, ~6 months on AWS ops)")
- **Source:** `.factory/planning/brief-research.md:128-129`
- **Confidence:** HIGH

The brief at L142 cites the Liu and Nguyen reports as evidence for the cognitive-diversity adversarial-review differentiator. L525-526 then formally describes them as "35-page audit" and "77-page production report".

The research source (brief-research.md §2.3) actually says:
> "Jim Liu (Obsidian, **35 pages**, ~6 months): ran the pattern in Obsidian with Claude as editor"
> "Tom Nguyen (production AWS ops, **77 pages**, 30+ sources, 13 custom skills, ~6 months)"

"35 pages" and "77 pages" in the research doc refer to **the size of Liu's and Nguyen's WIKIS** (i.e., the number of wiki pages they accumulated over 6 months) — **not the length of an audit document or production report they authored**. Liu's source is a blog post on openaitoolshub.org; Nguyen's source is a Medium post — both of indeterminate length but neither is a "35-page audit" or "77-page report".

The brief reframes "35 pages" as the **size of an audit document** ("35-page audit") and "77 pages" as the **size of a production report** ("77-page production report"). This is citation-form misrepresentation: the source provides one fact (wiki size at 6 months), the brief states a different fact (audit/report length).

**Why this matters:** "35-page audit" and "77-page production report" sound like authoritative, in-depth documents — the kind that would lend weight to the differentiator-#2 claim. The actual sources are blog posts. A reader (or future implementer in Phase 4 holdout evaluation, or a Phase 1b BC writer relying on the differentiator-#2 anchor) who follows the citation expecting to find a 35-page audit will instead find a blog post and an Obsidian vault of 35 pages, and the credibility argument collapses.

**Fix:** Reword L142 and L525-526 to accurately describe the source: "Liu's 6-month report (Obsidian wiki at 35 pages)" / "Nguyen's 6-month practitioner report (AWS-ops wiki at 77 pages, 30+ sources, 13 skills)". The wiki-size detail is interesting and load-bearing for the scale argument; conflating it with audit/report length is the error.

### F-NEW3-3 [IMPORTANT] — v0.9 scale test commitments lack any planning-doc citation

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L271-279 (Scale test at power-user tier in v0.9 ship gate)
- **Source:** None — no planning doc cited for any of the 6 pass criteria
- **Confidence:** HIGH

The new v0.9 scale test gate at L271-279 commits to 6 measurable pass criteria:
1. `/brain:ingest-url` retrieval-plus-wiki-write latency stays sub-linear
2. `/brain:lint-wiki` full health pass under 10 minutes on 10K-page wiki
3. GH Actions process 100 sources/day sustained over 5 days
4. Peak resident memory <2GB
5. Per-ingest cost ≤150K input tokens (3x the 50K baseline)
6. Synthetic corpus via `scripts/gen-test-corpus.sh`

**None of these criteria is cited to any planning document.** The brief is inventing them in scope. Plan.md §1 only says: "Karpathy's reported scale: ~100 sources, ~400K words, ~hundreds of pages... Beyond that scale, semantic retrieval starts to matter." Plan.md §2120 says: "Scale ceiling. Index-first navigation works through ~100 sources / ~hundreds of pages. Beyond, you need tiered retrieval." The planning docs do NOT commit to a 10K-source scale test, do NOT define a 10-minute lint budget, do NOT name a 2GB memory ceiling, do NOT specify a 150K-token-per-ingest ceiling, and do NOT mention `scripts/gen-test-corpus.sh`.

Additionally, **`scripts/gen-test-corpus.sh` is a NEW commitment** introduced by the brief without prior basis. It must be designed, written, tested, and maintained. The brief commits at L277 that "the script generates N source files with randomized content from a seed, plus a pre-built `manifest.json` representing the state after N-1 ingests" — that's a substantial sub-project. Who builds it? Which phase? It's referenced as a v0.9 gate dependency but doesn't appear in any earlier phase's deliverables list. There's no story for it.

The L279 disclaimer ("This scale test **supplements** phased plan §7.5's exit criteria; it does not replace any of the existing v0.9 gate items") is necessary but insufficient. Pass 2's F-NEW-1 paper-fix pattern applies: the brief is smuggling 6 new commitments into the v0.9 gate without source attribution AND without explicit disclosure that **all 6 criteria are brief-introduced** (not just one).

**Also problematic:** the scale test conflicts with the v0.x resource framing. L482 commits to "Single-author dogfood for Phases 0–2 (Josh Magady)" and L264 commits to "Author has used the plugin daily for at least 8 weeks." If 10K sources is the scale gate, how does single-author daily-dogfood generate 10K real sources in 8 weeks? Answer: it doesn't — the synthetic corpus is the workaround. But that means the v0.9 gate is **partially synthetic**, while the v0.9 self-VSDD convergence framing (L267) implies real-world dogfood validation. The two framings coexist but the brief doesn't reconcile them.

**Fix:** Either (a) cite the source for each scale-test criterion (most are brief-introduced; mark them explicitly), (b) cut criteria back to those with planning-doc grounding plus an explicit "additional brief-introduced criteria" subsection, or (c) move the entire scale test to a separate `.factory/specs/` artifact and reference it from the brief rather than inline.

### F-NEW3-4 [IMPORTANT] — wclaude absorption arithmetic "(4 + 4 = 8)" is mathematically inconsistent with bullet enumeration

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L156 ("four validation agents plus four pattern-and-flag absorptions"); L650 sibling table ("(4 validation agents + 4 pattern-and-flag absorptions)")
- **Confidence:** HIGH

L156 introduces the absorption inventory:
> "**Eight wclaude content-publishing plugin patterns** (four validation agents plus four pattern-and-flag absorptions)..."

L650 sibling table mirrors this:
> "8 patterns absorbed (4 validation agents + 4 pattern-and-flag absorptions)"

The body bullet list at L158-165 actually contains **8 bullets**:
1. (one bullet covering all 4 validation agents) — 1 bullet
2. Writescore + revision-loop — 1
3. `--finalize --url` flag — 1
4. Frontmatter state machine — 1
5. drafts/to-publish/published directory — 1
6. `--companion-posts` flag — 1
7. `--schedule <date>` flag — 1
8. `--hero-prompt` flag — 1

Total: 1 (agent group) + 7 (patterns) = 8 bullets.

The parenthetical "(four validation agents plus four pattern-and-flag absorptions)" only adds up to 8 if "four validation agents" is counted as **4 separate absorptions** (each agent = 1 absorption). But then "four pattern-and-flag absorptions" should be **seven** (the 7 individual pattern bullets), not four. With the current arithmetic, 4+4=8 but the bullet list documents 1+7=8.

The §Prior Art section at L538-545 has the same mismatch: 1 bullet for "4 validation agents" + 7 bullets for individual patterns = 8 bullets, but the framing implies "4 + 4".

This is a **count drift between framing prose and enumeration body**. Pass 2 F-NEW-2 fixed the gross count (Pass 2 saw "Four"/"Eight"/"Five"); Pass 3 finds the residual arithmetic decomposition still inconsistent.

**Fix:** Either (a) rewrite the bullet list to have 4 + 4 = 8 individual bullets (i.e., split each agent into its own bullet OR collapse the patterns into a single bullet of 4 flag-and-structure-pattern items), OR (b) reword the parenthetical to honestly describe the structure: "(one absorption pattern for the four validation agents plus seven individual pattern-and-flag absorptions, totaling eight)" OR "(four validation agents counted as one absorption pattern plus seven individual pattern absorptions = eight)".

### F-NEW3-5 [IMPORTANT] — `embedding_status` field commitment without v0.x support and Canonical Principle Rule 6 tension

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L211 (Scalability Design Principles §6 — "Every wiki page's frontmatter includes an `embedding_status` field... from the first page written")
- **Confidence:** MEDIUM

The brief commits:
> "Every wiki page's frontmatter includes an `embedding_status` field (values: `pending` | `computed` | `stale`) from the first page written. The field is currently unused by any hook or skill in v0.x... v1.0+ will populate these fields when implementing vector retrieval."

This commits to **every wiki page** (10K+ at v0.9 gate) carrying a frontmatter field that **no v0.x skill or hook uses**. The framing is "interface reservation for v1.0+." There are two problems:

1. **Validate-frontmatter-schema.sh implications.** Hook #8 at L370 is `validate-frontmatter-schema.sh`. If `embedding_status` is mandatory frontmatter, the hook must accept (or require) it. The brief at L211 says "No v0.x skill or hook fails if `embedding_status` is absent; the field is additive" — but this then means it's NOT "every wiki page... from the first page written"; it's optional. Internal contradiction within the same paragraph.

2. **Self-audit Canonical Principle Rule 6 tension.** Self-audit at L673 affirms "No 'pending architect review' / 'TODO for architect' / 'Placeholder for architect'" in the brief. `embedding_status` is functionally a "Placeholder for future implementation" — a field that exists solely to be filled in by future architecture work. The principle is about not deferring architect-answerable questions; this commitment defers a future-implementer question. The line is fuzzy. But the bigger issue is the contradiction in (1): is the field mandatory (every page from page 1) or additive (no failure if absent)? Pick one.

**Fix:** Resolve the mandatory-vs-additive contradiction in L211. Either:
- (a) "Every wiki page may optionally include `embedding_status`; default value `pending`. v0.x skills and hooks treat absence and `pending` equivalently."
- (b) "`embedding_status` is part of the v0.x mandatory frontmatter schema; `validate-frontmatter-schema.sh` requires it; default written by `/brain:ingest-url` is `pending`."

### F-NEW3-6 [IMPORTANT] — `.reference/` bootstrap v0.1 gate item creates external-contributor blocker

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L246 (v0.1 ship gate `.reference/` bootstrap); L569 (wclaude requires `gh auth login` with owner credentials); L581 (devops-engineer bootstrap)
- **Confidence:** HIGH

L246 commits the `.reference/` bootstrap (7 clones including wclaude) as a v0.1 ship gate criterion:
> "**`.reference/` directory bootstrapped** with 7 reference repos cloned (vsdd-factory, wclaude, defuddle, obsidian-skills, quartz, karpathy-llm-wiki, llm-wiki-skill)... wclaude clone requires authenticated `gh` (`gh repo clone drbothen/wclaude`)"

L569 reinforces: "For contributors: clone requires `gh auth login` with owner credentials"

L581: "wclaude clone requires `gh auth login` with owner credentials"

The brief at L484 says: "MIT. LICENSE file ships in v0.1 tarball. drbothen/claude-mp marketplace. Public repo from day one."

**Conflict:** brain-factory is a **public, MIT-licensed plugin** with a v0.1 ship gate that requires cloning a **private repo accessible only to the owner**. Public contributors (the Phase 3 pilot users at L116, or any open-source contributor) cannot satisfy the v0.1 ship gate item at L246 because they cannot `gh repo clone drbothen/wclaude`. This means:

- A Phase 3 pilot user attempting to validate the install cannot pass the gate.
- An open-source contributor cannot reproduce the bootstrap.
- CI on a fork (e.g., a Dependabot fork or contributor PR fork) cannot pass.
- The `.reference/MANIFEST.md` will document the wclaude commit hash and license, but external contributors cannot verify either.

The brief at L569 says "For contributors: clone requires `gh auth login` with owner credentials; the MANIFEST documents this requirement." But documenting the requirement doesn't make it satisfiable. The v0.1 ship gate is binary: pass or fail. If only the author can pass it, then the gate is author-only, which fundamentally violates the public-MIT-marketplace-plugin model.

**Also:** L154 says wclaude is "verified by direct filesystem inspection at `/Users/jmagady/Dev/wclaude/`". This is a single-machine fact — only useful to Josh Magady's local checkout. The brief is, in effect, depending on a private-to-author resource at the v0.1 ship gate.

**Fix:** Either (a) remove wclaude from the v0.1 `.reference/` bootstrap gate (make it author-only, optional for contributors); OR (b) commit to publishing wclaude OR (c) downscope: 6 reference repos cloned at v0.1; wclaude is author-private, copied patterns are first-class in brain-factory docs but no external clone requirement.

The current form locks in an unsatisfiable-by-contributor gate criterion.

---

## Process-Gap Findings

### F-PG3-1 [PROCESS-GAP] — Self-Audit Checklist not updated to v0.4.0

- **File:** `.factory/specs/product-brief.md`
- **Lines:** L671-680 (Self-Audit Checklist)
- **Confidence:** HIGH

The Self-Audit Checklist body still references "v0.3.1 edits" (L680: "After v0.3.1 edits..."). No mention of v0.4.0 in the checklist body. New frontmatter locked_decisions added in v0.4.0 (`scale_target_v0_9`, `scale_test_v0_9_gate`, `team_brain_scale`, `reference_repo_count`, `reference_repo_layout`) are not cross-checked in L680 ("Did I cross-check every `locked_decisions` field..."). The L680 enumeration ends at "wclaude_absorption: 8 verified against §Family Positioning 8-item list" — the 5 new v0.4.0 locked-decision fields are not in the verified list.

This is the watchdog-killed-summary footprint warned about in the Pass 3 dispatch prompt. The substantive content additions landed, but the self-audit metadata did not propagate.

Per the dispatch prompt: this finding is process-gap-grade rather than a content blocker — but should be noted because it represents incomplete provenance/verification for v0.4.0's expansion.

**Fix:** Bump the Self-Audit Checklist body to v0.4.0; verify all new frontmatter fields in the L680 enumeration; document the 5 new fields' body-evidence locations.

---

## Suggestions (non-blocking)

- **F-S3-1 [SUGGESTION]:** L139 says "7+ public implementations" implying more than 7, but L519 then says "None of these 7 implementations" referring to exactly 7. Either "7+" → "exactly 7" at L139, or document explicitly that the "+" reflects awareness of other implementations (lucasastorian/llmwiki, charlie947/ai-second-brain noted in reference-repos.md catalog) not enumerated.

- **F-S3-2 [SUGGESTION]:** L142 cites Liu/Nguyen for "ownership-noise failure modes" — the term "ownership-noise" is not defined anywhere in the brief or planning docs. Either define inline or use the term from the source (brief-research.md §2.4 uses "missing ownership"). Glossary gap.

- **F-S3-3 [SUGGESTION]:** L155 (8 wclaude patterns) and L538 (8 wclaude patterns) duplicate the same enumeration content. Consider consolidating: enumerate once in §Family Positioning; §Prior Art section references that enumeration by reference rather than re-listing. Cleaner DRY.

- **F-S3-4 [SUGGESTION]:** L501 says "as of 2026" — the brief's frontmatter `created: 2026-05-14` makes this granular. Consider "as of May 2026" for time-bounded competitive-landscape framing, since claims like "833 stars" are point-in-time and may drift.

---

## Count Reconciliation

| Claim | Stated | Verified | Status |
|---|---|---|---|
| 26 skills | 26 (13 + 12 + 1) | 26 (L301–L331) | PASS |
| 14 agents | 14 (10 + 4) | 14 (L340–L355) | PASS |
| 13 hooks | 13 (12 + 1) | 13 (L362–L376) | PASS |
| 19 GH Actions | 19 (15 + 4) | 19 (L382–L405) | PASS |
| 10 policies | 10 | 10 (L412–L414) | PASS |
| 9 bats suites | 9 (8 functional + meta-lint) | 9 (L417) | PASS |
| 7 topic categories | 7 (ai/health/psych/prod/biz/books/podcasts) | 7 (L413) | PASS |
| 8 wclaude absorptions | 8 bullets in §Family Positioning, 8 in §Prior Art | 8 in both | PASS (count); FAIL (arithmetic, F-NEW3-4) |
| 7 reference repos cloned | 7 | 7 (L565–L579) | PASS (with anthropics/claude-code deferred-as-8th explicitly disclosed at L581) |
| 6 wiki types | 6 | 6 (L193) | **FAIL — types don't match plan §3.4 (F-NEW3-1)** |

---

## Citation Spot-Check Audit (5 NEW v0.4.0 citations)

| # | Citation in Brief | Source | Verdict |
|---|---|---|---|
| 1 | L142 "Liu 35-page audit; Nguyen 77-page production report" | brief-research.md §2.3 | **FAILS** — source documents wiki sizes (35 pages of wiki, 77 pages of wiki), not audit/report lengths. See F-NEW3-2 |
| 2 | L193 "6 wiki types: concepts, entities, sources, synthesis, projects, reflections" | plan.md §3.4 (cited via L641 traceability) | **FAILS** — plan §3.4 enumerates `concepts/, people/, frameworks/, syntheses/, observations/, questions/` (entirely different set). See F-NEW3-1 |
| 3 | L271-277 v0.9 scale test pass criteria (6 items) | No planning doc cited | **FAILS** — all 6 are brief-introduced; no source attribution. See F-NEW3-3 |
| 4 | L139 "7+ public implementations" | reference-repos.md (Karpathy implementations: 7 named) | PARTIAL — "7+" suggests more, brief enumerates exactly 7 at L505-517; minor narrative drift (F-S3-1) |
| 5 | L246 ".reference/ bootstrapped with 7 reference repos cloned" + wclaude private | reference-repos.md §1.2 | VERIFIED for the 7-vs-8 divergence (catalog says 8, brief commits 7 with anthropics/claude-code disclosed as optional 8th at L581 — properly reconciled). Citation form correct. Gate satisfiability is a separate finding (F-NEW3-6) |

**Citation failures:** 3 of 5 (citations 1, 2, 3). All three are paper-fix-pattern variants: v0.4.0 expansion smuggled commitments under citation forms that don't support the claim.

---

## Locked-Decision Coverage (post-amendment)

All 19 frontmatter `locked_decisions` fields reviewed:

- `scale_target_v0_9: power-user (~10000 sources / ~40M words / ~10000 wiki pages)` — verified at L144, L175, L466
- `scale_test_v0_9_gate: required (synthetic 10K-source corpus)` — verified at L271-279 (but criteria themselves are unsourced — see F-NEW3-3)
- `team_brain_scale: out-of-scope-v0_x-and-v1_0` — verified at L438, L467
- `reference_repo_count: 7 (cloned to .reference/)` — verified at L246, L565
- `reference_repo_layout: .reference/ (singular, direct clones not git submodules)` — verified at L563, L581
- All prior fields (skill/agent/hook/GH-action counts, etc.) — already audited and clean per Pass 2

Frontmatter-body coherence: solid except for the wiki-types contradiction (F-NEW3-1) which is body-internal (not frontmatter-tied) and the scale-test sourcing gap (F-NEW3-3).

---

## Streak Decision

**RESET to 0/3.**

2 CRITICAL (F-NEW3-1 wiki types; F-NEW3-2 Liu/Nguyen citation form) + 4 IMPORTANT (F-NEW3-3 scale-test sourcing; F-NEW3-4 wclaude arithmetic; F-NEW3-5 embedding_status contradiction; F-NEW3-6 contributor-blocker `.reference/` gate). BC-5.39.001 requires zero (CRITICAL + IMPORTANT) findings for streak advancement.

---

## Top 3 Findings (one-line each)

1. **F-NEW3-1 [CRITICAL]** — L193 enumerates 6 wiki types (concepts/entities/sources/synthesis/projects/reflections) that contradict plan §3.4's canonical 6 (concepts/people/frameworks/syntheses/observations/questions); traceability table at L641 falsely cites plan §3.4 as the source. Plus internal contradiction: `sources` is named as both Layer-2 and wiki-type.
2. **F-NEW3-2 [CRITICAL]** — L142, L525, L526 cite Liu/Nguyen as "35-page audit" / "77-page production report" when the source says 35/77 are **wiki sizes**, not audit/report lengths. Citation-form misrepresentation — same pattern Pass 1 and Pass 2 caught.
3. **F-NEW3-3 [IMPORTANT]** — All 6 v0.9 scale-test pass criteria at L271-277 are brief-introduced with no planning-doc citation; `scripts/gen-test-corpus.sh` is a new sub-project with no phase ownership.

---

## Summary

**Pass 3 FAIL.** v0.4.0's expansion (+140 lines: 4th differentiator + Scalability Design Principles + Reference Repositories + Karpathy prior-art bump) is structurally substantial and Pass-2 fixes are intact. But the expansion introduced **2 NEW CRITICAL** findings — both citation-form misrepresentation, same pattern Pass 1 and Pass 2 caught (the brief invents support where the source doesn't provide it) — and **4 NEW IMPORTANT** findings around scale-test sourcing, wclaude-absorption arithmetic, `embedding_status` mandatory-vs-additive contradiction, and a `.reference/` v0.1 gate item that excludes external contributors.

The wiki-types contradiction (F-NEW3-1) is the most consequential: a Phase 1b BC writer using the brief as authoritative will scaffold `wiki/entities/`, `wiki/projects/`, `wiki/reflections/` — directly contradicting the methodology source which specifies `wiki/people/`, `wiki/frameworks/`, `wiki/questions/`. This is the single load-bearing taxonomy in the entire brain methodology, and the brief silently substitutes a different one while citing the plan as its source.

Process gap noted: the watchdog-killed Self-Audit Checklist did not propagate to v0.4.0 (still says "After v0.3.1 edits" at L680; 5 new locked_decision fields uncross-checked).

Streak resets to 0/3. Recommend a focused v0.4.1 fix-burst:
- F-NEW3-1: reconcile L193 wiki types with plan §3.4 (or document explicitly as brain-factory extension, same pattern as `briefs/research/`)
- F-NEW3-2: reword Liu/Nguyen citations at L142, L525, L526 to reflect wiki-size (not document-length)
- F-NEW3-3: add explicit "brief-introduced (not in planning docs)" disclaimer to L271-279; or downscope to criteria with planning citation
- F-NEW3-4: fix the "4 + 4" arithmetic at L156 and L650 to match the bullet structure
- F-NEW3-5: resolve mandatory-vs-additive contradiction in L211 `embedding_status` paragraph
- F-NEW3-6: either remove wclaude from L246 v0.1 gate, or downscope contributor-bootstrap expectations
- F-PG3-1: bump Self-Audit Checklist to v0.4.0; cross-check the 5 new locked_decision fields

Total fix surface: probably 30-60 lines of changes. After fix-burst, dispatch Pass 4 with fresh context.

---

## Structured Summary for Orchestrator

```yaml
target_file: .factory/specs/product-brief.md
target_version: 0.4.0
pass_number: 3
finding_counts:
  critical: 2
  important: 4
  suggestion: 4
  process_gap: 1
  total_blocking: 6
verdict: FAIL
streak_before: 0/3
streak_after: 0/3 (RESET)
recommended_next_action: dispatch vsdd-factory:product-owner for surgical v0.4.1 fix-burst (F-NEW3-1 through F-NEW3-6 + F-PG3-1), then Pass 4 adversary dispatch with fresh context
critical_finding_ids: [F-NEW3-1, F-NEW3-2]
important_finding_ids: [F-NEW3-3, F-NEW3-4, F-NEW3-5, F-NEW3-6]
suggestion_finding_ids: [F-S3-1, F-S3-2, F-S3-3, F-S3-4]
process_gap_finding_ids: [F-PG3-1]
paper_fix_pattern_observed: true
paper_fix_evidence: "v0.4.0 expansion introduced 3 citation-form misrepresentations (F-NEW3-1, F-NEW3-2, F-NEW3-3) — same pattern Pass 1 and Pass 2 caught; expansion smuggles commitments under citation forms that do not support them"
```
