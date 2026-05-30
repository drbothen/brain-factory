---
artifact_type: story
story_id: STORY-039
epic_id: EPIC-08
title: "Scale validation gate: GH Actions throughput, memory budget, and per-ingest cost at 10K corpus"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 13
priority: P1
subsystems: [SS-16]
behavioral_contracts: [BC-2.16.003, BC-2.16.004, BC-2.16.005]
vps: []
dependencies: [STORY-036, STORY-038, STORY-034, STORY-035]
blocks: []
inputs:
  - architecture/subsystems/SS-16-scale-aware-architecture.md
  - behavioral-contracts/ss-16/BC-2.16.003.md
  - behavioral-contracts/ss-16/BC-2.16.004.md
  - behavioral-contracts/ss-16/BC-2.16.005.md
input-hash: ""
# BC status: BC-2.16.003 + BC-2.16.004 + BC-2.16.005 assigned; status=draft per S-7.01
# Priority: P1 — Phase 3 scale gate; not blocking Phase 1 exit.
#   13 points: this story integrates the corpus generator (STORY-038), token JSONL
#   (STORY-036), and GH Actions (STORY-035) to create the complete v0.9 scale harness.
#   The bats test harness is substantial; the scale-test.yml workflow adds memory
#   measurement; the per-cost assertion requires 10K-corpus setup. Together these touch
#   more surfaces than a typical 8-point story.
# Dependency rationale:
#   STORY-036: ingest-tokens.jsonl must exist for cost measurement (BC-2.16.005).
#   STORY-038: gen-test-corpus.sh must be available for pre-loading 10K corpus.
#   STORY-034: v0.1 GH Action templates (scale-test.yml) built in STORY-034.
#   STORY-035: api-retry.sh canonical version required for 100-source/day throughput
#     without rate-limit-induced data loss (BC-2.16.003 invariant 1).
# Subsystem anchor: SS-16 owns all three BCs per BC-INDEX and epics.md.
---

# STORY-039: Scale validation gate — GH Actions throughput, memory budget, and per-ingest cost at 10K corpus

## Goal

Deliver the v0.9 scale validation gate: a `scale-test.yml` GitHub Action workflow that
runs `gen-test-corpus.sh` to pre-load a 10K-source corpus, then ingests 10 additional
sources while measuring (1) sustained throughput across 100-source GH Action runs,
(2) peak resident memory via `/usr/bin/time -v`, and (3) per-ingest token cost staying
within 3x the 50K-token baseline. These are the three gating assertions that determine
whether brain-factory is ready for v0.9 ship.

## User Value

As a brain-factory maintainer, I want CI-enforced scale gates so that no PR can regress
throughput, memory budget, or token cost below the v0.9 SLA — ensuring users who operate
at 10K-source scale can trust the plugin to perform.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.16.003 | GH Actions process 100 sources/day sustained over 5-day test run without data loss | P1 |
| BC-2.16.004 | Peak resident memory for any single operation stays under 2GB | P1 |
| BC-2.16.005 | Per-ingest token cost stays within 3x the 50K-token baseline at 10K-source corpus | P1 |

## Acceptance Criteria

### GH Actions 100-source/day throughput (BC-2.16.003)

**AC-001** — `scale-test.yml` GH Action workflow (created in STORY-034) is enhanced to
accept a `sources-per-day` matrix input. When run with `sources-per-day: 100`, the
workflow runs `gen-test-corpus.sh --sources 500 --seed 42` (500 = 5 days × 100/day)
then processes sources in batches of 100 via the existing matrix strategy. After all
5 matrix batches complete, all 500 sources are in manifest.json (no data loss from
rate limiting).
(traces to BC-2.16.003 postcondition 1; postcondition 2; invariant 2)

**AC-002** — A bats simulation test (`tests/integration.bats`) runs `gen-test-corpus.sh
--sources 100 --seed 42` and injects 100 sources through the ingest pipeline
sequentially (not parallel — bats cannot do parallel), verifying all 100 appear in
manifest.json and no hard failures (exit 2) occur. This is the CI-executable proxy for
the GH Actions 5-day test (which requires GH Actions infrastructure).
(traces to BC-2.16.003 precondition 2; postcondition 1)

**AC-003** — When a source is attempted twice (duplicate URL in corpus), the
`validate-source-immutability.sh` hook blocks the second attempt (exit 2, E-SOURCE-001).
The source appears in manifest exactly once. The batch exits advisory (exit 1), not hard
failure (exit 2). The bats test simulates a duplicate by including one source twice in
the 100-source batch.
(traces to BC-2.16.003 edge case EC-003)

