---
document_type: vp-index
level: L3
version: "0.1.8"
status: draft
producer: "vsdd-factory:architect"
timestamp: 2026-05-18T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
created: 2026-05-15
last_updated: 2026-05-25
---

# Verification Property Index: brain-factory

> Canonical enumeration of all 27 verification properties. Each VP traces to one or
> more BCs. VP files carry `traces_to: ../VP-INDEX.md` in frontmatter.
>
> Verification mechanism for brain-factory v0.x: bats (not Kani/proptest — this
> is bash, not Rust). Property-based testing uses parameterized bats re-runs.
> Formal proofs are not applicable to bash; the analog is: same stdin fixture
> re-run N times → same stdout verdict (determinism assertion).

| VP-ID | Title | Mechanism | Target BCs | Phase | Status |
|-------|-------|-----------|------------|-------|--------|
| VP-001 | Hook exit-code semantics coverage | bats (per-hook .bats files) | BC-2.04.016, BC-2.04.015 | P0 | proposed |
| VP-002 | PostToolUse hook trigger on wiki writes | bats (integration.bats) | BC-2.04.003..BC-2.04.007, BC-2.04.009, BC-2.04.010 | P0 | proposed |
| VP-003 | Source immutability enforcement | bats (validate-source-immutability.bats) | BC-2.04.002, BC-2.06.001 | P0 | proposed |
| VP-004 | Wikilink resolution correctness | bats (skills.bats + validate-wikilink-integrity.bats) | BC-2.04.003, BC-2.05.002 | P0 | proposed |
| VP-005 | Frontmatter schema conformance | bats (validate-frontmatter-schema.bats) | BC-2.04.004, BC-2.04.005, BC-2.05.006 | P0 | proposed |
| VP-006 | Meta-lint factory self-audit | meta-lint.bats | BC-2.18.001..BC-2.18.005 | P0 | proposed |
| VP-007 | Lobster workflow determinism | bats (integration.bats) | BC-2.12.001, BC-2.12.002 | P0 | proposed |
| VP-008 | Hook event catalog completeness | meta-lint.bats cross-ref | BC-2.17.001, BC-2.17.002 | P0 | proposed |
| VP-009 | Plugin manifest schema correctness | bats (upgrade.bats) | BC-2.14.004, BC-2.14.005 | P0 | proposed |
| VP-010 | Adversarial 3-CLEAN convergence | adversary cascade protocol | BC-2.07.001..BC-2.07.004 | P1 | proposed |
| VP-011 | Quarantine on every WebFetch | bats (quarantine.bats) | BC-2.10.002, BC-2.04.001 | P0 | proposed |
| VP-012 | Manifest write atomicity and last_ingest field correctness | bats (integration.bats) | NFR-018, BC-2.03.002, BC-2.06.003 | P0 | proposed |
| VP-013 | Hook p99 latency under 100ms | bats perf assertion (per-hook .bats files) | BC-2.04.015, NFR-001 | P0 | proposed |
| VP-014 | Brain initialization scaffolds complete folder structure | bats (integration.bats) | BC-2.01.001, BC-2.01.002, BC-2.01.003, BC-2.01.004 | P0 | proposed |
| VP-015 | URL ingest pipeline: Defuddle fetch to manifest delta to wiki pages | bats (integration.bats) | BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004, BC-2.02.006 | P0 | proposed |
| VP-016 | Source ingest pipeline: local file ingest and out-of-vault path rejection | bats (skills.bats + integration.bats) | BC-2.03.001, BC-2.03.003, BC-2.03.004 | P0 | proposed |
| VP-017 | Hook enforcement: kebab-case filename gate and AI attribution block | bats (enforce-kebab-case.bats + block-ai-attribution.bats) | BC-2.04.011, BC-2.04.012, BC-2.04.017 | P0 | proposed |
| VP-018 | Wiki layer: page schema, embedding state machine, and partial-failure fan-out | bats (skills.bats + integration.bats) | BC-2.05.001, BC-2.05.003, BC-2.05.004, BC-2.05.005 | P0 | proposed |
| VP-019 | Content brief pipeline: ONE THING / PROOF / TRANSFORMATION structure enforcement | bats (skills.bats) | BC-2.08.001, BC-2.08.002 | P0 | proposed |
| VP-020 | Publishing pipeline: state machine enforcement and LinkedIn API call shape | bats (validate-publish-state.bats + skills.bats + LinkedIn DTU) | BC-2.09.001, BC-2.09.004, BC-2.09.005 | P0 | proposed |
| VP-021 | Quarantine check skill activation and corpus location resolution | bats (quarantine.bats) | BC-2.10.001, BC-2.10.003 | P0 | proposed |
| VP-022 | Lobster headless execution: no interactive prompts in non-TTY context | bats (integration.bats) | BC-2.12.004 | P0 | proposed |
| VP-023 | GitHub Action templates: v0.1 core set YAML validity and trigger configuration | bats (meta-lint.bats) | BC-2.13.001 | P0 | proposed |
| VP-024 | Plugin lifecycle: install from marketplace and upgrade migration execution | bats (upgrade.bats) | BC-2.14.001, BC-2.14.003 | P0 | proposed |
| VP-025 | Scale-aware token instrumentation: JSONL record written on every ingest invocation | bats (integration.bats) | BC-2.16.001 | P0 | proposed |
| VP-026 | Event catalog: JSON schema validity and emit-site completeness | bats (meta-lint.bats + per-hook .bats files) | BC-2.17.003, BC-2.17.004 | P0 | proposed |
| VP-027 | Sub-linear ingest latency as wiki grows from 1K to 10K pages | bats (integration.bats — slow lane) | BC-2.02.007 | P1 | proposed |

