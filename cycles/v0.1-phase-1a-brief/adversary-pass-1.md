---
artifact_type: adversary-pass-report
pass_number: 1
cascade: brain-factory-product-brief-v0.2.0
target_file: .factory/specs/product-brief.md
target_version: 0.2.0
adversary_protocol: BC-5.39.001 3-CLEAN
streak: 0/3
created: 2026-05-14
author: vsdd-factory:adversary
inputs:
  - .factory/specs/product-brief.md
  - .factory/planning/elicitation-notes.md
  - .factory/planning/brief-research.md
  - CLAUDE.md
  - docs/planning/llm-second-brain-phased-build-plan.md (spot-checked)
finding_count_critical: 4
finding_count_important: 11
finding_count_suggestion: 5
finding_count_process_gap: 2
verdict: FAIL
---

# Adversary Pass 1 Report

> **Note:** This file persists the metadata for Pass 1. The adversary ran in read-only mode
> (`Read`, `Grep`, `Glob` only — no `Write`), so the report was returned inline to the
> orchestrator session. The full verbatim content is in the orchestrator session log.
> The fix-burst that responded to this pass is committed in a subsequent commit on main
> (factory-artifacts collocated with main pre-v0.1).

## Verdict: FAIL

Streak: 0/3. The product brief contains 4 CRITICAL findings, 11 IMPORTANT findings,
5 SUGGESTION findings, and 2 PROCESS-GAP findings. The brief must be remediated and
resubmitted for Pass 2 before the cascade can advance.

---

## CRITICAL Findings

**F-1 [CRITICAL] — Node/JS runtime contradiction**
The brief locks "Node 20+ required" (Stage 3, user-confirmed) but earlier sections
still contain "no JS runtime" language inherited from the phased build plan framing.
This contradiction will cause implementer mis-builds in Phase 3. CLAUDE.md line 5
also contradicts the brief on this point (separate fix required).

**F-2 [CRITICAL] — Defuddle scope undefined**
The brief references Defuddle CLI for web extraction (~70-90% token savings) but
does not define: which skill invokes it, what input/output contract it has, what
happens when Defuddle fails or produces degraded output, or whether it is required
or optional at the operator level. Without this, the BC writer cannot write a
testable contract.

**F-3 [CRITICAL] — run-skill.mjs role ambiguous**
`scripts/run-skill.mjs` is cited as a "headless skill runner powering scheduled
GitHub Actions" but the brief does not specify: what the script inputs/outputs are,
whether it is in-scope for Phase 1 stories or deferred to Phase 3+, who owns the
Node runtime dependency installation, or how it interacts with the hook chain.
A BC cannot be written until this is resolved.

**F-4 [CRITICAL] — Token savings claim unanchored**
The "~70-90% token savings" figure for Defuddle is cited without a source, test
methodology, or scope (savings on what baseline? full-page HTML vs Defuddle output?
for which content types?). This figure will propagate into the PRD as a performance
NFR and become unverifiable. Either anchor it to the research artifact that produced
it, or qualify it as "claimed, unvalidated" with a VP to validate during Phase 4.

---

## IMPORTANT Findings

**F-5 [IMPORTANT] — Phase gating for Node utilities not specified**
The brief says Node 20+ is required for Defuddle and run-skill.mjs but does not
specify which phase introduces each dependency. Phase 0 (manual brain) should have
zero Node requirements; Phase 1 hooks are pure bash. If Node is introduced in
Phase 1, the "pure bash for tests/hooks" claim becomes false mid-phase. Clarify
the phase boundary.

**F-6 [WITHDRAWN]**
Finding withdrawn after review; issue was superseded by F-3.

**F-7 [IMPORTANT] — GitHub Actions templates count unverified**
The brief references "18 GitHub Action templates" but the phased build plan's
appendix lists a different breakdown. The count must be reconciled against the
authoritative source before story decomposition.

**F-8 [IMPORTANT] — Operator-machine vs CI environment conflation**
"Node 20+ required at the operator's machine" — but GitHub Actions (the scheduled
runner) IS the CI environment, not the operator's machine. The distinction between
local-dev requirements and CI runner requirements is not drawn. This will cause
confusion in Phase 1d toolchain bootstrap.

