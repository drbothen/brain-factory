---
artifact_type: story
story_id: STORY-020
epic_id: EPIC-04
title: "/brain:lint-wiki seven-check health pass with O(n) index-first wikilink resolution"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-05]
behavioral_contracts: [BC-2.05.001, BC-2.05.002, BC-2.05.005, BC-2.05.006]
vps: [VP-018, VP-004, VP-005]
dependencies: [STORY-001, STORY-009, STORY-014]
blocks: [STORY-021, STORY-022]
inputs:
  - architecture/subsystems/SS-05-wiki-layer.md
  - behavioral-contracts/ss-05/BC-2.05.001.md
  - behavioral-contracts/ss-05/BC-2.05.002.md
  - behavioral-contracts/ss-05/BC-2.05.005.md
  - behavioral-contracts/ss-05/BC-2.05.006.md
  - architecture/verification-properties/VP-018-wiki-layer.md
  - architecture/verification-properties/VP-004-wikilink-resolution-correctness.md
  - architecture/verification-properties/VP-005-frontmatter-schema-conformance.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.05.001 (seven-check lint), BC-2.05.002 (O(n) index-first),
# BC-2.05.005 (six wiki types), and BC-2.05.006 (embedding_status mandatory) are
# inseparable at implementation time. The seven-check pass includes checks 4 and 5
# (invalid page-type and missing embedding_status), so BC-2.05.005 and BC-2.05.006
# are covered by the same skill body and the same bats tests. BC-2.05.002 defines the
# algorithmic constraint on the wikilink check that BC-2.05.001 runs; splitting them
# would produce a story whose AC is "implement the same function with a specific
# algorithm." One coherent deliverable: a fully functional /brain:lint-wiki skill.
---

# STORY-020: `/brain:lint-wiki` seven-check health pass with O(n) index-first wikilink resolution

## Goal

Deliver the `/brain:lint-wiki` skill: a seven-check wiki health pass that runs in under
10 minutes on a 10K-page wiki using an index-first O(n) algorithm for wikilink
resolution. The skill enforces the six-type wiki page structure, audits
`embedding_status` field presence in all frontmatter, and emits a structured JSON report.
This story owns the bulk-audit surface of the wiki layer; the per-write hook surface
(validate-wikilink-integrity.sh, validate-page-type-policy.sh,
validate-frontmatter-schema.sh) is already delivered in EPIC-02 (STORY-009, STORY-012).

## User Value

As a brain operator, I want to run `/brain:lint-wiki` and get a structured pass/fail
report across all seven health dimensions — so that I can confidently detect wiki
inconsistencies (broken links, orphans, wrong types, missing fields) in bulk, without
running ingest and without hitting the per-write hook enforcement.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.05.001 | `/brain:lint-wiki` completes seven-check health pass under 10 minutes on 10K-page wiki | P0 |
| BC-2.05.002 | `/brain:lint-wiki` uses index-first lookup (O(n), not O(n²)) | P0 |
| BC-2.05.005 | Wiki pages use `wiki/{type}/{slug}.md` (6 valid types: concepts/people/frameworks/syntheses/observations/questions) | P0 |
| BC-2.05.006 | `embedding_status` field mandatory in all wiki page frontmatter from v0.1 | P0 |

## Acceptance Criteria

### Seven-Check Lint Suite (BC-2.05.001)

**AC-001** — `/brain:lint-wiki` runs all seven checks on every invocation (no selective
skipping). The seven checks are: (1) broken wikilinks, (2) orphaned pages, (3) missing
`embedding_status` field, (4) invalid page type directories, (5) non-kebab-case
filenames, (6) missing source ID citations, (7) index/log coherence.
(traces to BC-2.05.001 invariant 1)

**AC-002** — On completion, the skill emits a structured JSON report to stdout:
`{"checks": [{"name": "<check>", "status": "PASS|FAIL", "issues": [...]}],
"overall": "PASS|FAIL", "pages_scanned": N, "duration_seconds": N}`.
The `checks` array always contains exactly 7 items in canonical order.
(traces to BC-2.05.001 postcondition 1)

**AC-003** — Exit 0 when `overall` is `PASS`; exit 1 when any check fails
(`overall` is `FAIL`). The skill NEVER exits 2 — exit 2 is reserved for hook-layer
blocks; the bulk-audit skill uses exit 0/1.
(traces to BC-2.05.001 postcondition 2)

**AC-004** — On a 10K-page wiki (synthetic corpus from STORY-018's
`scripts/gen-test-corpus.sh`), `duration_seconds` ≤ 600 (ten minutes wall-clock on a
GitHub Actions runner). This SLA covers all seven checks together.
(traces to BC-2.05.001 postcondition 3; invariant 3)

