---
document_type: subsystem-design
id: SS-13
title: "GitHub Action Templates"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-013
created: 2026-05-15
---

# SS-13: GitHub Action Templates

## Responsibility

Ships 19 GitHub Actions workflow templates (15 author-committed + 4 community-optional) that operators install into their brain vault's `.github/workflows/`. Templates enable scheduled and batch brain operations. `/brain:install-actions` materializes templates into the vault.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.13.001 | v0.1 core set (6 templates) ships and runs green on push | P0 |
| BC-2.13.002 | v0.5 additions (9 templates) ship with matrix strategy parallelism | P1 |
| BC-2.13.003 | Rate-limit handling: 429 → exponential backoff with retry-after | P1 |
| BC-2.13.004 | 4 community-optional templates ship in tarball with no-support documentation | P2 |

## Interfaces

**Inbound:** `/brain:install-actions` (no args); operator customization of materialized YAML

**Outbound:** YAML files at `${BRAIN_VAULT}/.github/workflows/`

## Key Design (references ADR-013)

Templates are organized by version gate:

**v0.1 core set (6):** `daily-brief.yml`, `weekly-refresh.yml`, `ingest-rss.yml`, `health-check.yml`, `lint-wiki.yml`, `scale-test.yml`. These 6 are CI-validated (yamllint + smoke run against fixture brain on ubuntu-latest). BC-2.13.001 requires all 6 to run green on push.

**v0.5 additions (9):** These use `matrix.strategy` for parallelism where applicable (e.g., `ingest-rss.yml` processes multiple feeds in parallel). Added at v0.5 gate.

**Community-optional (4):** Shipped in tarball at `templates/github-action-templates/community/`. Each carries a header comment: `# Community template — no author support. Use at your own risk.`

Rate-limit handling for all templates calling external APIs: uses `scripts/api-retry.sh` wrapper per ADR-016.

`/brain:install-actions` copies templates to the vault's `.github/workflows/` via a dry-run preview (lists what will be installed), then writes on operator confirmation. Templates are standalone YAML files — not templated at copy time (no substitutions needed; `${CLAUDE_PLUGIN_ROOT}` is not referenced in YAML action templates).

## Purity Classification

**Effectful shell.** Template copy (filesystem write) and GH Actions execution (external runner) are effectful. Template YAML schema validation (yamllint) is deterministic.

## Dependencies

- SS-12 (Lobster Runtime): templates invoke `bin/lobster-run` in headless mode
- SS-16 (Scale): `scale-test.yml` template
- SS-09 (Publishing): `publish-scheduled.yml` template

## Test Surface

- `bats/upgrade.bats` — template YAML is valid (yamllint); install-actions copies correct files; rate-limit retry fires on 429 fixture
- CI: v0.1 core 6 templates run green on ubuntu-latest against smoke-brain fixture
