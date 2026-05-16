---
document_type: subsystem-design
id: SS-10
title: "Prompt-Injection Quarantine"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-010
created: 2026-05-15
---

# SS-10: Prompt-Injection Quarantine

## Responsibility

Intercepts every WebFetch call (PreToolUse) and scrubs content for prompt-injection patterns before it reaches the tool-access session. The quarantine corpus is maintained in `scripts/quarantine.mjs`; the hook cannot be bypassed by any skill.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.10.001 | `/brain:quarantine-check <path>` scrubs prompt-injection patterns | P0 |
| BC-2.10.002 | `quarantine-fetch.sh` fires on EVERY WebFetch call — cannot be bypassed | P0 |
| BC-2.10.003 | Quarantine corpus patterns live in `scripts/quarantine.mjs` | P0 |

## Interfaces

**Inbound:** Claude Code PreToolUse event for WebFetch tool; stdin JSON with `tool: WebFetch` and `input.url`

**Outbound:** exit 0 (clean) or exit 2 (block) with E-QUARANTINE-001; `/brain:quarantine-check` returns structured report

## Key Design

### Quarantine corpus (`scripts/quarantine.mjs`)

The corpus is a Node 20+ module that exports an array of detection patterns:
```javascript
export const INJECTION_PATTERNS = [
  /ignore.previous.instructions/i,
  /you.are.now.a/i,
  /system.prompt/i,
  /disregard.your.instructions/i,
  // ... additional patterns
];
```
The corpus is maintained and versioned as a plugin artifact. New patterns are added via plugin release (not at runtime).

### `quarantine-fetch.sh` (PreToolUse, WebFetch)

This hook fires BEFORE the WebFetch executes. Since it is PreToolUse, the `output` field is absent from stdin. The hook:
1. Extracts the URL from `input.url`
2. Fetches a shallow preview of the URL (first 2KB) via `curl --max-filesize 2048 -s`
3. Pipes the preview through `node scripts/quarantine.mjs --check` which returns exit 0 (clean) or exit 2 (pattern matched) with the matching pattern name
4. If pattern matched: emit block verdict E-QUARANTINE-001, exit 2
5. If clean: emit allow verdict, exit 0

**Why PreToolUse?** The hook must run BEFORE WebFetch executes. If the hook were PostToolUse, the content would already have been fetched and potentially used in context. PreToolUse is the only event that can prevent the fetch from completing.

**Why cannot be bypassed (BC-2.10.002)?** The hooks.json.template registers `quarantine-fetch.sh` on the `WebFetch` matcher. Claude Code's hook dispatch is at the harness level — it fires regardless of which skill triggered the WebFetch. The agent cannot skip the hook by calling WebFetch "directly"; the PreToolUse hook intercepts every invocation.

### `/brain:quarantine-check` (skill)

Provides an explicit operator-invocable check on a local file or URL, returning a structured report without triggering the ingest pipeline. Useful for auditing existing sources or checking content before ingestion.

## Purity Classification

**Mixed.** The pattern-matching decision (does this content match a quarantine pattern?) is a pure function testable with fixture content strings. The actual curl fetch is effectful.

## Dependencies

- SS-04 (Hook Chain): quarantine-fetch.sh is one of the 13 registered hooks
- SS-17 (Event Catalog): quarantine events registered

## Test Surface

- `tests/quarantine.bats` — positive: clean URL preview → exit 0; negative: injected content → E-QUARANTINE-001 exit 2; edge: curl timeout → exit 2 (fail-closed per NFR-016)
