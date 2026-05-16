---
document_type: verification-property
id: VP-007
title: "Lobster workflow determinism"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
verifies_bcs: [BC-2.12.001, BC-2.12.002]
created: 2026-05-15
status: proposed
---

# VP-007: Lobster workflow determinism

## Property Statement

Given the same workflow YAML input, `bin/lobster-run` always produces the same step execution ordering and the same exit code. The dependency resolution (topological sort) is a deterministic pure function: no randomness, no external I/O, no mutable state.

Additionally: a workflow YAML with a dependency cycle exits 2 with `E-LOBSTER-001` — always, deterministically.

## Verification Mechanism

bats (integration.bats) — pure unit test on topological sort:

```bash
@test "lobster-run: linear DAG → executes in dependency order" {
  local yaml='name: test
steps:
  - id: step-a
    skill: brain:dummy-a
    args: []
    depends_on: []
  - id: step-b
    skill: brain:dummy-b
    args: []
    depends_on: [step-a]
  - id: step-c
    skill: brain:dummy-c
    args: []
    depends_on: [step-b]'
  
  run "${CLAUDE_PLUGIN_ROOT}/bin/lobster-run" --dry-run <(echo "$yaml")
  assert_success
  # --dry-run mode prints step IDs in execution order without running skills
  assert_output --partial "step-a"
  [[ "$(echo "$output" | grep -n step-a | cut -d: -f1)" -lt \
     "$(echo "$output" | grep -n step-b | cut -d: -f1)" ]]
  [[ "$(echo "$output" | grep -n step-b | cut -d: -f1)" -lt \
     "$(echo "$output" | grep -n step-c | cut -d: -f1)" ]]
}

@test "lobster-run: cycle → E-LOBSTER-001 exit 2" {
  local cycle_yaml='name: cycle-test
steps:
  - id: step-a
    skill: brain:dummy-a
    args: []
    depends_on: [step-b]
  - id: step-b
    skill: brain:dummy-b
    args: []
    depends_on: [step-a]'
  
  run "${CLAUDE_PLUGIN_ROOT}/bin/lobster-run" --dry-run <(echo "$cycle_yaml")
  assert_failure 2
  assert_output --partial '"code":"E-LOBSTER-001"'
}

@test "lobster-run determinism: same YAML → same ordering on two runs" {
  local order1; order1=$("${CLAUDE_PLUGIN_ROOT}/bin/lobster-run" --dry-run <(echo "$yaml"))
  local order2; order2=$("${CLAUDE_PLUGIN_ROOT}/bin/lobster-run" --dry-run <(echo "$yaml"))
  assert_equal "$order1" "$order2"
}
```

## Assumed Prerequisites

- `bin/lobster-run` supports `--dry-run` mode (prints ordering without executing skills)

## Counterexamples

- The topological sort uses random tie-breaking for nodes at the same depth level (non-deterministic ordering)
- A cycle in `depends_on` is not detected and lobster-run enters an infinite loop
- `bin/lobster-run` exits 0 even when a dependent step failed to execute

## Status

proposed — pending Phase 3 implementation of bin/lobster-run
