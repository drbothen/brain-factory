---
artifact_type: story
story_id: STORY-015
epic_id: EPIC-02
title: "Hook contract meta-lint expansion: performance budget, canonical I/O, fail-closed, and stream/credential enforcement"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-04, SS-17, SS-18]
behavioral_contracts: [BC-2.04.015, BC-2.04.016, BC-2.17.003, BC-2.17.004]
vps: [VP-001, VP-013, VP-026]
dependencies: [STORY-001, STORY-014]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/subsystems/SS-17-structured-event-catalog.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - behavioral-contracts/ss-04/BC-2.04.015.md
  - behavioral-contracts/ss-04/BC-2.04.016.md
  - behavioral-contracts/ss-17/BC-2.17.003.md
  - behavioral-contracts/ss-17/BC-2.17.004.md
  - architecture/verification-properties/VP-001-hook-exit-code-semantics.md
  - architecture/verification-properties/VP-013-hook-performance-budget.md
  - architecture/verification-properties/VP-026-event-catalog-schema-and-completeness.md
input-hash: "15c507c"
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.04.015 (perf budget), BC-2.04.016 (I/O contract),
# BC-2.17.003 (stream separation), and BC-2.17.004 (no-credential) are all
# CROSS-CUTTING properties that apply to every hook — they have no single hook
# as their implementation surface. Their verification home is meta-lint.bats
# (structural checks) and hook-contracts.bats latency assertions. Bundling into one story
# is correct: these BCs share the same test file targets and the same "expand
# meta-lint.bats" task. Implementing them separately would produce 4 near-identical
# stories each adding 1-2 tests to meta-lint.bats.
---

# STORY-015: Hook contract meta-lint expansion — performance budget, canonical I/O contract, fail-closed behavior, and stream/credential enforcement

## Goal

Expand `meta-lint.bats` and `hook-contracts.bats` to enforce the four cross-cutting hook quality
gates that apply uniformly to all 13 hooks: (1) every hook processes its canonical
sample payload under 100ms p99 (BC-2.04.015); (2) every hook reads JSON from stdin,
writes JSON verdict to stdout, and exits exactly 0, 1, or 2 (BC-2.04.016); (3) every
hook emits JSONL on stderr and keeps stdout reserved for the JSON verdict
(BC-2.17.003); (4) no hook emits token, API key, or credential values to any stream
(BC-2.17.004). These are not new hook scripts — they are test coverage additions and
meta-lint rules that apply structurally to all hooks in EPIC-02.

## User Value

As a factory maintainer, I want a single CI bats run to prove that every hook in the
enforcement chain conforms to its contract (exit codes, I/O shape, latency, no
credential leakage) so that adding a new hook in a future story cannot silently
violate these properties without a failing test.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.015 | Every hook processes its sample payload under 100ms p99 | P0 |
| BC-2.04.016 | Every hook reads JSON from stdin, writes JSON verdict to stdout, exits 0/1/2 only | P0 |
| BC-2.17.003 | Hooks emit JSONL on stderr; stdout reserved for JSON verdict only | P0 |
| BC-2.17.004 | No hook emits tokens, API keys, or credential values to any output stream | P0 |

## Acceptance Criteria

### Performance Budget (BC-2.04.015)

**AC-001** — `tests/hook-contracts.bats` contains a latency assertion for each of the
13 hooks: measured wall-clock time from invocation to exit on the canonical fixture is
under 100ms per run; measured over 10 consecutive runs; test passes only if p99 is under
100ms.
(traces to BC-2.04.015 postconditions 1–2; invariant 3)

**AC-002** — Each hook's canonical fixture for the latency test lives at
`tests/fixtures/<hook-name>-sample.json` (one file per hook, exactly matching the BC-2.04.015
precondition 3 naming convention).
(traces to BC-2.04.015 precondition 3)

**AC-003** — The Node startup overhead for `quarantine-fetch.sh` is included in the 100ms
budget measurement (not excluded). If Node startup alone approaches the limit, the bats
test comment flags this for Phase 1c incremental design review.
(traces to BC-2.04.015 edge case EC-002)

**AC-004** — The latency tests are test cases within `tests/hook-contracts.bats` (the
cross-cutting runtime contract suite), NOT a separate CI script outside bats.
(traces to BC-2.04.015 postcondition 2)

### Canonical I/O Contract (BC-2.04.016)

**AC-005** — `tests/meta-lint.bats` contains a static analysis assertion for all 13
hooks: each hook file starts with `#!/usr/bin/env bash` and has `set -euo pipefail`
within the first 10 lines.
(traces to BC-2.04.016 preconditions 2; invariants 1)

