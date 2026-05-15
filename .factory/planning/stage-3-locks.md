---
artifact_type: stage-3-locks
purpose: record-user-locked-decisions-from-stage-3-elicitation
phase: phase-1a-stage-3
status: complete
created: 2026-05-15
author: vsdd-factory:orchestrator (recorded by state-manager)
related_artifacts:
  - .factory/planning/elicitation-notes.md (Stage 2 research-agent extraction)
  - .factory/planning/brief-research.md (Stage 4-adjacent research)
  - .factory/planning/reference-repos.md (Stage 4-adjacent research)
  - .factory/specs/product-brief.md (Stage 4-6 product authorship)
total_locks: 10
---

# Stage 3 Elicitation User-Locks

This file records all decisions the user explicitly locked during Stage 3 of the
guided-brief-creation skill (the AskUserQuestion exchanges between orchestrator
and human, recorded as authoritative product-decisions for the brief). Each lock
is sourced to a specific orchestrator-session question; the brief at
`.factory/specs/product-brief.md` cites this file for traceability.

## Lock format

Each lock has:
- **ID:** SL-N (Stage Lock N)
- **Question asked:** the AskUserQuestion text presented to the human
- **Options offered:** the multi-select choices
- **User selection:** the option(s) the human picked
- **Date locked:** 2026-05-14 unless otherwise noted
- **Brief sections affected:** which sections of the brief depend on this lock

---

## SL-1 — v0.x toolchain includes Node 20+

**Question asked:** "The phased plan says 'no Node runtime in v0.x' but Defuddle CLI and run-skill.mjs both require Node 20+. How should the brief frame v0.x toolchain?"

**Options offered:** Embrace Node 20+ as required; Make Defuddle optional, graceful degrade; Defer Defuddle and scheduled actions to v0.5+

**User selection:** Embrace Node 20+ as required

**Brief sections affected:** Frontmatter `toolchain` field; Constraints §Technical; Target Users §Phase 3+ general operators

---

## SL-2 — v0.9 commits to all 26 skills functionally complete

**Question asked:** "What does v0.9 commit to for skill coverage?"

**Options offered:** All 25 skills functionally complete by v0.9; 13 primitives + 7 high-leverage by v0.9 (~20 total); All 25, but v0.9 gate is structural