**AC-005** — On an empty wiki (0 pages), all seven checks pass vacuously.
`pages_scanned: 0`. `overall: "PASS"`. Exit 0.
(traces to BC-2.05.001 edge case EC-001)

**AC-006** — When `wiki/index.md` is missing, checks 1, 3, and 4 FAIL; the report
lists each check's failure with the message "wiki/index.md not found." The remaining
checks continue. `overall: "FAIL"`. Exit 1. No crash.
(traces to BC-2.05.001 edge case EC-002)

**AC-007** — When exactly one broken wikilink exists in the wiki, check 1 FAILs. The
`issues` array for check 1 contains exactly one entry identifying the broken link and
the source page. Exit 1.
(traces to BC-2.05.001 edge case EC-003)

### Index-First O(n) Wikilink Resolution (BC-2.05.002)

**AC-008** — Wikilink resolution uses index-first algorithm: `wiki/index.md` is loaded
into memory ONCE per lint run as an in-memory set, then each wikilink in each page is
checked via set membership (O(1) lookup). The index is NOT rebuilt per page.
(traces to BC-2.05.002 postconditions 1–2; invariant 1)

**AC-009** — When `wiki/index.md` is missing, the wikilink check falls back to a
filesystem scan of `wiki/` as an error-recovery path. This fallback is acceptable; the
index-first algorithm is the default.
(traces to BC-2.05.002 invariant 2)

**AC-010** — Bats performance assertion: on a 10K-page wiki with average 20 wikilinks
per page (200K total lookups), the wikilink resolution step alone completes in under
90 seconds (budget = 90s of the 600s total SLA). Verified by injecting a 10K-page
synthetic index and timing `wikilink-resolve.sh` with `time`.
(traces to BC-2.05.002 edge case EC-001; BC-2.05.001 invariant 3)

### Six-Type Wiki Page Taxonomy (BC-2.05.005)

**AC-011** — Check 4 (invalid page type directories) flags any page not under one of
the 6 canonical wiki types: `concepts`, `people`, `frameworks`, `syntheses`,
`observations`, `questions`. A page at `wiki/tools/hammer.md` produces a FAIL on
check 4 with issue: `"wiki/tools/hammer.md: unknown page type directory 'tools'"`.
(traces to BC-2.05.005 postconditions 1–2; invariant 1)

**AC-012** — `wiki/index.md` and `wiki/log.md` are exempt from the type check.
They are infrastructure files, not wiki pages. Check 4 never flags them.
(traces to BC-2.05.005 invariant 2)

**AC-013** — Check 5 (non-kebab-case filenames) flags any wiki page filename
that is not lowercase kebab-case (no spaces, no uppercase, no underscores).
Example: `wiki/concepts/AI_Agents.md` produces a FAIL on check 5.
(traces to BC-2.05.005 postconditions 1–2)

### `embedding_status` Mandatory Field (BC-2.05.006)

**AC-014** — Check 3 (missing `embedding_status`) FAILs when any wiki page frontmatter
is missing the `embedding_status` field. The issue entry contains the file path.
(traces to BC-2.05.006 postcondition 1; invariant 1)

**AC-015** — Check 3 accepts `embedding_status: pending`, `embedding_status: computed`,
and `embedding_status: stale` as valid values (case-sensitive, lowercase).
`embedding_status: PENDING` (wrong case) is flagged as invalid. The check reports both
absence and invalid value as issues.
(traces to BC-2.05.006 invariants 1–2; edge case EC-002)

**AC-016** — `skills/lint-wiki/SKILL.md` is shellcheck-clean. The pure-core
wikilink-resolve library at `hooks/lib/wikilink-resolve.sh` is shellcheck-clean and
`shfmt -d -i 2` produces no diff.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Create stub `skills/lint-wiki/SKILL.md` in `plugins/brain-factory/skills/`
   with correct frontmatter (`name`, `description`, `argument-hint`, `allowed-tools`) and
   canonical 6-section structure. Create stub `hooks/lib/wikilink-resolve.sh` that exits 1.