**Totals:** 27 VPs total. P0: 25. P1: 2. Mechanism breakdown: bats: 26; adversary cascade protocol: 1.

---

## P0 Coverage Matrix

All 64 P0 BCs across all 18 subsystems have at least one VP. Coverage is exact: 64 of 64
P0 BCs covered. The table below enumerates coverage by subsystem for auditability.
BC-2.06.003 coverage was corrected in v0.1.2 (F-PASS2-C3): VP-012 frontmatter claimed
it but the body and index table did not reflect it; VP-012 extended with Group 2 tests.

| Subsystem | P0 BCs | Covered by | VP(s) |
|-----------|--------|-----------|-------|
| SS-01 Brain Init | BC-2.01.001, BC-2.01.002, BC-2.01.003, BC-2.01.004 | VP-014 | init scaffold |
| SS-02 URL Ingest | BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004, BC-2.02.006 | VP-015 | ingest pipeline |
| SS-02 URL Ingest (scale) | BC-2.02.007 | VP-027 | sub-linear latency (P1) |
| SS-03 Source Ingest | BC-2.03.001, BC-2.03.003, BC-2.03.004 | VP-016 | source ingest |
| SS-03 Source Ingest | BC-2.03.002 | VP-012 | manifest atomicity |
| SS-04 Hook Chain | BC-2.04.001 | VP-011 | quarantine on WebFetch |
| SS-04 Hook Chain | BC-2.04.002 | VP-003 | source immutability |
| SS-04 Hook Chain | BC-2.04.003..BC-2.04.007, BC-2.04.009, BC-2.04.010 | VP-002 | PostToolUse trigger |
| SS-04 Hook Chain | BC-2.04.004, BC-2.04.005 | VP-005 | frontmatter schema |
| SS-04 Hook Chain | BC-2.04.011, BC-2.04.012, BC-2.04.017 | VP-017 | naming + attribution |
| SS-04 Hook Chain | BC-2.04.015, BC-2.04.016 | VP-001, VP-013 | exit codes, latency |
| SS-05 Wiki Layer | BC-2.05.001, BC-2.05.003, BC-2.05.004, BC-2.05.005 | VP-018 | wiki integrity |
| SS-05 Wiki Layer | BC-2.05.002 | VP-004 | wikilink resolution |
| SS-05 Wiki Layer | BC-2.05.006 | VP-005 | frontmatter schema |
| SS-06 Source Immutability | BC-2.06.001 | VP-003 | source immutability |
| SS-06 Source Immutability | BC-2.06.003 | VP-012 | last_ingest field correctness |
| SS-07 Adversarial Review | BC-2.07.001..BC-2.07.004 | VP-010 | 3-CLEAN convergence (P1) |
| SS-08 Content Brief | BC-2.08.001, BC-2.08.002 | VP-019 | brief pipeline |
| SS-09 Publishing | BC-2.09.001, BC-2.09.004, BC-2.09.005 | VP-020 | publish state machine |
| SS-10 Quarantine | BC-2.10.001, BC-2.10.003 | VP-021 | quarantine skill |
| SS-10 Quarantine | BC-2.10.002 | VP-011 | quarantine on WebFetch |
| SS-12 Lobster | BC-2.12.001, BC-2.12.002 | VP-007 | lobster determinism |
| SS-12 Lobster | BC-2.12.004 | VP-022 | headless execution |
| SS-13 GH Actions | BC-2.13.001 | VP-023 | template YAML validity |
| SS-14 Plugin Lifecycle | BC-2.14.001, BC-2.14.003 | VP-024 | lifecycle |
| SS-14 Plugin Lifecycle | BC-2.14.004, BC-2.14.005 | VP-009 | manifest schema |
| SS-16 Scale | BC-2.16.001 | VP-025 | token instrumentation |
| SS-17 Event Catalog | BC-2.17.001, BC-2.17.002 | VP-008 | catalog completeness |
| SS-17 Event Catalog | BC-2.17.003, BC-2.17.004 | VP-026 | schema + emit-site |
| SS-18 Meta-Lint | BC-2.18.001..BC-2.18.005 | VP-006 | meta-lint self-audit |

