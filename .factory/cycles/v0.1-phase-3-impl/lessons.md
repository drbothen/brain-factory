---
document_type: lessons-learned
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-05-28T00:00:00
cycle: "v0.1-phase-3-impl"
inputs: [STATE.md]
input-hash: ""
traces_to: STATE.md
---

# Lessons Learned — v0.1-phase-3-impl

## Process-Level

1. **shopt -s inherit_errexit does NOT propagate set -e into bash functions invoked via if-conditional context** — The POSIX errexit-context rule overrides `inherit_errexit` for any function called inside an `if`-statement, `&&`-chain, or `||`-chain. This means `if ! _writeback_state; then` and `_writeback_state || ...` both suppress `set -e` inside `_writeback_state`, regardless of `shopt -s inherit_errexit`. Reviewers and implementers must NOT assume `inherit_errexit` is sufficient when a function is invoked via if-context. The production-grade pattern is explicit per-call `|| { sentinel=...; return 1; }` guards inside any function whose failure paths must surface to the caller.
   _Discovered: Pass 6 Fix Burst 6 (40de399), 2026-05-28. Root cause exposed by test 45 RED GATE in 9fe29ce transitioning FAIL → PASS after 40de399 applied explicit guards._

2. **Paper-fix detection works when test-writers have autonomy to commit initially-failing tests** — Pass 4 F-P4-O01 was "closed" at 5c8430a with `shopt -s inherit_errexit`. Pass 6 adversary surfaced the same issue as F-P6-C01. The paper-fix was only exposed when test-writer added a load-bearing yq-failure test (test 45) in 9fe29ce that initially FAILED — demonstrating the claimed fix was insufficient. The paper-fix was then actually closed at 40de399. Lesson: empirical RED GATE tests that start failing are more reliable closure evidence than implementer self-assessment. TD-VSDD-059 paper-fix detection protocol requires load-bearing tests precisely for this reason.
   _Discovered: Pass 6 (2026-05-28). Manifestation: 2-step closure required for a finding that was declared closed in Pass 4._

3. **Fresh-context audits should explicitly include narrative prose review (Description, AC text, Architecture Compliance Rules), not just enum/structural artifacts** — Postcondition-focused passes can leave Description prose unswept, creating partial-fix regression (S-7.01). The v1.3 → v1.4 burst correctly enumerated Postcondition 5 and its 4 writeback fields, but left BC-2.01.006 Description claiming "the skill fires the hook" intact. Seven consecutive passes missed this drift. Pass 8, a fresh-context audit, caught it by reading the Description prose against the actual BC-2.04.014 architecture. Lesson: adversary dispatch instructions should explicitly call out narrative sections (Description, Preconditions prose, Architecture Compliance Rules) as review surfaces alongside structured tables and enumerations.
   _Discovered: Pass 8 (2026-05-28). Root cause: partial-fix regression from v1.3→v1.4 burst. Closure: BC-2.01.006 v1.5 Description rewritten at 03a34d3._

4. **Reconciliation documents must sweep the WHOLE file in scope, not just named sub-fields** — BC-DIMENSION-RECONCILIATION.md §4 listed `plugins/brain-factory/templates/state-md-template.md` as a file where "frontmatter additions" would be made. The frontmatter was correctly updated with the six canonical dimension names. However, the body of the same file retained legacy dimension labels (Source Coverage, Wiki Completeness, Embedding Status, Brief Currency, Health, Convergence). Pass 9 fresh-context audit caught this partial-fix as F-P9-C04 (CRITICAL). The reconciliation document's scope statement said "frontmatter additions" — but the reconciliation was responsible for the file, not just one section of it. Production-grade rule: when a reconciliation document lists a file in scope, the reconciliation must sweep the WHOLE file, or explicitly enumerate which sections are intentionally out-of-scope. The orchestrator and PO closing the reconciliation must verify completeness across all sections of every in-scope file, not just the sections referenced in the reconciliation plan.
   _Discovered: Pass 9 (2026-05-28). Root cause: BC-DIMENSION-RECONCILIATION.md §4 partial-scope statement. Closure: state-md-template.md body rewritten at aad5374 (P9 fix burst 9)._

   **Refinement (Pass 10, 2026-05-29):** Lesson L4 applies recursively — even bursts that CITE L4 in their commit body must apply L4 to themselves. Pass-9 fix burst correctly cited L4 for the BC-DIMENSION-RECONCILIATION partial-fix on state-md-template body, but failed to apply L4 to its OWN sweeps: AC-009/Task #2 (adjacent story-body sections in STORY-004.md adjacent to AC-010/Task #3 swept by reconciliation), BC-2.04.014 Invariants section (adjacent to H1/Description/Postconditions swept by v1.5), VP-024 prose preamble (adjacent to test-code snippet already updated). Pass 10 adversary surfaced all four as IMPORTANT findings (F-P10-I01 through I04). Production-grade rule: when a fix burst sweeps file F with intent X, the fix burst must explicitly enumerate ALL sections of F that are in-scope for X and sweep every section before declaring closure. The intent "ALWAYS exits 0 contract" applies to ALL sections of BC-2.04.014 (including Invariants), and the intent "E-HEALTH-001 exit 2" applies to ALL sections of VP-024 (including prose preamble), not just the sections the implementer happened to look at.
   _Discovered: Pass 10 (2026-05-29). Root cause: Pass-9 fix burst cited L4 in commit message but applied section-scoped sweeps, not whole-file sweeps. Closure: STORY-004 AC-009+Task#2 (9cbcb22), BC-2.04.014 v1.6 Invariant 4 (ac9dc62), VP-024 prose preamble (658f712)._

