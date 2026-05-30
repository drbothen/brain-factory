---
artifact_type: story
story_id: STORY-037
epic_id: EPIC-08
title: "Token budget alert in /brain:health, source immutability invariant, and manifest chunks schema"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P1
subsystems: [SS-16, SS-06]
behavioral_contracts: [BC-2.16.002, BC-2.06.001, BC-2.06.002]
vps: [VP-003]
dependencies: [STORY-036, STORY-001]
blocks: []
inputs:
  - architecture/subsystems/SS-16-scale-aware-architecture.md
  - behavioral-contracts/ss-16/BC-2.16.002.md
  - behavioral-contracts/ss-06/BC-2.06.001.md
  - behavioral-contracts/ss-06/BC-2.06.002.md
  - architecture/verification-properties/VP-003-source-immutability.md
input-hash: ""
# BC status: BC-2.16.002 + BC-2.06.001 + BC-2.06.002 assigned; status=draft per S-7.01
# Priority: P1 — budget alert and schema constraints; not blocking Phase 1 exit gate.
# Dependency rationale:
#   STORY-036 writes ingest-tokens.jsonl — budget alert (BC-2.16.002) reads it; must exist.
#   STORY-001 (/brain:init + /brain:health scaffold) creates the base health skill;
#   this story adds the Sources YELLOW/RED dimension to it.
#   BC-2.06.001 has no new implementation code (hook already exists from EPIC-02); this
#   story delivers the bats scale-invariant test and confirms VP-003 coverage.
#   BC-2.06.002 (chunks schema) is a manifest init change that depends on STORY-001 init.
# Subsystem anchors:
#   SS-16 owns BC-2.16.002 (token budget alert).
#   SS-06 owns BC-2.06.001 (source immutability behavioral invariant) and
#   BC-2.06.002 (manifest chunks schema). Grouped here per epics.md rationale:
#   BC-2.06.001 is validated by the same hash machinery as the scale corpus; grouping
#   avoids splitting the immutability story across EPIC-01/EPIC-03/EPIC-08.
# VP anchor: VP-003 is anchored here for BC-2.06.001 scale invariant test.
---

# STORY-037: Token budget alert in `/brain:health`, source immutability invariant, and manifest chunks schema

## Goal

Deliver three related capabilities within the scale-aware architecture layer: (1) add the
token budget dimension to `/brain:health` — YELLOW alert at 2x baseline (>100K tokens
30-day average), RED at 3x (>150K); (2) validate the source immutability behavioral
invariant with a dedicated scale bats test in `tests/validate-source-immutability.bats`; (3) ensure every
new manifest entry written by the ingest skills contains `"chunks": []` and
`"embeddings_model": null` from v0.1 onward (schema forward-compatibility).

## User Value

As a brain-factory operator, I want `/brain:health` to warn me before my token spend
grows out of control, and I want the brain's immutability guarantees to hold under
production load — so I can operate the brain confidently at 10K-source scale without
cost surprises or data corruption.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.16.002 | Token budget alert: `/brain:health` warns if 30-day trailing average exceeds 2x baseline | P1 |
| BC-2.06.001 | `sources/{topic}/{slug}.md` is immutable after creation (no overwrite without explicit rename flow) | P0 |
| BC-2.06.002 | `manifest.json` schema supports `chunks` array from v0.1 (populated at v0.5+) | P1 |

## Acceptance Criteria

### Token budget alert in `/brain:health` (BC-2.16.002)

**AC-001** — When the 30-day trailing average token cost computed from
`.brain/logs/ingest-tokens.jsonl` is ≤ 100K tokens, `/brain:health` returns Sources
dimension GREEN with no alert.
(traces to BC-2.16.002 postcondition 1)

**AC-002** — When the 30-day trailing average is between 100K and 150K tokens (exclusive),
`/brain:health` returns Sources dimension YELLOW with the exact message:
`"30-day trailing average: <N> tokens/ingest (baseline: 50K). 2x baseline exceeded."`.
(traces to BC-2.16.002 postcondition 2, postcondition 4)

**AC-003** — When the 30-day trailing average exceeds 150K tokens, `/brain:health`
returns Sources dimension RED with the exact message:
`"30-day trailing average: <N> tokens/ingest (baseline: 50K). 3x baseline exceeded."`.
(traces to BC-2.16.002 postcondition 3, postcondition 4)

**AC-004** — When the JSONL log contains fewer than 30 days of records, `/brain:health`
uses the available records and notes `"Based on <N>-day history."` in the alert message.
(traces to BC-2.16.002 edge case EC-001)