**Coverage summary:** 64 of 64 P0 BCs covered. No deferrals. (BC-2.06.003 covered by VP-012 Group 2 — see VP-012 v1.1 changelog.)

---

## Self-Audit Checklist

- [x] All VP IDs are sequential (VP-001 through VP-027)
- [x] Every VP has a viable verification mechanism for bash/bats stack
- [x] All P0 BCs across all 18 subsystems have at least one VP (64 of 64 — see P0 Coverage Matrix above)
- [x] VP-INDEX total (27) matches the count of VP files in this directory
- [x] VP-013 verifies_bcs field updated: now [BC-2.04.015, NFR-001] — BC-2.02.007 moved to VP-027
- [x] VP-027 Phase P1 (slow lane — requires gen-test-corpus.sh infrastructure); VP-022 (lobster headless) Phase P0
- [x] VP-012 extended to cover BC-2.06.003 (last_ingest field); SS-06 row in P0 Coverage Matrix updated; Coverage summary accurate 64/64 (F-PASS2-C3)
- [x] **last_updated freshness check:** Before commit, verify `last_updated` frontmatter date >= MAX(date in any Changelog entry). If a new Changelog entry dated YYYY-MM-DD is added, `last_updated` MUST be >= YYYY-MM-DD. (Added F-PASS6-O1-arch — mirrors ARCH-INDEX freshness discipline established in F-PASS5.) Incremental scope: check VP-INDEX on every burst. Canonical-baseline scope: one-time audit at Pass 6 codification time — VP-INDEX confirmed clean at that point. (Dual-scope declaration added F-PASS11-C2.)

## Changelog

