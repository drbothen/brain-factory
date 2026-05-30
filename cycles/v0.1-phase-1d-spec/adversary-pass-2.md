---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 2
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
prior_pass_verdict: FAIL — Pass 1 found 7 CRITICAL + 12 IMPORTANT
producing_agents:
  - vsdd-factory:architect (fix-burst f5adb81)
  - vsdd-factory:product-owner (fix-burst 034f0cc)
---

# Adversary Pass 2 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 4
- IMPORTANT: 8
- SUGGESTION: 3
- OBSERVATION: 4
- Streak: 0/3 (reset)

Pass 2 verifies Pass 1 closures (13 fully closed, 4 partial sibling-sweep gaps, 2 revealed new defects) AND surfaces 4 NEW CRITICAL + 8 NEW IMPORTANT findings the producing agents missed.

## Scope reviewed (UPDATED VERSIONS)
- Brief v0.4.15 (Phase 1a converged)
- PRD v0.1.3 + 4 supplements (Phase 1b/1c-aligned + Pass 1 fixed)
- BC-INDEX v0.1.2; 95 BCs SS-NN-aligned + Pass 1 fixed
- ARCH-INDEX v0.1.2; 17 ADRs; 18 SS-NN designs (Phase 1c + Pass 1 fixed)
- VP-INDEX v0.1.1; 27 VPs

## Pass 1 closure verification

| Finding | Status | Evidence |
|---------|--------|----------|
| F-PASS1-C1 (BC-2.13.001 v0.1 templates) | VERIFIED CLOSED | Description+Postconditions+Test Vectors enumerate ADR-013 canonical names. quarterly-mirror flagged as v0.5. |
| F-PASS1-C2 BC portion (BC-2.16.006 CLI) | PARTIAL — sibling-sweep gap | BC body correct. test-vectors.md scale-test scenario STILL uses OLD CLI (--dir flag, positional count). See F-PASS2-I1. |
| F-PASS1-C2 ADR portion (.yml/.yaml) | VERIFIED LOCALLY; ARCH-WIDE DRIFT REVEALED | ADR-012 fixed. But ADR-006/SS-02/SS-03/SS-12/ADR-010/ADR-003/ARCH-INDEX still use .yaml for Lobster workflows. BC-2.12.003 introduces .lobster as 3rd extension. See F-PASS2-C2 + F-PASS2-I2. |
| F-PASS1-C3 (BC-2.04.017 + E-HOOK-002 path) | VERIFIED CLOSED | Both BC and error-taxonomy say hooks/lib/hook-event-emit.sh. |
| F-PASS1-C4 (SS-04 4 helpers) | VERIFIED CLOSED | SS-04 enumerates 4 helpers; sha256.sh attributed to ADR-015. |
| F-PASS1-C5 (SS-16 baseline 50K) | VERIFIED CLOSED | Matches BC-2.16.002 + NFR-007. |
| F-PASS1-C6 (PRD 5-file gate) | VERIFIED CLOSED | PRD Self-Audit uses 5-file for-loop with ARCH-INDEX. |
| F-PASS1-C7 (api-retry.sh path) | PARTIAL — sibling-sweep gap | SS-13/ADR-013 correct. BC-2.13.003 STILL says scripts/api-retry.sh (no lib/). See F-PASS2-I3. |
| F-PASS1-I1 (zero-arg CLI) | VERIFIED CLOSED | interface-definitions.md confirms; SS-01 documents. |
| F-PASS1-I2 (E-INIT-002 hard-fail) | VERIFIED CLOSED | BC-2.01.001 explicit; SS-01 documents. |
| F-PASS1-I3 (SS-01 bats roster) | VERIFIED CLOSED (test surface) BUT SEE F-PASS2-I4 | SS-01 cites tests/integration.bats. But broader 9-suite roster conflict surfaces between brief and SS-18. |
| F-PASS1-I4 (past-tense event_type) | PARTIAL — SIBLING-SWEEP FAILURE | BC-2.04.001 + .017 + SS-17 done. BC-2.04.002 STILL has `source.immutability.violation` (forbidden noun form per SS-17). See F-PASS2-C1. |
| F-PASS1-I5 (SS-09 E-PUBLISH-001) | VERIFIED CLOSED | |
| F-PASS1-I6 (SS-08 voice matcher) | VERIFIED CLOSED | |
| F-PASS1-I7 (companion-posts: 3) | PARTIAL | interface-definitions.md updated. BC-2.08.003 test vector STILL says "3–5 files". See F-PASS2-I8. |
| F-PASS1-I8 (SS-18 per-hook bats) | VERIFIED CLOSED | |
| F-PASS1-I9 (VP-021 counterexample) | VERIFIED CLOSED | |
| F-PASS1-I10 (VP-TBD backfill 95 BCs) | PARTIAL — REVEALS NEW DEFECT | Backfill done. But exposed BC-2.06.003 P0 has no VP per VP-INDEX matrix while VP-012 frontmatter claims it. See F-PASS2-C3. |
| F-PASS1-I11 (PRD §7 RTM Test Type) | VERIFIED CLOSED | |
| F-PASS1-I12 (SS-04 wording) | VERIFIED CLOSED | |
| 3 cross-cutting decisions | VERIFIED CLOSED | SS-01 + SS-17 documented. |

