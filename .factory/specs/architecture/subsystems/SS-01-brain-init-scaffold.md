---
document_type: subsystem-design
id: SS-01
title: "Brain Initialization and Scaffold"
level: L3
version: "1.2"
producer: "vsdd-factory:architect"
timestamp: 2026-05-18T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-001
created: 2026-05-15
---

# SS-01: Brain Initialization and Scaffold

## Responsibility

Scaffolds a new brain vault from an empty git repo and reports ongoing health state. This is the bootstrap operation — it runs once per brain and must be fast and correct.

## Capability Anchor

CAP-001 — Brain Initialization and Scaffold

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.01.001 | `/brain:init` scaffolds complete brain folder structure | P0 |
| BC-2.01.002 | `/brain:init` completes in under 5 minutes | P0 |
| BC-2.01.003 | `/brain:init` rejects non-git-repo with E-INIT-001 | P0 |
| BC-2.01.004 | `/brain:init` writes `embedding_status: pending` in wiki templates | P0 |
| BC-2.01.005 | `/brain:init` scaffolds `briefs/research/` subdirectory | P1 |
| BC-2.01.006 | `/brain:health` reports six-dimensional convergence state | P1 |

## Interfaces

**Inbound:** operator invokes `/brain:init` (no arguments); `/brain:health` (no arguments)

**Outbound:** writes directory structure and initial files to brain vault root; writes `.brain/STATE.md`, `.brain/manifest.json`, `.brain/policies.yaml`; returns structured JSON from `/brain:health`

**Emitted events:** `brain.init.started`, `brain.init.completed`, `brain.init.failed`, `brain.health.checked`

## Purity Classification

**Mixed with explicit boundary.** The scaffold directory enumeration is deterministic (pure); the git-repo detection (`git rev-parse --is-inside-work-tree`) and file writes are effectful. The file list and template content are generated from a pure function (template expansion); the writes are the effectful shell.

## Dependencies

- SS-06 (Source Layer): `sources/` directory structure and 7 default topic categories
- SS-15 (Governance): 10 baseline policies written to `.brain/policies.yaml`
- SS-17 (Event Catalog): structured events emitted during init

## Architectural Decisions (Phase 1d)

### Public CLI: zero arguments (F-PASS1-I1)

`/brain:init` is a zero-argument skill. The public interface is `/brain:init` with no flags. The skill uses the current working directory (the brain vault root) as the target. There is no `--target` or `--yes` flag in the public API per interface-definitions.md §Skill Interface Catalog.

**Implication for bats harness:** VP-014 bats tests must `cd` into the temp brain directory before invoking the init skill's run script. They do NOT pass `--target "$brain_dir"`. The run.sh internal implementation may use positional arguments internally, but these are not part of the public CLI contract.

### Already-initialized brain: hard-fail E-INIT-002 (F-PASS1-I2)

When `/brain:init` runs against a directory that already has `.brain/` initialized, it HARD-FAILS with E-INIT-002 (exit 2). It does NOT idempotently re-scaffold (no "fill in missing files" behavior).

**Rationale:** idempotent re-scaffold creates a trap — the operator may accidentally re-run init on an active brain and receive a silent success, then discover files were re-created on top of existing content. The hard-fail forces explicit intent: the operator must run `/brain:upgrade-brain` to modify an existing brain scaffold. This protects user data and makes the operation's footprint explicit.

**Recovery path:** if a brain is partially initialized (missing some scaffold files), the operator runs `/brain:upgrade-brain` which knows how to apply incremental scaffold changes idempotently. `/brain:init` is not that tool.

## Test Surface

- `tests/integration.bats` — positive: fresh git repo → scaffold created; negative: non-git dir → E-INIT-001; edge: existing `.brain/` dir → E-INIT-002 hard-fail (NOT idempotent scaffold)
- `local-dev-test.sh` — full `/brain:init` execution in temp vault; assert all directories exist; assert manifest.json valid JSON; assert policies.yaml has 10 entries
- NFR-002: `assert_under_5_minutes` timer assertion in `local-dev-test.sh`

**Note:** Init tests live in `tests/integration.bats`. `/brain:init` is an end-to-end skill test, not a hook unit test, so there is no per-hook `tests/init.bats`. The 8-category test surface reserves `integration.bats` for end-to-end skill flows including brain init.

## Scale Considerations

Init is O(1) — creates a fixed set of directories and files regardless of future corpus size. No scale concern.

## Deferred Concerns

None for v0.x. The `/brain:init` feature set is complete in v0.1.

## Changelog

### v1.2 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE — §Test Surface Note updated to remove 9-suite-roster framing):** The §Test Surface note "Init tests live in tests/integration.bats per NFR-019's 9-suite roster (no tests/init.bats exists; that would violate the 9-suite constraint)" replaced with explanation grounded in 8-category test surface and skill-vs-hook distinction. Conclusion unchanged: init tests remain in integration.bats. Cascades from SS-18 v1.5 per-hook .bats reversal (F-PHASE2-STEP-B-CLOSEOUT-O1). [audit-trail]

### v1.1 (2026-05-16)

**STRUCTURAL FIX (F-PASS1-I2/I3 — test surface and hard-fail decision):** Test Surface updated from deprecated `bats/init.bats` to canonical `tests/integration.bats` (init tests are end-to-end skill tests per the 9-suite roster; no `tests/init.bats` exists). Already-initialized brain edge case corrected from "idempotent scaffold (no overwrite)" to "E-INIT-002 hard-fail". Architectural decisions section added documenting the zero-argument CLI decision and the hard-fail decision with full rationale. Closes F-PASS1-I2 and F-PASS1-I3 as recorded in ARCH-INDEX v0.1.2. [audit-trail]

**RETROACTIVE CLASSIFICATION (F-PASS12-I2 — SS-NN Changelog discipline):** This file had content edits past initial creation but remained at v1.0 without a Changelog section, escaping the Pass 9 / Pass 10-I2 discipline. Bumped to v1.1 with Changelog added per F-PASS12-I2 resolution. [audit-trail]

### v1.0 (2026-05-15)

Original Phase 1c subsystem design — brain initialization and scaffold via `/brain:init`,
directory structure, frontmatter schema bootstrapping.
