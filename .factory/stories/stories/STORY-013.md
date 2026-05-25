---
artifact_type: story
story_id: STORY-013
epic_id: EPIC-02
title: "flush-state-and-commit.sh and brain-health-check.sh: session Stop commit and SessionStart health banner"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 3
priority: P1
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.013, BC-2.04.014]
vps: []
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.013.md
  - behavioral-contracts/ss-04/BC-2.04.014.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Note: BC-2.04.013 and BC-2.04.014 are both P1 — no dedicated VP; bats coverage
# is through per-hook .bats files (flush-state-and-commit.bats, brain-health-check.bats;
# no formal VP-NNN assigned per VP-INDEX).
---

# STORY-013: flush-state-and-commit.sh and brain-health-check.sh — session Stop commit and SessionStart health banner

## Goal

Implement two lifecycle hooks that fire at session boundaries, not at tool-call time.
`flush-state-and-commit.sh` fires on the Stop event: it auto-commits any uncommitted
brain changes using the `brain(auto):` conventional-commit prefix, preventing work loss
at session close. `brain-health-check.sh` fires on SessionStart: it reads
`.brain/STATE.md` and emits the six-dimensional convergence state as a banner, giving
operators immediate situational awareness. Both are advisory-or-allow-only hooks (exit
0 or exit 1 maximum) — neither may exit 2, as blocking session open/close is
unacceptable UX.

## User Value

As a brain operator, I want my uncommitted brain changes auto-committed when I close
Claude Code so I never lose an ingest session's work, and I want a health banner
showing my brain's current convergence state when I open Claude Code so I can orient
immediately without running `/brain:health` manually.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.013 | `flush-state-and-commit.sh` commits brain state on session Stop (exit 0 or advisory) | P1 |
| BC-2.04.014 | `brain-health-check.sh` surfaces six-dimensional convergence state on SessionStart (exit 0 or 1) | P1 |

## Acceptance Criteria

### Flush State and Commit (BC-2.04.013)

**AC-001** — `flush-state-and-commit.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin using `jq`, never
uses `eval`, and every `exit` uses `0` or `1` only — NEVER exits 2.
(traces to BC-2.04.013 invariant 2; BC-2.04.016 invariants 1–3)

**AC-002** — When called in a directory with uncommitted changes, the hook performs
`git add -A` and `git commit -m "brain(auto): flush session state"` (conventional-commit
prefix), exits 0, and stdout contains
`{"verdict":"allow","message":"Session state committed: <short-sha>",...}`.
(traces to BC-2.04.013 postconditions on uncommitted changes: 1–3)

**AC-003** — When called in a directory with no uncommitted changes, the hook exits 0
and stdout contains `{"verdict":"allow","message":"No changes to flush.",...}`.
(traces to BC-2.04.013 postconditions on no changes: 1–2)

**AC-004** — When `git commit` fails (e.g., pre-commit hook failure), the hook exits 1
with `"verdict":"advise"` and `"code":"E-FLUSH-001"` in stdout. The session still closes
(exit 1 is advisory, not a block).
(traces to BC-2.04.013 postconditions on git failure: 1–2; edge case EC-001)

**AC-005** — When called outside a git repository (`.git` absent), the hook exits 0
immediately with no commit attempted.
(traces to BC-2.04.013 edge case EC-002)

**AC-006** — The auto-commit message always uses the prefix `brain(auto):` — no
variation or AI attribution strings are acceptable in the commit message.
(traces to BC-2.04.013 invariant 1)

**AC-007** — The hook does NOT push to remote under any condition.
(traces to BC-2.04.013 invariant 3)

**AC-008** — On successful commit, stderr contains JSONL with
`"event_type":"session.state.committed"` and `"sha":"<short-sha>"`. On no-op, stderr
contains `"event_type":"session.state.flushed"` with `"committed":false`. On git failure,
stderr contains `"event_type":"session.state.commit_failed"` with `"error":"<msg>"`.
(traces to BC-2.04.013 postconditions: commit step 4, no-change step 3, failure step 3)

### Brain Health Check (BC-2.04.014)

**AC-009** — `brain-health-check.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin using `jq`, never
uses `eval`, and every `exit` uses `0` or `1` only — NEVER exits 2.
(traces to BC-2.04.014 invariant 1; BC-2.04.016 invariants 1–3)

