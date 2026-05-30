---
artifact_type: adversary-pass-report
phase: phase-1d-adversarial-spec-review
pass_number: 1
verdict: FAIL
streak_after: 0/3
created: 2026-05-16
---

# Adversary Pass 1 — Phase 1d brain-factory Spec Review

## Verdict: FAIL
- CRITICAL: 7
- IMPORTANT: 12
- SUGGESTION: 5
- OBSERVATION: 4
- Streak: 0/3 (was 0/3 at Phase 1d entry; remains 0/3)

## Scope reviewed
- Brief v0.4.15 (802 lines) — Changelog + Vision/Problem/Targets/ValueProp sections
- PRD v0.1.2 (~547 lines) — full index + 4 supplements (error-taxonomy, nfr-catalog, interface-definitions, test-vectors header)
- BC-INDEX v0.1.1
- Sample BCs across 18 subsystems: BC-2.01.001 (via VP-014), BC-2.02.x, BC-2.04.001, BC-2.04.016, BC-2.04.017, BC-2.13.001, BC-2.16.002, BC-2.16.006, BC-2.18.003
- Architecture v0.1.1: ARCH-INDEX + 17 ADRs (ADR-001, ADR-002, ADR-007, ADR-008, ADR-012, ADR-013, ADR-015, ADR-016 read in full; remainder via grep)
- 18 SS-NN designs sampled (SS-01, SS-04, SS-05, SS-08, SS-09, SS-10, SS-12, SS-13, SS-16, SS-17, SS-18 read in full)
- VP-INDEX + sample VPs (VP-014, VP-021)

## CRITICAL findings — F-PASS1-CN

### F-PASS1-C1 — BC-2.13.001 enumerates v0.1 templates that contradict ADR-013 (HIGH confidence)
**Location:** `.factory/specs/behavioral-contracts/ss-13/BC-2.13.001.md` (Description, line ~22) vs `.factory/specs/architecture/adr/ADR-013-github-action-templates.md` (lines 37–43) + SS-13 §Key Design (line ~40).

BC-2.13.001 Description: "v0.1 plugin tarball includes 6 GitHub Action YAML templates: `daily-brief.yml`, `weekly-lint.yml`, `weekly-synthesis.yml`, `schema-refresh.yml`, `wikilink-check.yml`, `quarterly-mirror.yml`."

ADR-013 (authoritative): "v0.1 core set (6 templates): daily-brief.yml, weekly-refresh.yml, ingest-rss.yml, health-check.yml, lint-wiki.yml, scale-test.yml".

Only `daily-brief.yml` overlaps. Five of six are different names. Worse: BC-2.13.001 lists `quarterly-mirror.yml` as v0.1; ADR-013 lists `quarterly-mirror.yml` as #7 in the **v0.5 additions**. The implementer cannot satisfy both contracts; the ship gate is unimplementable from the spec alone.

**Recommended remediation:** product-owner reconciles BC-2.13.001 Description and Postconditions to use the ADR-013 canonical names.
**Routing:** vsdd-factory:product-owner. **Confidence:** HIGH.

### F-PASS1-C2 — BC-2.16.006 and ADR-012 specify incompatible `gen-test-corpus.sh` CLI (HIGH)
**Location:** `.factory/specs/behavioral-contracts/ss-16/BC-2.16.006.md` (canonical test vector, line ~54) vs `.factory/specs/architecture/adr/ADR-012-test-corpus-generation.md` (lines 33–45).

ADR-012 Usage: `gen-test-corpus.sh [OPTIONS] <output-dir>` with `--sources N`, `--seed N`, `--topics`, `--avg-words`, `--wiki-ratio`, `--format`.

BC-2.16.006 canonical test vector: `gen-test-corpus.sh 10000 --seed 42 --dir /tmp/test-brain` — uses positional N (10000) and `--dir` flag, NOT positional `<output-dir>` and `--sources N`.

Incompatible CLIs. Additionally ADR-012 §Integration says `workflows/scale-test.yaml` (`.yaml`) while ADR-013 says template is `scale-test.yml` (`.yml`).

**Recommended remediation:** Reconcile to one canonical CLI (ADR is authoritative). Update BC-2.16.006 canonical test vector + extend Postconditions to include all six ADR-012 flags. Fix the .yml/.yaml extension drift.
**Routing:** vsdd-factory:product-owner (BC), vsdd-factory:architect (ADR-012 extension drift). **Confidence:** HIGH.

