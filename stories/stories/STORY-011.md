---
artifact_type: story
story_id: STORY-011
epic_id: EPIC-02
title: "validate-source-id-citation.sh and validate-publish-state.sh: citation integrity and publish state machine"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.009, BC-2.04.010]
vps: [VP-002]
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.009.md
  - behavioral-contracts/ss-04/BC-2.04.010.md
  - architecture/verification-properties/VP-002-posttooluse-hook-trigger.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-011: validate-source-id-citation.sh and validate-publish-state.sh — citation integrity and publish state machine

## Goal

Implement two PostToolUse hooks that enforce data-integrity invariants for the brain's
content layers. `validate-source-id-citation.sh` hard-blocks wiki writes (exit 2) when
any `source_ids` frontmatter entry does not resolve to a real entry in
`.brain/manifest.json`. `validate-publish-state.sh` hard-blocks invalid frontmatter
state-machine transitions (exit 2) on drafts/to-publish/published writes — enforcing the
`draft → ready → published` chain. Both hooks are fail-closed on their respective
dependencies (manifest.json unreadable → exit 2; status field absent → exit 2).

## User Value

As a brain operator, I want wiki pages blocked from being written if they claim to derive
from non-existent sources, and I want the publishing audit trail protected against
invalid state jumps, so that my brain's provenance chain and publication history are
always consistent.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.009 | `validate-source-id-citation.sh` blocks wiki writes with unresolved source citations (exit 2) | P0 |
| BC-2.04.010 | `validate-publish-state.sh` blocks invalid frontmatter state-machine transitions (exit 2) | P0 |

## Acceptance Criteria

### Source ID Citation (BC-2.04.009)

**AC-001** — `validate-source-id-citation.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin using `jq`, never
uses `eval`, and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.009 precondition 1; BC-2.04.016 invariants 1–3)

**AC-002** — Given a wiki page write with `source_ids: [ai/valid-source]` where
`manifest.json` contains a matching entry, the hook exits 0 and stdout is
`{"verdict":"allow",...}`.
(traces to BC-2.04.009 postconditions on all-resolved: 1–2)

**AC-003** — Given a wiki page write with `source_ids: [ai/nonexistent]` where
`manifest.json` has no entry for that slug, the hook exits 2 and stdout contains
`"code":"E-WIKI-007"` with the unresolved slug in the message.
(traces to BC-2.04.009 postconditions on unresolved: 1–2)

**AC-004** — When multiple source IDs are present and only one is unresolved, all
unresolved IDs are listed in the E-WIKI-007 output (not just the first).
(traces to BC-2.04.009 edge case EC-002)

**AC-005** — Given `source_ids: []` (empty list), the hook exits 0 (vacuously satisfied).
(traces to BC-2.04.009 invariant 1; edge case EC-001)

**AC-006** — When `.brain/manifest.json` is unreadable (absent), the hook exits 2 with
`"code":"E-WIKI-008"` (fail-closed per BC-2.04.009 invariant 2).
(traces to BC-2.04.009 invariant 2)

**AC-007** — On unresolved citation, stderr contains JSONL with
`"event_type":"source.citation.unresolved"`, `"hook_name":"validate-source-id-citation.sh"`,
and `"missing_source_id":"<slug>"`. On all resolved, stderr contains
`"event_type":"source.citation.resolved"`.
(traces to BC-2.04.009 postconditions on unresolved: 3 and on all-resolved: 2)

### Publish State Machine (BC-2.04.010)

**AC-008** — `validate-publish-state.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin using `jq`, never
uses `eval`, and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.010 precondition 1; BC-2.04.016 invariants 1–3)

**AC-009** — Given a new file write with `status: draft`, the hook exits 0 (creation —
no prior state).
(traces to BC-2.04.010 postconditions on valid/new: 1; invariant 3; edge case EC-001)

**AC-010** — Given valid transitions `draft → ready` and `ready → published`, the hook
exits 0 for both.
(traces to BC-2.04.010 postconditions on valid transition: 1; invariant 1)

**AC-011** — Given the invalid transition `draft → published` (skipping `ready`), the hook
exits 2 and stdout contains `"code":"E-PUBLISH-001"` with the from-state and to-state in
the message.
(traces to BC-2.04.010 postconditions on invalid: 1–2; edge case EC-002)