**Closure summary:** 13 fully verified, 4 partial sibling-sweep gaps, 2 revealed new defects.

## NEW CRITICAL findings — F-PASS2-CN

### F-PASS2-C1 — F-PASS1-I4 sibling-sweep failure: BC-2.04.002 uses forbidden noun-form event_type (CRITICAL, HIGH)
**Location:** `.factory/specs/behavioral-contracts/ss-04/BC-2.04.002.md` Postconditions: `event_type: "source.immutability.violation"` and `event_type: "source.new"`.
SS-17 §Event-type naming convention (line ~44) explicitly cites `source.immutability.violation` as the canonical FORBIDDEN example. Past-tense required.
**Why critical:** BC publishes the exact string SS-17 forbids. Direct in-spec contradiction. Sibling-sweep failure: F-PASS1-I4 fix only updated BC-2.04.001/.017 of 13 hook BCs.
**Routing:** vsdd-factory:product-owner (sweep all 13 hook BCs).

### F-PASS2-C2 — BC-2.12.003 vs SS-12 vs ADR-006 three-way contradiction on Lobster workflow filenames+extension (CRITICAL, HIGH)
**Evidence:** Three-way contradiction:
- BC-2.12.003: `ingest-url.lobster, daily-ritual.lobster, weekly-synthesis.lobster, monthly-perf.lobster, quarterly-mirror.lobster, cold-start-recovery.lobster`
- SS-12 + ADR-006: `ingest-url.yaml, ingest-source.yaml, brief-to-publish.yaml, daily-ritual.yaml, weekly-refresh.yaml, scale-test.yaml`
Two issues: extension drift (.lobster vs .yaml), filename drift (only 3 of 6 overlap).
**Why critical:** Implementer cannot resolve which workflow files to ship. Core deliverable of CAP-012. Phase 2 story decomposition blocked.
**Routing:** vsdd-factory:architect (resolve canonical 6 names + extension).

### F-PASS2-C3 — VP-INDEX 64/64 P0 coverage claim is paper-fix; reality 63/64; 4-way drift around BC-2.06.003 (CRITICAL, HIGH)
**Evidence:** Four-way drift:
1. VP-012 frontmatter `verifies_bcs: [BC-2.03.002, BC-2.06.003]` — claims it covers BC-2.06.003.
2. VP-INDEX VP-012 row Target BCs: `NFR-018, BC-2.03.002` — does NOT list BC-2.06.003.
3. VP-INDEX P0 Coverage Matrix SS-06 row: only BC-2.06.001 covered. BC-2.06.003 NOT in matrix.
4. VP-INDEX Coverage summary: "64 of 64 P0 BCs covered. No deferrals."
5. BC-2.06.003 body: "(no direct VP — P0; VP gap noted)"
6. VP-012 Property Statement: only manifest atomicity, NOT last_ingest timestamp.