5. **Cascade depth reflects slow-rotting spec drift; fresh-context findings should be closed mid-cascade per Rule 4 rather than deferred** — The BC-5.39.001 3-CLEAN protocol's true value is catching slow-rotting spec drift that earlier passes deprioritize or classify as "out of scope." Pass 11 surfaced findings (volatile line-number trace pin in AC-009, sibling-sweep miss in STORY-004 line 258, VP-024 Counterexample failure-mode ambiguity) that prior passes would have classified as edge-cases or deferred. All were real defects. The production-grade rule: in convergence cascades, treat fresh-context findings as authoritative regardless of "scope" classification. The scope decision should be made by orchestrator routing, NOT by skipping findings. Per CLAUDE.md production-grade default Rule 4 (AI-built defects = AI responsibility), the right disposition for spec drift surfaced mid-cascade is closure in-scope, not deferral. Exception: POL-14-governed findings (BC/story frontmatter `status: draft` pre-merge) are a well-defined false-positive class and should be recognized as such by adversary dispatch instructions, not closed mid-cascade — add explicit guidance to adversary dispatch template. Lesson 5 also highlights the value of the adversary dispatch "Already CLOSED" list: a growing list that includes POL-14 deferrals prevents false-positive recurrence without adding closure burden.
   _Discovered: Pass 11 cascade analysis (2026-05-29). Root cause: mixed slow-rotting spec drift (F-P11-01 through 04) + false-positive class (F-P11-05/06 POL-14) + historical-reference non-issue (F-P11-O01). Fix burst 11 (97630bd + b2f339c) closed actionable findings; POL-14 deferrals codified in adversary dispatch template for Pass 12._

## Policy Candidates

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| 1 | Explicit per-call error guards required in any bash function called via if-context | hook + skill bash code review checklist | proposed |
| 2 | Paper-fix closure MUST be validated by a load-bearing test (bats) that was initially FAILING | test-writer dispatch protocol for fix bursts | proposed |
| 3 | Adversary dispatch must explicitly list narrative prose sections (Description, AC text, Compliance Rules) as review surfaces alongside structured tables | adversary dispatch template + BC-5.39.001 cascade instructions | proposed |
| 4 | Reconciliation documents must specify ALL sections in scope per file, or explicitly enumerate out-of-scope sections; closing agent must verify completeness across the whole file | reconciliation document authoring protocol + PO closure checklist | proposed |
| 4R | L4 applies recursively: any fix burst whose commit message cites L4 must prove it applied L4 to its own sweeps (explicit section enumeration in commit body); adjacent sections in the same file are in scope for the same intent unless explicitly excluded | fix burst review checklist + state-manager closure protocol | proposed |
| 5 | Fresh-context adversary findings are authoritative mid-cascade; close in-scope per Rule 4 not defer; POL-14 pre-merge draft status is a recognized false-positive class; include explicit "do NOT flag" guidance in adversary dispatch template to prevent false-positive recurrence | adversary dispatch template + BC-5.39.001 cascade instructions | proposed |