**AC-004** — `scale-test.yml` writes a scale-test summary to
`.brain/logs/scale-test-{YYYY-MM-DD}.jsonl` at the end of each day's batch. The file
contains: `sources_attempted`, `sources_succeeded`, `sources_skipped_immutable`,
`rate_limit_retries`, `hard_failures`, `duration_ms`.
(traces to BC-2.16.003 invariant 2; SS-16 Key Design "scale-test-YYYY-MM-DD.jsonl")

### Peak memory budget (BC-2.16.004)

**AC-005** — `scale-test.yml` includes a `/brain:lint-wiki` step that runs on the 10K-page
wiki produced by `gen-test-corpus.sh --sources 10000 --seed 42 --wiki-ratio 5`. The step
wraps `lint-wiki` with `/usr/bin/time -v` and captures peak RSS from its output.
The step fails (exit 2) if peak RSS exceeds 2GB.
(traces to BC-2.16.004 postcondition 1; postcondition 2)

**AC-006** — A bats test exercises the 1K-page proportional check: `gen-test-corpus.sh
--sources 200 --seed 42` (200 sources × 5 wiki pages = 1K wiki pages), then runs
`/brain:lint-wiki` under `/usr/bin/time -v`. The bats test asserts peak RSS <
200MB (proportional scaling check per BC-2.16.004 canonical test vector 2). This is
runnable in CI without a full 10K corpus.
(traces to BC-2.16.004 canonical test vector 2; edge case EC-001)

**AC-007** — The scale test workflow outputs peak RSS to `scale-test-{date}.jsonl` as
`peak_rss_kb` (integer, kilobytes as reported by `/usr/bin/time -v` "Maximum resident set size").
A bats fixture test parses a sample `scale-test.jsonl` line and asserts `peak_rss_kb`
is a non-negative integer.
(traces to BC-2.16.004 postcondition 2; SS-16 Key Design "scale-test JSONL")

**AC-008** — When `/usr/bin/time -v` is unavailable (macOS `/usr/bin/time` uses `-l` not
`-v`, and reports bytes not kilobytes), the workflow falls back to `gtime -v` (GNU time
via Homebrew). A CI check at workflow start verifies either `command -v gtime` or detects
Linux (`uname -s == Linux`) and uses `/usr/bin/time -v`; if running on macOS without
`gtime`, the memory measurement step is SKIPPED (not errored) with a warning.
macOS CI runners should use `brew install gnu-time` in the workflow setup step.

**Platform note for memory measurement:**
- **Linux (GitHub Actions ubuntu-latest):** `/usr/bin/time -v` reports "Maximum resident set size" in kilobytes
- **macOS:** `/usr/bin/time -l` (lowercase L) reports "maximum resident set size" in BYTES (despite some documentation claiming kilobytes)

Portable wrapper for bats tests (task 5):

```bash
measure_rss_kb() {
  local cmd="$1"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    /usr/bin/time -l $cmd 2>&1 | awk '/maximum resident set size/ {print int($1/1024)}'
  else
    /usr/bin/time -v $cmd 2>&1 | awk '/Maximum resident set size/ {print $6}'
  fi
}
```

For CI (GitHub Actions ubuntu-latest): `/usr/bin/time -v` works directly. The CI workflow
does not need the macOS path.
(traces to BC-2.16.004 invariant 2; production-grade default per CLAUDE.md §Canonical Principle)

### Per-ingest token cost at 10K corpus (BC-2.16.005)

**AC-009** — A bats scale test (`tests/integration.bats`, slow-lane with skip annotation
`skip "slow — requires 10K corpus; run with BRAIN_SCALE_TESTS=1"`) runs 10 ingests
against a pre-loaded 10K-corpus fixture (created by `gen-test-corpus.sh --sources 10000`),
reads `ingest-tokens.jsonl`, and asserts:
- Average `input_tokens + output_tokens` across the 10 ingests is ≤ 150K.
- No single ingest exceeds 500K tokens.
(traces to BC-2.16.005 postcondition 1; postcondition 2)

**AC-010** — When a single ingest in the 10-run sample exceeds 500K tokens, the bats
test fails with a specific message: `"Outlier ingest detected: source=<slug>
tokens=<N>. Investigate chunking path."`. The test does NOT pass when any ingest
exceeds the pathological outlier limit.
(traces to BC-2.16.005 edge case EC-001)

**AC-011** — A chunked-source bats test verifies that a multi-chunk source (one
with 10 chunks) has its total cost measured as the sum across all chunks:
`sum_of_chunk_tokens = ingest_token_records where source_path = "<slug>"`.
The average is computed across whole-source costs, not per-chunk records.
(traces to BC-2.16.005 edge case EC-003)

