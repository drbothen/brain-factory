---
document_type: behavioral-contract
level: L3
version: "1.2"
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

# Behavioral Contract BC-2.04.007: `validate-page-type-policy.sh` blocks wiki writes to invalid wiki type directories (exit 2)

## Description

`validate-page-type-policy.sh` fires on PostToolUse (Write|Edit on `wiki/*`). It validates that the file path matches one of the 6 valid wiki type directories: `wiki/concepts/`, `wiki/people/`, `wiki/frameworks/`, `wiki/syntheses/`, `wiki/observations/`, `wiki/questions/`. Writes to undefined subtypes (e.g., `wiki/tools/`) are blocked. This prevents wiki taxonomy drift over time.

## Preconditions

1. PostToolUse fires on Write|Edit targeting `wiki/**`.
2. The file path is extractable from the hook's stdin payload.

## Postconditions

**On invalid wiki type directory:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-WIKI-005", "message": "Invalid wiki type directory '<type>' in path <path>. Must be one of: concepts, people, frameworks, syntheses, observations, questions.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "wiki.page_type.rejected", "hook_name": "validate-page-type-policy.sh", "path": "<path>", "invalid_type": "<type>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On valid wiki type:**
1. Hook exits 0.
2. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "wiki.page_type.accepted", "hook_name": "validate-page-type-policy.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

## Invariants

1. Valid wiki type directories: `concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions` (6 values; matches plan.md §3.4).
2. Direct writes to `wiki/` root (not in a type subdirectory) are also blocked with E-WIKI-006.
3. `wiki/index.md` and `wiki/log.md` are NOT type directories — they are exempt from this check. The hook must detect these known exceptions.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Write to `wiki/index.md` | Exempt (not a type directory). Exit 0 and defer to index-log-coherence hook. |
| EC-002 | Write to `wiki/log.md` | Exempt. Exit 0. |
| EC-003 | Write to `wiki/tools/some-page.md` | E-WIKI-005. Exit 2. |
| EC-004 | Write to `wiki/concepts/my-page.md` (valid) | Exit 0. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Path: `wiki/concepts/ai-agents.md` | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Path: `wiki/tools/hammer.md` | `{"verdict": "block", "code": "E-WIKI-005", ...}`; exit 2 | error |
| Path: `wiki/index.md` | `{"verdict": "allow", ...}`; exit 0 (exempt) | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-002 | All 6 valid types pass | bats tests/validate-page-type-policy.bats (parameterized) |
| VP-002 | Invalid type → exit 2 | bats tests/validate-page-type-policy.bats |
| VP-002 | index.md and log.md exempt | bats tests/validate-page-type-policy.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#9 `validate-page-type-policy.sh`) and §Scalability Design Principles §3 ("wiki/{type}/{slug}.md; 6 wiki types per plan.md §3.4"). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#9); §Scalability Design Principles §3 |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.05.005 — depends on (type taxonomy defined in wiki layer BC)

## Changelog

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/validate-page-type-policy.bats` (3 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