**AC-006** — `tests/meta-lint.bats` contains a grep-based assertion that no hook script
contains a bare `exit` statement (i.e., `exit` not followed by a space and a digit 0, 1,
or 2). Valid: `exit 0`, `exit 1`, `exit 2`. Invalid: `exit`, `exit $code` (without
explicit value).
(traces to BC-2.04.016 invariant 1)

**AC-007** — `tests/meta-lint.bats` contains a grep-based assertion that no hook script
contains the string `eval` anywhere in the file body.
(traces to BC-2.04.016 invariant 2)

**AC-008** — `tests/hook-contracts.bats` contains a parameterized test (over all 13 hooks)
that feeds empty stdin `""` and asserts: (a) exit code is 2; (b) stdout is valid JSON
containing `"code":"E-HOOK-001"`. This verifies fail-closed on malformed input.
(traces to BC-2.04.016 invariant 4; edge cases EC-001 and EC-002)

**AC-009** — `tests/hook-contracts.bats` contains a test that for each hook: feeding the
canonical happy-path fixture produces stdout that is valid JSON (`jq empty` succeeds on
captured stdout).
(traces to BC-2.04.016 postcondition 2 — stdout is always a single JSON object)

### Stream Separation (BC-2.17.003)

**AC-010** — `tests/meta-lint.bats` contains a grep-based assertion that no hook script
contains a bare `echo` or `printf` statement that writes to stdout without routing
through `emit_verdict` (i.e., any `echo` not on a stderr-redirect line and not in a
comment). This is a static analysis check.
(traces to BC-2.17.003 postcondition 3; edge case EC-002 — debug echoes blocked at lint time)

**AC-011** — `tests/hook-contracts.bats` contains a test for each hook: on a canonical
fixture invocation, the captured stderr contains at least one valid JSONL line (`jq empty`
on each line succeeds). The test asserts `wc -l ≥ 1` on captured stderr.
(traces to BC-2.17.003 postconditions 2; BC-2.04.017 invariant — ≥ 1 JSONL per invocation)

**AC-012** — `tests/hook-contracts.bats` contains a test for each hook: on the canonical
happy-path fixture, the captured stdout contains exactly one JSON object and no additional
lines.
(traces to BC-2.17.003 postcondition 1; invariant 1 — even on error paths)

### No Credential Leakage (BC-2.17.004)

**AC-013** — `tests/meta-lint.bats` contains a static analysis assertion: no hook script
contains a pattern matching known credential variable names (`$LINKEDIN_ACCESS_TOKEN`,
`$ANTHROPIC_API_KEY`, `$GITHUB_TOKEN`, or any `$*_TOKEN`, `$*_KEY`, `$*_SECRET`) inside
an `emit_event` or `emit_verdict` call. This is a grep-based static scan.
(traces to BC-2.17.004 postcondition 1; invariant 1; SS-17 §No credential leakage)

**AC-014** — `tests/hook-contracts.bats` contains a test for each hook that processes
credential-adjacent data: the hook is fed a fixture containing a synthetic credential
value (e.g., a fake API key string matching `sk-[a-f0-9]{32}`), and the captured stdout
and stderr are asserted NOT to contain that value.
(traces to BC-2.17.004 postconditions 1–2; edge case EC-001)

**AC-015** — `shellcheck` exits 0 on `tests/meta-lint.bats` additions. `shfmt -d -i 2`
produces no diff on any modified file.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[prerequisite check]** Verify STORY-014 has landed (or at minimum that
   `hooks/lib/hook-event-emit.sh` exists as a stub). STORY-015 tests rely on the shim;
   if the shim is absent, the emit-related bats tests will fail for the wrong reason.
   Document the dependency gate clearly in commit notes.

2. **[failing test — Red Gate]** Extend `tests/meta-lint.bats` with static analysis
   assertions in failing state:
   - `set -euo pipefail` within first 10 lines (all 13 hooks).
   - No bare `exit` (all 13 hooks).
   - No `eval` (all 13 hooks).
   - No direct `echo`/`printf` to stdout outside `emit_verdict` (all 13 hooks).
   - No credential variable references in emit calls (all 13 hooks).
   Create a fixture list of all 13 hook filenames for parameterized iteration.
   Run bats — confirm new tests fail (Red Gate confirmed, since hooks are stubs at
   this point).

3. **[failing test — Red Gate]** Create `tests/hook-contracts.bats` with runtime contract
   assertions in failing state (cross-cutting parameterized suite over all 13 hooks):
   - Empty stdin → exit 2 + E-HOOK-001 (parameterized over all 13 hooks).
   - Happy-path fixture stdout is valid JSON (parameterized over all 13 hooks).
   - Happy-path fixture stderr has ≥ 1 valid JSONL line (parameterized over all 13 hooks).
   - Latency assertion: canonical fixture → wall-clock < 100ms over 10 runs
     (parameterized, with quarantine-fetch.sh Node startup warning).
   Create canonical sample fixtures: `tests/fixtures/<hook-name>-sample.json` for all
   13 hooks (minimal valid payload for each hook type).
   Run bats — confirm new tests fail (Red Gate confirmed).

