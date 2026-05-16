---
document_type: adr
id: ADR-007
title: "factory-dispatcher relationship: v0.x bare bash; v1.0 WASM dispatcher migration"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-007: factory-dispatcher relationship

## Context

brain-factory is the second plugin in a planned family alongside vsdd-factory. A shared `factory-dispatcher` runtime (WASM-based hook dispatcher) is planned as an upstream prerequisite for v1.0. The dispatcher-extraction-plan.md documents how vsdd-factory would extract its hook runtime into a shared repo.

The phased-build-plan.md makes an explicit architectural decision: brain-factory v0.x uses bare bash hooks (Claude Code invokes hook .sh scripts directly); v1.0 migrates to WASM hooks via the shared dispatcher once it reaches v1.0.0.

## Decision

### v0.x architecture (current)

Claude Code invokes each hook script directly via the `command` field in hooks.json.template. No `factory-dispatcher` binary is involved. The hook I/O protocol (JSON-in / JSON-out / exit 0/1/2) is identical to the WASM hook ABI, so the protocol is already dispatcher-compatible even though the dispatch mechanism is not the shared dispatcher yet.

This is not a stopgap — it is the production enforcement layer for v0.x through v0.9.

### v1.0 migration conditions

The v1.0 dispatcher migration is gated on at least one of:
- factory-dispatcher repo exists at v1.0.0 with stable ABI
- Cross-platform breakage in bash hooks is observed in production (someone on Windows-native hits a wall)
- Hook chain growth past ~15 hooks makes per-event bash startup measurable
- A second factory adopts the same patterns and shared infrastructure becomes ROI-positive
- A pilot user requests observability that file-only logging cannot provide

Until at least one condition is met, bash hooks are the production layer.

### Parity test requirement for migration

When the v1.0 migration runs, a parity test corpus (`hooks/test-corpus/`) verifies that WASM hook outputs are byte-for-byte identical to bash hook outputs for the same stdin payloads (excluding `ts` and `trace` fields which are non-deterministic). This ensures the migration is a pure platform upgrade with no behavioral change. The diff count must be 0 across the corpus (KD-003 per PRD §1.3).

### dispatcher-extraction-plan.md relationship

The vsdd-dispatcher-extraction-plan.md describes how vsdd-factory would extract its hook runtime. brain-factory does not depend on this extraction — v1.0 migration could use the shared dispatcher if it exists, or brain-factory could build its own WASM wrapper if vsdd-factory's extraction is delayed. Either path is acceptable. The architectural compatibility (JSON-in / JSON-out / exit 0/1/2) ensures both paths are viable without a protocol redesign.

## Consequences

**Positive:**
- No blocking dependency on upstream factory-dispatcher extraction
- Protocol compatibility with WASM ABI means v1.0 migration is mechanical (port hook logic, no protocol redesign)
- Parity test corpus gives high confidence in migration correctness

**Negative:**
- hooks.json.template has no per-platform variant in v0.x — Windows-native users must use Git Bash or WSL2
- bash startup overhead (~50–80ms per hook invocation on cold start) counts against the 100ms p99 budget (NFR-001); measured on the CI environment and optimized if needed

**Neutral:**
- The factory-dispatcher relationship is a v1.0 concern; it has no impact on v0.x architecture decisions

## References

- vsdd-dispatcher-extraction-plan.md (upstream prerequisite description)
- phased-build-plan.md §1 (bash hooks vs WASM comparison table)
- phased-build-plan.md §2 ("The pause between Phase 3 and Phase 4 is intentional")
- PRD §1.5 (out of scope: WASM hooks via factory-dispatcher in v0.x)
- KD-003 (dispatcher-ready architecture — parity test requirement)
- NFR-001 (hook p99 latency < 100ms)
