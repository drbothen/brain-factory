---
artifact_type: story
story_id: STORY-046
epic_id: EPIC-02
title: "quarantine-fetch.sh ERR trap telemetry — emit JSONL on crash with fail-closed JSON stdout"
status: draft
created: 2026-05-30
tdd_mode: strict
phase: 3
points: 2
priority: P1
subsystems: [SS-04, SS-10]
behavioral_contracts: [BC-2.04.001, BC-2.04.016, BC-2.04.017, BC-2.10.002]
vps: []
dependencies: [STORY-006]
blocks: []
inputs:
  - plugins/brain-factory/hooks/quarantine-fetch.sh
  - behavioral-contracts/ss-04/BC-2.04.016.md
  - behavioral-contracts/ss-04/BC-2.04.017.md
  - behavioral-contracts/ss-10/BC-2.10.002.md
input-hash: ""
# Origin: D-PASS8-CS-02 — Wave 4 Gate 3 adversary finding L01 (also tracked as D-PASS8-CS-02).
# Canonical Principle Rule 3 anchor: explicit filing authorized as follow-up story at Wave 4 Gate 3
# (Wave 4 Gate 3 fix burst 2026-05-30). Concrete dependency: implementer fix of quarantine-fetch.sh
# silent ERR trap. Wave 5 maintenance sweep is the earliest anchor.
---

# STORY-046: `quarantine-fetch.sh` ERR trap telemetry — emit JSONL on crash with fail-closed JSON stdout

## Goal

Fix `quarantine-fetch.sh` ERR trap from silent `trap 'exit 2' ERR` to the canonical pattern: emit structured JSONL on stderr via `emit_event` helper AND emit a valid JSON error envelope on stdout before exiting 2. The current silent trap violates BC-2.04.016 (stdout must be valid JSON on all exit paths) and BC-2.04.017 (hooks emit JSONL events on stderr via hook-event catalog).

## Background

- `quarantine-fetch.sh` is the security-critical prompt-injection quarantine hook (PreToolUse on WebFetch), delivered in Wave 2 STORY-006 (PR #7, commit ce29e8f).
- Current ERR trap: `trap 'exit 2' ERR` — silent. On crash: no stdout JSON, no stderr JSONL.
- BC-2.04.016 requires every hook to emit valid JSON on stdout on ALL exit paths (EC-001 fail-closed).
- BC-2.04.017 requires JSONL stderr emission for crash/error events via the hook-event catalog.
- This is a security-critical hook — silent failure could mask a quarantine bypass under certain crash conditions.
- Wave 4 STORY-015 Pass 8 cross-story finding D-PASS8-CS-02 identified this. Deferred as out-of-STORY-015-scope with explicit story anchor per Canonical Principle Rule 3.

## Acceptance Criteria

- AC-001: `quarantine-fetch.sh` ERR trap replaced with a handler that (a) emits `{"continue":false,"decision":"block","hookSpecificOutput":{"error":"quarantine hook crash — fail closed","code":"E-QUARANTINE-005"}}` to stdout and (b) calls `emit_event` with an appropriate JSONL error event on stderr, before `exit 2`.
- AC-002: Error code `E-QUARANTINE-005` registered in `specs/prd/error-taxonomy.md` under SS-10 (quarantine errors).
- AC-003: Event type for the ERR crash event registered in `scripts/event-catalog.json` (BC-2.17.001 compliance).
- AC-004: New bats test: simulate ERR condition → verify stdout is parseable JSON with `continue:false` and `code:E-QUARANTINE-005`; verify stderr contains JSONL with the registered event_type.
- AC-005: `quarantine-check` SKILL.md documentation updated to note fail-closed behavior on hook crash (if relevant to operator-facing SKILL.md).

## Owner

implementer

## Traceability

- Origin: D-PASS8-CS-02 (Wave 4 Gate 3 adversary finding L01 / STORY-015 Pass 8 cross-story deferral)
- Deferred from: STORY-015 delivery (out-of-scope — quarantine-fetch.sh is STORY-006 deliverable; implementer domain)
- Target wave: Wave 5 maintenance sweep

## Changelog

### v0.1 (2026-05-30)

STORY-046 filed as follow-up story stub per Wave 4 Gate 3 fix burst (closes D-PASS8-CS-02 deferral with explicit story anchor per Canonical Principle Rule 3).
