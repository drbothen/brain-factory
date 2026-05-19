---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.008: `validate-voice-avoid-list.sh` advises on brief drafts containing voice-avoid-list terms (exit 1)

## Description

`validate-voice-avoid-list.sh` fires on PostToolUse (Write|Edit on `briefs/content/*-draft.md`). It checks the written draft against the 30-entry voice avoid-list in `rules/voice-avoid-list.txt`. Unlike hard-block hooks (exit 2), this hook exits 1 (advisory) — the write proceeds but a warning is surfaced. This preserves author control while making voice-pattern violations visible. The operator can override via policy.

## Preconditions

1. PostToolUse fires on Write|Edit targeting `briefs/content/*-draft.md`.
2. `rules/voice-avoid-list.txt` exists and is readable at `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`.

## Postconditions

**On avoid-list match found:**
1. Hook exits 1 (advisory).
2. stdout: `{"verdict": "advise", "code": "E-VOICE-001", "matches": ["<term1>", "<term2>"], "message": "Voice avoid-list matches found. Review before finalizing.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "voice.avoid_list.matched", "hook_name": "validate-voice-avoid-list.sh", "path": "<path>", "match_count": N}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On no avoid-list match:**
1. Hook exits 0. stdout: `{"verdict": "allow", ...}`.
2. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "voice.avoid_list.passed", "hook_name": "validate-voice-avoid-list.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

## Invariants

1. This hook NEVER exits 2 (block). Voice guidance is advisory-only.
2. All 30 entries in `rules/voice-avoid-list.txt` are checked.
3. Fail-closed for missing avoid-list: if `rules/voice-avoid-list.txt` is absent, hook exits 1 with E-VOICE-002 "Voice avoid-list not found — check plugin installation." (Advisory, not block — the write still proceeds.)

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Draft contains 0 avoid-list matches | Exit 0. |
| EC-002 | Draft contains multiple avoid-list matches | All matches reported in `matches` array. Exit 1. |
| EC-003 | `rules/voice-avoid-list.txt` missing | Exit 1 with E-VOICE-002 (advisory only). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Draft with "game-changer" (avoid-list term) | `{"verdict": "advise", "matches": ["game-changer"], ...}`; exit 1 | happy-path |
| Draft with no avoid-list terms | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Draft with 3 avoid-list terms | `{"matches": ["<term1>", "<term2>", "<term3>"], ...}`; exit 1 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | Avoid-list match → exit 1 (not 2) | bats tests/validate-voice-avoid-list.bats |
| (no VP — P1) | All 30 avoid-list terms trigger advisory | bats tests/validate-voice-avoid-list.bats (parameterized) |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#10 `validate-voice-avoid-list.sh`) and §Scope §Additional v0.x deliverables ("30-entry voice avoid-list in `rules/voice-avoid-list.txt`"). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | STORY-010 |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#10); §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.08.004 — related to (voice avoid-list also described at content-writing layer)

## Changelog

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-010 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-voice-avoid-list.bats` (2 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
