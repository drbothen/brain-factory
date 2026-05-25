---
artifact_type: story
story_id: STORY-008
epic_id: EPIC-02
title: "validate-wikilink-integrity.sh and validate-index-log-coherence.sh: wiki structural integrity hooks"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.003, BC-2.04.006]
vps: [VP-002, VP-004]
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-008-wiki-layer-architecture.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.003.md
  - behavioral-contracts/ss-04/BC-2.04.006.md
  - architecture/verification-properties/VP-002-posttooluse-hook-trigger.md
  - architecture/verification-properties/VP-004-wikilink-resolution.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-008: validate-wikilink-integrity.sh and validate-index-log-coherence.sh — wiki structural integrity hooks

## Goal

Implement two PostToolUse hooks that prevent wiki structural decay: `validate-wikilink-integrity.sh`
blocks wiki writes with broken `[[slug]]` wikilinks by checking each slug against
`wiki/index.md` (O(n) index-first lookup, not O(n²) filesystem scan), and
`validate-index-log-coherence.sh` blocks writes to `wiki/index.md` or `wiki/log.md` when
the two files fall out of sync. Together these hooks prevent the orphan-page and drift
failure modes documented by practitioners Nguyen and Liu.

## User Value

As a brain operator, I want wiki writes with broken wikilinks or index/log drift to be
blocked immediately, so that my wiki maintains referential integrity and I never
accumulate orphan pages silently.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.003 | `validate-wikilink-integrity.sh` blocks wiki writes with broken wikilinks (exit 2) | P0 |
| BC-2.04.006 | `validate-index-log-coherence.sh` blocks index/log writes that break coherence invariant (exit 2) | P0 |

## Acceptance Criteria

### Wikilink Integrity (BC-2.04.003)

**AC-001** — `validate-wikilink-integrity.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin, never uses `eval`,
and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.003 precondition 1; ADR-002 §hook-contract invariants)

**AC-002** — Given a wiki page where all `[[slug]]` wikilinks resolve in `wiki/index.md`,
the hook exits 0 and stdout is `{"verdict":"allow","message":"All wikilinks valid.","trace":"<uuid>"}`.
(traces to BC-2.04.003 postconditions on all wikilinks resolve: 1–2)

**AC-003** — Given a wiki page containing `[[nonexistent-slug]]` where that slug is
absent from `wiki/index.md`, the hook exits 2 and stdout is
`{"verdict":"block","code":"E-WIKI-001","message":"Broken wikilink [[nonexistent-slug]] in <path>. No matching wiki page found.","trace":"<uuid>"}`.
All broken slugs are reported in a single response (not just the first).
(traces to BC-2.04.003 postconditions on broken wikilink: 1–4)

**AC-004** — A wiki page with zero `[[...]]` wikilinks exits 0 (vacuously valid).
(traces to BC-2.04.003 postcondition on no wikilinks: 1; edge case EC-001)

**AC-005** — When `wiki/index.md` is absent, the hook exits 2 and stdout contains
`"code":"E-WIKI-002"`. Fail-closed.
(traces to BC-2.04.003 invariant 2; edge case EC-002)

**AC-006** — Wikilink resolution uses an index-first O(n) scan of `wiki/index.md`, NOT a
filesystem glob over all wiki files. A bats performance assertion confirms the hook
completes under 100ms on a 1,000-entry index fixture.
(traces to BC-2.04.003 invariant 1; VP-004 O(n) resolution property)

**AC-007** — Given a blocked payload, stderr contains JSONL with `"event_type":
"wiki.wikilink.broken"`, `"hook_name":"validate-wikilink-integrity.sh"`, and a
`"broken_slugs"` array. Given an allowed payload, stderr contains
`"event_type":"wiki.wikilink.validated"`.
(traces to BC-2.04.003 postconditions: broken step 4 and all-resolve step 3;
BC-2.04.017 event catalog compliance)

### Index-Log Coherence (BC-2.04.006)

**AC-008** — `validate-index-log-coherence.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin, never uses `eval`,
and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.006 precondition 1; ADR-002 §hook-contract invariants)

**AC-009** — Given a write to `wiki/index.md` where every slug in the index appears in
`wiki/log.md`, the hook exits 0 and stdout is `{"verdict":"allow",...}`.
(traces to BC-2.04.006 postconditions on coherent state: 1–2)

**AC-010** — Given a write to `wiki/index.md` where a slug appears in the index but not
in `wiki/log.md`, the hook exits 2 and stdout contains `"code":"E-WIKI-003"` and the
missing slug in the message.
(traces to BC-2.04.006 postconditions on coherence violation: 1–3)

**AC-011** — When either `wiki/index.md` or `wiki/log.md` is unreadable, the hook exits 2
with `"code":"E-WIKI-004"`. Fail-closed; both files are read atomically on each hook
execution.
(traces to BC-2.04.006 invariants 1–2; edge case EC-002)

