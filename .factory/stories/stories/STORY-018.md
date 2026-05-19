---
artifact_type: story
story_id: STORY-018
epic_id: EPIC-03
title: "Sub-linear ingest latency gate: bats scale assertion at 1K and 10K pages"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-02]
behavioral_contracts: [BC-2.02.007]
vps: [VP-027]
dependencies: [STORY-017]
blocks: []
inputs:
  - architecture/subsystems/SS-02-url-ingest-pipeline.md
  - behavioral-contracts/ss-02/BC-2.02.007.md
  - architecture/verification-properties/VP-027-sub-linear-ingest-latency.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Single-BC story rationale: BC-2.02.007 (sub-linear ingest latency) is a P1 scale gate
# requiring the gen-test-corpus.sh infrastructure (BC-2.16.006, EPIC-08 scope). This
# story delivers the bats harness and the measurement protocol so it can run once the
# corpus generator exists, without blocking the rest of EPIC-03 on that P1 dependency.
# The bats test is marked slow-lane (EPIC-08 prerequisite) but the assertion logic and
# fixture scaffolding are written here.
---

# STORY-018: Sub-linear ingest latency gate — bats scale assertion at 1K and 10K pages

## Goal

Deliver the bats latency assertion harness that verifies `/brain:ingest-url` ingest
latency (excluding network fetch time) grows at most 20x when the wiki scales from 1K
to 10K pages. The story writes the bats tests, documents the measurement protocol, and
wires the VP-027 slow-lane test into `tests/integration.bats` with a `skip` annotation
that activates once `scripts/gen-test-corpus.sh` (EPIC-08, BC-2.16.006) exists. The
harness can be unblocked by creating a lightweight synthetic 1K-page brain fixture for
the lower bound without requiring the full 10K corpus generator.

## User Value

As a brain architect, I want a CI-enforced assertion that ingest latency does not
degrade super-linearly as the wiki grows — so that operators who build 10K-page brains
are not surprised by progressively slower ingest cycles.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.02.007 | `/brain:ingest-url` latency stays sub-linear as wiki grows 1K→10K pages | P1 |

## Acceptance Criteria

### Sub-linear Latency Assertion (BC-2.02.007)

**AC-001** — `tests/integration.bats` contains a `@test "ingest latency sub-linear: T(10K)/T(1K) ≤ 20"` test case. The test:
1. Pre-populates a temp brain with N-1 sources (1K and 10K respectively via two runs) using
   `scripts/gen-test-corpus.sh --sources N --seed 42 /tmp/test-brain` or a lightweight
   fixture for the 1K lower bound.
2. Measures wall-clock time of `plugins/brain-factory/skills/ingest-url` invocation
   excluding network fetch time (source content is a fixture file, no real network call).
3. Asserts T(10K) / T(1K) ≤ 20.
(traces to BC-2.02.007 postconditions 1–3)

**AC-002** — The latency measurement excludes network fetch time. The test uses a local
fixture file as the source content to eliminate network variability. Only the wiki-layer
operations are measured: manifest read, duplicate check, wiki page writes, index updates.
(traces to BC-2.02.007 invariants 1–2)

**AC-003** — The 1K-page lower bound test uses a lightweight synthetic fixture (NOT the
full gen-test-corpus.sh) and can run in the standard bats suite without the EPIC-08
corpus generator. The 10K-page upper bound test has a bats `skip` annotation:
`skip "requires gen-test-corpus.sh (EPIC-08 BC-2.16.006) to generate 10K-source corpus"`.
The skip annotation cites the specific story that removes it (the story implementing
BC-2.16.006).
(traces to BC-2.02.007 precondition 2)

**AC-004** — The test uses `SECONDS` bash builtin or `date +%s%N` for timing. Network
fetch is bypassed by substituting the Defuddle call with a `cat` of the fixture file for
measurement purposes (test-mode flag or environment variable `BRAIN_TEST_SKIP_FETCH=1`).
(traces to BC-2.02.007 invariant 1 — network excluded from measurement)