### F-PASS1-C3 — Hook-event-emit helper path drift: BC-2.04.017 and error-taxonomy say `scripts/`, architecture says `hooks/lib/` (HIGH)
**Location:** `.factory/specs/behavioral-contracts/ss-04/BC-2.04.017.md` (Precondition 2, line ~27); `.factory/specs/prd/prd-supplements/error-taxonomy.md` (E-HOOK-002, line ~56); ADR-016 lines 35–36; ADR-002 line 71; ADR-014 line 40; ARCH-INDEX line 148; SS-04 line 60.

BC-2.04.017 Precondition 2: "The `hook-event:emit` helper function is sourced from `${CLAUDE_PLUGIN_ROOT}/scripts/hook-event-emit.sh`."
E-HOOK-002 message: "Event emission helper missing at `${CLAUDE_PLUGIN_ROOT}/scripts/hook-event-emit.sh`."
ADR-016 (authoritative): the helper lives at `hooks/lib/hook-event-emit.sh`. All other architecture artifacts agree.

Sibling-sweep gap from Phase 1c's hooks/lib/ decision: location was decided at the ADR layer but not propagated back into the BC body or the error message.

**Recommended remediation:** product-owner updates BC-2.04.017 Precondition 2 and error-taxonomy E-HOOK-002 message to `${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh`.
**Routing:** vsdd-factory:product-owner. **Confidence:** HIGH.

### F-PASS1-C4 — SS-04 lists 3 shared helpers but skips api-retry.sh and misattributes sha256.sh to ADR-016 (HIGH)
**Location:** `.factory/specs/architecture/subsystems/SS-04-hook-enforcement-chain.md` (line ~60).

SS-04 says: "**Shared helpers:** `hooks/lib/hook-event-emit.sh`, `hooks/lib/manifest-write.sh`, `hooks/lib/sha256.sh` (ADR-016)".

But ADR-016 title is "Hook helper architecture: hook-event-emit.sh, api-retry.sh, manifest-write.sh" — defines exactly those three, NOT sha256.sh. The `sha256.sh` portability shim is defined in ADR-015. So SS-04's three-helper list (a) omits `api-retry.sh` (used by SS-09 LinkedIn calls per ADR-016 line 132), and (b) wrongly attributes `sha256.sh` to ADR-016 when it's an ADR-015 artifact. Actual helper count under hooks/lib/ is **four**.

**Recommended remediation:** architect updates SS-04 line ~60 to enumerate all four helpers correctly and reattribute sha256.sh to (ADR-015). Optionally update ADR-016 inventory or add explicit doc that sha256.sh is the fourth shared helper governed by ADR-015.
**Routing:** vsdd-factory:architect. **Confidence:** HIGH.

### F-PASS1-C5 — SS-16 Budget Alert uses "100K baseline" contradicting brief + BC-2.16.002 50K baseline (HIGH)
**Location:** `.factory/specs/architecture/subsystems/SS-16-scale-aware-architecture.md` (line ~50) vs `.factory/specs/behavioral-contracts/ss-16/BC-2.16.002.md` (lines ~22, 34, 38); brief §Scalability §5; NFR-007.

SS-16 §Budget alert (BC-2.16.002): "...if the 30-day average exceeds 2x the baseline (**100K tokens; 2x = 200K**)."
BC-2.16.002 Description: "compares it to **the 50K-token baseline**. If the trailing average exceeds 100K tokens (2x baseline), the Sources dimension of the health report goes YELLOW".

SS-16's parenthetical claim that "the baseline (100K tokens; 2x = 200K)" is wrong; the baseline is 50K, the 2x threshold is 100K. The implementer following SS-16 would set the alert threshold at 200K (2x the wrong 100K) — twice as permissive as the spec requires.

**Recommended remediation:** architect updates SS-16 §Budget alert to: "exceeds 2x the baseline (50K tokens; 2x = 100K)" — matching BC-2.16.002 and brief §Scalability §5.
**Routing:** vsdd-factory:architect. **Confidence:** HIGH.

### F-PASS1-C6 — Five-file gate command in PRD index still says four-file (HIGH; sibling-sweep gap)
**Location:** `.factory/specs/prd/index.md` (Self-Audit Checklist, lines ~504–512).

