---
artifact_type: story
story_id: STORY-021
epic_id: EPIC-04
title: "/brain:rename-page atomic backlink propagation with existence and slug guards"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-05]
behavioral_contracts: [BC-2.05.003, BC-2.05.004]
vps: [VP-018]
dependencies: [STORY-020]
blocks: []
inputs:
  - architecture/subsystems/SS-05-wiki-layer.md
  - behavioral-contracts/ss-05/BC-2.05.003.md
  - behavioral-contracts/ss-05/BC-2.05.004.md
  - architecture/verification-properties/VP-018-wiki-layer-integrity.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.05.003 (atomic rename + backlink propagation) and BC-2.05.004
# (existence check before any writes) are the happy-path and the error-path of the same
# skill entry point. They MUST be in the same story — BC-2.05.004 defines the first guard
# that BC-2.05.003 depends on. Splitting them would require two stories that both touch
# the skills/rename-page/SKILL.md file, creating a serialization dependency with no user
# value.
---

# STORY-021: `/brain:rename-page` atomic backlink propagation with existence and slug guards

## Goal

Deliver the `/brain:rename-page <old-slug> <new-slug>` skill: the ONLY permitted path
for renaming a wiki page. The skill renames the file, performs a full backlink sweep to
update all `[[old-slug]]` references to `[[new-slug]]`, updates `wiki/index.md` and
`wiki/log.md`, and commits all changes atomically. Pre-rename guards reject non-existent
old slugs, already-existing new slugs, and non-kebab-case new slugs before any filesystem
changes occur.

## User Value

As a brain operator, I want to run `/brain:rename-page ai-agents ai-agent-systems` and
have the wiki page renamed, all backlinks updated, and the index/log refreshed in a single
atomic commit — so that no wiki page ever points to a stale slug, and so that I cannot
accidentally rename to a slug that already exists.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.05.003 | `/brain:rename-page` renames wiki page and propagates all backlinks atomically | P0 |
| BC-2.05.004 | `/brain:rename-page` rejects rename if old slug does not exist | P0 |

## Acceptance Criteria

### Atomic Rename + Backlink Propagation (BC-2.05.003)

**AC-001** — On a successful rename, `wiki/{type}/old-slug.md` is renamed to
`wiki/{type}/new-slug.md`. All pages containing `[[old-slug]]` are updated to
`[[new-slug]]`. `wiki/index.md` entry is updated. `wiki/log.md` receives a rename event
entry.
(traces to BC-2.05.003 postconditions 1–4)

**AC-002** — The skill exits 0 with a JSON summary:
`{"renamed": "old-slug → new-slug", "backlinks_updated": N}`.
`N` is the exact count of pages that had `[[old-slug]]` updated.
(traces to BC-2.05.003 postcondition 5)

**AC-003** — All changes (file rename, backlink edits, index update, log update) are
committed atomically as a single git commit with message:
`rename: <old-slug> → <new-slug>`. If any step fails after the rename has started,
`git checkout .` is called before reporting failure, leaving the repository in a clean
pre-rename state.
(traces to BC-2.05.003 invariants 1–2)

**AC-004** — When there are 0 backlinks referencing `[[old-slug]]`, the rename proceeds
normally. The summary reports `backlinks_updated: 0`. Exit 0.
(traces to BC-2.05.003 edge case EC-004)

**AC-005** — Backlink detection uses index-first lookup (O(n)), not a full-wiki grep
scan. The skill reads the backlinks section of `wiki/index.md` to identify which pages
reference `[[old-slug]]`, then applies targeted `sed -i` substitutions to those pages
only.
(traces to BC-2.05.003 invariant 3)

**AC-006** — `skills/rename-page/SKILL.md` is shellcheck-clean and `shfmt -d -i 2`
produces no diff. The git commit message does NOT contain `Co-Authored-By: Claude` or
any robot emoji.
(traces to CLAUDE.md §Conventions; CLAUDE.md §Git Workflow)

### Existence Check Guard (BC-2.05.004)

**AC-007** — As its first operation, `/brain:rename-page` checks that
`wiki/{type}/old-slug.md` exists in any wiki type directory. If the old slug does not
exist, the skill exits 2 immediately with E-RENAME-001:
`"Page <old-slug> not found."`. No file system changes are made.
(traces to BC-2.05.004 postconditions 1–2; invariant 1)

