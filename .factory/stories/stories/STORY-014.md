---
artifact_type: story
story_id: STORY-014
epic_id: EPIC-02
title: "Structured event catalog: scripts/event-catalog.json, hook-event-emit.sh shim, and BC-2.04.017 universal emission"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-04, SS-17]
behavioral_contracts: [BC-2.04.017, BC-2.17.001, BC-2.17.002]
vps: [VP-008, VP-017]
dependencies: [STORY-001]
blocks: [STORY-006, STORY-007, STORY-008, STORY-009, STORY-010, STORY-011, STORY-012, STORY-013, STORY-015]
inputs:
  - architecture/subsystems/SS-17-structured-event-catalog.md
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.017.md
  - behavioral-contracts/ss-17/BC-2.17.001.md
  - behavioral-contracts/ss-17/BC-2.17.002.md
  - architecture/verification-properties/VP-008-hook-event-catalog-completeness.md
  - architecture/verification-properties/VP-017-hook-naming-and-attribution.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.04.017 (universal hook emission) and BC-2.17.001+002
# (catalog registration + schema) are indivisible at implementation time — the shim
# and the catalog file are the same deliverable. BC-2.17.003 and BC-2.17.004
# (stdout/stderr separation + no-credential security) are cross-cutting meta-lint
# concerns covered in STORY-015. Separation by concern; no BC overlap.
---

# STORY-014: Structured event catalog — scripts/event-catalog.json, hook-event-emit.sh shim, and universal emission (BC-2.04.017 + BC-2.17.001 + BC-2.17.002)

## Goal

Deliver the foundational structured event catalog infrastructure that every hook in
EPIC-02 depends on. This story produces three tightly coupled deliverables:
(1) `scripts/event-catalog.json` — the machine-readable registry of all event types,
pre-populated with an entry for every event type emitted by the 13 hooks; (2)
`hooks/lib/hook-event-emit.sh` — the canonical helper shim that every hook calls to
emit JSONL events to stderr; (3) a meta-lint bats test asserting catalog completeness
(all `emit_event` call sites in hook scripts have a registered catalog row). Every other
story in EPIC-02 (STORY-006..STORY-013) calls this shim — the shim must exist before
those stories can be fully implemented. The `blocks:` field signals that full integration
of STORY-006..STORY-013 depends on this catalog being in place, but stubs can proceed
in parallel.

## User Value

As a brain operator and factory maintainer, I want every hook event emitted by the
brain-factory to be traceable through a machine-readable catalog so that I can configure
observability tooling, validate schema correctness in CI, and be certain that no
ad-hoc event type escapes governance review.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.017 | Every hook emits JSONL events on stderr via hook-event catalog | P0 |
| BC-2.17.001 | Every `hook-event:emit` site has a registered row in the structured event catalog | P0 |
| BC-2.17.002 | Event catalog defines: event_type, hook_name, severity, fields, example payload | P0 |

## Acceptance Criteria

### Hook Event Emit Shim (BC-2.04.017)

**AC-001** — `hooks/lib/hook-event-emit.sh` exists at
`plugins/brain-factory/hooks/lib/hook-event-emit.sh` and is a valid bash library (no
shebang required; designed to be sourced). It exports two functions:
`emit_event <event_type> [key=value ...]` (writes JSONL to stderr) and
`emit_verdict <json-string>` (writes JSON verdict to stdout).
(traces to BC-2.04.017 precondition 2; ADR-016 §hook-helper-architecture)

**AC-002** — `emit_event` produces a single JSONL line on stderr conforming to the base
schema: `{"ts":"<ISO8601>","event_type":"<type>","hook_name":"<script>","trace":"<uuid>",
...hook-specific-fields}`. The `ts` field is always a valid ISO 8601 timestamp. The
`trace` field is a consistent UUID within a hook invocation.
(traces to BC-2.04.017 postconditions: 1–2; invariants 1–3)

**AC-003** — When `hooks/lib/hook-event-emit.sh` is absent (renamed away), any hook that
sources it detects the absence and emits a best-effort JSONL directly to stderr with
`"event_type":"hook.helper.missing"` and exits 2 with `"code":"E-HOOK-002"`.
(traces to BC-2.04.017 edge case EC-001)

