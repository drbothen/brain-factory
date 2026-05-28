---
name: brain-health
description: "Emit a six-dimensional JSON health report for the current brain vault, covering Capture, Sources, Wiki, Synthesis, Output, and Reflection."
argument-hint: ""
allowed-tools:
  - Bash
  - Read
---

## Iron Law

Never exit without emitting structured JSON — either the full six-dimensional report or the E-HEALTH-001 error envelope.

## Red Flags

- Running outside a brain vault directory (no `.brain/STATE.md`) — check with `[ -f .brain/STATE.md ]` before invoking
- Interpreting a YELLOW result as a failure — YELLOW is informational, not blocking
- Modifying any file in the brain vault EXCEPT `.brain/STATE.md` — the skill writes computed health back to STATE.md frontmatter (BC-2.01.006 v1.3 Postcondition 5); all other vault files are untouched

## Announce-at-Start

"Running /brain:health to check all six convergence dimensions..."

## Procedure

1. Set `BRAIN_ROOT` to the current brain vault directory (default: $PWD).
2. Execute `bash "${CLAUDE_PLUGIN_ROOT}/skills/brain-health/run.sh"` with `BRAIN_ROOT` set.
3. Parse the JSON output from stdout.
4. If exit code is 2, display the `message` field from the error envelope and stop.
5. If exit code is 0, display a summary of each dimension's status and the overall result to the user.

## Quality Bar

- Exit 0 with valid JSON health report: all six dimension keys present, each with `status` (GREEN/YELLOW/RED) and `detail` string.
- Exit 2 with E-HEALTH-001 JSON envelope only when `.brain/STATE.md` is missing or unreadable.
- `.brain/STATE.md` frontmatter updated with computed `overall_health`, `last_health_check`, and six `dimensions` statuses (BC-2.01.006 v1.3 Postcondition 5); STATE.md body (markdown content) is preserved verbatim.
- `last_checked` field is a valid ISO8601 UTC timestamp.

## Output

Structured JSON to stdout (from `run.sh`):

```json
{
  "dimensions": {
    "capture":    {"status": "GREEN|YELLOW|RED", "detail": "..."},
    "sources":    {"status": "GREEN|YELLOW|RED", "detail": "..."},
    "wiki":       {"status": "GREEN|YELLOW|RED", "detail": "..."},
    "synthesis":  {"status": "GREEN|YELLOW|RED", "detail": "..."},
    "output":     {"status": "GREEN|YELLOW|RED", "detail": "..."},
    "reflection": {"status": "GREEN|YELLOW|RED", "detail": "..."}
  },
  "overall": "GREEN|YELLOW|RED",
  "last_checked": "YYYY-MM-DDTHH:MM:SSZ"
}
```

On error (STATE.md missing):

```json
{"level":"error","code":"E-HEALTH-001","message":"...","trace":"<uuid>"}
```
