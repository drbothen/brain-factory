---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 3
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_passes: [pass-1 FAIL (7C+12I), pass-2 FAIL (4C+8I)]
producing_agents:
  - pass-2 architect fix-burst 4fe045a
  - pass-2 product-owner fix-burst 5023852
---

# Adversary Pass 3 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 2
- IMPORTANT: 4
- SUGGESTION: 2
- OBSERVATION: 2
- Streak: 0/3 (reset)

## Pass 1 + Pass 2 closure verification

Pass 2 closures verified clean: F-PASS2-C1 (event_type past-tense sweep), F-PASS2-C3 (VP-012 extension for BC-2.06.003), F-PASS2-I1 (test-vectors CLI), F-PASS2-I3 (BC-2.13.003 api-retry path), F-PASS2-I5 (E-INGEST-001), F-PASS2-I7 (templates/policies.yaml unified), F-PASS2-I8 (companion-posts 3).

Pass 2 closures INCOMPLETE (sibling-sweep gaps): F-PASS2-C2 (BC-2.12.003 swept but BC-2.12.001/.004 missed — F-PASS3-C1), F-PASS2-C4 (BC-2.17.002 frontmatter+lead-text swept but Edge Cases prose + VP row + BC-2.17.001 missed — F-PASS3-C2).

## NEW Critical findings

### F-PASS3-C1 CRITICAL — Sibling-sweep gap: BC-2.12.001 + BC-2.12.004 still use `.lobster` extension
- BC-2.12.001 Canonical Test Vector: `bin/lobster-run workflows/ingest-url.lobster`
- BC-2.12.004 Canonical Test Vector: `bin/lobster-run workflow.lobster < /dev/null`

Pass 2 F-PASS2-C2 swept BC-2.12.003 but missed sibling BCs in ss-12 subsystem. ADR-006 §Workflow extension convention requires `.yaml`. Implementer following BC-2.12.001 will create `ingest-url.lobster` which BC-2.12.003 EC-002 says meta-lint will flag as naming violation.

**Routing:** vsdd-factory:product-owner.

### F-PASS3-C2 CRITICAL — Sibling-sweep gap: BC-2.17.001 + BC-2.17.002 body prose stale on catalog location
- BC-2.17.001 Postcondition 1: "structured event catalog (at `plugins/brain-factory/docs/event-catalog.md` or equivalent)" — contradicts SS-17 + ARCH-INDEX (`scripts/event-catalog.json`)
- BC-2.17.002 EC-001: "NOT registered in `event-catalog.md`"
- BC-2.17.002 EC-002: "An `example_payload` in the catalog" — stale field name (canonical is `example`)
- BC-2.17.002 VP Proof Method: "bats integration.bats (markdown table parse)" — stale format

Pass 2 F-PASS2-C4 updated BC-2.17.002 frontmatter/Description/Postcondition/Invariant/Canonical Test Vector but missed Edge Cases prose + VP row + sibling BC-2.17.001.

**Routing:** vsdd-factory:product-owner.

## NEW Important findings

### F-PASS3-I1 IMPORTANT — Retry policy three-way contradiction (NEW)
- BC-2.13.003 + error-taxonomy E-RATE-001: 3 retries, 60s base, exponential 60/120/240s, exit 1 after 3 failures
- ADR-013: "Max retries: 5, exponential backoff 1s/2s/4s/8s... cap 300s"
- ADR-016 implementation: `max_attempts=5, delay=1, delay=$((delay * 2))`, cap 300

Different policies — different retry counts, timing, error surface.

Per Source-of-Truth Precedence: BC supersedes for contract semantics. Default fix: align ADR-013 + ADR-016 to BC numbers UNLESS architect surfaces concrete rationale to amend BC.

**Routing:** vsdd-factory:architect.

### F-PASS3-I2 IMPORTANT — VP-027 cites non-canonical gen-test-corpus.sh flags
- VP-027: `gen-test-corpus.sh --brain "$brain_dir" --pages 999` and `--pages 9999`
- ADR-012 canonical: positional `<output-dir>`, flags `--sources`, `--seed`, `--topics`, `--avg-words`, `--wiki-ratio`, `--format`. No `--brain` or `--pages`.

**Routing:** vsdd-factory:architect.

### F-PASS3-I3 IMPORTANT — BC-2.16.005 uses non-canonical `--count` flag
- BC-2.16.005: `gen-test-corpus.sh --seed 42 --count 10000`
- Canonical (ADR-012 + BC-2.16.006): `--sources` flag

Sibling-sweep gap from F-PASS1-C2.

**Routing:** vsdd-factory:product-owner.

### F-PASS3-I4 IMPORTANT — BC-2.06.003 VP-012 anchor label mis-anchored
- BC-2.06.003: "VP-012 — Manifest schema integrity (Group 2: last_ingest field correctness)"
- VP-012 title: "Manifest write atomicity and last_ingest field correctness"

Pass 2 fix-burst updated VP-012 title but BC anchor label not swept.

**Routing:** vsdd-factory:product-owner.

## Suggestions

### F-PASS3-S1 — VP-026 counterexample uses `"hook.start"` (imperative); could be `"hook.started"`
### F-PASS3-S2 — SS-13 v0.5 `cold-start-recover.yml` vs brief `cold-start.yml` slight rename drift

## Observations

### F-PASS3-O1 — Brief retains legacy citations (`.lobster`, old workflow names, `policies-yaml-template.yaml`) — expected post-convergence; brief is immutable; downstream supersedes
### F-PASS3-O2 [process-gap] — Pass 2 fix-bursts terminated scope at primary contract surfaces without sweeping all prose mentions in same file + sibling files. Recommend: fix-burst checklist add "grep -n <old-value> <file>" verification.

## Disciplines observed (positive)
- Past-tense event_type sweep across 14 hook BCs ✓
- Five-file gate canonical ✓
- api-retry.sh dual-copy pattern ✓
- VP-012 BC-2.06.003 coverage real ✓
- 9-suite roster sweep (audit-trail only) ✓
- No AI attribution / no --no-verify ✓

## Five-file gate self-test
CLEAN across all 5 canonical files.

## P0 VP coverage independent verification
64/64 P0 BCs covered. VP-INDEX honest. BC-2.06.003 covered by VP-012 Group 2.

## Recommended next action

FAIL — fix-burst pair required.

1. vsdd-factory:product-owner: F-PASS3-C1, C2, I3, I4.
2. vsdd-factory:architect: F-PASS3-I2, I1.

Process-gap F-PASS3-O2 → cycle-closing checklist.

## Novelty: MEDIUM
3 NEW sibling-sweep gaps + 1 NEW architectural contradiction. Convergence trending positive: CRITICAL 7 → 4 → 2 across Pass 1 → 2 → 3.
