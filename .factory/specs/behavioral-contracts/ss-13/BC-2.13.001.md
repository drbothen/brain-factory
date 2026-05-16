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
subsystem: "SS-13"
capability: "CAP-013"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.13.001: v0.1 core set (6 author-committed templates) ships and runs green on push

## Description

The v0.1 plugin tarball includes 6 GitHub Action YAML templates: `daily-brief.yml`, `weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`, `scale-test.yml`. These 6 templates are author-committed (full support, bats coverage, CHANGELOG accountability). They must run green on a sample push in the v0.1 ship gate. Template names are canonical per ADR-013 §Template inventory; `quarterly-mirror.yml` is a v0.5 addition (not v0.1).

## Preconditions

1. Plugin installed; GH Action templates copied to target brain's `.github/workflows/`.
2. Brain has at least 1 ingested source.
3. GitHub Actions is enabled on the brain's repository.

## Postconditions

1. All 6 workflows (`daily-brief.yml`, `weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`, `scale-test.yml`) run green on a sample push.
2. Each workflow uses `scripts/run-skill.mjs` for skill invocation (Node 20+ required).
3. Each workflow includes explicit rate-limit handling if it calls external APIs.

## Invariants

1. Exactly 6 author-committed templates in v0.1.
2. Community-optional templates do NOT mix into the v0.1 core set.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Node 20+ not in Actions runner | Workflow fails with clear error; not a plugin bug. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Sample push to brain repo | All 6 workflows (`daily-brief.yml`, `weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`, `scale-test.yml`) run; exit 0 in CI | happy-path |
| Template list in tarball | Exactly 6 files matching ADR-013 §v0.1 core set — `quarterly-mirror.yml` is absent | happy-path |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-023 | All 6 v0.1 templates run green | bats upgrade.bats (CI simulation) |
| VP-023 | Exactly 6 templates in v0.1 tarball | bats upgrade.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-013 ("GitHub Action Templates") per brief §Scope §19 GitHub Action templates ("v0.1 core set — author-committed (6)") and §Success Criteria §v0.1 ship gate ("CI workflow runs green on a sample push"). |
| Architecture Module | SS-13: GitHub Action Templates |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §GH Action templates; §Success Criteria §v0.1 ship gate |
