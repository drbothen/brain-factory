---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-016"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.16.006: `scripts/gen-test-corpus.sh` generates reproducible synthetic corpus for scale test

## Description

`scripts/gen-test-corpus.sh` is a Phase 3 deliverable that generates a reproducible synthetic corpus for the v0.9 scale test. It accepts a count N and a random seed, generates N source markdown files with randomized content from the seed, and creates a pre-built `manifest.json` representing the state after N-1 ingests. This allows the scale test to start from an existing-corpus baseline rather than re-ingesting from zero.

## Preconditions

1. `scripts/gen-test-corpus.sh` is executable.
2. `jq` and `bash` 4+ available.
3. A target directory is specified.

## Postconditions

1. N source files generated at `<target>/sources/{topic}/` with randomized but valid content.
2. `<target>/.brain/manifest.json` pre-populated with N-1 entries (N-1 "already ingested" sources).
3. The corpus generation is deterministic given the same N and seed (reproducible by any contributor).
4. The script is committed to the plugin repo so it's available to all contributors.

## Invariants

1. Same N + seed → identical corpus on every run.
2. Generated sources are valid source-layer markdown (correct frontmatter, valid content).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Target directory already contains existing source files from a prior run | The script detects the conflict and exits 1 with a message identifying the conflict; it does not overwrite existing files; the operator must remove the target directory or specify a clean one |
| EC-002 | N=0 is specified (empty corpus) | The script exits 1 with a usage error; it does not create a target directory or manifest; minimum N is 1 |
| EC-003 | Two contributors run the script with the same seed on different OS implementations of `bash` | The corpus must be byte-identical across macOS bash 5+ and Linux bash 4+; the random number generator used must be implemented in the script itself (not via shell `$RANDOM`) to ensure cross-platform reproducibility |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `gen-test-corpus.sh 10000 --seed 42 --dir /tmp/test-brain` | 10K source files; manifest with 9999 entries | happy-path |
| Same command run twice | Second run detects conflict; exits 1 | edge-case |
| `gen-test-corpus.sh 0 --seed 42 --dir /tmp/test-brain` | Usage error; exit 1; no files created | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Same seed → same corpus | bats integration.bats (run twice; diff output) |
| VP-TBD | 10K source files generated | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-016 ("Scale-Aware Architecture") per brief §Scope §Additional v0.x deliverables ("`scripts/gen-test-corpus.sh` — synthetic-corpus generator producing N source files + manifest.json for the v0.9 scale test (Phase 3 deliverable owned by devops-engineer, designed during Phase 1c architecture, built during Phase 3 alongside scale-test execution)"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Additional v0.x deliverables; §Success Criteria §v0.9 ship gate §Scale test |