**AC-012** — The p95 token cost is included in the monthly-perf report
(`/brain:monthly-perf`, BC-2.09.006, STORY-031). A bats test asserts the monthly-perf
output JSON contains `p95_input_tokens` (integer). This verifies the STORY-031 integration
without re-running the full scale corpus.
(traces to BC-2.16.005 invariant 2)

## Tasks

1. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/integration.bats`:

   Throughput (BC-2.16.003):
   - `"scale: 100-source batch → all 100 in manifest (BC-2.16.003)"` — bats proxy
     for the 5-day GH Actions run.
   - `"scale: duplicate source in batch → skipped (immutability); batch exits 1 (BC-2.16.003 EC-003)"`.
   - `"scale-test.yml: summary JSONL written with required fields"`.

   Memory (BC-2.16.004):
   - `"scale: lint-wiki on 1K-page corpus < 200MB RSS (BC-2.16.004)"` (1K-page proxy).
   - `"scale: scale-test.jsonl peak_rss_kb is non-negative integer"`.

   Token cost (BC-2.16.005) — marked `skip "slow — requires 10K corpus; run with BRAIN_SCALE_TESTS=1"`:
   - `"scale: 10 ingests at 10K corpus avg ≤ 150K tokens (BC-2.16.005)"`.
   - `"scale: single ingest > 500K tokens → outlier message (BC-2.16.005 EC-001)"`.
   - `"scale: chunked source → total cost is sum of chunks (BC-2.16.005 EC-003)"`.

   Integration:
   - `"monthly-perf: output contains p95_input_tokens field (BC-2.16.005 invariant 2)"`.

   Run bats — confirm all 9 tests fail (Red Gate confirmed).

2. **[stub — scale-test.yml enhancement]** Enhance
   `plugins/brain-factory/templates/github-action-templates/scale-test.yml`
   (created in STORY-034) with:
   - `workflow_dispatch` input: `sources-per-day` (default: 100).
   - Step: `gen-test-corpus.sh --sources 500 --seed 42`.
   - Step: matrix ingest loop (100 per batch via existing matrix strategy).
   - Step: `/brain:lint-wiki` wrapped with `/usr/bin/time -v` (with `gtime` fallback).
   - Step: write `scale-test-{date}.jsonl` summary.
   Body: stub comments only — failing tests first.

3. **[impl — 100-source batch simulation]** Implement the bats 100-source throughput
   test: call `gen-test-corpus.sh --sources 100 --seed 42 /tmp/scale-test-brain`,
   then iterate over the 1 un-ingested source file (the Nth source from the generator)
   and 99 more synthetic sources via a loop. Assert manifest has 100 entries at end.

4. **[impl — duplicate detection in batch]** Add the duplicate-detection test: create
   a 50-source corpus, then attempt to ingest one already-ingested source again. Assert
   the hook fires (exit 1 from the batch) and the manifest count stays at 50 (no duplicate).

5. **[impl — memory bats test]** Implement the 1K-page RSS test:
   - Call `gen-test-corpus.sh --sources 200 --wiki-ratio 5 --seed 42 /tmp/mem-test`.
   - Use the portable `measure_rss_kb` wrapper defined in AC-008 to run
     `bash ${PLUGIN_ROOT}/skills/lint-wiki/run.sh` and capture peak RSS.
   - Parse the RSS value (already in KB from wrapper); assert < 200000 (KB) = 200MB.
   - On Linux: wrapper uses `/usr/bin/time -v` and extracts kilobytes directly.
   - On macOS: wrapper uses `/usr/bin/time -l`, reads bytes, divides by 1024 for KB.
   - If neither measurement method is available, call `skip "RSS measurement unavailable on this platform"`.

6. **[impl — scale-test.yml]** Fill in the complete `scale-test.yml` workflow with
   correct step implementation. API-calling steps source `api-retry.sh`.
   Memory measurement step uses `gtime` fallback pattern.

7. **[impl — token cost slow-lane]** Implement the 10K-corpus slow-lane bats tests with
   the `skip` annotation guarded by `BRAIN_SCALE_TESTS=1` env var.
   `if [[ -z "${BRAIN_SCALE_TESTS:-}" ]]; then skip "..."; fi`

8. **[green]** Run all 9 bats tests (fast-path only; slow-lane marked skip). All fast-path
   tests pass. Confirm `BRAIN_SCALE_TESTS=1 bats tests/integration.bats` runs the
   slow-lane tests (requires 10K corpus — expected to fail in CI without the corpus;
   document this in the test runner README).

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| 100-source batch ingest | All 100 in manifest; no hard failures | scale | BC-2.16.003 canonical test vector 1 |
| 100-source batch with 5 duplicates from prior run | 5 blocked by immutability; 95 new in manifest; batch exits 1 | edge-case | BC-2.16.003 canonical test vector 3 |
| `/brain:lint-wiki` on 1K-page wiki | Peak RSS < 200MB | scale | BC-2.16.004 canonical test vector 2 |
| 10 ingests at 10K corpus; avg tokens ≤ 150K | Test passes | scale | BC-2.16.005 canonical test vector 1 |
| 10 ingests; 1 ingest costs 520K tokens | Test fails; outlier identified | error | BC-2.16.005 canonical test vector 2 |
| 10-chunk source; per-source cost = sum of chunks | Average computed correctly | edge-case | BC-2.16.005 canonical test vector 3 |
| `scale-test.jsonl` line | `peak_rss_kb` is non-negative integer | happy-path | BC-2.16.004 invariant |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no P0 VP — P1 BCs) | 100-source batch without data loss | `tests/integration.bats` (proxy test) |
| (no P0 VP — P1 BCs) | Peak RSS < 2GB on 10K wiki | `scale-test.yml` (GH Actions) |
| (no P0 VP — P1 BCs) | Average token cost ≤ 150K at 10K corpus | `tests/integration.bats` (slow-lane) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-16-scale-aware-architecture.md`:

