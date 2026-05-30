# Demo Evidence Report — STORY-004

**Story:** /brain:health six-dimensional convergence skill
**Date:** 2026-05-29
**Product type:** CLI / bash plugin (shell command evidence)
**Verdict:** ALL ACs PASS

---

## AC-001 — Healthy brain overall=GREEN, exits 0, six dimensions emitted

**Test:** `BC_2_01_006: healthy brain overall=GREEN exits 0`

**Bats output:**
```
ok 1 BC_2_01_006: healthy brain overall=GREEN exits 0
ok 2 BC_2_01_006: healthy brain emits all six dimensions in JSON
ok 3 BC_2_01_006: healthy brain all six dimensions GREEN
```

**Verdict:** PASS

---

## AC-002 — Overall aggregation: RED > YELLOW > GREEN

**Test:** `BC_2_01_006: overall=RED when any dimension is RED` / `overall=YELLOW when any dimension YELLOW and none RED` / `overall=GREEN only when all six dimensions GREEN`

**Bats output:**
```
ok 4 BC_2_01_006: overall=RED when any dimension is RED
ok 5 BC_2_01_006: overall=YELLOW when any dimension YELLOW and none RED
ok 6 BC_2_01_006: overall=GREEN only when all six dimensions GREEN
```

**Verdict:** PASS

---

## AC-003 — Status values are exactly GREEN/YELLOW/RED uppercase only

**Test:** `BC_2_01_006: all dimension status values are GREEN YELLOW or RED uppercase`

**Bats output:**
```
ok 7 BC_2_01_006: all dimension status values are GREEN YELLOW or RED uppercase
ok 8 BC_2_01_006: overall status value is GREEN YELLOW or RED uppercase
```

**Verdict:** PASS

---

## AC-004 — Missing ingest-tokens.jsonl: sources GREEN, skip token check

**Test:** `BC_2_01_006: missing ingest-tokens.jsonl sources dimension GREEN`

**Bats output:**
```
ok 9 BC_2_01_006: missing ingest-tokens.jsonl sources dimension GREEN
ok 10 BC_2_01_006: missing ingest-tokens.jsonl sources detail is No ingest history yet
```

**Verdict:** PASS

---

## AC-005 — Token budget alert: YELLOW >100K, RED >150K

**Test:** `BC_2_01_006: token avg over 100K sources=YELLOW with token budget in detail`

**Bats output:**
```
ok 11 BC_2_01_006: token avg over 100K sources=YELLOW with token budget in detail
ok 12 BC_2_01_006: token avg over 150K sources=RED
ok 13 BC_2_01_006: token avg over 100K detail contains actual average value
```

**Verdict:** PASS

---

## AC-006 — Missing STATE.md: E-HEALTH-001 exit 2

**Test:** `BC_2_01_006: missing STATE.md emits E-HEALTH-001 exit 2`

**Bats output:**
```
ok 14 BC_2_01_006: missing STATE.md emits E-HEALTH-001 exit 2
ok 15 BC_2_01_006: missing STATE.md emitted JSON has level=error
ok 16 BC_2_01_006: missing STATE.md error JSON has non-empty trace field
```

**Verdict:** PASS

---

## AC-007 — 0 wiki pages: wiki YELLOW

**Test:** `BC_2_01_006: zero wiki pages wiki dimension YELLOW`

**Bats output:**
```
ok 17 BC_2_01_006: zero wiki pages wiki dimension YELLOW
ok 18 BC_2_01_006: zero wiki pages wiki detail is No wiki pages yet
```

**Verdict:** PASS

---

## AC-008 — last_checked ISO8601 UTC within 5 seconds

**Test:** `BC_2_01_006: last_checked is within 5 seconds of invocation time (AC-008 delta)`

**Bats output:**
```
ok 19 BC_2_01_006: last_checked field is present in JSON output
ok 20 BC_2_01_006: last_checked is valid ISO8601 UTC format
ok 21 BC_2_01_006: last_checked is within 5 seconds of invocation time (AC-008 delta)
```

