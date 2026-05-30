---
artifact_type: story
story_id: STORY-010
epic_id: EPIC-02
title: "validate-page-type-policy.sh and validate-voice-avoid-list.sh: wiki type path gate and voice advisory"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 3
priority: P0
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.007, BC-2.04.008]
vps: [VP-002]
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.007.md
  - behavioral-contracts/ss-04/BC-2.04.008.md
  - architecture/verification-properties/VP-002-posttooluse-hook-trigger.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-010: validate-page-type-policy.sh and validate-voice-avoid-list.sh — wiki type path gate and voice advisory

## Goal

Implement two PostToolUse hooks: `validate-page-type-policy.sh` is a hard-block (exit 2)
hook that enforces writes to `wiki/**` land in one of the 6 valid type directories
(`concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions`);
`validate-voice-avoid-list.sh` is an advisory hook that checks brief draft files against
the 30-entry voice avoid-list in `rules/voice-avoid-list.txt`, surfacing matches without
blocking the write. The voice hook uses the correct Claude Code advisory channel: exit 0
with `{"continue": true, "systemMessage": "Voice avoid-list terms found: ..."}` in stdout
JSON (NOT exit 1 — exit 1 stderr goes to debug log only, not shown to user). Together
they demonstrate both exit-code semantics from the hook contract.

## User Value

As a brain operator, I want writes to undefined wiki type directories to be blocked
immediately (preventing wiki taxonomy drift), and I want voice avoid-list terms in my
brief drafts to be flagged as advisory warnings so I can review them without being forced
to fix them before saving.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.007 | `validate-page-type-policy.sh` blocks wiki writes to invalid wiki type directories (exit 2) | P0 |
| BC-2.04.008 | `validate-voice-avoid-list.sh` advises on brief drafts containing voice-avoid-list terms (exit 0 + systemMessage) | P1 |

## Acceptance Criteria

### Page Type Policy (BC-2.04.007)

**AC-001** — `validate-page-type-policy.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin, never uses `eval`,
and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.007 precondition 1; ADR-002 §hook-contract invariants)

**AC-002** — Given a write to `wiki/concepts/ai-agents.md`, the hook exits 0 and
stdout is `{"verdict":"allow",...}`. Each of the 6 valid type directories is tested
individually (parameterized): `concepts`, `people`, `frameworks`, `syntheses`,
`observations`, `questions`.
(traces to BC-2.04.007 postconditions on valid type: 1–2; invariant 1)

**AC-003** — Given a write to `wiki/tools/hammer.md` (invalid type directory), the hook
exits 2 and stdout contains `"code":"E-WIKI-005"` with the invalid type name in the
message.
(traces to BC-2.04.007 postconditions on invalid type: 1–3)

**AC-004** — A direct write to `wiki/` root (no subdirectory, e.g., `wiki/stray.md`)
exits 2 and stdout contains `"code":"E-WIKI-006"`.
(traces to BC-2.04.007 invariant 2)

**AC-005** — Writes to `wiki/index.md` and `wiki/log.md` are exempt: hook exits 0 for
both these paths without checking the type directory.
(traces to BC-2.04.007 invariant 3; edge cases EC-001 and EC-002)

**AC-006** — Given a blocked payload, stderr contains JSONL with
`"event_type":"wiki.page_type.rejected"`, `"hook_name":"validate-page-type-policy.sh"`,
and `"invalid_type":"<type>"`. Given an accepted payload, stderr contains
`"event_type":"wiki.page_type.accepted"`.
(traces to BC-2.04.007 postconditions: invalid step 3 and valid step 2;
BC-2.04.017 event catalog compliance)

### Voice Avoid-List Advisory (BC-2.04.008)

**AC-007** — `validate-voice-avoid-list.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin, never uses `eval`,
and every `exit` uses `0` only — NEVER exits 1 or 2. Advisories are delivered via
stdout `"systemMessage"` field with `"continue": true`, not via exit 1.
(traces to BC-2.04.008 precondition 1; invariant 1 — this hook NEVER blocks;
see Hook I/O Protocol Reference section for the correct advisory channel)

**AC-008** — Given a brief draft write (`briefs/content/*-draft.md`) with no avoid-list
terms, the hook exits 0 and stdout is `{"continue": true}`.
(traces to BC-2.04.008 postconditions on no match: 1–2; edge case EC-001)

