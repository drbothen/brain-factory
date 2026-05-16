---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 8
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [pass-1 7C+12I, pass-2 4C+8I, pass-3 2C+4I, pass-4 3C+3I, pass-5 2C+3I, pass-6 2C+3I, pass-7 2C+3I]
producing_agents:
  - pass-7 persist 90acdbf
  - pass-7 architect 7e60898
  - pass-7 PO 1c0251c
  - pass-7 state-manager FINAL fd033d1
---

# Adversary Pass 8 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 1
- IMPORTANT: 3
- OBSERVATIONS: 2 (both [process-gap])
- Streak: 0/3 (reset)

Target: brief v0.4.19 + PRD v0.1.8 + BC-INDEX v0.1.7 + ARCH-INDEX v0.1.9 + VP-INDEX v0.1.4.

Trajectory CRITICAL: 7→4→2→3→2→2→2→1. First single-digit critical pass. Modest count reduction (5→4 blockers).

NOVELTY: HIGH. All 4 blockers are NEW classes not surfaced in Pass 1-7.

## CRITICAL findings

### F-PASS8-C1 CRITICAL — SESSION-HANDOFF.md cites non-existent VP-INDEX path
SESSION-HANDOFF line 112: "VP-INDEX: .factory/specs/verification-properties/VP-INDEX.md"
Lines 197-198: same incorrect path pattern.
Actual canonical: `.factory/specs/architecture/verification-properties/VP-INDEX.md` (missing `architecture/` segment).
ARCH-INDEX correctly uses the longer path; SESSION-HANDOFF doesn't.

Root cause: Pass 7 state-manager FINAL refresh updated versions but not paths. Path-currency check was not in scope.

Fresh-context orchestrator following SESSION-HANDOFF §9 resume procedure would Read a non-existent path.

**Routing:** vsdd-factory:state-manager. Fix all 3 path cites + add new Self-Audit item "path-currency check on operational state docs" (test -e on every cited .factory/specs/... path).

## IMPORTANT findings

### F-PASS8-I1 IMPORTANT — ADR-004 cites 3 stale absolute line counts (v0.4.6 line-count-drift discipline violated)
ADR-004 line 36: "product-brief.md (single file — 802 lines; index is the file itself)" — actual 830 lines
ADR-004 line 38: "index.md (PRD index — summaries + RTM; 535 lines)" — actual 646 lines
ADR-004 line 45: "BC-INDEX.md (canonical sharding index — 231 lines)" — actual 328 lines

Brief v0.4.6 STRUCTURAL FIX established dropping absolute line counts in favor of date-anchors due to wc-l-vs-Read-tool drift. Discipline applied to brief but never propagated to architecture artifacts.

**Routing:** vsdd-factory:architect. Drop absolute line counts; use semantic anchors per v0.4.6 discipline. Sibling-sweep all ADRs/SS-NN/VPs.

### F-PASS8-I2 IMPORTANT — VP-012 frontmatter vs VP-INDEX row asymmetry (F-1c-CV-05 regression)
VP-INDEX line 37: VP-012 Target BCs = "NFR-018, BC-2.03.002, BC-2.06.003"
VP-012 file line 11: verifies_bcs = "[BC-2.03.002, BC-2.06.003]" (NFR-018 absent)

Per Source-of-Truth Precedence rule 4: VP file frontmatter authoritative. NFR-018 referenced in VP-012 body but NOT in machine-readable verifies_bcs.

**Routing:** vsdd-factory:architect. Add NFR-018 to VP-012 verifies_bcs (Group 1 bats test asserts atomicity = NFR-018; correct addition).

### F-PASS8-I3 IMPORTANT — ARCH-INDEX v0.1.8 changelog narrative factually wrong
ARCH-INDEX line 381 (v0.1.8 changelog F-PASS7-C2-arch): "PRD was bumped to v0.1.7 during the Pass 7 state-manager-persist burst (burst 1); architect burst (burst 2) runs after..."

FACT: PRD was bumped to v0.1.7 during Pass 6 PO closure (commit e0e143c), NOT during Pass 7 state-manager-persist (90acdbf only refreshed STATE/HANDOFF/TASK-LIST).

The inherits_from pin selection is correct; the rationale citing the wrong burst is wrong.

**Routing:** vsdd-factory:architect. Correct narrative to cite Pass 6 PO burst as PRD-bump source.

## Observations

### F-PASS8-O1 [process-gap] — Sequential Pass 7 discipline scoped too narrowly
state-manager FINAL discipline successfully closed inherits_from chain integrity. But the FINAL burst's responsibility was scoped to "re-pin inherits_from to post-all-bursts parent versions" only. Path-currency, line-count-drift, and changelog factual accuracy were NOT in scope.

Extend FINAL burst checklist:
(a) inherits_from re-pin (existing)
(b) path-currency check on every cited .factory/specs/... reference
(c) cited-SHA verification (cited fix-burst commits exist in git log)
(d) absolute-quantity audit (line counts, file sizes, etc.)
(e) changelog factual-accuracy spot-check (cited burst SHAs match git log)

### F-PASS8-O2 [process-gap] — SS-18 audit-trail version-range upper bound stale (pending intent verification)
SS-18 lines 45-47 cap audit-history at v0.4.18; brief now v0.4.19. Claim "§Test architecture unchanged across v0.4.15..v0.4.18" still true (v0.4.19 didn't touch §Test architecture). Pending intent: snapshot or drift?

**Routing:** orchestrator adjudicates. If snapshot, add NOTE. If drift, extend to v0.4.19.

## 16-Dimension Audit Status

| # | Dimension | Status |
|---|-----------|--------|
| 1 | Sweep-by-canonical-pattern (tests/) | CLEAN |
| 2 | last_updated freshness (indices) | CLEAN |
| 3 | inherits_from chain integrity | CLEAN — Pass 7 discipline works |
| 4 | Plain-prose `line N` gate Clause 2 | CLEAN |
| 5 | L-prefixed gate Clause 1 | CLEAN |
| 6 | Clause 2 sibling-sweep | CLEAN |
| 7 | Operational state doc version freshness | CLEAN |
| 8 | Operational state doc path currency | **VIOLATED** F-PASS8-C1 |
| 9 | Absolute-quantity stability (line counts) | **VIOLATED** F-PASS8-I1 |
| 10 | VP file ↔ VP-INDEX row consistency | **VIOLATED** F-PASS8-I2 |
| 11 | Changelog narrative factual accuracy | **VIOLATED** F-PASS8-I3 |
| 12 | Subsystem registry 1:1 SS↔ss↔CAP | CLEAN |
| 13 | 64/64 P0 BC VP coverage | CLEAN |
| 14 | No blanket-coverage wording | CLEAN |
| 15 | No AI attribution | CLEAN |
| 16 | Sequential pass-closure discipline | PARTIAL (versions yes; paths/facts no) |

## Recommended Next Action

3-burst sequential closure (no PO scope this pass):
1. state-manager persist Pass 8 (THIS commit; no refresh)
2. architect: F-PASS8-I1 + I2 + I3. Bump ARCH-INDEX v0.1.9 → v0.1.10.
3. state-manager FINAL: F-PASS8-C1 (path correction) + STATE/HANDOFF/TASK-LIST refresh + extended Self-Audit (path-currency); document Pass 7 discipline extension per F-PASS8-O1.

Pass 9 after.

## Streak: 0/3 (RESET)