**AC-010** — When `.brain/STATE.md` does not exist in the working directory, the hook
exits 0 and emits `"event_type":"brain.health.skipped"` on stderr with
`"reason":"not_a_brain_session"`.
(traces to BC-2.04.014 postconditions on non-brain: 1–2; invariant per NFR-011)

**AC-011** — When `.brain/STATE.md` exists and the overall state is GREEN, the hook exits
0 and stdout contains `{"verdict":"allow","message":"Brain health: GREEN. <summary>",...}`.
(traces to BC-2.04.014 postconditions on GREEN: 1–2)

**AC-012** — When `.brain/STATE.md` exists and any dimension is RED, the hook exits 1
and stdout contains `{"verdict":"advise","code":"E-HEALTH-002","message":"Brain health:
RED. <dimension summaries>",...}`.
(traces to BC-2.04.014 postconditions on YELLOW/RED: 1–2; edge case EC-002 would produce
exit 1 for malformed STATE.md)

**AC-013** — The health banner is concise: one summary line per RED/YELLOW dimension
showing dimension name and issue. Long multi-page dumps are NOT acceptable.
(traces to BC-2.04.014 invariant 2)

**AC-014** — When `.brain/STATE.md` exists but is malformed (unparseable YAML), the hook
exits 1 with advisory message "Brain STATE.md unreadable — run /brain:health for
diagnosis."
(traces to BC-2.04.014 edge case EC-002)

**AC-015** — On any exit path, stderr contains at least one JSONL event:
`brain.health.checked` (GREEN/RED), `brain.health.skipped` (non-brain), or
`brain.health.checked` with `"overall_state":"UNREADABLE"` (malformed STATE.md).
(traces to BC-2.04.017 universal emission requirement)

**AC-016** — `shellcheck` exits 0 on both scripts. `shfmt -d -i 2` produces no diff.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[stub]** Confirm stub files exist from STORY-001:
   `plugins/brain-factory/hooks/flush-state-and-commit.sh` and
   `plugins/brain-factory/hooks/brain-health-check.sh`. If absent, create canonical stubs.

2. **[failing test — Red Gate]** Create `plugins/brain-factory/tests/flush-state-and-commit.bats`
   and `plugins/brain-factory/tests/brain-health-check.bats` with test cases in failing state:
   - `flush-state-and-commit.bats` (≥ 3 `@test` blocks): uncommitted changes → commit
     performed + exit 0; no changes → exit 0 + "No changes to flush"; git commit fails →
     exit 1 + E-FLUSH-001; outside git repo → exit 0 no-op; auto-commit message uses
     `brain(auto):` prefix; hook NEVER exits 2.
   - `brain-health-check.bats` (≥ 3 `@test` blocks): non-brain dir (no `.brain/STATE.md`)
     → exit 0 + `brain.health.skipped`; GREEN STATE.md → exit 0 + "Brain health: GREEN";
     RED STATE.md → exit 1 + E-HEALTH-002; malformed STATE.md → exit 1 + advisory; hook
     NEVER exits 2.
   Create fixtures: `stop-event-with-changes.json`, `stop-event-no-changes.json`,
   `session-start-green-brain.json`, `session-start-red-brain.json`,
   `session-start-non-brain.json`.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement `plugins/brain-factory/hooks/flush-state-and-commit.sh`
   per BC-2.04.013:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Check if `.git` directory exists; if not → emit `session.state.flushed` JSONL stderr;
     exit 0
   - Run `git status --porcelain`; if empty → emit `session.state.flushed` JSONL stderr;
     exit 0
   - Update `.brain/STATE.md` if present with session close timestamp (before add)
   - Run `git add -A` then `git commit -m "brain(auto): flush session state"`
   - On success: capture short SHA via `git rev-parse --short HEAD`; emit stdout verdict +
     `session.state.committed` JSONL stderr; exit 0
   - On git failure: capture error message; emit E-FLUSH-001 stdout + 
     `session.state.commit_failed` JSONL stderr; exit 1
   - INVARIANT: this hook NEVER reaches `exit 2` under any execution path

4. **[impl]** Implement `plugins/brain-factory/hooks/brain-health-check.sh`
   per BC-2.04.014:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Check if `.brain/STATE.md` exists; if not → emit `brain.health.skipped` JSONL stderr;
     exit 0
   - Parse `.brain/STATE.md` using `yq` to extract six-dimensional convergence state; on
     parse failure → emit advisory stdout + `brain.health.checked` JSONL stderr with
     `"overall_state":"UNREADABLE"`; exit 1
   - Evaluate overall_state: GREEN → emit banner stdout + `brain.health.checked` JSONL
     stderr; exit 0
   - YELLOW or RED → emit banner with dimension summaries stdout + `brain.health.checked`
     JSONL stderr; exit 1
   - INVARIANT: this hook NEVER reaches `exit 2` under any execution path