Real coverage: 63/64. False attestation in VP-INDEX. PO surfaced this in Pass 1 fix-burst; orchestrator deferred to Pass 2 — independently confirmed CRITICAL paper-fix.
**Routing:** vsdd-factory:architect (extend VP-012 to actually cover BC-2.06.003 OR create new VP for it; update VP-INDEX matrix + Coverage summary).

### F-PASS2-C4 — BC-2.17.002 contradicts SS-17 on catalog location, format, fields, naming pattern (CRITICAL, HIGH)
**Evidence:** Four contradictions:
1. Location: BC says `plugins/brain-factory/docs/event-catalog.md`. SS-17/ARCH-INDEX say `scripts/event-catalog.json`.
2. Format: BC says markdown table. SS-17 says JSON array.
3. Fields: BC says `event_type, hook_name, severity, trigger, fields, example_payload`. SS-17 says `event_type, hook_name, severity, fields, example` (no `trigger`; `example` not `example_payload`).
4. Pattern: BC says `<subsystem>.<action>`. SS-17 says `<domain>.<past-tense-verb>`.
**Why critical:** BC-2.17.002 IS the catalog schema contract. Implementer cannot ship two formats.
**Routing:** vsdd-factory:product-owner (align BC-2.17.002 with SS-17).

## NEW IMPORTANT findings — F-PASS2-IN

### F-PASS2-I1 — F-PASS1-C2 sibling-sweep gap: test-vectors.md still uses OLD gen-test-corpus.sh CLI
test-vectors.md scale-test scenario: `bash scripts/gen-test-corpus.sh 10000 --seed 42 --dir /tmp/scale-brain`. Per ADR-012 + BC-2.16.006 (F-PASS1-C2 closure): canonical is `--sources 10000 --seed 42 /tmp/scale-brain`.
**Routing:** vsdd-factory:product-owner.

### F-PASS2-I2 — Lobster workflow extension drift (.yaml/.yml convention) — architecture-wide
ADR-006/SS-02/SS-03/SS-12/ADR-010/ADR-003/ARCH-INDEX all use .yaml for Lobster workflows; ADR-012/ADR-013 use .yml for GH Actions. Convention may be intentional but undocumented; BC-2.12.003 introduces .lobster as 3rd extension.
**Routing:** vsdd-factory:architect (document convention in ADR-006 or ADR-013).

### F-PASS2-I3 — F-PASS1-C7 sibling-sweep gap: BC-2.13.003 still cites scripts/api-retry.sh (no lib/)
BC-2.13.003 line ~38: "centralized in `scripts/api-retry.sh`". Canonical is `scripts/lib/api-retry.sh` per F-PASS1-C7.
**Routing:** vsdd-factory:product-owner.

### F-PASS2-I4 — Two competing 9-suite bats roster definitions (brief vs SS-18)
Brief v0.4.15 + BC-2.18.005: `{skills.bats, hooks.bats, templates.bats, policies.bats, adversary.bats, quarantine.bats, integration.bats, upgrade.bats, meta-lint.bats}`.
SS-18: `{meta-lint.bats, hooks.bats, ingest.bats, wiki.bats, quarantine.bats, adversary.bats, policies.bats, upgrade.bats, integration.bats}`.
Brief uses skills.bats + templates.bats; SS-18 uses ingest.bats + wiki.bats.
~20 artifact citations across SS-08/SS-09/SS-11, VP-016/018/019/020, ARCH-INDEX VP-INDEX Summary, BC bodies cite skills.bats/templates.bats.
**Why important:** Brief is parent spec (Phase 1a converged). SS-18's renaming is undocumented (no ADR). Per Source-of-Truth Precedence: brief wins; SS-18 must be brought into alignment. ~20 sibling-sweep callsites already aligned with brief naming.
**Routing:** vsdd-factory:architect (align SS-18 to brief naming) + vsdd-factory:product-owner (sweep ~20 callsites that may have been already-aligned to brief).

