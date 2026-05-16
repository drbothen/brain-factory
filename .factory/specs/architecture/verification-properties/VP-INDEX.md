---
document_type: vp-index
level: L3
version: "0.1.0"
status: draft
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
created: 2026-05-15
---

# Verification Property Index: brain-factory

> Canonical enumeration of all 13 verification properties. Each VP traces to one or
> more BCs. VP files carry `traces_to: ../VP-INDEX.md` in frontmatter.
>
> Verification mechanism for brain-factory v0.x: bats (not Kani/proptest — this
> is bash, not Rust). Property-based testing uses parameterized bats re-runs.
> Formal proofs are not applicable to bash; the analog is: same stdin fixture
> re-run N times → same stdout verdict (determinism assertion).

| VP-ID | Title | Mechanism | Target BCs | Phase | Status |
|-------|-------|-----------|------------|-------|--------|
| VP-001 | Hook exit-code semantics coverage | bats (hooks.bats) | BC-2.04.016, BC-2.04.015 | P0 | proposed |
| VP-002 | PostToolUse hook trigger on wiki writes | bats (integration.bats) | BC-2.04.003..BC-2.04.007, BC-2.04.009, BC-2.04.010 | P0 | proposed |
| VP-003 | Source immutability enforcement | bats (hooks.bats) | BC-2.04.002, BC-2.06.001 | P0 | proposed |
| VP-004 | Wikilink resolution correctness | bats (unit + integration) | BC-2.04.003, BC-2.05.002 | P0 | proposed |
| VP-005 | Frontmatter schema conformance | bats (hooks.bats) | BC-2.04.004, BC-2.04.005, BC-2.05.006 | P0 | proposed |
| VP-006 | Meta-lint factory self-audit | meta-lint.bats | BC-2.18.001..BC-2.18.005 | P0 | proposed |
| VP-007 | Lobster workflow determinism | bats (unit) | BC-2.12.001, BC-2.12.002 | P0 | proposed |
| VP-008 | Hook event catalog completeness | meta-lint.bats cross-ref | BC-2.17.001, BC-2.17.002 | P0 | proposed |
| VP-009 | Plugin manifest schema correctness | bats (upgrade.bats) | BC-2.14.004, BC-2.14.005 | P0 | proposed |
| VP-010 | Adversarial 3-CLEAN convergence | adversary cascade protocol | BC-2.07.001..BC-2.07.004 | P1 | proposed |
| VP-011 | Quarantine on every WebFetch | bats (quarantine.bats) | BC-2.10.002, BC-2.04.001 | P0 | proposed |
| VP-012 | Manifest write atomicity | bats (integration.bats) | NFR-018, BC-2.03.002 | P0 | proposed |
| VP-013 | Hook p99 latency under 100ms | bats perf assertion (hooks.bats) | BC-2.04.015, NFR-001 | P0 | proposed |

**Totals:** 13 VPs total. P0: 12. P1: 1. Mechanism breakdown: bats: 12; adversary cascade protocol: 1.

---

## Self-Audit Checklist

- [x] All VP IDs are sequential (VP-001 through VP-013)
- [x] Every VP has a viable verification mechanism for bash/bats stack
- [x] All P0 BCs (hook enforcement chain, wiki layer, source immutability) have at least one VP
- [x] VP-INDEX total (13) matches the count of VP files in this directory