5. **[green]** Run `bats plugins/brain-factory/tests/flush-state-and-commit.bats` and
   `bats plugins/brain-factory/tests/brain-health-check.bats` — all new tests pass.

6. **[green]** Run `shellcheck` and `shfmt -d -i 2` on both scripts — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Stop event; uncommitted changes present | commit performed; exit 0; `brain(auto):` prefix | happy-path | BC-2.04.013 |
| Stop event; no uncommitted changes | exit 0; "No changes to flush" | happy-path | BC-2.04.013 |
| Stop event; git commit fails | exit 1; E-FLUSH-001 | edge-case | BC-2.04.013 EC-001 |
| Stop event; outside git repo | exit 0 (no-op) | edge-case | BC-2.04.013 EC-002 |
| flush hook invoked; output | NEVER exit 2 | invariant | BC-2.04.013 invariant 2 |
| SessionStart; no `.brain/STATE.md` | exit 0; `brain.health.skipped` | edge-case | BC-2.04.014 EC-001 |
| SessionStart; GREEN STATE.md | exit 0; "Brain health: GREEN..." | happy-path | BC-2.04.014 |
| SessionStart; RED STATE.md | exit 1; E-HEALTH-002 | edge-case | BC-2.04.014 |
| SessionStart; malformed STATE.md | exit 1; advisory | edge-case | BC-2.04.014 EC-002 |
| health hook invoked; output | NEVER exit 2 | invariant | BC-2.04.014 invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no VP — P1) | Flush hook auto-commits on Stop | `tests/flush-state-and-commit.bats` |
| (no VP — P1) | Flush hook never exits 2 | `tests/flush-state-and-commit.bats` |
| (no VP — P1) | Health hook shows GREEN/RED banner | `tests/brain-health-check.bats` |
| (no VP — P1) | Health hook never exits 2 | `tests/brain-health-check.bats` |
| (no VP — P1) | Health hook exits 0 in non-brain dir + skipped event | `tests/brain-health-check.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md` and ADR-002:

1. `flush-state-and-commit.sh` is a **Stop** event hook (no matcher). It fires when the
   Claude Code session ends. Do NOT register it as PreToolUse or PostToolUse.
2. `brain-health-check.sh` is a **SessionStart** event hook (no matcher). It fires when
   the Claude Code session opens. Do NOT register it as PreToolUse or PostToolUse.
3. Both hooks exit 0 or 1 ONLY. Exit 2 from a SessionStart or Stop hook would block
   session open/close, which is architecturally forbidden.
4. `flush-state-and-commit.sh` uses `brain(auto):` conventional-commit prefix. This prefix
   must never be changed to a generic commit message or anything containing AI attribution.
5. `.brain/STATE.md` path is relative to the vault root (not `${CLAUDE_PLUGIN_ROOT}`).
6. The health banner must be concise — a full dump of STATE.md is a violation of invariant 2.
7. JSONL events emitted via `hooks/lib/hook-event-emit.sh` (ADR-016).

**Forbidden dependencies:**
- `flush-state-and-commit.sh`: no `git push`, no force flags, no remote operations.
- Both scripts: pure bash + git/yq/jq. No Node.js, no Python.

## Hook I/O Protocol Reference (ADR-002 v2.0)

This section inlines the hook I/O contract so this story is self-contained.

### stdin — Claude Code delivers this JSON

**Stop event** (`flush-state-and-commit.sh`) and **SessionStart event** (`brain-health-check.sh`):

```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "hook_event_name": "Stop|SessionStart"
}
```

Note: Stop and SessionStart events carry no `tool_name` or `tool_input` — they are
session lifecycle events, not tool-call events. The stdin JSON is minimal.

### stdout — hook verdict JSON

```json
{
  "continue": true,
  "systemMessage": "Advisory (exit 0 only)",
  "decision": "block",
  "reason": "Why blocked",
  "hookSpecificOutput": {"code": "E-SCOPE-NNN", "trace": "<uuid>", "details": {}}
}
```