1. Peak RSS measurement uses `/usr/bin/time -v` (Linux) or `gtime -v` (macOS GNU time).
   The measurement isolates the process under test via PID — not total runner memory.
   `scale-test.yml` must run the measurement in a dedicated step, not as a side-effect
   of another step.
   **Platform portability:** `/usr/bin/time -v` is Linux-only. macOS `/usr/bin/time` uses
   `-l` (lowercase L) and reports bytes (not kilobytes). For the scale-test.yml CI workflow
   targeting GitHub Actions ubuntu-latest, `/usr/bin/time -v` works directly. For local
   macOS development, use `gtime -v` (Homebrew `gnu-time`). The bats memory test (task 5)
   must use the portable wrapper pattern described in AC-008.

2. The `scale-test-{YYYY-MM-DD}.jsonl` log is the source-of-truth for the memory
   measurement. The GitHub Actions run summary may duplicate the value for readability,
   but the JSONL is the canonical record (append-only; same pattern as ingest-tokens.jsonl).

3. The 100-sources/day throughput test validates the GH Actions matrix strategy from
   BC-2.16.003. The bats proxy test (sequential 100-source ingest) is NOT a substitute
   for the actual 5-day GH Actions run — it is a CI-executable proxy that tests the
   manifest-correctness invariant. The actual 5-day run is a Phase 3 manual validation gate.

4. The slow-lane token cost tests require the 10K corpus. The `BRAIN_SCALE_TESTS=1`
   env var guard is MANDATORY. Tests without this guard that require the 10K corpus
   will make the bats suite extremely slow for local development. The guard is the
   production-grade default — NOT a shortcut.

5. `scale-test.yml` depends on `api-retry.sh` (from STORY-035) for any steps that call
   external APIs. The workflow must source `scripts/lib/api-retry.sh` before any
   `curl` call in the workflow's shell steps.

**Forbidden dependencies:**
- No Grafana / Loki / Prometheus integration (v0.x is JSONL files only).
- No hardcoded token cost baselines — derive from `max_ingest_tokens_per_chunk` in
  policies.yaml (consistent with BC-2.16.002 design).
- Memory measurement must NOT use `ps aux` output — it must use `/usr/bin/time -v`
  "Maximum resident set size" which measures peak RSS, not instantaneous.
- `scale-test.yml` must NOT use `continue-on-error: true` to hide failures — hard
  failures (exit 2) from ingest must propagate to the Actions step result.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.7+ (latest: 1.8.1) | JSONL parsing for cost assertion |
| `yq` | 4.x+ (mikefarah/yq, Go-based — NOT kislyuk/yq Python-based) | Manifest schema checks |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |
| `/usr/bin/time -v` | any (Linux only) | RSS measurement (kilobytes); use `gtime -v` on macOS |
| `/usr/bin/time -l` | macOS built-in | RSS measurement on macOS (reports BYTES, not KB) |
| `gnu-time` (gtime) | Homebrew `brew install gnu-time` | macOS portable fallback for `/usr/bin/time -v` behaviour |
| `scripts/lib/api-retry.sh` | (this repo, STORY-035) | Rate-limit backoff for API-calling workflow steps |
| `scripts/gen-test-corpus.sh` | (this repo, STORY-038) | 10K corpus pre-loading |

