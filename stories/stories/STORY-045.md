---
artifact_type: story
story_id: STORY-045
epic_id: EPIC-02
title: "validate-page-type-policy.sh ERR trap JSONL alignment — sibling-sweep with hook ERR trap pattern"
status: draft
created: 2026-05-30
tdd_mode: strict
phase: 3
points: 2
priority: P1
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.007, BC-2.04.016, BC-2.04.017]
vps: []
dependencies: [STORY-010]
blocks: []
inputs:
  - plugins/brain-factory/hooks/validate-page-type-policy.sh
  - behavioral-contracts/ss-04/BC-2.04.016.md
  - behavioral-contracts/ss-04/BC-2.04.017.md
input-hash: ""
# Origin: D-PASS8-CS-01 — Wave 4 Gate 3 adversary finding M02 (also tracked as D-PASS8-CS-01).
# Canonical Principle Rule 3 anchor: explicit filing authorized as follow-up story at Wave 4 Gate 3
# (Wave 4 Gate 3 fix burst 2026-05-30). Concrete dependency: implementer sweep of validate-page-type-policy.sh
# ERR trap against sibling hook JSONL stderr pattern. Wave 5 maintenance sweep is the earliest anchor.
---

# STORY-045: `validate-page-type-policy.sh` ERR trap JSONL alignment

## Goal

Fix `validate-page-type-policy.sh` ERR trap to emit structured JSONL on stderr (consistent with all 8 sibling hooks) rather than plain-text echo on crash. The current implementation emits a plain-text string on ERR which violates BC-2.04.016 (stdout must be valid JSON on all exit paths, including crash) and BC-2.04.017 (hooks emit JSONL events on stderr via hook-event catalog).

## Background

- `validate-page-type-policy.sh` was delivered in Wave 3 STORY-010 (PR #12, commit c79fcca).
- 8 sibling hooks all emit JSONL on stderr for crash events via `emit_event` helper.
- `validate-page-type-policy.sh` ERR trap uses a plain-text echo instead of the canonical `emit_event` JSONL pattern.
- Wave 4 STORY-015 Pass 8 cross-story finding D-PASS8-CS-01 identified this. Deferred as out-of-STORY-015-scope with explicit story anchor per Canonical Principle Rule 3.

## Acceptance Criteria

- AC-001: `validate-page-type-policy.sh` ERR trap replaced with `emit_event` JSONL emission matching sibling hook pattern (event_type following BC-2.04.017 catalog naming, stderr output, no plain-text echo on crash).
- AC-002: On ERR trap trigger, stdout still contains a valid JSON error envelope (BC-2.04.016 fail-closed requirement), not a mix of plain-text and JSON.
- AC-003: New bats test verifies that on a simulated ERR condition, stdout is parseable JSON and stderr contains JSONL with the correct event_type.
- AC-004: `scripts/event-catalog.json` contains a registered entry for the ERR event_type emitted by this hook (BC-2.17.001 / BC-2.04.017 compliance).
- AC-005: Sibling-sweep: grep all 13 hooks for ERR trap pattern; confirm no other hook uses plain-text echo on crash (or document as follow-up).

## Owner

implementer

## Traceability

- Origin: D-PASS8-CS-01 (Wave 4 Gate 3 adversary finding M02 / STORY-015 Pass 8 cross-story deferral)
- Deferred from: STORY-015 delivery (out-of-scope — validate-page-type-policy.sh is STORY-010 deliverable; implementer domain)
- Target wave: Wave 5 maintenance sweep

## Changelog

### v0.1 (2026-05-30)

STORY-045 filed as follow-up story stub per Wave 4 Gate 3 fix burst (closes D-PASS8-CS-01 deferral with explicit story anchor per Canonical Principle Rule 3).
