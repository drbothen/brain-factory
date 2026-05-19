---
artifact_type: story
story_id: STORY-038
epic_id: EPIC-08
title: "scripts/gen-test-corpus.sh — reproducible synthetic corpus generator"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P1
subsystems: [SS-16]
behavioral_contracts: [BC-2.16.006]
vps: []
dependencies: [STORY-001]
blocks: [STORY-039, STORY-018]
inputs:
  - architecture/subsystems/SS-16-scale-aware-architecture.md
  - behavioral-contracts/ss-16/BC-2.16.006.md
input-hash: ""
# BC status: BC-2.16.006 assigned; status=draft per Spec-First Gate S-7.01
# Priority: P1 — Phase 3 deliverable; required before scale validation (STORY-039) and
#   before the VP-027 slow-lane test in STORY-018 can be unblocked.
# Dependency rationale:
#   STORY-001 (/brain:init) establishes the .brain/ directory layout and manifest.json
#   schema that gen-test-corpus.sh must replicate. gen-test-corpus.sh creates a "pre-ingested"
#   brain vault tree that mirrors what /brain:init + N ingests would produce.
# Blocks rationale:
#   STORY-039 (scale gate) requires gen-test-corpus.sh to pre-populate 10K sources before
#   measuring throughput, memory, and per-ingest cost.
#   STORY-018 (VP-027 slow-lane) has a @test with a skip annotation waiting for this script.
# Subsystem anchor: SS-16 owns BC-2.16.006 per BC-INDEX and epics.md.
#   No additional subsystems — this is a pure script with no hook or skill dependencies.
---

# STORY-038: `scripts/gen-test-corpus.sh` — reproducible synthetic corpus generator

## Goal

Deliver `scripts/gen-test-corpus.sh`, the Phase 3 synthetic corpus generator that
produces a deterministic brain vault tree with N source files, a pre-built `manifest.json`,
and cross-referenced wiki pages. Given the same `--sources N` and `--seed N`, every
contributor gets byte-identical output across macOS and Linux bash. This script unlocks
the VP-027 slow-lane test (STORY-018) and the STORY-039 scale gate.

## User Value

As a brain-factory contributor, I want a reproducible way to generate an N-source test
brain so that scale tests are consistent across environments and every contributor can
reproduce the same corpus to validate performance claims.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.16.006 | `scripts/gen-test-corpus.sh` generates reproducible synthetic corpus for scale test | P1 |

## Acceptance Criteria

### CLI interface and output structure (BC-2.16.006)

**AC-001** — The script is invoked as:
`gen-test-corpus.sh [OPTIONS] <output-dir>`
with positional `<output-dir>` required. Flags per ADR-012:
`--sources N` (default 100), `--seed N` (default 42),
`--topics LIST` (comma-separated, default: 7 brain categories),
`--avg-words N` (default 3000), `--wiki-ratio N` (default 5),
`--format FORMAT` (`brain-vault` | `json-manifest-only`, default `brain-vault`).
(traces to BC-2.16.006 precondition 4)

**AC-002** — After a successful run with default flags and `--sources 10`:
- N source markdown files exist at `<output-dir>/sources/{topic}/{slug}.md` with valid
  frontmatter (matching the BC-2.06.001 immutability schema: `type: source`, `slug`,
  `topic`, `created_at`, no `chunks` field populated).
- `<output-dir>/.brain/manifest.json` contains N-1 pre-populated entries (N-1 sources
  "already ingested"; one source left un-ingested for the scale test to ingest).
- Wiki page directories exist at `<output-dir>/wiki/{type}/` with wiki pages at the
  default `--wiki-ratio 5` (5 wiki pages per source).
(traces to BC-2.16.006 postcondition 1, postcondition 2)

**AC-003** — Running the script twice with the same `--sources 10 --seed 42 /tmp/same-dir`
(after removing the output dir between runs) produces byte-identical output: same file
names, same file content, same manifest.json. The reproducibility assertion uses `diff -r`
between the two output trees (after removing `manifest.json` timestamps from the diff
scope — timestamps are excluded by comparing only structural content and source body hashes).
(traces to BC-2.16.006 postcondition 3; invariant 1)