**AC-009** — Given a brief draft containing the term "game-changer" (an avoid-list term),
the hook exits 0 and stdout contains `{"continue": true, "systemMessage": "Voice avoid-list terms found: game-changer", "hookSpecificOutput": {"hookEventName": "PostToolUse", "code": "E-VOICE-001", "matches": ["game-changer"]}}`. All matched terms in the draft are reported in the `matches` array, not just the first.
(traces to BC-2.04.008 postconditions on match found: 1–3; edge case EC-002)

**AC-010** — When `rules/voice-avoid-list.txt` is absent, the hook exits 0 with
`{"continue": true, "systemMessage": "Voice avoid-list not found; advisory skipped.", "hookSpecificOutput": {"code": "E-VOICE-002"}}`. The write still proceeds — this is advisory, not a hard block.
(traces to BC-2.04.008 invariant 3; edge case EC-003)

**AC-011** — `rules/voice-avoid-list.txt` exists in the plugin at
`${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt` and contains exactly 30 entries (one
per line). Each entry is a plain text term or short phrase. This file is created by
STORY-027 (Wave 1). This story implements the hook that READS the file — it does NOT
create the canonical file. Task 1 below creates the file for standalone development; if
STORY-027 has already run, the file already exists with the canonical 30 entries.
(traces to BC-2.04.008 precondition 2; invariant 2 — all 30 entries checked)

**AC-012** — Given a brief with 3 avoid-list terms, the `matches` array in the
`hookSpecificOutput` stdout field contains all 3 terms.
(traces to BC-2.04.008 edge case EC-002)

**AC-013** — Given an avoid-list match, stderr contains JSONL with
`"event_type":"voice.avoid_list.matched"` and `"match_count":N`. Given no match, stderr
contains `"event_type":"voice.avoid_list.passed"`.
(traces to BC-2.04.008 postconditions: match step 3 and no-match step 2;
BC-2.04.017 event catalog compliance)

**AC-014** — `shellcheck` exits 0 on both scripts. `shfmt -d -i 2` produces no diff on
both scripts.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Verify or create `plugins/brain-factory/rules/voice-avoid-list.txt`. The
   canonical 30-entry list is defined and created by STORY-027 (Wave 1). If STORY-027 has
   already run, the file already exists — do not overwrite it. If running this story
   standalone (before STORY-027), create the file with the canonical 30 entries from
   STORY-027: "game-changer", "paradigm shift", "revolutionary", "disruptive", "leverage",
   "synergy", "holistic", "robust", "seamless", "cutting-edge", "best-in-class",
   "world-class", "innovative", "state-of-the-art", "next-generation", "ground-breaking",
   "transformative", "empowering", "actionable", "ecosystem", "thought leader",
   "circle back", "deep dive", "boil the ocean", "low-hanging fruit", "move the needle",
   "bandwidth", "touch base", "in the weeds", "ping". Exactly 30 terms total, one per
   line, no trailing whitespace.

2. **[failing test — Red Gate]** Create two per-hook bats files in failing state:
   - `plugins/brain-factory/tests/validate-page-type-policy.bats` with VP-002 assertions:
     all 6 valid directories → exit 0; `wiki/tools/` → exit 2 + E-WIKI-005;
     direct `wiki/stray.md` → exit 2 + E-WIKI-006; `wiki/index.md` → exit 0 (exempt);
     `wiki/log.md` → exit 0 (exempt).
   - `plugins/brain-factory/tests/validate-voice-avoid-list.bats` with VP-002 assertions:
     no match → exit 0 + `{"continue":true}`; one match → exit 0 + `systemMessage` containing term + `hookSpecificOutput.code:E-VOICE-001`;
     3 matches → exit 0 + `hookSpecificOutput.matches` array length 3; missing avoid-list → exit 0 + `hookSpecificOutput.code:E-VOICE-002`;
     note: voice hook NEVER exits 1 or 2 — ALL paths exit 0.
   Create fixtures: `wiki-page-valid-type-path.md` (path context only),
   `briefs-draft-no-matches.md`, `briefs-draft-with-matches.md`.
   Run bats — confirm all new tests fail.

