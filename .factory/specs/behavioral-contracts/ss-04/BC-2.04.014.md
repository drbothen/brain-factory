---
document_type: behavioral-contract
level: L3
version: "1.6"
status: active
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: ["2026-05-28", "2026-05-29"]
---

# Behavioral Contract BC-2.04.014: `brain-health-check.sh` surfaces convergence state on SessionStart (always exits 0; advisory delivered via systemMessage)

## Description

`brain-health-check.sh` fires on the SessionStart event. It reads `.brain/STATE.md` frontmatter and emits a one-line convergence summary to the operator via the `systemMessage` field. The summary takes the form `Brain health: <state>. Issues: <name>: <detail>; ...` derived from the `red_dimensions` array written by the last `/brain:health` invocation. This gives the operator immediate situational awareness at the start of each session without requiring a manual `/brain:health` invocation. The hook ALWAYS exits 0 — per ADR-002 v2.0, operator-visible advisories are delivered via `systemMessage` (exit 0), never via exit 1 (which goes to the debug log only and is not shown to the operator).

## Preconditions

1. SessionStart event fires.
2. Working directory is a brain (`.brain/STATE.md` exists) OR is not a brain (in which case the hook exits 0 and emits `brain.health.skipped` per NFR-011).

## Postconditions

**In a valid brain with GREEN overall state:**
1. Hook exits 0.
2. stdout: `{"continue": true, "systemMessage": "Brain health: GREEN. All dimensions healthy.", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "overall_health: GREEN"}}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "brain.health.checked", "hook_name": "brain-health-check.sh", "overall_state": "GREEN"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**In a valid brain with YELLOW or RED state:**
1. Hook exits 0 (advisory delivered via systemMessage per ADR-002 v2.0 — exit 1 is debug-log only and NOT shown to the operator).
2. stdout: `{"continue": true, "systemMessage": "Brain health: <YELLOW|RED>. Issues: <name>: <detail>; ...", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "E-HEALTH-002", "unhealthy_state": true, "red_dimensions": ["<dim>"]}}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "brain.health.checked", "hook_name": "brain-health-check.sh", "overall_state": "<YELLOW|RED>", "red_dimensions": ["<dim>"]}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**Not in a brain directory (`.brain/STATE.md` absent):**
1. Hook exits 0 (no banner shown — not every session is a brain session).
2. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "brain.health.skipped", "hook_name": "brain-health-check.sh", "reason": "not_a_brain_session", "path": "<cwd>"}` (per BC-2.04.017 universal emission requirement + NFR-011).

## Invariants

1. This hook NEVER exits 2 (a SessionStart block would prevent the session from opening — unacceptable).
2. The banner is concise: one line per RED/YELLOW dimension, showing dimension name and issue summary.
3. The six canonical dimension names used in `.brain/STATE.md` frontmatter and any banner output are: `capture`, `sources`, `wiki`, `synthesis`, `output`, `reflection` — per BC-2.01.006 invariant 1 and `docs/planning/llm-second-brain-phased-build-plan.md` §Six-dimensional convergence. Any test fixture or STATE.md content using other names (e.g., `briefs`, `publishing`, `voice`, `structural`) is non-conformant.
4. This hook NEVER exits 1 (per ADR-002 v2.0: exit 1 stderr goes to the debug log only and is NOT shown to the operator; advisories MUST be delivered via stdout `systemMessage` field + exit 0). Hook exit code is exactly 0 across all execution paths.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Not in a brain directory | Exit 0; emit `brain.health.skipped` JSONL event to stderr (NFR-011 + BC-2.04.017). |
| EC-002 | `.brain/STATE.md` exists but is malformed | Exit 0 with advisory delivered via systemMessage: "Brain STATE.md unreadable — run /brain:health for diagnosis."; `hookSpecificOutput.unhealthy_state=true`. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| SessionStart in healthy brain | `{"continue": true, "systemMessage": "Brain health: GREEN. All dimensions healthy.", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "overall_health: GREEN"}}`; exit 0 | happy-path |
| SessionStart in brain with RED wiki dimension | `{"continue": true, "systemMessage": "Brain health: RED. Issues: wiki: ...", "hookSpecificOutput": {"hookEventName": "SessionStart", "additionalContext": "E-HEALTH-002", "unhealthy_state": true, "red_dimensions": ["wiki"]}}`; exit 0 | edge-case |
| SessionStart outside a brain directory | stderr: `{"event_type": "brain.health.skipped", ...}`; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| (no VP — P1) | GREEN brain → exit 0 | bats tests/brain-health-check.bats |
| (no VP — P1) | RED dimension → exit 0 (advisory via systemMessage; never exit 1 or 2) | bats tests/brain-health-check.bats |
| (no VP — P1) | Non-brain directory → exit 0 + `brain.health.skipped` event on stderr | bats tests/brain-health-check.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#1 `brain-health-check.sh`) and §Scope §Additional v0.x deliverables ("Six-dimensional convergence tracking... User-visible via `/brain:health` and SessionStart hook banner"). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | STORY-013 |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#1); §Scope §Additional v0.x deliverables |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.01.006 — related to (/brain:health skill surfaces the same dimensions)

## Changelog

### v1.6 (2026-05-29)

**INVARIANT COMPLETENESS FIX (F-P10-I02):** Added Invariant 4 codifying that this hook NEVER exits 1, per ADR-002 v2.0 (exit 1 stderr is debug-log only and not shown to the operator; advisories must be delivered via stdout `systemMessage` + exit 0). Pass 9 (v1.5) had swept all other BC sections to "ALWAYS exits 0" semantics — H1 title, Description, Postconditions, EC-002, Canonical Test Vectors, and Verification Properties were all updated. Invariants was the only section not updated, creating a spec-vs-test asymmetry: `test_BC_2_04_014_hook_never_exits_1` (brain-health-check.bats lines 119–124) already enforced the property; the BC now documents the invariant the test verifies. No other BC sections required changes — Pass-9's sweep was otherwise complete. Sibling sweep per TD-VSDD-060: BC-2.04.008 (`exit 1` advisory on PostToolUse), BC-2.04.013 (`exit 1` on Stop), and BC-2.04.016 (generic hook contract enumerating 0/1/2) all correctly retain `exit 1` semantics for their respective non-SessionStart hooks and are unaffected.

### v1.5 (2026-05-28)

**ADR-002 v2.0 FULL ALIGNMENT (F-P9-C01 + F-P9-C02 + F-P9-I01 + DI-003 retirement):** Complete rewrite of all exit-code and stdout-schema references to match ADR-002 v2.0 verified May 2026 Claude Code hook protocol. Prior versions contained the v1.0-era custom verdict envelope (`{"verdict": "allow|advise|block", ...}`) and incorrect exit 1 advisory semantics — both superseded by ADR-002 v2.0.

Changes in this version:
- **H1 title:** "(exit 0 or 1)" → "(always exits 0; advisory delivered via systemMessage)" — accurately reflects the ADR-002 v2.0 contract.
- **Description:** Rewrote to accurately state (a) the hook emits a one-line summary via `systemMessage`, not a "six-dimensional banner"; (b) the summary is derived from `red_dimensions` array; (c) hook ALWAYS exits 0; (d) exit 1 is debug-log only and NOT shown to the operator per ADR-002 v2.0. Closes F-P9-I01 (misleading "six-dimensional banner" phrasing per BC-DIMENSION-RECONCILIATION §BC-2.04.014 Dimension Names Clarification — the hook never enumerates dimension names).
- **Postconditions (GREEN state):** `{"verdict": "allow", ...}` → `{"continue": true, "systemMessage": "Brain health: GREEN...", "hookSpecificOutput": {...}}`.
- **Postconditions (YELLOW/RED state):** exit 1 → exit 0; `{"verdict": "advise", ...}` → `{"continue": true, "systemMessage": "Brain health: <state>. Issues: ...", "hookSpecificOutput": {"unhealthy_state": true, "red_dimensions": [...]}}`.
- **EC-002:** "Exit 1 with advisory" → "Exit 0 with advisory delivered via systemMessage; hookSpecificOutput.unhealthy_state=true".
- **Canonical Test Vectors:** All rows updated. RED-dimension row: exit 1 → exit 0; `{"verdict": "advise", ...}` → native Claude Code schema.
- **Verification Properties:** "RED dimension → exit 1 (never 2)" → "RED dimension → exit 0 (advisory via systemMessage; never exit 1 or 2)".
- **Invariant 1** ("hook NEVER exits 2") verified correct — kept unchanged.
- **Invariant 3** (canonical dimension names) verified correct — kept unchanged.

DI-003 (deferred exit-code narrative drift item) is fully closed by this version. The deferral lacked the three required criteria under CLAUDE.md Canonical Principle Rule 3 (explicit human direction, concrete future dependency, specific future story anchor) — per Rule 4, AI-built defects are AI responsibility to fix in scope.

### v1.4 (2026-05-28)

**DIMENSION RECONCILIATION (BC-DIMENSION-RECONCILIATION.md):** Added Invariant 3 codifying the canonical six dimension names (capture / sources / wiki / synthesis / output / reflection) as the authoritative vocabulary for STATE.md frontmatter and banner output. This closes the vocabulary collision surfaced by STORY-004 Pass 1 adversary review. No change to postconditions or exit-code semantics.

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-013 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/brain-health-check.bats` (3 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
