---
document_type: adr
id: ADR-002
title: "Hook chain canonical contract: exit 0/1/2; JSON stdin/stdout; structured event emission"
status: accepted
level: L3
version: "2.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-25T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-002: Hook chain canonical contract

## Context

brain-factory's enforcement layer consists of 13 bash hook scripts registered in `hooks/hooks.json`. These hooks fire at tool events (PreToolUse, PostToolUse, SessionStart, Stop). The protocol between Claude Code and each hook script must be unambiguous, fail-closed, and WASM-port-compatible (KD-003: dispatcher-ready architecture).

Three dimensions require canonical decisions:
1. Exit code semantics (what does each code mean to Claude Code?)
2. I/O protocol (how does the hook receive context and report its verdict?)
3. Event emission (how does the hook signal its internal state for observability?)

## Decision

### Exit code semantics (binding for all 13 hooks)

| Exit Code | Verdict | Claude Code action |
|-----------|---------|-------------------|
| 0 | Success | Proceed; Claude Code parses stdout as JSON if valid |
| 2 | Blocking error | Abort tool call; stderr content shown to operator |
| Other non-zero (including 1) | Non-blocking error | Allow tool call; stderr goes to debug log only — NOT shown to operator |

**Critical correction from v1.0:** Exit code 1 is a NON-BLOCKING error in Claude Code's hook protocol. It is NOT an "advisory" shown to the user. Advisory messages (warnings visible to the operator) MUST be delivered via stdout JSON using the `systemMessage` field with exit code 0, NOT via exit 1.

Exit code on crash: hooks MUST exit 2 (never exit 0 on error — NFR-016 fail-closed guarantee). Every `exit` statement carries an explicit numeric argument. Bare `exit` is forbidden (meta-lint enforces this via BC-2.18.002).

### I/O protocol

**stdin:** Claude Code delivers a JSON object with the following schema (verified May 2026):

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/directory",
  "permission_mode": "default|plan|acceptEdits|auto|dontAsk|bypassPermissions",
  "effort": {"level": "low|medium|high|xhigh|max"},
  "hook_event_name": "PreToolUse",
  "tool_name": "Bash|Edit|Write|Read|Glob|Grep|Agent|WebFetch|WebSearch|mcp__*",
  "tool_input": {
    // For Write: "file_path", "content"
    // For Edit: "file_path", "old_string", "new_string", "replace_all"
    // For Bash: "command", "description", "timeout", "run_in_background"
    // For Read: "file_path"
    // For WebFetch: "url"
  },
  "tool_use_id": "unique-id-123"
}
```

For PostToolUse hooks, an additional `tool_result` field is present:
```json
{
  "tool_result": {
    "type": "text|image|error",
    "text": "<tool output>",
    "exit_code": 0
  }
}
```

**Key field names (v2.0 correction):**
- `tool_name` — NOT `tool` (v1.0 was wrong)
- `tool_input` — NOT `input` (v1.0 was wrong)
- `tool_result` — NOT `output` (v1.0 was wrong, PostToolUse only)

**stdout:** Hook writes a JSON verdict object conforming to Claude Code's hook output schema:

```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Warning message shown to user",
  "decision": "block",
  "reason": "Explanation of block",
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "Context for Claude",
    "permissionDecision": "deny|allow|ask|defer",
    "permissionDecisionReason": "Why",
    "modifiedInput": {"command": "safer version"}
  }
}
```

brain-factory hooks use this top-level schema. Error codes (E-SCOPE-NNN), trace UUIDs, and other internal fields are placed inside `hookSpecificOutput` so the top-level schema matches Claude Code's expected format. The full hook output contract:

- **Allow (no action):** exit 0, stdout `{"continue": true}` (or empty stdout)
- **Advisory (warn but allow):** exit 0, stdout `{"continue": true, "systemMessage": "<warning text>", "hookSpecificOutput": {"hookEventName": "<event>", "additionalContext": "<detail>"}}`
- **Block:** exit 2, stdout `{"continue": false, "decision": "block", "reason": "<human-readable>", "hookSpecificOutput": {"hookEventName": "<event>", "permissionDecision": "deny", "permissionDecisionReason": "<detail>"}}` AND stderr `<human-readable explanation>`

stdout is RESERVED for the verdict JSON only — no other output is written to stdout.

**stderr:** JSONL structured events only (BC-2.17.003). Format defined by the event catalog (SS-17). For blocking errors (exit 2), stderr also carries the human-readable explanation shown to the operator.

### Advisory messages — correct pattern

Advisory messages visible to the operator MUST use exit 0 + `systemMessage`, not exit 1:

```bash
# CORRECT: advisory shown to operator
echo '{"continue": true, "systemMessage": "E-SCOPE-001: Wikilink [[foo]] not found in wiki/", "hookSpecificOutput": {"hookEventName": "PostToolUse", "additionalContext": "Create the target page or remove the link."}}' >&1
exit 0

