---
artifact_type: story
story_id: STORY-036
epic_id: EPIC-08
title: "Token JSONL instrumentation wired into ingest skills"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-16]
behavioral_contracts: [BC-2.16.001]
vps: [VP-025]
dependencies: [STORY-017, STORY-019]
blocks: [STORY-037, STORY-039]
inputs:
  - architecture/subsystems/SS-16-scale-aware-architecture.md
  - behavioral-contracts/ss-16/BC-2.16.001.md
  - architecture/verification-properties/VP-025-scale-token-instrumentation.md
input-hash: ""
# BC status: BC-2.16.001 assigned; status=draft per Spec-First Gate S-7.01
# Priority: P0 — token instrumentation is a first-class architectural constraint
#   required before any scale measurement or budget alerting (STORY-037, STORY-039) can run.
# Dependency rationale:
#   STORY-017 (/brain:ingest-url core pipeline) and STORY-019 (/brain:ingest-source,
#   EPIC-03) are the two skills whose run.sh entry points get the token-write wiring
#   added here. Both must be merged before this story modifies them.
#   (STORY-015 is the hook contract meta-lint expansion in EPIC-02 — not an ingest skill.)
# VP anchor: VP-025 is anchored here — this is the story where the token JSONL
#   instrumentation is built and the VP-025 integration.bats tests are written.
# Blocks rationale:
#   STORY-037 (budget alert) reads ingest-tokens.jsonl — needs this first.
#   STORY-039 (scale gate) validates per-ingest cost via ingest-tokens.jsonl — needs this first.
---

# STORY-036: Token JSONL instrumentation wired into ingest skills

## Goal

Wire JSONL token record emission into `/brain:ingest-url` and `/brain:ingest-source` so
that every invocation appends a structured record to `.brain/logs/ingest-tokens.jsonl`.
Records are written on both success AND partial failure (never omitted). The directory and
file are auto-created on first ingest. This is the foundational instrumentation that
enables budget alerting (STORY-037) and scale cost measurement (STORY-039).

## User Value

As a brain-factory operator, I want every ingest operation to record its token cost so
that I can track my total cost over time, receive budget alerts before cost becomes a
surprise, and validate scale behavior at 10K sources.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.16.001 | Token instrumentation: `/brain:ingest-url` writes JSONL record per invocation | P0 |

## Acceptance Criteria

### Token JSONL record written on every ingest (BC-2.16.001)

**AC-001** — After a successful `/brain:ingest-url` invocation, a new JSONL record is
appended to `.brain/logs/ingest-tokens.jsonl`. The record contains all required fields:
`ts` (ISO 8601), `skill` (`"ingest-url"`), `url`, `source_path`, `input_tokens` (integer),
`output_tokens` (integer), `wiki_pages_generated` (integer), `duration_ms` (integer),
`status` (`"complete"`).
(traces to BC-2.16.001 postcondition 1)

**AC-002** — After a partial failure in `/brain:ingest-url` (some wiki pages written,
then a hook blocks further writes, exit 1), a JSONL record is still appended with
`status: "partial"` and token counts up to the point of failure. The record is never
omitted on partial failure.
(traces to BC-2.16.001 postcondition 2; edge case EC-001)

**AC-003** — When `.brain/logs/ingest-tokens.jsonl` does not exist at ingest time, the
file is created by the first ingest. The `.brain/logs/` directory is created if absent.
No error; ingest exits 0.
(traces to BC-2.16.001 edge case EC-002)

**AC-004** — Across 3 sequential `/brain:ingest-url` invocations, the JSONL file contains
exactly 3 records (one per ingest). Records are append-only: no record is modified or
deleted. Every line in the file is valid JSON.
(traces to BC-2.16.001 invariant 1, invariant 2)

