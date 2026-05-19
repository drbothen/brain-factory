---
document_type: behavioral-contract
level: L3
version: "1.4"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-18T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: ["v1.2"]
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.04.015: Every hook processes its sample payload under 100ms p99 (performance budget)

## Description

Every hook in the 13-hook set must process its canonical sample payload in under 100ms p99 on a standard GitHub Actions runner. This is a v0.1 ship gate requirement, not an aspiration. Latency assertions are embedded as test cases inside the per-hook bats file for each hook (`plugins/brain-factory/tests/<hook-name>.bats`) — not in a separate performance suite. Wikilink validation across a 500+ page wiki may require incremental design at Phase 1c; the bats test budget covers single-payload performance only.

## Preconditions

1. The hook under test conforms to BC-2.04.016 (valid stdin JSON → stdout JSON → exit 0/1/2).
2. The test environment is a GitHub Actions `ubuntu-latest` runner or equivalent (2-core, modern CPU).
3. The "sample payload" for each hook is the canonical fixture defined in `plugins/brain-factory/tests/fixtures/{hook-name}-sample.json`.
4. All hook dependencies (`jq`, `yq`, `awk`, Node 20+) are available in PATH.

## Postconditions

1. For each hook, the latency assertion in its per-hook bats file (e.g., `tests/quarantine-fetch.bats` for `quarantine-fetch.sh`) passes: wall-clock time from hook invocation to exit is under 100ms. All 13 per-hook latency assertions pass.
2. The latency assertions live inside the per-hook bats file for that hook (not a separate performance suite).

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
| `bats tests/<hook-name>.bats` run with `--tap` output (per hook) | All latency test cases pass (green) | happy-path |
| Simulate slow hook (inject `sleep 0.2`) | Bats latency assertion fails; CI blocks | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-001, VP-013 | All 13 hook latency assertions pass in CI | bats tests/<hook-name>.bats (per-hook latency test cases) |
| VP-001, VP-013 | Node startup overhead for quarantine hook < 100ms | bats tests/quarantine-fetch.bats timing assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Constraints §Technical ("Hook performance budget: <100ms; v0.1 ship gate includes a bats test asserting tail latency under load.") and §Success Criteria §v0.1 ship gate ("Hook performance budget test: v0.1 ship gate adds explicit hook-performance test cases in each hook's per-hook bats file (`plugins/brain-factory/tests/<hook-name>.bats`, one file per hook in the per-hook + category test model)"). |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | STORY-015 |
| Source Brief Section | product-brief.md §Constraints §Technical (hook performance budget); §Success Criteria §v0.1 ship gate (hook performance bats test); §Scalability Design Principles §2 (O(log n) or O(n) max) |

## Related BCs

- BC-2.04.016 — composes with (performance budget applies to hooks conforming to the I/O contract)
- BC-2.18.005 — related to (per-hook bats files cover hook performance as latency test cases)

## Architecture Anchors

- `architecture/subsystems/SS-04-hook-enforcement-chain.md`

## Story Anchor

STORY-015

## VP Anchors

- VP-001 — Hook exit-code semantics coverage (bats per-hook files)
- VP-013 — Hook p99 latency under 100ms (bats perf assertion in per-hook bats files)

## Changelog

### v1.4 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-015; Story Anchor updated from [S-TBD] to STORY-015 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.3 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-RETRY-I01):** Postcondition 1 corrected from stale `hooks.bats` reference to per-hook bats file pattern: "For each hook, the latency assertion in its per-hook bats file (e.g., `tests/quarantine-fetch.bats`) passes." Capability Anchor Justification §v0.1 ship gate quote updated from stale "test cases inside `plugins/brain-factory/tests/hooks.bats`" to current brief language: "test cases in each hook's per-hook bats file (`plugins/brain-factory/tests/<hook-name>.bats`)". Both changes align with brief v0.4.20 per-hook bats model. No semantic change to the 100ms p99 performance contract. [audit-trail]

### v1.2 (2026-05-18)

**TEST-ARCHITECTURE AMENDMENT CASCADE (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE):** Description, Postcondition 2, Test Vectors, VP table, VP Anchors, and Related BCs updated to replace `hooks.bats` / "9-suite" references with per-hook bats file model per brief v0.4.20. No semantic change to the 100ms p99 performance contract itself. [audit-trail]

### v1.1 (2026-05-16)

Prior version. Referenced consolidated `hooks.bats` and "9-suite bats coverage".