**AC-005** — The test asserts that `T(1K) < 30` seconds (absolute upper bound at the
lower corpus size), matching the BC test vector. This assertion runs without the 10K
corpus and is NOT skipped.
(traces to BC-2.02.007 canonical test vector: "T(1K) < 30 seconds (excluding fetch)")

**AC-006** — When T(10K) data is available (gen-test-corpus.sh present), the ratio
assertion T(10K) / T(1K) ≤ 20 fails visibly in bats output if violated. The test does
NOT swallow a ratio > 20 and silently pass — it fails with a descriptive message:
"Ingest latency ratio T(10K)/T(1K) = <actual>. Expected ≤ 20."
(traces to BC-2.02.007 postcondition 3 — v0.9 scale gate asserts via automated measurement)

## Tasks

1. **[prerequisite check]** Verify STORY-017 has landed (wiki page generation pipeline
   complete). This story's latency measurement covers wiki-layer operations which depend
   on STORY-017's `generate-wiki` step existing.

2. **[failing test — Red Gate]** Add `@test "ingest latency at 1K pages: T(1K) < 30 seconds"`
   to `tests/integration.bats` in failing state:
   - Create a 1K-source lightweight fixture directory in `tests/fixtures/scale-1k/` (1K
     pre-populated manifest entries; no actual source files needed — manifest entries
     suffice for duplicate-check and index-read operations).
   - Set `BRAIN_TEST_SKIP_FETCH=1` to bypass Defuddle call.
   - Measure wall-clock time of ingest operation.
   - Assert wall-clock < 30 seconds.
   Run bats — confirm test fails (STORY-017 not yet integrated with timing harness).

3. **[failing test — Red Gate]** Add `@test "ingest latency sub-linear: T(10K)/T(1K) ≤ 20"` to
   `tests/integration.bats` in failing state with `skip` annotation for gen-test-corpus.sh
   dependency. The ratio assertion logic is written (not stubbed) — it is just skipped at
   runtime until EPIC-08 provides the corpus generator.
   Run bats — confirm the non-skipped T(1K) test fails, the T(10K) test is skipped cleanly.

4. **[impl]** Add `BRAIN_TEST_SKIP_FETCH=1` environment variable support to
   `skills/ingest-url/SKILL.md`: when set, the fetch step is bypassed and the skill reads
   source content from `BRAIN_TEST_FIXTURE_PATH` instead of calling `defuddle-fetch.mjs`.
   This test-mode hook enables timing-clean latency measurement without network calls.
   The flag is ONLY respected in tests and must never affect production behavior.

5. **[impl]** Create `tests/fixtures/scale-1k/manifest.json`: a synthetic `.brain/manifest.json`
   pre-populated with 1000 source entries (generated via a small node/bash generator
   script, not hand-authored). Each entry has the canonical schema fields.

6. **[green]** Run `bats tests/integration.bats --filter "ingest latency at 1K pages"` —
   test passes (T(1K) < 30 seconds against the 1K fixture).

7. **[green]** Run `bats tests/integration.bats --filter "ingest latency sub-linear"` —
   test is skipped cleanly (not failed) with the gen-test-corpus.sh citation.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Ingest with 1K-entry manifest (fixture); BRAIN_TEST_SKIP_FETCH=1 | Wall-clock < 30 seconds | happy-path | BC-2.02.007 canonical test vector |