### F-PASS2-I5 — SS-02 cites E-SOURCE-002 for duplicate-URL but BC-2.02.006 + error-taxonomy say E-INGEST-001
SS-02 line 30 + 45: "BC-2.02.006 | Rejects already-ingested URL with E-SOURCE-002". Error-taxonomy: E-SOURCE-002 is "manifest.json unreadable", E-INGEST-001 is "URL already ingested".
**Routing:** vsdd-factory:architect (update SS-02 to E-INGEST-001).

### F-PASS2-I6 — BC-2.04.013/014 + others don't document event_type emission despite BC-2.04.017 universal requirement
Only BC-2.04.001, .002 explicitly document event_type. The other 11 hook BCs don't enumerate event_types but BC-2.04.017 requires "for every hook invocation, at minimum one JSONL event is written to stderr".
**Routing:** vsdd-factory:product-owner (enumerate event_type per BC) OR vsdd-factory:architect (produce event-catalog.json draft).

### F-PASS2-I7 — templates/policies.yaml vs templates/policies-yaml-template.yaml filename drift
BC-2.15.001 + BC-2.01.001: `templates/policies-yaml-template.yaml`. SS-15 + ARCH-INDEX: `templates/policies.yaml`.
**Routing:** vsdd-factory:product-owner + vsdd-factory:architect agree on canonical filename, sibling-sweep.

### F-PASS2-I8 — F-PASS1-I7 partial: BC-2.08.003 Canonical Test Vector still says "3–5 files" while interface-definitions.md updated to "3"
Two contract surfaces, two answers.
**Routing:** vsdd-factory:product-owner.

## SUGGESTIONS

### F-PASS2-S1 — VP-012 should be renamed/augmented to disambiguate "manifest atomicity" vs "last_ingest timestamp"
If F-PASS2-C3 resolved by adding BC-2.06.003 to VP-012, rename VP-012 OR split into VP-012 + new VP-028.

### F-PASS2-S2 — SS-15 baseline 10 policies listed but no canonical templates/policies.yaml fixture
For implementation, ship the canonical 10 baseline policy YAML blobs.

### F-PASS2-S3 — BC-2.17.001 says event-catalog.md; SS-17 says event-catalog.json
Same disambiguation as F-PASS2-C4. Spot-check BC-2.17.001 to align.

## OBSERVATIONS

