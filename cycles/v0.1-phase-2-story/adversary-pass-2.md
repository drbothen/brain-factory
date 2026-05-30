---
artifact_type: adversary-pass-report
phase: phase-2-story-decomposition
step: step-g-adversarial-story-review
pass_number: 2
verdict: FAIL
critical_count: 0
important_count: 3
suggestion_count: 4
streak_before: 0
streak_after: 0
streak_target: 3
protocol: BC-5.39.001 3-CLEAN
prior_pass_closure: "Pass 1 all 17 findings verified CLOSED (C01-C04, I01-I06, I08, S01-S05); I07 DEFERRED per UD-007/UD-008"
dispatched: 2026-05-19
authored_by: vsdd-factory:adversary
persisted_by: vsdd-factory:state-manager
inputs_snapshot:
  - product-brief.md@v0.4.20
  - prd/index.md@v0.1.13
  - prd-supplements/error-taxonomy@v0.1.2
  - prd-supplements/nfr-catalog@v0.1.1
  - behavioral-contracts/BC-INDEX.md@v0.1.15
  - architecture/ARCH-INDEX.md@v0.1.23
  - architecture/verification-properties/VP-INDEX.md@v0.1.7
  - stories/STORY-INDEX.md@v0.3.2
  - stories/epics.md@v0.1.2
  - stories/dependency-graph.md@v0.1.0
  - stories/wave-schedule.md@v0.1.2
  - stories/sprint-state.yaml@v0.1.0
  - stories/holdout-scenarios.md: EXCLUDED (access_control: restricted)
holdout_isolation: confirmed-no-leaks
---

# Phase 2 Adversarial Review — Pass 2

**Protocol:** BC-5.39.001 3-CLEAN  
**Verdict:** FAIL  
**Streak:** 0/3 (reset)  
**Findings:** 0 CRITICAL · 3 IMPORTANT · 4 SUGGESTION  
**Date:** 2026-05-19

---

## Pass 1 Closure Verification

Before scanning for new findings, I verified all 17 Pass 1 findings against the fix-closure commit log and current artifact state.

### Critical findings (C01–C04) — VERIFIED CLOSED

**C01 — VP path sweep:** All VP references in story files now use correct relative paths under `architecture/verification-properties/`. Fix-burst A committed. ✓

**C02 — PRD RTM rows:** `prd/index.md@v0.1.13` contains 23 per-hook bats-sweep RTM rows. Fix-burst C committed. ✓

**C03 — Story anchor/ref fixes:** 4 story anchor mismatches repaired, cross-refs resolve. Fix-burst A committed. ✓

**C04 — BC-INDEX bidirectional traceability:** `BC-INDEX.md@v0.1.15` now carries `story_ids` back-refs for all 95 BCs. Fix-burst D committed. ✓

### Important findings (I01–I06, I08) — VERIFIED CLOSED

**I01 — dep-graph missing edge:** Dependency graph edge added. Fix-burst A committed. ✓

**I02 — STORY-INDEX input refresh:** `STORY-INDEX.md@v0.3.2` updated. Fix-burst A committed. ✓

**I03 — wave-schedule input refresh:** `wave-schedule.md@v0.1.2` updated. Fix-burst A committed. ✓

**I04 — epics.md updates:** `epics.md@v0.1.2` updated. Fix-burst A committed. ✓

**I05 — VP-INDEX path alignment:** Paths aligned in fix-burst A. ✓

**I06 — sprint-state.yaml:** Updated in fix-burst A. ✓

**I08 — Story anchor consistency:** All anchor IDs normalized. Fix-burst A committed. ✓

### Important finding I07 — DEFERRED (confirmed)

**I07** was deferred per UD-007 (holdout-scenarios.md access_control: restricted) and UD-008. Not re-examined in Pass 2. Deferral status confirmed unchanged.

### Suggestion findings (S01–S05) — VERIFIED CLOSED

**S01 — wave-schedule footer note version pin:** Updated to v0.3.2 in fix-burst A. ✓  
*(Note: S01 re-emerges as a new finding below — see F-PHASE2-ADV-PASS2-S01. The prior S01 addressed the wave-schedule internal note; the new S01 addresses a residual footer discrepancy introduced by the wave-schedule rewrite.)*

**S02 — cross_cutting_bcs pattern inconsistency:** Normalized in fix-burst A. ✓

**S03 — epics.md phase frontmatter:** Corrected in fix-burst A. ✓

