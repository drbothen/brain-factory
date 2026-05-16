---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 4
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [pass-1 7C+12I, pass-2 4C+8I, pass-3 2C+4I]
producing_agents:
  - pass-3 architect fix-burst 2df98db
  - pass-3 product-owner fix-burst c6617bd
---

# Adversary Pass 4 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 3
- IMPORTANT: 3
- SUGGESTION: 0
- OBSERVATION: ~10 (positive-disciplines verified)
- Streak: 0/3 (reset)

Trajectory regression: Pass 3 had 2C+4I; Pass 4 has 3C+3I. Sibling-sweep gap pattern persists — Pass 3's "explicit sibling-sweep verification" insufficient to catch the systematic `bats/`→`tests/` class across 16 architecture files.

## Critical Findings

### F-PASS4-C1 CRITICAL — ARCH-INDEX v0.1.4 frontmatter has no matching Changelog entry
ARCH-INDEX frontmatter `version: "0.1.4"` but Changelog has entries for v0.1.3, v0.1.2, v0.1.1, v0.1.0 only — no v0.1.4. Paper-fix pattern that v0.4.10 audit-trail discipline was designed to prevent. Architect bumped version without changelog entry.

**Routing:** vsdd-factory:architect.

### F-PASS4-C2 CRITICAL — 16 architecture files use stale `bats/X.bats` path; canonical is `tests/X.bats`
Affected files: SS-04 line 79, SS-06 line 84, SS-07 line 77, SS-08 line 88, SS-09 line 81, SS-10 line 79, SS-11 line 65, SS-12 lines 50+86, SS-13 line 62, SS-14 lines 41+68, SS-15 line 83, SS-16 line 76, SS-17 line 96, SS-18 line 33, ADR-003 line 48.

Brief + CLAUDE.md + NFR-019 + PRD §7 RTM all canonical: `plugins/brain-factory/tests/X.bats`. Pass 2 F-PASS2-I4 changelog falsely claimed "Sibling-sweep applied to 6 architecture artifacts" but left 14+ stragglers in same architectural layer.

**Process-gap pattern:** Pass 3's sibling-sweep used grep-by-changed-token (e.g., grep for `ingest.bats`), missing the broader `bats/X.bats` → `tests/X.bats` canonical pattern. New discipline needed: sweep-by-canonical-pattern, not sweep-by-changed-token.

**Routing:** vsdd-factory:architect (16-file sweep, document new sweep discipline in ARCH-INDEX changelog).

### F-PASS4-C3 CRITICAL — ADR-012 line 89 has TWO defects: wrong `.yml` extension + missing positional output-dir
Current text: `` `workflows/scale-test.yml` calls `gen-test-corpus.sh --sources 10000` as its first step ``

Defect (a): ADR-006 §Workflow extension convention says `workflows/` directory uses `.yaml` extension, NOT `.yml`. Correct: `workflows/scale-test.yaml`. (Confirmed by SS-02 + ADR-010 which both use `.yaml`.) ARCH-INDEX changelog F-PASS1-C2 entry INTRODUCED this defect by mistakenly applying ADR-013's `.yml` filename to the Lobster workflows directory.

Defect (b): ADR-012 §Script interface defines positional `<output-dir>` as REQUIRED. Line 89 invocation has no output-dir. BC-2.16.006 + VP-027 both correctly include positional output-dir.

F-PASS2-I2 claim "No architecture artifact uses wrong extension" is FALSE — TD-VSDD-059 paper-fix.

**Routing:** vsdd-factory:architect.

## Important Findings

### F-PASS4-I1 IMPORTANT — BC-2.04.014 silent no-op exception violates NFR-011 universal hook emission
BC-2.04.014 SessionStart-outside-brain path: "Hook exits 0 silently... No event emitted (not a brain session; no catalog row needed)".
BC-2.04.017 Postcondition 1: "For every hook invocation, at minimum one JSONL event is written to stderr."
BC-2.17.003 EC-003: "A hook produces zero JSONL events... bats hooks.bats asserts wc -l ≥ 1; the test fails; NFR-011 requires ≥ 1 JSONL event per hook invocation."
NFR-011: "Every hook invocation produces ≥ 1 JSONL event on stderr."

The silent-no-op carve-out is undeclared in BC-2.04.017, NFR-011, BC-2.17.003. Implementer following BC-2.04.014 literally fails BC-2.17.003 EC-003 bats test.

