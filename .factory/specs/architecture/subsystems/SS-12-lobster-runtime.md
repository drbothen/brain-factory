---
document_type: subsystem-design
id: SS-12
title: "Lobster Runtime"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-012
created: 2026-05-15
---

# SS-12: Lobster Runtime

## Responsibility

Provides a bash workflow orchestrator (`bin/lobster-run`) that reads workflow YAML files, resolves step dependencies via topological sort, executes skill steps in dependency order, and supports headless execution for GH Actions.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.12.001 | `bin/lobster-run` reads workflow YAML and executes steps in declared dependency order | P0 |
| BC-2.12.002 | `bin/lobster-run` exits 0 (all succeed), 1 (advisory), 2 (any step blocks) | P0 |
| BC-2.12.003 | Six workflow YAML files ship in `plugins/brain-factory/workflows/` | P1 |
| BC-2.12.004 | `bin/lobster-run` supports headless execution (no interactive prompts) | P0 |

## Interfaces

**Inbound:** `bin/lobster-run <workflow.yaml> [--headless] [--env KEY=VALUE ...]`

**Outbound:** step results as JSONL to `.brain/logs/lobster-YYYY-MM-DD.jsonl`; exit 0/1/2

## Key Design (references ADR-006)

### Dependency resolution

Kahn's algorithm (BFS) on the `depends_on` DAG. Steps with no dependencies execute first; subsequent steps execute only after all their dependencies succeed. If a dependency step exits 2 (block), dependent steps are skipped and lobster-run exits 2.

### Step execution

In headless mode (`--headless`): invokes `node scripts/run-skill.mjs <skill-name> <args>` for each step. `run-skill.mjs` is the headless skill runner (SL-1 Node 20+ utility).

In interactive mode (no flag): prints the skill invocation command and waits for the operator to confirm via Claude Code. This mode is used when the operator runs a workflow manually in a Claude Code session.

### Workflow YAML schema (six files)

Schema validated by `bats/integration.bats` — each field is required:
- `name`: string, workflow identifier
- `description`: string, human-readable purpose
- `steps`: array of step objects (id, skill, args, depends_on)

The six workflow files ship in `plugins/brain-factory/workflows/`:
1. `ingest-url.yaml`
2. `ingest-source.yaml`
3. `brief-to-publish.yaml`
4. `daily-ritual.yaml`
5. `weekly-refresh.yaml`
6. `scale-test.yaml`

### Exit code propagation

Step result envelope written to lobster log:
```json
{"step_id": "fetch", "exit_code": 0, "verdict": "allow", "duration_ms": 1200}
```
Lobster-run's own exit code:
- 0 if all steps exit 0
- 1 if any step exits 1 (advisory) and no step exits 2
- 2 if any step exits 2 (block)

## Purity Classification

**Mixed.** The topological sort (dependency resolution) is a pure function testable with fixture workflow YAML. The step execution (invoking run-skill.mjs or Claude Code) is effectful.

## Dependencies

- SS-02, SS-03 (Ingest pipelines): lobster orchestrates ingest workflows
- SS-16 (Scale): scale-test.yaml workflow
- SS-17 (Event Catalog): lobster step events registered

## Test Surface

- `bats/integration.bats` — topological sort with fixture YAML; cycle detection → E-LOBSTER-001; headless execution of smoke workflow in temp brain