**S04 — process gap flagged:** Acknowledged and logged. ✓

**S05 — epics.md running totals:** Corrected in fix-burst A and in story-writer fix commit. ✓

### Pass 1 closure summary

All 17 Pass 1 findings: **CLOSED** (16 by fix; 1 by accepted deferral).  
Streak entering Pass 2: 0/3 (streak count resets at each pass start; convergence requires 3 consecutive clean passes).

---

## Pass 2 Findings

### IMPORTANT — F-PHASE2-ADV-PASS2-I01

**Title:** `dependency-graph.md` §Stats block contains WIP contradictions with current STORY-INDEX

**Artifact:** `.factory/stories/dependency-graph.md@v0.1.0`

**Description:**  
The §Stats block at the top of `dependency-graph.md` still reads values from the pre-fix-burst state. Specifically:

1. The `total_stories` count in the Stats block does not match the authoritative count in `STORY-INDEX.md@v0.3.2`. STORY-INDEX lists the definitive story roster; dep-graph §Stats must derive from it.
2. The `wave_assignments` summary in §Stats lists wave sizes that contradict `wave-schedule.md@v0.1.2`. The wave-schedule is the authoritative wave-assignment source; dep-graph §Stats is a derived view and must agree.
3. One edge in the mermaid diagram uses a notation that was normalized in fix-burst A (`STORY-NNN --> STORY-MMM` vs `STORY-NNN --> |label| STORY-MMM`) but the §Stats "edge count" integer was not decremented to match the removed duplicate edge from I01's fix. The edge count is off by one.

**Impact:** `dependency-graph.md` is consumed by `wave-scheduling` and `holdout-evaluator` as an authoritative source. Stale §Stats cause those consumers to work from incorrect totals. This is a data-integrity defect, not cosmetic.

**Severity rationale:** IMPORTANT (not CRITICAL) — the mermaid diagram edges themselves are correct post-fix-burst A; only the prose §Stats header is stale. The erroneous §Stats do not gate any currently dispatched agent, but they will gate `vsdd-factory:wave-scheduling` re-runs and `phase-4-holdout-evaluation` dispatch.

**Remediation:** Update `dependency-graph.md` §Stats to match STORY-INDEX.md total_stories, wave-schedule.md wave sizes, and the corrected edge count. No structural changes required — prose/integer updates only.

**Fix owner:** `vsdd-factory:story-writer`

---

### IMPORTANT — F-PHASE2-ADV-PASS2-I02

**Title:** `wave-schedule.md` W4 missing STORY-015 terminal dependency + Holdout-Eligibility Map gap

**Artifact:** `.factory/stories/wave-schedule.md@v0.1.2`

**Description:**  
Two distinct sub-issues in wave-schedule.md:

**Sub-issue A — W4 STORY-015 terminal dependency missing:**  
Wave 4 in `wave-schedule.md` lists STORY-015 as a deliverable but does not declare it as a terminal dependency of W4. The dependency-graph correctly shows STORY-015 depending on two W3 stories. However, the wave-schedule's "Wave 4 exit gate" section does not enumerate STORY-015 as a required-complete story for W4's holdout gate. This creates a gap: the wave-gate validator (Phase 4) will not block on STORY-015 incomplete status.

**Sub-issue B — Holdout-Eligibility Map gap:**  
The wave-schedule includes a Holdout-Eligibility Map section listing which stories are eligible for holdout evaluation per wave. STORY-015 (Wave 4) is absent from this map. Given that STORY-015 covers the `rename-page` skill (wiki filename immutability enforcement — a high-assurance BC), its absence from holdout eligibility is a specification gap. Per the phased build plan §5.4, every story with ≥1 HIGH-severity BC should appear in the holdout eligibility map.

**Impact:** Wave 4 holdout evaluation may execute without STORY-015 coverage, leaving the rename-page skill's correctness unvalidated under adversarial conditions.

**Severity rationale:** IMPORTANT — does not block Phase 2 completion but will produce a specification gap that Phase 4 dispatchers must compensate for ad hoc. Better to fix the map now.

**Remediation:**  
1. Add STORY-015 to W4 exit gate dependencies in wave-schedule.md.  
2. Add STORY-015 to the Holdout-Eligibility Map with the appropriate BC reference(s).

**Fix owner:** `vsdd-factory:story-writer`

---

### IMPORTANT — F-PHASE2-ADV-PASS2-I03

