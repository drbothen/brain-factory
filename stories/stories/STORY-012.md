---
artifact_type: story
story_id: STORY-012
epic_id: EPIC-02
title: "enforce-kebab-case.sh and block-ai-attribution.sh: filename naming gate and AI attribution block"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 3
priority: P0
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.011, BC-2.04.012]
vps: [VP-017]
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.011.md
  - behavioral-contracts/ss-04/BC-2.04.012.md
  - architecture/verification-properties/VP-017-hook-naming-and-attribution.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-012: enforce-kebab-case.sh and block-ai-attribution.sh — filename naming gate and AI attribution block

## Goal

Implement two PreToolUse hooks that enforce critical governance rules before writes
reach the filesystem. `enforce-kebab-case.sh` fires on Write|Edit and blocks any target
filename that is not kebab-case (lowercase letters, hyphens, digits; no spaces, no
underscores, no uppercase) — preventing wiki filename drift that would break backlinks.
`block-ai-attribution.sh` fires on Bash tool calls and blocks commands containing AI
attribution tokens (`Co-Authored-By: Claude`, robot emoji `🤖`, or `"Generated with
Claude Code"`) — enforcing the explicit operator directive documented in CLAUDE.md.

## User Value

As a brain operator, I want all new files forced to kebab-case naming at write time so
that backlink integrity is preserved from the moment of creation, and I want any attempt
to commit AI attribution strings to be automatically blocked so that the no-attribution
convention is machine-enforced rather than policy-only.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.011 | `enforce-kebab-case.sh` blocks file writes with non-kebab-case filenames (exit 2) | P0 |
| BC-2.04.012 | `block-ai-attribution.sh` blocks bash commands containing AI attribution tokens (exit 2) | P0 |

## Acceptance Criteria

### Kebab-Case Enforcement (BC-2.04.011)

**AC-001** — `enforce-kebab-case.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin using `jq`, never
uses `eval`, and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.011 precondition 1; BC-2.04.016 invariants 1–3)

**AC-002** — Given a write to `wiki/concepts/ai-agents.md`, the hook exits 0 and stdout
is `{"verdict":"allow",...}`.
(traces to BC-2.04.011 postconditions on kebab-case: 1; edge case EC-004)

**AC-003** — Given a write to `wiki/concepts/AI Agents.md` (uppercase + space), the hook
exits 2 and stdout contains `"code":"E-NAMING-001"` with a suggested kebab-case name
`ai-agents.md`.
(traces to BC-2.04.011 postconditions on non-kebab: 1–3; edge case EC-002)

**AC-004** — Given a write to `wiki/concepts/ai_agents.md` (underscore), the hook exits 2
with `"code":"E-NAMING-001"` and suggestion `ai-agents.md`.
(traces to BC-2.04.011 postconditions on non-kebab: 1–3; edge case EC-003)

**AC-005** — Given a write to `CLAUDE.md`, the hook exits 0 (exempt from kebab-case check
per the explicit exception list).
(traces to BC-2.04.011 invariant 3; edge case EC-001)

**AC-006** — The exception list covers all required uppercase-convention files: `CLAUDE.md`,
`README.md`, `CHANGELOG.md`, `MANIFEST.md`, `LICENSE`, `.brain/STATE.md`,
`.brain/manifest.json`.
(traces to BC-2.04.011 invariant 3)

**AC-007** — The suggested kebab-case name in E-NAMING-001 is derived by: lowercasing,
replacing spaces with hyphens, replacing underscores with hyphens.
(traces to BC-2.04.011 postconditions on non-kebab: 3)

**AC-008** — On rejection, stderr contains JSONL with `"event_type":"naming.kebab_case.rejected"`,
`"filename":"<name>"`, and `"suggested":"<suggested>"`. On acceptance, stderr contains
`"event_type":"naming.kebab_case.accepted"`.
(traces to BC-2.04.011 postconditions on non-kebab: 4 and on kebab: 2)

### AI Attribution Block (BC-2.04.012)

**AC-009** — `block-ai-attribution.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin using `jq`, never
uses `eval`, and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.012 precondition 1; BC-2.04.016 invariants 1–3)

**AC-010** — Given a bash command `git commit -m "feat: add feature"` (no attribution
tokens), the hook exits 0 and stdout is `{"verdict":"allow",...}`.
(traces to BC-2.04.012 postconditions on no tokens: 1)

**AC-011** — Given a bash command containing `Co-Authored-By: Claude Opus`, the hook
exits 2 and stdout contains `"code":"E-ATTR-001"` identifying the forbidden token.
(traces to BC-2.04.012 postconditions on token found: 1–2; invariant 1)

**AC-012** — Given a bash command containing the robot emoji `🤖`, the hook exits 2
with `"code":"E-ATTR-001"`. No exceptions for emoji in comments.
(traces to BC-2.04.012 postconditions on token found: 1–2; edge case EC-001)

**AC-013** — Given a bash command containing the string `Generated with Claude Code`,
the hook exits 2 with `"code":"E-ATTR-001"`.
(traces to BC-2.04.012 postconditions on token found: 1–2; invariant 1)