**AC-008** — The existence check is the first guard, executed BEFORE any slug validation
or new-slug collision check. This prevents misleading error messages when the operator
has mistyped the old slug.
(traces to BC-2.05.004 invariant 1)

### New-Slug Collision and Format Guards (BC-2.05.003)

**AC-009** — If `wiki/{type}/new-slug.md` already exists, the skill exits 2 with
E-RENAME-002: `"Page <new-slug> already exists. Choose a different slug."`.
No file system changes are made.
(traces to BC-2.05.003 precondition 2; edge case EC-002)

**AC-010** — If `new-slug` is not a valid kebab-case string (contains uppercase letters,
spaces, underscores, or special characters other than hyphens), the skill exits 2 with
E-NAMING-001. No file system changes are made.
(traces to BC-2.05.003 precondition 3; edge case EC-003)

## Tasks

1. **[stub]** Create stub `skills/rename-page/SKILL.md` in `plugins/brain-factory/skills/`
   with correct frontmatter and canonical 6-section structure. Procedure section contains
   a single numbered step: "Not yet implemented." Iron Law: "Every wiki page rename goes
   through `/brain:rename-page`. Direct `mv` is forbidden."

2. **[failing test — Red Gate]** Add failing bats tests in `tests/skills.bats`:
   - Happy-path rename with 5 backlinks: file renamed; 5 backlinks updated; index updated;
     log updated; summary has `backlinks_updated: 5`; exit 0.
   - Zero backlinks: rename proceeds; `backlinks_updated: 0`; exit 0.
   - Old slug does not exist: E-RENAME-001; exit 2; no fs changes (assert with
     `git status` clean).
   - New slug already exists: E-RENAME-002; exit 2; no fs changes.
   - Non-kebab-case new slug: E-NAMING-001; exit 2; no fs changes.
   - Rollback on mid-rename failure (mock git commit to fail): repo is in clean state
     after error; exit 2.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `skills/rename-page/SKILL.md` skill body:
   - Guard 1: old-slug existence check (AC-007).
   - Guard 2: new-slug collision check (AC-009).
   - Guard 3: new-slug kebab-case validation (AC-010).
   - Backlink detection via index-first lookup on `wiki/index.md` backlinks section (AC-005).
   - File rename with `git mv` (AC-001).
   - Backlink sweep via `sed -i` on identified backlink files (AC-001).
   - `wiki/index.md` entry update (AC-001).
   - `wiki/log.md` rename event append (AC-001).
   - Atomic commit with canonical message format (AC-003).
   - On any failure after rename started: `git checkout .` + exit 2 with structured error.
   - Emit `wiki.page.renamed` structured event via `hook-event-emit.sh` (AC-006).

4. **[green]** Run `bats tests/skills.bats` — all rename-page tests pass.

5. **[green]** Run `shellcheck skills/rename-page/SKILL.md` (if the skill body contains
   bash inline code) and verify git commit message format in the test fixture.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Rename `ai-agents` → `ai-agent-systems`; 5 backlinks | All 5 updated; file renamed; index updated; exit 0 | happy-path | BC-2.05.003 |
| Rename with 0 backlinks | Rename succeeds; `backlinks_updated: 0`; exit 0 | happy-path | BC-2.05.003 EC-004 |
| Old slug does not exist | E-RENAME-001; exit 2; no fs changes | error | BC-2.05.004 |
| New slug already exists | E-RENAME-002; exit 2; no fs changes | error | BC-2.05.003 EC-002 |
| Non-kebab-case new slug (`AI_Agents`) | E-NAMING-001; exit 2; no fs changes | error | BC-2.05.003 EC-003 |
| Mid-rename failure (mock) | Repo clean after rollback; exit 2 | edge-case | BC-2.05.003 invariant 2 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-018 | All backlinks updated on rename | `tests/skills.bats` |
| VP-018 | Rename atomic (no partial state on failure) | `tests/skills.bats` (rollback test) |
| VP-018 | Non-existent old slug → exit 2 before any changes | `tests/skills.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-05-wiki-layer.md` (rename atomicity section):

