# Red Gate Log — STORY-004

**Date:** 2026-05-28
**Test File:** `plugins/brain-factory/tests/brain-health-skill.bats`
**BC:** BC-2.01.006
**VP:** VP-024

## Result

RED GATE CONFIRMED — 30/30 tests fail. 0 tests pass.

## Failure Summary

All 30 tests fail because `plugins/brain-factory/skills/brain-health/run.sh` does not exist.
The primary failure mode is exit 127 (command not found) for tests 1–22 and 25–30.
Tests 23 and 24 fail because `brain-health-check.sh` does not yet reference `skills/brain-health/run.sh`.

| Test # | Test Name | Failure Reason |
|--------|-----------|----------------|
| 1 | healthy brain overall=GREEN exits 0 | exit 127 (run.sh not found) |
| 2 | healthy brain emits all six dimensions in JSON | exit 127 |
| 3 | healthy brain all six dimensions GREEN | exit 127 |
| 4 | overall=RED when any dimension is RED | exit 127 + jq parse error on empty output |
| 5 | overall=YELLOW when any dimension YELLOW and none RED | exit 127 |
| 6 | overall=GREEN only when all six dimensions GREEN | exit 127 |
| 7 | all dimension status values are GREEN YELLOW or RED uppercase | exit 127 |
| 8 | overall status value is GREEN YELLOW or RED uppercase | exit 127 |
| 9 | missing ingest-tokens.jsonl sources dimension GREEN | exit 127 |
| 10 | missing ingest-tokens.jsonl sources detail is No ingest history yet | exit 127 |
| 11 | token avg over 100K sources=YELLOW with token budget in detail | exit 127 |
| 12 | token avg over 200K sources=RED | exit 127 |
| 13 | token avg over 100K detail contains actual average value | exit 127 |
| 14 | missing STATE.md emits E-HEALTH-001 exit 2 | exit 127 (not 2 as required) |
| 15 | missing STATE.md emitted JSON has level=error | exit 127 |
| 16 | missing STATE.md error JSON has non-empty trace field | exit 127 |
| 17 | zero wiki pages wiki dimension YELLOW | exit 127 |
| 18 | zero wiki pages wiki detail is No wiki pages yet | exit 127 |
| 19 | last_checked field is present in JSON output | exit 127 |
| 20 | last_checked is valid ISO8601 UTC format | exit 127 |
| 21 | non-brain dir invocation does not crash (VP-024 health-callable) | exit 127 > 2 |
| 22 | non-brain dir emits structured JSON not raw bash error | exit 127 > 2 |
| 23 | brain-health-check.sh hook references skills/brain-health/run.sh | hook has 0 skill references |
| 24 | brain-health-check.sh does not re-implement dimension logic (thin-wrapper enforced) | hook has 0 skill references (skill_refs > 0 check fails) |
| 25 | brain-health run.sh passes shellcheck | [ -f run.sh ] fails (file absent) |
| 26 | brain-health run.sh passes shfmt normalization check | [ -f run.sh ] fails |
| 27 | brain-health run.sh starts with correct shebang | [ -f run.sh ] fails |
| 28 | brain-health run.sh has set -euo pipefail within first 10 lines | [ -f run.sh ] fails |
| 29 | brain-health run.sh does not use eval | [ -f run.sh ] fails |
| 30 | brain-health run.sh has no hardcoded .claude/templates paths | [ -f run.sh ] fails |

## Existing Tests — No Regression

`brain-health-check.bats` (22 tests for the SessionStart hook): 22/22 pass. No regression.

## AC Coverage Map

| AC | Tests Covering It |
|----|-------------------|
| AC-001 (six-dim JSON, exit 0, overall=GREEN) | 1, 2, 3 |
| AC-002 (overall aggregation: RED > YELLOW > GREEN) | 4, 5, 6 |
| AC-003 (status values uppercase GREEN/YELLOW/RED only) | 7, 8 |
| AC-004 (missing ingest-tokens.jsonl → sources=GREEN) | 9, 10 |
| AC-005 (token avg > 100K → YELLOW; > 200K → RED) | 11, 12, 13 |
| AC-006 (missing STATE.md → E-HEALTH-001 exit 2) | 14, 15, 16 |
| AC-007 (0 wiki pages → wiki=YELLOW) | 17, 18 |
| AC-008 (last_checked is ISO8601 UTC) | 19, 20 |
| AC-009 (non-brain dir → no crash, structured JSON) | 21, 22 |
| AC-010 (hook is thin wrapper over run.sh) | 23, 24 |
| Structural quality (shellcheck, shfmt, shebang, set -euo, no eval) | 25–30 |

## Handoff to Implementer

All 30 tests fail for the right reasons (file not found, not vacuously true).
The implementer must create:
1. `plugins/brain-factory/skills/brain-health/run.sh` — six-dimensional JSON skill
2. Refactor `plugins/brain-factory/hooks/brain-health-check.sh` to call `run.sh`

Make each test pass one at a time with minimum code. Do not modify test expectations.