4. **[impl]** The implementation for this story is in the TEST FILES, not in hook scripts.
   The hooks themselves are implemented in STORY-006..STORY-013. This story's
   implementation task is to finalize the meta-lint + hook-contracts.bats assertions such that:
   - All static analysis tests pass once STORY-006..STORY-013 are complete.
   - The latency assertions pass under CI runner conditions.
   - The parameterized empty-stdin tests pass for all hooks with full implementations.
   For hooks still in stub form: add a bats `skip` annotation with
   `# TODO: unskip when STORY-NNN implements this hook` — never leave failing tests
   without a clear skip explanation.

5. **[green]** Run `bats tests/meta-lint.bats` — all structural assertions pass.

6. **[green]** Run `bats tests/hook-contracts.bats` — all I/O contract and stream-separation
   assertions pass.

7. **[green]** Run `shellcheck` and `shfmt -d -i 2` on `tests/meta-lint.bats` and any
   new test helper files — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Any hook; canonical fixture; 10 runs timed | All runs < 100ms; p99 < 100ms | happy-path | BC-2.04.015 |
| Any hook; empty stdin `""` | exit 2; stdout `{"code":"E-HOOK-001",...}` | error | BC-2.04.016 EC-001 |
| Any hook; happy-path fixture | stdout is single valid JSON object | happy-path | BC-2.04.016 postcondition 2 |
| Any hook; happy-path fixture | stderr has ≥ 1 valid JSONL line | happy-path | BC-2.17.003 |
| Hook with credential-value fixture | stdout + stderr do NOT contain the credential value | security | BC-2.17.004 |
| Hook script grep for bare `exit` | grep finds zero matches | meta-lint | BC-2.04.016 invariant 1 |
| Hook script grep for `eval` | grep finds zero matches | meta-lint | BC-2.04.016 invariant 2 |
| Hook script grep for `echo` to stdout | grep finds zero matches outside emit_verdict | meta-lint | BC-2.17.003 EC-002 |
| Hook script grep for credential vars in emit | grep finds zero matches | meta-lint | BC-2.17.004 invariant 1 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-001 | All 13 hooks exit 0/1/2 only; no bare `exit` | `tests/meta-lint.bats` (static) + `tests/hook-contracts.bats` (empty-stdin) |
| VP-001 | No `eval` in any hook | `tests/meta-lint.bats` (grep) |
| VP-013 | All 13 hook latency assertions pass < 100ms p99 | `tests/hook-contracts.bats` (timing) |
| VP-026 | stdout is always valid single JSON | `tests/hook-contracts.bats` (jq empty) |
| VP-026 | stderr contains JSONL ≥ 1 line per invocation | `tests/hook-contracts.bats` (wc -l) |
| VP-026 | No credential values in hook output | `tests/hook-contracts.bats` (grep on captured output) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md`,
`architecture/subsystems/SS-17-structured-event-catalog.md`, and ADR-002:

1. The 100ms budget is measured for the canonical **sample payload** only (per BC-2.04.015
   invariant 1). Full-wiki operations (500+ pages) are NOT in scope for the p99 assertion.
2. Empty stdin (`""`) must produce exit 2 + E-HOOK-001 for ALL hooks — this is the
   fail-closed universal entry check (BC-2.04.016 invariant 4). Tests confirm this.
3. The meta-lint static analysis runs at the file level (grep, awk). It is NOT a
   runtime check — it fires during `bats tests/meta-lint.bats`, not during hook execution.
4. Credential leakage detection is static (meta-lint scans source) AND dynamic
   (bats test injects known-fake key and asserts on captured output). Both layers are
   required by BC-2.17.004.
5. The `skip` mechanism for stub hooks must use bats `skip` annotation with a specific
   future-story reference (e.g., `# skip: STORY-007 implements this hook`) — not
   commenting out the test.

**Forbidden dependencies (test files):**
- `tests/meta-lint.bats` must use only bash, bats, grep, awk, jq. No Node.js test runners.
- Test fixture files must be plain JSON (valid, minimal). No templating.

## Hook I/O Protocol Reference (ADR-002 v2.0)

This section inlines the hook I/O contract so this story is self-contained. This is
especially important for STORY-015 since the meta-lint and hook-contracts suites must
validate the correct contract across all 13 hooks.

### stdin — Claude Code delivers this JSON

**PostToolUse** (Write/Edit hooks):

```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "hook_event_name": "PostToolUse",
  "tool_name": "Write|Edit|...",
  "tool_input": {"file_path": "<path>", "content": "<string>"},
  "tool_use_id": "<string>",
  "tool_result": {"type": "text|image|error", "text": "...", "exit_code": 0}
}
```