**AC-005** — `/brain:ingest-source` (local file ingest) also writes a JSONL token record
on every invocation. The record contains `skill: "ingest-source"`, `path` (not `url`),
and all other required fields. The same append-only and partial-failure guarantees apply.
(traces to BC-2.16.001 postcondition 1; SS-16 Key Design: "Every `/brain:ingest-url`
and `/brain:ingest-source` invocation appends to ingest-tokens.jsonl")

**AC-006** — At corpus sizes of 10K+ sources (JSONL file exceeds 1MB), ingest still
appends the new record without truncation or rewrite. The file grows append-only.
(traces to BC-2.16.001 edge case EC-003)

**AC-007** — `scripts/write-token-record.sh` is the single helper that appends the JSONL
record. Both `ingest-url/run.sh` and `ingest-source/run.sh` source and call it. There is
no copy-pasted token-write logic in the two skills.
(traces to BC-2.16.001 invariant 2; CLAUDE.md §Conventions: "No eval", no swallowed errors)

## Tasks

1. **[stub — helper]** Create `plugins/brain-factory/scripts/write-token-record.sh`:
   - Shebang `#!/usr/bin/env bash` + `set -euo pipefail`.
   - Accepts args: `--skill SKILL --source-path PATH --url-or-path VALUE
     --input-tokens N --output-tokens N --wiki-pages N --duration-ms N --status STATUS`.
   - Builds JSONL record via `jq -n`, appends to `${BRAIN_ROOT}/.brain/logs/ingest-tokens.jsonl`.
   - Creates `.brain/logs/` directory if absent (no silent failure).
   - `shellcheck` clean; `shfmt -d -i 2` passes.
   - Body: `todo` comment stub (no implementation yet — Red Gate first).

2. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/integration.bats` using VP-025 test vectors:
   - `"token JSONL: record appended on successful ingest-url (BC-2.16.001)"` — asserts
     file exists + required fields present + `status == "complete"`.
   - `"token JSONL: record written even on partial failure (BC-2.16.001 EC-001)"` —
     asserts `status == "partial"` on simulated partial ingest.
   - `"token JSONL: directory created on first ingest when absent (BC-2.16.001 EC-002)"` —
     removes `.brain/logs/`; asserts it is created and file written.
   - `"token JSONL: append-only across 3 ingests (BC-2.16.001)"` — 3 ingests → 3 records;
     each line valid JSON; `jq empty` passes on each.
   - `"token JSONL: ingest-source writes record with path field (BC-2.16.001)"` — asserts
     `skill == "ingest-source"` and `path` field present.
   - `"token JSONL: token_count is non-negative integer"` — `jq -e '.token_count | type
     == "number" and . >= 0'`.
   - `"write-token-record.sh: shellcheck clean"`.
   - `"write-token-record.sh: shfmt -d -i 2 clean"`.
   Run bats — confirm all 8 tests fail (Red Gate confirmed).

3. **[impl — helper]** Implement `scripts/write-token-record.sh`:
   - Parse args with `while` loop (`--skill`, `--source-path`, etc.).
   - Build timestamp via `date -u +%Y-%m-%dT%H:%M:%SZ`.
   - Build JSON via `jq -n --arg ts "$ts" --arg skill "$skill" ...`.
   - Append: `echo "$record" >> "${BRAIN_ROOT}/.brain/logs/ingest-tokens.jsonl"`.
   - Guard: `mkdir -p "${BRAIN_ROOT}/.brain/logs"` before append.
   - Emit event: `emit_event "ingest.token.recorded"` with skill, source_path fields.
   - All `exit` calls use explicit codes (0, 1, 2). No bare `exit`.

4. **[impl — ingest-url wiring]** In `plugins/brain-factory/skills/ingest-url/run.sh`:
   - Source `scripts/write-token-record.sh` at top.
   - Track token counts (read from Claude Code API response envelope or
     `BRAIN_INGEST_INPUT_TOKENS` / `BRAIN_INGEST_OUTPUT_TOKENS` env vars set by the
     Claude Code session layer).
   - Call `write_token_record` in a `trap EXIT` handler so the record is written even
     on partial failure; set `STATUS="partial"` if exit code is non-zero before trap fires.
   - Duration: capture `START=$(date +%s%3N)` at start; compute `DURATION_MS=$((NOW - START))`
     in the trap.

5. **[impl — ingest-source wiring]** Mirror the same trap pattern in
   `plugins/brain-factory/skills/ingest-source/run.sh`.

6. **[green]** Run all 8 bats tests — all pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Successful `/brain:ingest-url` | JSONL appended; `status == "complete"`; all 8 required fields | happy-path | BC-2.16.001 / VP-025 |
| Partial failure (wiki hook blocks) | JSONL appended; `status == "partial"`; token count up to failure point | edge-case | BC-2.16.001 EC-001 / VP-025 |
| First ingest; `.brain/logs/` absent | Directory created; file created; record written | edge-case | BC-2.16.001 EC-002 / VP-025 |
| 3 sequential ingests | Exactly 3 JSONL lines; each line valid JSON | happy-path | BC-2.16.001 invariant 1 |
| `/brain:ingest-source` invocation | `skill == "ingest-source"`; `path` field present | happy-path | BC-2.16.001; SS-16 Key Design |
| `token_count` field check | `type == "number" and . >= 0` | happy-path | VP-025 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-025 | JSONL record written on every ingest invocation | `tests/integration.bats` (6 test cases) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-16-scale-aware-architecture.md`:

1. The JSONL record schema is: `{"ts":"...","skill":"ingest-url","url":"...","source_path":
   "...","input_tokens":N,"output_tokens":N,"wiki_pages_generated":N,"duration_ms":N,
   "status":"complete|partial"}`. No field may be omitted or renamed. This schema is the
   source-of-truth for BC-2.16.002 (budget alert) and BC-2.16.005 (scale cost assertion).

2. `scripts/write-token-record.sh` is the SINGLE authoritative write path for
   ingest-tokens.jsonl. No skill may write token records directly — all must call through
   this helper. Prevents schema drift across two ingest skills.

3. The token record is written in a `trap EXIT` handler, NOT at end-of-main, so it fires
   even on partial failure (a hook blocks mid-way with exit 1 or exit 2).

4. Token records are append-only. The helper must NEVER truncate or rewrite the JSONL
   file. It uses `>>` (append), never `>` (overwrite).

5. SS-16 depends on SS-02 and SS-03. This story's output (write-token-record.sh + wiring)
   is the upstream for STORY-037 (budget alert) and STORY-039 (scale gate). No scale
   measurement is possible until this story is complete.

**Forbidden dependencies:**
- `scripts/write-token-record.sh` must NOT use `eval`.
- Token counts must NOT be hardcoded as 0 — they must be read from actual API response
  data or the env var protocol (`BRAIN_INGEST_INPUT_TOKENS`). A hardcoded 0 is a paper-fix
  (TD-VSDD-059 violation).
- No skill may bypass `write-token-record.sh` with a direct `echo "..." >> ingest-tokens.jsonl`.
- `write-token-record.sh` must NOT access the LinkedIn API or any external service.
- No Prometheus, Loki, or Grafana integration — v0.x delivers JSONL files only.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 3.2+ | macOS compat |
| `jq` | 1.6+ | JSONL record construction and validation |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.8+ | CLAUDE.md §Conventions |
| `shfmt` | 3.x+ | CLAUDE.md §Conventions |
| `date` (GNU or BSD) | any | ISO 8601 timestamp; BSD `date -u` and GNU `date -u` both support `+%Y-%m-%dT%H:%M:%SZ` |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/scripts/write-token-record.sh` | Create | New helper; single authoritative JSONL write path |
| `plugins/brain-factory/skills/ingest-url/run.sh` | Modify | Add `trap EXIT` handler; source + call `write_token_record` |
| `plugins/brain-factory/skills/ingest-source/run.sh` | Modify | Mirror the same `trap EXIT` handler |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 8 VP-025 bats test cases (6 functional + 2 lint) |

Files NOT to modify: any `.factory/` artifact, `plugin.json`, any hook script, any prior
story file, `scripts/event-catalog.json` (catalog entry for `ingest.token.recorded` is
added in STORY-014's scope; this story calls the emit helper, not the catalog itself).

## Previous Story Intelligence

STORY-019 (`/brain:ingest-source`, EPIC-03) and STORY-017 (`/brain:ingest-url`) established
the ingest skill entry points (`run.sh`). STORY-014 (EPIC-02 part 2) delivered the
`hook-event-emit.sh` helper and the `scripts/event-catalog.json` file. The `emit_event`
function from STORY-014 is available for use in `write-token-record.sh`.

STORY-031 (`/brain:monthly-perf`) already reads `ingest-tokens.jsonl` — the schema this
story writes must match what STORY-031 expects. Check STORY-031's Task 1 for the
expected field names before implementation.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,500 |
| SS-16 subsystem design | ~700 |
| BC-2.16.001 file | ~600 |
| VP-025 file (with bats test vectors) | ~1,800 |
| STORY-017 run.sh (ingest-url context) | ~800 |
| STORY-019 run.sh (ingest-source context) | ~800 |
| Existing integration.bats (prior tests) | ~1,500 |
| **Total** | **~10,700** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- STORY-037: token budget alert (`/brain:health` YELLOW/RED warning) — depends on this story.
- STORY-039: scale gate (100 sources/day throughput, memory budget, 3x cost bound) — depends on this story.
- `scripts/gen-test-corpus.sh` — STORY-038 scope.
- Grafana / Loki / Prometheus integration — explicitly forbidden per CLAUDE.md §Conventions
  (v0.x is pure bash + jq + yq + awk + sha256sum).

## Anchors

- BC-2.16.001: `behavioral-contracts/ss-16/BC-2.16.001.md`
- VP-025: `architecture/verification-properties/VP-025-scale-token-instrumentation.md`
- SS-16: `architecture/subsystems/SS-16-scale-aware-architecture.md`
- STORY-017: `stories/stories/STORY-017.md` (ingest-url — predecessor)
- STORY-019: `stories/stories/STORY-019.md` (ingest-source — predecessor)
- STORY-014: `stories/stories/STORY-014.md` (emit helper — prerequisite)
- STORY-031: `stories/stories/STORY-031.md` (monthly-perf reads this JSONL)