**AC-012** — Given a reverse transition `published → draft`, the hook exits 2 with
`"code":"E-PUBLISH-001"` (invariant: reverse transitions always blocked).
(traces to BC-2.04.010 invariant 2; postconditions on invalid: 1–2)

**AC-013** — Given a write where the `status` field is absent from frontmatter, the hook
exits 2 with `"code":"E-PUBLISH-002"`.
(traces to BC-2.04.010 invariant 4; edge case EC-003)

**AC-014** — On invalid transition, stderr contains JSONL with
`"event_type":"publish.state.transition_rejected"`, `"from_state":"<from>"`, and
`"to_state":"<to>"`. On valid/new, stderr contains
`"event_type":"publish.state.transition_accepted"`.
(traces to BC-2.04.010 postconditions on invalid: 3 and on valid: 2)

**AC-015** — `shellcheck` exits 0 on both scripts. `shfmt -d -i 2` produces no diff.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Confirm stub files exist from STORY-001:
   `plugins/brain-factory/hooks/validate-source-id-citation.sh` and
   `plugins/brain-factory/hooks/validate-publish-state.sh`. If absent, create them with
   the canonical shebang + `set -euo pipefail` + `exit 0` stub body.

2. **[failing test — Red Gate]** Create two per-hook bats files in failing state:
   - `plugins/brain-factory/tests/validate-source-id-citation.bats` with VP-002 assertions:
     resolved `source_ids` → exit 0; unresolved slug → exit 2 + E-WIKI-007;
     empty `source_ids` → exit 0; `manifest.json` absent → exit 2 + E-WIKI-008;
     multiple unresolved IDs listed.
   - `plugins/brain-factory/tests/validate-publish-state.bats` with VP-002 assertions:
     new file + `status: draft` → exit 0; `draft→ready` → exit 0;
     `ready→published` → exit 0; `draft→published` (skip) → exit 2 + E-PUBLISH-001;
     `published→draft` (reverse) → exit 2 + E-PUBLISH-001; missing `status` field → exit 2 + E-PUBLISH-002.
   Create fixtures: `wiki-page-valid-source-ids.json`, `wiki-page-unresolved-source-id.json`,
   `publish-state-valid-new.json`, `publish-state-invalid-skip.json`.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `plugins/brain-factory/hooks/validate-source-id-citation.sh`
   per BC-2.04.009:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Read stdin JSON; extract path and `source_ids` array from frontmatter via `jq`
   - Empty `source_ids` array → exit 0 immediately
   - Read `.brain/manifest.json`; if unreadable → emit E-WIKI-008 stdout; exit 2
   - For each slug in `source_ids`: check presence in manifest; collect unresolved
   - If any unresolved: emit E-WIKI-007 stdout listing all + `source.citation.unresolved`
     JSONL stderr via `hooks/lib/hook-event-emit.sh`; exit 2
   - If all resolved: emit `source.citation.resolved` JSONL stderr; exit 0

4. **[impl]** Implement `plugins/brain-factory/hooks/validate-publish-state.sh`
   per BC-2.04.010:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Read stdin JSON; extract path, prior-state and new-state from frontmatter fields
   - If `status` field absent → emit E-PUBLISH-002 stdout; exit 2
   - If new file (no prior state): any `status: draft` → exit 0; other status on new file →
     emit E-PUBLISH-001; exit 2
   - Evaluate transition pair against valid matrix (`draft→ready`, `ready→published`);
     all others → emit E-PUBLISH-001 stdout with from/to + `publish.state.transition_rejected`
     JSONL stderr; exit 2
   - On valid: emit `publish.state.transition_accepted` JSONL stderr; exit 0

5. **[green]** Run `bats plugins/brain-factory/tests/validate-source-id-citation.bats` and
   `bats plugins/brain-factory/tests/validate-publish-state.bats` — all new tests pass.

