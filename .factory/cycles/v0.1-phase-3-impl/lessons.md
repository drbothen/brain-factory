---
document_type: lessons-learned
level: ops
version: "1.0"
status: in-progress
producer: state-manager
timestamp: 2026-05-28T00:00:00
cycle: "v0.1-phase-3-impl"
inputs: [STATE.md]
input-hash: ""
traces_to: STATE.md
---

# Lessons Learned — v0.1-phase-3-impl

## Process-Level

1. **shopt -s inherit_errexit does NOT propagate set -e into bash functions invoked via if-conditional context** — The POSIX errexit-context rule overrides `inherit_errexit` for any function called inside an `if`-statement, `&&`-chain, or `||`-chain. This means `if ! _writeback_state; then` and `_writeback_state || ...` both suppress `set -e` inside `_writeback_state`, regardless of `shopt -s inherit_errexit`. Reviewers and implementers must NOT assume `inherit_errexit` is sufficient when a function is invoked via if-context. The production-grade pattern is explicit per-call `|| { sentinel=...; return 1; }` guards inside any function whose failure paths must surface to the caller.
   _Discovered: Pass 6 Fix Burst 6 (40de399), 2026-05-28. Root cause exposed by test 45 RED GATE in 9fe29ce transitioning FAIL → PASS after 40de399 applied explicit guards._

2. **Paper-fix detection works when test-writers have autonomy to commit initially-failing tests** — Pass 4 F-P4-O01 was "closed" at 5c8430a with `shopt -s inherit_errexit`. Pass 6 adversary surfaced the same issue as F-P6-C01. The paper-fix was only exposed when test-writer added a load-bearing yq-failure test (test 45) in 9fe29ce that initially FAILED — demonstrating the claimed fix was insufficient. The paper-fix was then actually closed at 40de399. Lesson: empirical RED GATE tests that start failing are more reliable closure evidence than implementer self-assessment. TD-VSDD-059 paper-fix detection protocol requires load-bearing tests precisely for this reason.
   _Discovered: Pass 6 (2026-05-28). Manifestation: 2-step closure required for a finding that was declared closed in Pass 4._

## Policy Candidates

| Lesson | Proposed Policy | Scope | Status |
|--------|----------------|-------|--------|
| 1 | Explicit per-call error guards required in any bash function called via if-context | hook + skill bash code review checklist | proposed |
| 2 | Paper-fix closure MUST be validated by a load-bearing test (bats) that was initially FAILING | test-writer dispatch protocol for fix bursts | proposed |