**AC-004** — `emit_verdict` writes exclusively to stdout and produces no stderr output.
`emit_event` writes exclusively to stderr and produces no stdout output. There is no
cross-contamination between the two streams from these helpers.
(traces to BC-2.04.017 postcondition 4; BC-2.17.003 invariants — stream separation)

**AC-005** — No secret values (API keys, tokens, credential strings) appear in any output
of `emit_event`. The helper does not accept raw credential field values; fields with
known credential names are masked to `[REDACTED]` before writing.
(traces to BC-2.04.017 postcondition 5; BC-2.17.004 precondition 1)

### Event Catalog (BC-2.17.001 + BC-2.17.002)

**AC-006** — `scripts/event-catalog.json` exists at
`plugins/brain-factory/scripts/event-catalog.json` and is a valid JSON array parseable
by `jq .`.
(traces to BC-2.17.002 precondition 1; postcondition 2)

**AC-007** — Each catalog entry is a JSON object containing exactly these fields:
`event_type` (string, unique), `hook_name` (string), `severity` (one of
`info|warn|error`), `fields` (array of strings), `example` (valid JSON object
parseable by `jq empty`).
(traces to BC-2.17.002 postcondition 1; invariant 2)

**AC-008** — All `event_type` values in the catalog match the pattern
`<domain>.<past-tense-verb>` (dot-separated lowercase, past-tense per SS-17 §Event-type
naming convention). Imperative and noun forms are forbidden. Examples of correct types:
`quarantine.blocked`, `source.citation.unresolved`, `naming.kebab_case.rejected`,
`session.state.committed`.
(traces to BC-2.17.002 invariant 1)

**AC-009** — The catalog is pre-populated with one row for EVERY event type emitted by
all 13 hooks. The complete initial set covers (at minimum, others added per hook story):
`quarantine.blocked`, `quarantine.allowed`, `source.immutability.violated`,
`source.immutability.accepted`, `wiki.wikilink.broken`, `wiki.wikilink.validated`,
`wiki.index_log.coherence_violated`, `wiki.index_log.coherence_accepted`,
`frontmatter.schema.rejected`, `frontmatter.schema.accepted`,
`wiki.page_type.rejected`, `wiki.page_type.accepted`,
`voice.avoid_list.matched`, `voice.avoid_list.passed`,
`source.citation.unresolved`, `source.citation.resolved`,
`publish.state.transition_rejected`, `publish.state.transition_accepted`,
`naming.kebab_case.rejected`, `naming.kebab_case.accepted`,
`attribution.token.blocked`, `attribution.token.cleared`,
`session.state.committed`, `session.state.flushed`, `session.state.commit_failed`,
`brain.health.checked`, `brain.health.skipped`.
(traces to BC-2.17.001 postcondition 1; BC-2.17.002 postcondition 1)

**AC-010** — `event_type` values in the catalog are unique. No two catalog entries share
the same `event_type`.
(traces to BC-2.17.001 invariant 2)

**AC-011** — The catalog is append-only by convention: no event types are removed in this
story; any future removal must be preceded by a deprecation entry (per BC-2.17.001
invariant 1).
(traces to BC-2.17.001 invariant 1)

### Meta-Lint Catalog Completeness

**AC-012** — `tests/meta-lint.bats` contains a test that: (1) greps all 13 hook
scripts for `emit_event` call sites, extracts the `event_type` argument, and (2) verifies
each extracted `event_type` appears in `scripts/event-catalog.json`. Any unregistered
emit site fails the test. The catalog-completeness check lives in `tests/meta-lint.bats`
(the 8-category static analysis suite) — do NOT create a separate `tests/integration.bats`
catalog suite for this purpose.
(traces to BC-2.17.001 postcondition 1; VP-008 cross-reference check)

**AC-009b** — Cross-check: every `event_type` emitted by STORY-006 through STORY-013
(per their ACs) MUST appear in the catalog. Implementer: before declaring STORY-014
done, grep all EPIC-02 hook stories for `hook-event:emit` calls and verify the emitted
`event_type` strings are in `scripts/event-catalog.json`. If any hook story emits an
event NOT in the catalog, that is a defect blocking STORY-014's wave gate. The catalog
list in AC-009 is the authoritative source-of-truth; STORY-014 owns it and STORY-014's
bats meta-test verifies catalog-vs-hook-emission consistency at build time. The catalog
is open-ended and grows as hook stories add events.
(traces to BC-2.17.001 postcondition 1; BC-2.17.001 invariant 1)

