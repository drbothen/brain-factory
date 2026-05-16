---
document_type: adr
id: ADR-004
title: "Sharded .factory/ layout for specs and behavioral contracts"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-16T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-004: Sharded .factory/ layout

## Context

brain-factory is being built using the VSDD pipeline (vsdd-factory). The VSDD pipeline produces planning artifacts (product brief, domain spec, PRD, behavioral contracts, architecture docs, stories) in a `.factory/` directory. These artifacts must be organized so that:

1. No single artifact file grows large enough to exhaust agent context budgets
2. Each artifact type has a canonical home discoverable by fresh-context agents
3. Behavioral contracts can be sharded by domain without losing their index

The alternative — a single monolithic PRD or single BC file — would require agents to load thousands of lines of context for tasks that only touch a few BCs.

## Decision

The `.factory/` layout uses domain sharding for behavioral contracts and a separate `prd-supplements/` directory for large PRD annexes:

```
.factory/
  specs/
    product-brief.md                 (single file; the file is its own index)
    prd/
      index.md                       (PRD index — summaries + RTM)
      prd-supplements/
        interface-definitions.md
        error-taxonomy.md
        nfr-catalog.md
        test-vectors.md
    behavioral-contracts/
      BC-INDEX.md                    (canonical sharding index over 95 BCs across 18 subsystems)
      ss-01/ .. ss-18/               (18 subsystem directories, 95 BC files)
    architecture/
      ARCH-INDEX.md                  (this file's canonical sharding index)
      adr/                           (one ADR per decision)
      subsystems/                    (one design doc per SS-NN)
      verification-properties/       (one VP per property + VP-INDEX.md)
  planning/
    stage-3-locks.md                 (Stage 3 user-locked decisions)
    elicitation-notes.md
    brief-research.md
    reference-repos.md
  cycles/
    v0.1-phase-1a-brief/             (adversary pass reports, immutable)
  STATE.md                           (live pipeline state)
  SESSION-HANDOFF.md                 (resume-ready handoff)
  TASK-LIST.md                       (task ledger)
```

**Sharding rule for behavioral contracts:** BC files are grouped by capability domain subsystem (ss-NN), matching the PRD §2 CAP-NNN groupings. BC-INDEX.md is the canonical enumeration; individual BC files carry `traces_to: ../BC-INDEX.md`. Agent context discipline: load BC-INDEX.md first; load individual BC files only for the subsystem under construction.

**Sharding rule for architecture:** ARCH-INDEX.md is the canonical enumeration. ADRs, subsystem designs, and VPs are separate files. Architecture agents load ARCH-INDEX.md as the entry point; load individual files when the task is specific to that ADR/SS/VP.

**Worktree layout (pre-v0.1):** `.factory/` is a regular directory tracked on `main`, not a canonical orphan-branch worktree. This is intentional pre-v0.1 state per SESSION-HANDOFF §10 standing directive. Migration to orphan-branch worktree is a Phase 2 prep or v0.1 release prep decision (open for human direction).

## Consequences

**Positive:**
- Agent context budgets scale linearly with the task rather than with the full spec
- Each artifact type has an unambiguous canonical home; fresh-context agents can navigate without prior session state
- BC-INDEX / ARCH-INDEX as sharding indexes enable consistent cross-reference without loading all files

**Negative:**
- New architects must read the index before the detail files — adds one read per session
- Cross-subsystem BC queries (e.g., "find all P0 BCs") require reading BC-INDEX rather than grepping one file

**Neutral:**
- The `.factory/` layout is a VSDD pipeline convention inherited from vsdd-factory; brain-factory customizes it but does not redesign it

## References

- Current PRD + BC-INDEX.md (the canonical sharding index over 95 BCs across 18 subsystems)
- BC-2.01.001 through BC-2.18.005 (the 95 BC files that live in this layout)
- SESSION-HANDOFF.md §10 (worktree layout standing directive)