1. The rename implementation uses `git mv` (not `mv`) for the file rename step. This
   ensures the operation is git-tracked and contributes to the atomic commit.
2. Backlink sweep uses `sed -i "s/\[\[old-slug\]\]/[[new-slug]]/g"` applied only to
   pages identified by index-first lookup. Full-wiki grep scanning is forbidden.
3. All changes (git mv + sed backlinks + index update + log update) are staged in a
   single `git add -A` followed by `git commit`. A two-commit approach (rename then
   backlinks) is a violation of BC-2.05.003 invariant 1.
4. Rollback on failure: any error after `git mv` executes calls `git checkout .` before
   reporting. The skill MUST NOT leave the repository in partial-rename state.
5. Structured event emitted: `wiki.page.renamed` — must be pre-registered in
   `scripts/event-catalog.json`.
6. The skill MUST NOT bypass `validate-wikilink-integrity.sh` or other hooks. The
   rename-page skill itself enforces correctness; the hooks are a backstop on
   subsequent writes to the renamed page.

**Forbidden dependencies:**
- `skills/rename-page/SKILL.md`: must NOT call `/brain:lint-wiki` as a pre-flight check
  (too slow for an interactive rename; the guard checks are direct and sufficient).
- Rename logic: must NOT use `find . -name "*.md" -exec grep` for backlink detection
  (O(n²) violation); must use index-first lookup.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ | CLAUDE.md §Conventions; ADR-001 |
| `git` | any modern | rename atomicity; rollback via `git checkout .` |
| `sed` | BSD/GNU compatible | backlink substitution |
| `jq` | 1.6+ | JSON summary construction |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/rename-page/SKILL.md` | Create | Atomic rename skill with canonical 6-section structure |
| `plugins/brain-factory/tests/skills.bats` | Extend | Rename happy-path + error guards + rollback test |
| `plugins/brain-factory/tests/fixtures/wiki-rename-setup.json` | Create | Pre-rename wiki state with 5 backlinks |
| `plugins/brain-factory/tests/fixtures/wiki-rename-zero-backlinks.json` | Create | Wiki state with 0 backlinks to old slug |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json.template`,
any prior STORY-NNN.md, existing hook scripts.

## Previous Story Intelligence

STORY-020 delivered `hooks/lib/wikilink-resolve.sh` and the full `/brain:lint-wiki`
implementation. The rename-page skill's index-first backlink detection re-uses the same
indexing approach as lint-wiki. Confirm `wikilink-resolve.sh` exists and its
`wikilink_in_index` function is callable from the rename skill body.

STORY-001 created `skills/rename-page/` with a stub `SKILL.md`. This story replaces
that stub with the full implementation.

The CLAUDE.md brain-factory-002 rule ("wiki filenames are IMMUTABLE after creation —
renames go through the dedicated `rename-page` skill") means this skill is the ONLY
permitted rename path. The adversary will verify that no other skill or hook performs
a direct `mv` or `git mv` on wiki pages.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,800 |
| SS-05 subsystem design | ~1,200 |
| BC-2.05.003, BC-2.05.004 files | ~2,000 |
| VP-018 file | ~800 |
| skills.bats existing content (after STORY-020) | ~3,000 |
| hooks/lib/wikilink-resolve.sh (STORY-020 deliverable) | ~600 |
| event-catalog.json (STORY-014 deliverable) | ~2,000 |
| **Total** | **~12,400** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:lint-wiki` seven-check health pass — STORY-020.
- Per-write wikilink integrity hook (validate-wikilink-integrity.sh) — STORY-009.
- Kebab-case filename enforcement hook (validate-kebab-case-filename.sh) — STORY-012.
- Any tooling for discovering which wiki pages CONTAIN broken links post-rename — that
  is a lint-wiki concern (STORY-020), not rename-page.

## Anchors

- BC-2.05.003: `behavioral-contracts/ss-05/BC-2.05.003.md`
- BC-2.05.004: `behavioral-contracts/ss-05/BC-2.05.004.md`
- VP-018: `architecture/verification-properties/VP-018-wiki-layer-integrity.md`
- SS-05: `architecture/subsystems/SS-05-wiki-layer.md`
