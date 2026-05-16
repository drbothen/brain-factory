---
document_type: verification-property
id: VP-022
title: "Lobster headless execution: no interactive prompts in non-TTY context"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.12.004]
created: 2026-05-15
status: proposed
---

# VP-022: Lobster headless execution: no interactive prompts in non-TTY context

## Property Statement

`bin/lobster-run <workflow.yaml>` executes to completion or workflow-step-failure without
ever blocking on stdin when invoked from a non-TTY context (BC-2.12.004). This is the
GitHub Actions headless execution guarantee: any `bin/lobster-run` workflow that would
succeed in an interactive shell must also succeed when stdin is redirected from
`/dev/null` and the process is running in a non-TTY GitHub Actions runner.

Concretely:
1. `bin/lobster-run` itself never calls `read`, `select`, or any interactive input
   function (verified statically by shellcheck and grep).
2. When a workflow step calls a skill that would normally prompt the user, the skill
   must detect non-TTY stdin (`! [ -t 0 ]`) and default to safe non-interactive behavior
   (the `--yes` flag equivalent) — or `bin/lobster-run` must pass explicit argument flags
   to bypass prompts.
3. The workflow exits with the correct exit code: 0 on full success, 1 on step failure
   (partial), 2 on hard failure.
4. stdout during headless execution contains only structured output (no interactive
   prompts leak to stdout).

## Verification Mechanism

bats (integration.bats) — headless execution with stdin redirected:

```bash
@test "lobster-run: headless execution does not block on stdin with /dev/null" {
  local workflow_file; workflow_file="${BATS_TEST_DIRNAME}/fixtures/sample-daily-brief.yaml"

  # Redirect stdin from /dev/null — any blocking read would cause the test to hang
  # bats timeout (60s default) would kill it; we explicitly time-limit to 30s
  run timeout 30 bash "${PLUGIN_ROOT}/bin/lobster-run" "$workflow_file" \
    --brain "${BATS_TEST_TMPDIR}/fixture-brain" < /dev/null

  # Must not timeout (exit 124 = timeout killed the process)
  refute [ "$status" -eq 124 ]
  # Must complete with a meaningful exit code (0, 1, or 2)
  assert [ "$status" -le 2 ]
}

@test "lobster-run: binary contains no direct 'read' builtin calls (static check)" {
  # Static analysis: bin/lobster-run must not call 'read' (the bash builtin)
  # in any code path not gated by 'if [ -t 0 ]' TTY detection
  run grep -n '^\s*read ' "${PLUGIN_ROOT}/bin/lobster-run"
  assert_output ""  # No bare 'read' calls
}

@test "lobster-run: workflow exits 0 on full step success (headless)" {
  # Use a minimal workflow that only runs non-interactive steps
  local workflow_file; workflow_file="${BATS_TEST_TMPDIR}/minimal-workflow.yaml"
  cat > "$workflow_file" <<'EOF'
name: minimal-test
steps:
  - id: health
    skill: brain:health
    args: ["--json"]
EOF

  run timeout 30 bash "${PLUGIN_ROOT}/bin/lobster-run" "$workflow_file" \
    --brain "${BATS_TEST_TMPDIR}/fixture-brain" < /dev/null
  assert_success
}

@test "lobster-run: workflow exits 1 on step failure (not exit 2 for recoverable)" {
  local workflow_file; workflow_file="${BATS_TEST_TMPDIR}/failing-workflow.yaml"
  cat > "$workflow_file" <<'EOF'
name: failing-test
steps:
  - id: bad-step
    skill: brain:nonexistent-skill
    args: []
    on_failure: continue
EOF

  run timeout 30 bash "${PLUGIN_ROOT}/bin/lobster-run" "$workflow_file" \
    --brain "${BATS_TEST_TMPDIR}/fixture-brain" < /dev/null
  # Step failure with on_failure: continue → exit 1 (partial), not exit 2 (hard)
  assert_failure 1
}

@test "lobster-run: stdout contains no interactive prompt text during headless run" {
  local workflow_file; workflow_file="${BATS_TEST_DIRNAME}/fixtures/sample-daily-brief.yaml"

  # Capture stdout and assert it contains no prompt-style patterns
  local stdout_output
  stdout_output="$(timeout 30 bash "${PLUGIN_ROOT}/bin/lobster-run" "$workflow_file" \
    --brain "${BATS_TEST_TMPDIR}/fixture-brain" < /dev/null 2>/dev/null)"

  # Common interactive prompt patterns must not appear in stdout
  for pattern in "Press Enter" "Continue? [y/N]" "[Y/n]" "Enter your choice" "Confirm:"; do
    if grep -qF "$pattern" <<< "$stdout_output"; then
      fail "Interactive prompt pattern found in stdout: $pattern"
    fi
  done
}
```

## Assumed Prerequisites

- `tests/fixtures/sample-daily-brief.yaml` is a representative workflow fixture that
  exercises the daily-brief headless path (referenced by BC-2.13.001 template 1)
- `${BATS_TEST_TMPDIR}/fixture-brain` is an initialized fixture brain set up by
  `setup_file` or similar bats hook
- `timeout` command available (GNU coreutils or macOS timeout equivalent)
- The static grep check is a unit-level defense in depth; the integration test is the
  primary correctness check

## Counterexamples

- A skill step in the workflow calls `read -p "Confirm? [y/N]" answer` without a TTY
  check guard — this blocks the workflow indefinitely in GitHub Actions; the 30-second
  timeout test catches this by timing out
- `bin/lobster-run` exits 0 even when a step fails (masking step failures) — the
  failing-step test catches this by asserting exit 1 for recoverable step failures
- The workflow emits an interactive confirmation prompt to stdout (instead of stderr)
  during a step that normally asks the user — the stdout-content assertion catches
  prompt text leaking to stdout

## Status

proposed — pending Phase 3 implementation of bin/lobster-run and integration.bats