**AC-012** — A brand-new brain with both files empty exits 0 (coherent vacuously).
(traces to BC-2.04.006 edge case EC-001)

**AC-013** — Given a coherence violation, stderr contains JSONL with
`"event_type":"wiki.index_log.coherence_violated"`. Given coherent state, stderr
contains `"event_type":"wiki.index_log.coherence_verified"`.
(traces to BC-2.04.006 postconditions: violation step 3 and coherent step 2;
BC-2.04.017 event catalog compliance)

## Tasks

1. **[failing test — Red Gate]** Create two per-hook bats files in failing state:
   - `plugins/brain-factory/tests/validate-wikilink-integrity.bats` with VP-004 assertions:
     all-valid → exit 0; broken slug → exit 2 + E-WIKI-001; no wikilinks → exit 0;
     missing index.md → exit 2 + E-WIKI-002; blocked → stderr E-WIKI event.
   - `plugins/brain-factory/tests/validate-index-log-coherence.bats` with VP-002 assertions:
     coherent → exit 0; slug in index not in log → exit 2 + E-WIKI-003;
     missing log.md → exit 2 + E-WIKI-004; both empty → exit 0.
   Create bats fixtures under `tests/fixtures/`: `wiki-index-with-slugs.md`,
   `wiki-log-with-slugs.md`, `wiki-page-valid-links.md`, `wiki-page-broken-link.md`,
   `wiki-page-no-links.md`. Run bats — confirm all new tests fail.

2. **[impl]** Implement `plugins/brain-factory/hooks/validate-wikilink-integrity.sh`
   per BC-2.04.003:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Extract the file path from stdin JSON payload using `.tool_input.file_path` and read the written file content
   - Extract all `[[slug]]` patterns using the portable approach (macOS BSD grep lacks the `-P` flag; `grep -oP` is GNU-only and MUST NOT be used):
     ```bash
     # Portable wikilink extraction (works on macOS BSD grep and GNU grep):
     grep -o '\[\[[^]]*\]\]' "$file" | sed 's/^\[\[//;s/\]\]$//'
     # OR using awk (fully POSIX):
     awk '{while(match($0,/\[\[[^\]]+\]\]/)){s=substr($0,RSTART+2,RLENGTH-4);print s;$0=substr($0,RSTART+RLENGTH)}}' "$file"
     ```
   - If no wikilinks found: exit 0 immediately
   - Check `wiki/index.md` is readable; exit 2 with E-WIKI-002 if absent
   - For each slug, grep `wiki/index.md` for the slug (index-first O(n) lookup)
   - Collect all broken slugs; if any found: emit E-WIKI-001 stdout + `wiki.wikilink.broken`
     JSONL stderr via `hooks/lib/hook-event-emit.sh`; exit 2
   - If all resolve: emit allow stdout + `wiki.wikilink.validated` JSONL stderr; exit 0

3. **[impl]** Implement `plugins/brain-factory/hooks/validate-index-log-coherence.sh`
   per BC-2.04.006:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Extract the written file path from stdin JSON
   - Read both `wiki/index.md` and `wiki/log.md` atomically; exit 2 with E-WIKI-004 if
     either is unreadable
   - Extract slug lists from both files using `awk` or `grep` pattern
   - Diff: find slugs in index not in log; if any missing: emit E-WIKI-003 stdout +
     `wiki.index_log.coherence_violated` JSONL stderr; exit 2
   - If coherent: emit allow stdout + `wiki.index_log.coherence_verified` JSONL stderr;
     exit 0

4. **[green]** Run `bats plugins/brain-factory/tests/validate-wikilink-integrity.bats` and
   `bats plugins/brain-factory/tests/validate-index-log-coherence.bats` — all VP-002 and
   VP-004 tests pass.

5. **[green]** Run `shellcheck` and `shfmt -d -i 2` on both hook scripts — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Wiki page with `[[valid-slug]]` (slug in index.md) | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.003 |
| Wiki page with `[[broken-slug]]` (slug NOT in index.md) | exit 2; `{"code":"E-WIKI-001",...}` | error | BC-2.04.003 |
| Wiki page with no `[[...]]` patterns | exit 0; `{"verdict":"allow",...}` | edge-case | BC-2.04.003 EC-001 |
| wiki/index.md missing | exit 2; `{"code":"E-WIKI-002",...}` | edge-case | BC-2.04.003 EC-002 |
| Multiple broken wikilinks | exit 2; all broken slugs in response | edge-case | BC-2.04.003 EC-003 |
| Coherent index + log (all slugs match) | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.006 |
| Index has `slug-a` but log does not | exit 2; `{"code":"E-WIKI-003",...}` | error | BC-2.04.006 |
| Both files empty (new brain) | exit 0 | edge-case | BC-2.04.006 EC-001 |
| log.md missing | exit 2; `{"code":"E-WIKI-004",...}` | edge-case | BC-2.04.006 EC-002 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-002 | PostToolUse hook trigger on wiki writes | `tests/validate-index-log-coherence.bats` |
| VP-002 | Coherence violation → exit 2 | `tests/validate-index-log-coherence.bats` |
| VP-004 | Broken wikilink → exit 2 | `tests/validate-wikilink-integrity.bats` |
| VP-004 | O(n) index-first resolution (performance assertion) | `tests/validate-wikilink-integrity.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md`, ADR-002, and ADR-008:

1. Both hooks are **PostToolUse** (matcher: `Write|Edit` on `wiki/**` for wikilink
   integrity; `wiki/index.md` or `wiki/log.md` for coherence). Do NOT register them as
   PreToolUse.
2. Wikilink resolution is **index-first** (scan `wiki/index.md`). DO NOT scan the
   filesystem with `find wiki/ -name "*.md"` — that is O(n²) and violates BC-2.04.003
   invariant 1.
3. `validate-index-log-coherence.sh` reads BOTH files on every hook execution — no
   in-memory caching across calls. ADR-002 §no-state-across-calls.
4. Both hooks emit JSONL events via `hooks/lib/hook-event-emit.sh` (ADR-016). Do NOT
   write events directly with `echo`.
5. `wiki/index.md` and `wiki/log.md` are located in the brain vault (`BRAIN_ROOT/wiki/`),
   NOT in `${CLAUDE_PLUGIN_ROOT}`. Paths must be resolved relative to the vault root.
6. The `broken_slugs` field in E-WIKI-001 stdout is an array (even if only one broken
   slug). Emit ALL broken slugs in one response — do not exit on first failure.
7. Wikilink extraction MUST use portable `grep -o` + `sed` or `awk` — DO NOT use
   `grep -oP` (GNU-only; macOS BSD grep lacks the `-P` PCRE flag). See the portable
   alternatives in Task 2 above.

**Forbidden dependencies:** Both hook scripts must NOT depend on Node.js, npm, or any
non-standard tool beyond bash, jq, awk, and grep. Pure bash + POSIX utilities only.

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
| `awk` | POSIX | BC-2.04.003 precondition 3; ADR-008 §wikilink-extraction |
| `grep` | POSIX (BSD or GNU; use `-o` only — NOT `-P`) | wikilink pattern extraction |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) (`-i 2`) | CLAUDE.md §Conventions |

No Node.js required.

## File Structure Requirements

Files to create/modify:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/validate-wikilink-integrity.sh` | Modify (replace stub) | Full implementation per BC-2.04.003 |
| `plugins/brain-factory/hooks/validate-index-log-coherence.sh` | Modify (replace stub) | Full implementation per BC-2.04.006 |
| `plugins/brain-factory/tests/validate-wikilink-integrity.bats` | Create | VP-004 assertions for wikilink integrity hook |
| `plugins/brain-factory/tests/validate-index-log-coherence.bats` | Create | VP-002 assertions for index-log coherence hook |
| `plugins/brain-factory/tests/fixtures/wiki-index-with-slugs.md` | Create | 3+ slug entries for resolution tests |
| `plugins/brain-factory/tests/fixtures/wiki-log-with-slugs.md` | Create | Matching log entries |
| `plugins/brain-factory/tests/fixtures/wiki-page-valid-links.md` | Create | Page with valid `[[slug]]` references |
| `plugins/brain-factory/tests/fixtures/wiki-page-broken-link.md` | Create | Page with `[[nonexistent-slug]]` |
| `plugins/brain-factory/tests/fixtures/wiki-page-no-links.md` | Create | Page with no `[[...]]` patterns |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-007 established the pattern for bats fixtures (JSON payloads via stdin using
`run bash <hook>.sh < fixture.json` pattern) and created
`tests/validate-source-immutability.bats` as the first per-hook bats file. STORY-008
follows the same per-hook convention: each hook implemented in this story gets its own
standalone bats file (`tests/validate-wikilink-integrity.bats` and
`tests/validate-index-log-coherence.bats`) per SS-04 v1.5 and BC-2.18.005 v1.2.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-008 wiki layer architecture | ~1,500 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.003, BC-2.04.006 files | ~1,500 |
| VP-002, VP-004 files | ~800 |
| validate-source-immutability.bats from STORY-007 (pattern reference) | ~500 |
| Test output context | ~500 |
| **Total** | **~11,800** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `validate-frontmatter-schema.sh` — STORY-009
- `validate-page-type-policy.sh` — STORY-010
- `/brain:lint-wiki` skill (bulk audit version of these checks) — EPIC-04

## Anchors

- BC-2.04.003: `behavioral-contracts/ss-04/BC-2.04.003.md`
- BC-2.04.006: `behavioral-contracts/ss-04/BC-2.04.006.md`
- VP-002: `architecture/verification-properties/VP-002-posttooluse-hook-trigger.md`
- VP-004: `architecture/verification-properties/VP-004-wikilink-resolution.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-008: `architecture/adr/ADR-008-wiki-layer-architecture.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
