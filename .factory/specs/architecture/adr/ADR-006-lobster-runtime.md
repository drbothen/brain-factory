---
document_type: adr
id: ADR-006
title: "Lobster runtime as bash workflow orchestrator (not LangChain, not Temporal)"
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

# ADR-006: Lobster runtime as bash workflow orchestrator

## Context

Several brain-factory operations require multi-step skill orchestration: URL ingest dispatches Defuddle, then invokes `brain:librarian` to generate 5–15 wiki pages, then writes the manifest delta. Without an explicit orchestrator, these multi-step flows are either baked into individual SKILL.md bodies (coupling) or left to ad-hoc Claude Code agent reasoning (non-deterministic).

SL-3 locked the decision to ship a minimal bash Lobster runner in v0.x (not LangChain, not Temporal, not a raw agent loop).

## Decision

`bin/lobster-run` is a bash script that:
1. Reads a workflow YAML file (argument or stdin)
2. Resolves step dependencies using a topological sort
3. Executes steps in dependency order, dispatching each step by invoking the corresponding skill via `scripts/run-skill.mjs` (headless) or directly via the Claude Code agent
4. Exits 0 (all steps succeed), 1 (any step produces advisory exit code), or 2 (any step blocks)

### Workflow YAML schema

```yaml
# plugins/brain-factory/workflows/<name>.yaml
name: ingest-url
description: Fetch URL, generate wiki pages, write manifest delta
steps:
  - id: fetch
    skill: brain:ingest-url
    args: ["${URL}"]
    depends_on: []
  - id: generate-wiki
    skill: brain:librarian
    args: ["${FETCH_OUTPUT}"]
    depends_on: [fetch]
  - id: write-manifest
    skill: brain:manifest-update
    args: ["${GENERATE_WIKI_OUTPUT}"]
    depends_on: [generate-wiki]
```

Fields: `name` (string), `description` (string), `steps` (array of step objects). Each step: `id` (unique string), `skill` (brain:X identifier), `args` (array), `depends_on` (array of step IDs).

### Dependency resolution algorithm

`bin/lobster-run` resolves dependencies with a simple topological sort:
1. Build an adjacency list from `depends_on` declarations
2. Run Kahn's algorithm (queue-based BFS) to produce a linear execution order
3. Reject cycles: if the output ordering contains fewer steps than the input, a cycle exists — exit 2 with `E-LOBSTER-001`

This is O(V + E) where V = steps and W = dependency edges. For brain-factory's workflow sizes (2–8 steps), this is instantaneous.

### Headless execution

`bin/lobster-run` supports headless execution (BC-2.12.004) by dispatching skills via `scripts/run-skill.mjs` when the `--headless` flag is passed. In interactive mode (no flag), it invokes skills by writing to the Claude Code agent. This is the distinction between GH Actions execution (headless) and operator-invoked execution (interactive).

### Six workflow files shipped (BC-2.12.003)

Six workflow YAML files in `plugins/brain-factory/workflows/`:
1. `ingest-url.yaml` — URL fetch → wiki generation → manifest write
2. `ingest-source.yaml` — local file → wiki generation → manifest write
3. `brief-to-publish.yaml` — brief → write → adversary-review → publish-content
4. `daily-ritual.yaml` — brain-health-check → process-inbox → connect → daily-brief
5. `weekly-refresh.yaml` — connect → synthesize → weekly-refresh
6. `scale-test.yaml` — gen-test-corpus → batch-ingest → lint-wiki → health-check

### Workflow file inventory decision (F-PASS2-C2)

BC-2.12.003 drafted `.lobster` as the extension and named the six files differently from SS-12 and ADR-006. The canonical decision (architect-owned, Phase 1d Pass 2 fix-burst):

**Extension: `.yaml`.** Lobster workflow files use the `.yaml` extension. Rationale: yq-compatible, conventional YAML tooling reads them without plugin installation, and the v0.x bash runner consumes them directly. The `.lobster` extension was never formally adopted in an ADR — it appeared only in a BC draft. This ADR supersedes that draft naming.

**Filenames: Option A (SS-12 / ADR-006 set).** The six canonical workflow filenames are those defined here and in SS-12: `ingest-url.yaml`, `ingest-source.yaml`, `brief-to-publish.yaml`, `daily-ritual.yaml`, `weekly-refresh.yaml`, `scale-test.yaml`. Rationale: this set provides functional coverage of v0.x scope — both ingest surfaces (URL + local file), the full brief → publish pipeline, the daily ritual, the weekly refresh, and the scale validation workflow. The BC-2.12.003 draft set (`weekly-synthesis`, `monthly-perf`, `quarterly-mirror`, `cold-start-recovery`) either conflicts with BC names in other subsystems or duplicates ritual functions already covered by `daily-ritual.yaml` and `weekly-refresh.yaml`. PO downstream burst aligns BC-2.12.003 to this canonical set.

### Workflow extension convention (F-PASS2-I2)

Two file extension conventions apply across brain-factory; the path disambiguates:

- **Lobster workflow files** at `plugins/brain-factory/workflows/` use **`.yaml`**. Examples: `ingest-url.yaml`, `daily-ritual.yaml`. yq-compatible; consumed by `bin/lobster-run`.
- **GitHub Action workflow templates** at `templates/github-action-templates/` use **`.yml`**. Examples: `daily-brief.yml`, `scale-test.yml`. GitHub's canonical extension; required for GH Actions runner detection.

Workflow files and Action templates may share base names (`scale-test.yaml` vs `scale-test.yml`); the directory path is the disambiguator. No file at either path uses the other extension.

## Consequences

**Positive:**
- Workflow logic is declarative and version-controlled (YAML, not Python/JS)
- Dependency graph is explicit and validated at parse time (cycle detection)
- Headless execution enables GH Actions to run the same workflows as interactive sessions
- The bash implementation is small enough to be read and understood by any engineer

**Negative:**
- No dynamic branching in v0.x (if/else on step output is not supported — workflows are linear DAGs)
- No retry logic at the workflow level (individual steps handle retries via api-retry.sh)

**Neutral:**
- LangChain and Temporal would provide more sophisticated orchestration but introduce dependencies incompatible with the bash-only v0.x stack (ADR-001)

## References

- SL-3 (user lock: "Ship a minimal bash Lobster runner in v0.x")
- phased-build-plan.md §5.7 (workflows directory structure)
- BC-2.12.001 (reads workflow YAML, executes in dependency order)
- BC-2.12.002 (exit code semantics)
- BC-2.12.003 (six workflow YAML files)
- BC-2.12.004 (headless execution)
- ADR-012 (scale-test workflow integration)