### v0.1.8 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** VP-INDEX version bumped to reflect VP file version bumps across this burst. 8 VP files updated: VP-002 v1.0→v1.1, VP-003 v1.1→v1.2, VP-004 v1.2→v1.3, VP-005 v1.1→v1.2, VP-009 v1.0→v1.1, VP-011 v1.0→v1.1, VP-021 v1.2→v1.3, VP-026 v1.3→v1.4. Changes: `hooks.json.template` → `hooks.json` (filename rename), stdin field names updated (`"tool"` → `"tool_name"`, `"input":{...}` → `"tool_input":{...}`, `"output":{}` removed from PostToolUse/PreToolUse fixtures), verdict assertions updated (`"verdict":"allow"` → `"continue":true`, `"verdict":"block"` → `"decision":"block"` + `"continue":false`), exit 1 semantics clarified (debug log only; advisory = exit 0 + systemMessage). VP-INDEX table and coverage matrix unchanged (no new VPs, no VP retirements). [audit-trail]

### v0.1.7 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE — VP table Mechanism column updated to per-hook .bats convention):** 8 VP rows updated: VP-001 (`hooks.bats` → `per-hook .bats files`), VP-003 (`hooks.bats` → `validate-source-immutability.bats`), VP-004 (`unit + integration` → `skills.bats + validate-wikilink-integrity.bats`), VP-005 (`hooks.bats` → `validate-frontmatter-schema.bats`), VP-013 (`perf assertion (hooks.bats)` → `perf assertion (per-hook .bats files)`), VP-017 (`hooks.bats` → `enforce-kebab-case.bats + block-ai-attribution.bats`), VP-020 (`hooks.bats + skills.bats + LinkedIn DTU` → `validate-publish-state.bats + skills.bats + LinkedIn DTU`), VP-026 (`meta-lint.bats + hooks.bats` → `meta-lint.bats + per-hook .bats files`). Cascades from SS-18 v1.5 per-hook .bats reversal (F-PHASE2-STEP-B-CLOSEOUT-O1). [audit-trail]

### v0.1.6 (2026-05-16)

**STRUCTURAL FIX (F-PASS11-C2 — retroactive dual-scope declaration for last_updated freshness check):** The `last_updated freshness check` Self-Audit item (added F-PASS6-O1-arch) lacked explicit dual-scope declarations as required by the F-PASS10-O1 dual-scope discipline. Incremental scope and canonical-baseline scope declarations added. Canonical-baseline confirmed clean at Pass 6 codification. [audit-trail]

**STRUCTURAL FIX (F-PASS11-C1/I3 — timestamp canonical-baseline sweep reflected):** VP-INDEX documents that the Pass 11 architect burst swept all 27 VP files for timestamp correctness. Files bumped to 2026-05-16T00:00:00: VP-004, VP-012, VP-014, VP-021, VP-026, VP-027. Files retaining 2026-05-15T00:00:00 (no content edit after initial backfill): VP-001..VP-003, VP-005..VP-011, VP-013, VP-015..VP-020, VP-022..VP-025. [audit-trail]

### v0.1.5 (2026-05-16)

**STRUCTURAL FIX (F-PASS10-C1/I1 — canonical-baseline VP title sweep):** Title cells updated to match canonical VP file H1 for all drifted VPs. VP-014: "Brain init scaffold completeness" corrected to "Brain initialization scaffolds complete folder structure". VP-015: "URL ingest pipeline: Defuddle to manifest to wiki pages" corrected to "URL ingest pipeline: Defuddle fetch to manifest delta to wiki pages". VP-016: "Source ingest: local file ingest and vault path rejection" corrected to "Source ingest pipeline: local file ingest and out-of-vault path rejection". VP-017: "Hook enforcement: kebab-case gate and AI attribution block" corrected to "Hook enforcement: kebab-case filename gate and AI attribution block". VP-018: "Wiki layer: page schema, embedding state machine, partial-failure fan-out" corrected to "Wiki layer: page schema, embedding state machine, and partial-failure fan-out". VP-019: "Content brief pipeline: ONE THING / PROOF / TRANSFORMATION enforcement" corrected to "Content brief pipeline: ONE THING / PROOF / TRANSFORMATION structure enforcement". VP-021: "Quarantine skill activation and corpus location resolution" corrected to "Quarantine check skill activation and corpus location resolution". VP-023: "GitHub Action templates: v0.1 core set YAML validity and trigger config" corrected to "GitHub Action templates: v0.1 core set YAML validity and trigger configuration". VP-024: "Plugin lifecycle: install completeness and upgrade migration idempotency" corrected to "Plugin lifecycle: install from marketplace and upgrade migration execution". VP-025: "Scale token instrumentation: JSONL record on every ingest invocation" corrected to "Scale-aware token instrumentation: JSONL record written on every ingest invocation". VPs already aligned (no change): VP-001..VP-013, VP-020, VP-022, VP-026, VP-027. VP file H1 is canonical per Source-of-Truth Precedence rule 4. [audit-trail]

