---
artifact_type: adversary-pass-report
phase: phase-2-story-decomposition
step: step-g-adversarial-story-review
pass_number: 3
verdict: FAIL
critical_count: 0
important_count: 2
suggestion_count: 2
streak_before: 0
streak_after: 0
streak_target: 3
protocol: BC-5.39.001 3-CLEAN
prior_pass_closure: "Pass 1 (17 findings) + Pass 2 (7 findings) all VERIFIED-CLOSED; I07 still DEFERRED per UD-007/UD-008"
new_findings_classification: "partial-fix regression of Pass 2 S04 invariant codification — sibling-sweep gap"
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
  - stories/STORY-INDEX.md@v0.3.3
  - stories/epics.md@v0.1.3
  - stories/dependency-graph.md@v0.1.1
  - stories/wave-schedule.md@v0.1.3
  - stories/sprint-state.yaml@v0.1.0
  - stories/holdout-scenarios.md: EXCLUDED (access_control: restricted; frontmatter-only audit performed for input-version drift)
holdout_isolation: confirmed-frontmatter-only-no-body-read
---

# Adversary Pass 3 — Phase 2 Story Decomposition

**Verdict:** FAIL
**Streak:** 0 / 3 (target: 3-CLEAN per BC-5.39.001)
**Protocol:** BC-5.39.001 3-CLEAN convergence
**Classification:** Partial-Fix Regression (S-7.01) — Pass 2 S04 invariant codification missed sprint-state.yaml (sibling-sweep gap)

---

## 1. Pass 1 + Pass 2 Closure Verification

All prior findings from Pass 1 (17) and Pass 2 (7) are VERIFIED-CLOSED except I07 which remains DEFERRED per UD-007/UD-008.

### Pass 1 Closure Table (17 findings)

| Finding | Description | Status |
|---------|-------------|--------|
| P1-C01 | S17 missing bats test for hook exit-code contract | VERIFIED-CLOSED |
| P1-C02 | S22 hook emit site not in structured event catalog | VERIFIED-CLOSED |
| P1-C03 | Wave 4 holdout map missing from wave-schedule | VERIFIED-CLOSED |
| P1-C04 | BC-INDEX bidirectional traceability gap (95 BCs) | VERIFIED-CLOSED |
| P1-I01 | dep-graph §Stats edge count stale | VERIFIED-CLOSED |
| P1-I02 | wave-schedule W3 story list incomplete | VERIFIED-CLOSED |
| P1-I03 | epics.md phase assignment inconsistencies | VERIFIED-CLOSED |
| P1-I04 | STORY-INDEX missing 6 story rows | VERIFIED-CLOSED |
| P1-I05 | dependency-graph missing 3 edges | VERIFIED-CLOSED |
| P1-I06 | sprint-state wave-schedule input pin stale | VERIFIED-CLOSED (tracked separately — see F-P3-I01 below for new regression) |
| P1-I07 | holdout-scenarios.md body not reviewed (restricted) | DEFERRED per UD-007/UD-008 — access-control boundary preserved |
| P1-I08 | epics.md cross_cutting_bcs field missing from 3 epics | VERIFIED-CLOSED |
| P1-S01 | wave-schedule W1 capacity note inconsistency | VERIFIED-CLOSED |
| P1-S02 | dep-graph node shape conventions undocumented | VERIFIED-CLOSED |
| P1-S03 | STORY-INDEX epic column inconsistencies | VERIFIED-CLOSED |
| P1-S04 | sprint-state wave mapping comment missing | VERIFIED-CLOSED (see F-P3-S01 below for sibling-sweep gap) |
| P1-S05 | wave-schedule formatting nits | VERIFIED-CLOSED |

### Pass 2 Closure Table (7 findings)

| Finding | Description | Status |
|---------|-------------|--------|
| P2-I01 | dep-graph §Stats cleanup (edge count precision) | VERIFIED-CLOSED |
| P2-I02 | wave-schedule W4/holdout-map completeness | VERIFIED-CLOSED |
| P2-I03 | 4-artifact inputs_snapshot version pins refresh | VERIFIED-CLOSED |
| P2-S01 | cross_cutting_bcs decision documented in epics | VERIFIED-CLOSED |
| P2-S02 | epics.md phase assignment final pass | VERIFIED-CLOSED |
| P2-S03 | S04 invariant comment codification | VERIFIED-CLOSED in 4 artifacts; PARTIAL — sprint-state.yaml missed (F-P3-S01) |
| P2-S04 | dep-graph §Stats edge automation suggestion | VERIFIED-CLOSED (deferred per P2 disposition) |

