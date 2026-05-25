---
artifact_type: story
story_id: STORY-002
epic_id: EPIC-01
title: "/brain:init core scaffold — directory structure, templates, manifest.json, policies.yaml"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-01, SS-06]
behavioral_contracts: [BC-2.01.001, BC-2.01.004, BC-2.06.003, BC-2.06.004]
vps: [VP-014, VP-012]
dependencies: [STORY-001]
blocks: [STORY-003, STORY-004]
inputs:
  - architecture/subsystems/SS-01-brain-init-scaffold.md
  - architecture/subsystems/SS-06-source-layer-immutability.md
  - behavioral-contracts/ss-01/BC-2.01.001.md
  - behavioral-contracts/ss-01/BC-2.01.004.md
  - behavioral-contracts/ss-06/BC-2.06.003.md
  - behavioral-contracts/ss-06/BC-2.06.004.md
  - architecture/verification-properties/VP-014-brain-init-scaffold.md
  - architecture/verification-properties/VP-012-manifest-atomicity.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-002: /brain:init core scaffold — directory structure, templates, manifest.json, policies.yaml

## Goal

Implement the `/brain:init` skill's core happy path: scaffold the complete brain vault
directory structure in a fresh git-initialized directory, write all template files with
`embedding_status: pending` in frontmatter, initialize `manifest.json` with the canonical
schema (including `chunks: []`, `embeddings_model: null`, `last_ingest` field), write
`policies.yaml` with 10 baseline policies, and write 7 default source topic directories.
Error paths (non-git-repo, existing `.brain/`, missing tools) are in STORY-003.

## User Value

As an operator running `/brain:init` in a fresh git repo for the first time, I want the
complete brain vault folder structure and initial files created in one command, so I
immediately have a working brain ready for ingest.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.01.001 | `/brain:init` scaffolds complete brain folder structure | P0 |
| BC-2.01.004 | `/brain:init` writes `embedding_status: pending` in every wiki page template | P0 |
| BC-2.06.003 | `manifest.json` records `last_ingest` timestamps per source | P0 |
| BC-2.06.004 | Sources directory uses 7 default topic categories scaffolded by `/brain:init` | P1 |

## Acceptance Criteria

**AC-001** — After a successful `/brain:init` run, all of the following directories exist
in the target working directory: `sources/ai/`, `sources/health/`, `sources/psychology/`,
`sources/productivity/`, `sources/business/`, `sources/books/`, `sources/podcasts/`,
`wiki/concepts/`, `wiki/people/`, `wiki/frameworks/`, `wiki/syntheses/`,
`wiki/observations/`, `wiki/questions/`, `inbox/`, `briefs/daily/`, `briefs/weekly/`,
`briefs/monthly/`, `briefs/content/`, `briefs/decisions/`, `.brain/logs/`,
`.github/workflows/`, `rules/`.
(traces to BC-2.01.001 postcondition 1)

**AC-002** — After init, the following files exist: `.brain/manifest.json`,
`.brain/STATE.md`, `.brain/policies.yaml`, `wiki/index.md`, `wiki/log.md`, `CLAUDE.md`,
`rules/voice-avoid-list.txt`.
(traces to BC-2.01.001 postcondition 1)

**AC-003** — `.brain/manifest.json` is valid JSON with the canonical schema:
`"version": "1"`, `"sources": {}`, `"last_updated": "<ISO8601>"`,
`"embeddings_model": null`, `"chunks": []` at the top level.
(traces to BC-2.01.004 postconditions 2–3)

**AC-004** — `.brain/policies.yaml` contains exactly 10 baseline policy entries
(as defined in `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml`).
(traces to BC-2.01.001 postcondition 1)

**AC-005** — Every wiki page type template written during init (one per type in
`wiki/{type}/`) contains `embedding_status: pending` in YAML frontmatter. Running
`yq eval '.embedding_status' <file>` on each returns `"pending"`.
(traces to BC-2.01.004 postcondition 1)

**AC-006** — The 7 source topic directories exist: `sources/ai/`, `sources/health/`,
`sources/psychology/`, `sources/productivity/`, `sources/business/`, `sources/books/`,
`sources/podcasts/`. Each is empty at init time.
(traces to BC-2.06.004 postconditions 1–2)