**AC-005** — When the JSONL log is empty (new brain, no ingests yet), `/brain:health`
returns Sources dimension GREEN with `"No ingest history yet."` — no alert, no error.
(traces to BC-2.16.002 edge case EC-002)

**AC-006** — The 30-day window is rolling: computed as the most recent 30 calendar days
from current date, not a fixed calendar month. The baseline is the `max_ingest_tokens_per_chunk`
value from `.brain/policies.yaml` (default 50K if the policy key is absent).
(traces to BC-2.16.002 invariant 1, invariant 2)

### Source immutability behavioral invariant (BC-2.06.001)

**AC-007** — `tests/validate-source-immutability.bats` contains the VP-003 test cases: a
PostToolUse Write to an existing source path (in manifest.json fixture) produces
`validate-source-immutability.sh` exit 2 and error code `E-SOURCE-001`. A Write to a new
source path produces exit 0 and `"verdict":"allow"`.
(traces to BC-2.06.001 postcondition 1; VP-003 verification mechanism)

**AC-008** — `tests/validate-source-immutability.bats` contains a determinism assertion:
running the same `validate-source-immutability.sh` payload twice in succession produces
byte-identical stdout (modulo `ts` and `trace` fields). This confirms the hook is a pure
function of its manifest.json state.
(traces to BC-2.06.001 invariant 1; VP-003 determinism property)

**AC-009** — A Bash-tool write to an existing source path (simulating `echo >> sources/ai/foo.md`)
triggers the PostToolUse hook at exit 2. The write already occurred (PostToolUse cannot
prevent writes); the hook's advisory causes the session to flag the mutation. A bats test
in `tests/validate-source-immutability.bats` documents this limitation with a comment:
"PostToolUse detects but cannot prevent — this is an inherent limitation per BC-2.06.001
EC-001."
(traces to BC-2.06.001 edge case EC-001; CLAUDE.md §Canonical Principle — document known limitations)

### Manifest chunks schema forward-compatibility (BC-2.06.002)

**AC-010** — Every manifest entry produced by a fresh `/brain:ingest-url` or
`/brain:ingest-source` invocation after this story contains:
`"chunks": []` (empty array, not null, not absent) and `"embeddings_model": null`.
The bats test reads a fresh manifest entry from a post-ingest fixture and asserts both
fields with `jq -e`.
(traces to BC-2.06.002 postcondition 1; postcondition 2)

**AC-011** — The `chunks` field is always an array. If an operator manually deletes the
field from a manifest entry, the next ingest skill that reads that entry treats a missing
`chunks` as an empty array (graceful fallback via `jq '(.chunks // []).'` pattern), not
as an error. A bats test verifies this graceful fallback.
(traces to BC-2.06.002 invariant 1; edge case EC-001)

**AC-012** — `embeddings_model` is `null` in every manifest entry written by v0.x ingest
skills. No skill sets it to a non-null value in v0.x. A bats assertion on fresh entries
confirms `jq -e '.embeddings_model == null'` passes.
(traces to BC-2.16.002 invariant 2; BC-2.06.002 postcondition 1)

## Tasks

1. **[impl — health alert helper]** Create `plugins/brain-factory/scripts/compute-token-average.sh`:
   - Accepts `--days N` and reads `${BRAIN_ROOT}/.brain/logs/ingest-tokens.jsonl`.
   - Outputs JSON: `{"average_tokens": N, "sample_days": N, "sample_count": N}`.
   - Uses `jq` to filter by `ts` within rolling window; computes average of
     `input_tokens + output_tokens` across records in window.
   - Returns empty result JSON with `sample_count: 0` if log is absent or empty.
   - `set -euo pipefail`; shellcheck clean; shfmt -d -i 2 passes.