**AC-013** — The `jq empty` check on every `example` field in `scripts/event-catalog.json`
passes in bats.
(traces to BC-2.17.002 invariant 2; edge case EC-002)

**AC-014** — `shellcheck` exits 0 on `hooks/lib/hook-event-emit.sh`. `shfmt -d -i 2`
produces no diff.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Verify STORY-001 created a stub at
   `plugins/brain-factory/hooks/lib/hook-event-emit.sh`. If the stub exists but is empty
   or non-functional, note it — Task 3 replaces it with full implementation.

2. **[failing test — Red Gate]** Add VP-008 assertions to `tests/meta-lint.bats` (or
   create `tests/integration.bats`) in failing state:
   - Test: `scripts/event-catalog.json` exists and is valid JSON array.
   - Test: all entries have `event_type`, `hook_name`, `severity`, `fields`, `example` fields.
   - Test: all `event_type` values match `^[a-z][a-z0-9_]*\.[a-z][a-z0-9_]*$` pattern
     (domain.past-tense).
   - Test: `jq empty` on each entry's `example` field passes.
   - Test: all `emit_event` call sites in hook scripts have matching catalog rows.
   - Test: `emit_event` writes to stderr; `emit_verdict` writes to stdout; no cross-contamination
     (in `tests/hook-event-emit.bats`).
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `plugins/brain-factory/hooks/lib/hook-event-emit.sh` per
   BC-2.04.017 and ADR-016:
   ```bash
   #!/usr/bin/env bash
   # Sourced by all brain-factory hook scripts.
   # emit_event <event_type> [key=value ...] — writes JSONL to stderr
   # emit_verdict <json-string>             — writes JSON verdict to stdout
   emit_event() { ... }  # builds {"ts":...,"event_type":...,"hook_name":...,"trace":...} + extras → stderr
   emit_verdict() { ... } # writes "$1" → stdout
   ```
   - `ts` via `date -u +"%Y-%m-%dT%H:%M:%SZ"` (ISO 8601)
   - `trace` shared per invocation via `${HOOK_TRACE_ID:-$(uuidgen)}` (set once by the
     sourcing hook before calling emit_event for the first time)
   - `hook_name` derived from `${BASH_SOURCE[1]##*/}` (basename of the calling script)
   - Credential masking: if any key matches `*_token|*_key|*_secret|*_password` (case
     insensitive), value is replaced with `[REDACTED]`
   - If helper file is absent when sourced: hooks fall back to bare stderr JSONL with
     `event_type: hook.helper.missing`

4. **[impl]** Create `plugins/brain-factory/scripts/event-catalog.json` with all 27+
   event types pre-populated per AC-009. Each entry includes `event_type`, `hook_name`,
   `severity`, `fields` array, and `example` JSONL object.

5. **[green]** Run bats meta-lint / integration catalog tests — all pass.

6. **[green]** Run `shellcheck` and `shfmt -d -i 2` on `hooks/lib/hook-event-emit.sh` —
   clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `jq . scripts/event-catalog.json` | Valid JSON array; all entries have required fields | happy-path | BC-2.17.002 |
| `jq empty` on each `example` field | All pass | happy-path | BC-2.17.002 invariant 2 |
| Grep `emit_event` call sites in all hooks | All event_types in catalog | happy-path | BC-2.17.001 |
| Catalog entry with noun `event_type` | meta-lint.bats fails | error | BC-2.17.002 invariant 1 |
| Emit event with credential key | Value replaced with [REDACTED] in stderr output | security | BC-2.04.017 postcondition 5 |
| Source helper absent | Hook emits fallback JSONL + exits 2 + E-HOOK-002 | edge-case | BC-2.04.017 EC-001 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-008 | All hook emit sites have catalog rows | `tests/meta-lint.bats` or `tests/integration.bats` |
| VP-008 | All catalog entries have required fields | `tests/meta-lint.bats` |
| VP-008 | All example payloads valid JSON | `tests/meta-lint.bats` |
| VP-017 | `emit_event` writes to stderr only (no stdout contamination) | `tests/hook-event-emit.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-17-structured-event-catalog.md` and ADR-016:

1. `hooks/lib/hook-event-emit.sh` is a **sourced bash library**, not an executable script.
   Hook scripts call `. "${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"` before
   calling `emit_event` or `emit_verdict`.
2. `scripts/event-catalog.json` location is `${CLAUDE_PLUGIN_ROOT}/scripts/event-catalog.json`.
3. The catalog is a JSON array (not a markdown table). Machine-parseable by `jq`.
4. Event type naming: `<domain>.<past-tense-verb>` per SS-17 §Event-type naming convention.
   Domain: `quarantine`, `source`, `wiki`, `frontmatter`, `voice`, `publish`, `naming`,
   `attribution`, `session`, `brain`, `hook`.
5. The `meta-lint.bats` catalog completeness check must be a bats test, not a CI script
   separate from bats. This is within the 9-suite bats roster (or extends `meta-lint.bats`).
6. `emit_verdict` → stdout ONLY. `emit_event` → stderr ONLY. No exceptions.
7. The catalog is append-only. No entries are deleted in any story.

**Forbidden dependencies:**
- `hooks/lib/hook-event-emit.sh`: no external process calls except `date` and `uuidgen`.
- No Node.js, no Python, no jq dependency inside the emit helper itself (it must be
  bootstrappable without jq for edge-case fallback).

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.6+ | Catalog validation in tests |
| `date` | GNU coreutils | ISO 8601 timestamp generation |
| `uuidgen` | system utility | trace field UUID generation |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (`-i 2`) | CLAUDE.md §Conventions |

No Node.js required for the shim itself.

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/lib/hook-event-emit.sh` | Modify (replace stub) | Full implementation: emit_event + emit_verdict functions |
| `plugins/brain-factory/scripts/event-catalog.json` | Create | 27+ event entries, pre-populated |
| `plugins/brain-factory/tests/hook-event-emit.bats` | Create | Per-hook bats suite for the emit shim: emit_event stderr-only, emit_verdict stdout-only, credential masking, JSONL schema (≥ 3 @test blocks) |
| `plugins/brain-factory/tests/meta-lint.bats` | Extend | VP-008 catalog completeness assertions |

Files NOT to modify: individual hook scripts (they call the shim; STORY-006..STORY-013
implement them), `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-001 created `hooks/lib/hook-event-emit.sh` as a stub. STORY-006 through STORY-013
already reference the shim via `hooks/lib/hook-event-emit.sh` calls in their Tasks
sections — they depend on this story delivering the full implementation. The catalog
pre-population (AC-009) covers all 27 event types across all 13 hooks. Each hook story
(STORY-006..STORY-013) uses the same event types already listed in their own ACs — those
event type names are already final and must match the catalog rows exactly.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,000 |
| SS-17 subsystem design | ~1,500 |
| SS-04 hook registration matrix | ~500 |
| ADR-016 helper architecture | ~1,500 |
| BC-2.04.017, BC-2.17.001, BC-2.17.002 files | ~2,000 |
| VP-008, VP-017 files | ~800 |
| meta-lint.bats from prior stories | ~1,500 |
| event-catalog.json (27 entries) | ~2,000 |
| **Total** | **~13,800** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- BC-2.17.003 (stdout/stderr separation) and BC-2.17.004 (no credentials) are cross-cutting
  meta-lint invariants enforced in STORY-015, not in this story. The shim enforces the
  stream separation at the implementation level; STORY-015 adds the meta-lint bats test
  that scans hook scripts for direct echo-to-stdout violations.
- Individual hook implementations (STORY-006..STORY-013) — those stories call this shim
  but implement their own logic.

## Anchors

- BC-2.04.017: `behavioral-contracts/ss-04/BC-2.04.017.md`
- BC-2.17.001: `behavioral-contracts/ss-17/BC-2.17.001.md`
- BC-2.17.002: `behavioral-contracts/ss-17/BC-2.17.002.md`
- VP-008: `architecture/verification-properties/VP-008-hook-event-catalog-completeness.md`
- VP-017: `architecture/verification-properties/VP-017-hook-naming-and-attribution.md`
- SS-17: `architecture/subsystems/SS-17-structured-event-catalog.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
