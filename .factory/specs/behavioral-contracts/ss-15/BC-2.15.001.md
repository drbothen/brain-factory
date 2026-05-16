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
subsystem: "SS-15"
capability: "CAP-015"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.15.001: `.brain/policies.yaml` is initialized with 10 baseline policies by `/brain:init`

## Description

`.brain/policies.yaml` is the brain's governance configuration file. `/brain:init` copies the default template from `${CLAUDE_PLUGIN_ROOT}/templates/policies-yaml-template.yaml` to `.brain/policies.yaml`. The template ships pre-populated with 10 baseline policies enumerated in plugin-plan.md §10.2. Operators may extend via `/brain:policy-add`.

## Preconditions

1. `/brain:init` is executing its template-expansion phase.
2. `${CLAUDE_PLUGIN_ROOT}/templates/policies-yaml-template.yaml` is present.

## Postconditions

1. `.brain/policies.yaml` exists with 10 baseline policies.
2. File is valid YAML (parseable by `yq`).
3. Policies include at minimum: `adversary_model` (default: Opus/Sonnet split), `max_adversary_iterations` (default: 3), `max_ingest_tokens_per_chunk` (default: 50000).

## Invariants

1. Exactly 10 baseline policies at v0.1.
2. Template is the source of truth — init always copies from template.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `${CLAUDE_PLUGIN_ROOT}/templates/policies-yaml-template.yaml` is missing or corrupt at init time | `/brain:init` exits with E-INIT-004 ("Plugin root not found — reinstall brain-factory"); `.brain/policies.yaml` is not created; brain scaffold is rolled back |
| EC-002 | `.brain/policies.yaml` already exists when `/brain:init` is run (re-init attempt) | `/brain:init` exits with E-INIT-002 before reaching the policy-copy phase; existing `.brain/policies.yaml` is not overwritten |
| EC-003 | The policies template contains a policy with a duplicate key (malformed template at authoring time) | `yq eval '.' .brain/policies.yaml` fails YAML parse after copy; `/brain:policy-registry-validate` detects the duplicate and exits 1; operator is directed to reinstall the plugin |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh init; `yq eval '.' .brain/policies.yaml` | Valid YAML; 10 policies present | happy-path |
| Init with template file absent | E-INIT-004 message; exit 2; no `.brain/policies.yaml` created | error |
| Init on a directory that already has `.brain/` | E-INIT-002 message; exit 2; existing policies.yaml untouched | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | 10 baseline policies present after init | bats policies.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-015 ("Governance and Policies") per brief §Scope §Additional v0.x deliverables ("10 baseline policies in `.brain/policies.yaml`") and plugin-plan.md §10.2. |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Additional v0.x deliverables |
