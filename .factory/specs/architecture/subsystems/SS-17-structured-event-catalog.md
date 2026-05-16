---
document_type: subsystem-design
id: SS-17
title: "Structured Event Catalog"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-017
created: 2026-05-15
---

# SS-17: Structured Event Catalog

## Responsibility

Maintains the canonical registry of all hook event types. Ensures every `hook-event:emit` site in the codebase has a registered row. Enforces that hooks emit JSONL on stderr and keep stdout reserved for the verdict. Prevents credential leakage to any output stream.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.17.001 | Every `hook-event:emit` site has a registered row in the structured event catalog | P0 |
| BC-2.17.002 | Event catalog defines: event_type, hook_name, severity, fields, example payload | P0 |
| BC-2.17.003 | Hooks emit JSONL on stderr; stdout reserved for JSON verdict only | P0 |
| BC-2.17.004 | No hook emits tokens, API keys, or credential values to any output stream | P0 |

## Interfaces

**Inbound:** `hook-event-emit.sh` helper (ADR-016) is the only sanctioned way to emit events; meta-lint validates catalog completeness

**Outbound:** JSONL events on stderr of each hook invocation; catalog file read by meta-lint and observability tools

## Key Design

### Event-type naming convention (F-PASS1-I4 decision)

All `event_type` values use **past-tense verbs** to describe completed events. Events describe what has happened, not what to do. This is the standard observability convention (e.g., Datadog, OpenTelemetry semantic conventions use past-tense for event names).

**Canonical pattern:** `<domain>.<past-tense-verb>` — e.g., `quarantine.blocked`, `source.immutability.violated`, `wiki.wikilink.broken`, `ingest.url.started`, `ingest.url.completed`.

**Forbidden pattern:** `<domain>.<imperative-verb>` — e.g., `quarantine.block`, `source.immutability.violation` (noun form, not verb). Any `event_type` using an imperative or noun form is a meta-lint violation.

This decision is recorded here (SS-17, the Event Catalog design) rather than in a new ADR because it is a naming rule within a single subsystem's responsibility, not a cross-cutting architectural decision requiring ADR-grade trade-off analysis.

### Event catalog file

Location: `scripts/event-catalog.json`. This is a version-controlled JSON array:
```json
[
  {
    "event_type": "ingest.url.started",
    "hook_name": "N/A (skill event)",
    "severity": "info",
    "fields": ["ts", "url", "trace"],
    "example": {"ts":"2026-01-01T00:00:00Z","event_type":"ingest.url.started","hook_name":"N/A","severity":"info","trace":"<uuid>","url":"https://..."}
  },
  {
    "event_type": "quarantine.blocked",
    "hook_name": "quarantine-fetch.sh",
    "severity": "warn",
    "fields": ["ts", "url", "pattern_matched", "trace"],
    "example": {"ts":"...","event_type":"quarantine.blocked","hook_name":"quarantine-fetch.sh","severity":"warn","trace":"<uuid>","url":"https://malicious.example.com","pattern_matched":"ignore.previous.instructions"}
  }
]
```

### Catalog completeness enforcement (BC-2.17.001)

`meta-lint.bats` includes a catalog-completeness check: it greps all hook scripts and skills for `emit_event` calls, extracts the `event_type` argument, and verifies each event_type appears in `scripts/event-catalog.json`. Any `emit_event` call with an unregistered event_type is a meta-lint failure (P1 finding).

### stderr/stdout separation (BC-2.17.003)

Enforced by `hook-event-emit.sh` (ADR-016): `emit_event` writes to stderr (`>&2`); `emit_verdict` writes to stdout. Individual hook scripts have no other mechanism to write to either stream. `meta-lint.bats` scans for any `echo` or `printf` in hook scripts that writes to stdout without routing through `emit_verdict` — these are violations.

### No credential leakage (BC-2.17.004)

`meta-lint.bats` scans hook scripts for patterns that could emit secrets:
- No `$LINKEDIN_ACCESS_TOKEN`, `$ANTHROPIC_API_KEY`, or `$GITHUB_TOKEN` in any `emit_event` or `emit_verdict` call
- No literal key patterns (40+ character hex strings, `sk-...` patterns) in emit calls
This check runs at meta-lint time, not at hook runtime — it's a static analysis of the hook source.

## Purity Classification

**Pure.** The catalog completeness check (given a set of event_type strings and a catalog JSON, are all strings present?) is a pure function testable with fixtures. The JSONL emit is effectful (stderr write).

## Dependencies

- SS-04 (Hook Chain): all 13 hooks emit events registered in the catalog
- SS-18 (Meta-Lint): catalog completeness check is part of meta-lint.bats

## Test Surface

- `tests/hooks.bats` — stderr capture assertion: each hook produces ≥ 1 JSONL event (NFR-011); stdout contains only the verdict JSON
- `meta-lint.bats` — catalog completeness: all emit_event calls have catalog entries; no stdout echo in hook scripts