**Verdict:** PASS

---

## AC-009 — Non-brain dir: no crash, structured JSON, exit ≤ 1

**Test:** `BC_2_01_006: non-brain dir invocation does not crash (VP-024 health-callable)`

**Bats output:**
```
ok 22 BC_2_01_006: non-brain dir invocation does not crash (VP-024 health-callable)
ok 23 BC_2_01_006: non-brain dir emits structured JSON not raw bash error
```

**Verdict:** PASS

---

## AC-010 — brain-health-check.sh is thin wrapper (no re-implementation)

**Test:** `BC_2_01_006: brain-health-check.sh hook references skills/brain-health/run.sh`

**Bats output:**
```
ok 24 BC_2_01_006: brain-health-check.sh hook references skills/brain-health/run.sh
ok 25 BC_2_01_006: brain-health-check.sh does not re-implement dimension logic (thin-wrapper enforced)
```

**Verdict:** PASS

---

## BC-2.01.006 PC5 — STATE.md writeback

**Bats output:**
```
ok 26 BC_2_01_006: after run overall_health is written to STATE.md frontmatter
ok 27 BC_2_01_006: after run last_health_check is written to STATE.md frontmatter
ok 28 BC_2_01_006: after run dimension statuses written to STATE.md frontmatter
ok 29 BC_2_01_006: after run STATE.md body content is preserved
ok 30 BC_2_01_006: after YELLOW run overall_health YELLOW is written to STATE.md
ok 37 BC_2_01_006: after YELLOW run red_dimensions written to STATE.md frontmatter
ok 38 BC_2_01_006: after GREEN run red_dimensions is empty list in STATE.md
ok 39 BC_2_01_006: after RED run red_dimensions contains RED dimension name in STATE.md
ok 40 BC_2_01_006: body with horizontal rule survives writeback cycle
ok 41 BC_2_01_006: JSON report includes writeback_status field
ok 42 BC_2_01_006: JSON report writeback_status is ok on successful healthy brain
ok 43 BC_2_01_006: zero-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged
ok 44 BC_2_01_006: one-marker STATE.md triggers skipped_malformed_frontmatter and leaves file unchanged
ok 45 BC_2_01_006: malformed YAML in well-fenced frontmatter triggers writeback_status=failed and leaves file unchanged
```

**Verdict:** PASS

---

## BC-2.04.014 — brain-health-check.sh SessionStart hook (43 tests)

