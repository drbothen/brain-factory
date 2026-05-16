---
document_type: subsystem-design
id: SS-01
title: "Brain Initialization and Scaffold"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
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

## Test Surface

- `bats/init.bats` — positive: fresh git repo → scaffold created; negative: non-git dir → E-INIT-001; edge: already-initialized brain → idempotent scaffold (no overwrite)
- `local-dev-test.sh` — full `/brain:init` execution in temp vault; assert all directories exist; assert manifest.json valid JSON; assert policies.yaml has 10 entries
- NFR-002: `assert_under_5_minutes` timer assertion in `local-dev-test.sh`

## Scale Considerations

Init is O(1) — creates a fixed set of directories and files regardless of future corpus size. No scale concern.

## Deferred Concerns

None for v0.x. The `/brain:init` feature set is complete in v0.1.