### F-PASS2-O1 [process-gap] — Consistency-validator forward-only; no reverse-traceability check on VP verifies_bcs ↔ VP-INDEX rows
Phase 1c consistency-validator caught F-1c-CV-05 (VP-013) forward but persistent same-class defect at VP-012 (file claims BC-2.06.003, table doesn't list it). Reverse check would have caught.
**Recommendation:** add reverse-traceability bash one-liner to consistency-validator.

### F-PASS2-O2 [process-gap] — No sibling-sweep enforcement for cross-artifact value changes
F-PASS1-I4/I7/C2/C7 fix-bursts had sibling-sweep gaps consistency-validator missed. Pattern: validator runs at index/anchor level, not prose level.
**Recommendation:** post-fix-burst grep gate.

### F-PASS2-O3 — Brief discrepancy with architecture on bats suite roster requires policy decision
F-PASS2-I4 surfaced this. Per CLAUDE.md Source-of-Truth Precedence + brain-factory-001: brief is parent spec, SS-18 must align.

### F-PASS2-O4 — BC-2.06.003 P0 status itself may be the issue, not the missing VP
In v0.x, last_ingest=ingested_at since sources are write-once. The "P0" rating may be over-prioritized for v0.x; could be reduced to P1.

## Independent P0 VP coverage verification

**Authoritative P0 BC count: 64** (verified by direct count of `| P0 |` rows in BC-INDEX.md):
- SS-01: 4 (.001-.004)
- SS-02: 5 (.001-.004, .006)
- SS-03: 4 (.001-.004)
- SS-04: 14 (.001-.007, .009-.012, .015-.017)
- SS-05: 6 (.001-.006)
- SS-06: 2 (.001, .003)
- SS-07: 3 (.001, .002, .004)
- SS-08: 2 (.001, .002)
- SS-09: 3 (.001, .004, .005)
- SS-10: 3 (.001-.003)
- SS-12: 3 (.001, .002, .004)
- SS-13: 1 (.001)
- SS-14: 4 (.001, .003, .004, .005)
- SS-16: 1 (.001)
- SS-17: 4 (.001-.004)
- SS-18: 5 (.001-.005)
- **Total: 64**

**Real coverage from VP `verifies_bcs:` arrays:** 63/64. BC-2.06.003 not in any VP's verifies_bcs (VP-012 frontmatter mentions it but VP body+VP-INDEX table+matrix don't). VP-INDEX claim 64/64 is FALSE — paper-fix per TD-VSDD-059.

## Five-file gate self-test

CLEAN on all five files (brief, handoff, prd/index.md, BC-INDEX, ARCH-INDEX) for literal-line-number-token pattern. The gate checks writing-discipline; it does NOT cover content correctness in BC body files, ADR body files, SS body files, or VP body files. Content defects above are not detectable by the gate.

## Top 3 most concerning findings

1. **F-PASS2-C3** — VP-INDEX 64/64 paper-fix; reality 63/64. False attestation in canonical VP coverage matrix; TD-VSDD-059 violation. Pass 1 fix-bursts acknowledged but did NOT close.
2. **F-PASS2-C2** — BC-2.12.003 vs SS-12 vs ADR-006 three-way Lobster workflow contradiction. Phase 2 blocked for CAP-012.
3. **F-PASS2-C1** — F-PASS1-I4 sibling-sweep failure (BC-2.04.002 still uses forbidden noun-form). PO fix-burst stopped at 1 of 13 hook BCs.

## Recommended next action

FAIL — fix-burst required. Streak resets to 0/3.

Routing for fix-burst:
1. vsdd-factory:architect: F-PASS2-C2 (Lobster workflow resolution), F-PASS2-C3 (VP-INDEX 64/64 closure), F-PASS2-I2 (.yaml/.yml convention doc), F-PASS2-I4 (align SS-18 to brief naming), F-PASS2-I5 (SS-02 E-INGEST-001).
2. vsdd-factory:product-owner: F-PASS2-C1 (past-tense sweep all 13 hook BCs), F-PASS2-C4 (BC-2.17.002 align to SS-17), F-PASS2-I1 (test-vectors CLI), F-PASS2-I3 (BC-2.13.003 path), F-PASS2-I4 follow-on (~20 callsites), F-PASS2-I6 (event_type enumeration), F-PASS2-I7 (template filename), F-PASS2-I8 (BC-2.08.003 count).

After fix-burst, Pass 3.

Process-gaps F-PASS2-O1, F-PASS2-O2 tracked for cycle-closing checklist.

## Novelty: HIGH
4 NEW CRITICAL + 8 NEW IMPORTANT beyond Pass 1 verification. Findings include:
- Fully-confirmed paper-fix (VP-INDEX 64/64 vs 63/64)
- 3 sibling-sweep gaps from Pass 1 fix-bursts
- New 3-way contradiction (BC-2.12.003 vs SS-12 vs ADR-006)
- New BC-vs-SS contradiction at catalog schema layer
- New 9-suite roster brief-vs-architecture conflict
- New SS-02 error code misuse

Convergence not close: 4 CRITICAL + 8 IMPORTANT remain.
