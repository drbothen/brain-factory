---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.001: `/brain:init` scaffolds complete brain folder structure in a fresh directory

## Description

`/brain:init` is the first skill an operator runs to create a new brain. It scaffolds the complete target-brain folder structure — `sources/`, `wiki/`, `inbox/`, `briefs/`, `.brain/`, `.github/workflows/`, CLAUDE.md — in the working directory. It must work from a directory that is a git repository (already initialized with `git init -b main` or equivalent) but has no brain structure yet. **If `.brain/` already exists, `/brain:init` HARD-FAILS with E-INIT-002 (exit 2). It does NOT idempotently re-scaffold — that is by design to protect existing brain state.** The operator must run `/brain:upgrade-brain` to modify an existing brain (per SS-01 §Architectural Decisions). This BC defines the complete structural contract: exactly what directories and files exist after a successful run in a fresh directory.

## Preconditions

1. The working directory is a git repository (`git rev-parse --git-dir` exits 0).
2. The working directory does NOT already contain a `.brain/` directory. If `.brain/` IS present, the precondition fails and the skill HARD-FAILS with E-INIT-002 before any writes (not idempotent re-scaffold — see EC-002 and SS-01 §Architectural Decisions §Already-initialized brain: hard-fail E-INIT-002).
3. `${CLAUDE_PLUGIN_ROOT}` resolves to the brain-factory plugin installation directory.
4. Node 20+ is available in PATH (required for Defuddle and `scripts/run-skill.mjs`).
5. `bash`, `jq`, `yq`, `awk` are available in PATH.

## Postconditions

1. The following directory structure exists relative to the working directory:
   - `sources/ai/`, `sources/health/`, `sources/psychology/`, `sources/productivity/`, `sources/business/`, `sources/books/`, `sources/podcasts/` (7 default topic categories per brief §Scalability Design Principles §3)
   - `wiki/concepts/`, `wiki/people/`, `wiki/frameworks/`, `wiki/syntheses/`, `wiki/observations/`, `wiki/questions/` (6 wiki types per plan.md §3.4)
   - `inbox/`
   - `briefs/daily/`, `briefs/weekly/`, `briefs/monthly/`, `briefs/content/`, `briefs/decisions/`, `briefs/research/` (6 briefs subdirs, including the brief-introduced `research/` subdir)
   - `.brain/logs/`, `.brain/STATE.md` (initialized with six-dimensional convergence tracking)
   - `.github/workflows/` (6 core GH Action template files from v0.1 set)
   - `CLAUDE.md` (brain CLAUDE.md from `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-template.md`)
   - `.brain/policies.yaml` (initialized with 10 baseline policies from `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml`)
   - `.brain/manifest.json` (initialized with empty sources array and schema that supports `chunks` array and `embeddings_model: null`)
   - `wiki/index.md` (initialized empty index)
   - `wiki/log.md` (initialized empty ingest log)
   - `rules/voice-avoid-list.txt` (30-entry voice avoid-list from `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`)
2. All template files are sourced via `${CLAUDE_PLUGIN_ROOT}/templates/...` — no hardcoded paths.
3. Completion wall-clock time is under 5 minutes (see BC-2.01.002 for the SLA contract).
4. A success confirmation is printed to the user with the brain root path.

## Invariants

1. The engine plugin files are never modified. Only the target working directory receives writes.
2. Template resolution uses `${CLAUDE_PLUGIN_ROOT}/templates/...` at every callsite.
3. Every wiki page template written during init includes `embedding_status: pending` in frontmatter (see BC-2.01.004).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Working directory is not a git repo | Exit with E-INIT-001; display "brain:init requires a git repository — run `git init -b main` first" |
| EC-002 | `.brain/` directory already exists | HARD-FAIL: exit 2 with E-INIT-002. Message: "brain already initialized at <path>. Use `/brain:upgrade-brain` to modify an existing brain." No files are created or overwritten. This is intentional — `/brain:init` is NOT idempotent (per SS-01 §Architectural Decisions §Already-initialized brain: hard-fail E-INIT-002). |
| EC-003 | Node 20+ not in PATH | Exit with E-INIT-003; display "Node 20+ is required. Install from nodejs.org or via nvm." |
| EC-004 | `${CLAUDE_PLUGIN_ROOT}` does not resolve | Exit with E-INIT-004; display "Plugin root not found — reinstall brain-factory." |
| EC-005 | Working directory has conflicting files (e.g., a `wiki/` directory that is not a brain wiki) | Exit with E-INIT-005; display "Conflict: <path> already exists. Remove it or init in a clean directory." |
| EC-006 | `jq` or `yq` not in PATH | Exit with E-INIT-006; display "jq and yq are required. Install via your package manager." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Fresh git repo, all prerequisites satisfied | All 25+ directories/files created; exit 0; success message printed | happy-path |
| Working directory has no `.git/` | E-INIT-001 message; exit 2 | error |
| `.brain/` already exists | E-INIT-002 message; exit 2 | error |
| Node 20 absent from PATH | E-INIT-003 message; exit 2 | error |
| `wiki/` already exists as non-brain directory | E-INIT-005 message; exit 2 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | All postcondition directories exist after successful run | bats (integration.bats) |
| VP-014 | Error cases produce correct E-INIT-NNN codes with non-zero exit | bats (integration.bats) |
| VP-014 | No engine files modified during init | bats (integration.bats) file-integrity assertion |
| VP-014 | `${CLAUDE_PLUGIN_ROOT}` reference present at all template callsites | shellcheck + grep |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-001 ("Brain Initialization and Scaffold") per brief §Scope §Phase 0/1 primitives skill #1 (`/brain:init`). This BC defines the complete structural postcondition of the init skill, which is exactly what CAP-001: Brain Initialization and Scaffold covers. |
| L2 Domain Invariants | N/A (L2 domain spec not yet produced — Phase 1a) |
| Architecture Module | SS-01: Brain Initialization and Scaffold |
| Stories | [filled by story-writer — Phase 2] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (skill #1), §Success Criteria §v0.1 ship gate |

## Related BCs

- BC-2.01.002 — depends on (5-minute SLA for init completion)
- BC-2.01.003 — related to (non-git-repo rejection)
- BC-2.01.004 — composes with (embedding_status written by init templates)
- BC-2.06.004 — composes with (7 source topic categories scaffolded here)

## Architecture Anchors

- `architecture/subsystems/SS-01-brain-init-scaffold.md`

## Story Anchor

[S-TBD] — [filled by story-writer — Phase 2]

## VP Anchors

- VP-014 — Brain init scaffold completeness (bats integration.bats)