### High-resolution timing portability

macOS `date` does NOT support `%N` (nanosecond format specifier). For timing measurements
in bats tests and workflow steps, use one of these portable alternatives:

- **`perl -MTime::HiRes -e 'printf("%.9f\n", Time::HiRes::time())'`** — works on both macOS and Linux; perl is pre-installed on both
- **`$EPOCHREALTIME`** bash variable — microsecond precision; bash 5.0+ only (not available with macOS system bash 3.2)
- **`date +%s%N`** — works on Linux (GitHub Actions) only; NOT portable to macOS

For CI (GitHub Actions ubuntu-latest): `date +%s%N` works directly. For the bats latency
proxy tests that run locally on macOS: use the `perl` method or `$EPOCHREALTIME` (requires
Homebrew bash 5.0+).

### yq Disambiguation

`yq` in this story refers to **mikefarah/yq** (Go-based, v4.x+). NOT kislyuk/yq (Python-based).

- On Ubuntu, `sudo apt install yq` may install the WRONG yq (kislyuk). Use `snap install yq`
  or download from GitHub releases: `https://github.com/mikefarah/yq/releases`
- Verify: `yq --version` should show `yq (https://github.com/mikefarah/yq/) version v4.x.x`
- Both `yq eval '.key' file.yaml` and `yq '.key' file.yaml` are valid (`eval` is the
  optional default command in v4.x)

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/templates/github-action-templates/scale-test.yml` | Modify | Add 100-source matrix, memory measurement, summary JSONL |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 9 scale gate bats tests (fast-path + slow-lane) |

Files NOT to modify: any `.factory/` artifact, any hook script, `plugin.json`,
`scripts/gen-test-corpus.sh` (STORY-038 scope), `scripts/write-token-record.sh` (STORY-036),
any prior story file.

## Previous Story Intelligence

STORY-036 (this epic) wires token JSONL instrumentation into ingest skills. This story
READS that output to assert per-ingest cost. Verify STORY-036 integration.bats tests
are green before starting token-cost assertions here.

STORY-038 (this epic) delivers `gen-test-corpus.sh`. This story uses it in both bats
proxy tests (100-source batch) and the slow-lane 10K test. Verify STORY-038 bats tests
are green before implementing the corpus setup in this story's tasks.

STORY-034 created the initial `scale-test.yml` stub as part of the v0.1 GH Action
template set. This story enhances it. Check STORY-034 for the current workflow structure
before adding steps.

STORY-037 (this epic) confirmed that `validate-source-immutability.sh` correctly blocks
duplicate sources. The duplicate detection assertion in AC-003 uses the hook that STORY-037
validated. These can be developed in parallel; the dependency is only on the STORY-036
JSONL write being present for cost assertions.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~6,200 |
| SS-16 subsystem design | ~700 |
| BC-2.16.003 file | ~900 |
| BC-2.16.004 file | ~700 |
| BC-2.16.005 file | ~700 |
| STORY-036 (token JSONL schema) | ~500 |
| STORY-038 (corpus generator context) | ~500 |
| STORY-034 (scale-test.yml current content) | ~800 |
| Existing integration.bats (prior tests) | ~1,500 |
| **Total** | **~12,500** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- The actual 5-day GH Actions test run — that is a Phase 3 manual validation gate, not
  a CI artifact. This story delivers the test infrastructure; the Phase 3 team runs
  the actual 5-day test.
- Grafana observability stack — explicitly forbidden per CLAUDE.md §Conventions.
- BC-2.16.001 (token write) and BC-2.16.002 (budget alert) — delivered in STORY-036
  and STORY-037 respectively.
- BC-2.16.006 (corpus generator) — delivered in STORY-038.
- Embedding (chunks array population) — v0.5+ scope per BC-2.06.002.

## Anchors

- BC-2.16.003: `behavioral-contracts/ss-16/BC-2.16.003.md`
- BC-2.16.004: `behavioral-contracts/ss-16/BC-2.16.004.md`
- BC-2.16.005: `behavioral-contracts/ss-16/BC-2.16.005.md`
- SS-16: `architecture/subsystems/SS-16-scale-aware-architecture.md`
- STORY-036: `stories/stories/STORY-036.md` (token JSONL — prerequisite)
- STORY-037: `stories/stories/STORY-037.md` (immutability bats — prerequisite for EC-003)
- STORY-038: `stories/stories/STORY-038.md` (corpus generator — prerequisite)
- STORY-034: `stories/stories/STORY-034.md` (scale-test.yml stub — predecessor)
- STORY-035: `stories/stories/STORY-035.md` (api-retry.sh canonical — prerequisite)
