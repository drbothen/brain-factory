---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 9
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [pass-1 7C+12I, pass-2 4C+8I, pass-3 2C+4I, pass-4 3C+3I, pass-5 2C+3I, pass-6 2C+3I, pass-7 2C+3I, pass-8 1C+3I]
producing_agents:
  - pass-8 persist a6917e4
  - pass-8 architect bf34582
  - pass-8 state-mgr FINAL 35fd7c2
---

# Adversary Pass 9 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 1
- IMPORTANT: 2
- OBSERVATIONS: 3
- Streak: 0/3 (reset)

Target: brief v0.4.19 + PRD v0.1.8 + BC-INDEX v0.1.7 + ARCH-INDEX v0.1.10 + VP-INDEX v0.1.4. VP-012 v1.2, SS-18 v1.3.

Trajectory CRITICAL: 7→4→2→3→2→2→2→1→1. Convergence approaching but cascade still surfacing net-new defect classes.

NOVELTY: MODERATE. 3 net-new defect classes.

## CRITICAL findings

### F-PASS9-C1 CRITICAL — ARCH-INDEX Document Map ↔ VP-INDEX Summary intra-document title mismatch (VP-012)
ARCH-INDEX line 84 (Document Map): "VP-012 | ... | Manifest write atomicity" (stale pre-v1.1 short title)
ARCH-INDEX line 310 (VP-INDEX Summary): "VP-012 | Manifest write atomicity and last_ingest field correctness" (canonical v1.1+)
VP-012 H1: "Manifest write atomicity and last_ingest field correctness" (canonical)

Pass 8 architect F-PASS8-I2 closure updated VP-INDEX Summary cell but NOT Document Map cell. In-document sibling-sweep gap within ARCH-INDEX.

Severity CRITICAL: ARCH-INDEX Document Map is the file's stated entry-point for discovery. Fresh-context implementer reading Document Map first would build wrong VP-012 scope mental model.

**Routing:** vsdd-factory:architect.

## IMPORTANT findings

### F-PASS9-I1 IMPORTANT — Writing-technique principle violated in VP-012 v1.2 + ARCH-INDEX v0.1.10 changelog entries
VP-012 line 139 (v1.2 changelog F-PASS8-I2): "VP-INDEX line 37"
ARCH-INDEX line 377 (v0.1.10 changelog F-PASS8-I1): "ADR-004 lines 36, 38, 45" and "(802, 535, 231)"

Both contain plain-prose `line N` literals. Both carry `[audit-trail]` tags exempting them from Clause 2 gate. BUT writing-technique principle (STATE.md items 7+12-14) is BROADER than the gate — applies to all spec content.

5th recursion of narrow-fix-broad-announcement: brief level (Pass 19) → BC-INDEX level (Pass 7) → architecture changelogs (Pass 8). Pattern migrates to next un-policed layer each time.

**Routing:** vsdd-factory:architect. Rewrite changelog entries with semantic anchors. Codify writing-technique principle as architecture-layer discipline (applies regardless of audit-trail tag).

### F-PASS9-I2 IMPORTANT — SS-18 has no Changelog section despite v1.3 bump (process-gap in SS-NN template)
SS-18 has been bumped v1.0 → v1.1 → v1.2 → v1.3 per ARCH-INDEX changelog. SS-18 file has no `## Changelog` section. Version-history audit trail exists only in ARCH-INDEX cross-references.

VP-012 has a proper Changelog (v1.0/v1.1/v1.2 entries). SS-NN template lacks Changelog requirement.

[process-gap] sibling-sweep across SS-01..SS-17 likely confirms same gap.

**Routing:** vsdd-factory:architect. Add Changelog section to SS-18 with reconstructed v1.0..v1.3 entries. Codify SS-NN template discipline: any SS-NN bumped past v1.0 MUST have in-file Changelog. Sibling-sweep other bumped SS-NN designs.

## Observations

### F-PASS9-O1 — VP-INDEX field name `verifies_bcs` mixed with NFR IDs is established convention (no remediation)

### F-PASS9-O2 — VP-012 timestamp 2026-05-15 stale by 2 bumps (v1.1, v1.2 both dated 2026-05-16); same for SS-18. Per-artifact `timestamp` freshness not yet in audit scope. Surface as Phase 1d v0.1.11+ candidate.

### F-PASS9-O3 — Pass 8 architecture changelog narrative quality: closure-rationale + sibling-sweep evidence + defect-location combined in single entries. Splitting would improve readability.

## 18-Dimension Cumulative Audit Status

All Phase 1a (13) + Phase 1d (5) disciplines intact EXCEPT:
- In-document title-cell sibling-sweep (NEW class): VIOLATED F-PASS9-C1
- Writing-technique principle in architecture-layer (Pass 9 extension): VIOLATED F-PASS9-I1
- SS-NN template Changelog requirement (NEW process-gap): VIOLATED F-PASS9-I2

## Recommended Next Action

3-burst sequential closure (no PO scope):
1. state-mgr persist Pass 9 (THIS commit)
2. architect: F-PASS9-C1 + I1 + I2 + codify new disciplines. Bump ARCH-INDEX 0.1.10→0.1.11, VP-012 v1.2→v1.3, SS-18 v1.3→v1.4.
3. state-mgr FINAL: extend discipline (now 6 sub-checks including in-document title-cell sibling-sweep) + STATE/HANDOFF/TASK-LIST refresh.

Pass 10.

## Streak: 0/3