**Full bats output:**
```
1..43
ok 1 test_BC_2_04_014_hook_starts_with_correct_shebang
ok 2 test_BC_2_04_014_hook_has_set_euo_pipefail_within_first_10_lines
ok 3 test_BC_2_04_014_hook_does_not_use_eval
ok 4 test_BC_2_04_014_hook_never_exits_2
ok 5 test_BC_2_04_014_hook_never_exits_1
ok 6 test_BC_2_04_014_non_brain_dir_exits_0_with_skipped_event
ok 7 test_BC_2_04_014_non_brain_dir_stderr_contains_skipped_event
ok 8 test_BC_2_04_014_green_state_exits_0
ok 9 test_BC_2_04_014_green_state_stdout_contains_GREEN
ok 10 test_BC_2_04_014_green_stdout_has_continue_true
ok 11 test_BC_2_04_014_green_stdout_has_systemMessage_not_message
ok 12 test_BC_2_04_014_green_stdout_hookEventName_is_SessionStart
ok 13 test_BC_2_04_014_green_stdout_additionalContext_contains_GREEN
ok 14 test_BC_2_04_014_red_state_exits_0_with_E_HEALTH_002
ok 15 test_BC_2_04_014_red_state_exit_is_0_not_1_or_2
ok 16 test_BC_2_04_014_red_event_has_red_dimensions_field
ok 17 test_BC_2_04_014_red_stdout_has_continue_true
ok 18 test_BC_2_04_014_red_stdout_additionalContext_is_E_HEALTH_002
ok 19 test_BC_2_04_014_red_stdout_unhealthy_state_is_true
ok 20 test_BC_2_04_014_red_stdout_red_dimensions_is_nonempty_array
ok 21 test_BC_2_04_014_malformed_state_exits_0_advisory
ok 22 test_BC_2_04_014_malformed_state_exit_is_0_not_1_or_2
ok 23 test_BC_2_04_014_unreadable_stdout_additionalContext_is_E_HEALTH_003
ok 24 test_BC_2_04_014_unreadable_stdout_unhealthy_state_is_true
ok 25 test_BC_2_04_014_green_emits_checked_event
ok 26 test_BC_2_04_014_red_emits_checked_event
ok 27 test_BC_2_04_014_skipped_emits_skipped_event
ok 28 test_BC_2_04_014_malformed_state_emits_checked_event_with_unreadable_state
ok 29 test_BC_2_04_014_skipped_event_has_path_field
ok 30 test_BC_2_04_014_shellcheck_clean
ok 31 test_BC_2_04_014_shfmt_normalized
ok 32 test_BC_2_04_014_red_systemMessage_starts_with_health_status_issues_clause
ok 33 test_BC_2_04_014_red_systemMessage_uses_colon_space_name_detail_separator
ok 34 test_BC_2_04_014_red_systemMessage_uses_semicolon_space_entry_separator
ok 35 test_BC_2_04_014_red_systemMessage_rejects_old_paren_format
ok 36 test_BC_2_04_014_red_systemMessage_rejects_old_comma_format
ok 37 test_BC_2_04_014_skipped_stdout_has_only_continue_key
ok 38 test_BC_2_04_014_skipped_stdout_continue_value_is_true
ok 39 test_BC_2_04_014_skipped_stdout_has_no_systemMessage
ok 40 test_BC_2_04_014_yellow_empty_red_dims_systemMessage_contains_fallback_clause
ok 41 test_BC_2_04_014_yellow_empty_red_dims_systemMessage_still_has_issues_clause
ok 42 test_BC_2_04_014_yq_empty_return_on_malformed_yaml_yields_UNREADABLE_not_GREEN
ok 43 test_BC_2_04_014_hooks_json_SessionStart_entry_includes_brain_health_check
```

**Verdict:** ALL 43 PASS

---

## Static Analysis

**shellcheck:**
```
$ shellcheck plugins/brain-factory/skills/brain-health/run.sh plugins/brain-factory/hooks/brain-health-check.sh
shellcheck PASS: 0 warnings
```

**shfmt:**
```
$ shfmt -d -i 2 plugins/brain-factory/skills/brain-health/run.sh plugins/brain-factory/hooks/brain-health-check.sh
shfmt PASS: 0 diff
```

---

## Summary

| AC | Description | Result |
|----|-------------|--------|
| AC-001 | Healthy brain overall=GREEN exits 0 | PASS |
| AC-002 | Overall aggregation logic (RED > YELLOW > GREEN) | PASS |
| AC-003 | Status values uppercase only | PASS |
| AC-004 | Missing ingest-tokens.jsonl: sources GREEN | PASS |
| AC-005 | Token alert YELLOW >100K / RED >150K | PASS |
| AC-006 | Missing STATE.md: E-HEALTH-001 exit 2 | PASS |
| AC-007 | 0 wiki pages: wiki YELLOW | PASS |
| AC-008 | last_checked ISO8601 within 5s | PASS |
| AC-009 | Non-brain dir: no crash, structured JSON | PASS |
| AC-010 | brain-health-check.sh is thin wrapper | PASS |
| BC-2.01.006 PC5 | STATE.md writeback (15 tests) | PASS |
| BC-2.04.014 | SessionStart hook (43 tests) | PASS |
| shellcheck | 0 warnings | PASS |
| shfmt | 0 diff | PASS |

**Total: 88/88 bats tests pass. shellcheck clean. shfmt normalized.**