Production-grade fix: emit event (e.g., `brain.health.skipped` for non-brain SessionStart). Never silent.

**Routing:** vsdd-factory:product-owner.

### F-PASS4-I2 IMPORTANT — Brief v0.4.15 line 333 still cites `ingest-url.lobster`
Brief line 333: "the `ingest-url.lobster` pipeline from `plugins/brain-factory/workflows/`"
Canonical (ADR-006 + BC-2.12.001/.003/.004): `.yaml` extension.

Brief is part of the canonical five-file gate AND is parent spec, BUT also marked Phase 1a CLOSED. Amending requires explicit consideration:
- If brief is operational artifact (part of active gate): single-token fix in scope OK.
- If brief is immutable post-convergence: human direction required.

Recommendation per CLAUDE.md Source-of-Truth Precedence rule 2 (ADR supersedes earlier artifacts): brief follows ADR-006 canonicalization. Single-token sibling-sweep.

**Routing:** vsdd-factory:product-owner (single-token fix, brief 0.4.15 → 0.4.16; orchestrator can override if human wants to defer).

### F-PASS4-I3 IMPORTANT — SS-18 internal contradiction: line 33 `bats/`, lines 50-58 `tests/`
SS-18 line 33: "**Inbound:** `bats/meta-lint.bats` and 8 other bats suite files"
SS-18 lines 50-58: enumerate 9-suite roster using `tests/X.bats` paths

Internal contradiction in the meta-lint architecture subsystem itself — the artifact responsible for "factory tests itself" governance.

**Routing:** vsdd-factory:architect (bundle with F-PASS4-C2 sweep).

## Disciplines observed (positive)
- Retry-policy alignment across ADR-013, ADR-016, BC-2.13.003: 3 attempts, 60s base, 60/120/240s, exit 1, E-RATE-001 — consistent
- BC-2.06.003 VP-012 anchor correctly updated (F-PASS3-I4)
- VP-008 JSON catalog refs (F-PASS3-C2)
- VP-027 --sources flag + positional output-dir (F-PASS3-I2)
- BC-2.16.005 EC-002 --sources flag (F-PASS3-I3)
- Cross-doc count consistency verified (13 hooks, 26 skills, 19 GH templates, 6 Lobster, 95 BCs, 27 VPs, 17 ADRs, 18 SS, 25 NFRs, 21 error scopes, 9 bats)
- NFR catalog measurability verified (25 NFRs all quantitative)
- 3-CLEAN protocol consistency (BC-2.07.001-004 + ADR-009 + VP-010)
- 13 hook BCs all document JSON stdin/stdout
- Frontmatter consistency (subsystem: SS-NN, traces_to)
- Edge case catalog substantive (no stubs)
- Six-file gate question resolved: VP-INDEX correctly excluded (no line-number anchors in VPs)

## Process-gaps
- [process-gap] Pass 3 "explicit sibling-sweep verification" used grep-by-changed-token, not grep-by-canonical-pattern. Missed F-PASS4-C2 16-file blast radius.
- [process-gap] F-PASS2-I2 false attestation (claim of convention compliance not verified by violation grep). Discipline needed: when documenting new convention, grep for violations in same burst.
- [process-gap] Pass 3 fix-burst sibling-sweep claimed 6 architecture artifacts but missed 14+ stragglers. Pattern recurrence (F-PASS2-I4 same class).

## Streak
**0/3 (RESET)**. Convergence requires 3 consecutive zero-CRITICAL + zero-IMPORTANT passes.

## Recommended Next Action

1. **Architect fix-burst**: F-PASS4-C1 (ARCH-INDEX changelog), F-PASS4-C2 (16-file bats/→tests/ sweep + document new discipline), F-PASS4-C3 (ADR-012 line 89 dual fix), F-PASS4-I3 (SS-18 line 33).
2. **PO fix-burst**: F-PASS4-I1 (BC-2.04.014 emit event for non-brain) + F-PASS4-I2 (brief 0.4.15 → 0.4.16 single-token).
3. Pass 5 after both bursts land.

## Novelty: MEDIUM-HIGH
3 new sibling-sweep gaps + 3 new architectural-coherence defects. Convergence not approaching as Pass 3 anticipated — additional cascade iterations required.