**AC-007** — `CLAUDE.md` is sourced from
`${CLAUDE_PLUGIN_ROOT}/templates/claude-md-template.md` — not hardcoded inline content.
The file must contain the correct brain structure documentation.
(traces to BC-2.01.001 postcondition 2; BC-2.14.003 invariant 2)

**AC-008** — After init, the 6 core GitHub Action template YAML files exist in
`.github/workflows/` (sourced from
`${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/`).
(traces to BC-2.01.001 postcondition 1)

**AC-009** — `rules/voice-avoid-list.txt` contains exactly 30 entries, sourced from
`${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`.
(traces to BC-2.01.001 postcondition 1)

**AC-010** — A manifest entry written by ingest (tested via `ingest-source` bats
integration fixture) contains `last_ingest` set to the same ISO8601 value as
`ingested_at` on first ingest, and `last_ingest` is non-null.
(traces to BC-2.06.003 postconditions 1–2; BC-2.06.003 invariant 1)

**AC-011** — No files are written under `${CLAUDE_PLUGIN_ROOT}/` during init. Only
the target working directory receives writes. Verified by comparing mtime of plugin
directory files before and after init: no changes.
(traces to BC-2.01.001 invariant 1; BC-2.14.003 postcondition 1)

**AC-012** — Template resolution at every callsite uses `${CLAUDE_PLUGIN_ROOT}/templates/...`.
Running `grep -r '\.claude/templates' plugins/brain-factory/skills/init/` returns no output.
(traces to BC-2.01.001 invariant 2; BC-2.14.003 invariant 2)

## Tasks

1. **[stub]** Create `plugins/brain-factory/skills/init/` directory and stub `run.sh`
   (scaffold of: read-cwd, check-git, check-existing-brain, check-deps, scaffold-dirs,
   copy-templates) — all logic paths are `todo` stubs that `exit 0` or emit placeholder
   JSON.