2. **[failing tests — Red Gate]** Add failing `@test` blocks:

   In `tests/integration.bats` (budget alert):
   - `"health: Sources GREEN when avg ≤ 100K (BC-2.16.002)"` — fixture JSONL with avg 80K.
   - `"health: Sources YELLOW when avg 100K-150K with 2x message (BC-2.16.002)"` — avg 120K.
   - `"health: Sources RED when avg >150K with 3x message (BC-2.16.002)"` — avg 200K.
   - `"health: partial history note when <30 days of records (BC-2.16.002 EC-001)"`.
   - `"health: no alert when log is empty — Sources GREEN (BC-2.16.002 EC-002)"`.
   - `"compute-token-average.sh: shellcheck clean"`.
   - `"compute-token-average.sh: shfmt -d -i 2 clean"`.

   In `tests/validate-source-immutability.bats` (VP-003 — add to the per-hook suite created by STORY-007):
   - `"validate-source-immutability.sh: existing source path → E-SOURCE-001"` (VP-003).
   - `"validate-source-immutability.sh: new source path → allow"` (VP-003).
   - `"validate-source-immutability.sh: path not in sources/ → allow (no-op)"` (VP-003).
   - `"validate-source-immutability.sh: determinism — same payload twice → same stdout"`.
   - `"validate-source-immutability.sh: bash echo to existing source → exit 2 advisory"`.

   In `tests/integration.bats` (manifest schema):
   - `"manifest: chunks field is empty array in fresh ingest entry (BC-2.06.002)"`.
   - `"manifest: embeddings_model is null in fresh ingest entry (BC-2.06.002)"`.
   - `"manifest: missing chunks field treated as empty array (BC-2.06.002 EC-001)"`.

   Run bats — confirm all 15 tests fail (Red Gate confirmed).

3. **[impl — budget alert in health]** In `plugins/brain-factory/skills/brain-health/run.sh`:
   - Source `compute-token-average.sh`; call it with `--days 30`.
   - Read `average_tokens` from JSON output; compare against baseline (50K, or
     `policies.yaml` `max_ingest_tokens_per_chunk`).
   - Set Sources dimension: GREEN / YELLOW (2x) / RED (3x) with the canonical message
     format from BC-2.16.002 postcondition 4.
   - For partial history: append `" Based on <N>-day history."` to the message.
   - For empty log: return GREEN with `"No ingest history yet."`.

4. **[impl — manifest schema]** In manifest-write helper
   (`scripts/lib/manifest-write.sh`, created in STORY-016 or STORY-015 scope):
   - Ensure every new entry template includes `"chunks": []` and
     `"embeddings_model": null`.
   - Add graceful fallback: when reading an existing entry, treat absent `chunks`
     as `[]` via `jq '(.chunks // []).'`.

5. **[green]** Run all 15 bats tests — all pass. Confirm VP-003 bats cases pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| JSONL fixture: 30 days at avg 80K | Sources GREEN; no alert | happy-path | BC-2.16.002 postcondition 1 |
| JSONL fixture: 30 days at avg 120K | Sources YELLOW; `"2x baseline exceeded."` | edge-case | BC-2.16.002 postcondition 2 |
| JSONL fixture: 30 days at avg 200K | Sources RED; `"3x baseline exceeded."` | edge-case | BC-2.16.002 postcondition 3 |
| JSONL fixture: 5 days of records | Alert message includes `"Based on 5-day history."` | edge-case | BC-2.16.002 EC-001 |
| Empty JSONL | Sources GREEN; `"No ingest history yet."` | edge-case | BC-2.16.002 EC-002 |
| Write to `sources/ai/existing.md` (manifest fixture) | `validate-source-immutability.sh` exit 2; `E-SOURCE-001` | error | BC-2.06.001 / VP-003 |
| Write to `sources/ai/new.md` (not in manifest) | Exit 0; `"verdict":"allow"` | happy-path | BC-2.06.001 / VP-003 |
| Same immutability payload run twice | Byte-identical stdout (modulo ts/trace) | happy-path | VP-003 determinism |
| Fresh ingest; read manifest entry | `"chunks": []` and `"embeddings_model": null` present | happy-path | BC-2.06.002 |
| Manifest entry with `chunks` key deleted | Graceful fallback: reads as `[]` | edge-case | BC-2.06.002 EC-001 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-003 | Source immutability: existing path → exit 2 + E-SOURCE-001 | `tests/validate-source-immutability.bats` |
| VP-003 | Source immutability: new path → exit 0 + allow | `tests/validate-source-immutability.bats` |
| VP-003 | Determinism property | `tests/validate-source-immutability.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-16-scale-aware-architecture.md`:

1. The budget alert baseline is `50K tokens` (configurable via `max_ingest_tokens_per_chunk`
   in policies.yaml). The thresholds are: 2x = 100K (YELLOW), 3x = 150K (RED). These
   numbers must NOT be hardcoded — they must be derived from the baseline value so that
   operators who change `max_ingest_tokens_per_chunk` get automatically recalibrated alerts.

2. The 30-day window is rolling (last 30 calendar days from today), not a fixed calendar
   month. `compute-token-average.sh` must compute this correctly using `date` arithmetic,
   not a month boundary.