**I07 Deferred status:** Access-control boundary is active. Frontmatter-only audit confirms holdout-scenarios.md shows stale input pins (see F-P3-I02 below). Body content NOT read — isolation confirmed.

---

## 2. Pass 3 Findings

### Summary

| ID | Severity | Title |
|----|----------|-------|
| F-P3-I01 | IMPORTANT | sprint-state.yaml input pins stale (wave-schedule v0.1.0 / dep-graph v0.1.0 vs actual v0.1.3 / v0.1.1); wave-schedule.md internal contradiction on dep-graph version |
| F-P3-I02 | IMPORTANT | holdout-scenarios.md frontmatter has 5 stale upstream input pins |
| F-P3-S01 | SUGGESTION | sprint-state.yaml missing S04 invariant comment block (Pass 2 codification sibling-sweep gap) |
| F-P3-S02 | SUGGESTION | dep-graph §Stats edge count verifiable but worth automating (low-confidence, carry-forward from P2-S04 disposition) |

---

### F-P3-I01 — IMPORTANT: sprint-state.yaml stale input pins + wave-schedule.md internal contradiction

**Artifact:** `stories/sprint-state.yaml` line 3; `stories/wave-schedule.md` line 125

**Observation:**

`sprint-state.yaml` line 3 reads:

```yaml
inputs_snapshot:
  wave-schedule: v0.1.0
  dep-graph: v0.1.0
```

The actual current versions are:

- `wave-schedule.md` frontmatter: `version: v0.1.3`
- `dependency-graph.md` frontmatter: `version: v0.1.1`

This is a regression: Pass 1 finding P1-I06 closed the wave-schedule pin (v0.1.0 → v0.1.2); Pass 2 fix-bundle bumped wave-schedule to v0.1.3. The sprint-state pin was updated once (P1-I06 closure) but not re-swept when wave-schedule was bumped again in the Pass 2 fix-bundle.

Additionally, `wave-schedule.md` line 25 (frontmatter) declares `dep_graph_version: v0.1.1`, but line 125 in the body prose reads "Dependency graph: v0.1.0" — an internal contradiction within the same file.

**Impact:** Stale input pins violate the inputs_snapshot contract (BC-5.28.xxx series, artifact-version coherence). Any future state-manager defensive sweep that reads sprint-state.yaml will report false-clean on input-drift. The wave-schedule.md body-vs-frontmatter mismatch will produce conflicting signals on dep-graph currency.

**Required fix:**

1. `sprint-state.yaml` line 3: bump `wave-schedule: v0.1.0 → v0.1.3` and `dep-graph: v0.1.0 → v0.1.1`.
2. `wave-schedule.md` line 125: update body prose from "v0.1.0" → "v0.1.1" to match frontmatter `dep_graph_version`.
3. Bump `sprint-state.yaml` version to `v0.1.1`.
4. After fix, run defensive sweep: `grep -r "v0.1.0" .factory/stories/ | grep -v ".git"` to confirm no other stale pins.

**Root cause:** Pass 2 fix-bundle bumped wave-schedule and dep-graph versions but did not re-sweep sprint-state.yaml's inputs_snapshot block. Classic sibling-sweep gap (TD-VSDD-060).

---

### F-P3-I02 — IMPORTANT: holdout-scenarios.md frontmatter has 5 stale upstream input pins

**Artifact:** `stories/holdout-scenarios.md` frontmatter (body NOT read — isolation confirmed)

**Observation:**

Frontmatter-only read reveals `inputs_snapshot` block in holdout-scenarios.md still pins:

- `prd/index.md: v0.1.11` (actual: v0.1.13)
- `behavioral-contracts/BC-INDEX.md: v0.1.13` (actual: v0.1.15)
- `stories/epics.md: v0.1.1` (actual: v0.1.3)
- `stories/dependency-graph.md: v0.1.0` (actual: v0.1.1)
- `stories/wave-schedule.md: v0.1.1` (actual: v0.1.3)

All five upstream artifacts were bumped during Pass 1 and/or Pass 2 fix-bundles. holdout-scenarios.md was not re-swept after either fix-bundle.

**Impact:** holdout-scenarios.md is downstream of all five inputs. Stale pins mean the holdout-scenario evaluator (Phase 4) will not detect if scenarios were authored against an older PRD or BC set. This is an artifact-version coherence violation that could silently permit scenarios to evaluate against superseded contracts.

**Holdout isolation note:** Only frontmatter was read. Scenario bodies remain protected. The stale-pin audit was performed via `head -N` to the closing `---` of the frontmatter block only, consistent with UD-007/UD-008 access-control boundary.

**Required fix:**