**PreToolUse** (Write/Edit/Bash hooks — no `tool_result`):

```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write|Edit|Bash",
  "tool_input": {"file_path": "<path>", "content": "<string>"},
  "tool_use_id": "<string>"
}
```

**Stop / SessionStart** (lifecycle hooks — no tool fields):

```json
{
  "session_id": "<string>",
  "transcript_path": "<path>",
  "cwd": "<path>",
  "hook_event_name": "Stop|SessionStart"
}
```

### Per-tool `tool_input` fields

| Tool | Fields |
|------|--------|
| Write | `file_path`, `content` |
| Edit | `file_path`, `old_string`, `new_string`, `replace_all` |
| Bash | `command`, `description`, `timeout` |

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

**CRITICAL:** Exit 1 is NOT advisory. Use exit 0 + `systemMessage` for advisories.
Stop/SessionStart hooks MUST NOT exit 2.

### Canonical field access patterns

```bash
# Extract file path (PostToolUse / PreToolUse Write|Edit):
file_path="$(jq -r '.tool_input.file_path' <<< "$stdin_json")"
# Extract tool name:
tool_name="$(jq -r '.tool_name' <<< "$stdin_json")"
# Extract bash command (PreToolUse Bash):
command="$(jq -r '.tool_input.command' <<< "$stdin_json")"
```

The **canonical sample fixtures** for latency tests (`tests/fixtures/<hook-name>-sample.json`)
must use `.tool_input.file_path` (not `.input.path` or `.input.file_path`) per ADR-002 v2.0.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `jq` | 1.7+ (latest: 1.8.1) | JSON validation in test assertions |
| `grep` | POSIX | Static analysis assertions |
| `awk` | POSIX | Pattern extraction in meta-lint |
| `time` / `SECONDS` | bash builtin | Latency measurement |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

No Node.js, no Python in test files.

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/tests/meta-lint.bats` | Extend | Static analysis: bare-exit, eval, echo-stdout, credential-var assertions |
| `plugins/brain-factory/tests/hook-contracts.bats` | Create | Runtime cross-cutting: empty-stdin, JSON stdout, JSONL stderr, latency assertions (parameterized over all 13 hooks) |
| `plugins/brain-factory/tests/fixtures/<hook>-sample.json` | Create (×13) | One canonical fixture per hook for latency tests |

Files NOT to modify: any hook script (STORY-006..STORY-013 own hook implementation),
`hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-014 delivers the `hooks/lib/hook-event-emit.sh` shim that STORY-015's stream-
separation tests depend on. STORY-015 tests are designed to pass once all hook stories
(STORY-006..STORY-013) are implemented; during STORY-015 implementation, stub hooks
will cause runtime tests to fail — use bats `skip` annotations for hooks not yet
implemented rather than removing assertions. The meta-lint static assertions (shebang,
set -euo pipefail, no bare exit, no eval) should pass immediately on the stubs created
by STORY-001 if those stubs were created correctly. The runtime cross-cutting tests live
in `tests/hook-contracts.bats` (not a shared hooks.bats) — do NOT add them to any
per-hook .bats file; they are parameterized over all 13 hooks by design.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,000 |
| SS-04 subsystem design | ~1,500 |
| SS-17 subsystem design | ~1,000 |
| ADR-002 hook chain contract | ~1,500 |
| BC-2.04.015, BC-2.04.016, BC-2.17.003, BC-2.17.004 files | ~2,500 |
| VP-001, VP-013, VP-026 files | ~1,000 |
| meta-lint.bats existing content | ~1,500 |
| hook-contracts.bats (new) | ~1,500 |
| 13 sample fixture files | ~1,000 |
| **Total** | **~15,500** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Individual hook implementations — STORY-006..STORY-013 own those.
- Structured event catalog file and shim — STORY-014.
- EPIC-04 meta-lint expansions (wiki layer, skill meta-lint) — separate epic.
- The `hook-event-emit.sh` credential masking implementation — STORY-014 owns that;
  STORY-015 verifies the behavior through bats test assertions.

## Anchors

- BC-2.04.015: `behavioral-contracts/ss-04/BC-2.04.015.md`
- BC-2.04.016: `behavioral-contracts/ss-04/BC-2.04.016.md`
- BC-2.17.003: `behavioral-contracts/ss-17/BC-2.17.003.md`
- BC-2.17.004: `behavioral-contracts/ss-17/BC-2.17.004.md`
- VP-001: `architecture/verification-properties/VP-001-hook-exit-code-semantics.md`
- VP-013: `architecture/verification-properties/VP-013-hook-performance-budget.md`
- VP-026: `architecture/verification-properties/VP-026-event-catalog-schema-and-completeness.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- SS-17: `architecture/subsystems/SS-17-structured-event-catalog.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
