---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 5
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [pass-1 7C+12I, pass-2 4C+8I, pass-3 2C+4I, pass-4 3C+3I]
producing_agents:
  - pass-4 architect fix-burst b68a52b
  - pass-4 product-owner fix-burst ee67abb
---

# Adversary Pass 5 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 2
- IMPORTANT: 3
- SUGGESTION: 0
- OBSERVATION: ~5
- Streak: 0/3 (reset)

Trajectory: Pass 1 (7C+12I) → 2 (4C+8I) → 3 (2C+4I) → 4 (3C+3I) → 5 (2C+3I). Modest reduction continuing.

**Pass 4 closure verification: ALL VERIFIED CLOSED** via Pass 4's positive+negative pattern sweep discipline. 12-dimension audit clean on past-tense event_types, .yaml/.yml extensions, hook-helper paths, api-retry dual-copy, event-catalog.json, gen-test-corpus --sources flag, retry policy, tests/X.bats, SS-NN frontmatter, traces_to, 9-suite roster.

**Novelty: MEDIUM-HIGH** — surfaces NEW pattern: post-burst metadata-and-narrative staleness (frontmatter `inherits_from`, `last_updated`, narrative version cites don't auto-update when parent bumps). Sweep-by-canonical-pattern discipline catches body-content drift; it does NOT catch frontmatter staleness.

## Critical Findings

### F-PASS5-C1 CRITICAL — PRD §2 prose stale + inherits_from drift across 3 indices

- PRD index.md line 10: `inherits_from: product-brief.md@v0.4.15` (current brief is v0.4.16)
- PRD index.md lines 87-91 (active spec content): "Architecture has not yet been produced (Phase 1c); subsystem field in BC frontmatter uses `SS-TBD` placeholder pending architect assignment" — but Phase 1c COMPLETED; 95/95 BCs have canonical SS-NN.
- ARCH-INDEX line 10: `inherits_from: prd@v0.1.1` (current PRD is v0.1.5)
- BC-INDEX line 10: `inherits_from: prd@v0.1.0` (current PRD is v0.1.5)

**Routing:** vsdd-factory:product-owner.

### F-PASS5-C2 CRITICAL — Brief vs BC policies template filename — F-PASS3-O1 deferral rationale invalidated

- Brief line 520: `policies-yaml-template.yaml` (2 occurrences)
- BC-2.15.001 + BC-2.01.001 + SS-15 + ARCH-INDEX: `templates/policies.yaml`

F-PASS3-O1 deferred this on the rationale "brief is immutable post-convergence". Brief v0.4.16 (just created) demonstrates brief mutability. The deferral rationale is invalidated; divergence must be resolved.

**Routing:** vsdd-factory:product-owner (pick canonical filename + sweep brief OR BCs).

## Important Findings

### F-PASS5-I1 IMPORTANT — VP-007 mechanism label drift

- VP-INDEX line 32 + ARCH-INDEX line 279: `bats (unit)`
- VP-007 file line 26 + BC-2.12.001/.002 Verification Properties: `bats (integration.bats)`

Per Source-of-Truth Precedence: VP file supersedes VP-INDEX.

**Routing:** vsdd-factory:architect.

### F-PASS5-I2 IMPORTANT — SS-18 cites brief v0.4.15 (current is v0.4.16)

SS-18 lines 41, 44: "brief v0.4.15 §Test architecture..."

TD-VSDD-091 anti-volatile-pin at architecture layer.

**Routing:** vsdd-factory:architect.

### F-PASS5-I3 IMPORTANT — last_updated 2026-05-15 stale across 4 indices despite 2026-05-16 changelog entries

- PRD index.md line 12: `last_updated: 2026-05-15`
- ARCH-INDEX line 13: `last_updated: 2026-05-15`
- BC-INDEX line 12: `last_updated: 2026-05-15`
- VP-INDEX line 11: `last_updated: 2026-05-15`

All four have changelog entries dated 2026-05-16. [process-gap] candidate.

**Routing:** vsdd-factory:product-owner + vsdd-factory:architect (bump respective indices' last_updated).

## Observations

- [process-gap] F-PASS3-O1 rationale "brief immutable post-convergence" contradicted by v0.4.16. Should make "brief mutable for critical sibling-sweep" policy explicit.
- ARCH-INDEX v0.1.5 changelog: "16 files" but enumeration lists 15 + 2 occurrences in SS-12 + 2 in SS-14 = 15 distinct files / 17 replacements. LOW count drift.
- VP-006 bats harness only checks Iron Law section, not full 6-section structure (depth-of-verification concern, not contradiction).

## Recommended Next Action

1. **product-owner fix-burst**: F-PASS5-C1 (PRD §2 + inherits_from PRD/BC-INDEX + last_updated PRD/BC-INDEX), F-PASS5-C2 (policies filename canonical sweep — recommend `templates/policies.yaml` short form; sweep brief from `policies-yaml-template.yaml` → `policies.yaml`). Bump PRD 0.1.5→0.1.6, BC-INDEX 0.1.4→0.1.5, brief 0.4.16→0.4.17.

2. **architect fix-burst**: F-PASS5-I1 (VP-INDEX + ARCH-INDEX VP-007 mechanism), F-PASS5-I2 (SS-18 brief cite → v0.4.16), F-PASS5-I3 architecture portion (ARCH-INDEX + VP-INDEX last_updated). Bump ARCH-INDEX 0.1.5→0.1.6, VP-INDEX 0.1.2→0.1.3.

3. **New Self-Audit candidate**: `last_updated ≥ max(changelog-entry-date)` enforcement.

After bursts, Pass 6.

## Streak: 0/3 (RESET)