3. **[impl]** Implement `plugins/brain-factory/hooks/validate-page-type-policy.sh`
   per BC-2.04.007:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Extract the written file path from stdin JSON payload
   - Exempt `wiki/index.md` and `wiki/log.md` → exit 0
   - Extract the type directory component (second path segment under `wiki/`)
   - Validate against the 6 valid values; if direct `wiki/` root write → E-WIKI-006
   - If invalid type: emit E-WIKI-005 stdout + `wiki.page_type.rejected` JSONL stderr
     via `hooks/lib/hook-event-emit.sh`; exit 2
   - If valid: emit `wiki.page_type.accepted` JSONL stderr; exit 0

4. **[impl]** Implement `plugins/brain-factory/hooks/validate-voice-avoid-list.sh`
   per BC-2.04.008 and the Hook I/O Protocol Reference section:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Extract the written file path from stdin JSON using `.tool_input.file_path`
   - Check `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt` is readable; if absent:
     emit exit 0 with stdout
     `{"continue":true,"systemMessage":"Voice avoid-list not found; advisory skipped.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-VOICE-002"}}` +
     `voice.avoid_list.skipped` JSONL stderr; exit 0. DO NOT exit 1 or 2.
   - Read the written file content from the extracted path
   - Use `grep -iF` to check content against each line in the avoid-list; collect all matches
   - If matches found: emit stdout
     `{"continue":true,"systemMessage":"Voice avoid-list terms found: <terms>","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-VOICE-001","matches":[...]}}` +
     `voice.avoid_list.matched` JSONL stderr; exit 0
   - If no matches: emit stdout `{"continue":true}` + `voice.avoid_list.passed` JSONL stderr;
     exit 0
   - This hook MUST NEVER exit 1 or 2 under ANY condition. ALL paths must exit 0.
     Advisories are communicated via `systemMessage` in stdout JSON, not via exit code.

5. **[green]** Run `bats plugins/brain-factory/tests/validate-page-type-policy.bats` and
   `bats plugins/brain-factory/tests/validate-voice-avoid-list.bats` — all VP-002 tests
   for page-type-policy and voice-avoid-list pass.

6. **[green]** Run `shellcheck` and `shfmt -d -i 2` on both scripts — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Path: `wiki/concepts/ai-agents.md` | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.007 |
| Path: `wiki/tools/hammer.md` | exit 2; `{"code":"E-WIKI-005",...}` | error | BC-2.04.007 |
| Path: `wiki/stray.md` (no type subdir) | exit 2; `{"code":"E-WIKI-006",...}` | error | BC-2.04.007 invariant 2 |
| Path: `wiki/index.md` | exit 0 (exempt) | edge-case | BC-2.04.007 EC-001 |
| Path: `wiki/log.md` | exit 0 (exempt) | edge-case | BC-2.04.007 EC-002 |
| All 6 valid type paths | exit 0 each | happy-path | BC-2.04.007 invariant 1 |
| Brief draft with "game-changer" | exit 0; `{"continue":true,"systemMessage":"Voice avoid-list terms found: game-changer","hookSpecificOutput":{"code":"E-VOICE-001","matches":["game-changer"]}}` | happy-path | BC-2.04.008 |
| Brief draft with no avoid-list terms | exit 0; `{"continue":true}` | happy-path | BC-2.04.008 |
| Brief draft with 3 avoid-list terms | exit 0; `hookSpecificOutput.matches` array length 3 | edge-case | BC-2.04.008 EC-002 |
| `rules/voice-avoid-list.txt` absent | exit 0; `{"continue":true,"systemMessage":"Voice avoid-list not found; advisory skipped.","hookSpecificOutput":{"code":"E-VOICE-002"}}` | edge-case | BC-2.04.008 EC-003 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-002 | PostToolUse hook trigger on wiki writes | `tests/validate-page-type-policy.bats` |
| VP-002 | Invalid wiki type path → exit 2 | `tests/validate-page-type-policy.bats` |
| VP-002 | All 6 valid wiki types pass | `tests/validate-page-type-policy.bats` (parameterized) |
| VP-002 | index.md and log.md exempt from type check | `tests/validate-page-type-policy.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md` and ADR-002:

1. `validate-page-type-policy.sh` is **PostToolUse** (matcher: `Write|Edit` on
   `wiki/**`). Hard block (exit 2) for invalid type directory.
2. `validate-voice-avoid-list.sh` is **PostToolUse** (matcher: `Write|Edit` on
   `briefs/content/*-draft.md`). Advisory ONLY (exit 0 always). Exit 1 and exit 2 are
   BOTH FORBIDDEN under any condition for this hook. Advisories are communicated via
   `systemMessage` in stdout JSON with `"continue": true` — NOT via exit code. Voice
   guidance is never a hard block, and exit 1 is silently dropped to debug log, not
   shown to the user.