**AC-004** — The script is committed to the plugin repository at
`plugins/brain-factory/scripts/gen-test-corpus.sh` and is executable (`chmod +x`). It is
available to all contributors without separate installation.
(traces to BC-2.16.006 postcondition 4)

### Cross-platform reproducibility (BC-2.16.006 invariant 1 + EC-003)

**AC-005** — The random number generator used to produce varied content per source is
implemented entirely within the script (a simple linear congruential generator (LCG) in
bash), NOT via shell `$RANDOM`. This ensures byte-identical output on macOS bash 5+ and
Linux bash 4+ with the same seed.
(traces to BC-2.16.006 invariant 1; edge case EC-003)

**AC-006** — Generated source files are valid source-layer markdown: correct frontmatter
fields (`type: source`, `slug`, `topic`, `created_at`, `immutability_hash`), and a content
body of approximately `--avg-words` words. A bats test runs `yq eval '.type' source-file.md`
and asserts the value is `"source"`.
(traces to BC-2.16.006 invariant 2)

### Error cases (BC-2.16.006 edge cases)

**AC-007** — When the output directory already contains source files from a prior run,
the script exits 1 with a human-readable message identifying the conflict directory and
does NOT overwrite or delete existing files. A bats test creates a pre-existing source
file, then runs the script and asserts exit 1 and the conflict message.
(traces to BC-2.16.006 edge case EC-001)

**AC-008** — When `--sources 0` is passed, the script exits 1 with usage error message:
"gen-test-corpus.sh: --sources N must be ≥ 1". No output directory or manifest is created.
(traces to BC-2.16.006 edge case EC-002)

**AC-009** — `--format json-manifest-only` writes only `<output-dir>/.brain/manifest.json`
(N-1 pre-populated entries) without creating any `sources/` or `wiki/` directories. A
bats test asserts the manifest file exists and no `sources/` directory was created.
(traces to BC-2.16.006 canonical test vector 4)

### Bash hygiene

**AC-010** — `scripts/gen-test-corpus.sh` starts with `#!/usr/bin/env bash` and
`set -euo pipefail`. No `eval`. No bare `exit`. Every `exit` call uses explicit codes
0 or 1. `shellcheck` exits 0 on the script. `shfmt -d -i 2` produces no diff.
(traces to BC-2.16.006 precondition 2; CLAUDE.md §Conventions §Bash hook contract)

## Tasks

1. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/integration.bats`:
   - `"gen-test-corpus.sh: --sources 10 --seed 42 → 10 source files + manifest (BC-2.16.006)"`.
   - `"gen-test-corpus.sh: same seed → byte-identical output (BC-2.16.006 invariant 1)"` —
     runs twice, uses `diff -r` on source file bodies.
   - `"gen-test-corpus.sh: generated sources have valid frontmatter (BC-2.16.006 invariant 2)"`.
   - `"gen-test-corpus.sh: --sources 0 → exit 1 usage error (BC-2.16.006 EC-002)"`.
   - `"gen-test-corpus.sh: existing output dir → exit 1 conflict error (BC-2.16.006 EC-001)"`.
   - `"gen-test-corpus.sh: --format json-manifest-only → manifest only, no sources/ dir (BC-2.16.006)"`.
   - `"gen-test-corpus.sh: wiki pages present at default --wiki-ratio 5"`.
   - `"gen-test-corpus.sh: shellcheck clean"`.
   - `"gen-test-corpus.sh: shfmt -d -i 2 clean"`.
   Run bats — confirm all 9 tests fail (Red Gate confirmed).

2. **[impl — LCG PRNG]** Implement a deterministic LCG in bash as a library function:
   ```bash
   # LCG params: m=2^32, a=1664525, c=1013904223 (Numerical Recipes)
   lcg_seed=42
   lcg_next() {
     lcg_seed=$(( (1664525 * lcg_seed + 1013904223) & 0xFFFFFFFF ))
     echo "$lcg_seed"
   }
   ```
   This is the only source of randomness in the script. `$RANDOM` must NOT be used
   (per EC-003: platform-independent reproducibility).

3. **[impl — content generation]** Implement word-list based content generation:
   - A small fixed wordlist (50–100 words) embedded in the script (no external files).
   - Each source's content is `--avg-words` words sampled from the wordlist using
     `lcg_next` for index selection.
   - Source frontmatter: `type: source`, `slug: source-{N}`, `topic: {topic-for-N}`,
     `created_at: 2026-01-01T00:00:00Z`, `immutability_hash: ""` (sha256 populated post-creation).

4. **[impl — manifest builder]** Generate `manifest.json` with N-1 entries:
   ```json
   {
     "brain_version": "0.1.0",
     "sources": {
       "sources/{topic}/source-001.md": {
         "slug": "source-001", "topic": "...", "ingested_at": "...",
         "chunks": [], "embeddings_model": null
       }
     }
   }
   ```
   Use `jq -n` to build the manifest (not string concatenation). N-1 entries are
   "already ingested"; the Nth source file exists on disk but has no manifest entry
   (it is the source the scale test will ingest).

5. **[impl — wiki pages]** At `--wiki-ratio 5`, generate 5 wiki stubs per source in
   `wiki/{type}/` dirs (cycling through `concepts`, `people`, `frameworks`, `syntheses`,
   `observations`). Each wiki page has minimal valid frontmatter:
   `type: {wiki-type}`, `title: "Stub {N}"`, `embedding_status: pending`, `created_at: "..."`.

6. **[impl — format=json-manifest-only]** When `--format json-manifest-only`: write only
   `.brain/manifest.json`; skip source file and wiki page generation.

7. **[green]** Run all 9 bats tests — all pass.

8. **[unblock STORY-018]** Remove the `skip` annotation from the VP-027 slow-lane test
   in `tests/integration.bats` (the annotation added in STORY-018 that reads:
   `skip "waiting for gen-test-corpus.sh (EPIC-08 BC-2.16.006)"` or similar).
   The test should now run and pass with the corpus generator available.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `gen-test-corpus.sh --sources 10000 --seed 42 /tmp/test-brain` | 10K source files across 7 topic dirs; manifest pre-populated with 9999 entries | happy-path | BC-2.16.006 canonical test vector 1 |
| Same command run twice (different output dirs) | `diff -r` on source file bodies: zero differences | happy-path | BC-2.16.006 invariant 1 / EC-003 |
| `gen-test-corpus.sh --sources 0 --seed 42 /tmp/out` | Exit 1; usage error; no files created | error | BC-2.16.006 EC-002 |
| Existing source file in output dir | Exit 1; conflict message; no overwrite | edge-case | BC-2.16.006 EC-001 |
| `gen-test-corpus.sh --sources 100 --format json-manifest-only /tmp/out` | `manifest.json` written; no `sources/` directory | happy-path | BC-2.16.006 canonical test vector 4 |
| Generated source file: `yq eval '.type'` | `"source"` | happy-path | BC-2.16.006 invariant 2 |
| Default `--wiki-ratio 5` with `--sources 2` | 10 wiki stub files total (2 sources × 5 ratio) | happy-path | BC-2.16.006 postcondition 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no P0 VP — P1 BC) | Same seed → identical corpus | `tests/integration.bats` |
| (no P0 VP — P1 BC) | 10K source files generated | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-16-scale-aware-architecture.md`:

1. `gen-test-corpus.sh` must produce a valid brain vault tree that matches the structure
   created by `/brain:init` + N ingest operations. The manifest.json schema must match
   BC-2.06.002 (chunks: [] and embeddings_model: null in every entry).

2. The LCG PRNG must use `(1664525 * seed + 1013904223) & 0xFFFFFFFF` (Numerical Recipes
   constants). This specific LCG is documented in BC-2.16.006 EC-003 as the cross-platform
   determinism strategy. Do NOT use `/dev/urandom`, `$RANDOM`, or Python's `random` module.