**Title:** Input-version drift across 4 story-decomposition artifacts post-fix-burst

**Artifact:** Multiple — `epics.md@v0.1.2`, `dependency-graph.md@v0.1.0`, `STORY-INDEX.md@v0.3.2`, `wave-schedule.md@v0.1.2`

**Description:**  
Each of the four story-decomposition artifacts carries an `inputs_snapshot` or `input_versions` section that records the upstream spec versions it was built against. After the fix-burst A-D commits, these snapshots are internally inconsistent:

- `epics.md@v0.1.2` records `prd/index.md@v0.1.13` (correct — matches fix-burst C output).
- `dependency-graph.md@v0.1.0` still records `prd/index.md@v0.1.12` (stale — pre-fix-burst C).
- `STORY-INDEX.md@v0.3.2` records `BC-INDEX.md@v0.1.14` (stale — pre-fix-burst D, which bumped BC-INDEX to v0.1.15).
- `wave-schedule.md@v0.1.2` records `STORY-INDEX.md@v0.3.1` (stale — pre-fix-burst which produced v0.3.2).

**Impact:** The `check-input-drift` skill and any future re-run of `vsdd-factory:wave-scheduling` will report false-positive drift for these three stale snapshots. More critically: the holdout-evaluator reads `dependency-graph.md`'s input snapshot to determine whether a re-run of the dependency analysis is needed before Phase 4 dispatch. A stale snapshot means the evaluator may wrongly conclude the dep-graph is current.

**Severity rationale:** IMPORTANT — the actual artifact content is correct (the fix bursts updated the content); only the provenance metadata is stale. However, provenance metadata is a first-class contract under the VSDD factory — stale inputs_snapshots have historically caused Phase 4 re-dispatch loops in peer projects.

**Remediation:** Update the three stale `inputs_snapshot` / `input_versions` entries:
- `dependency-graph.md`: set `prd/index.md` to `v0.1.13`
- `STORY-INDEX.md`: set `BC-INDEX.md` to `v0.1.15`
- `wave-schedule.md`: set `STORY-INDEX.md` to `v0.3.2`

**Fix owner:** `vsdd-factory:story-writer`

---

### SUGGESTION — F-PHASE2-ADV-PASS2-S01

**Title:** `wave-schedule.md` footer note still references v0.3.1

**Artifact:** `.factory/stories/wave-schedule.md@v0.1.2`

**Description:**  
The wave-schedule footer contains a note: "Generated from STORY-INDEX.md v0.3.1 wave assignments." This note was introduced in the fix-burst A rewrite. Pass 1 S01 addressed a different footer location; this particular line was added by the fix-burst itself. The correct reference is v0.3.2 (the current STORY-INDEX version after fix-burst A).

**Severity:** SUGGESTION — cosmetic/documentation consistency.

**Remediation:** Update footer note from `v0.3.1` to `v0.3.2`.

**Fix owner:** `vsdd-factory:story-writer`

---

### SUGGESTION — F-PHASE2-ADV-PASS2-S02

**Title:** `cross_cutting_bcs` frontmatter pattern inconsistency in 2 story files

**Artifact:** Story files (2 instances — specific IDs noted below)

**Description:**  
Pass 1 S02 normalized the `cross_cutting_bcs` field to use YAML sequence format (`- BC-N.NN.NNN`) across story files. Fix-burst A addressed the majority. Two story files that were not in fix-burst A's diff were not swept:

- The story for STORY-011 uses inline comma-delimited string: `cross_cutting_bcs: "BC-5.39.001, BC-5.39.002"` rather than YAML sequence.
- The story for STORY-017 omits `cross_cutting_bcs` entirely (field absent from frontmatter), though the story body references two cross-cutting BCs.

Both are non-conforming with the normalized schema established in fix-burst A.

**Severity:** SUGGESTION — schema consistency, no behavioral impact in Phase 2. Becomes IMPORTANT by Phase 3 if the test-writer reads `cross_cutting_bcs` to auto-generate red-gate bats stubs.

**Remediation:**  
- STORY-011: convert `cross_cutting_bcs` to YAML sequence.  
- STORY-017: add `cross_cutting_bcs` field with the two BCs referenced in the body.

**Fix owner:** `vsdd-factory:story-writer`

---

### SUGGESTION — F-PHASE2-ADV-PASS2-S03

**Title:** `epics.md` phase frontmatter field value inconsistency with wave-schedule taxonomy

**Artifact:** `.factory/stories/epics.md@v0.1.2`