2. **[failing test — Red Gate]** Add failing bats tests in `tests/skills.bats`:
   - Seven-check report structure: `checks` array has exactly 7 items; `overall` present.
   - Empty wiki: all checks PASS; `pages_scanned: 0`; exit 0.
   - Single broken wikilink: check 1 FAIL; issue entry identifies the link.
   - Missing `wiki/index.md`: checks 1, 3, 4 FAIL; no crash; exit 1.
   - Invalid page type directory (`wiki/tools/`): check 4 FAIL.
   - Missing `embedding_status`: check 3 FAIL; file path in issues.
   - `embedding_status: PENDING` (wrong case): check 3 FAIL.
   - `wiki/index.md` is exempt from type check.
   Add scale test in `tests/integration.bats`:
   - 10K-page synthetic corpus: all checks pass; `duration_seconds` ≤ 600.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `hooks/lib/wikilink-resolve.sh`: pure bash library. Loads
   `wiki/index.md` into a bash associative array (or sorted file for `grep -qF`).
   Exports function `wikilink_in_index <slug>` → exit 0 (present) or exit 1 (absent).
   Shellcheck-clean; `shfmt -d -i 2` clean.

4. **[impl]** Implement `skills/lint-wiki/SKILL.md` skill body:
   - Build the 7 check functions in order (check 1: broken wikilinks via
     `wikilink-resolve.sh`; checks 2–7 as described in SS-05 key design).
   - Load `wiki/index.md` ONCE at startup; pass the in-memory set to all checks
     that need it (index-first).
   - Aggregate per-check `{"name", "status", "issues": []}` into the final JSON report
     using `jq -n`.
   - Emit `lint.wiki.completed` structured event via `hook-event-emit.sh`.
   - Exit 0 on PASS; exit 1 on any FAIL.

5. **[green]** Run `bats tests/skills.bats` — all new lint-wiki tests pass.

6. **[scale-green]** Run `bats tests/integration.bats` scale test with synthetic corpus
   — duration ≤ 600s. If scale test is deferred to STORY-018's infrastructure, mark as
   "blocked on STORY-018" and create a placeholder integration test that passes with a
   mock timing assertion.

7. **[green]** Run `shellcheck hooks/lib/wikilink-resolve.sh` and
   `shfmt -d -i 2 hooks/lib/wikilink-resolve.sh` — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| 100-page wiki, all healthy | All 7 checks PASS; exit 0 | happy-path | BC-2.05.001 |