| Ingest with 10K-entry manifest (gen-test-corpus.sh); ratio T(10K)/T(1K) | Ratio ≤ 20 | edge-case (scale) | BC-2.02.007 postcondition 3 |
| T(10K)/T(1K) ratio = 25 (failure scenario) | bats test fails with descriptive ratio message | error | BC-2.02.007 postcondition 3 |
| bats run without gen-test-corpus.sh | T(1K) test passes; T(10K) test skipped cleanly | happy-path | AC-003 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-027 | T(1K) < 30 seconds (1K-fixture, no network) | `tests/integration.bats` (always-runs assertion) |
| VP-027 | T(10K)/T(1K) ≤ 20 | `tests/integration.bats` (skipped until EPIC-08; unblocked by BC-2.16.006) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-02-url-ingest-pipeline.md`:

1. Network fetch time is EXCLUDED from the latency measurement. Only wiki-layer
   operations are timed: manifest read, duplicate check, wiki page writes, index updates.
   (BC-2.02.007 invariant 1)
2. `BRAIN_TEST_SKIP_FETCH=1` is a TEST-MODE ONLY flag. It must be absent from all
   production code paths. The skill MUST NOT check this flag in production execution.
3. The `skip` annotation for the 10K test must cite the specific BC and story that
   removes it: `skip "requires scripts/gen-test-corpus.sh — EPIC-08 BC-2.16.006"`. A
   bare `skip` or a skip citing only "EPIC-08" without the BC ID is insufficient.
4. The 1K synthetic manifest fixture must use the canonical manifest schema (same as
   BC-2.02.004 precondition 2 schema: `sources` array with `source_id`, `url`, `topic`,
   `ingested_at`, `last_ingest`, `chunks`, `embeddings_model`). Fixture entries with
   wrong schema will cause the manifest-read path to behave differently than production.

**Forbidden dependencies:**
- The latency harness must NOT import Node.js timing libraries. Use `SECONDS` builtin or
  `date +%s` / `date +%s%N` (bash).
- The 1K synthetic fixture must NOT be generated by `gen-test-corpus.sh` — that creates
  a circular dependency. Use a standalone `tests/fixtures/gen-scale-fixture.sh` script.
- No network calls in the latency test. `BRAIN_TEST_SKIP_FETCH=1` must be set in all
  scale test fixtures.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ | CLAUDE.md §Conventions |
| `date` | GNU/POSIX | Nanosecond-resolution timing (`date +%s%N`) |
| `SECONDS` | bash builtin | Alternative for second-resolution timing |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `jq` | 1.6+ | Fixture manifest generation / validation |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (`-i 2`) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/tests/integration.bats` | Extend | Two latency tests: T(1K) always-runs; T(10K) skipped until EPIC-08 |
| `plugins/brain-factory/tests/fixtures/scale-1k/manifest.json` | Create | 1K-entry synthetic manifest (canonical schema) |
| `plugins/brain-factory/tests/fixtures/gen-scale-fixture.sh` | Create | Script to regenerate the synthetic manifest |
| `plugins/brain-factory/skills/ingest-url/SKILL.md` | Extend | Add BRAIN_TEST_SKIP_FETCH=1 test-mode bypass |

Files NOT to modify: `scripts/defuddle-fetch.mjs`, `hooks/lib/manifest-write.sh`,
`scripts/gen-test-corpus.sh` (does not exist yet — EPIC-08 scope), any `.factory/` file.

## Previous Story Intelligence

STORY-017 completed the wiki page generation step. The latency test exercises that step
(wiki page writes contribute to the measured T(N) time). Ensure the wiki generation
path in `SKILL.md` is instrumented to run cleanly with a mocked source content file
(via `BRAIN_TEST_FIXTURE_PATH`) before the timing harness will produce stable results.

The 50K-token check added in STORY-017 must also run in < 30 seconds on the 1K fixture.
Since it uses `wc -w` on the fixture source content, it should be near-instant.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-02 subsystem design | ~1,500 |
| BC-2.02.007 file | ~800 |
| VP-027 file | ~600 |
| integration.bats existing content | ~3,000 |
| scale-1k/manifest.json (1K entries) | ~4,000 |
| **Total** | **~12,900** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `scripts/gen-test-corpus.sh` implementation — EPIC-08 (BC-2.16.006).
- Full 10K corpus test execution — blocked until EPIC-08; skip annotation cites it.
- Token budget alerting (`/brain:health` warns at 2x baseline) — EPIC-08 (BC-2.16.002).
- Any changes to the production fetch path — test-mode bypass only.

## Anchors

- BC-2.02.007: `behavioral-contracts/ss-02/BC-2.02.007.md`
- VP-027: `architecture/verification-properties/VP-027-sub-linear-ingest-latency.md`
- SS-02: `architecture/subsystems/SS-02-url-ingest-pipeline.md`
