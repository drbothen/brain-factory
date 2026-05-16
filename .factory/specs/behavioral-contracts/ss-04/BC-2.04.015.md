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
subsystem: "SS-04"
capability: "CAP-004"
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

# Behavioral Contract BC-2.04.015: Every hook processes its sample payload under 100ms p99 (performance budget)

## Description

Every hook in the 13-hook set must process its canonical sample payload in under 100ms p99 on a standard GitHub Actions runner. This is a v0.1 ship gate requirement, not an aspiration. Latency assertions are embedded as test cases inside `plugins/brain-factory/tests/hooks.bats` — within the existing 9-suite bats coverage, not a separate suite. Wikilink validation across a 500+ page wiki may require incremental design at Phase 1c; the bats test budget covers single-payload performance only.

## Preconditions

1. The hook under test conforms to BC-2.04.016 (valid stdin JSON → stdout JSON → exit 0/1/2).
2. The test environment is a GitHub Actions `ubuntu-latest` runner or equivalent (2-core, modern CPU).
3. The "sample payload" for each hook is the canonical fixture defined in `plugins/brain-factory/tests/fixtures/{hook-name}-sample.json`.
4. All hook dependencies (`jq`, `yq`, `awk`, Node 20+) are available in PATH.

## Postconditions

1. For each hook, the latency assertion in `hooks.bats` passes: wall-clock time from hook invocation to exit is under 100ms.
2. The bats suite remains within the 9-suite count (latency tests are test cases within `hooks.bats`, not a separate suite).

## Invariants

1. The 100ms budget applies to single-payload processing, not to full-wiki operations.
2. If a hook exceeds 100ms on a 500+ page wiki (e.g., wikilink integrity), this is flagged as an incremental-design concern (Phase 1c architecture), not a v0.1 gate failure.
3. The p99 metric: measured over 10 consecutive runs of the same hook on the same payload.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Hook processes a very large JSON payload (100KB+ stdin) | Performance contract applies to the canonical sample payload only. Large-payload performance is a Phase 1c architecture concern. |
| EC-002 | Node.js startup overhead for `quarantine-fetch.sh` | Node startup is included in the 100ms budget. If startup alone exceeds the budget, the quarantine approach must be redesigned (e.g., pre-warmed Node process or rewrite in bash). |
| EC-003 | Hook performance degrades on busy CI runner | p99 budget; a single outlier does not constitute failure. Measure over 10 runs. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Canonical fixture for each of 13 hooks | All 13 hooks: wall-clock < 100ms per run; bats latency assertion passes | happy-path |
| `hooks.bats` run with `--tap` output | All latency test cases pass (green) | happy-path |
| Simulate slow hook (inject `sleep 0.2`) | Bats latency assertion fails; CI blocks | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | All 13 hook latency assertions pass in CI | bats hooks.bats (latency test cases) |
| VP-TBD | Node startup overhead for quarantine hook < 100ms | bats hooks.bats timing assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Constraints §Technical ("Hook performance budget: <100ms; v0.1 ship gate includes a bats test asserting tail latency under load.") and §Success Criteria §v0.1 ship gate ("Hook performance budget test: v0.1 ship gate adds explicit hook-performance test cases inside `plugins/brain-factory/tests/hooks.bats`"). |
| L2 Domain Invariants | N/A |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Constraints §Technical (hook performance budget); §Success Criteria §v0.1 ship gate (hook performance bats test); §Scalability Design Principles §2 (O(log n) or O(n) max) |

## Related BCs

- BC-2.04.016 — composes with (performance budget applies to hooks conforming to the I/O contract)
- BC-2.18.005 — related to (bats suites cover hook performance as test cases within hooks.bats)

## Architecture Anchors

- `architecture/SS-TBD-hooks.md`

## Story Anchor

[S-TBD]

## VP Anchors

- [VP-TBD]