**F-9 [IMPORTANT] — factory-dispatcher dependency chain underspecified**
"WASM hooks via factory-dispatcher = v1.0 (post-MVP)" appears in the brief but
the dependency chain is not specified: what version of vsdd-factory ships the
dispatcher extraction? Is there a tracking issue? What is the fallback if
factory-dispatcher v1.0 does not ship before brain-factory v1.0 is needed?

**F-10 [IMPORTANT] — Exit gate for Phase 0 not reflected in brief**
The phased build plan defines Phase 0 exit gates. The brief's success criteria
do not map onto these gates. If the brief is the authoritative source for Phase 1
spec crystallization, the exit gates need to appear in the brief or be explicitly
deferred to the phased build plan (with a reference).

**F-11 [IMPORTANT] — "Second brain" term undefined in brief**
The brief uses "second brain" extensively but does not define it in the ubiquitous
language section. This leaves the L2 domain spec author without a canonical
definition to anchor entity definitions to.

**F-12 [IMPORTANT] — Operator persona not distinguished from author persona**
The brief conflates "the person using the brain" with "the person operating the
plugin." These may be the same person but the roles have distinct responsibilities
(one writes wiki pages, one configures hook settings). Failing to distinguish them
will produce ambiguous BCs.

**F-13 [IMPORTANT] — "Source immutability" rule scope unclear**
The brief references source-immutability hashing but does not define what counts
as a "source" vs a "wiki page" vs a "brief." The phased plan §A.4 defines it
but the brief should carry the definition so Phase 1b BC writers have a
self-contained reference.

**F-14 [WITHDRAWN]**
Finding withdrawn after review; out of scope for brief layer.

**F-15 [IMPORTANT] — Scheduled GitHub Actions trigger conditions unspecified**
The brief mentions scheduled GitHub Actions but does not specify: what schedule,
what triggers besides cron, how failures are surfaced to the operator, and what
the retry policy is. These are Phase 2+ concerns but need a placeholder in the
brief's out-of-scope section to prevent scope creep into Phase 1.

**F-16 [IMPORTANT] — Brief version history missing**
The brief is at v0.2.0 but there is no changelog section or version history.
The adversary cannot determine what changed from v0.1.0 to v0.2.0, making it
impossible to verify that prior findings were addressed.

---

## SUGGESTION Findings

**F-17 [SUGGESTION] — Add a "non-goals" section**
The brief lacks an explicit non-goals section. Several implicit non-goals
(no JS test framework, no compiled binaries in v0.x, no concurrent multi-user
support) are scattered through the document. Consolidating them into a
non-goals section would reduce contradiction risk.

**F-18 [SUGGESTION] — Defuddle fallback behavior should be suggested**
Even if the full contract is deferred to Phase 1b, the brief should suggest
the intended graceful-degradation behavior when Defuddle is unavailable or
fails, so the product-owner has direction when writing BC-level error handling.

**F-19 [SUGGESTION] — Cross-reference to CLAUDE.md should be explicit**
The brief implicitly assumes CLAUDE.md is read alongside it (they share the
Node 20+ lock) but does not cite CLAUDE.md as a co-input. This makes
the brief appear self-contradictory to a reader who hasn't read CLAUDE.md.

**F-20 [SUGGESTION] — "Plugin" vs "factory" naming consistency**
The brief uses "plugin" and "factory" interchangeably in some sections.
The canonical name is "brain-factory" (a Claude Code plugin in the factory
family). Suggest standardizing: "brain-factory plugin" for the installed
artifact, "factory" for the pipeline that builds it.

**F-21 [SUGGESTION] — Success metric for token savings should be time-bounded**
"~70-90% token savings" as a success criterion has no measurement point
specified. Suggest: "at Phase 4 holdout evaluation, a representative batch
of 10 web articles processed via `/brain:ingest-url` must demonstrate ≥70%
token reduction vs. raw HTML baseline."

---

## Process-Gap Findings