Tri-state mapping:
- **allow**: exit 0, `{"continue": true}`
- **advise**: exit 0, `{"continue": true, "systemMessage": "..."}`
- **block**: exit 0, `{"decision": "block", "reason": "..."}` OR exit 2 + stderr

### Exit codes

| Exit | Meaning |
|------|---------|
| 0 | Success (stdout parsed as JSON) |
| 2 | Blocking error (stderr shown to user) |
| Other (1) | Non-blocking (stderr to debug log ONLY) |

**CRITICAL for lifecycle hooks:** Stop and SessionStart hooks MUST NOT exit 2. Blocking
a session open or close is architecturally forbidden (BC-2.04.013 invariant 2,
BC-2.04.014 invariant 1). Exit 1 is NOT advisory — use exit 0 + `systemMessage`.

## yq Disambiguation

`yq` in this story refers to **mikefarah/yq** (Go-based, v4.x+). NOT kislyuk/yq (Python-based).

- On Ubuntu, `sudo apt install yq` may install the WRONG yq (kislyuk). Use `snap install yq`
  or download from GitHub releases: `https://github.com/mikefarah/yq/releases`
- Verify: `yq --version` should show `yq (https://github.com/mikefarah/yq/) version v4.x.x`
- Both `yq eval '.key' file.yaml` and `yq '.key' file.yaml` are valid (`eval` is the
  optional default command in v4.x)

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.7+ (latest: 1.8.1) | ADR-002 §hook-stdin-parsing |
| `yq` | 4.x+ (mikefarah/yq, Go-based — NOT kislyuk/yq Python-based) | STATE.md YAML parsing for health-check |
| `git` | 2.x+ | flush-state-and-commit.sh git operations |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/flush-state-and-commit.sh` | Modify (replace stub) | Full implementation per BC-2.04.013 |
| `plugins/brain-factory/hooks/brain-health-check.sh` | Modify (replace stub) | Full implementation per BC-2.04.014 |
| `plugins/brain-factory/tests/flush-state-and-commit.bats` | Create | Bats test cases for flush-state-and-commit.sh (≥ 3 @test blocks; no VP — P1) |
| `plugins/brain-factory/tests/brain-health-check.bats` | Create | Bats test cases for brain-health-check.sh (≥ 3 @test blocks; no VP — P1) |
| `plugins/brain-factory/tests/fixtures/stop-event-with-changes.json` | Create | Stop payload with uncommitted changes flag |
| `plugins/brain-factory/tests/fixtures/stop-event-no-changes.json` | Create | Stop payload clean |
| `plugins/brain-factory/tests/fixtures/session-start-green-brain.json` | Create | SessionStart payload in green brain dir |
| `plugins/brain-factory/tests/fixtures/session-start-red-brain.json` | Create | SessionStart payload in red-state brain |
| `plugins/brain-factory/tests/fixtures/session-start-non-brain.json` | Create | SessionStart payload outside brain dir |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-012 established PreToolUse hooks and the per-hook .bats convention; STORY-013
introduces a new event category: Stop and SessionStart lifecycle hooks. The stdin JSON
payload schema differs for Stop and SessionStart events — check ADR-002 §Universal Hook
Input Schema for the exact field names (they may carry session metadata rather than tool
call data). Note that bats tests for these hooks require simulating git state (tmp git
repos) — the test harness must create a temporary git repository as a fixture rather than
relying on the real brain vault. Both hooks are P1 (not P0), which means they have no
dedicated VP. Coverage is through dedicated per-hook .bats files (`flush-state-and-commit.bats`
and `brain-health-check.bats`), NOT a shared hooks.bats.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,500 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.013, BC-2.04.014 files | ~1,500 |
| flush-state-and-commit.bats (new) | ~1,500 |
| brain-health-check.bats (new) | ~1,500 |
| Test fixtures | ~500 |
| **Total** | **~12,500** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Structured event catalog (BC-2.17.001..004) — STORY-014
- Hook contract meta-lint expansion (BC-2.04.015, BC-2.04.016, BC-2.17.003,
  BC-2.17.004) — STORY-015
- The six-dimensional convergence state model itself (defined in SS-01) — STORY-001
  scaffolds `.brain/STATE.md`; this story reads it

## Anchors

- BC-2.04.013: `behavioral-contracts/ss-04/BC-2.04.013.md`
- BC-2.04.014: `behavioral-contracts/ss-04/BC-2.04.014.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