The PRD index Self-Audit Checklist item is labeled "Changelog audit-trail discipline (inherited four-file gate)" and iterates over four files (brief, handoff, prd/index.md, BC-INDEX.md). Text says "All four files... must be free of literal line-number anchors." Says "extended to a four-file gate."

But STATE.md, SESSION-HANDOFF.md, BC-INDEX.md, and ARCH-INDEX.md all state the gate is the canonical **five-file** gate that adds `architecture/ARCH-INDEX.md`. BC-INDEX and ARCH-INDEX carry the correct five-file command. The PRD index — itself one of the five canonical files — codifies an outdated four-file gate. Sibling-sweep gap from F-1c-CV-02 closure: ARCH-INDEX added to BC-INDEX and ARCH-INDEX gates, but not to the PRD index gate.

**Recommended remediation:** product-owner extends the PRD index Self-Audit Checklist gate to the canonical five-file `for`-loop, updates "four-file" → "five-file", adds the architecture ID token exclusion clause.
**Routing:** vsdd-factory:product-owner. **Confidence:** HIGH.

### F-PASS1-C7 — SS-13 references nonexistent `scripts/api-retry.sh` path that contradicts both ADR-013 and ADR-016 (HIGH)
**Location:** `.factory/specs/architecture/subsystems/SS-13-github-action-templates.md` (line ~46).

SS-13 says: "Rate-limit handling for all templates calling external APIs: uses `scripts/api-retry.sh` wrapper per ADR-016."
ADR-013 §Rate-limit handling says: "Implemented via `hooks/lib/api-retry.sh` (ADR-016)" — wrong for GH Actions context.
ADR-016 §api-retry.sh Delivery for GitHub Actions is explicit: GH Actions templates use `scripts/lib/api-retry.sh` (NOT `hooks/lib/`, NOT `scripts/`). Three different paths exist; only `scripts/lib/api-retry.sh` is correct per the most-recent dispositive resolution.

**Recommended remediation:** architect updates SS-13 to `scripts/lib/api-retry.sh` and corrects ADR-013 from `hooks/lib/api-retry.sh` to `scripts/lib/api-retry.sh` (within the GH Actions context).
**Routing:** vsdd-factory:architect. **Confidence:** HIGH.

## IMPORTANT findings — F-PASS1-IN

