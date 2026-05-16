---
document_type: adr
id: ADR-002
title: "Hook chain canonical contract: exit 0/1/2; JSON stdin/stdout; structured event emission"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-002: Hook chain canonical contract

## Context

brain-factory's enforcement layer consists of 13 bash hook scripts registered in `hooks.json.template`. These hooks fire at tool events (PreToolUse, PostToolUse, SessionStart, Stop). The protocol between Claude Code and each hook script must be unambiguous, fail-closed, and WASM-port-compatible (KD-003: dispatcher-ready architecture).

Three dimensions require canonical decisions:
1. Exit code semantics (what does each code mean to Claude Code?)
2. I/O protocol (how does the hook receive context and report its verdict?)
3. Event emission (how does the hook signal its internal state for observability?)

## Decision

### Exit code semantics (binding for all 13 hooks)

| Exit Code | Verdict | Claude Code action |
|-----------|---------|-------------------|
| 0 | `allow` | Proceed with the tool call |
| 1 | `advise` | Allow tool call; surface advisory to operator |
| 2 | `block` | Abort tool call; surface block reason to operator |

Exit code on crash: hooks MUST exit 2 (never exit 0 on error — NFR-016 fail-closed guarantee). Every `exit` statement carries an explicit numeric argument. Bare `exit` is forbidden (meta-lint enforces this via BC-2.18.002).

### I/O protocol

**stdin:** Claude Code delivers a JSON object conforming to the Universal Hook Input Schema (interface-definitions.md §2):
```json
{
  "tool": "<tool-name>",
  "input": { "<tool-input-fields>" },
  "output": { "<tool-output-fields>" }
}
```
`output` is absent for PreToolUse hooks; present for PostToolUse hooks.

**stdout:** Hook writes a JSON verdict object:
```json
{
  "verdict": "allow|advise|block",
  "code": "E-SCOPE-NNN",
  "message": "<human-readable message>",
  "trace": "<uuid-v4>"
}
```
`code` and `message` are required when `verdict` is `advise` or `block`. `trace` is always required. stdout is RESERVED for the verdict only — no other output is written to stdout.

**stderr:** JSONL structured events only (BC-2.17.003). Format defined by the event catalog (SS-17).

### Path-matcher dispatch

hooks.json.template registers hooks against Claude Code's `matcher` field (a regex matched against the tool name and, for file-writing tools, the file path). The hook itself does NOT need to re-parse the matcher pattern — it receives the full stdin payload and decides based on the `input` fields within it. Example: `validate-source-immutability.sh` receives the Write tool's `path` field in `input.path` and checks it against `sources/` prefix. This is simpler and more correct than re-implementing matcher logic inside each hook.

### Structured event emission

Every hook uses `hooks/lib/hook-event-emit.sh` (see ADR-016) to emit JSONL events on stderr. Minimum: one event per hook invocation. Event fields: `ts` (ISO-8601), `event_type` (from catalog), `hook_name`, `severity`, `trace`, plus event-specific fields. No credential values are emitted to any stream (NFR-012, BC-2.17.004).

## Consequences

**Positive:**
- WASM-port-compatible: the JSON-in / JSON-out / exit-0/1/2 contract is identical to the WASM hook ABI. Phase 4 migration can port hook logic without changing the protocol.
- Fail-closed by default: a crashed hook exits 2, blocking the operation rather than silently allowing it (NFR-016).
- Testable: each hook's behavior reduces to: "given this stdin fixture, assert this stdout JSON and this exit code" — a bats property test.

**Negative:**
- Each hook must parse stdin JSON (via `jq`) — this adds a `jq` dependency to every hook. `jq` is a standard tool on macOS + Linux; it is part of `make setup`.

**Neutral:**
- The `trace` UUID generation (one per invocation) requires `uuidgen` or a bash fallback. The shared helper `hook-event-emit.sh` generates the trace, so individual hooks do not duplicate this logic.

## Alternatives Considered

1. **Exit codes 0/1 only (no exit 2).** Rejected: would make the hook contract indistinguishable between "advisory" and "no-op" on tool call routing. Tri-state (allow/advise/block) maps directly to the three actions Claude Code takes.
2. **Positional argument passing instead of JSON stdin.** Rejected: WASM hook ABI uses JSON-in. Bash hooks should use the same I/O contract from day one to make Phase 4 migration mechanical rather than a protocol redesign.
3. **Write verdict to a file instead of stdout.** Rejected: Claude Code's hook protocol reads stdout. File-based verdict adds unnecessary I/O.

## References

- phased-build-plan.md §A.4 (hook contract specification — "same JSON-in/JSON-out protocol")
- interface-definitions.md §2 (Universal Hook Input/Output schemas and exit-code semantics table)
- BC-2.04.016 (every hook reads JSON stdin, writes JSON stdout, exits 0/1/2 only)
- BC-2.17.003 (stderr reserved for JSONL events only)
- NFR-016 (fail-closed guarantee)
- ADR-016 (hook-event-emit.sh helper design)
