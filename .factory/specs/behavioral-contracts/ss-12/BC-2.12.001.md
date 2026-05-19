---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-12"
capability: "CAP-012"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.12.001: `bin/lobster-run` reads workflow YAML and executes skill steps in declared dependency order

## Description

`bin/lobster-run` is the minimal bash Lobster runtime shipped with brain-factory v0.1. It reads a Lobster YAML workflow file, parses the `steps:` array with `depends_on:` declarations, resolves the dependency graph, and executes each step (skill invocation) in topological order. It supports headless execution for GitHub Actions. The 6 workflow files shipped in `plugins/brain-factory/workflows/` are the primary consumers.

## Preconditions

1. `bin/lobster-run` is executable (`chmod +x`).
2. The workflow YAML file exists at the specified path.
3. All referenced skills are registered in the plugin manifest.

## Postconditions

1. Steps execute in topological dependency order (all `depends_on` steps complete before dependent steps start).
2. Skill invocations use the brain-factory skill namespace (`/brain:*`).
3. Final exit code: 0 (all steps succeed), 1 (advisory from any step), 2 (any step exits 2 — pipeline stops).

## Invariants

1. `bin/lobster-run` is a pure bash interpreter — no Node, no Python, no Rust in v0.x.
2. On step failure (exit 2), the pipeline stops immediately (no subsequent steps run).
3. On step advisory (exit 1), the pipeline continues and reports the advisory in the summary.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Circular dependency in workflow YAML | lobster-run exits 2 with E-LOBSTER-001: "Circular dependency detected in workflow." |
| EC-002 | Referenced skill not found | lobster-run exits 2 with E-LOBSTER-002: "Skill '<name>' not found in plugin manifest." |
| EC-003 | YAML parse error | lobster-run exits 2 with E-LOBSTER-003: "Invalid workflow YAML: <error>." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `bin/lobster-run workflows/ingest-url.yaml` | All steps execute in order; exit 0 | happy-path |
| Workflow with circular dependency | E-LOBSTER-001; exit 2 | error |
| Workflow with missing skill | E-LOBSTER-002; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-007 | Steps execute in dependency order | bats integration.bats |
| VP-007 | Circular dependency detected | bats integration.bats |
| VP-007 | Step failure stops pipeline | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-012 ("Lobster Runtime") per brief §Scope §bin/lobster-run ("a bash interpreter for Lobster YAML workflow files. The runtime behavior (reads workflow YAML; executes skill steps in declared dependency order; exits 0/1/2) is the commitment.") and locked decision SL-3 (Ship bin/lobster-run in v0.x). |
| Architecture Module | SS-12: Lobster Runtime |
| Stories | STORY-032 |
| Source Brief Section | product-brief.md §Scope §bin/lobster-run; locked decisions SL-3 |

## Related BCs

- BC-2.12.002 — composes with (exit codes)
- BC-2.12.004 — composes with (headless execution)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-032 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