**Description:**  
Pass 1 S03 corrected the `phase` frontmatter field in `epics.md`. The fix-burst A update resolved the original discrepancy. However, the fix introduced a new minor inconsistency: `epics.md` now carries `phase: "phase-2"` in its frontmatter, but the wave-schedule uses the taxonomy `phase: phase-2-story-decomposition` (hyphenated, full slug). Other artifacts in the story-decomposition set use the full-slug form. `epics.md` is now the sole artifact using the short form.

**Severity:** SUGGESTION — no functional impact. The inconsistency could cause false negatives in a future metadata-consistency linter that pattern-matches on full-slug phase identifiers.

**Remediation:** Update `epics.md` frontmatter: `phase: phase-2` → `phase: phase-2-story-decomposition`.

**Fix owner:** `vsdd-factory:story-writer`

---

### SUGGESTION — F-PHASE2-ADV-PASS2-S04 [PROCESS-GAP]

**Title:** No automated input-version-currency check across story-decomposition artifacts

**Artifact:** Process / tooling gap

**Description:**  
This is the same class of process gap surfaced as Pass 1 S04. Pass 1 S04 was acknowledged and logged. I re-surface it here because I03 above (stale inputs_snapshots in 3 of 4 artifacts) is a direct manifestation of this gap. Without an automated check, every fix-burst that bumps an upstream spec version requires manual propagation to all downstream artifact `inputs_snapshot` fields — and as I03 demonstrates, that propagation was missed in 3 of 4 cases even in a well-disciplined fix burst.

**Process description of gap:** The `vsdd-factory:check-input-drift` skill exists but is not wired as a mandatory gate before Phase 2 story-decomposition artifacts are committed. A pre-commit hook or a mandatory state-manager pre-commit check that runs `check-input-drift` against the story-decomposition artifact set would have caught I03 before it landed.

**Severity:** SUGGESTION (process gap — no in-scope artifact fix possible; remediation is tooling/process change).

**Remediation options (for orchestrator consideration):**
1. Add `vsdd-factory:check-input-drift` as a mandatory step in the Phase 2 step-g-adversarial-story-review checklist, run by state-manager before dispatching the adversary.
2. Wire a lefthook pre-commit that runs `check-input-drift --scope story-decomposition` on any commit that modifies `.factory/stories/*.md` or `.factory/specs/**/*.md`.

Option 1 is in-scope for Phase 2 process hardening. Option 2 requires Phase 1d toolchain work.

**Fix owner:** Orchestrator (process decision) — not story-writer.

---

## Holdout-Isolation Certification

**Confirmed:** No holdout scenario content was read, accessed, or leaked into this review. `stories/holdout-scenarios.md` was excluded from the inputs snapshot (`access_control: restricted`). No finding in this pass references specific holdout scenario IDs, test vectors, or acceptance-criteria content that would only be known from the restricted file.

---

## 3-CLEAN Protocol Status

| Pass | Verdict | Streak |
|------|---------|--------|
| Pass 1 | FAIL (4C + 8I + 5S) | 0/3 |
| Pass 2 | FAIL (0C + 3I + 4S) | 0/3 |
| Pass 3 | pending | — |

**Convergence requires:** 3 consecutive PASS verdicts (0 CRITICAL, 0 IMPORTANT, 0 SUGGESTION across all three passes).  
**Current trajectory:** Positive — CRITICAL count eliminated, IMPORTANT count reduced from 8 to 3. All findings in Pass 2 are lower-severity and narrower in scope.

**Recommended fix order for Pass 2 remediation (sequential):**

1. **I03 first** — update stale `inputs_snapshot` fields in dep-graph, STORY-INDEX, wave-schedule. Low blast radius, prevents false-drift reports during the fix burst itself.
2. **I01** — update `dependency-graph.md` §Stats block. Structural integrity before wave-schedule corrections.
3. **I02** — add STORY-015 to W4 exit gate + Holdout-Eligibility Map in wave-schedule.md.
4. **S01** — wave-schedule footer note v0.3.1 → v0.3.2 (can be bundled with I02 or I03 fix).
5. **S02** — normalize `cross_cutting_bcs` in STORY-011 and add field to STORY-017.
6. **S03** — update `epics.md` phase frontmatter short-form → full-slug.
7. **S04** — process-gap decision by orchestrator (non-blocking for Pass 3 dispatch).

After fix-closure burst, dispatch Pass 3.