6. **[green]** Run `shellcheck` and `shfmt -d -i 2` on both scripts — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `source_ids: [ai/valid-source]`; manifest has entry | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.009 |
| `source_ids: [ai/nonexistent]`; manifest missing entry | exit 2; `{"code":"E-WIKI-007",...}` | error | BC-2.04.009 |
| `source_ids: []` | exit 0 | edge-case | BC-2.04.009 EC-001 |
| `manifest.json` absent | exit 2; `{"code":"E-WIKI-008",...}` | edge-case | BC-2.04.009 invariant 2 |
| Two `source_ids`; one unresolved | exit 2; both slugs listed in E-WIKI-007 | edge-case | BC-2.04.009 EC-002 |
| New file `status: draft` | exit 0 | happy-path | BC-2.04.010 EC-001 |
| `draft → ready` transition | exit 0 | happy-path | BC-2.04.010 invariant 1 |
| `ready → published` transition | exit 0 | happy-path | BC-2.04.010 invariant 1 |
| `draft → published` (skip ready) | exit 2; `{"code":"E-PUBLISH-001",...}` | error | BC-2.04.010 EC-002 |
| `published → draft` (reversal) | exit 2; `{"code":"E-PUBLISH-001",...}` | error | BC-2.04.010 invariant 2 |
| Missing `status` field | exit 2; `{"code":"E-PUBLISH-002",...}` | error | BC-2.04.010 EC-003 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-002 | PostToolUse trigger: source citation validation on wiki writes | `tests/validate-source-id-citation.bats` |
| VP-002 | Unresolved source_id → exit 2 + E-WIKI-007 | `tests/validate-source-id-citation.bats` |
| VP-002 | manifest.json absent → exit 2 fail-closed | `tests/validate-source-id-citation.bats` |
| VP-002 | PostToolUse trigger: publish state machine enforcement | `tests/validate-publish-state.bats` |
| VP-002 | Invalid state transition → exit 2 + E-PUBLISH-001 | `tests/validate-publish-state.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md` and ADR-002:

1. `validate-source-id-citation.sh` is **PostToolUse** (matcher: `Write|Edit` on `wiki/**`).
   Hard block (exit 2) on unresolved source IDs and on manifest.json unreadable.
2. `validate-publish-state.sh` is **PostToolUse** (matcher: `Write|Edit` on
   `drafts/**`, `to-publish/**`, `published/**`). Hard block (exit 2) on invalid transitions
   and missing `status` field.
3. Both hooks are fail-closed: if their dependency (manifest.json for citation; `status`
   field for publish state) is unavailable, exit 2.
4. JSONL events emitted via `hooks/lib/hook-event-emit.sh` (ADR-016). Event types use
   past-tense verbs per SS-17 naming convention.
5. `manifest.json` is read from `.brain/manifest.json` relative to the vault root, NOT
   from `${CLAUDE_PLUGIN_ROOT}`. The vault root is distinct from the plugin root.

### Prior-state retrieval for publish state transitions

PostToolUse fires AFTER the Write/Edit completes. The file on disk now has the NEW content.
To detect the PRIOR state for transition validation:

1. **For Edit tool**: The `tool_input.old_string` field contains the text that was replaced.
   Parse the old frontmatter from `old_string` to extract the prior `status:` value.
2. **For Write tool** (full file replacement): Use `git show HEAD:<file>` to read the
   committed version before the write. If the file is not tracked in git (new file),
   treat as "no prior state" (creation).
3. **Fallback**: If neither method works, check the `tool_result` for error indicators.

Portable git-based prior-state extraction:

```bash
prior_content="$(git show HEAD:"$file_path" 2>/dev/null)" || prior_content=""
if [ -z "$prior_content" ]; then
  # New file — no prior state; treat as creation
  prior_status=""
else
  prior_status="$(printf '%s' "$prior_content" | yq eval '.status' -)"
fi
new_status="$(jq -r '.tool_input.content' <<< "$stdin_json" | yq eval '.status' -)"
```

**Forbidden dependencies:** Both scripts must use pure bash + jq + POSIX utilities.
No Node.js, no yq, no Python. Exception: `validate-publish-state.sh` may use `yq`
(mikefarah/yq, Go-based v4.x+) for frontmatter YAML parsing from `old_string` and file
content — this is the only hook in this story that needs it.

## Hook I/O Protocol Reference (ADR-002 v2.0)

This section inlines the hook I/O contract so this story is self-contained.

### stdin — Claude Code delivers this JSON

**PostToolUse** (both hooks in this story are PostToolUse):

```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write|Edit|...",
  "tool_input": {"file_path": "<path>", "content": "<string>"},
  "tool_use_id": "<string>",
  "tool_result": {"type": "text|image|error", "text": "...", "exit_code": 0}
}
```