**F-PG-1 [PROCESS-GAP] — Brief was modified without adversary sign-off**
The brief is at v0.2.0 but there is no record of Pass 0 or Pass 1 for v0.1.0.
Either v0.1.0 was never adversarially reviewed (process gap: the 3-CLEAN
protocol should have applied to v0.1.0 before v0.2.0 was produced), or the
pass reports were not persisted (a bookkeeping gap). Per BC-5.39.001, every
version increment requires a clean cascade, not just the final version.

**F-PG-2 [PROCESS-GAP] — Elicitation notes not linked from brief frontmatter**
The brief does not list `.factory/planning/elicitation-notes.md` or
`.factory/planning/brief-research.md` in its `inputs` frontmatter field.
These documents were used by the product-owner to produce the brief but
are not formally cited. This breaks input-hash drift detection
(`/vsdd-factory:check-input-drift`).

---

## Citation Spot-Check Audit

Ten citations from the brief were spot-checked against their source documents.

| # | Citation in Brief | Source Doc | Verdict |
|---|---|---|---|
| 1 | "Phase 0: manual brain, 1 week" | phased-build-plan §4 | VERIFIED |
| 2 | "Phase 1: plugin scaffold with bash hooks, 3 weeks" | phased-build-plan §4 | VERIFIED |
| 3 | "~70-90% token savings (Defuddle)" | brief-research.md | UNVERIFIED — research doc does not contain this figure; adversary could not locate source |
| 4 | "18 GitHub Action templates" | plugin-plan §3 | PARTIAL — plugin-plan lists 17, not 18; off-by-one |
| 5 | "bats-core for tests" | phased-build-plan §A.4 | VERIFIED |
| 6 | "WASM dispatcher = factory-dispatcher v1.0" | vsdd-dispatcher-extraction-plan §2 | VERIFIED |
| 7 | "exit code 0/1/2 semantics" | phased-build-plan §A.4 | VERIFIED |
| 8 | "Node 20+ required for Defuddle" | elicitation-notes.md (Stage 3) | VERIFIED — human-confirmed lock |
| 9 | "run-skill.mjs headless skill runner" | elicitation-notes.md (Stage 3) | VERIFIED — human-confirmed |
| 10 | "source immutability via sha256sum" | phased-build-plan §A | VERIFIED |

**Citation failures:** 2 of 10 (citations 3 and 4). Both require remediation before Phase 1b.

---

## Count Reconciliation

| Claim | Stated | Verified | Delta | Status |
|---|---|---|---|---|
| GitHub Action templates | 18 | 17 (plugin-plan §3) | -1 | MISMATCH — brief overcounts |
| Phase count | 5 (0-4) | 5 | 0 | OK |
| Skill count (planned) | ~25 | ~25 (plugin-plan §4) | 0 | OK |
| Specialist agent count | 10 | 10 (plugin-plan §4) | 0 | OK |
| Hook exit code values | 3 (0/1/2) | 3 | 0 | OK |

---

## Comments on Locked-Decision Coverage

The brief contains 22 locked decisions (Stage 1–3). The adversary reviewed all 22.

| Lock # | Decision | Coverage in Brief | Status |
|---|---|---|---|
| L-1 | Bash hooks for v0.x | Covered | OK |
| L-2 | bats-core for tests | Covered | OK |
| L-3 | shellcheck + shfmt for lint | Covered | OK |
| L-4 | No compiled binaries in v0.x | Covered | OK |
| L-5 | No JS test framework | Covered | OK |
| L-6 | No Rust in v0.x | Covered | OK |
| L-7 | factory-dispatcher WASM at v1.0 | Covered | OK |
| L-8 | MIT license | Covered | OK |
| L-9 | main branch (pre-v0.1) → develop (post-v0.1) | Covered | OK |
| L-10 | factory-artifacts orphan branch for .factory/ | Covered | OK |
| L-11 | Conventional Commits enforced by lefthook | Covered | OK |
| L-12 | No AI attribution in commits | Covered | OK |
| L-13 | No --no-verify | Covered | OK |
| L-14 | ${CLAUDE_PLUGIN_ROOT}/templates/... path discipline | Covered | OK |
| L-15 | Wiki filenames immutable after creation | Covered | OK |
| L-16 | exit 0/1/2 hook contract | Covered | OK |
| L-17 | JSON-in / JSON-out for hooks | Covered | OK |
| L-18 | Operator-machine requirement: Node 20+ | Covered | OK (F-3 gap notwithstanding) |
| L-19 | Defuddle CLI for web extraction | Covered (sparse) | PARTIAL — F-2 applies |
| L-20 | run-skill.mjs for scheduled Actions | Covered (sparse) | PARTIAL — F-3 applies |
| L-21 | Single-commit-per-burst (TD-VSDD-053) | Referenced | OK |
| L-22 | 3-CLEAN adversary protocol (BC-5.39.001) | Referenced | OK |