3. `compute-token-average.sh` is a pure-ish helper: given the same JSONL file and the
   same current date, it produces the same output. Implementer must NOT bake in `date`
   calls that vary with the clock during test runs — use a `BRAIN_CURRENT_DATE` env var
   override for test reproducibility.

From `architecture/verification-properties/VP-003-source-immutability.md`:

4. `validate-source-immutability.sh` already exists (EPIC-02). This story does NOT
   reimplement it. The AC-007 / AC-008 / AC-009 tests are bats coverage additions only —
   they exercise the existing hook with fixture payloads.

5. BC-2.06.001 is enforced at hook level (EPIC-02). This story's contribution is the VP-003
   bats test suite that verifies the behavioral invariant holds.

**Forbidden dependencies:**
- `compute-token-average.sh` must NOT use `eval`.
- No Grafana / Loki / Prometheus integration.
- Budget alert thresholds must NOT be hardcoded — derive from `max_ingest_tokens_per_chunk`.
- `validate-source-immutability.sh` must NOT be modified by this story — it is EPIC-02 scope.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions |
| `jq` | 1.7+ (latest: 1.8.1) | JSONL aggregation + manifest schema checks |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | Reading `max_ingest_tokens_per_chunk` from policies.yaml. **Ubuntu note:** `apt install yq` installs the WRONG tool (kislyuk/yq, Python-based). Use `snap install yq`. |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |
| `date` (GNU or BSD) | any | Rolling 30-day window calculation |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/scripts/compute-token-average.sh` | Create | Token average aggregation helper |
| `plugins/brain-factory/skills/brain-health/run.sh` | Modify | Add Sources dimension YELLOW/RED alert |
| `plugins/brain-factory/scripts/lib/manifest-write.sh` | Modify | Add `chunks: []` and `embeddings_model: null` to every new entry template |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 7 budget-alert + manifest schema bats tests |
| `plugins/brain-factory/tests/validate-source-immutability.bats` | Extend | Add 5 VP-003 source-immutability bats tests to the per-hook suite (STORY-007 created it) |
| `plugins/brain-factory/tests/fixtures/manifest-with-existing-source.json` | Create | Fixture manifest with a pre-existing source entry for VP-003 tests |

Files NOT to modify: any `.factory/` artifact, `hooks/validate-source-immutability.sh`
(EPIC-02 scope), any prior story file.

## Previous Story Intelligence

STORY-036 (this epic) delivers `scripts/write-token-record.sh` and wires token writes
into the ingest skills. This story READS that output via `compute-token-average.sh`.
Implementer must run STORY-036 tests green before starting this story's budget-alert tasks.

STORY-001 (`/brain:init` and `/brain:health`) created the base health skill. The Sources
dimension alerting from this story layers onto the six-dimensional health report structure
from STORY-001. Check STORY-001 for the exact health report JSON shape before modifying
`health/run.sh`.

STORY-016 (or the manifest-write helper in STORY-015) created `scripts/lib/manifest-write.sh`.
Read that file before modifying it to add the `chunks` and `embeddings_model` fields.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~5,200 |
| SS-16 subsystem design | ~700 |
| BC-2.16.002 file | ~600 |
| BC-2.06.001 file | ~700 |
| BC-2.06.002 file | ~600 |
| VP-003 file (with bats test vectors) | ~700 |
| STORY-001 health run.sh context | ~500 |
| Existing integration.bats (prior tests) | ~1,500 |
| Existing validate-source-immutability.bats (extend) | ~1,500 |
| **Total** | **~12,000** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `scripts/gen-test-corpus.sh` — STORY-038 scope.
- Scale throughput / memory / per-ingest cost at 10K corpus — STORY-039 scope.
- VP-003 hook implementation — already exists from EPIC-02 (STORY-013 scope).
- Chunks array population at v0.5+ — the BC explicitly states population is deferred to v0.5;
  v0.1 only needs the empty array field present.

## Anchors

- BC-2.16.002: `behavioral-contracts/ss-16/BC-2.16.002.md`
- BC-2.06.001: `behavioral-contracts/ss-06/BC-2.06.001.md`
- BC-2.06.002: `behavioral-contracts/ss-06/BC-2.06.002.md`
- VP-003: `architecture/verification-properties/VP-003-source-immutability.md`
- SS-16: `architecture/subsystems/SS-16-scale-aware-architecture.md`
- STORY-036: `stories/stories/STORY-036.md` (token JSONL write — predecessor)
- STORY-001: `stories/stories/STORY-001.md` (health skill base — predecessor)