1. Frontmatter-only edit: bump all 5 stale pins to current versions.
2. Bump holdout-scenarios.md `version` field to next minor.
3. Defensive sweep: confirm no other story-layer artifacts carry stale pins against the same 5 upstream versions.

**Root cause:** holdout-scenarios.md inputs_snapshot was never included in the Pass 2 fix-bundle defensive sweep list (S-7.02). Access-control restrictions mean it was not read in Pass 1 or Pass 2 — but frontmatter-only pin audits are explicitly permitted and should have been performed.

---

### F-P3-S01 — SUGGESTION: sprint-state.yaml missing S04 invariant comment block

**Artifact:** `stories/sprint-state.yaml`

**Observation:**

Pass 2 finding P2-S03 required codification of the S04 invariant (stories assigned to at most one wave; wave-unblocked status derived from dep-graph, not manually set) as a comment block in story-layer artifacts. The Pass 2 fix-bundle applied this comment to 4 artifacts: `dependency-graph.md`, `wave-schedule.md`, `epics.md`, and `STORY-INDEX.md`. It did not apply the comment to `sprint-state.yaml`.

`sprint-state.yaml` is a story-layer artifact that directly encodes wave assignments and story statuses — it is precisely the surface where the S04 invariant is operationally active. The omission means sprint-state.yaml has wave-assignment rows without the invariant reminder that guides future sprint-state updates.

**Impact:** Low operational risk (the invariant is enforced by dep-graph, not by the comment), but the sibling-sweep gap is a process-discipline finding. Future story-writer agents editing sprint-state.yaml will not see the invariant reminder inline.

**Required fix:** Add S04 invariant comment block to sprint-state.yaml immediately above the wave-assignments section, matching the style applied in the 4 other artifacts.

**Root cause:** Sibling-sweep for P2-S03 closure listed 4 artifacts; sprint-state.yaml was not on the list despite being a wave-assignment-bearing story-layer artifact. TD-VSDD-060 applies.

---

### F-P3-S02 — SUGGESTION: dep-graph §Stats edge count verifiable but worth automating

**Artifact:** `stories/dependency-graph.md` §Stats

**Observation:**

The §Stats section lists total node count and edge count. These are manually maintained. As the story graph grows (Waves 2–4 add ~60+ stories), manual maintenance of these counts creates drift risk. This was deferred from P2-S04 disposition.

**Current state:** dep-graph §Stats counts are correct as of v0.1.1 (verified by cross-count during Pass 3 review). This is a carry-forward suggestion, not a new defect.

**Suggested improvement:** Add a `# AUTO-COUNT: run scripts/count-dep-graph.sh to regenerate` comment above the stats block, or add a bats test in meta-lint.bats that asserts the stats counts match grep-based node/edge counts. Either approach makes drift detectable mechanically rather than by adversary visual inspection.

**Disposition:** Suggest deferring to story implementation (story-writer can wire this into the Phase 3 meta-lint.bats suite). No block.

---

## 3. Holdout Isolation Confirmation

**Status:** VERIFIED

The holdout-scenarios.md body was NOT read during this pass. Access was restricted to the frontmatter block only (lines 1 through the closing `---` of the YAML front matter). The stale input-pin audit (F-P3-I02) was performed on frontmatter fields exclusively.

No scenario body content, no scenario descriptions, no scenario acceptance criteria were accessed. The UD-007/UD-008 access-control boundary is intact.

---

## 4. Convergence Assessment

| Metric | Value |
|--------|-------|
| Pass number | 3 |
| Critical findings | 0 |
| Important findings | 2 |
| Suggestion findings | 2 |
| Total new findings | 4 |
| Streak before | 0 |
| Streak after | 0 (reset — findings present) |
| Streak target | 3 |
| Verdict | FAIL |

**Pattern:** Partial-Fix Regression (S-7.01). Pass 2 fix-bundle applied S04 invariant codification to 4 of 5 applicable artifacts (sprint-state.yaml missed) and bumped 5 upstream artifact versions without re-sweeping all downstream inputs_snapshot blocks (sprint-state.yaml and holdout-scenarios.md missed). Both IMPORTANT findings are direct outputs of sibling-sweep discipline gaps (TD-VSDD-060 and S-7.02).

**Path to convergence:** Fix F-P3-I01 and F-P3-I02 (required), apply F-P3-S01 (recommended in same fix-burst). F-P3-S02 may be deferred to Phase 3 meta-lint story. After fix-bundle, dispatch Pass 4.

**Convergence trajectory:** C: 4 → 0 → 0 | I: 8 → 3 → 2 | S: 5 → 4 → 2 | Total: 17 → 7 → 4
