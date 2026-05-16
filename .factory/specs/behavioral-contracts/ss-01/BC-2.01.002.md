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
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.002: `/brain:init` completes end-to-end in under 5 minutes (tested SLA)

## Description

The 5-minute init SLA is a tested contract, not an aspiration. The v0.1 ship gate requires an explicit timer assertion (`assert_under_5_minutes`) in the local-dev test script at `plugins/brain-factory/tests/local-dev-test.sh`. This BC defines the performance contract, the measurement method, and the conditions under which the SLA must hold.

## Preconditions

1. All preconditions from BC-2.01.001 are satisfied (valid git repo, all tools in PATH, no `.brain/` exists).
2. The test is run on a machine meeting minimum operator spec: modern laptop or CI runner (equivalent to GitHub Actions `ubuntu-latest` 2-core runner).
3. A network connection is not required for init (all templates are local to the plugin). This SLA does not include optional network operations at init time.

## Postconditions

1. Wall-clock time from skill invocation to successful completion is under 300 seconds (5 minutes).
2. The `assert_under_5_minutes` test case in `plugins/brain-factory/tests/local-dev-test.sh` passes without modification.
3. No pre-existing timer assertions are weakened to accommodate an implementation that exceeds 5 minutes.

## Invariants

1. The SLA is measured by the local-dev test script, not by operator self-report.
2. The SLA applies to the complete init operation including: template expansion, directory creation, baseline file writes, and GH Action template installation.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Init on a high-latency NFS-mounted filesystem | SLA applies to local-only init operations; NFS latency is outside contract scope. Log a warning if operation exceeds 60 seconds for any single file write. |
| EC-002 | Machine under significant load (CPU busy) | SLA is a p95 contract: measured over 5 test runs on a clean machine. A single slow outlier does not constitute a failure. |
| EC-003 | Future extensions to init scaffold add new directories | Each new directory added to init scope must re-run the SLA test. SLA extends to cover new scope. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh git repo on a GitHub Actions ubuntu-latest runner | Wall-clock < 300s; `assert_under_5_minutes` passes | happy-path |
| Timer assertion in local-dev-test.sh called with 5-minute threshold | Test passes when init < 300s; fails when init > 300s | edge-case |
| Init with 50 template files (future expansion) | Wall-clock still < 300s; timer assertion still passes | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | `assert_under_5_minutes` test case passes in CI | bats integration (local-dev-test.sh) |
| VP-TBD | SLA holds on GitHub Actions ubuntu-latest runner | CI pipeline measurement |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-001 ("Brain Initialization and Scaffold") per brief §Scope §Phase 0/1 primitives skill #1. This BC specifically covers the performance SLA of the init operation, which is part of the CAP-001 initialization contract. |
| L2 Domain Invariants | N/A |
| Architecture Module | [filled by architect — Phase 1c] |
| Stories | [filled by story-writer — Phase 2] |
| Source Brief Section | product-brief.md §Success Criteria §v0.1 ship gate (5-minute init SLA; `assert_under_5_minutes`) |

## Related BCs

- BC-2.01.001 — depends on (init must complete successfully within this SLA)
- BC-2.04.015 — related to (hook performance budget is a separate SLA)

## Architecture Anchors

- `architecture/subsystems/SS-01-brain-init-scaffold.md`

## Story Anchor

[S-TBD] — [filled by story-writer — Phase 2]

## VP Anchors

- [VP-TBD] — [filled by architect/formal-verifier — Phase 1c]
