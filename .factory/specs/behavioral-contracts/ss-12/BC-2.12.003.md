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

The six workflows (per ADR-006 §Workflow file inventory decision): `ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`, `weekly-refresh.yaml`, `scale-test.yaml`. All use the `.yaml` extension — not `.lobster`. Lobster workflow files use `.yaml` to remain yq-compatible without plugin-specific tooling; GitHub Action templates at `templates/github-action-templates/` use `.yml` (the GH Actions canonical extension). The directory path disambiguates.

## Preconditions

1. Plugin is installed.

## Postconditions

1. All six workflow files exist at `${CLAUDE_PLUGIN_ROOT}/workflows/`: `ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`, `weekly-refresh.yaml`, `scale-test.yaml`.
2. Each workflow file is valid YAML parseable by `yq`.
3. Each workflow file passes schema validation (required fields: `name`, `description`, `steps`).

## Invariants

1. Exactly 6 workflows ship in v0.1 tarball.
2. Workflow files use the `.yaml` extension (not `.lobster`). Files at `plugins/brain-factory/workflows/` use `.yaml`; files at `templates/github-action-templates/` use `.yml` — directory path is the disambiguator.
3. Workflow files are read-only at runtime (engine side).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | A workflow file is corrupt | `bin/lobster-run` exits 2 with E-LOBSTER-003. |
| EC-002 | A file with `.lobster` extension exists in `workflows/` | meta-lint.bats flags it as a naming violation; CI blocks the PR. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `ls ${CLAUDE_PLUGIN_ROOT}/workflows/` | 6 files listed: `ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`, `weekly-refresh.yaml`, `scale-test.yaml` | happy-path |
| `yq eval '.' ${CLAUDE_PLUGIN_ROOT}/workflows/*.yaml` | All 6 parse without error | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Exactly 6 workflow files present | bats integration.bats |
| (no VP — P1) | All 6 parse as valid YAML | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-012 ("Lobster Runtime") per brief §Scope §bin/lobster-run ("6 workflow YAML files ship in `plugins/brain-factory/workflows/`"). Canonical filenames and `.yaml` extension per ADR-006 §Workflow file inventory decision. |
| Architecture Module | SS-12: Lobster Runtime |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §bin/lobster-run |
