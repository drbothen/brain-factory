---
artifact_type: story
story_id: STORY-027
epic_id: EPIC-06
title: "Content brief scaffold — publishing directories + voice avoid-list file"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 3
priority: P1
subsystems: [SS-08, SS-09]
behavioral_contracts: [BC-2.08.004, BC-2.09.005]
vps: [VP-020]
dependencies: [STORY-001]
blocks: [STORY-028, STORY-029, STORY-030]
inputs:
  - architecture/subsystems/SS-08-content-brief-writing.md
  - architecture/subsystems/SS-09-publishing-pipeline.md
  - behavioral-contracts/ss-08/BC-2.08.004.md
  - behavioral-contracts/ss-09/BC-2.09.005.md
input-hash: ""
# BC status: BC-2.08.004 + BC-2.09.005 assigned; status=draft per Spec-First Gate S-7.01
# Priority: P1 — prerequisite scaffold for all EPIC-06 stories
# Dependency rationale: STORY-001 (/brain:init) must exist so we know the init-time scaffold
# surface; this story extends init by wiring the publishing directory tree and voice-avoid-list
# file into the scaffold. Blocks STORY-028/029/030 because they write to paths created here.
---

# STORY-027: Content brief scaffold — publishing directories + voice avoid-list file

## Goal

Extend `/brain:init` to scaffold the three-bucket publishing directory tree
(`drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/`) and copy the
30-entry `rules/voice-avoid-list.txt` from the plugin template into the brain vault.
After this story `/brain:init` satisfies the structural preconditions for every
EPIC-06 skill.

## User Value

As a brain-factory operator, I want `/brain:init` to create the publishing directory
tree and install the voice avoid-list file so that my brief-writing and publishing
skills work out of the box without manual setup.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.09.005 | `drafts/{platform}/`, `to-publish/{platform}/`, `published/{platform}/` directory structure is maintained | P0 |
| BC-2.08.004 | Voice avoid-list (30 entries in `rules/voice-avoid-list.txt`) is enforced on brief drafts | P1 |

## Acceptance Criteria

### Publishing directory structure (BC-2.09.005)

**AC-001** — After `/brain:init` runs on a fresh directory, the three LinkedIn
publishing directories exist: `drafts/linkedin/`, `to-publish/linkedin/`, and
`published/linkedin/`.
(traces to BC-2.09.005 postcondition 1)

**AC-002** — The directories follow the `{state}/{platform}/` pattern: the state
bucket (`drafts/`, `to-publish/`, `published/`) is the parent; the platform name
(`linkedin`) is the child directory. Platform names are kebab-case lowercase.
(traces to BC-2.09.005 invariant 2)

**AC-003** — Running `/brain:init` a second time on an already-initialized brain does
not delete or overwrite the directory tree — idempotent execution leaves existing files
untouched.
(traces to BC-2.09.005 postcondition 1; BC-2.01.001 init-idempotency invariant)

### Voice avoid-list file (BC-2.08.004)

**AC-004** — After `/brain:init`, `rules/voice-avoid-list.txt` exists in the brain
vault and was copied from `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`.
(traces to BC-2.08.004 precondition 1)

**AC-005** — `rules/voice-avoid-list.txt` contains exactly 30 entries at v0.1 release:
one term or phrase per line, no blank lines, no comment lines.
(traces to BC-2.08.004 postcondition 1, postcondition 2)

**AC-006** — The avoid-list is operator-editable: the file is not write-protected.
The hook reads it fresh on every invocation, so operator customizations take effect
immediately without re-running init.
(traces to BC-2.08.004 invariant 3)

**AC-007** — If `rules/voice-avoid-list.txt` already exists (operator has customized
it), re-running `/brain:init` does NOT overwrite it with the default list.
(traces to BC-2.08.004 invariant 1; init idempotency)

## Tasks

1. **[stub]** In `plugins/brain-factory/skills/init/SKILL.md`, add stubs for the two
   new init steps: "scaffold publishing directories" and "copy voice avoid-list".
   Procedure body for new steps is empty at this point (later tasks fill them).

2. **[stub]** Create `plugins/brain-factory/rules/voice-avoid-list.txt` in the plugin
   template with exactly 30 entries. Seed entries (do not expand):
   "utilize", "leverage", "synergy", "game-changer", "paradigm shift", "deep dive",
   "holistic", "circle back", "bandwidth", "move the needle", "low-hanging fruit",
   "best practices", "thought leader", "disruptive", "scalable", "ecosystem",
   "robust", "seamless", "cutting-edge", "innovative", "transformative", "empower",
   "journey", "unlock potential", "deliverables", "streamline", "value-add",
   "actionable insights", "going forward", "proactive".
   Verify: `wc -l rules/voice-avoid-list.txt` = 30. (Exactly 30 lines, none blank.)

3. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/integration.bats`:
   - `"init: publishing directories created (BC-2.09.005)"` — runs init on a temp dir;
     asserts `drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/` all exist.
   - `"init: voice-avoid-list.txt has exactly 30 entries (BC-2.08.004)"` — runs init;
     asserts `rules/voice-avoid-list.txt` exists; `wc -l` = 30; no blank lines.
   - `"init: idempotent — no overwrite of existing avoid-list (BC-2.08.004 AC-007)"` —
     writes a custom avoid-list; re-runs init; asserts custom content preserved.
   - `"init: idempotent — no overwrite of existing publishing dirs (BC-2.09.005 AC-003)"` —
     creates a file inside `drafts/linkedin/`; re-runs init; asserts file still present.
   Run bats — confirm all 4 tests fail (Red Gate confirmed).

4. **[impl]** Implement the two new init steps in the `init` skill:
   - Step N (publishing dirs): `mkdir -p drafts/linkedin to-publish/linkedin published/linkedin`
     — guarded by `if [[ ! -d drafts/linkedin ]]` to support idempotency.
   - Step N+1 (voice avoid-list): `if [[ ! -f rules/voice-avoid-list.txt ]]; then
     cp "${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt" rules/voice-avoid-list.txt; fi`
     — copy only if not already present.

5. **[green]** Run `bats tests/integration.bats -f "init:"` — all 4 tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Fresh `/brain:init` | `drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/` present | happy-path | BC-2.09.005 canonical test vector |
| Fresh `/brain:init` | `rules/voice-avoid-list.txt` has exactly 30 lines | happy-path | BC-2.08.004 canonical test vector |
| Second `/brain:init` after custom avoid-list written | Custom avoid-list preserved | idempotency | BC-2.08.004 AC-007 |
| Second `/brain:init` after file placed in `drafts/linkedin/` | File still present | idempotency | BC-2.09.005 AC-003 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-020 | LinkedIn directories present after init | `tests/integration.bats` |
| (no VP — P1) | Voice avoid-list 30 entries | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-08-content-brief-writing.md` and
`architecture/subsystems/SS-09-publishing-pipeline.md`:

1. The publishing directory structure uses the `{state}/{platform}/` pattern — state
   bucket first, platform second. Do NOT invert to `{platform}/{state}/`.

2. `rules/voice-avoid-list.txt` lives in the brain's `rules/` directory (not in
   `.brain/` or `wiki/`). The engine ships the template at
   `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`; the init skill copies it.
   The hook reads the brain's copy — never the engine's template directly.

3. The `validate-voice-avoid-list.sh` hook fires on `briefs/content/*-draft.md` writes
   only (not all of `briefs/`). This story does NOT wire the hook — that is EPIC-02
   (STORY-010). This story only scaffolds the file the hook reads.

4. Platform names are kebab-case lowercase: `linkedin`, not `LinkedIn`. Enforced by
   the `enforce-kebab-case.sh` hook (EPIC-02).

5. The init skill must be idempotent. Use guard conditions (`-d`, `-f` checks) before
   creating directories or copying files — never `rm -rf` + recreate.

**Forbidden dependencies:**
- `init` skill: must NOT read `briefs/` or `wiki/` during scaffolding step.
- `init` skill: must NOT call any LinkedIn API — this is directory creation only.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `mkdir` / `cp` | POSIX | Directory creation and file copy |
| `wc` | POSIX | Line count assertion in test |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/init/SKILL.md` | Modify | Add two new Procedure steps (publishing dirs, voice avoid-list) |
| `plugins/brain-factory/rules/voice-avoid-list.txt` | Create | 30-entry default avoid-list |
| `plugins/brain-factory/tests/integration.bats` | Modify | Add 4 failing-then-passing init test blocks |

Files NOT to modify: any file under `.factory/`, any other skill SKILL.md, any other
existing bats test file.

## Previous Story Intelligence

N/A — first story in EPIC-06. However, note that STORY-001 (`/brain:init` scaffold)
established the init skill structure. Confirm the Procedure section numbering in
`init/SKILL.md` before adding new steps so step numbers remain contiguous and ordered.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,400 |
| SS-08 subsystem design | ~900 |
| SS-09 subsystem design | ~900 |
| BC-2.08.004 file | ~600 |
| BC-2.09.005 file | ~600 |
| Existing `init/SKILL.md` (for step numbering) | ~1,500 |
| Existing `integration.bats` (for test context) | ~1,500 |
| **Total** | **~8,400** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Wiring `validate-voice-avoid-list.sh` hook into hooks.json — EPIC-02 (STORY-010).
- The `/brain:brief` skill itself — STORY-028.
- The `/brain:write` skill — STORY-029.
- `/brain:publish-content` — STORY-030.
- Additional platform directories (Medium, etc.) — future extension.

## Anchors

- BC-2.08.004: `behavioral-contracts/ss-08/BC-2.08.004.md`
- BC-2.09.005: `behavioral-contracts/ss-09/BC-2.09.005.md`
- SS-08: `architecture/subsystems/SS-08-content-brief-writing.md`
- SS-09: `architecture/subsystems/SS-09-publishing-pipeline.md`
- VP-020: `architecture/verification-properties/VP-020-publish-state-machine.md`
- STORY-001: `stories/stories/STORY-001.md` (init skill — predecessor)