### v0.1.4 (2026-05-16)

**STRUCTURAL FIX (F-PASS6-O1-arch — last_updated freshness check added to Self-Audit):** VP-INDEX Self-Audit Checklist now includes the `last_updated freshness check` item: before commit, verify `last_updated` >= MAX(date in any Changelog entry). Mirrors the same discipline established in ARCH-INDEX Self-Audit during F-PASS5. Prevents silent last_updated drift across future fix-bursts.

### v0.1.3 (2026-05-16)

**STRUCTURAL FIX (F-PASS5-I1 — VP-007 mechanism label drift):** VP-007 row Mechanism column corrected from `bats (unit)` to `bats (integration.bats)`. The VP-007 body (source of truth per Source-of-Truth Precedence: VP file supersedes VP-INDEX) specifies `bats (integration.bats)` at its Verification Mechanism heading. VP-INDEX label was stale from initial draft; now aligned to VP file body.

**STRUCTURAL FIX (F-PASS5-I3 — last_updated stale):** VP-INDEX frontmatter `last_updated` bumped from `2026-05-15` to `2026-05-16` to reflect today's fix-burst edits. Freshness check: last_updated >= MAX(date in any Changelog entry) = 2026-05-16. Satisfied.

### v0.1.2 (2026-05-16)

**STRUCTURAL FIX (F-PASS2-C3 — VP-INDEX 64/64 paper-fix resolution):** VP-012 row
updated: title extended to "Manifest write atomicity and last_ingest field correctness";
Target BCs column now includes BC-2.06.003. P0 Coverage Matrix SS-06 row extended with
`| SS-06 Source Immutability | BC-2.06.003 | VP-012 | last_ingest field correctness |`.
Coverage summary corrected from a stale claim to accurate 64/64 attribution noting the
v0.1.2 correction. VP-012 file itself extended with Group 2 bats harness asserting
last_ingest field presence, ISO 8601 format, and v0.x write-once equality with
ingested_at. False attestation from F-1c-CV-01 fix-burst resolved.

### v0.1.1 (2026-05-15)

**STRUCTURAL FIX (F-1c-CV-01):** Added VP-014 through VP-027 (14 new VPs) covering all
P0 BCs in subsystems SS-01, SS-02 (including BC-2.02.007 in new VP-027), SS-03, SS-04
(kebab-case / attribution / event emission), SS-05, SS-08, SS-09, SS-10, SS-12, SS-13,
SS-14, SS-16, SS-17. P0 coverage is now 64 of 64 BCs across all 18 subsystems.

**STRUCTURAL FIX (F-1c-CV-05):** VP-013 verifies_bcs corrected from
`[BC-2.04.015, BC-2.02.007]` to `[BC-2.04.015, NFR-001]`. BC-2.02.007 (sub-linear
ingest latency) now has its own dedicated VP-027 — the property is ingest-layer scale,
not hook-level latency. VP-INDEX Self-Audit Checklist updated with accurate P0 coverage
matrix across all 18 subsystems.

### v0.1.0 (2026-05-15)

Initial VP-INDEX creation with VP-001 through VP-013. P0 coverage was partial (hook
chain, wiki layer, source immutability only).