### Per-tool `tool_input` fields

| Tool | Fields |
|------|--------|
| Write | `file_path`, `content` |
| Edit | `file_path`, `old_string`, `new_string`, `replace_all` |

### stdout — hook verdict JSON

```json
{
  "continue": true,
  "systemMessage": "Advisory (exit 0 only)",
  "decision": "block",
  "reason": "Why blocked",
  "hookSpecificOutput": {"code": "E-SCOPE-NNN", "trace": "<uuid>", "details": {}}
}
```

Tri-state mapping:
- **allow**: exit 0, `{"continue": true}`
- **advise**: exit 0, `{"continue": true, "systemMessage": "..."}`
- **block**: exit 0, `{"decision": "block", "reason": "..."}` OR exit 2 + stderr

### Exit codes

| Exit | Meaning |
|------|---------|
| 0 | Success (stdout parsed as JSON) |
| 2 | Blocking error (stderr shown to user) |
| Other (1) | Non-blocking (stderr to debug log ONLY) |

**CRITICAL:** Exit 1 is NOT advisory. Use exit 0 + `systemMessage` for advisories.

### Extracting file path

```bash
file_path="$(jq -r '.tool_input.file_path' <<< "$stdin_json")"
```

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.7+ (latest: 1.8.1) | ADR-002 §hook-stdin-parsing |
| `yq` | 4.x+ (mikefarah/yq, Go-based — NOT kislyuk/yq Python-based) | Frontmatter extraction from markdown file content |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/validate-source-id-citation.sh` | Modify (replace stub) | Full implementation per BC-2.04.009 |
| `plugins/brain-factory/hooks/validate-publish-state.sh` | Modify (replace stub) | Full implementation per BC-2.04.010 |
| `plugins/brain-factory/tests/validate-source-id-citation.bats` | Create | VP-002 assertions for source-id-citation hook |
| `plugins/brain-factory/tests/validate-publish-state.bats` | Create | VP-002 assertions for publish-state hook |
| `plugins/brain-factory/tests/fixtures/wiki-page-valid-source-ids.json` | Create | Payload with resolved source_ids |
| `plugins/brain-factory/tests/fixtures/wiki-page-unresolved-source-id.json` | Create | Payload with missing manifest entry |
| `plugins/brain-factory/tests/fixtures/publish-state-valid-new.json` | Create | New file status: draft |
| `plugins/brain-factory/tests/fixtures/publish-state-invalid-skip.json` | Create | draft → published (skip ready) |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-010 established the pattern for two hooks per story and created per-hook bats files
(`tests/validate-page-type-policy.bats` and `tests/validate-voice-avoid-list.bats`).
STORY-011 follows the same per-hook convention (SS-04 v1.5, BC-2.18.005 v1.2). Note that
`validate-source-id-citation.sh` reads from `.brain/manifest.json` (vault root), not from
the plugin root; bats tests must set up a temp manifest fixture. The publish-state hook
requires reading the file's PRIOR state — the stdin payload from the harness includes the
file's content as written; prior state must be read from disk before the write, or inferred
from the hook payload's `tool_input` fields. Check ADR-002 §Universal Hook Input Schema
for how prior-state is delivered.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,500 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.009, BC-2.04.010 files | ~1,500 |
| VP-002 file | ~500 |
| Per-hook bats files from prior stories (pattern reference) | ~2,000 |
| Test fixture files | ~500 |
| **Total** | **~12,000** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `enforce-kebab-case.sh` (BC-2.04.011) and `block-ai-attribution.sh` (BC-2.04.012) —
  STORY-012
- `flush-state-and-commit.sh` (BC-2.04.013) and `brain-health-check.sh` (BC-2.04.014) —
  STORY-013
- Structured event catalog (BC-2.17.001..004) — STORY-014
- Hook contract meta-lint expansion (BC-2.04.015, BC-2.04.016, BC-2.17.003, BC-2.17.004) —
  STORY-015

## Anchors

- BC-2.04.009: `behavioral-contracts/ss-04/BC-2.04.009.md`
- BC-2.04.010: `behavioral-contracts/ss-04/BC-2.04.010.md`
- VP-002: `architecture/verification-properties/VP-002-posttooluse-hook-trigger.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
