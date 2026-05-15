---
artifact_type: product-brief
project: brain-factory
phase: phase-1a
status: draft
version: 0.4.9
target_release: v0.x (MVP through v0.9)
v1_dependency: factory-dispatcher (planned)
created: 2026-05-14
author: vsdd-factory:product-owner
source_documents:
  - docs/planning/llm-second-brain-plan.md
  - docs/planning/llm-second-brain-plugin-plan.md
  - docs/planning/llm-second-brain-phased-build-plan.md
  - docs/planning/vsdd-dispatcher-extraction-plan.md
sibling_references:
  - ../wclaude (content-publishing plugin — private as of May 2026; public-transition pre-v0.1 ship gate; absorbed patterns)
  - ../thought-leadership (user's actual content workflow — Medium + LinkedIn)
elicitation_notes: .factory/planning/elicitation-notes.md
locked_decisions:
  stage_3_locks: .factory/planning/stage-3-locks.md
  primary_user: plugin-operators
  secondary_user: methodology-end-users
  mvp_target: v0.9
  v1_commitment: hard-roadmap (not contingent)
  toolchain: bash + jq + yq + awk + bats + shellcheck + shfmt + Node 20+
  skill_count_v0_9: 26
  agent_count_v0_9: 14
  hook_count_v0_x: 13
  gh_action_count_total: 19
  gh_action_count_committed: 15 (6 in v0.1, 9 in v0.5)
  gh_action_count_community_optional: 4 (in v0.5 tarball; operator opts in)
  lobster_runtime: bash-interpreter-in-v0_x
  self_vsdd: full-7-phase-in-v0_x
  publish_platforms: [LinkedIn-posts, LinkedIn-articles-manual, extension-hooks]
  v0_x_committed_platforms: [LinkedIn]
  medium_v0_x_status: reference-extension-not-core
  perf_tracking: LinkedIn + extension-registered (Medium is first reference extension)
  content_types_v0_x: [articles, posts]
  marketplace: drbothen/claude-mp
  license: MIT
  cross_platform: macOS + Linux + WSL2 (native Windows = v1.0)
  wclaude_absorption: patterns-and-agents-merged-into-existing-plan
  wclaude_repo_status: transitioning-private-to-public-before-v0.1 (currently drbothen/wclaude private; local path /Users/jmagady/Dev/wclaude/)
  scale_target_v0_9: power-user (~10000 sources / ~40M words / ~10000 wiki pages)
  scale_test_v0_9_gate: required (synthetic 10K-source corpus)
  team_brain_scale: out-of-scope-v0_x-and-v1_0 (v2.0+ separate roadmap)
  reference_repo_count: 7 (cloned to .reference/)
  reference_repo_layout: .reference/ (singular, direct clones not git submodules)
  perplexity_mcp_status: optional-opt-in-research-backend (v0.9+; web-search is default)
---

# Product Brief: brain-factory

**Changes in v0.4.9 (2026-05-15):**
- Reconciled hook-performance bats coverage to live inside `hooks.bats` (parallel to embedding_status treatment per line 301); preserves 9-suite bats count commitment (F-PASS14-I1)
- Corrected skill #26 categorical label in v0.9 ship gate: "Phase 2-3 polish" → "Phase 2-3 new skill" matching §Scope §399 (F-PASS14-I2)
- Fixed Open Question #4 phase reference: "Phase 2 polish skill implementation" → "Phase 3 polish skill implementation" (F-PASS14-S1)
- Added `plugins/brain-factory/tests/local-dev-test.sh` to §Scope Additional v0.x deliverables enumeration (F-PASS14-O1)

**Changes in v0.4.8 (2026-05-15):**
- Reconciled Phase 3 Timeline "13 polish skills" → "12 polish skills" + /brain:research, aligning with §Scope's 12+1=13 phase-2-3 count (F-PASS13-I1)
- Added .reference/README.md creation to devops-engineer bootstrap task; resolves v0.1 gate vs task artifact mismatch — gate requires both MANIFEST.md and README.md, now both are committed by the task (F-PASS13-I2, Option A)
- Sibling-swept "phased plan §X" → "phased-build-plan §X" and "plugin plan §X" → "plugin-plan.md §X" at all callsites to align with Citation Conventions block (F-PASS12-O1 / F-PASS13-O1)
- Removed `§` notation from "Changelog" trailers in Self-Audit Checklist: "see §Changelog at top of brief" → "see the Changelog block at top of brief" (Changelog is a bold-header block, not a numbered section) (F-PASS12-O2 / F-PASS13-O2)

**Changes in v0.4.7 (2026-05-15):**
- **STRUCTURAL FIX:** collapsed Self-Audit Checklist per-version annotations (v0.3.0 through v0.4.6) to single "See Changelog at top of brief" references. Eliminates the per-version-attestation drift class permanently (F-PASS11-I1). Same drift-eliminate discipline applied in v0.4.5 (grep-anchors for L-number refs) and v0.4.6 (creation-date anchors for line counts).
- Corrected v0.4.6 changelog count-claim: disambiguation sweep was 5 callsites, not 4 (F-PASS11-S1)
- Added Open Questions preamble note explaining strikethrough-Resolved convention (F-PASS11-O1)
- Moved `stage_3_locks` frontmatter field under `locked_decisions:` block (F-PASS11-O2)

**Changes in v0.4.6 (2026-05-15):**
- **Structural fix:** dropped specific line counts from Traceability artifact citations; replaced with creation-date anchors only (F-PASS10-I1). Eliminates the recurring "wc-l-vs-Read-tool" line-count drift defect class. Same discipline as v0.4.5's structural fix to Self-Audit line-number refs. Acknowledges Pass 9 F-PASS9-S1 was correct, not a false positive; v0.4.5's "Verified via Read tool" claim was inaccurate (used wc -l).
- Sibling-sweep Open Question #2 to match Q#12 reframing — applied Q#8-style strikethrough + Resolved annotation (F-PASS10-S1)
- Disambiguated "plan §A.2" → "phased-build-plan §A.2" at 5 callsites; added Citation Conventions note (F-PASS10-O2)
- Added v0.5 early-ship timing notes for skills #18 `/brain:monthly-perf` and #22 `/brain:publish-content` (F-PASS10-O1)

**Changes in v0.4.5 (2026-05-15):**
- **Structural fix:** replaced all line-number references in §Self-Audit Checklist with grep-anchored semantic references — eliminates the recurring "stale-line-number-after-edit" defect class that Passes 5, 7, and 9 each caught (F-PASS9-I1)
- Verified Traceability line-count citations via Read tool: elicitation-notes.md = 610 lines, stage-3-locks.md = 171 lines, brief-research.md = 495 lines — all existing citations confirmed accurate; Pass 9 finding F-PASS9-S1 ("off by one") was itself incorrect (F-PASS9-S1)
- Clarified `/brain:init` v0.1 scaffold: 7 topic categories + explicit note that `highlights/` and `bookmarks/` are created on-demand by v0.5 readwise/raindrop GH Actions, not part of the v0.1 scaffold (F-PASS9-S2)
- Locked v0.9 ship gate research-backend path: gate tests web-search default; Perplexity MCP opt-in path is tested in Phase 3 dogfood but is not part of the v0.9 release gate (F-PASS9-O1)
- Reframed Open Question #12 from self-resolved-decision to genuine open dimension: what measurable Phase-3-evaluation criteria would trigger a post-v0.9 default-backend reversal? (F-PASS9-O2)

**Changes in v0.4.4 (2026-05-15):**
- Resolved `/brain:research` v0.1-vs-v0.9 timing contradiction (F-PASS8-I1): removed v0.1 ship-gate runtime-dispatch claim; `/brain:init` v0.1 scaffolds `briefs/research/` directory but the skill itself ships v0.9; added new v0.9 ship gate item testing the skill at its actual milestone
- Made Perplexity MCP optional (F-PASS8-I2): default `/brain:research` backend is standard web-search; Perplexity MCP is opt-in via `.brain/policies.yaml`; added Constraints §Technical optional MCP integrations note; added frontmatter `perplexity_mcp_status` locked-decision; added Open Question #12 for post-Phase 3 backend evaluation
- Updated Traceability line-count citation (F-PASS8-S2): brief-research.md 378→495 (verified via `wc -l`; elicitation-notes 610 and stage-3-locks 171 already accurate)
- Made `validate-publish-state.sh` glob scope explicit at §13 bash hooks list (F-PASS8-S3)
- Flagged `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` as brief-introduced extension beyond plan §A.2 at §Family Positioning (F-PASS8-S4)
- Sibling-sweep "preserved through v0.4.2" → version-agnostic "preserved through the current version" at §Traceability sibling references (F-PASS8-S1)

**Changes in v0.4.3 (2026-05-15):**
- Sibling-sweep "12 hooks" → "13 hooks" at §Family Positioning (planned shared infrastructure paragraph), §v1.0 ship gate, and §Future shared infrastructure with adjustment parenthetical matching the v0.4.2 pattern at v0.1 and v0.9 gate items — resolves adversary Pass 7 F-PASS7-I1
- Added `stage_3_locks` frontmatter field and Traceability §Stage 3 locks subsection for `.factory/planning/stage-3-locks.md`
- Refreshed Self-Audit Checklist sibling-sweep annotation post-v0.4.2 edits (NOTE: v0.4.3 used line-number references; v0.4.5 structural fix converts these to grep-anchored semantic references — see F-PASS9-I1)
- Reordered changelog entries to reverse-chronological (newest first)
- Corrected citation §8.3 → §10.5 for literal `diff_count = 0` origin in §Core differentiator #3

**Changes in v0.4.2 (2026-05-15):**
- v0.4.2 cites new `.factory/planning/stage-3-locks.md` artifact (created in parallel by state-manager during the v0.4.2 fix-burst) for v0.9 scale-test source attribution; SL-9 and SL-10 verified present in the locks file at brief v0.4.2-final authorship time
- Reconciled v0.1 ship gate wclaude items: removed duplicate/contradictory gate items in the v0.1 ship gate wclaude-public-transition and `.reference/` bootstrap sections; combined into single coherent gate item with explicit post-transition state and reference-repos.md §7.1 prism citation; sibling-swept devops-engineer bootstrap text in §Reference Repositories
- Reconciled `validate-frontmatter-schema.sh` hook scope: §Scalability Design Principles §6 now matches §Scope §13 bash hooks list's plan §A.4 canonical scope (`wiki/*` and `sources/*`); specified different field-set responsibilities per layer
- Added v0.1 ship gate validation for `embedding_status` enforcement (positive + negative bats test); ensures the v0.4.1 mandatory-field commitment is gate-validated
- 3 suggestion-grade improvements: "matching prism's" now cites reference-repos.md §7.1 (§1.4 does not exist — corrected); "7 public implementations" → "7 publicly-documented implementations" (acknowledges Farzapedia's private-repo / public-gist asymmetry); refreshed stale version tag to v0.4.2

**Changes in v0.4.1 (2026-05-15):**
- Reconciled wiki types to plan §3.4 canonical (concepts/people/frameworks/syntheses/observations/questions); removed invented taxonomy
- Reworded Liu/Nguyen citations to reflect wiki size (35/77 pages of wiki accumulated), not document length
- Disclosed v0.9 scale-test criteria as brief-introduced via Stage 3 elicitation lock; assigned scripts/gen-test-corpus.sh to Phase 3 deliverables
- Corrected wclaude absorption arithmetic (1+7=8, not 4+4=8)
- Made `embedding_status` frontmatter field mandatory in v0.1 (with validate-frontmatter-schema.sh enforcement); resolved mandatory-vs-additive contradiction
- Added owner pre-v0.1 task: make drbothen/wclaude public before v0.1.0 ship; resolves contributor-reproducibility gate
- Self-audit checklist bumped to v0.4.0/v0.4.1 explicit
- 4 suggestion-grade improvements applied (7+ → 7, ownership-noise defined, duplicate enumeration DRY, time-bound "May 2026")

**Changes in v0.4.0 (2026-05-14):**
- Added scalability as 4th core differentiator with v0.9 measured scale test gate (10x Karpathy target: ~10K sources / ~40M words / ~10K wiki pages)
- Added Scalability Design Principles section with 7 concrete architectural disciplines
- Added Reference Repositories section with 7 CLONE-TO-REFERENCE recommendations and the `.reference/` directory bootstrap commitment (v0.1 ship gate)
- Bumped Karpathy prior-art list from 4 to 7 named implementations (added 3 Claude Code skill competitors; reframed Farzapedia as private-repo-only-gist-public)
- Reframed wclaude as private sister repo (drbothen/wclaude, private GitHub; verified by direct filesystem inspection)
- Tightened differentiator #3 to address skill-vs-plugin packaging tier relative to 3 new Claude Code skill competitors
- Expanded frontmatter locked_decisions with scale_target_*, reference_repo_* fields

---

## Vision

`brain-factory` is a versioned, distributable Claude Code plugin that packages an LLM-maintained second-brain methodology — capture → immutable sources → LLM-owned wiki organized by type → output briefs → published work — into a deployable artifact with hook-enforced discipline that an agent cannot bypass at runtime. It is the second factory in the `<domain>-factory` family alongside `vsdd-factory` (Verified Spec-Driven Development), applying the same engine/target split: one stateless, read-only plugin installed once powers any number of private user brains, with enforcement at the tool-event level rather than in agent-readable markdown rules. In v0.x (through v0.9), brain-factory ships 26 skills, 14 specialist agents, 13 bash hooks, 19 GitHub Action templates (15 author-committed + 4 community-optional opt-in), and a minimal Lobster runtime (`bin/lobster-run`) — sufficient to scaffold a functional brain in under 5 minutes via `/brain:init`, ingest a URL into 5+ cross-referenced wiki pages, and produce adversary-reviewed daily briefs and publishable content without the operator writing a single CLAUDE.md or hook script by hand. The plugin's promise is that after six months of use, a brain has read everything its owner has read, drawn non-obvious cross-domain connections they didn't have time to draw, and can answer questions synthesized across hundreds of sources — without the bookkeeping tax that kills most knowledge bases at month six.

Sources: elicitation-notes.md §1; `llm-second-brain-plugin-plan.md` §0, §1; `llm-second-brain-phased-build-plan.md` §0, §3; `README.md`.

---

## Problem Statement

### Why someone installs brain-factory (primary problem — for plugin operators)

A knowledge worker who has read the bare second-brain methodology could execute it by hand. But manual execution requires the operator to maintain CLAUDE.md discipline themselves, trust that ad-hoc slash-command bodies stay consistent across sessions, manually enforce immutability rules and wikilink hygiene, and reproduce the same scaffold for every new brain they create. When the methodology is upgraded, they must edit files in every brain they own. (`llm-second-brain-plugin-plan.md` §1)

The plugin eliminates this burden by centralizing the methodology as versioned artifacts and moving enforcement from agent-readable rules — which an agent can violate, either by mistake or because a different skill body forgot to invoke the quarantine step — to hook-level enforcement. The PreToolUse hook on WebFetch is invoked by the Claude Code harness, not by the agent. The agent cannot bypass it. This is what makes plugin enforcement strictly stronger than markdown rules. (`llm-second-brain-plugin-plan.md` §7.3)

The capability delta the plugin provides over the bare methodology:

| Capability | Bare plan | brain-factory plugin |
|---|---|---|
| Skill definitions | Markdown in each repo; copy-paste drift | Centralized, versioned, same skill in every brain |
| Schema (CLAUDE.md) | Copy-paste template; manually maintained | Scaffolded by `/brain:init`; auto-validated by hooks |
| Enforcement | Hard rules in CLAUDE.md (agent-dependent) | Hooks at tool-event level — agent cannot bypass |
| Quality gates | "Quality bar" text inside each skill | Adversarial-review skill + measurable six-dimensional convergence |
| Upgrades | Manual edit in every brain | `/plugin update` once; new skills and hooks apply everywhere |
| Multi-brain support | Each brain fully independent; copy-paste drift | One plugin powers many brains; state lives in each brain's `.brain/` |
| Test coverage | None | bats suites validating every hook, every skill, every template |
| Governance | None | `.brain/policies.yaml` per-brain; plugin ships 10 baseline policies |

(`llm-second-brain-plugin-plan.md` §1 capability table; §3 engine/target split)

### What the brain itself solves (downstream — for methodology end-users)

A knowledge worker reads 5–20 substantive pieces of content per week — articles, papers, podcast episodes, book chapters, conversations. Almost none of it compounds. The four default failure modes: (`llm-second-brain-plan.md` §1)

- **Capture friction kills input.** The planning docs report that anything taking more than ~10 seconds of conscious effort gets skipped under real cognitive load. (`llm-second-brain-plan.md` §1)
- **No connection layer.** Notes sit in isolation. Cross-domain patterns that would actually develop thinking never get drawn.
- **No return path.** The vault doesn't push insight back to the user. Humans don't remember to pull.
- **Maintenance debt.** Tagging, cross-referencing, and reorganization compound until the system collapses. Most knowledge bases die at 6 months.

The brain answers each failure mode: multiple zero-friction capture surfaces flow into one git-backed `inbox/`; the LLM runs cross-referencing on every ingest and forces weekly pattern discovery via `/brain:connect` and `/brain:synthesize`; daily briefs are generated by GitHub Actions at 6am so the brain pushes insight back without the user asking; and the LLM owns the wiki layer entirely so maintenance debt doesn't compound against the human.

---

## Target Users

### Primary: plugin operators

The plugin's primary user is the operator who installs and runs brain-factory — the person who runs `claude --plugin-dir` or `/plugin install brain-factory@claude-mp`. Three phase-bound operator segments:

**Phase 0–2 operator (sole):** Josh Magady, the plugin author. Single-author dogfood. (`llm-second-brain-phased-build-plan.md` §3, §4, §5, §6; plan.json `"author": { "name": "Josh Magady" }`)

**Phase 3 operators (3–5 pilot users):** "Pick 3–5 people who: Already use a knowledge tool (Obsidian, Logseq, Notion). Write publicly (blog, newsletter, Twitter). Are willing to give honest feedback for 4 weeks." (`llm-second-brain-phased-build-plan.md` §7.3)

**Phase 3+ general operators:** knowledge workers comfortable on the CLI who can run `git init`, `gh repo create`, and `claude --plugin-dir`. Requires: Claude Code installed, `ANTHROPIC_API_KEY`, git and GitHub, Node 20+ for Defuddle CLI and `scripts/run-skill.mjs`. On macOS or Linux natively; on Windows requires Git Bash or WSL2. Familiar with Obsidian-style markdown (wikilinks, frontmatter, nested tags are not friction). (`llm-second-brain-phased-build-plan.md` §A.6 ingest-url skill; elicitation-notes.md §3.1, §7.1)

### Secondary: methodology end-users

The knowledge worker benefiting from a working brain — in v0.x this overlaps with the operator (single-author phase). The canonical end-user reads 5–20 substantive pieces per week (`llm-second-brain-plan.md` §1). Current capture habits are ad-hoc and friction-heavy, with notes that don't compound. Current default tools fail at all four failure modes documented above. The gap: anything requiring more than 10 seconds of conscious effort gets skipped; most knowledge bases die at 6 months from maintenance debt. The brain addresses both the effort threshold and the maintenance debt by making the LLM own the bookkeeping layer entirely.

### Non-users (explicit exclusions for v0.x)

- **Native Windows users.** v0.x requires bash 4+. Operators on Windows install Git Bash or WSL2. The bash hooks resolve via `bash` in PATH. Windows-native support is Phase 4 / v1.0 via WASM. (`llm-second-brain-phased-build-plan.md` §5.6, §6.5, §12)
- **Users wanting hosted SaaS.** The plugin requires a private GitHub repo per brain. `.brain/` state is local. Brain content belongs to the user, not the plugin. This is explicitly local-only; not on roadmap. (`llm-second-brain-plugin-plan.md` §2 engine/target split)
- **Users without git/GitHub.** `/brain:init` requires `git init -b main`. Not a git repo triggers a hard stop with explicit error. (`llm-second-brain-phased-build-plan.md` §A.6 init skill Red Flag #3)
- **Users without a markdown vault habit.** The brain is a six-dimensional convergence system with adversary review on every ingest. It is a multi-month commitment, not a save-clipper. Phase 0 exit gate asks explicitly: "would I use this every day for the next 6 months?" (`llm-second-brain-phased-build-plan.md` §4.6)
- **Users expecting WASM-deterministic cross-platform behavior from day one.** v0.x is pure bash + jq + yq + awk + Node 20+. WASM via factory-dispatcher is v1.0. (`llm-second-brain-phased-build-plan.md` §1 trade table)
- **Multi-user or federated brains.** Each install is single-machine, single-user. (`README.md`: "v0.x — bash hooks. Single-machine, single-user.")

---

## Value Proposition

### Core differentiator

brain-factory's novelty is **not** implementing the Karpathy LLM-wiki pattern. The pattern has **7 publicly-documented implementations as of May 2026** — three Claude Code skill packages (Astro-Han/karpathy-llm-wiki, lewislulu/llm-wiki-skill, kfchou/wiki-skills), Farzapedia (Karpathy-endorsed; repo private, methodology documented via public gist), Spisak's reference implementation, nashsu's desktop application, and rohitg00's v2 gist (see §Competing implementations and `.factory/planning/reference-repos.md`). Claiming novelty for implementing the three-layer architecture would be false. What brain-factory adds is:

1. **Hook-enforced governance** at the tool-event level — quarantine, source-immutability, wikilink-integrity, frontmatter-schema enforced by hooks the agent cannot bypass. No other published implementation operates at this enforcement tier. The quarantine hook fires before web content reaches a tool-access session; the source-immutability hook fires after any write to `sources/`; the wikilink integrity hook fires after any write to `wiki/`. None of these are advisory. They block at exit code 2. (`llm-second-brain-plugin-plan.md` §7.3; elicitation-notes.md §4.1, §4.3)
2. **Adversarial review with cognitive diversity** baked into the methodology — every brief, every synthesis, every published piece passes a fresh-context different-model adversary. This addresses documented drift, hallucination, and ownership-noise failure modes (where authorship attribution between human-curated and LLM-generated wiki content blurs over time, making it unclear which claims are human-vetted versus LLM-asserted) reported by 6-month-scale practitioners — Jim Liu (Obsidian-based wiki grew to ~35 pages over 6 months; openaitoolshub.org blog post) and Tom Nguyen (AWS-ops-focused wiki grew to ~77 pages over 6 months with 30+ sources and 13 custom skills; Medium post). See `.factory/planning/brief-research.md` §2.3. The `brain:adversary-reviewer` agent MUST run in a different model family than the agent that produced the work under review (in brain-factory v0.x: Opus and Sonnet are different families for adversary-review purposes; both Anthropic; cognitive diversity does not require a second vendor).
3. **Dispatcher-ready architecture** — v0.x ships bash hooks; v1.0 migrates to WASM via the shared factory-dispatcher with parity tests (each WASM hook receives identical stdin payloads as the bash equivalent and must emit matching verdicts (`diff_count = 0` across the payload corpus), per `llm-second-brain-phased-build-plan.md` §8.2.4 ("verdicts must match") and §10.5 (where the literal pass-criterion `diff_count = 0` appears)). No other Karpathy-pattern implementation in any packaging tier (skill, vault, app, plugin) has a credible cross-platform WASM migration path. The 3 Claude Code skill competitors (Astro-Han, lewislulu, kfchou) are skill-only — no hook layer to migrate. The vault-style competitors (Spisak, nashsu) are template or app — no plugin migration path. brain-factory is the only implementation building toward dispatcher-tier cross-platform determinism.
4. **Scale-aware architecture from v0.1.** Karpathy's reported scale is ~100 sources / ~400K words / hundreds of wiki pages — beyond which he notes semantic retrieval starts to matter. brain-factory targets **10x that scale**: ~10,000 sources / ~40M words / ~10,000 wiki pages, as the v0.9 ship gate. This is a tested SLA, not an aspiration. Seven architectural disciplines are locked in from v0.1 (detailed in §Scalability Design Principles): incremental ingest via manifest-delta; O(log n) or O(n) max wiki operations; file-system layouts designed for 10K+ files; GH Action parallelism where applicable; token budget instrumentation on every operation; vector-indexing interface reserved for v1.0+ without a rewrite; and page-chunking interface reserved for v0.5+. No other Karpathy-pattern implementation in any packaging tier targets this scale or specifies a tested SLA at this scale.

The Karpathy pattern is the substrate; brain-factory is the enforcement, validation, lifecycle discipline, and scale-aware architecture applied to it.

The single most important thing to do well: **hook-enforced discipline of the methodology's hard rules** — specifically the immutability of `sources/`, wikilink integrity, prompt-injection quarantine before any web content reaches an agent, and atomic index/log coherence. Every other plugin capability (centralized skills, upgrades, multi-brain) is a packaging win. Hook-enforced discipline is a correctness win. Without it, brain-factory is just a well-organized skill catalog.

### Family positioning

brain-factory is the second factory in the `<domain>-factory` family alongside `vsdd-factory`, applying the engine/target split, lifecycle discipline, hook-based enforcement, declarative governance, and adversarial-review quality gates established by the vsdd-factory pattern. (`llm-second-brain-plugin-plan.md` §0) Both factories ship on the `drbothen/claude-mp` marketplace. (`llm-second-brain-phased-build-plan.md` §6.1)

wclaude is a sister repo by the same author (drbothen/wclaude). **Currently PRIVATE as of brief authorship (May 2026); to be transitioned to PUBLIC before v0.1 release as a documented pre-ship owner task.** Patterns are absorbed via local source and documented inline below; once public, the absorbed patterns can be verified directly against the wclaude repo. The local path `/Users/jmagady/Dev/wclaude/` is the current cloning source during pre-v0.1 development.

**Eight wclaude content-publishing plugin patterns** absorbed: the four validation agents (one absorption group) plus seven individual pattern-and-flag absorptions = eight total absorption items as enumerated below (attribution: wclaude is developed by the same author and patterns are re-implemented, not code-copied):

- Four validation agents absorbed: `voice-analyzer`, `content-structure-reviewer`, `frontmatter-validator`, `platform-compliance-checker`. These ship as `plugins/brain-factory/agents/` specialists dispatched by `/brain:adversary-review`. They bring wclaude's platform-compliance enforcement and multi-pass writescore revision loop into the brain's content output pipeline. This bumps brain-factory's agent count from 10 to 14.
- Writescore + revision-loop: multi-pass revision with score threshold baked into `/brain:adversary-review`.
- `--finalize --url "..."` flag pattern: absorbed into `/brain:publish-content` for manual platforms including LinkedIn articles.
- Frontmatter state machine (draft → ready → published): absorbed into `/brain:publish-content` + new `validate-publish-state.sh` hook (bumps hook count 12 → 13).
- `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` directory structure: adopted in the target brain's content layer **as a brief-introduced extension beyond phased-build-plan §A.2's simpler `published/` baseline** (per CLAUDE.md brain-factory-001: planning artifacts are immutable; mid-pipeline structural extensions documented in .factory/ specs).
- `--companion-posts` flag on `/brain:write` (no new skill).
- `--schedule <date>` flag on `/brain:publish-content` (no new skill).
- `--hero-prompt` flag on `/brain:write` (no new skill).

(Sources: wclaude README.md; wclaude CLAUDE.md; thought-leadership CLAUDE.md; locked decision in brief prompt §wclaude-absorption)

Planned shared infrastructure: `factory-dispatcher` is a hard v1.0 dependency, not a v0.x concern. It will extract the hook runtime from vsdd-factory into a shared repo with cross-compiled WASM binaries. The brain plugin's Phase 4 migration is a **13-hook** port — simpler than vsdd-factory's 52-hook migration. (Adjusted from `llm-second-brain-phased-build-plan.md` §8.3's 12-hook baseline: wclaude absorption adds `validate-publish-state.sh` to the migration scope; see §"13 bash hooks" for the full list.) Until factory-dispatcher v1.0.0 ships, bash hooks are the production enforcement layer for brain-factory. Not a fallback. Not a stopgap. The production layer. (`llm-second-brain-phased-build-plan.md` §1; `vsdd-dispatcher-extraction-plan.md` §3)

---

## Scalability Design Principles

Seven architectural disciplines are locked from v0.1 to support the v0.9 scale gate (~10K sources / ~40M words / ~10K wiki pages — 10x Karpathy's reported scale). These are not performance aspirations; they are design constraints enforced at the architecture and test level.

### 1. Incremental ingest (no full-corpus re-reads)

Every ingest operation reads only what changed since the last ingest. The brain's `manifest.json` (in `.brain/`) records `last_ingest` timestamps per source. `validate-source-immutability.sh` enforces that existing source records are not overwritten without explicit user-directed rename flow. At 10K sources, a full re-read costs millions of tokens per cycle — incremental-only is a correctness requirement, not an optimization.

**Commitment:** `/brain:ingest-url` and `/brain:ingest-source` operate on the manifest delta. They never read the entire `sources/` tree on each invocation. The `manifest.json` schema locks in v0.1 to support this at any scale.

### 2. No quadratic hot paths (O(log n) or O(n) max)

Wiki operations that touch multiple pages must complete in bounded time as the wiki grows. Quadratic algorithms (e.g., checking every page against every other page for wikilink consistency) become unusable at 10K+ pages.

**Commitment:** `/brain:lint-wiki` completes wikilink integrity checks via index-first lookup (O(n) scan of `index.md`, not O(n²) cross-product). Hook performance budget: every hook in the 13-hook set processes its sample payload in under 100ms p99 — asserted in per-hook latency test cases inside `plugins/brain-factory/tests/hooks.bats` (within the existing 9-suite bats coverage; not a new suite — bats count remains 9) as a v0.1 ship gate. Wikilink validation across a 500+ page wiki may require incremental design (Phase 1c architecture concern); the bats test budget covers single-payload performance, not full-wiki scan.

### 3. File-system layouts for 10K+ files

Single-directory layouts degrade at 10K+ files (filesystem readdir performance, editor tooling, agent context windows). brain-factory locks the directory taxonomy from v0.1 to prevent this.

**Commitment:** `sources/` uses `sources/{topic}/` subdirectories (7 default categories: ai, health, psychology, productivity, business, books, podcasts; extensible). `wiki/` uses `wiki/{type}/{slug}.md` (6 wiki types per plan.md §3.4: **concepts, people, frameworks, syntheses, observations, questions**). No flat single-directory layouts at either layer. Note: `sources/` is a Layer-2 directory (immutable raw material) — it is NOT a wiki type; wiki types govern the `wiki/{type}/` subdirectory only. `/brain:init` scaffolds this structure; `/brain:ingest-url` writes into the correct subdirectory by type. This layout can handle 10K+ files with no structural change.

### 4. GH Action parallelism

Ingest-intensive workflows (rss-inbox, readwise-sync, raindrop-sync) process multiple sources per run. Sequential processing of 100 sources/day is too slow at power-user scale.

**Commitment:** GH Action templates use matrix strategy where applicable (e.g., `rss-inbox.yml` fans out per feed; `readwise-sync.yml` fans out per batch). Rate-limit handling (LinkedIn Posts API, Readwise, Raindrop) is explicit: 429 responses trigger exponential backoff with `retry-after` header respect, not hard failures. Parallelism target: 100 sources/day sustained ingest without rate-limit-induced data loss.

### 5. Token budget instrumentation

Every operation reports its token consumption. At 10K sources, cumulative token cost becomes a real budget concern — without instrumentation, the operator has no signal until they receive a surprise bill.

**Commitment:** `/brain:ingest-url` writes a JSONL record to `.brain/logs/ingest-tokens.jsonl` on every invocation: `{ "timestamp": ISO8601, "url": "...", "input_tokens": N, "output_tokens": N, "wiki_pages_created": N }`. `/brain:monthly-perf` aggregates this log and surfaces: total monthly token cost, per-ingest average, p95 cost outliers, and a "burn rate at current pace" projection. Baseline target: ~50K input tokens per ingest at steady state (adjusted upward for chunking overhead when page-chunking is active at v0.5+). Operators receive an alert via `/brain:health` if the 30-day trailing average exceeds 2x the baseline.

### 6. Vector-indexing interface reservation

At Karpathy's scale (~hundreds of pages), keyword search on `index.md` is sufficient. At 10x scale (~10K pages), semantic retrieval ("find pages about X that don't mention X by name") becomes load-bearing. brain-factory reserves the interface in v0.x so v1.0+ can implement semantic retrieval without a wiki rewrite.

**Commitment:** Every wiki page's frontmatter MUST include an `embedding_status` field (values: `pending` | `computed` | `stale`) from v0.1 onward. **Default value `pending`** written by `/brain:ingest-url` and `/brain:ingest-source` skills. **`validate-frontmatter-schema.sh` hook enforces presence on `wiki/*` writes** (PostToolUse on Write|Edit; scope includes both `wiki/*` and `sources/*` per plan §A.4, but the `embedding_status` requirement applies only to `wiki/*` since `sources/*` has a different mandatory-fields schema — see `validate-source-immutability.sh` for the source-fields enforcement). Operations that do not produce embeddings (v0.x default) leave the value at `pending`. The `manifest.json` schema includes an `embeddings_model` field (default: `null` in v0.x). v1.0+ implementations of vector retrieval populate both fields; v0.x reserves the schema. This mandatory-from-v0.1 commitment ensures the v1.0+ migration is non-breaking.

### 7. Page-chunking readiness

Source files that exceed the token budget for a single ingest pass (~50K input tokens) must be split into chunks. At 10x Karpathy scale, long-form books and research papers are common.

**Commitment:** `/brain:ingest-url` and `/brain:ingest-source` detect when source content exceeds the 50K-token threshold (configurable in `.brain/policies.yaml` as `max_ingest_tokens_per_chunk`). When the threshold is exceeded, the skill outputs a warning in v0.1 (no automatic chunking). In v0.5+, the skill splits the source into numbered chunks (`source-slug-part-1.md`, `source-slug-part-2.md`, ...) with `manifest.json` back-references preserving the parent source relationship. The v0.1 warning explicitly names the v0.5 chunking behavior so operators know what to expect. The `manifest.json` schema supports a `chunks: [slug-part-1, slug-part-2, ...]` array from v0.1 (populated at v0.5+).

---

## Success Criteria

### v0.1 ship gate (Phase 1 + Phase 2 exit)

Each criterion is measurable and tested; none are aspirational.

- Plugin repo at `~/Dev/brain-factory` with full Phase 1 folder structure present. (`llm-second-brain-phased-build-plan.md` §5.11)
- `plugin.json` valid, version 0.1.0. (`llm-second-brain-phased-build-plan.md` §5.11)
- All 13 hook scripts present, executable, and shellcheck-clean. (Adjusted from `llm-second-brain-phased-build-plan.md` §5.11's 12 hooks: wclaude absorption adds `validate-publish-state.sh`; see §"13 bash hooks" for full list.)
- **All 13** skills present as `SKILL.md` files (the Phase 0/1 primitives — exact match, not minimum). (`llm-second-brain-phased-build-plan.md` §5.11)
- `hooks.json.template` valid JSON; references all hooks via `${CLAUDE_PLUGIN_ROOT}`. (`llm-second-brain-phased-build-plan.md` §5.11)
- `claude --plugin-dir ./plugins/brain-factory` loads without error. (`llm-second-brain-phased-build-plan.md` §5.11)
- `/brain:init` in a fresh directory produces a working brain (folder structure, CLAUDE.md, .brain/, .github/workflows/) in under 5 minutes. **The 5-minute claim is a tested SLA: the v0.1 ship gate adds an explicit timer assertion (`assert_under_5_minutes`) to the local-dev test script in `plugins/brain-factory/tests/local-dev-test.sh`, supplementing phased-build-plan §5.11's exit criteria. This is a new addition to the gate, not a re-citation.** (`llm-second-brain-phased-build-plan.md` §5.10, §6.5; `README.md`)
- `/brain:ingest-url` in the test brain produces 5+ wiki pages with cross-references and adversary-review PASS. (`llm-second-brain-phased-build-plan.md` §5.11)
- All 13 hooks fire on Write/Edit and emit verdicts (verified via `.brain/logs/hooks-*.jsonl`). (Adjusted from `llm-second-brain-phased-build-plan.md` §5.11's 12 hooks: wclaude absorption adds `validate-publish-state.sh`; see §"13 bash hooks" for full list.)
- `/brain:init` scaffolds the `briefs/research/` subdirectory in the target brain's folder structure (extending phased-build-plan §A.2's `briefs/` directory; the actual `/brain:research` skill that writes into this directory ships in v0.9 per §26 Scope).
- Adversary PASS on a sample brief produced by `/brain:brief`. (`llm-second-brain-phased-build-plan.md` §5.11)
- `bin/lobster-run` executes a sample workflow YAML headlessly (the `ingest-url.lobster` pipeline from `plugins/brain-factory/workflows/`).
- CI workflow runs green on a sample push. (`llm-second-brain-phased-build-plan.md` §5.11)
- Meta-lint bats suite passes on all `SKILL.md`, `AGENT.md`, and hook scripts. (CLAUDE.md Meta-Lint Contract)
- **Hook performance budget test:** the v0.1 ship gate adds **explicit hook-performance test cases inside `plugins/brain-factory/tests/hooks.bats`** (within the existing 9-suite bats coverage; these are per-hook latency assertions within `hooks.bats`, **not a new suite — bats count remains 9**). The test asserts every hook in the 13-hook set processes its sample payload in under 100ms p99. **This is a new addition to the gate, supplementing phased-build-plan §5.11's exit criteria.** Wikilink validation across a 500+ page wiki may exceed this budget; that case is incremental-design (Phase 1c architecture concern), not a v0.1 gate criterion.
- **`validate-frontmatter-schema.sh` embedding_status enforcement test (new v0.1 ship gate addition).** The hook rejects wiki page writes lacking the `embedding_status` frontmatter field. Positive case: write a wiki page with `embedding_status: pending` — hook exits 0 (no advisory). Negative case: write a wiki page without `embedding_status` — hook exits 2 (block). Both cases asserted in `plugins/brain-factory/tests/hooks.bats` (within the existing 9-suite bats coverage; these are per-hook test cases within `hooks.bats`, not a new suite — bats count remains 9). This supplements the hook performance bats test at the immediately-preceding item; together they validate both the v0.4.1 mandatory-field commitment (Scalability §6) AND the v0.1 hook-perf budget. **This is a new addition to the gate, supplementing phased-build-plan §5.11's exit criteria.**
- Plugin tagged v0.1.0; tarball in GH Releases; tarball mirrored to `drbothen/claude-mp`. (`llm-second-brain-phased-build-plan.md` §6.6)
- `/plugin install brain-factory@claude-mp` succeeds in a fresh Claude session. (`llm-second-brain-phased-build-plan.md` §6.6)
- After install, `/brain:health` returns GREEN in the author's brain. (`llm-second-brain-phased-build-plan.md` §6.6)
- README explains install and first-brain bootstrap. (`llm-second-brain-phased-build-plan.md` §6.6)
- **`.reference/` directory bootstrapped** with 7 reference repos cloned (vsdd-factory, wclaude, defuddle, obsidian-skills, quartz, karpathy-llm-wiki, llm-wiki-skill). Cloned via direct clone (matching prism's `.references/` pattern per `.factory/planning/reference-repos.md` §7.1). `.reference/` added to `.gitignore`. README at `.reference/README.md` documents what each is and how brain-factory ingests from it. After the owner pre-v0.1 task below, all 7 clones use unauthenticated `gh`. `MANIFEST.md` at `.reference/MANIFEST.md` documents URL, license, cloned commit hash, and clone date for each repo. **This is a new v0.1 gate addition**, supplementing phased-build-plan §5.11's exit criteria.
- **Owner pre-v0.1 task: make drbothen/wclaude public.** Run `gh repo edit drbothen/wclaude --visibility public` **before tagging v0.1.0**. This unblocks contributor reproducibility of the `.reference/` directory bootstrap. The wclaude repo contains content-publishing patterns absorbed by brain-factory; making it public preserves attribution lineage and enables external CI / Dependabot / pilot users to clone the reference set without owner credentials.

### v0.5 milestone

- 13 additional templates ship at v0.5: 9 author-committed (`rss-inbox.yml`, `issue-capture.yml`, `readwise-sync.yml`, `raindrop-sync.yml`, `auto-connect.yml`, `monthly-perf.yml`, `token-budget.yml`, `cold-start.yml`, `snapshot.yml`) + 4 community-optional opt-in (`garden-publish.yml`, `telegram-bridge.yml`, `email-inbox.yml`, `cross-repo-dispatch.yml`). Total in tarball at v0.5: 19. (`llm-second-brain-plan.md` §8.5–§8.18)
- LinkedIn Posts API (Community Management) integration live and tested end-to-end: at least one post published to LinkedIn via `/brain:publish-content`.
- LinkedIn articles manual-finalize flow functional via `--finalize --url "..."` flag on `/brain:publish-content`.
- Medium reference extension shipped at `plugins/brain-factory/extensions/medium/` as the canonical demonstration of the extension pattern. **Prerequisite:** the extension schema (hook contract + frontmatter schema) MUST be locked in Phase 1c architecture before this milestone can be claimed. At least one operator (the author or a pilot) successfully uses the Medium reference extension end-to-end. (Medium API is officially deprecated per `.factory/planning/brief-research.md` §6.1; only legacy integration tokens work, best-effort, with no support commitment from Medium.)
- `/brain:monthly-perf` pulls performance data from LinkedIn Posts API (Community Management) correctly and reports to `.brain/logs/`. Medium perf pulls available via the Medium reference extension if the operator opted in.

### v0.9 ship gate (Phase 3 exit — full MVP)

- No P0 or P1 bugs in the plugin issue tracker. (`llm-second-brain-phased-build-plan.md` §7.5)
- All 13 hooks have bats coverage (positive case, negative case, and edge case). (`llm-second-brain-phased-build-plan.md` §7.5; the 13 covers the 12 from §A.4 plus `validate-publish-state.sh` from wclaude absorption)
- All 26 skills functionally complete and invoked at least once by the author and at least once by a pilot user. (`llm-second-brain-phased-build-plan.md` §7.5; skill count 25 + /brain:research = 26)
- `/brain:research <topic>` (skill #26, Phase 2-3 new skill — distinct from the 12 polish skills per §Scope) successfully dispatches the `brain:researcher` specialist. **The v0.9 ship gate tests the default web-search backend path** (i.e., operator has NOT opted in to Perplexity MCP); the Perplexity MCP opt-in path is tested in a separate Phase 3 dogfood validation but is not part of the v0.9 release gate (since Perplexity is a paid optional service). The skill synthesizes findings on a sample topic and outputs to both `wiki/` pages and `briefs/research/<topic>-research.md`. (This is the runtime-dispatch validation for skill #26; the `briefs/research/` directory scaffolding is tested at v0.1 per `/brain:init` gate item above.)
- CHANGELOG.md honest about every breaking change between v0.1 and v0.9. (`llm-second-brain-phased-build-plan.md` §7.5)
- Cross-platform: at least one operator on each of {macOS, Linux, Windows-via-Git-Bash or WSL2} reports successful install and ingest. (`llm-second-brain-phased-build-plan.md` §7.5)
- v0.9.0 tagged and released. (`llm-second-brain-phased-build-plan.md` §7.6)
- Author has used the plugin daily for at least 8 weeks. (`llm-second-brain-phased-build-plan.md` §7.6)
- At least 3 pilot users have used it for at least 4 weeks each. (`llm-second-brain-phased-build-plan.md` §7.6)
- At least one piece of content has shipped through the full brain → brief → write → publish pipeline (author's or a pilot's). (`llm-second-brain-phased-build-plan.md` §7.6)
- **7-phase VSDD-pipeline convergence achieved on brain-factory's own development.** All seven phases (1: spec crystallization with sub-phases 1a domain / 1b PRD / 1c architecture / 1d adversarial spec review; 2: story decomposition; 3: TDD implementation; 4: holdout evaluation; 5: adversarial refinement; 6: formal hardening; 7: 7-dimensional convergence assessment) have reached convergence against brain-factory's own `.factory/` artifacts before the v0.9.0 tag. Note: the brain's internal six-dimensional convergence (Capture / Sources / Wiki / Synthesis / Output / Reflection — tracked in `.brain/STATE.md`) is orthogonal to this VSDD-pipeline convergence. (CLAUDE.md Phase pipeline; locked decision §self-vsdd)
- Voice rules tuned against real published briefs from author and pilot sessions. (`llm-second-brain-phased-build-plan.md` §7.6)
- Performance tracking layer operational: `/brain:monthly-perf` pulls from LinkedIn Posts API (Community Management) correctly, and at least one extension-registered endpoint is documented. Medium perf pulls available via the Medium reference extension for operators who opted in.
- Meta-lint passes on every artifact in the plugin repo at time of tag.
- **Scale test at power-user tier (new v0.9 gate addition).** v0.9 ship gate includes ingesting a 10,000-source synthetic corpus (~40M words, expected ~10,000 wiki pages) and measuring against these pass criteria:

  **Source attribution:** The following 6 pass criteria are **brief-introduced via Stage 3 elicitation user-locks SL-9 (scalability scope) and SL-10 (scale target)** recorded in `.factory/planning/stage-3-locks.md` (Stage 3 locks artifact created 2026-05-15; SL-9 at §132, SL-10 at §144):
  - SL-9: User selected "Discipline + measured v0.9 scale test"
  - SL-10: User selected "Power-user scale (10x personal)" — ~10,000 sources / ~40M words / ~10,000 wiki pages

  The planning docs (`docs/planning/llm-second-brain-plan.md` and `llm-second-brain-phased-build-plan.md`) do NOT specify these exact numbers — they reference Karpathy's ~100-source / ~hundreds-of-pages baseline scale (`plan.md` §2.1). The brief introduces 10x-Karpathy as a production-grade SLA per the user's locked scale target. Each criterion below is independently testable.

  - `/brain:ingest-url` retrieval-plus-wiki-write latency stays sub-linear (O(log n) or better) as the wiki grows from 1K to 10K pages — measured at 1K, 5K, and 10K checkpoints.
  - `/brain:lint-wiki` full health pass completes in under 10 minutes on a 10K-page wiki (measured wall-clock on a standard GitHub Actions runner).
  - GH Actions process the target ingest rate (100 sources/day sustained over 5 days of the test run) without rate-limit-induced data loss or hard failures.
  - Peak resident memory for any single operation stays under 2GB (measured via `/usr/bin/time -v` or equivalent on the Actions runner).
  - Token budget at scale: cumulative consumption tracked via `/brain:monthly-perf`; per-ingest cost stays within 3x the 50K-token baseline (i.e., ≤150K input tokens per ingest including chunking overhead at the 10K-source corpus size).
  - The synthetic corpus is generated by a dedicated `scripts/gen-test-corpus.sh` script (**Phase 3 deliverable owned by devops-engineer; designed during Phase 1c architecture; built during Phase 3 alongside the scale test execution**) checked into the plugin repo, so the test is reproducible by any contributor. The script generates N source files with randomized content from a seed, plus a pre-built `manifest.json` representing the state after N-1 ingests, allowing the scale test to start from an existing-corpus baseline rather than re-ingesting from zero.

  This scale test **supplements** phased-build-plan §7.5's exit criteria; it does not replace any of the existing v0.9 gate items.

### v1.0 ship gate (post-MVP, named for context)

v1.0 is a hard roadmap commitment — not contingent on any optional migration trigger. It requires factory-dispatcher v1.0.0 to be available before it can start.

- All **13** WASM hooks compile and pass parity test against bash equivalents (`diff_count = 0`). (Adjusted from `llm-second-brain-phased-build-plan.md` §8.3's 12 hooks: wclaude absorption adds `validate-publish-state.sh` to the migration scope; see §"13 bash hooks".)
- Vendored dispatcher binaries in tarball; SHA-verified at build time. (`llm-second-brain-phased-build-plan.md` §8.3)
- `hooks.json.template` wires Claude Code → factory-dispatcher → WASM plugins. (`llm-second-brain-phased-build-plan.md` §8.3)
- At least one week of operation under WASM hooks with zero false positives or false negatives versus the bash baseline. (`llm-second-brain-phased-build-plan.md` §8.3)
- Cross-platform parity: WASM hooks behave identically on macOS, Linux, and Windows-native without Git Bash. (`llm-second-brain-phased-build-plan.md` §8.3)
- v1.0.0 tagged; CHANGELOG documents the bash-to-WASM migration; bash hook scripts removed from tarball. (`llm-second-brain-phased-build-plan.md` §8.3)
- Pilot users report no behavioral difference versus v0.9.

---

## Scope

### In scope for v0.x (through v0.9)

**26 skills (by phase):**

Phase 0/1 primitives (13 — ship with v0.1):
1. `/brain:init` — scaffold a new brain from zero: folder structure, CLAUDE.md, .brain/, .github/workflows/
2. `/brain:health` — validate brain structure; surface six-dimensional convergence state
3. `/brain:ingest-url <url>` — fetch via Defuddle → sources/ → wiki/ (5–15 pages, cross-referenced)
4. `/brain:ingest-source <path>` — ingest a local file into sources/ → wiki/
5. `/brain:process-inbox` — classify and route inbox notes
6. `/brain:lint-wiki` — seven-check health pass on wiki layer
7. `/brain:connect [days]` — find cross-domain connections across recent ingests
8. `/brain:synthesize` — weekly synthesis, builds a thesis from connection layer
9. `/brain:brief <topic>` — generate a content brief in ONE THING / PROOF / TRANSFORMATION format
10. `/brain:write <brief-path>` — produce a full piece in the author's voice (flags: `--companion-posts`, `--hero-prompt`)
11. `/brain:quarantine-check <path>` — scrub prompt-injection patterns from content before agent access
12. `/brain:rename-page <old-slug> <new-slug>` — rename wiki page and propagate all backlinks
13. `/brain:adversary-review <path>` — fresh-context quality gate with multi-pass writescore revision loop via the four absorbed wclaude validation agents

Phase 2–3 polish skills (12 — ship by v0.9; skills #18 `/brain:monthly-perf` and #22 `/brain:publish-content` ship early at v0.5 milestone per §Success Criteria v0.5 milestone):
14. `/brain:daily-brief` — tomorrow-morning synthesis prompt (also wired to GH Actions)
15. `/brain:weekly-refresh` — update Current Projects section in CLAUDE.md from recent activity
16. `/brain:quarterly-mirror` — 90-day career and belief evolution analysis
17. `/brain:reflect` — ad-hoc reflection triggered by a prompt or event
18. `/brain:monthly-perf` — pull performance data from LinkedIn Posts API (Community Management) + registered extensions (Medium via reference extension if operator opted in)
19. `/brain:install-actions` — wire GH Action templates into the target brain's `.github/workflows/`
20. `/brain:upgrade-brain` — upgrade the plugin and migrate `.brain/` state if needed
21. `/brain:export-brain` — export wiki layer for static-site rendering (Quartz or custom)
22. `/brain:publish-content <file>` — publishing orchestrator supporting LinkedIn Posts API (Community Management), LinkedIn articles manual-finalize via `--finalize --url "..."`, and `--schedule <date>` (flags: `--finalize`, `--schedule`). Medium publishing available via the Medium reference extension at `plugins/brain-factory/extensions/medium/` for operators who install it separately.
23. `/brain:policy-add <id> <body>` — register a new governance policy in `.brain/policies.yaml`
24. `/brain:policy-registry-validate` — validate all policies in `.brain/policies.yaml` against the schema
25. `/brain:cold-start-recover` — recover a brain session after a cold start or context loss

Phase 2–3 new skill (1 — ships by v0.9):
26. `/brain:research <topic>` — dispatches `brain:researcher` specialist. Default research backend: web search via standard Claude tools. If Perplexity MCP is configured (optional opt-in via `.brain/policies.yaml`), the researcher uses it for higher-quality synthesis. Outputs to both `wiki/` pages and `briefs/research/<topic>-research.md`. The `briefs/research/` directory is created by `/brain:init` as part of the scaffold. **This extends the target brain's folder structure beyond phased-build-plan §A.2's enumerated `briefs/{daily,weekly,monthly,content,decisions}/` subdirs** to include `research/`. The extension is a brief-introduced scope addition (per CLAUDE.md brain-factory-001: planning artifacts are immutable; mid-pipeline changes go to .factory/ specs).

(`llm-second-brain-phased-build-plan.md` §A.6; locked skill count in brief prompt §skill-count-lock)

**14 specialist agents:**

**All 14 agents below ship in the brain-factory plugin tarball and use the `brain:*` namespace.** brain-factory does NOT inherit any agent from `vsdd-factory` at runtime. `vsdd-factory:*` agents (e.g., `vsdd-factory:orchestrator`, `vsdd-factory:product-owner`) drive brain-factory's own development pipeline (per CLAUDE.md Agent Routing Table), never operate on a deployed brain. brain-factory is fully self-contained at runtime.

Brain-side specialists (10 — per plugin-plan.md §6; elicitation-notes.md §5.1):
1. `brain:orchestrator`
2. `brain:librarian`
3. `brain:synthesizer`
4. `brain:writer`
5. `brain:curator`
6. `brain:adversary-reviewer`
7. `brain:archivist`
8. `brain:state-manager`
9. `brain:voice-coach`
10. `brain:researcher`

wclaude validation agents absorbed (4 — dispatched by `/brain:adversary-review`):
11. `brain:voice-analyzer` — writing voice consistency, AI-pattern detection, tone register
12. `brain:content-structure-reviewer` — content organization, flow, headings, hooks, closings
13. `brain:frontmatter-validator` — YAML frontmatter schemas, cross-references, naming conventions
14. `brain:platform-compliance-checker` — LinkedIn requirements, character limits, hashtags; Medium requirements covered when Medium reference extension is active

(Sources: `llm-second-brain-plugin-plan.md` §6; wclaude README.md Agents table; locked decision in brief prompt §wclaude-absorption)

**13 bash hooks:**

The 12 hooks from phased-build-plan §A.4:
1. `brain-health-check.sh` (SessionStart)
2. `quarantine-fetch.sh` (PreToolUse, matcher=WebFetch)
3. `enforce-kebab-case.sh` (PreToolUse, matcher=Write|Edit)
4. `block-ai-attribution.sh` (PreToolUse, matcher=Bash)
5. `validate-source-immutability.sh` (PostToolUse, Write|Edit on sources/*)
6. `validate-wikilink-integrity.sh` (PostToolUse, Write|Edit on wiki/*)
7. `validate-index-log-coherence.sh` (PostToolUse, Write|Edit on wiki/index or log.md)
8. `validate-frontmatter-schema.sh` (PostToolUse, Write|Edit on wiki/* or sources/*)
9. `validate-page-type-policy.sh` (PostToolUse, Write|Edit on wiki/*)
10. `validate-voice-avoid-list.sh` (PostToolUse, Write|Edit on briefs/content/*-draft.md)
11. `validate-source-id-citation.sh` (PostToolUse, Write|Edit on wiki/*)
12. `flush-state-and-commit.sh` (Stop)

Plus 1 from wclaude absorption (bumps count 12 → 13):
13. `validate-publish-state.sh` (PostToolUse, Write|Edit on `drafts/{platform}/*.md`, `to-publish/{platform}/*.md`, or `published/{platform}/*.md` — enforces draft → ready → published frontmatter state machine across the wclaude-absorbed content lifecycle)

(`llm-second-brain-phased-build-plan.md` §A.4; locked hook count in brief prompt §wclaude-absorption)

**19 GitHub Action templates (15 author-committed + 4 community-optional opt-in):**

v0.1 core set — author-committed (6):
1. `daily-brief.yml` (plan.md §8.1)
2. `weekly-lint.yml` (plan.md §8.2)
3. `weekly-synthesis.yml` (plan.md §8.3)
4. `schema-refresh.yml` (plan.md §8.4)
5. `wikilink-check.yml` (plan.md §8.8)
6. `quarterly-mirror.yml` (plan.md §8.11)

v0.5 additions — author-committed (9):
7. `rss-inbox.yml` (plan.md §8.5)
8. `issue-capture.yml` (plan.md §8.6)
9. `readwise-sync.yml` (plan.md §8.7)
10. `raindrop-sync.yml` (plan.md §8.7b)
11. `auto-connect.yml` (plan.md §8.9)
12. `monthly-perf.yml` (plan.md §8.10)
13. `token-budget.yml` (plan.md §8.12)
14. `cold-start.yml` (plan.md §8.13)
15. `snapshot.yml` (plan.md §8.14)

Community-optional add-ons (4) — shipped in the v0.5 tarball for per-operator opt-in; no author support commitment:
16. `garden-publish.yml` (plan.md §8.15)
17. `telegram-bridge.yml` (plan.md §8.16)
18. `email-inbox.yml` (plan.md §8.17)
19. `cross-repo-dispatch.yml` (plan.md §8.18)

Note: The 15 author-committed templates are covered by adversarial review, bats coverage, and CHANGELOG accountability. The 4 community-optional templates ship in the tarball for per-operator opt-in; they are not author-maintained integrations and carry no support commitment. Total templates in tarball: 19. (`llm-second-brain-plan.md` §8.1–§8.18; elicitation-notes.md §5.1)

**bin/lobster-run:** a bash interpreter for Lobster YAML workflow files. The runtime behavior (reads workflow YAML; executes skill steps in declared dependency order; exits 0/1/2) is the commitment. Implementation footprint is not a brief-level commitment. Ships in v0.1 and enables headless GH Actions execution without Node runtime overhead. 6 workflow YAML files ship in `plugins/brain-factory/workflows/`: `ingest-url.lobster`, `daily-ritual.lobster`, `weekly-synthesis.lobster`, `monthly-perf.lobster`, `quarterly-mirror.lobster`, `cold-start-recovery.lobster`. (`llm-second-brain-plugin-plan.md` §8.1; locked decision in brief prompt §lobster-runtime-lock)

**Additional v0.x deliverables:**
- ~20 templates via `${CLAUDE_PLUGIN_ROOT}/templates/...` (CLAUDE.md template, 6 wiki page type templates — one per wiki type: concepts, people, frameworks, syntheses, observations, questions — 3 source type templates, 5 brief templates, 1 policies.yaml template, 1 STATE.md template, 1 manifest template, GitHub Action YAML templates). The `policies-yaml-template.yaml` template at `${CLAUDE_PLUGIN_ROOT}/templates/policies-yaml-template.yaml` ships pre-populated with the 10 baseline policies enumerated in plugin-plan.md §10.2. `/brain:init` copies this template to the target brain's `.brain/policies.yaml`, which the operator can then extend via `/brain:policy-add`. (`llm-second-brain-plugin-plan.md` §9, §10.2)
- **7 default topic categories** scaffolded by `/brain:init` in the target brain's `sources/` folder per `llm-second-brain-plan.md` §3.3: `ai`, `health`, `psychology`, `productivity`, `business`, `books`, `podcasts`. Customizable via `/brain:weekly-refresh` after install. **Two additional source subdirs (`highlights/` and `bookmarks/`) are created on-demand by the v0.5 GH Action templates `readwise-sync.yml` and `raindrop-sync.yml` respectively** (per phased-build-plan §A.2's full 9-subdir layout); they are not part of the v0.1 `/brain:init` scaffold.
- 10 baseline policies in `.brain/policies.yaml`. (`llm-second-brain-plugin-plan.md` §10.2)
- 30-entry voice avoid-list in `rules/voice-avoid-list.txt`. (`llm-second-brain-phased-build-plan.md` §A.10)
- Prompt-injection corpus patterns in `scripts/quarantine.mjs`. (`llm-second-brain-phased-build-plan.md` §A.11)
- **9 bats test suites** (8 functional: `skills.bats`, `hooks.bats`, `templates.bats`, `policies.bats`, `adversary.bats`, `quarantine.bats`, `integration.bats`, `upgrade.bats`; plus `meta-lint.bats` per CLAUDE.md Meta-Lint Contract). (`llm-second-brain-plugin-plan.md` §4; CLAUDE.md Meta-Lint Contract)
- `plugins/brain-factory/tests/local-dev-test.sh` — local-dev integration test script asserting 5-minute init SLA (`assert_under_5_minutes`). Ships in v0.1 tarball.
- Plugin's own CI workflow and release pipeline. (`llm-second-brain-phased-build-plan.md` §5.9, §6.2)
- Content publish platforms in v0.x: LinkedIn Posts API (Community Management) + LinkedIn articles manual-finalize via `--finalize`. Medium support ships as the first reference extension at `plugins/brain-factory/extensions/medium/`, demonstrating the extension pattern. (Medium API is officially deprecated per `.factory/planning/brief-research.md` §6.1; only legacy integration tokens work, best-effort, with no support commitment from Medium.) Extension pattern at `plugins/brain-factory/extensions/<platform>/` with hook contract and frontmatter schema.
- Content types in v0.x: articles (1000+ words, LinkedIn via manual-finalize; Medium via reference extension) and posts (<3000 chars, LinkedIn via Posts API). (thought-leadership CLAUDE.md directory structure)
- Self-VSDD: `.factory/` active throughout v0.x development. (CLAUDE.md Pipeline Authority)
- Per-platform hooks.json variants (darwin-arm64, darwin-x86_64, linux-x86_64, windows-x86_64) — same content for v0.x bash hooks. (`llm-second-brain-phased-build-plan.md` §6.2)
- `scripts/run-skill.mjs` — headless skill runner for GH Actions using Node 20+. (locked decision in brief prompt §toolchain-node-runtime-lock)
- `scripts/defuddle-fetch.mjs` — Defuddle CLI wrapper for `/brain:ingest-url`. Requires Node 20+. (`llm-second-brain-phased-build-plan.md` §A.6; elicitation-notes.md Q-20)
- LICENSE file (MIT) ships in v0.1 tarball. (locked decision; plugin-plan.md §27.2; phased-build-plan §6.2)
- Six-dimensional convergence tracking in `.brain/STATE.md`: Capture / Sources / Wiki / Synthesis / Output / Reflection. User-visible via `/brain:health` and SessionStart hook banner. (`llm-second-brain-plugin-plan.md` §3.6, §12)
- Planning docs (`docs/planning/`) do NOT ship in the published tarball — author-only design substrate. (`llm-second-brain-phased-build-plan.md` §6.2 release step; elicitation-notes.md Q-18)

### Out of scope for v0.x (deferred, named)

- **WASM hooks via factory-dispatcher.** Phase 4 / v1.0. (`llm-second-brain-phased-build-plan.md` §0, §2, §8)
- **factory-dispatcher repo creation and v1.0.0 release.** Upstream prerequisite, gated on vsdd-factory completing its own dispatcher extraction per `vsdd-dispatcher-extraction-plan.md`. (`vsdd-dispatcher-extraction-plan.md` §27 step 5)
- **Observability sinks beyond file logs.** OTEL-gRPC, DataDog, Honeycomb, and HTTP sinks come with WASM in Phase 4. (`llm-second-brain-phased-build-plan.md` §9 comparison table)
- **Native Windows support.** Phase 4 via WASM. v0.x operators on Windows use Git Bash or WSL2. (`llm-second-brain-phased-build-plan.md` §9)
- **4 community-optional GH Actions as author-supported features** (telegram-bridge, email-inbox, cross-repo-dispatch, garden-publish). These ship as community templates in the tarball. They are per-user opt-in add-ons, not author-maintained integrations in v0.x.
- **Medium API as a core v0.x channel.** Medium's official API is deprecated by Medium; brain-factory ships Medium support only as a reference extension at `plugins/brain-factory/extensions/medium/`, demonstrating the extension pattern. Medium integration is best-effort (legacy tokens only) with no author support commitment for the extension.
- **Multi-brain federation.** Not addressed by any planning document. Engine/target split is explicitly per-user-per-brain.
- **Team-brain scale (~100K+ sources / federated brains).** v2.0+, separate roadmap. v0.x and v1.0 target personal + power-user tier (single-machine, single-user, local-only). The v0.9 scale gate tests ~10K sources (power-user); 100K+ conflicts with the local-only single-machine constraint that is locked through v1.0.
- **Hosted SaaS.** Local-only. Not on roadmap.
- **Email, correspondence, and song content types** as `/brain:publish-content` targets. Deferred to v0.5+. (thought-leadership CLAUDE.md content types; locked decision in brief prompt)
- **wclaude overlap-with-primitives skills NOT absorbed:** mine-ideas, capture-idea, research-topic-as-separate-skill (brain-factory ships `/brain:research` instead), draft-article, draft-email, manage-correspondence, create-thought-grenade. Brain-factory primitives cover the function or skill flags handle it. (locked decision in brief prompt §wclaude-absorption NOT-absorbed list)
- **Worktree-mounted `.brain/` state.** Plugin plan §3.15 marks it OPTIONAL advanced. Default for new installs is plain (no worktree). Not committed in v0.x.
- **PowerShell ports of bash hooks.** More work; throwaway code once Phase 4 lands. (`llm-second-brain-phased-build-plan.md` §13 #3)

---

## Constraints

### Technical

- **Toolchain (operator prerequisites):** bash 4+, jq, yq, awk, bats, shellcheck, shfmt, Node 20+. Node 20+ is required for Defuddle CLI (`scripts/defuddle-fetch.mjs`) and `scripts/run-skill.mjs` (headless skill runner for GH Actions). No Rust toolchain in v0.x. (`llm-second-brain-phased-build-plan.md` §1 trade table; locked decision in brief prompt §toolchain-node-runtime-lock; elicitation-notes.md Q-20)
- **Engine read-only at runtime.** Plugin files are never modified by a running brain operation. State lives exclusively in the target's `.brain/`. (`llm-second-brain-plugin-plan.md` §2 rule 1; CLAUDE.md Hard rules)
- **Templates resolved via `${CLAUDE_PLUGIN_ROOT}/templates/...`.** Never hardcoded `.claude/templates/...` paths. Enforced by CI grep check. (`llm-second-brain-phased-build-plan.md` §5.9; CLAUDE.md conventions)
- **Hook contract:** `#!/usr/bin/env bash` + `set -euo pipefail`. Reads JSON on stdin; writes JSON verdict on stdout; exits 0 (ok), 1 (advisory), 2 (block). Never bare `exit`. Never `eval`. (`llm-second-brain-phased-build-plan.md` §A.4; CLAUDE.md Bash hook contract)
- **Conventional Commits.** No AI attribution (`Co-Authored-By: Claude`, robot emoji, "Generated with Claude Code" trailers). Enforced by `block-ai-attribution.sh` at PreToolUse and by lefthook pre-commit. (CLAUDE.md; project `CLAUDE.md` conventions)
- **Wiki filenames kebab-case, lowercase, no spaces. IMMUTABLE after creation.** Renames go through `/brain:rename-page`. (`llm-second-brain-phased-build-plan.md` §A.4; CLAUDE.md brain-factory-002)
- **No `--no-verify`. No force-push to `main`.** TD-FACTORY-HOOK-BYPASS-001 P0. (CLAUDE.md non-negotiable git rules)
- **No JS/Node test framework.** v0.x is pure bash + jq + yq + awk + bats for portability. No remark, no markdownlint-cli2, no ajv. (CLAUDE.md conventions)
- **shellcheck clean + shfmt-normalized.** No SC2XXX warnings. Indent 2 spaces. (CLAUDE.md conventions)
- **Cognitive diversity in adversary review.** The `brain:adversary-reviewer` agent MUST run in a different model family than the agent that produced the work under review (in brain-factory v0.x: Opus and Sonnet are different families for adversary-review purposes; both Anthropic; cognitive diversity does not require a second vendor). (`llm-second-brain-plugin-plan.md` §3.8; `llm-second-brain-phased-build-plan.md` §A.6)
- **Prompt-injection quarantine non-optional.** Every ingest pipeline MUST run `/brain:quarantine-check` before content reaches a Claude session with tool access. This is the most important rule in the entire system. (`llm-second-brain-plan.md` §3.7)
- **Hook performance budget.** Performance budget: <100ms; v0.1 ship gate includes a bats test asserting tail latency under load. Wikilink validation across a 500+ page wiki may require incremental design. (`llm-second-brain-plugin-plan.md` §23)
- **Token budget per ingest.** Token budget: <50K input tokens per `/brain:ingest-url` at steady state; instrumented via `.brain/logs/ingest-tokens.jsonl` and reported by `/brain:monthly-perf`. (`llm-second-brain-plan.md` §5; `llm-second-brain-plugin-plan.md` §A.2)
- **Self-VSDD:** brain-factory's own development follows the full 7-phase VSDD pipeline (phases 1–7; sub-phases 1a–1d within phase 1) with `.factory/` active throughout v0.x. (CLAUDE.md Pipeline Authority; locked decision §self-vsdd)
- **Cross-platform:** macOS + Linux strong; Windows via Git Bash or WSL2. (`llm-second-brain-phased-build-plan.md` §1 trade table)
- **Optional MCP integrations:** Perplexity MCP is supported as an opt-in research backend for `/brain:research` (skill #26, ships v0.9). Default is standard web-search; operators may configure Perplexity MCP via `.brain/policies.yaml` if they want higher-quality synthesis. Perplexity is a paid third-party service — not a brain-factory dependency, just an optional backend. Not required by any v0.x operator prerequisite.
- **Scale target (v0.9 ship gate):** power-user tier (~10,000 sources, ~40M words, ~10,000 wiki pages — 10x Karpathy's reported scale of ~100 sources / ~400K words / hundreds of pages). The scale test gate is a tested SLA against a synthetic corpus (see §Scale test at power-user tier in v0.9 gate).
- **Team-brain scale (100,000+ sources) is explicitly out of v0.x and v1.0 roadmap.** Reserved for v2.0+ on a separate roadmap. Conflicts with the local-only single-user single-machine constraint locked through v1.0.

### Timeline

- Phase 0 (Manual brain validation): 1 week
- Phase 1 (Plugin scaffold, 13 primitives, bin/lobster-run): 3 weeks
- Phase 2 (Marketplace publish, first install): 1 week
- Phase 3 (Author dogfood + pilot users, 12 polish skills + /brain:research + perf integration): 8–12 weeks
- **Total v0.x (through v0.9): 13–17 weeks**
- Phase 4 (v1.0 dispatcher migration): 4 weeks, gated on factory-dispatcher v1.0.0 existing

(`llm-second-brain-phased-build-plan.md` §2; elicitation-notes.md §7.2)

### Resource

Single-author dogfood for Phases 0–2 (Josh Magady). Phase 3 expands to 3–5 invited pilot users. (`llm-second-brain-phased-build-plan.md` §3, §7.3; elicitation-notes.md §3.1)

### License and distribution

MIT. LICENSE file ships in v0.1 tarball. `drbothen/claude-mp` marketplace. Public repo from day one. (`llm-second-brain-plugin-plan.md` §27.2; `llm-second-brain-phased-build-plan.md` §6.1; `README.md`; project `CLAUDE.md`)

---

## Prior Art and References

### Methodology origins

- **Andrej Karpathy's LLM-wiki pattern.** Origin of the three-layer architecture (raw sources / wiki / schema), the index-first navigation discipline, and the principle that "the LLM bookkeeps, humans curate." Karpathy reports scale: ~100 sources, ~400K words, hundreds of wiki pages, all navigable by index-first reading. (`llm-second-brain-plan.md` §2.1)
- **Capture-to-output system.** Origin of: organize by TYPE at the wiki layer; the four connection types (A/B/C/D); the brief format (ONE THING / PROOF / TRANSFORMATION + 3 hooks + 3 closers); voice rules (short punchy sentences; closer written before body; avoid LinkedIn-speak). (`llm-second-brain-plan.md` §2.2)
- **Steph Ango's Obsidian Skills (kepano upstream).** Five skills teaching agents Obsidian fluency: obsidian-markdown (wikilinks, embeds, callouts, properties, highlights, nested tags), obsidian-bases, json-canvas, obsidian-cli, defuddle. (`llm-second-brain-plan.md` §2.3)
- **Defuddle (kepano/defuddle).** Web content extractor: URL or HTML in, clean markdown out. Achieves approximately 70–90% fewer tokens for the same article by stripping website chrome. Three usage paths: local CLI `npx defuddle <url>`, hosted `https://defuddle.md/?url=<encoded>`, npm package. brain-factory wraps this in `scripts/defuddle-fetch.mjs`. (`llm-second-brain-plan.md` §2.4; `llm-second-brain-phased-build-plan.md` §A.6)

### Competing implementations of the Karpathy LLM-wiki pattern (as of May 2026)

The Karpathy LLM-wiki pattern has **7 publicly-documented implementations as of May 2026**. brain-factory positions itself relative to these, not as an alternative methodology. The implementations fall into three categories.

**Claude Code skills (closest competitive prior art — pattern as agent-discoverable skill files):**

- **`Astro-Han/karpathy-llm-wiki`** (MIT, 833 stars) — Claude Code skill implementing the Karpathy pattern as a single skill package. Defines ingest/query/lint operations against the same `raw/` + `wiki/` + `index.md` + `log.md` scaffold brain-factory targets. Closest third-party skill competitor. Gene-transfusion candidate: cloned to `.reference/karpathy-llm-wiki/`. (`.factory/planning/reference-repos.md` §2.6)
- **`lewislulu/llm-wiki-skill`** (MIT, 499 stars) — Claude Code skill with the Karpathy pattern; includes Python scripts, TypeScript libraries, Obsidian plugin, and a Node.js preview server. Multi-language reference value. Gene-transfusion candidate: cloned to `.reference/llm-wiki-skill/`. (`.factory/planning/reference-repos.md` §2.6)
- **`kfchou/wiki-skills`** (MIT, 134 stars) — Claude Code skill collection with six skills (init/ingest/query/audit/lint/update). Lighter coverage than Astro-Han/lewislulu; external-doc-only reference. (`.factory/planning/reference-repos.md` §2.6)

**Vault-based or repo-based implementations (Obsidian-style or standalone):**

- **Farzapedia** (**private repo** — Farza explicitly stated it will not be made public; only `farza wiki-gen-skill.md` gist is public at `gist.github.com/farzaa/c35ac0cfbeb957788650e36aabea836d`; **Karpathy-endorsed** via tweet status 2040572272944324650) — the reference implementation Karpathy himself endorsed. Personal-Wikipedia built by extracting from diary/Apple Notes/iMessages: 2,500 raw entries → 400 detailed articles. The gist reveals six operations (ingest/absorb/query/cleanup/breakdown/status) and a directory taxonomy (people/, projects/, philosophies/, patterns/, transitions/, decisions/, eras/). (`.factory/planning/reference-repos.md` §2.2)
- **`NicholasSpisak/second-brain`** (no LICENSE file — all-rights-reserved default; read-only reference; 322 stars) — Obsidian vault template implementing the Karpathy pattern. Vault template + methodology copy; not a Claude Code plugin. Cannot transfuse code. (`.factory/planning/reference-repos.md` §2.3)
- **`nashsu/llm_wiki`** (**GPL-3.0 — incompatible with brain-factory's MIT for code copying**; read-only reference; 7.5k stars; v0.4.10 May 2026) — a cross-platform desktop application (TypeScript + Rust, Tauri v2 + React 19) implementing the Karpathy pattern. Not a Claude Code plugin; standalone app. (`.factory/planning/reference-repos.md` §2.4)

**Pattern variants and gists:**

- **`rohitg00`'s LLM Wiki v2 gist** — extends Karpathy with lessons from "building agentmemory"; memory lifecycle, hybrid retrieval (BM25 + vector + entity graph), multi-agent collaboration. Community-maintained methodology document. (`.factory/planning/reference-repos.md` §2.5)

None of these 7 implementations ship as a distributable plugin with hook-enforced governance, cognitive-diversity adversarial review, scale-aware architecture targeting 10K-source corpora, or a WASM migration path. The 3 Claude Code skill packages (Astro-Han, lewislulu, kfchou) are the closest competitive tier — same packaging category (Claude Code skills) — but they are skill-only: no hook layer, no agents, no GH Actions, no lifecycle discipline, no scale-aware architectural commitments. brain-factory operates at a different stack tier: the methodology becomes versioned, governed, enforced, scale-aware plugin infrastructure rather than a vault-by-vault or skill-only hand-rolled effort.

### Real-world practitioner reports at 6-month scale

Two published reports document the methodology at production scale and the failure modes brain-factory's design directly addresses:

- **Liu's 6-month report** (Obsidian; ~35-page wiki accumulated): documents drift, hallucination, and ownership-noise failure modes after unsupervised LLM curation. [Source: OpenAIToolsHub — Karpathy's LLM Wiki, Six Months In] (`.factory/planning/brief-research.md` §2.3)
- **Nguyen's 6-month practitioner report** (AWS-ops; ~77-page wiki, 30+ sources, 13 custom skills): documents index-log drift and orphan-page accumulation. [Source: Tom Nguyen Medium] (`.factory/planning/brief-research.md` §2.3)

brain-factory's hook layer (source-immutability, wikilink-integrity, index-log-coherence, frontmatter-schema), the adversarial-review skill, and the lint-wiki health check are designed against these specific documented failures.

### Plugin pattern origins

- **vsdd-factory.** Sister plugin and origin of: engine/target split (engine in `~/.claude/plugins/.../brain-factory/<version>/`, state in `<brain>/.brain/`); hook-enforced discipline at PreToolUse/PostToolUse/SessionStart/Stop; declarative governance via `policies.yaml`; adversarial review with cognitive-diversity rule; cycle-scoped vs. living artifacts; 16 lifted principles. brain-factory is the second consumer of these patterns. vsdd-factory scale for reference: 33 specialists, 52 WASM hooks, 18 policies, 534 bats tests across 17 suites. brain-factory adapts to a slimmer roster: 14 agents, 13 hooks, 10 policies, 9 bats suites. (`llm-second-brain-plugin-plan.md` §3; `vsdd-dispatcher-extraction-plan.md` §2)

### Content lifecycle patterns absorbed from wclaude

Content lifecycle patterns absorbed from wclaude (8 absorptions): see §Family Positioning above for the full enumeration. Summary: 4 validation agents (one absorption group: voice-analyzer, content-structure-reviewer, frontmatter-validator, platform-compliance-checker) + writescore-revision-loop + --finalize flag + frontmatter state machine + drafts/to-publish/published directory + 3 flag absorptions on existing skills (--companion-posts, --schedule, --hero-prompt). All re-implemented in brain-factory style; not code-copied.

The GitHub remote (drbothen/wclaude) is currently private (as of May 2026); to be transitioned to PUBLIC before v0.1 release. For pre-v0.1 verification: inspect `/Users/jmagady/Dev/wclaude/` locally.

(Sources: wclaude README.md; wclaude CLAUDE.md; locked decision in brief prompt §wclaude-absorption)

### Real-world content workflow studied

- **thought-leadership repository** (the user's actual content workflow): LinkedIn as the committed v0.x platform (Medium demoted to reference extension per `.factory/planning/brief-research.md` §6.1); articles (1000+ words) and posts (<3000 chars) as the two content types; `to-publish/{platform}/` queue for automation; research sidecar structure under `content/articles/research/`; companion post atomization strategy. (thought-leadership CLAUDE.md; locked decision in brief prompt §platforms-lock)

### Future shared infrastructure

- **factory-dispatcher.** Planned shared repo extracting four engine crates and five sink crates from vsdd-factory. Hosts `factory-dispatcher` binary (Rust), `hook-sdk`, `hook-sdk-macros`, `context-resolvers-core`, and `sink-{file,otel-grpc,datadog,honeycomb,http}`. Published as cross-compiled binaries on GitHub Releases for five platforms plus crates on crates.io. brain-factory's v1.0 migration is a **13-hook** WASM port — simpler than vsdd-factory's 52-hook migration because brain-factory doesn't ship its own dispatcher, only consumes the shared one. (Adjusted from §8.3's 12-hook baseline: wclaude absorption adds `validate-publish-state.sh`.) (`vsdd-dispatcher-extraction-plan.md` §3; `llm-second-brain-phased-build-plan.md` §8.1)

---

## Reference Repositories

brain-factory ingests selected reference codebases via `.reference/` for gene-transfusion (proven solutions adapted) and architectural pattern reference. The full research catalog — including methodology, verification approach, and per-repo gene-transfusion assessment — is at `.factory/planning/reference-repos.md`.

**Directory convention:** `.reference/` (singular), direct clones — not git submodules. Verified: prism uses direct clones at `.references/` (each reference has its own `.git/config`; no `.gitmodules` at prism root). brain-factory uses the same direct-clone approach with singular spelling. `.reference/` is added to `.gitignore` so the clones are local-only and don't bloat the plugin repo history.

### Cloned into `.reference/` (7 repos)

1. **`vsdd-factory`** (`drbothen/vsdd-factory`, MIT) — sister plugin; engine/target split, hook contract patterns, 33-agent routing, dispatcher architecture, 534 bats tests across 17 suites. Direct architectural template for brain-factory's own structure. Highest-value reference. (`reference-repos.md` §1.1)

2. **`wclaude`** (`drbothen/wclaude`; currently private as of May 2026; public-transition committed as v0.1 ship gate task — after transition, `gh repo clone drbothen/wclaude` works without owner credentials; MIT status: license unverified from unauthenticated vantage — devops-engineer must confirm MIT-compatibility before code transfusion) — content-publishing patterns absorbed: 4 validation agents (voice-analyzer, content-structure-reviewer, frontmatter-validator, platform-compliance-checker), writescore + revision-loop, `--finalize --url` flag, frontmatter state machine (draft → ready → published), drafts/to-publish/published directory structure, `--companion-posts` flag, `--schedule <date>` flag, `--hero-prompt` flag = 8 absorbed patterns. Same-author sister repo. For contributors before public transition: clone requires `gh auth login` with owner credentials; the MANIFEST documents this requirement. (`reference-repos.md` §1.2)

3. **`defuddle`** (`kepano/defuddle`, MIT, v0.18.1 Apr 22 2026) — hard runtime dependency for `/brain:ingest-url`. Reference for CLI interface (`npx defuddle parse [file/url]`) and library API (Defuddle class accepting DOM Document). Track upstream for API breaks — especially the post-0.13.0 string-deprecation and the 0.18.0 LinkedIn/Threads/Bluesky extractors. (`reference-repos.md` §3.1)

4. **`obsidian-skills`** (`kepano/obsidian-skills`, MIT, 31.3k stars) — canonical Obsidian Agent Skills format (5 skills: obsidian-markdown, obsidian-bases, json-canvas, obsidian-cli, defuddle). brain-factory's skills MUST conform to the same Agent Skills specification validated by these canonical examples. The `obsidian-markdown` skill defines wikilinks/embeds/callouts/properties semantics that brain-factory's ingest and wiki-page skills must understand. (`reference-repos.md` §3.2)

5. **`quartz`** (`jackyzha0/quartz`, MIT, v4.5.2, 12.2k stars) — static-site builder; reference for `/brain:export-brain` Quartz integration and for the v0.5 `garden-publish.yml` community-optional GH Action. Quartz is the path-of-least-resistance for "Obsidian vault → public site." Clone now for reference; integration scope confirmed in Phase 1c architecture. (`reference-repos.md` §4.1)

6. **`karpathy-llm-wiki`** (`Astro-Han/karpathy-llm-wiki`, MIT, 833 stars) — Claude Code skill implementing the Karpathy pattern. Closest third-party skill competitor. Defines ingest/query/lint against `raw/` + `wiki/` + `index.md` + `log.md`. Reference for skill body structure at the same target scaffold brain-factory uses. (`reference-repos.md` §2.6)

7. **`llm-wiki-skill`** (`lewislulu/llm-wiki-skill`, MIT, 499 stars) — Claude Code skill with Python scripts, TypeScript libraries, Obsidian plugin, Node.js preview server. Multi-language reference value for hook scripts and skill bodies. (`reference-repos.md` §2.6)

**devops-engineer bootstrap task (Phase 1):** Clone the 7 repos into `.reference/`. Add `.reference/` to `.gitignore`. Create `.reference/MANIFEST.md` with one row per repo: Path | URL | License | Cloned commit (SHA) | Cloned date | Purpose. **Create `.reference/README.md` documenting what each repo is and how brain-factory ingests from it (one section per repo: vsdd-factory, wclaude, defuddle, obsidian-skills, quartz, karpathy-llm-wiki, llm-wiki-skill).** wclaude: clone via `gh repo clone drbothen/wclaude .reference/wclaude`. After the v0.1 owner-public-transition task runs, this clone works with unauthenticated `gh`. Until then (during pre-v0.1 development), authentication is required. anthropics/claude-code is an optional 8th clone (for plugin SDK schema reference — devops-engineer decides in Phase 1c).

### External documentation only (cite, don't clone)

Notable cite-only references (full list in `.factory/planning/reference-repos.md`):

- `Karpathy gist` (`gist.github.com/karpathy/442a6bf555914893e9891c11519de94f`) — origin gist for the three-layer architecture and operations vocabulary.
- `farza wiki-gen-skill gist` (`gist.github.com/farzaa/c35ac0cfbeb957788650e36aabea836d`) — Farzapedia skill (Farzapedia repo is private; only the gist is public).
- `kfchou/wiki-skills` (MIT, 134 stars) — third Claude Code skill competitor; lighter pattern coverage than Astro-Han/lewislulu; external-doc-only.
- `drbothen/claude-mp` — marketplace manifest (one JSON file; cite-only sufficient).
- `anthropics/claude-plugins-official` — 101 production plugins; cite schema docs, don't clone wholesale.
- `linkedin-developers/linkedin-api-python-client` (MIT) — LinkedIn Posts API OAuth flow reference; not a direct dependency (brain-factory will likely call the REST API directly).
- `Medium/medium-api-docs` (archived Mar 2 2023) — deprecated; cite-only for the OAuth2 + post-creation endpoint signatures.
- `NicholasSpisak/second-brain` (no LICENSE — read-only reference) — taxonomy reference; cannot clone for code use.

### Excluded from `.reference/` (license-incompatible or unavailable)

| Repo | Excluded because |
|---|---|
| `nashsu/llm_wiki` | GPL-3.0 — incompatible with brain-factory's MIT for code copying. Read-only reference only; do NOT clone. |
| `Farzapedia` repo | Private; Farza explicitly stated it will not be made public. Only the gist is accessible. |
| `anthropics/claude-plugins-official` | 101 plugins is too broad to clone wholesale; cite-only for schema docs. |
| `Medium/medium-sdk-nodejs` | Deprecated; no engineering value in a local copy. |

---

## Open Questions (deferred to PRD / architecture phases)

These questions are tracked here. Resolved entries retain strikethrough + Resolved annotation for traceability; un-struck entries are open. Each open entry has a clear ownership path and will be resolved before the phase that requires them.

1. **Specific pilot user list.** Who are the 3–5 Phase 3 operators? Lock by end of Phase 2 (before pilot onboarding begins). (`llm-second-brain-phased-build-plan.md` §13 #4)

2. ~~**Adversary model defaults.** Adversary model defaults are locked in v0.x as Opus producer + Sonnet adversary (or vice-versa for different-family rotation). Operators MAY override via `.brain/policies.yaml`.~~ **Resolved (v0.3.1 brief, user-confirmed):** Lock = Opus producer + Sonnet adversary by default; operator override via `.brain/policies.yaml`. (`llm-second-brain-phased-build-plan.md` §13 #6; elicitation-notes.md Q-5)

3. **Token-budget alert threshold.** Default value for the monthly-perf check that surfaces excessive per-ingest cost. Lock before Phase 3 (when adversary review starts running per-ingest at scale). (`llm-second-brain-phased-build-plan.md` §13 #7; elicitation-notes.md Q-6)

4. **Quartz integration depth for `/brain:export-brain`.** Bake in Quartz templates, or instruct the operator to install Quartz externally and invoke via `/brain:export-brain --static-site`? Lock before Phase 3 polish skill implementation. (`llm-second-brain-plugin-plan.md` §24 #8; elicitation-notes.md Q-11)

5. **API rate-limit handling for LinkedIn perf pulls.** Does `/brain:monthly-perf` implement retry-with-backoff, or surface a "rate limited — retry in X" advisory and exit? Lock before v0.5 milestone. (Medium perf pulls, if used via the reference extension, follow the same pattern but are the extension's responsibility to document.)

6. **Whether meta-lint runs as pre-commit hook or only in CI.** Currently defined as pre-commit (subset) and pre-push (full) in CLAUDE.md. Lock whether the pre-commit subset is in lefthook.yml scope for Phase 1d toolchain bootstrap. (CLAUDE.md Meta-Lint Contract; elicitation-notes.md Q-19 analogy)

7. **Extension schema at `plugins/brain-factory/extensions/<platform>/`.** Exact hook contract and frontmatter schema for a community extension. Extension schema MUST be locked in Phase 1c (architecture). The v0.5 Medium reference extension is conditional on this prerequisite landing — without it, the v0.5 milestone cannot be claimed. (locked decision §platforms-lock)

8. ~~**`/brain:research` output targets.**~~ **Resolved (v0.3.0 brief, user-confirmed).** `/brain:research` writes to BOTH `wiki/` pages AND `briefs/research/<topic>-research.md`. Both outputs are committed; no flag controls the mix. The `briefs/research/` directory is created by `/brain:init` as a brief-introduced extension beyond phased-build-plan §A.2's five enumerated `briefs/` subdirs (daily, weekly, monthly, content, decisions).

9. **License obligation transparency for wclaude pattern absorption.** brain-factory re-implements patterns from wclaude (both are the same author's work; no code is copied). Document in CHANGELOG and ATTRIBUTION or README that the four agent patterns and the writescore revision loop are re-implementations inspired by wclaude. Ensures any future open-source contributor understands the lineage. Lock wording before v0.1 publish.

10. **Pilot brain content: fresh start or author's existing reading backlog?** Does Phase 3 pilot begin with an empty vault (clean methodology test) or with a backlog of the author's historical sources pre-ingested? (`llm-second-brain-plugin-plan.md` §24 #6; elicitation-notes.md Q-10)

11. **Medium API future status.** If Medium fully restores API access and accepts new integrations, should the reference extension at `plugins/brain-factory/extensions/medium/` be promoted to a core v0.x channel? Lock criteria before v0.5 milestone. (Current status: deprecated, legacy tokens only, best-effort — per `.factory/planning/brief-research.md` §6.1.)

12. **Post-Phase 3 evaluation criteria for default-research-backend reversal.** Web-search is the v0.9 default (per F-PASS8-I2 lock); Perplexity MCP is opt-in via `.brain/policies.yaml`. If Phase 3 dogfood reveals a dramatic Perplexity quality advantage, the default may reverse for v1.0. **Open dimension:** what measurable criteria (latency? citation accuracy rate? operator satisfaction score?) would trigger this reversal? Lock criteria before Phase 3 dogfood begins so the evaluation has a clear pass/fail threshold rather than a post-hoc judgment call.

---

## Traceability

**Citation conventions:** "plan.md" refers to `docs/planning/llm-second-brain-plan.md` (the methodology document); "phased-build-plan.md" refers to `docs/planning/llm-second-brain-phased-build-plan.md` (the build-sequencing document); "plugin-plan.md" refers to `docs/planning/llm-second-brain-plugin-plan.md` (the plugin packaging document). Each plan has its own §-numbering; cite the specific plan to disambiguate.

### Source planning documents

| Document | Sections cited |
|---|---|
| `docs/planning/llm-second-brain-plan.md` | §1 (failure modes, core promise), §2.1–2.4 (Karpathy, capture-to-output, Ango, Defuddle), §3.1–3.7 (five-layer architecture, six wiki types, prompt-injection), §5 (token budget), §8 (GitHub Actions) |
| `docs/planning/llm-second-brain-plugin-plan.md` | §0 (family positioning), §1 (capability table), §2 (engine/target split), §3 (16 principles), §4 (folder structure), §5 (25 skills), §6 (10 agents), §7.1, §7.3 (hook enforcement), §8 (Lobster workflows), §9 (templates), §10 (policies), §12 (convergence), §13 (roadmap phases), §20 (CI), §22–§24 (rollout, limitations, open questions), §27 (dispatcher migration) |
| `docs/planning/llm-second-brain-phased-build-plan.md` | §0 (sequencing premise), §1 (trade table), §2 (phase architecture), §3 (phase deliverables), §4 (Phase 0), §5 (Phase 1, §5.11 exit gate), §6 (Phase 2, §6.6 exit gate), §7 (Phase 3, §7.5 quality bar, §7.6 exit gate), §8 (Phase 4, §8.3 exit gate), §9 (same-vs-different table), §10 (decision gates), §12 (risks), §13 (open questions), §A.1–A.11 (embedded artifacts) |
| `docs/planning/vsdd-dispatcher-extraction-plan.md` | §2 (vsdd-factory baseline), §3 (factory-dispatcher target state), §27 step 5 (brain-factory migration) |

### Sibling references

| Sibling | Role in this brief |
|---|---|
| `../wclaude` | Content-publishing sister plugin (drbothen/wclaude; private as of May 2026; public-transition planned pre-v0.1 ship gate); 8 absorptions: one absorption group for 4 validation agents + 7 individual pattern absorptions (writescore-revision-loop, --finalize flag, frontmatter state machine, directory structure, --companion-posts flag, --schedule flag, --hero-prompt flag). See §Family Positioning for the full enumeration. For contributor reproducibility of `.reference/` bootstrap, wclaude must be public by the time external pilots attempt clean install. |
| `../thought-leadership` | Author's actual content workflow; originally referenced Medium + LinkedIn; v0.2.0+ brief demotes Medium to reference extension (deprecated API, state preserved through the current version) and commits LinkedIn as the sole core v0.x platform; content types (articles + posts) and directory structure adopted into brain-factory's target layer |

### Elicitation notes

`.factory/planning/elicitation-notes.md` — research-agent extraction (created 2026-05-14) covering vision (§1), problem (§2), users (§3), value (§4), scope (§5), success criteria (§6), constraints (§7), prior art (§8), 25 open questions (§9.1 contradictions, §9.2 planning-doc open questions, §9.3 surfaced questions), and full citations map (§10).

### Stage 3 locks

`.factory/planning/stage-3-locks.md` — artifact recording all 11 Stage 3 elicitation user-locks (created 2026-05-15) (SL-1 through SL-11). The brief's v0.9 scale-test source attribution at §Success Criteria cites SL-9 (scalability scope) and SL-10 (scale target: power-user 10x Karpathy). Created in response to adversary Pass 4 Finding F-NEW4-1, which identified that elicitation-notes.md (Stage 2) did not record Stage 3 decisions.

### Brief-level research

`.factory/planning/brief-research.md` — brief-level research report (created 2026-05-14) with 11 VALIDATES / 2 REVISE / 6 WATCH classifications across 6 topics: competitive landscape, Karpathy LLM-wiki pattern reception, Claude Code plugin marketplace maturity, Defuddle current state, Obsidian skills upstream, and Medium + LinkedIn API state. Critical findings driving brief revisions: Medium API officially deprecated (REVISE → demoted to reference extension); LinkedIn UGC API replaced by Posts API (REVISE → terminology corrected throughout); competing Karpathy implementations identified (WATCH → differentiator reframe applied).

### Brief lifecycle

`draft` → adversarial review (Stage 5) → human-approve (Stage 6) → state-manager commit

---

## Self-Audit Checklist (completed before delivery)

Per CLAUDE.md Canonical Principle Self-Audit Checklist:

- [x] Did I rationalize any decision with "MVP," "for now," "good enough," or "we can fix later"? **No.** All counts (26 skills, 14 agents, 13 hooks, 19 action templates = 15 author-committed + 4 community-optional, 9 bats suites, 8 wclaude absorptions) are stated as exact commitments, not approximations. The v0.9 ship gate requires 7-phase VSDD-pipeline convergence, not "aims for." **Per-version fix-burst details: see the Changelog block at top of brief.**
- [x] Did I add a new tech-debt-register entry without all three of: explicit human direction, concrete future dependency, and a specific future story/wave anchor? **No.** No tech-debt-register entries created.
- [x] Did I leave any "pending architect review," "TODO for architect," or "Placeholder for architect" in a spec artifact for a question I could have answered in scope? **No.** Open Questions section lists only questions that require human decision or future-phase information (pilot list, model defaults, threshold values). None are answerable from current planning docs.
- [x] Did I find a bug or gap in another AI's output and surface it as a question/advisory instead of fixing it in scope? **No.** All contradictions from elicitation-notes.md §9.1 were resolved in the brief (C-1 through C-9) and all brief-research.md §6.1–6.2 REVISE findings were resolved in scope. **Per-version fix-burst details: see the Changelog block at top of brief.**
- [x] Did I default to the cheapest mechanism instead of the correct mechanism? **No.** The Node 20+ dependency for Defuddle (previously surfaced as Q-20 in elicitation notes) is stated explicitly as a prerequisite rather than softened. The 5-minute init SLA is stated as a tested integration-test assertion.
- [x] If I added an ADVISORY-severity finding to a report, did I evaluate whether it should be a BLOCKER? **No advisory findings produced.** Brief is a spec artifact, not a review.
- [x] Did I paper-fix a finding by renaming, doc-commenting, or asserting-only when the real fix is structural? **No.** The hook count (13, not 12) reflects the structural reality of the wclaude absorption adding `validate-publish-state.sh`. CLAUDE.md alignment to Node 20+ lock (F-3): CLAUDE.md is being aligned to the brief's toolchain lock by state-manager in parallel — structural fix, not paper fix.
- [x] Did I sibling-sweep all callsites when I changed a hook signature, exit-code semantic, or canonical identifier? **Not applicable to a brief.** Canonical identifiers introduced here (hook names, skill names, agent names) are consistent throughout. Each fix-burst performs a sibling-sweep of all affected callsites before delivery. **Per-version fix-burst details: see the Changelog block at top of brief.**
- [x] Did I modify a planning artifact in `docs/planning/` without explicit human direction? **No.** All writes go to `.factory/specs/`.
- [x] Did I cross-check every `locked_decisions` field in frontmatter against the body section that implements it, asserting numeric, naming, and scope consistency? **Yes.** All `locked_decisions` fields verified against body sections: counts (26 skills, 14 agents, 13 hooks, 19 actions, 9 bats suites, 8 wclaude absorptions), scale targets, reference repo layout, platform commitments, and stage_3_locks path all cross-checked and consistent. **Per-version fix-burst details: see the Changelog block at top of brief.**