3. `wiki/index.md` and `wiki/log.md` are explicitly exempt from the type-directory check.
   The hook must detect these two paths before applying the type validation logic.
4. `validate-page-type-policy.sh` checks the directory path (second path segment under
   `wiki/`), NOT the `type` frontmatter field. This is complementary to
   `validate-frontmatter-schema.sh` (STORY-009): the path check and the field check are
   independent layers.
5. `rules/voice-avoid-list.txt` path uses `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`
   — never a hardcoded absolute path.
6. JSONL events emitted via `hooks/lib/hook-event-emit.sh` (ADR-016).

**Forbidden dependencies:** Both scripts must be pure bash + POSIX utilities (grep, awk,
cut). No Node.js, no yq for these hooks.

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

**CRITICAL:** Exit 1 is NOT an advisory channel — stderr goes to debug log, not to user. Use exit 0 + `systemMessage` for advisories. `validate-voice-avoid-list.sh` MUST use exit 0 + `systemMessage` for all advisory output — never exit 1.

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
| `grep` | POSIX | voice-avoid-list term matching |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) (`-i 2`) | CLAUDE.md §Conventions |

No Node.js, no yq required.

## File Structure Requirements

Files to create/modify:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/validate-page-type-policy.sh` | Modify (replace stub) | Full implementation per BC-2.04.007 |
| `plugins/brain-factory/hooks/validate-voice-avoid-list.sh` | Modify (replace stub) | Full implementation per BC-2.04.008 |
| `plugins/brain-factory/rules/voice-avoid-list.txt` | Create | Exactly 30 terms, one per line |
| `plugins/brain-factory/tests/validate-page-type-policy.bats` | Create | VP-002 assertions for page-type-policy hook |
| `plugins/brain-factory/tests/validate-voice-avoid-list.bats` | Create | VP-002 assertions for voice-avoid-list hook |
| `plugins/brain-factory/tests/fixtures/briefs-draft-no-matches.md` | Create | Draft with no avoid-list terms |
| `plugins/brain-factory/tests/fixtures/briefs-draft-with-matches.md` | Create | Draft with 3+ avoid-list terms |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-009 established the per-field validation pattern in `validate-frontmatter-schema.sh`
and created `tests/validate-frontmatter-schema.bats`. This story creates two standalone
per-hook bats files (`tests/validate-page-type-policy.bats` and
`tests/validate-voice-avoid-list.bats`) following the same per-hook convention (SS-04
v1.5, BC-2.18.005 v1.2). Note the key distinction: STORY-009 validates the `type`
frontmatter FIELD value; this story (STORY-010) validates the `type` DIRECTORY PATH.
Both can fail independently (e.g., a file at `wiki/concepts/page.md` with `type: people`
in frontmatter would pass the path hook but fail the frontmatter hook). The two
validations are complementary.

The voice avoid-list hook (BC-2.04.008) is P1 priority (unlike all other hooks in this
epic which are P0). Its bats tests are included here because the hook implementation is
small and P1 hooks deserve the same bats coverage as P0. However, if bats tests for the
P1 hook would delay delivery of the P0 hook tests, prioritize P0 (page-type-policy) tests
first.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.007, BC-2.04.008 files | ~1,500 |
| VP-002 file | ~500 |
| Per-hook bats files from prior stories (pattern reference) | ~1,500 |
| Test output context | ~500 |
| **Total** | **~11,000** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `validate-source-id-citation.sh` and `validate-publish-state.sh` — EPIC-02 Part 2
  (STORY-011+)
- `enforce-kebab-case.sh` and `block-ai-attribution.sh` — EPIC-02 Part 2
- `flush-state-and-commit.sh` and `brain-health-check.sh` — EPIC-02 Part 2
- Structured event catalog registration (BC-2.17.001..004) — EPIC-02 Part 2 (STORY-011)

## Anchors

- BC-2.04.007: `behavioral-contracts/ss-04/BC-2.04.007.md`
- BC-2.04.008: `behavioral-contracts/ss-04/BC-2.04.008.md`
- VP-002: `architecture/verification-properties/VP-002-posttooluse-hook-trigger.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
