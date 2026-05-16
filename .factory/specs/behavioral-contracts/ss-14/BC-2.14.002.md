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
subsystem: "SS-14"
capability: "CAP-014"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.14.002: `/brain:upgrade-brain` upgrades the plugin and migrates `.brain/` state if needed

## Description

`/brain:upgrade-brain` handles the upgrade path when a new version of brain-factory is installed. It compares the current `.brain/` schema version against the new plugin version's schema, runs any required migrations (manifest format changes, policies schema changes, STATE.md format changes), and confirms the upgrade was clean. This is the only safe upgrade path — manual edits to `.brain/` during an upgrade are unsupported.

## Preconditions

1. New version of brain-factory has been installed via `/plugin install` or `/plugin update`.
2. Existing `.brain/` directory with state from a prior version.

## Postconditions

1. `.brain/` schema matches the new version's expected schema.
2. `manifest.json`, `policies.yaml`, `STATE.md` are valid under the new schema.
3. CHANGELOG.md updated with the upgrade record.
4. Exit 0.

## Invariants

1. Upgrades are always forward-only. No downgrade support in v0.x.
2. Migration scripts are idempotent (safe to run twice).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | `.brain/` schema is from an incompatible version | Exit 2 with E-UPGRADE-001: "Incompatible schema version. Manual migration required. See CHANGELOG." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| v0.1 brain upgraded to v0.2 | Schema migrated; exit 0 | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Upgrade migration runs without error | bats upgrade.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-014 ("Plugin Lifecycle and Upgrade") per brief §Scope §Phase 2–3 polish skills (#20: `/brain:upgrade-brain — upgrade the plugin and migrate `.brain/` state if needed`). |
| Architecture Module | SS-14: Plugin Lifecycle and Upgrade |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 2–3 polish skills (#20) |