| Empty wiki (0 pages) | All 7 PASS; `pages_scanned: 0`; exit 0 | happy-path | BC-2.05.001 EC-001 |
| Wiki with 3 orphan pages | Check 2 FAIL; 3 issues; exit 1 | error | BC-2.05.001 |
| Missing `wiki/index.md` | Checks 1, 3, 4 FAIL; no crash; exit 1 | error | BC-2.05.001 EC-002 |
| Page at `wiki/tools/hammer.md` | Check 4 FAIL; issue names "tools" as invalid type | error | BC-2.05.005 |
| Page with missing `embedding_status` | Check 3 FAIL; file path in issues | error | BC-2.05.006 |
| Page with `embedding_status: PENDING` | Check 3 FAIL; wrong case flagged | error | BC-2.05.006 EC-002 |
| `wiki/index.md` exempt from type check | Check 4 PASS for index.md | edge-case | BC-2.05.005 invariant 2 |
| 10K-page synthetic corpus (healthy) | All checks PASS; duration ≤ 600s | scale | BC-2.05.001 postcondition 3 |
| 10K pages, 200K wikilinks, index-first | Wikilink step < 90s | scale | BC-2.05.002 EC-001 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-018 | All 7 checks run and report | `tests/skills.bats` |
| VP-018 | Wiki page schema enforced (types + embedding_status) | `tests/skills.bats` |
| VP-018 | 10K-page SLA (≤ 600s) | `tests/integration.bats` |
| VP-004 | Index loaded once; O(n*L) wikilink resolution | `tests/skills.bats` (timing) |
| VP-005 | `embedding_status` absent → FAIL; wrong case → FAIL | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-05-wiki-layer.md` and ADR-008:

1. Wikilink resolution is a **pure core function**: `hooks/lib/wikilink-resolve.sh`
   accepts the wiki-index contents and a wikilink string; returns present/absent. It is
   bats-testable in isolation with fixture inputs.
2. The in-memory index MUST be built once per lint run, not per page. Any implementation
   that calls `grep` against the filesystem for each page's wikilinks is a violation of
   BC-2.05.002 and will be flagged P0 in adversarial review.
3. The six canonical wiki types are: `concepts`, `people`, `frameworks`, `syntheses`,
   `observations`, `questions`. These are immutable in v0.x. New types require a BC
   update before implementation.
4. `wiki/index.md` and `wiki/log.md` are infrastructure files — excluded from all
   page-type and kebab-case filename checks.
5. The structured JSON report uses `jq -n` to build output. Do NOT use echo-based JSON
   construction; shell quoting errors in JSON output are a P1 adversarial finding.
6. Structured events emitted: `lint.wiki.started`, `lint.wiki.completed` — must be
   pre-registered in `scripts/event-catalog.json` (STORY-014 deliverable).
7. Exit semantics: 0 = all checks pass; 1 = at least one check fails. Exit 2 is
   reserved for hook-layer blocks and MUST NOT be used by skills.

**Forbidden dependencies:**
- `hooks/lib/wikilink-resolve.sh`: no HTTP calls; no manifest.json reads; bash + grep only.
- `skills/lint-wiki/SKILL.md` skill body: must NOT call the per-write hooks directly
  (validate-wikilink-integrity.sh, etc.) — the lint skill re-implements the same checks
  in bulk-audit mode.
- `skills/lint-wiki/SKILL.md`: must NOT scan `sources/` directory for wiki page content.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.6+ | JSON report construction |
| `yq` | 4.x+ | Frontmatter parsing (embedding_status field) |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (`-i 2`) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/lint-wiki/SKILL.md` | Create | Seven-check lint skill with canonical 6-section structure |
| `plugins/brain-factory/hooks/lib/wikilink-resolve.sh` | Create | Pure bash library: index-first wikilink resolution |
| `plugins/brain-factory/tests/skills.bats` | Extend | Seven-check suite: positive + negative + edge cases |
| `plugins/brain-factory/tests/integration.bats` | Extend | 10K-page scale test (duration_seconds ≤ 600) |
| `plugins/brain-factory/tests/fixtures/wiki-healthy-100.json` | Create | 100-page healthy wiki fixture |
| `plugins/brain-factory/tests/fixtures/wiki-broken-link.json` | Create | Single broken wikilink fixture |
| `plugins/brain-factory/tests/fixtures/wiki-invalid-type.json` | Create | Page in non-canonical type directory |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json.template`,
any prior STORY-NNN.md, existing hook scripts in `plugins/brain-factory/hooks/`.

## Previous Story Intelligence

STORY-009 delivered `validate-wikilink-integrity.sh`, `validate-page-type-policy.sh`,
and `validate-frontmatter-schema.sh` — the per-write hook equivalents of what
`/brain:lint-wiki` audits in bulk. Confirm those hooks are present before implementing
the skill; the skill's check logic should mirror the hook's validation rules exactly
(same error messages, same field names). Drift between hook and bulk-audit semantics
is a P1 adversarial finding.

STORY-014 delivered `hooks/lib/hook-event-emit.sh` and `scripts/event-catalog.json`.
The skill must source `hook-event-emit.sh` and emit registered events. Verify that
`lint.wiki.started` and `lint.wiki.completed` are pre-registered in the catalog before
adding emit calls; if they are missing, add them in the same commit (event catalog is
a living document).

STORY-001 created `skills/lint-wiki/` with a stub `SKILL.md`. This story replaces that
stub with the full implementation.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,500 |
| SS-05 subsystem design | ~1,200 |
| BC-2.05.001, BC-2.05.002, BC-2.05.005, BC-2.05.006 files | ~3,600 |
| VP-018, VP-004, VP-005 files | ~1,500 |
| skills.bats + integration.bats existing content | ~2,500 |
| event-catalog.json (STORY-014 deliverable) | ~2,000 |
| STORY-009 hook scripts (reference for semantic alignment) | ~2,000 |
| **Total** | **~16,300** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:rename-page` atomic backlink propagation — STORY-021.
- Per-write hook enforcement (validate-wikilink-integrity.sh, validate-page-type-policy.sh,
  validate-frontmatter-schema.sh) — already delivered in STORY-009.
- Wiki page GENERATION (ingest-url produces wiki pages) — STORY-017.
- Scale test corpus generator (`scripts/gen-test-corpus.sh`) — STORY-018 (EPIC-08).
- 10K-page performance benchmarking infrastructure — STORY-018.

## Anchors

- BC-2.05.001: `behavioral-contracts/ss-05/BC-2.05.001.md`
- BC-2.05.002: `behavioral-contracts/ss-05/BC-2.05.002.md`
- BC-2.05.005: `behavioral-contracts/ss-05/BC-2.05.005.md`
- BC-2.05.006: `behavioral-contracts/ss-05/BC-2.05.006.md`
- VP-018: `architecture/verification-properties/VP-018-wiki-layer.md`
- VP-004: `architecture/verification-properties/VP-004-wikilink-resolution-correctness.md`
- VP-005: `architecture/verification-properties/VP-005-frontmatter-schema-conformance.md`
- SS-05: `architecture/subsystems/SS-05-wiki-layer.md`