---

## Stress-Test Results

Eight stress scenarios applied to the brief.

| Test | Scenario | Result |
|---|---|---|
| T-1 | A Phase 1b BC writer uses ONLY the brief — can they write a testable hook contract for Defuddle? | FAIL — F-2 (input/output contract missing) |
| T-2 | A Phase 1d toolchain engineer uses ONLY the brief to install deps — do they install Node? | AMBIGUOUS — brief says "operator's machine" but doesn't list Node in the setup checklist |
| T-3 | An implementer reads brief + CLAUDE.md in parallel — do they get consistent Node guidance? | FAIL — contradiction between brief Stage 3 lock and CLAUDE.md line 5 (F-1; fixed by Task 2 in this dispatch) |
| T-4 | The consistency-validator checks GitHub Action template count: brief says 18, plugin-plan says 17 — which wins? | MISMATCH — would surface as ADV finding; brief is the more-specific artifact so it "wins" per precedence rule, but it is WRONG |
| T-5 | The holdout evaluator at Phase 4 measures token savings — what is the acceptance threshold? | FAIL — "~70-90%" is unanchored; F-4 applies |
| T-6 | A new collaborator (Phase 3+) reads the brief to understand the factory — is "second brain" defined? | FAIL — F-11 applies |
| T-7 | The story-writer creates Phase 0 stories — does the brief provide exit gate criteria? | PARTIAL — brief references phased-build-plan for gates but does not inline them |
| T-8 | Phase 0 exit gate is evaluated — can it be evaluated without Node? | PASS — Phase 0 is manual; no tools required |

---

## Novelty Assessment

All 25 findings (including 2 withdrawn) are novel to Pass 1. No findings were previously
reported by another agent in this session. Streak is 0/3 because this is Pass 1.

---

## Recommendation

REMEDIATE before Pass 2. Required remediations for CRITICAL findings:

1. **F-1 / F-3 (partially):** Align CLAUDE.md line 5 with the Node 20+ lock — separate
   fix-burst dispatched in parallel (Task 2 of this state-manager dispatch).
2. **F-2:** Product-owner must add Defuddle input/output contract sketch to brief, or
   add a scoped BC placeholder with explicit deferral justification referencing a
   Phase 1b story ID.
3. **F-3:** Product-owner must clarify run-skill.mjs scope, inputs/outputs, and phase
   ownership in the brief.
4. **F-4:** Product-owner must anchor the "~70-90%" figure to a source or qualify it
   as a hypothesis with VP to validate at Phase 4.

The 11 IMPORTANT findings should be addressed in the same fix-burst where feasible.
SUGGESTION findings may be batched into a follow-on burst if the critical/important
burst would exceed 200 lines of changes.

---

## Top 3 Critical Findings

1. **F-1** — Node/JS runtime contradiction between brief Stage 3 lock and CLAUDE.md
   line 5 (and residual "no JS runtime" language in brief body).
2. **F-2** — Defuddle CLI has no input/output contract in the brief; BC cannot be written.
3. **F-4** — Token savings figure (~70-90%) is unanchored; will propagate as unverifiable NFR.

---

## Summary

Pass 1 FAIL. The brief has made meaningful progress (22/22 locked decisions covered;
8/10 citations verified) but contains 4 CRITICAL gaps that prevent Phase 1b BC writing.
The Node contradiction (F-1) is being resolved in parallel by the Task 2 CLAUDE.md
fix-burst. The remaining 3 CRITICAL findings (F-2, F-3, F-4) require product-owner
dispatch. After remediation, Pass 2 may proceed. Streak resets to 0/3.
