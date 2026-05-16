---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 6
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [pass-1 7C+12I, pass-2 4C+8I, pass-3 2C+4I, pass-4 3C+3I, pass-5 2C+3I]
producing_agents:
  - pass-5 architect fix-burst d588aa7
  - pass-5 product-owner fix-burst 96a2a14
---

# Adversary Pass 6 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 2
- IMPORTANT: 3
- OBSERVATIONS: 2
- Streak: 0/3 (reset)

Target: brief v0.4.17 + PRD v0.1.6 + BC-INDEX v0.1.5 + ARCH-INDEX v0.1.6 + VP-INDEX v0.1.3.

Trajectory: 2C+3I → 2C+3I identical count; novel-class findings replace closed ones.

## CRITICAL findings

### F-PASS6-C1 CRITICAL — ARCH-INDEX inherits_from chain broken (stale by 5 PRD versions)
ARCH-INDEX frontmatter `inherits_from: prd@v0.1.1`. Current PRD is v0.1.6. F-PASS5-C1 closed PRD + BC-INDEX inherits_from drift but missed ARCH-INDEX (sibling-sweep gap).
**Routing:** vsdd-factory:architect.

### F-PASS6-C2 CRITICAL — PRD vs BC-INDEX inherits_from semantic conflict
PRD v0.1.6 changelog: "inherits_from pinned to brief version at PRD authoring time, not the latest" (pins to v0.4.16).
BC-INDEX v0.1.5 changelog: "inherits_from updated to the PRD version current after this fix-burst" (pins to v0.1.6).
Conflicting semantics. Architect must adjudicate ONE rule, document explicitly, sibling-sweep all four indices' changelog entries.
**Routing:** vsdd-factory:architect.

## IMPORTANT findings

### F-PASS6-I1 IMPORTANT — Brief v0.4.16 changelog has plain-prose "line 333" + "line 514" literal anchors
Brief v0.4.17 line 59 (v0.4.16 changelog entry): "the §Bring-up plan citation of ingest-url.lobster (line 333) updated to..."
Five-file gate pattern `\bL[0-9]+\b` catches L333 form but NOT plain "line 333". Fifth-syntactic-recursion of writing-technique principle.
**Routing:** vsdd-factory:product-owner. Also extend gate to match `line [0-9]+` (with exclusion-list-extension).

### F-PASS6-I2 IMPORTANT — ADR-009 + ADR-004 cite stale PRD v0.1.1
ADR-009 line 68: "Phase 1d adversary reviews the full spec package (PRD v0.1.1 + architecture)."
ADR-004 line 86: "PRD v0.1.1 BC-INDEX.md"
Current PRD v0.1.6. Sibling-sweep all ADRs + SS-NN designs for stale narrative version cites.
**Routing:** vsdd-factory:architect.

### F-PASS6-I3 IMPORTANT — STATE.md body content stale by 5+ revisions despite fresh last_updated
STATE.md last_updated: 2026-05-16 but body still cites:
- canonical_brief: v0.4.15
- canonical_prd: v0.1.2
- canonical_bc_index: v0.1.1
- canonical_architecture: v0.1.1
- Body narrative: "brief v0.4.15 + PRD v0.1.2 + BC-INDEX v0.1.1 + architecture v0.1.1"

Current state: brief v0.4.17, PRD v0.1.6, BC-INDEX v0.1.5, ARCH-INDEX v0.1.6. STATE.md self-declares as canonical state-discovery entry; freshness audit was applied only to spec indices, missing STATE.md.

[process-gap]: Pass 5 freshness audit scope too narrow — operational state docs (STATE.md, SESSION-HANDOFF, TASK-LIST) are also subject to last_updated/body-freshness invariants.

**Routing:** vsdd-factory:state-manager (this burst — being addressed in Part 2 of this commit).

## Observations

### F-PASS6-O1 — last_updated freshness check exists only in ARCH-INDEX Self-Audit
Not sibling-swept to PRD/BC-INDEX/VP-INDEX Self-Audit Checklists. TD-VSDD-060 violation.
**Routing:** all three indices' owners (PO for PRD/BC-INDEX; architect for VP-INDEX) add the freshness check item.

### F-PASS6-O2 — Writing-technique principle has 4 observed syntactic forms; gate covers only 1
Forms: L333, §132 masquerading, quoted-literal `L333`, plain "line 333" prose. Gate matches `\bL[0-9]+\b` only.
[process-gap]: Pass 6 finds 4th form (plain prose); broaden gate to match principle.

## Recommended Next Action

1. **state-manager** (this burst): update STATE.md body to current state (closes F-PASS6-I3).
2. **architect**: F-PASS6-C1 (ARCH-INDEX inherits_from), F-PASS6-C2 (adjudicate policy + sweep all 4 indices changelogs to one rule), F-PASS6-I2 (ADR narrative version cites + broader sweep), F-PASS6-O1 architect portion (VP-INDEX Self-Audit).
3. **product-owner**: F-PASS6-I1 (brief changelog line-N + extend gate to `line [0-9]+`), F-PASS6-O1 PO portion (PRD + BC-INDEX Self-Audit additions).
4. Pass 7.

## Streak: 0/3