**AC-014** — The hook checks for all three forbidden patterns in a single pass (not
separately). All three are covered in one bats parameterized test.
(traces to BC-2.04.012 invariant 1)

**AC-015** — On blocked command, stderr contains JSONL with
`"event_type":"attribution.token.blocked"` and `"matched_pattern":"<pattern>"`. On
clean command, stderr contains `"event_type":"attribution.token.cleared"`.
(traces to BC-2.04.012 postconditions on token found: 3 and on no tokens: 2)

**AC-016** — `shellcheck` exits 0 on both scripts. `shfmt -d -i 2` produces no diff.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Confirm stub files exist from STORY-001:
   `plugins/brain-factory/hooks/enforce-kebab-case.sh` and
   `plugins/brain-factory/hooks/block-ai-attribution.sh`. If absent, create canonical stubs.

2. **[failing test — Red Gate]** Create `plugins/brain-factory/tests/enforce-kebab-case.bats`
   and `plugins/brain-factory/tests/block-ai-attribution.bats` with VP-017 assertions in
   failing state:
   - `enforce-kebab-case.bats` (≥ 3 `@test` blocks): `ai-agents.md` → exit 0;
     `AI Agents.md` → exit 2 + E-NAMING-001 + suggestion; `ai_agents.md` → exit 2 +
     E-NAMING-001; `CLAUDE.md` → exit 0 (exempt); all 7 exception-list files → exit 0.
   - `block-ai-attribution.bats` (≥ 3 `@test` blocks): clean commit command → exit 0;
     `Co-Authored-By: Claude` → exit 2 + E-ATTR-001; robot emoji `🤖` → exit 2 +
     E-ATTR-001; `Generated with Claude Code` → exit 2 + E-ATTR-001.
   Create fixtures: `write-kebab-valid.json`, `write-kebab-invalid-space.json`,
   `write-kebab-exempt-claude-md.json`, `bash-clean-commit.json`,
   `bash-ai-attribution-coauthored.json`, `bash-ai-attribution-emoji.json`.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `plugins/brain-factory/hooks/enforce-kebab-case.sh` per BC-2.04.011:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Read stdin JSON; extract the target file path (basename) using `jq`
   - Check against exception list (`CLAUDE.md`, `README.md`, `CHANGELOG.md`, `MANIFEST.md`,
     `LICENSE`, `STATE.md`, `manifest.json`); if match → emit `naming.kebab_case.accepted`
     JSONL stderr; exit 0
   - Validate basename against pattern `^[a-z0-9][a-z0-9-]*(\.[a-z0-9]+)?$`
   - If non-conforming: derive suggestion (lowercase + s/ /-/g + s/_/-/g); emit
     E-NAMING-001 stdout + `naming.kebab_case.rejected` JSONL stderr via
     `hooks/lib/hook-event-emit.sh`; exit 2
   - If conforming: emit `naming.kebab_case.accepted` JSONL stderr; exit 0

4. **[impl]** Implement `plugins/brain-factory/hooks/block-ai-attribution.sh` per BC-2.04.012:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Read stdin JSON; extract the bash command string using `jq`
   - Scan for all three forbidden patterns in a single pass:
     1. `Co-Authored-By: Claude` (substring)
     2. `🤖` (literal emoji)
     3. `Generated with Claude Code` (substring)
   - If any match: emit E-ATTR-001 stdout with matched pattern +
     `attribution.token.blocked` JSONL stderr via `hooks/lib/hook-event-emit.sh`; exit 2
   - If no match: emit `attribution.token.cleared` JSONL stderr; exit 0

5. **[green]** Run `bats plugins/brain-factory/tests/enforce-kebab-case.bats` and
   `bats plugins/brain-factory/tests/block-ai-attribution.bats` — all new VP-017 tests pass.

6. **[green]** Run `shellcheck` and `shfmt -d -i 2` on both scripts — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Target: `wiki/concepts/ai-agents.md` | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.011 EC-004 |
| Target: `wiki/concepts/AI Agents.md` | exit 2; E-NAMING-001; suggestion: `ai-agents.md` | error | BC-2.04.011 EC-002 |
| Target: `wiki/concepts/ai_agents.md` | exit 2; E-NAMING-001; suggestion: `ai-agents.md` | error | BC-2.04.011 EC-003 |
| Target: `CLAUDE.md` | exit 0 (exempt) | edge-case | BC-2.04.011 EC-001 |
| Bash: `git commit -m "feat: add feature"` | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.012 |
| Bash with `Co-Authored-By: Claude Opus` | exit 2; E-ATTR-001 | error | BC-2.04.012 |
| Bash with `🤖` emoji | exit 2; E-ATTR-001 | error | BC-2.04.012 EC-001 |
| Bash with `Generated with Claude Code` | exit 2; E-ATTR-001 | error | BC-2.04.012 EC-002 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-017 | Non-kebab-case names blocked before write | `tests/enforce-kebab-case.bats` |
| VP-017 | Valid kebab-case names pass | `tests/enforce-kebab-case.bats` |
| VP-017 | Exception list covers known uppercase files | `tests/enforce-kebab-case.bats` |
| VP-017 | All 3 forbidden attribution patterns blocked | `tests/block-ai-attribution.bats` |
| VP-017 | Clean bash commands pass | `tests/block-ai-attribution.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md` and ADR-002:

1. `enforce-kebab-case.sh` is **PreToolUse** (matcher: `Write|Edit`). It fires BEFORE the
   write so no bad filename ever reaches the filesystem.
2. `block-ai-attribution.sh` is **PreToolUse** (matcher: `Bash`). It fires BEFORE the bash
   command executes so no forbidden commit can run.
3. Both hooks emit JSONL events via `hooks/lib/hook-event-emit.sh` (ADR-016).
4. The kebab-case check applies to the filename BASENAME only, not the full path. Directory
   names are not checked by this hook.
5. The attribution check scans the entire bash command string. There are no exceptions for
   "search commands" or comments containing the forbidden strings — the scan is
   substring-based and produces a false positive on `grep "Co-Authored-By"` commands (this
   is documented and accepted per BC-2.04.012 edge case EC-003).

**Forbidden dependencies:** Both scripts are pure bash + grep + POSIX utilities.
No Node.js, no Python, no external tooling.

## Hook I/O Protocol Reference (ADR-002 v2.0)

This section inlines the hook I/O contract so this story is self-contained.

### stdin — Claude Code delivers this JSON

**PreToolUse** (both hooks in this story are PreToolUse):

```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write|Edit|Bash",
  "tool_input": {"file_path": "<path>", "content": "<string>"},
  "tool_use_id": "<string>"
}
```

### Per-tool `tool_input` fields

| Tool | Fields |
|------|--------|
| Write | `file_path`, `content` |
| Edit | `file_path`, `old_string`, `new_string`, `replace_all` |
| Bash | `command`, `description`, `timeout` |

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

### Extracting file path and bash command

```bash
# For Write/Edit hooks:
file_path="$(jq -r '.tool_input.file_path' <<< "$stdin_json")"
# For Bash hooks:
command="$(jq -r '.tool_input.command' <<< "$stdin_json")"
```

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.7+ (latest: 1.8.1) | ADR-002 §hook-stdin-parsing |
| `grep` | POSIX | Pattern matching for both hooks |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

No Node.js, no yq required.

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/enforce-kebab-case.sh` | Modify (replace stub) | Full implementation per BC-2.04.011 |
| `plugins/brain-factory/hooks/block-ai-attribution.sh` | Modify (replace stub) | Full implementation per BC-2.04.012 |
| `plugins/brain-factory/tests/enforce-kebab-case.bats` | Create | VP-017 assertions for enforce-kebab-case.sh (≥ 3 @test blocks) |
| `plugins/brain-factory/tests/block-ai-attribution.bats` | Create | VP-017 assertions for block-ai-attribution.sh (≥ 3 @test blocks) |
| `plugins/brain-factory/tests/fixtures/write-kebab-valid.json` | Create | Valid kebab target path |
| `plugins/brain-factory/tests/fixtures/write-kebab-invalid-space.json` | Create | Space in filename |
| `plugins/brain-factory/tests/fixtures/write-kebab-exempt-claude-md.json` | Create | CLAUDE.md exempt path |
| `plugins/brain-factory/tests/fixtures/bash-clean-commit.json` | Create | Clean git commit command |
| `plugins/brain-factory/tests/fixtures/bash-ai-attribution-coauthored.json` | Create | Co-Authored-By token |
| `plugins/brain-factory/tests/fixtures/bash-ai-attribution-emoji.json` | Create | Robot emoji token |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-010 established the two-hooks-per-story pattern and per-hook .bats files (one .bats
file per hook, not a shared hooks.bats). Note that these are PreToolUse hooks (unlike
STORY-010's PostToolUse hooks). The stdin payload schema differs: PreToolUse `Write|Edit`
delivers `tool_input.file_path`, and PreToolUse `Bash` delivers `tool_input.command`.
Check ADR-002 §Universal Hook Input Schema for the exact field names. Create
`tests/enforce-kebab-case.bats` and `tests/block-ai-attribution.bats` as standalone
suites; do NOT add to a shared hooks.bats.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.011, BC-2.04.012 files | ~1,500 |
| VP-017 file | ~500 |
| enforce-kebab-case.bats (new) | ~1,200 |
| block-ai-attribution.bats (new) | ~1,300 |
| Test fixtures | ~400 |
| **Total** | **~11,900** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `validate-source-id-citation.sh` and `validate-publish-state.sh` — STORY-011
- `flush-state-and-commit.sh` and `brain-health-check.sh` — STORY-013
- Structured event catalog (BC-2.17.001..004) — STORY-014
- Hook contract meta-lint expansion (BC-2.04.015, BC-2.04.016, BC-2.17.003,
  BC-2.17.004) — STORY-015

## Anchors

- BC-2.04.011: `behavioral-contracts/ss-04/BC-2.04.011.md`
- BC-2.04.012: `behavioral-contracts/ss-04/BC-2.04.012.md`
- VP-017: `architecture/verification-properties/VP-017-hook-naming-and-attribution.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