**User selection:** All 25 skills functionally complete by v0.9 (later expanded to 26 after adding /brain:research as #26)

**Brief sections affected:** Frontmatter `skill_count_v0_9`; Scope §In scope §26 skills; v0.9 ship gate

---

## SL-3 — Ship bin/lobster-run in v0.x

**Question asked:** "Do .lobster workflows execute headlessly in v0.x, or do they live as docs the orchestrator agent reads?"

**Options offered:** Declarative-only in v0.x; Ship a minimal bash Lobster runner in v0.x; Lobster runtime is a v1.0 deliverable

**User selection:** Ship a minimal bash Lobster runner in v0.x

**Brief sections affected:** Frontmatter `lobster_runtime`; Vision; Scope §bin/lobster-run

---

## SL-4 — Full self-VSDD in v0.x

**Question asked:** "What does the brief commit to regarding brain-factory's own development discipline (self-VSDD)?"

**Options offered:** Full self-VSDD in v0.x; Informal self-VSDD in v0.x; Self-VSDD deferred to v1.0

**User selection:** Full self-VSDD in v0.x

**Brief sections affected:** Frontmatter `self_vsdd`; v0.9 ship gate (7-phase VSDD-pipeline convergence); Constraints §Self-VSDD

---

## SL-5 — Add /brain:research as 26th skill

**Question asked:** "The brain-factory plan has /brain:ingest-url (known URL) and /brain:ingest-source (local file) but no user-invokable 'research a topic from scratch' skill (wclaude's research-topic). Add it?"

**Options offered:** Add /brain:research as the 26th skill; Don't add it — use /brain:ingest-url with --research flag; Don't add user-invokable research at all in v0.x

**User selection:** Add /brain:research as the 26th skill

**Brief sections affected:** Frontmatter `skill_count_v0_9: 26`; Scope §26 skills item #26; v0.1 ship gate

---

## SL-6 — Take the wclaude absorption proposal as-is

**Question asked:** "Does this wclaude-absorption split match what you want, or do you want to keep/drop different pieces?"

**Options offered:** Take this split as proposed; Take more from wclaude; Take less from wclaude; Different split

**User selection:** Take this split as proposed (then later: "follow brain-factory plan completely, just merge useful or good ideas from wclaude")

**Brief sections affected:** §Family Positioning (8 wclaude patterns absorbed); Frontmatter `wclaude_absorption`

---

## SL-7 — Platforms: Medium + LinkedIn + extension hooks

**Question asked:** "Platforms for v0.x publishing + /brain:monthly-perf (now that brain-factory absorbs wclaude's publishing role)?"

**Options offered:** Medium + LinkedIn only (matches your workflow); Medium + LinkedIn + Substack; Medium + LinkedIn + extension hooks

**User selection:** Medium + LinkedIn + extension hooks (later revised in F-research and Pass-2 fix-burst: Medium demoted to reference extension; v0.x core platforms = LinkedIn only; Medium = first reference extension demonstrating the extension pattern)

**Brief sections affected:** Frontmatter `publish_platforms`, `v0_x_committed_platforms`, `medium_v0_x_status`, `perf_tracking`; Scope §Platforms

---

## SL-8 — Publish-content semantics aligned with wclaude (not extended)

**Question asked (across multiple turns):** "How should brain-factory and wclaude relate around publishing?"

**User free-text response:** "i only want brain-factory at the end of this. I need you to take the ideas from wclaude that you like and adapt them to the factory method we are building in brain-factory"

**Resolution:** brain-factory absorbs wclaude's publishing role; wclaude's 8 patterns merged into brain-factory's v0.x agent roster and skill surface

**Brief sections affected:** §Family Positioning (wclaude absorption block); §Prior Art (wclaude entry); Reference Repositories (wclaude as cloned reference)

---

## SL-9 — Scalability scope: Discipline + measured v0.9 scale test

**Question asked:** "What does 'infinitely scalable from day one' mean concretely for the brief? Pick the level of commitment you want locked."

**Options offered:** Design discipline only; **Discipline + measured v0.9 scale test**; Discipline + measured + cross-scale benchmarks; Discipline now + scale-test gate moved to v1.0

**User selection:** Discipline + measured v0.9 scale test

**Brief sections affected:** §Scalability Design Principles (7 disciplines); v0.9 ship gate §Scale test at power-user tier (6 pass criteria); Frontmatter `scale_test_v0_9_gate: required`

---

## SL-10 — Scale target: Power-user (10x Karpathy)

**Question asked:** "What scale targets does brain-factory care about? This anchors the v0.9 scale test (if you picked options 2/3 above) or sets architectural design constraints."

**Options offered:** Personal-brain scale (Karpathy reference); **Power-user scale (10x personal)**; Team-brain scale (100x personal); All three with degradation curves

**User selection:** Power-user scale (10x personal) — ~10,000 sources, ~40M words, ~10,000 wiki pages

**Brief sections affected:** Frontmatter `scale_target_v0_9: power-user (~10000 sources / ~40M words / ~10000 wiki pages)`; §Scalability Design Principles preamble; v0.9 ship gate §Scale test pass criteria; Constraints §Technical §Scale target; Out of Scope §team-brain scale

---

## SL-11 — Reference repos to clone

**Question asked (across multiple turns):** Identification of reference repos for .reference/ directory ingestion; wclaude framing as private sister repo; Karpathy prior-art bump to 7+ implementations

**User selection:** (a) "Make wclaude public before v0.1"; (b) "Bump prior-art list to 7+ implementations"; (c) clone from local ../wclaude/ path; (d) use singular .reference/ directory name

**Brief sections affected:** §Reference Repositories (7 cloned + external-doc-only + excluded); Frontmatter `reference_repo_count: 7`, `reference_repo_layout`, `wclaude_repo_status: transitioning-private-to-public-before-v0.1`; v0.1 ship gate (wclaude public-transition task)

---

## Notes on lock provenance

- All locks recorded in this artifact were originally captured via Claude Code AskUserQuestion exchanges in the orchestrator session that authored brief v0.1.0–v0.4.1.
- This artifact was created (state-manager dispatch) in response to adversary Pass 4 Finding F-NEW4-1, which identified that elicitation-notes.md did not contain Stage 3 locks (it predates Stage 3, being the Stage 2 research-agent extraction).
- Future Stage-N elicitations should persist their locks here OR in a numbered companion artifact (stage-N-locks.md).
- This artifact is the canonical source for the brief's Stage 3 lock citations.