# WRONG (v1.0 pattern — exit 1 is debug-log only, NOT shown to operator):
# echo '{"verdict": "advise", "code": "E-SCOPE-001", "message": "..."}' >&1
# exit 1
```

Hooks that need to expose internal E-SCOPE-NNN codes do so via `hookSpecificOutput.additionalContext` or a custom field within `hookSpecificOutput`.

### Path-matcher dispatch

`hooks/hooks.json` registers hooks against Claude Code's `matcher` field. Matcher syntax:

- **Pipe-separated with backslash escape:** `"Edit\\|Write"` matches Edit or Write
- **Regex:** `"^Notebook"` matches any tool starting with Notebook; `"mcp__.*"` matches all MCP tools
- **Additional filtering via `"if"` field:** `"Bash(rm *)"` (Bash with rm command), `"Edit(*.ts)"` (Edit on .ts files)

The hook itself does NOT need to re-parse the matcher pattern — it receives the full stdin payload and decides based on `tool_input` fields within it. Example: `validate-source-immutability.sh` reads `tool_input.file_path` (not `input.path` as in v1.0) and checks it against the `sources/` prefix.

### Hook handler types

Claude Code supports 5 hook handler types. brain-factory uses `command` only in v0.x; others are documented for completeness:

| Type | v0.x Usage | Description |
|------|-----------|-------------|
| `command` | YES — all 13 hooks | Execute a shell command; stdin/stdout protocol as defined above |
| `http` | No | POST to an HTTP endpoint |
| `mcp_tool` | No | Call an MCP tool |
| `prompt` | No | Inject a system prompt |
| `agent` | No | Invoke a Claude Code agent |

All 13 brain-factory hooks use `"type": "command"`. The WASM-port-compatibility rationale (ADR-007) applies to `command` type only in v0.x.

### Supported event types

Claude Code 25+ event types are available. brain-factory registers hooks against the following subset:

| Event | brain-factory usage |
|-------|-------------------|
| `SessionStart` | `brain-health-check.sh` — validate .brain/ state at session open |
| `PreToolUse` | `quarantine-fetch.sh` (WebFetch), `enforce-kebab-case.sh` (Write\|Edit), `block-ai-attribution.sh` (Bash) |
| `PostToolUse` | 8 validation hooks (Write\|Edit) — see hooks.json |
| `Stop` | `flush-state-and-commit.sh` |

Other available events (not used in v0.x, documented for Phase 4 planning):
- `Setup`, `SessionEnd`, `UserPromptSubmit`, `UserPromptExpansion`
- `StopFailure`, `PermissionRequest`, `PermissionDenied`
- `PostToolUseFailure`, `PostToolBatch`
- `SubagentStart`, `SubagentStop`, `TaskCreated`, `TaskCompleted`
- `TeammateIdle`, `FileChanged`, `ConfigChange`, `CwdChanged`
- `InstructionsLoaded`, `WorktreeCreate`, `WorktreeRemove`
- `PreCompact`, `PostCompact`, `Elicitation`, `ElicitationResult`, `Notification`

### Structured event emission

Every hook uses `hooks/lib/hook-event-emit.sh` (see ADR-016) to emit JSONL events on stderr. Minimum: one event per hook invocation. Event fields: `ts` (ISO-8601), `event_type` (from catalog), `hook_name`, `severity`, `trace`, plus event-specific fields. No credential values are emitted to any stream (NFR-012, BC-2.17.004).

## Consequences

**Positive:**
- WASM-port-compatible: the JSON-in / JSON-out / exit-0/2 contract aligns with the WASM hook ABI. Phase 4 migration can port hook logic without changing the top-level protocol.
- Fail-closed by default: a crashed hook exits 2, blocking the operation rather than silently allowing it (NFR-016).
- Testable: each hook's behavior reduces to: "given this stdin fixture, assert this stdout JSON and this exit code" — a bats property test.
- Advisory messages (exit 0 + systemMessage) are visible to the operator; debug-only errors (exit 1) go to the log. The correct routing is now explicit.

**Negative:**
- Each hook must parse stdin JSON (via `jq`) — this adds a `jq` dependency to every hook. `jq` is a standard tool on macOS + Linux; it is part of `make setup`.
- v1.0 hook code reading `input.tool`, `input.input`, `input.output` must be updated to `tool_name`, `tool_input`, `tool_result`. The bats test fixtures must also be updated to use the correct field names.

**Neutral:**
- The `trace` UUID generation (one per invocation) requires `uuidgen` or a bash fallback. The shared helper `hook-event-emit.sh` generates the trace, so individual hooks do not duplicate this logic.

## Alternatives Considered

1. **Exit codes 0/1 only (no exit 2).** Rejected: exit 1 is non-blocking (debug-log only). A blocking verdict requires exit 2. Tri-state (allow/advisory/block) requires: exit 0 for both allow and advisory (differentiated via stdout JSON), and exit 2 for block.
2. **Positional argument passing instead of JSON stdin.** Rejected: WASM hook ABI uses JSON-in. Bash hooks use the same I/O contract from day one to make Phase 4 migration mechanical rather than a protocol redesign.
3. **Write verdict to a file instead of stdout.** Rejected: Claude Code's hook protocol reads stdout. File-based verdict adds unnecessary I/O.
4. **Custom top-level verdict envelope (v1.0 design: `{"verdict": "allow|advise|block", "code": "...", ...}`).** Rejected: the custom envelope was speculative. Claude Code expects its own schema at the top level. Brain-factory-internal fields (E-SCOPE-NNN codes, traces) move inside `hookSpecificOutput`.

## References

- phased-build-plan.md §A.4 (hook contract specification — "same JSON-in/JSON-out protocol")
- interface-definitions.md §2 (Universal Hook Input/Output schemas and exit-code semantics table — update required to match v2.0)
- BC-2.04.016 (every hook reads JSON stdin, writes JSON stdout, exits 0/1/2 only — advisory semantics update required)
- BC-2.17.003 (stderr reserved for JSONL events only)
- NFR-016 (fail-closed guarantee)
- ADR-016 (hook-event-emit.sh helper design)

## Changelog

### v2.0 (2026-05-25)

**Breaking schema changes** — v1.0 contained speculative/incorrect assumptions about the Claude Code hook API. All corrections are based on verified May 2026 API behavior.

1. **stdin field names corrected:** `tool` → `tool_name`, `input` → `tool_input`, `output` → `tool_result`. The v1.0 schema was incorrect; all hook scripts and bats fixtures must be updated to use the correct field names.

2. **stdout verdict schema replaced:** v1.0 used a custom envelope `{"verdict": "allow|advise|block", "code": "...", "message": "...", "trace": "..."}`. v2.0 uses Claude Code's native schema: `{"continue": true/false, "decision": "block", "reason": "...", "systemMessage": "...", "hookSpecificOutput": {...}}`. brain-factory-internal fields (E-SCOPE-NNN codes, traces) move inside `hookSpecificOutput`.

3. **Exit code 1 semantics corrected:** v1.0 claimed exit 1 = "advise (shown to user)". This is WRONG. Exit 1 (and all non-zero non-2 codes) = non-blocking error, stderr goes to debug log only, NOT shown to operator. Advisory messages visible to the operator require exit 0 + `systemMessage` in stdout JSON.

4. **Matcher syntax documented:** pipe-separated with backslash escape (`"Edit\\|Write"`), regex support, `"if"` field for additional filtering.

5. **Hook handler types documented:** 5 types exist (`command`, `http`, `mcp_tool`, `prompt`, `agent`); brain-factory uses `command` only.

6. **Available event types expanded:** 25+ event types catalogued; brain-factory subset identified (SessionStart, PreToolUse, PostToolUse, Stop).

7. **hooks.json.template renamed to hooks.json:** See ADR-003 v2.0 for the packaging-level change. References in this ADR updated accordingly.

### v1.0 (2026-05-15)

Initial accepted ADR. Contained speculative stdin/stdout schemas and incorrect exit code semantics for exit 1. Superseded by v2.0.