2. **[failing test — Red Gate]** Write `tests/integration.bats` (per SS-01 test surface)
   with all VP-014 assertions in failing state:
   - `@test "/brain:init: all postcondition directories exist in fresh brain"` — fails
     because `run.sh` is a stub.
   - `@test "/brain:init: embedding_status: pending in all init wiki templates"` — fails.
   - `@test "/brain:init: plugin dir unmodified after init"` — fails.
   Also write `tests/skills.bats` with VP-012 Group 2 assertions for `last_ingest` field
   (fails because ingest skill stub doesn't write manifest yet; used as anchor for EPIC-03).

3. **[impl]** Implement directory scaffold logic in `run.sh`: create all 25+ directories
   using `mkdir -p`. Use `${BRAIN_ROOT:-$PWD}` as the target (cwd-based per SS-01
   §Architectural Decisions §Public CLI: zero arguments).

4. **[impl]** Implement template copy logic: copy each file from
   `${CLAUDE_PLUGIN_ROOT}/templates/` to its target location in the brain. Specifically:
   `claude-md-template.md` → `CLAUDE.md`; 6 wiki type templates → `wiki/{type}/`
   (each must contain `embedding_status: pending`); `policies.yaml` → `.brain/policies.yaml`;
   6 GH Action templates → `.github/workflows/`; `voice-avoid-list.txt` → `rules/`.

5. **[impl]** Implement `manifest.json` initialization: write to `.brain/manifest.json`
   the canonical schema with `"version":"1"`, `"sources":{}`, `"last_updated":"<ISO8601>"`,
   `"embeddings_model":null`, `"chunks":[]`. Use `date -u +%Y-%m-%dT%H:%M:%SZ` for the
   timestamp.

6. **[impl]** Implement `STATE.md` initialization: copy from
   `${CLAUDE_PLUGIN_ROOT}/templates/state-md-template.md` to `.brain/STATE.md`.

7. **[impl]** Create all required template source files in `plugins/brain-factory/templates/`:
   `claude-md-template.md`, wiki type templates for each of the 6 types (each with
   `embedding_status: pending` in frontmatter), `policies.yaml` (10 baseline policies),
   `state-md-template.md`, `voice-avoid-list.txt` (30 entries). These are data files,
   not logic.

8. **[impl]** Create 6 stub GitHub Action YAML templates in
   `plugins/brain-factory/templates/github-action-templates/`: one per core workflow
   (daily-brain.yml, weekly-brain.yml, ingest-rss.yml, ingest-bookmarks.yml,
   brain-health-check.yml, adversary-review.yml). Content-stub only; full YAML in EPIC-07.

9. **[green]** Run `bats tests/integration.bats` — VP-014 assertions pass (directories
   exist, templates have `embedding_status: pending`, plugin dir unmodified).

10. **[green]** Run `shellcheck plugins/brain-factory/skills/init/run.sh`.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Fresh git repo; run init | All 25+ dirs/files created; exit 0 | happy-path | BC-2.01.001 |
| `ls sources/` after init | ai health psychology productivity business books podcasts | happy-path | BC-2.06.004 |
| `yq eval '.embedding_status' wiki/concepts/*.md` | `pending` | happy-path | BC-2.01.004 |
| `jq '.embeddings_model' .brain/manifest.json` | `null` | happy-path | BC-2.01.004 postcondition 2 |
| `jq '.chunks' .brain/manifest.json` | `[]` | happy-path | BC-2.01.004 postcondition 3 |
| `jq '.policies \| length' .brain/policies.yaml` (via yq) | `10` | happy-path | BC-2.01.001 postcondition 1 |
| `grep -c '${CLAUDE_PLUGIN_ROOT}' skills/init/run.sh` | positive count | happy-path | BC-2.01.001 invariant 2 |
| Find any mtime change under `${CLAUDE_PLUGIN_ROOT}` after init | zero changes | happy-path | BC-2.01.001 invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-014 | All postcondition dirs exist after init | `tests/integration.bats` |
| VP-014 | `embedding_status: pending` in wiki templates | `tests/integration.bats` |
| VP-014 | Engine dir not modified | `tests/integration.bats` |
| VP-012 (Group 2) | `last_ingest` field present, ISO8601 | `tests/skills.bats` (stub; completed in EPIC-03) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-01-brain-init-scaffold.md`:

1. `/brain:init` is a zero-argument skill. The `run.sh` uses `${BRAIN_ROOT:-$PWD}` as
   its target — the bats harness `cd`s into the temp brain dir before invoking it. No
   `--target` flag in the public interface.
2. Already-initialized brain check (`.brain/` exists) must be the SECOND check after
   git-repo check — done in STORY-003. This story covers only the happy path.
3. Template path discipline: every template read in `run.sh` uses
   `"${CLAUDE_PLUGIN_ROOT}/templates/..."`. Never `.claude/templates/`. Never hardcoded
   absolute paths. shellcheck must pass with no SC warnings.

From `architecture/subsystems/SS-06-source-layer-immutability.md`:

4. `manifest.json` initial schema must include `chunks: []` from v0.1 (BC-2.06.002,
   forward-compatibility locked). Write-once; no partial-write. AC-003 verifies this.
5. `last_ingest` field in each manifest source entry must be an ISO8601 string matching
   `ingested_at` on first write. This is enforced by the ingest pipeline (EPIC-03); this
   story creates the initial empty manifest with the correct schema to receive entries.

**Forbidden dependencies:** `skills/init/run.sh` must NOT `source` or call any code from
`plugins/brain-factory/hooks/`. The init skill is pure filesystem I/O; hook enforcement
fires via the PostToolUse mechanism (EPIC-02), not via direct skill invocation.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | phased-build-plan.md §1 |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `jq` | 1.7+ (latest: 1.8.1) | BC-2.01.001 precondition 5; manifest validation |
| `yq` | 4.x+ (mikefarah/yq, NOT kislyuk/yq; latest: 4.53.2) — `yq eval` | BC-2.01.004 test vector; frontmatter assertions |
| `git` | any modern | BC-2.01.001 precondition 1 (git-repo check in STORY-003) |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

> **yq disambiguation:** `yq` = mikefarah/yq (Go-based). On Ubuntu, `apt install yq` installs the WRONG tool (kislyuk/yq). Use `snap install yq` or install from GitHub releases.

No Node.js required in this story (Defuddle is for ingest, not init).

## File Structure Requirements

Files to create:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/init/run.sh` | Create | Core scaffold logic; `#!/usr/bin/env bash`; `set -euo pipefail` |
| `plugins/brain-factory/skills/init/SKILL.md` | Replace stub | Full SKILL.md with Iron Law, Red Flags, Announce-at-Start, Procedure, Quality Bar, Output |
| `plugins/brain-factory/templates/claude-md-template.md` | Create | Brain CLAUDE.md template |
| `plugins/brain-factory/templates/wiki-concept-template.md` | Create | Frontmatter includes `embedding_status: pending` |
| `plugins/brain-factory/templates/wiki-person-template.md` | Create | Frontmatter includes `embedding_status: pending` |
| `plugins/brain-factory/templates/wiki-framework-template.md` | Create | Frontmatter includes `embedding_status: pending` |
| `plugins/brain-factory/templates/wiki-synthesis-template.md` | Create | Frontmatter includes `embedding_status: pending` |
| `plugins/brain-factory/templates/wiki-observation-template.md` | Create | Frontmatter includes `embedding_status: pending` |
| `plugins/brain-factory/templates/wiki-question-template.md` | Create | Frontmatter includes `embedding_status: pending` |
| `plugins/brain-factory/templates/policies.yaml` | Create | 10 baseline policies |
| `plugins/brain-factory/templates/state-md-template.md` | Create | Six-dimensional convergence tracking template |
| `plugins/brain-factory/rules/voice-avoid-list.txt` | Create | 30-entry voice avoid-list |
| `plugins/brain-factory/templates/github-action-templates/*.yml` (×6) | Create | Stub YAML; final content in EPIC-07 |
| `plugins/brain-factory/tests/integration.bats` | Create | VP-014 assertions (Red Gate → Green) |
| `plugins/brain-factory/tests/skills.bats` | Create | VP-012 Group 2 anchor (stub; completed EPIC-03) |

Files NOT to modify: `.factory/` tree, `docs/planning/`, STORY-001 files.

## Previous Story Intelligence

STORY-001 establishes the plugin directory skeleton and 13 stub hook scripts. This story
builds the init skill and templates into that skeleton. Key carryover:
- The stub SKILL.md for `skills/init/SKILL.md` created in STORY-001 is REPLACED here
  with a full implementation.
- `tests/upgrade.bats` already exists from STORY-001; do not modify it.
- All template reads in `run.sh` must use `${CLAUDE_PLUGIN_ROOT}` — the same invariant
  enforced in STORY-001's manifest files applies here.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-01 subsystem design | ~1,200 |
| SS-06 subsystem design | ~1,000 |
| BC-2.01.001 (long — full postconditions) | ~1,500 |
| BC-2.01.004, BC-2.06.003, BC-2.06.004 | ~2,000 |
| VP-014 (with bats test code) | ~2,500 |
| VP-012 | ~2,000 |
| STORY-001 (previous context) | ~1,000 |
| Test output context | ~1,000 |
| **Total** | **~15,200** |

Well within 20% of a 200K-token context window. No split required.

## Out of Scope

- `/brain:init` error handling (non-git-repo, existing `.brain/`, missing deps) — STORY-003
- SLA timer assertion — STORY-003
- `briefs/research/` subdirectory — STORY-003
- `/brain:health` skill — STORY-004
- Source immutability hash enforcement (validate-source-immutability.sh) — EPIC-02
- Manifest atomic write helper (`hooks/lib/manifest-write.sh`) — EPIC-03

## Anchors

- BC-2.01.001: `behavioral-contracts/ss-01/BC-2.01.001.md`
- BC-2.01.004: `behavioral-contracts/ss-01/BC-2.01.004.md`
- BC-2.06.003: `behavioral-contracts/ss-06/BC-2.06.003.md`
- BC-2.06.004: `behavioral-contracts/ss-06/BC-2.06.004.md`
- VP-014: `architecture/verification-properties/VP-014-brain-init-scaffold.md`
- VP-012: `architecture/verification-properties/VP-012-manifest-atomicity.md`
- SS-01: `architecture/subsystems/SS-01-brain-init-scaffold.md`
- SS-06: `architecture/subsystems/SS-06-source-layer-immutability.md`
- phased-build-plan §5.7–§5.8
