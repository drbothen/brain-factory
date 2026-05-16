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
subsystem: "SS-12"
capability: "CAP-012"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.12.003: Six workflow YAML files ship in `plugins/brain-factory/workflows/`

## Description

The v0.1 plugin tarball includes six Lobster workflow YAML files that define the primary multi-step brain operations. These files are the primary consumers of `bin/lobster-run`. Each workflow is tested via the integration bats suite.

The six workflows: `ingest-url.lobster`, `daily-ritual.lobster`, `weekly-synthesis.lobster`, `monthly-perf.lobster`, `quarterly-mirror.lobster`, `cold-start-recovery.lobster`.

## Preconditions

1. Plugin is installed.

## Postconditions

1. All six workflow files exist at `${CLAUDE_PLUGIN_ROOT}/workflows/`.
2. Each workflow file is valid YAML parseable by `yq`.
3. Each workflow file passes schema validation (required fields: `name`, `version`, `steps`).

## Invariants

1. Exactly 6 workflows ship in v0.1 tarball.
2. Workflow files are read-only at runtime (engine side).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A workflow file is corrupt | `bin/lobster-run` exits 2 with E-LOBSTER-003. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `ls ${CLAUDE_PLUGIN_ROOT}/workflows/` | 6 files listed | happy-path |
| `yq eval '.' *.lobster` | All parse without error | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Exactly 6 workflow files present | bats integration.bats |
| VP-TBD | All 6 parse as valid YAML | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-012 ("Lobster Runtime") per brief §Scope §bin/lobster-run ("6 workflow YAML files ship in `plugins/brain-factory/workflows/`: ingest-url.lobster, daily-ritual.lobster, weekly-synthesis.lobster, monthly-perf.lobster, quarterly-mirror.lobster, cold-start-recovery.lobster"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §bin/lobster-run |