3. ADR-012 defines the CLI interface for this script. The implementer must cross-check
   ADR-012 before finalizing flag names and defaults. If ADR-012 conflicts with this story,
   ADR-012 wins (architecture is source of truth; story scope is bounded by architecture).

4. `gen-test-corpus.sh` is a SCRIPT, not a hook. It does NOT accept JSON on stdin and
   does NOT emit JSONL events. It is a standalone tool invoked by CI and by developers.
   The hook exit-code contract (0/1/2) does NOT apply — it uses standard bash exit codes
   (0 = success, 1 = error).

5. The N-1 pre-populated / 1 un-ingested structure (postcondition 2) is intentional: the
   scale test in STORY-039 measures the cost of ingesting ONE new source into an existing
   N-source corpus. The corpus generator must leave exactly one source not in the manifest
   so the scale test has a clean measurement target.

**Forbidden dependencies:**
- No `eval`.
- No `$RANDOM` (platform-dependent; not reproducible across macOS/Linux).
- No Python or Node.js — the script must be pure bash + jq (per CLAUDE.md §Conventions:
  "no compiled binaries in v0.x — pure bash + markdown").
- No external file wordlist — the wordlist must be embedded in the script.
- Generated sources must NOT have `embedding_status` field (that field belongs to wiki
  pages, not source files). Using the wrong field in source frontmatter is a schema error.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 4.0+ | Integer arithmetic for LCG (`(( ... ))` syntax); note macOS ships bash 3.2; use `#!/usr/bin/env bash` and document `brew install bash` for macOS contributors if bash 4 features are used |
| `jq` | 1.6+ | Manifest JSON construction (`jq -n`) |
| `yq` | 4.x+ | Frontmatter validation in bats tests |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.8+ | CLAUDE.md §Conventions |
| `shfmt` | 3.x+ | CLAUDE.md §Conventions |

Note on bash version: the LCG uses `(( ... & 0xFFFFFFFF ))`. On macOS bash 3.2, integer
arithmetic is 64-bit but bitwise AND works correctly. Test on both bash 3.2 and bash 5
to confirm identical output. If any difference exists, document it in the script header
and require bash 4+ explicitly.

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/scripts/gen-test-corpus.sh` | Create | New script; executable (`chmod +x`) |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 9 corpus generator bats tests; remove VP-027 skip annotation |

Files NOT to modify: any `.factory/` artifact, any hook script, `plugin.json`, any
prior story file.

## Previous Story Intelligence

STORY-001 (`/brain:init`) defines the manifest.json schema and `.brain/` directory
layout. `gen-test-corpus.sh` must replicate that exact schema. Read `STORY-001.md`
(specifically the manifest.json test vector) before implementing the manifest builder.

STORY-018 (EPIC-03, sub-linear latency gate) planted a `skip` annotation in
`tests/integration.bats` waiting for this script. Task 8 above removes that skip.
Check STORY-018 for the exact skip annotation text and test name to target.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~5,000 |
| SS-16 subsystem design | ~700 |
| BC-2.16.006 file | ~900 |
| STORY-001 (manifest schema context) | ~800 |
| STORY-018 (skip annotation context) | ~500 |
| ADR-012 (CLI interface reference) | ~600 |
| Existing integration.bats (for skip annotation location) | ~1,500 |
| **Total** | **~10,000** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Scale test execution (STORY-039) — this story only produces the tool.
- VP-027 slow-lane test implementation — written in STORY-018; this story unblocks it.
- Embedding chunk population — that is v0.5+; `chunks: []` in manifest is sufficient.
- Actual ingest pipeline execution (gen-test-corpus.sh builds the corpus structure WITHOUT
  running ingest skills — it creates the pre-populated state directly).

## Anchors

- BC-2.16.006: `behavioral-contracts/ss-16/BC-2.16.006.md`
- SS-16: `architecture/subsystems/SS-16-scale-aware-architecture.md`
- STORY-001: `stories/stories/STORY-001.md` (init manifest schema — context)
- STORY-018: `stories/stories/STORY-018.md` (VP-027 skip annotation — to remove)
- STORY-039: `stories/stories/STORY-039.md` (scale gate — blocked by this story)
