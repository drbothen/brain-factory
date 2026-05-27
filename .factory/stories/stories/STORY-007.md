---
artifact_type: story
story_id: STORY-007
epic_id: EPIC-02
title: "validate-source-immutability.sh: block overwrite of existing source records"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 3
priority: P0
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.002]
vps: [VP-003]
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-015-source-immutability-hash.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.002.md
  - architecture/verification-properties/VP-003-source-immutability.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-007: validate-source-immutability.sh — block overwrite of existing source records

## Goal

Implement `validate-source-immutability.sh` as a PostToolUse hook on Write|Edit calls
targeting `sources/**`. The hook reads `.brain/manifest.json` to determine whether the
written path already exists as a registered source. If it does, it exits 2 (hard block)
to enforce source immutability. If the path is new, it exits 0 (allow). This is the
hook-side enforcement of the source-immutability invariant: once a source is written, it
is ground truth and cannot be silently overwritten.

## User Value

As a brain operator, I want any attempt to overwrite an existing source file to be
blocked with an error that names the correct repair path (`/brain:rename-page`), so that
my brain's raw knowledge base cannot be silently corrupted.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.002 | `validate-source-immutability.sh` blocks overwrite of existing source records (exit 2) | P0 |

## Acceptance Criteria

**AC-001** — `validate-source-immutability.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin, never uses `eval`,
and every `exit` statement uses `0`, `1`, or `2` only.
(traces to BC-2.04.002 precondition 2; ADR-002 §hook-contract invariants)

**AC-002** — Given a PostToolUse stdin payload for a Write to `sources/ai/new-source.md`
where that path is NOT in `.brain/manifest.json`, the hook exits 0 and stdout is
`{"continue":true,"trace":"<uuid>","message":"New source accepted."}`.
(traces to BC-2.04.002 postconditions on new source write: 1–3)

**AC-003** — Given a PostToolUse stdin payload for an Edit to `sources/ai/existing.md`
where that path IS in `.brain/manifest.json`, the hook exits 2 and stdout is
`{"continue":false,"decision":"block","reason":"Source file <path> already exists in manifest. Sources are immutable. Use /brain:rename-page to rename.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SOURCE-001","trace":"<uuid>"}}`.
(traces to BC-2.04.002 postconditions on overwrite attempt: 1–3)

**AC-004** — When `.brain/manifest.json` is absent, the hook exits 2 and stdout contains structured block response with `"code":"E-SOURCE-002"` in `hookSpecificOutput`. The hook is fail-closed.
(traces to BC-2.04.002 invariant 2; edge case EC-003)

**AC-005** — The hook checks the manifest for the path (not file-system existence). A
path that exists on disk but is not in the manifest is allowed.
(traces to BC-2.04.002 invariant 1)

**AC-006** — Given a blocked payload, the hook emits a JSONL event to stderr containing
`"event_type":"source.immutability.violated"` and `"hook_name":"validate-source-immutability.sh"`.
Given an allowed payload, stderr contains `"event_type":"source.added"`.
(traces to BC-2.04.002 postconditions: overwrite attempt step 3 and new source step 3;
BC-2.04.017 event catalog compliance)

**AC-007** — `shellcheck` exits 0 on `validate-source-immutability.sh` with no warnings.
`shfmt -d -i 2` produces no diff.
(traces to CLAUDE.md §Conventions §shellcheck + shfmt)

## Tasks

1. **[failing test — Red Gate]** Create `plugins/brain-factory/tests/validate-source-immutability.bats` with the VP-003 assertions in failing state:
   - Test: clean stdin (path not in manifest) → exit 0 + `verdict:allow` stdout.
     Use a JSON fixture with a temp manifest.json that does NOT contain the path.
   - Test: overwrite stdin (path in manifest) → exit 2 + `verdict:block` +
     `code:E-SOURCE-001` stdout.
   - Test: manifest absent → exit 2 + `code:E-SOURCE-002`.
   - Test: blocked payload → stderr contains `event_type:source.immutability.violated`.
   - Test: allowed payload → stderr contains `event_type:source.added`.
   Run bats on this suite — confirm all tests fail (Red Gate confirmed).

2. **[impl]** Implement `plugins/brain-factory/hooks/validate-source-immutability.sh`
   per BC-2.04.002:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Read stdin JSON payload via `jq`; extract the file path from the PostToolUse payload
     using `.tool_input.file_path` (the canonical Claude Code PostToolUse payload
     field per ADR-002 §PostToolUse-payload and the Hook I/O Protocol Reference section below)
   - Check `.brain/manifest.json` is readable; exit 2 with E-SOURCE-002 if absent
   - Use `jq` to check whether the extracted path appears in `.brain/manifest.json`
     (check `.sources[<path>]` or the appropriate manifest schema key from ADR-010)
   - If path in manifest: emit `verdict:block`/`E-SOURCE-001` stdout +
     `source.immutability.violated` JSONL stderr via `hooks/lib/hook-event-emit.sh`;
     exit 2
   - If path not in manifest: emit `verdict:allow` stdout + `source.added` JSONL stderr;
     exit 0
   - Generate a uuid for the `trace` field

3. **[green]** Run `bats plugins/brain-factory/tests/validate-source-immutability.bats` — all VP-003 tests pass.

4. **[green]** Run `shellcheck plugins/brain-factory/hooks/validate-source-immutability.sh`
   — clean. Run `shfmt -d -i 2` — no diff.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Write to `sources/ai/new-source.md`; path NOT in manifest | exit 0; `{"continue":true,...}` | happy-path | BC-2.04.002 |
| Edit to `sources/ai/existing.md`; path IS in manifest | exit 2; `{"continue":false,"decision":"block","hookSpecificOutput":{"code":"E-SOURCE-001",...}}` | error | BC-2.04.002 |
| Write with `manifest.json` absent | exit 2; `{"code":"E-SOURCE-002",...}` | edge-case | BC-2.04.002 EC-003 |
| Path exists on disk but NOT in manifest | exit 0 | edge-case | BC-2.04.002 invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-003 | Existing source overwrite → exit 2 | `tests/validate-source-immutability.bats` |
| VP-003 | New source write → exit 0 | `tests/validate-source-immutability.bats` |
| VP-003 | Missing manifest → exit 2 (fail-closed) | `tests/validate-source-immutability.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md`, ADR-002, and ADR-015:

1. `validate-source-immutability.sh` is a **PostToolUse** hook (matcher: `Write|Edit` on
   `sources/**`). It fires AFTER the write completes. The hook cannot prevent the write at
   the filesystem level; it records a block verdict that the harness uses to roll back.
2. The manifest check is authoritative: check `.brain/manifest.json`, NOT filesystem
   existence. A file on disk not in the manifest is treated as a new source.
3. Fail-closed: unreadable manifest = exit 2 with E-SOURCE-002. No permissive fallback.
4. JSONL events emitted via `hooks/lib/hook-event-emit.sh` (ADR-016). Do NOT write events
   directly to stderr with raw `echo` calls.
5. No `eval`. No bare `exit`. No hardcoded absolute paths.
6. The hook reads `.brain/manifest.json` relative to the brain vault root, NOT relative to
   `${CLAUDE_PLUGIN_ROOT}`. Brain state is at `.brain/`, not inside the plugin directory.

**Forbidden dependencies:** `validate-source-immutability.sh` must NOT depend on
`scripts/quarantine.mjs` or any Node.js runtime. It is pure bash + jq.

## Hook I/O Protocol Reference (ADR-002 v2.0)

This section inlines the hook I/O contract so this story is self-contained.

### stdin — Claude Code delivers this JSON on stdin

**PreToolUse:**
```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "effort": {"level": "low|medium|high|xhigh|max"},
  "hook_event_name": "PreToolUse",
  "tool_name": "Write|Edit|Read|Bash|WebFetch|WebSearch|Glob|Grep|Agent|mcp__*",
  "tool_input": { /* see per-tool fields below */ },
  "tool_use_id": "<string>"
}
```

**PostToolUse** — same as above plus:
```json
"hook_event_name": "PostToolUse",
"tool_result": {"type": "text|image|error", "text": "...", "exit_code": 0}
```

### Per-tool `tool_input` fields

| Tool | Fields |
|------|--------|
| Write | `file_path` (string), `content` (string) |
| Edit | `file_path` (string), `old_string`, `new_string`, `replace_all` (bool) |
| Read | `file_path` (string) |
| Bash | `command` (string), `description`, `timeout`, `run_in_background` |
| WebFetch | `url` (string) |

### stdout — hook writes this JSON to stdout

```json
{
  "continue": true,
  "systemMessage": "Advisory shown to user (only on exit 0)",
  "decision": "block",
  "reason": "Why the operation was blocked",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse|PostToolUse",
    "code": "E-SCOPE-NNN",
    "trace": "<uuid-v4>",
    "details": { /* hook-specific data */ }
  }
}
```

brain-factory tri-state mapping:
- **allow**: exit 0, stdout `{"continue": true}` (no `decision` field)
- **advise**: exit 0, stdout `{"continue": true, "systemMessage": "Advisory: ..."}` + `hookSpecificOutput` with code
- **block**: exit 0, stdout `{"decision": "block", "reason": "..."}` + `hookSpecificOutput` with code. OR exit 2 with stderr message.

### Exit codes

| Exit | Meaning | Claude Code action |
|------|---------|-------------------|
| 0 | Success | stdout parsed as JSON; if `decision:"block"` → blocked |
| 2 | Blocking error | stderr shown to user; operation aborted |
| Other (1, etc.) | Non-blocking error | stderr to debug log ONLY (NOT shown to user) |

**CRITICAL:** Exit 1 is NOT an advisory channel — stderr goes to debug log, not to user. Use exit 0 + `systemMessage` for advisories.

### Extracting the file path from stdin

For PostToolUse hooks on Write|Edit, extract the file path with:
```bash
file_path="$(jq -r '.tool_input.file_path' <<< "$stdin_json")"
```

For the tool name:
```bash
tool_name="$(jq -r '.tool_name' <<< "$stdin_json")"
```

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.7+ (latest: 1.8.1) | ADR-002 §hook-stdin-parsing |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) (`-i 2`) | CLAUDE.md §Conventions |

No Node.js required.

## File Structure Requirements

Files to create/modify:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/validate-source-immutability.sh` | Modify (replace stub) | Full implementation per BC-2.04.002 |
| `plugins/brain-factory/tests/validate-source-immutability.bats` | Create | VP-003 assertions (Red Gate → Green) |
| `plugins/brain-factory/tests/fixtures/manifest-with-source.json` | Create | Fixture: manifest.json with one source entry for negative test |
| `plugins/brain-factory/tests/fixtures/manifest-empty.json` | Create | Fixture: empty sources object `{"sources":{}}` for positive test |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`,
`docs/planning/`.

## Previous Story Intelligence

STORY-001 created the `validate-source-immutability.sh` stub. STORY-006 established the
pattern for bats test fixtures (feeding JSON payloads via stdin) and the use of
`hooks/lib/hook-event-emit.sh` for structured JSONL emission. Follow that pattern exactly.
STORY-006 may have created `tests/quarantine.bats`. This story creates
`tests/validate-source-immutability.bats` as a standalone per-hook bats file following
the per-hook test convention (SS-04 v1.5, BC-2.18.005 v1.2).

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~2,500 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-015 source immutability hash | ~1,000 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.002 file | ~800 |
| VP-003 file | ~500 |
| validate-source-immutability.sh stub + validate-source-immutability.bats stub | ~300 |
| Test output context | ~400 |
| **Total** | **~9,500** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- All other hook scripts in EPIC-02 (wikilink integrity, frontmatter schema, etc.)
- Source immutability hash algorithm (ADR-015 sha256 shim) — EPIC-08 scale stories
- `/brain:rename-page` skill — EPIC-04 (the repair path referenced in E-SOURCE-001
  messages, but not implemented here)

## Anchors

- BC-2.04.002: `behavioral-contracts/ss-04/BC-2.04.002.md`
- VP-003: `architecture/verification-properties/VP-003-source-immutability.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-015: `architecture/adr/ADR-015-source-immutability-hash.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
