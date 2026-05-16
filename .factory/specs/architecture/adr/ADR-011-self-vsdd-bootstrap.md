---
document_type: adr
id: ADR-011
title: "Self-VSDD bootstrap: brain-factory built with its own pipeline"
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

# ADR-011: Self-VSDD bootstrap

## Context

SL-4 locks "Full self-VSDD in v0.x" — brain-factory builds itself using the vsdd-factory methodology. This means the product brief, PRD with BCs, architecture docs, stories, and TDD implementation of every hook and skill all follow the VSDD pipeline. The v0.9 ship gate requires 7-phase VSDD-pipeline convergence.

The self-VSDD commitment has several architectural implications:
1. The `.factory/` directory contains VSDD pipeline artifacts about brain-factory (the planning and spec artifacts)
2. The adversarial review pattern from Phase 1d (3-CLEAN BC-5.39.001 cascades) produces the very adversarial review skill that brain-factory ships as a product feature
3. The meta-lint suite validates that brain-factory's own skill/hook/agent artifacts conform to the contracts they enforce on users

## Decision

### The bootstrap paradox resolution

brain-factory ships the adversarial review pattern as `/brain:adversary-review`. But the adversarial review pattern was used to BUILD brain-factory (23 Phase 1a passes). This is not circular — it is a proof of production readiness:

The Phase 1a cascade validated the product brief through 23 adversary passes before any code was written. The adversary-review skill that ships in the plugin is the same protocol, now packaged and usable by operators on their own content. The skill's quality is validated by the same discipline that produced the spec.

### .factory/ as the living pipeline state

The `.factory/` directory is a first-class citizen in the brain-factory repo. It is NOT disposable scaffolding — it is the authoritative record of every architectural decision (ADRs), every behavioral contract (BCs), every verification property (VPs), and every story (Phase 2+). Future contributors to brain-factory read `.factory/` to understand WHY decisions were made.

The `.factory/` artifacts are committed on `main` via `factory(...)` conventional commits (pre-v0.1 worktree state per SESSION-HANDOFF §10). In Phase 2+, this may migrate to an orphan-branch worktree — that migration is a human-directed housekeeping decision.

### v0.9 ship gate self-VSDD requirement

The v0.9 ship gate (per product brief) requires 7-phase VSDD-pipeline convergence. This means:
- Phase 1 (spec crystallization): COMPLETE at the time this architecture lands
- Phase 2 (story decomposition): produces sprint-ready stories for every BC
- Phase 3 (TDD implementation): every hook and skill implemented via bats Red Gate → TDD green → LOCAL adversary 3-CLEAN
- Phase 4 (holdout evaluation): hidden acceptance scenarios evaluated against implementation
- Phase 5 (adversarial refinement): post-implementation cascade
- Phase 6 (formal hardening): shellcheck + shfmt + bats coverage + meta-lint clean
- Phase 7 (convergence): 7-dimensional convergence check

### meta-lint as self-validation

`tests/meta-lint.bats` (BC-2.18.001 through BC-2.18.005) validates that brain-factory's own SKILL.md, AGENT.md, and hook scripts conform to the contracts those artifacts define. This is the factory testing itself. A failing meta-lint is a P1 adversarial finding — the factory cannot enforce its own contracts on users if it doesn't enforce them on its own source.

## Consequences

**Positive:**
- Every architectural decision is documented in an ADR and reviewed by the adversary
- The adversary-review skill is production-validated before it ships (it was used to build the product)
- meta-lint provides automated regression detection for factory artifacts

**Negative:**
- The self-VSDD pipeline adds planning overhead compared to direct implementation. The payoff is the architectural discipline documented here and the adversarial review quality bar.
- Fresh contributors must read `.factory/` ADRs + BCs to understand the codebase — this is a higher onboarding bar than a typical open-source project

**Neutral:**
- The self-VSDD discipline is a user lock (SL-4) — it is not negotiable as a scope reduction

## References

- SL-4 (user lock: Full self-VSDD in v0.x)
- product-brief.md v0.9 ship gate (7-phase VSDD-pipeline convergence requirement)
- BC-2.18.001..BC-2.18.005 (meta-lint self-audit BCs)
- CLAUDE.md Canonical Principle (production-grade default — applies to self-VSDD artifacts)