### F-PASS1-I1 — VP-014 invokes /brain:init with --target / --yes flags that contradict the BC-2.01.001 zero-argument interface (MEDIUM)
**Location:** VP-014 lines 47, 80, 93, 102, 113 vs interface-definitions.md (line ~25, `/brain:init | (no arguments)`).
VP-014 invokes `bash "${CLAUDE_PLUGIN_ROOT}/skills/init/run.sh" --target "$brain_dir" --yes`. Either skill has hidden flags not in public interface, or VP-014 asserts wrong contract.
**Routing:** vsdd-factory:product-owner (decide flags' public/internal status; if public, update interface-definitions.md). **Confidence:** MEDIUM.

### F-PASS1-I2 — VP-014 asserts E-INIT-002 hard-failure for already-initialized brain, but SS-01 says idempotent scaffold (no overwrite) (MEDIUM)
**Location:** VP-014 lines 98–106 vs SS-01 line 56 ("edge: already-initialized brain → idempotent scaffold (no overwrite)").
Mutually exclusive expected behaviors: VP-014's third bats test asserts `assert_failure 2` with `code: E-INIT-002`; SS-01 commits to idempotent re-init. Error-taxonomy E-INIT-002 is real but SS-01 promises idempotent.
**Routing:** vsdd-factory:architect (SS-01 owner) + vsdd-factory:product-owner (BC edges). **Confidence:** MEDIUM.

### F-PASS1-I3 — SS-01 references `bats/init.bats` not in canonical 9-suite roster (MEDIUM)
**Location:** SS-01 line 56 vs SS-18 lines 41–50 (9-suite roster).
SS-01 test surface: `bats/init.bats`. SS-18 9-suite roster: `meta-lint, hooks, ingest, wiki, quarantine, adversary, policies, upgrade, integration` — no `init.bats`. Implementer would create 10th `init.bats` violating NFR-019. Same defect class as F-PASS14-I1 from Phase 1a brief cascade recurring at architecture layer.
**Routing:** vsdd-factory:architect (decide whether init lives in integration.bats or ingest.bats; update SS-01). **Confidence:** MEDIUM.

### F-PASS1-I4 — Event-type naming inconsistency: BC-2.04.001/.017 use `quarantine.block`; SS-17 catalog example uses `quarantine.blocked` (MEDIUM)
**Location:** BC-2.04.001 line 42; BC-2.04.017 line 42; SS-17 line 51.
Same event with two names. BC-2.17.001 mandates registered catalog row per emit site — but catalog example uses different name from emit site.
**Routing:** vsdd-factory:architect (SS-17 catalog) + vsdd-factory:product-owner (BC bodies) to reconcile to one canonical convention. **Confidence:** MEDIUM.

### F-PASS1-I5 — SS-09 cites wrong error code E-PUBLISH-002 for "invalid transition" path (MEDIUM)
**Location:** `.factory/specs/architecture/subsystems/SS-09-publishing-pipeline.md` lines ~57–58.
SS-09 says: "Any other transition: E-PUBLISH-002 block." But error-taxonomy E-PUBLISH-002 is "Missing status field in content file" — not "invalid transition". The "invalid transition" code is E-PUBLISH-001.
**Routing:** vsdd-factory:architect. **Confidence:** MEDIUM.

### F-PASS1-I6 — SS-08 says voice avoid-list fires on writes to `briefs/` but interface-definitions.md matcher restricts to `briefs/content/*-draft.md` (MEDIUM)
**Location:** SS-08 line 64 vs interface-definitions.md line 152.
Hook matcher in interface-definitions.md (PRD supplement, authoritative interface contract) is much narrower than SS-08's prose. Implementer per SS-08 would over-fire; per interface-definitions.md narrower behavior.
**Routing:** vsdd-factory:architect (SS-08 owner) to align with matcher OR vsdd-factory:product-owner to expand matcher. **Confidence:** MEDIUM.

### F-PASS1-I7 — Companion-posts count drift: SS-08 says "3", interface-definitions says "3–5" (MEDIUM)
**Location:** SS-08 line 68 vs interface-definitions.md line 221.
Implementer needs to know whether to generate exactly 3 or up to 5.
**Routing:** vsdd-factory:architect or vsdd-factory:product-owner. **Confidence:** MEDIUM.

### F-PASS1-I8 — BC-2.18.002 body narrower than SS-18 design extension (MEDIUM)
**Location:** BC-2.18.002 vs SS-18 lines 63–70.
SS-18 specifies meta-lint must check 7 conditions on each hook; BC-2.18.002 only formally commits to 4. Additionally "Has corresponding `.bats` test file" implies per-hook test files, but SS-18's 9-suite roster has all hooks in ONE file (hooks.bats).
**Routing:** vsdd-factory:product-owner (extend BC body) AND vsdd-factory:architect (decide per-hook test files vs single-file). **Confidence:** MEDIUM.

### F-PASS1-I9 — VP-021 contradicts itself on missing-corpus exit code semantics (MEDIUM, internal contradiction)
**Location:** VP-021 line 25 vs line 152.
Line 25 (Property): "Fail-closed: if `scripts/quarantine.mjs` fails to load or throws, the skill exits 2."
Line 152 (Counterexamples): "`scripts/quarantine.mjs` missing causes the skill to exit 0 (silently pass)..."
Either rewrite line 152 to clearly mark the regression-pattern, or remove the ambiguity.
**Routing:** vsdd-factory:architect (VP-021 owner). **Confidence:** MEDIUM.

### F-PASS1-I10 — All 95 BCs carry `VP-TBD` placeholders despite Phase 1c VP coverage closure (MEDIUM, sibling-sweep)
**Location:** All 95 BC files — `VP-TBD` appears 199 times across 95 files; 91/95 BCs have `[S-TBD]` Story Anchor.
Phase 1c added 14 new VPs achieving 64/64 P0 coverage per VP-INDEX. Forward mapping (VP → BCs) complete via verifies_bcs frontmatter. REVERSE mapping (BC → VPs) NOT backfilled. Story-writer/implementer working from BC body has no idea which VPs cover it.
[S-TBD] for Stories is expected (Phase 2 fills it).
**Routing:** vsdd-factory:product-owner (backfill VP IDs from VP-INDEX into each BC's "Verification Properties" table and "VP Anchors" section). **Confidence:** MEDIUM.

### F-PASS1-I11 — PRD §7 RTM Test Type column does not use canonical 9-suite names (MEDIUM)
**Location:** PRD §7 RTM (lines ~393–488).
Uses ambiguous labels like `integration/bats`, `unit/bats`, `perf/bats`. SS-18 enumerates exactly 9 named bats files. Implementer ambiguity.
**Routing:** vsdd-factory:product-owner (update RTM Test Type column with explicit suite-file names). **Confidence:** MEDIUM.

### F-PASS1-I12 — SS-04 §Test Surface "9 test suites" wording suggests subdivision contradicting SS-18 (MEDIUM)
**Location:** SS-04 line ~75.
"`bats/hooks.bats` — 9 test suites; ≥ 3 test cases per hook" reads as "hooks.bats contains 9 internal suites". SS-18 establishes 9 BATS FILES total (one is hooks.bats). Confusing.
**Routing:** vsdd-factory:architect (clarify SS-04 wording). **Confidence:** MEDIUM.

## SUGGESTION findings — F-PASS1-SN

### F-PASS1-S1 — VP-014 ≥25 entries assertion not committed to by BC-2.01.001 (LOW)
Either add count postcondition to BC-2.01.001 or remove ≥25 assertion from VP-014.

### F-PASS1-S2 — SS-04 uses pipe-escape-without-backslash in some markdown table cells; could break stricter renderers (LOW)

### F-PASS1-S3 — ADR-013 §References does not back-link to SS-13 (LOW)
Traceability completeness.

### F-PASS1-S4 — ARCH-INDEX "Pure-Core / Effectful-I/O Boundary" tables enumerate components without indexing by SS-NN (LOW)

### F-PASS1-S5 — Brief frontmatter `hook_count_v0_x: 13` is consistent across artifacts; positive note. (LOW)

## OBSERVATION findings — F-PASS1-ON

### F-PASS1-O1 — Architect's self-flagged class #3 (Purity classification accuracy) only minimally enforced; "Mixed" appears in 8+ SS designs. SS-01 + SS-04 + SS-05 + SS-12 + SS-16 draw boundary explicitly; SS-08 partial.

### F-PASS1-O2 — SS-18 Inbound says "8 other bats suite files" — implies 8 + 1 = 9 (consistent with NFR-019) but unusual wording.

### F-PASS1-O3 — Brief cross_platform: macOS + Linux + Git-Bash + WSL2 — no SS-NN explicitly owns cross-platform CI matrix; NFR-014 partial. Worth tracking for Phase 2.

### F-PASS1-O4 [process-gap] — No SS-NN-to-BC reverse traceability check in any spec audit; this allowed BC-2.04.017 path drift and BC-2.13.001 template-name drift to survive Phase 1c.
The consistency-validator runs forward checks (BC → architecture cited) but not reverse checks (architecture content → BC body grep). Recommend adding reverse traceability check to consistency-validator workflow.

## Disciplines observed (positive notes)

- Five-file gate runs clean: grep `\bL[0-9]+\b` on each of 5 canonical files returns only matches inside listed exclusion list (WSL2, level: L3, gate command lines themselves).
- No literal line-number-token quotations in prose: writing-technique principle held across PRD, BC, architecture artifacts.
- No AI attribution anywhere in tracked spec files.
- timestamp field present in all sampled architecture artifacts and BC files.
- 95/95 BCs have `subsystem: SS-NN`; 95/95 have `traces_to: ../BC-INDEX.md`.
- All 17 ADRs and 18 SS-NN designs carry `traces_to: ../ARCH-INDEX.md`.
- No blanket-coverage wording in newly-authored Phase 1b/1c artifacts.
- VP-INDEX P0 Coverage Matrix is verifiable; 64/64 holds independently.

## What I attacked
Dimensions exercised: cross-document count consistency; VP coverage paper-fix verification; structural-fix discipline survival; ADR-cross-ADR / ADR-BC / planning-doc consistency; hook helper completeness; purity classification; gen-test-corpus chain; frontmatter/metadata; edge case catalog; standing user directives; brief↔PRD↔BC↔arch↔planning chain; interface contract completeness; NFR measurability; five-file gate honesty; filename discipline; event-type naming consistency; bats suite roster vs SS-NN test-surface references.

## Five-file gate self-test
| File | Matches (after exclusions) |
|------|-------|
| `.factory/specs/product-brief.md` | 0 (clean) |
| `.factory/SESSION-HANDOFF.md` | 0 (clean) |
| `.factory/specs/prd/index.md` | 0 — all matches in exclusion-list scope |
| `.factory/specs/behavioral-contracts/BC-INDEX.md` | 0 — all matches in exclusion-list scope |
| `.factory/specs/architecture/ARCH-INDEX.md` | 0 — all matches in exclusion-list scope |

Gate: CLEAN on all five files. Note: the PRD index gate-COMMAND itself only iterates 4 files (F-PASS1-C6), but the LITERAL grep on the five-file set returns zero on each.

## P0 VP coverage independent verification

Independently counting P0 BCs from BC-INDEX (source-of-truth for BC priorities), and matching each to its VP via VP-INDEX `verifies_bcs` arrays + VP-INDEX P0 Coverage Matrix:

| Subsystem | P0 BCs | VPs covering them |
|---|---|---|
| SS-01 | BC-2.01.001..004 = 4 | VP-014 ✓ |
| SS-02 | BC-2.02.001..004, 006 = 5 | VP-015 ✓ |
| SS-03 | BC-2.03.001..004 = 4 | VP-016 + VP-012 ✓ |
| SS-04 | 14 P0 BCs | VP-001, VP-002, VP-003, VP-005, VP-011, VP-013, VP-017 ✓ |
| SS-05 | BC-2.05.001..006 = 6 | VP-004, VP-005, VP-018 ✓ |
| SS-06 | BC-2.06.001, 003 = 2 | VP-003 ✓ |
| SS-07 | 3 P0 (.001, .002, .004) | VP-010 (P1) — see note |
| SS-08 | BC-2.08.001, 002 = 2 | VP-019 ✓ |
| SS-09 | BC-2.09.001, 004, 005 = 3 | VP-020 ✓ |
| SS-10 | BC-2.10.001..003 = 3 | VP-021, VP-011 ✓ |
| SS-11 | 0 P0 | — |
| SS-12 | BC-2.12.001, 002, 004 = 3 | VP-007, VP-022 ✓ |
| SS-13 | BC-2.13.001 = 1 | VP-023 ✓ |
| SS-14 | BC-2.14.001, 003, 004, 005 = 4 | VP-024, VP-009 ✓ |
| SS-15 | 0 P0 | — |
| SS-16 | BC-2.16.001 = 1 | VP-025 ✓ |
| SS-17 | BC-2.17.001..004 = 4 | VP-008, VP-026 ✓ |
| SS-18 | BC-2.18.001..005 = 5 | VP-006 ✓ |

**Total P0 BCs: 64** matches VP-INDEX claim. **Coverage: 64/64** (matrix is honest).

Note on SS-07: VP-010 phase tag (P1) describes when VP runs (in cascade), not BC priority. Acceptable but creates phase-ordering risk for Phase 3.

## Recommended next action for the orchestrator

This pass is FAIL with 7 CRITICAL and 12 IMPORTANT findings. Streak remains 0/3.

**Dispatch routing:**
1. **vsdd-factory:product-owner** burst — close BC/PRD-body content defects: F-PASS1-C1, C2, C3, C6, I1, I7, I10, I11.
2. **vsdd-factory:architect** burst — close architecture-body content defects: F-PASS1-C4, C5, C7, I2, I3, I4, I5, I6, I8, I9, I12 (+ ADR-012 .yml/.yaml drift portion of C2).
3. **vsdd-factory:product-owner OR architect (joint)** for F-PASS1-I1 (decide whether `/brain:init` has flags).

**No new VPs needed** for closing findings; P0 coverage matrix holds.

**After fix-burst**, dispatch Pass 2 with fresh-context adversary. Production-grade default: all CRITICAL and IMPORTANT findings closed before Pass 2 — DO NOT proceed to Pass 2 with partial fixes.

**[process-gap]** F-PASS1-O4: orchestrator should record consistency-validator reverse-traceability gap in cycle-closing checklist for codification follow-up.

## Top 3 most concerning findings
1. F-PASS1-C1: BC-2.13.001 v0.1 template list disagrees with ADR-013 on 5 of 6 names — v0.1 ship gate currently unimplementable from spec.
2. F-PASS1-C2: ADR-012 and BC-2.16.006 specify incompatible `gen-test-corpus.sh` CLIs — Phase 3 deliverable cannot be built.
3. F-PASS1-C3: BC-2.04.017 and E-HOOK-002 cite `${CLAUDE_PLUGIN_ROOT}/scripts/hook-event-emit.sh` while all architecture artifacts say `hooks/lib/hook-event-emit.sh` — helper path-drift contradicts ADR-016.
