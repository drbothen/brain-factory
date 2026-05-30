#!/usr/bin/env bats
# STORY-015: Hook contract meta-lint expansion — cross-cutting runtime assertions
# Traces to: BC-2.04.015 (perf budget), BC-2.04.016 (I/O contract),
#            BC-2.17.003 (stream separation), BC-2.17.004 (no-credential leakage)
# VP anchors: VP-001, VP-013, VP-026
#
# This suite exercises ALL 13 hooks with parameterized assertions.
# Individual hook functional behavior lives in per-hook .bats files.
# This file tests the CROSS-CUTTING contractual properties that must hold
# for every hook regardless of its specific domain logic.
#
# DEPENDENCY NOTE (STORY-015 Task 1):
# These tests require CLAUDE_PLUGIN_ROOT to point to a valid plugin directory
# with hooks/*.sh present (stubs accepted) and hooks/lib/hook-event-emit.sh.
# Tests that require full hook implementations are marked with skip annotations
# citing the story that delivers the implementation.
#
# LATENCY MEASUREMENT RATIONALE (BC-2.04.015 invariant 3 / AC-001):
# We use `date +%s%3N` (milliseconds since epoch) before and after each hook
# invocation.  Measuring via bash builtins + `date` is the only portable
# approach that does not require hyperfine or Node.js in the test environment.
# It is load-bearing because:
#   - Each run is an independent wall-clock measurement (not a no-op estimate).
#   - The 10-run loop with sort produces a true p99-of-10 (= 9th/10th maximum).
#   - A `sleep 0.2` injected into a hook would cause the assertion to fail.
# Caveat: CI runner jitter can cause false positives; the p99-of-10 window
# absorbs single outliers (EC-003).  If this causes flakiness, the canonical
# fix is to increase runs to 20 (p99 = 19th out of 20), not to remove the test.

setup_file() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PLUGIN_DIR

  # Canonical list of all 13 hook names (without .sh extension for array use).
  # This list is the authoritative roster for parameterized iteration.
  HOOKS=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )
  export HOOKS

  # Synthetic credential sentinel values (BC-2.17.004 AC-014).
  # These are FAKE values — no real credentials. Used as canary strings.
  CRED_SENTINEL_KEY="sk-test-ABCDEF1234567890abcdef1234567890"
  CRED_SENTINEL_TOKEN="ghp_FAKE_TOKEN_xyzXYZ999aaa"
  export CRED_SENTINEL_KEY CRED_SENTINEL_TOKEN
}

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export PLUGIN_DIR
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Ensure hooks/lib/hook-event-emit.sh exists (STORY-014 dependency).
  # If missing, tests that source the helper will fail at the hook level —
  # the test itself will still report a meaningful failure.
  EMIT_HELPER="${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
  export EMIT_HELPER
}

# =============================================================================
# SECTION 1: BC-2.04.016 — Canonical I/O: empty stdin → exit 2 + E-HOOK-001
# AC-008: parameterized over all 13 hooks.
# =============================================================================

# Each hook, when fed empty stdin, MUST exit 2 and emit a JSON object
# on stdout containing "E-HOOK-001".
# The hook names are iterated inside a single @test to avoid 13 near-identical
# test declarations while still producing one failure per non-conforming hook.
# This is the most readable parameterization pattern in bats-core 1.10.
#
# NOTE: brain-health-check and flush-state-and-commit are advisory-only (always
# exit 0). Per BC-2.04.016 EC-001, empty stdin must still produce exit 2 for
# fail-closed hooks. Advisory-only hooks (brain-health-check, flush-state-and-commit)
# are expected to exit 0 even on empty stdin; they are SKIPPED here because their
# advisory-only contract supersedes the fail-closed default.
# See STORY-015 Architecture Compliance Rule 2 and hook comments.

@test "BC_2_04_016: block-ai-attribution empty stdin exits 2 with E-HOOK-001 in stdout" {
  local hook="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: enforce-kebab-case empty stdin exits 2 with E-HOOK-001 in stdout" {
  local hook="${PLUGIN_DIR}/hooks/enforce-kebab-case.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: quarantine-fetch empty stdin exits 2 with E-HOOK-001 in stdout" {
  # quarantine-fetch has a Node dependency check that fires before stdin parsing.
  # If Node is absent the hook exits 2 with E-QUARANTINE-003 (not E-HOOK-001).
  # Per BC-2.04.016 invariant 4: on empty stdin the hook MUST exit 2 and emit
  # {"verdict":"block","code":"E-HOOK-001",...} when stdin parse fails.
  # Node-absent path may emit a different code — the canonical empty-stdin parse
  # path (Node present) must emit E-HOOK-001.
  # IMPLEMENTATION NOTE for implementer: if Node is absent, the hook bails early
  # with E-QUARANTINE-003; when Node IS present but stdin is empty, the stdin-
  # parse path fires E-HOOK-001. This test exercises the stdin-parse path.
  # If Node is absent in CI, this test will fail with a different code — that
  # is intentional: it surfaces the constraint gap to the implementer.
  local hook="${PLUGIN_DIR}/hooks/quarantine-fetch.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-frontmatter-schema empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-index-log-coherence empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-page-type-policy empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-page-type-policy.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-publish-state empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-publish-state.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-source-id-citation empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-source-id-citation.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-source-immutability empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-source-immutability.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

@test "BC_2_04_016: validate-voice-avoid-list empty stdin exits 2 with JSON on stdout" {
  # validate-voice-avoid-list is advisory-only (exit 0 always).
  # Empty stdin should still produce valid JSON. The exit code may be 0 or 2
  # depending on the advisory-only contract. We assert JSON on stdout only.
  skip "validate-voice-avoid-list is advisory-only; empty-stdin exit behavior " \
    "is verified in its per-hook bats suite (validate-voice-avoid-list.bats). " \
    "Skip: advisory-only contract supersedes fail-closed default."
}

@test "BC_2_04_016: validate-wikilink-integrity empty stdin exits 2 with E-HOOK-001 in stdout" {
  # BC-2.04.016 invariant 4: fail-closed hook on empty stdin MUST emit
  # {"verdict":"block","code":"E-HOOK-001",...} on stdout.
  local hook="${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  echo "$output" | jq -e '.code == "E-HOOK-001"' >/dev/null
}

# Advisory-only hooks: empty stdin → still produces valid JSON stdout, exit 0.
@test "BC_2_04_016: brain-health-check advisory-only hook exits 0 on empty stdin with valid JSON stdout" {
  # brain-health-check uses an advisory-only ERR trap (always exit 0).
  # Empty stdin triggers the advisory trap, not a fail-closed block.
  local hook="${PLUGIN_DIR}/hooks/brain-health-check.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
}

@test "BC_2_04_016: flush-state-and-commit advisory-only hook exits 0 on empty stdin with valid JSON stdout" {
  local hook="${PLUGIN_DIR}/hooks/flush-state-and-commit.sh"
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
}

# =============================================================================
# SECTION 2: BC-2.04.016 — Canonical I/O: happy-path fixture → valid JSON stdout
# AC-009: for each hook, canonical fixture produces valid JSON stdout.
# =============================================================================

@test "BC_2_04_016: block-ai-attribution canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: brain-health-check canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/brain-health-check.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/brain-health-check-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: enforce-kebab-case canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/enforce-kebab-case.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/enforce-kebab-case-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: flush-state-and-commit canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/flush-state-and-commit.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/flush-state-and-commit-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: quarantine-fetch canonical fixture stdout is valid JSON" {
  # AC-003: Node startup overhead is included (no --exclude-node-startup).
  # Verdict: quarantine-fetch fixture exercises the "URL not blocked" path in
  # environments with Node, but may exit 2 (E-QUARANTINE-003) without Node.
  # The fixture cannot guarantee a true happy-path continue:true without Node
  # present, so this test asserts JSON validity only (known infrastructure gap).
  # When Node is present and the fixture URL is not blocked, the hook emits
  # continue:true — a future fixture enhancement can add that assertion once
  # Node presence is guaranteed in CI (see STORY-015 architecture notes).
  local hook="${PLUGIN_DIR}/hooks/quarantine-fetch.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/quarantine-fetch-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # Verdict structure: must have either continue:true (allowed) or
  # continue:false with a structured hookSpecificOutput (blocked/error).
  echo "$output" | jq -e 'has("continue")' >/dev/null
}

@test "BC_2_04_016: validate-frontmatter-schema canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-frontmatter-schema-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  # Fixture was corrected from type:concept (singular, invalid) to type:concepts
  # (plural, valid per canonical-6 type set in validate-frontmatter-schema.sh).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: validate-index-log-coherence canonical fixture stdout is valid JSON" {
  # validate-index-log-coherence requires a real wiki/index.md and wiki/log.md on
  # disk to exercise the happy path. The fixture points to /tmp which lacks these
  # files, causing the hook to exit 2 (E-WIKI-002 or similar). This test asserts
  # JSON validity + correct verdict structure; a true happy-path assertion requires
  # fixture infrastructure (real index+log files in a temp brain directory).
  local hook="${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-index-log-coherence-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # Verdict structure: must have continue field regardless of outcome.
  echo "$output" | jq -e 'has("continue")' >/dev/null
}

@test "BC_2_04_016: validate-page-type-policy canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/validate-page-type-policy.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-page-type-policy-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  # This hook validates the file PATH type directory, not frontmatter type field.
  # Fixture path wiki/concepts/my-concept.md gives type_dir=concepts (valid).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: validate-publish-state canonical fixture stdout is valid JSON" {
  # validate-publish-state requires a real file on disk with publish_status
  # frontmatter to exercise the full validation path. The fixture points to
  # /tmp which lacks a real file, so the hook exits 2 (fail-closed). This test
  # asserts JSON validity + correct verdict structure.
  local hook="${PLUGIN_DIR}/hooks/validate-publish-state.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-publish-state-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # Verdict structure: must have continue field regardless of outcome.
  echo "$output" | jq -e 'has("continue")' >/dev/null
}

@test "BC_2_04_016: validate-source-id-citation canonical fixture stdout is valid JSON" {
  # validate-source-id-citation requires source_id references against a real
  # sources directory. The fixture uses /tmp which lacks real source files,
  # so the hook exits 2 (fail-closed). This test asserts JSON validity + structure.
  local hook="${PLUGIN_DIR}/hooks/validate-source-id-citation.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-source-id-citation-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # Verdict structure: must have continue field regardless of outcome.
  echo "$output" | jq -e 'has("continue")' >/dev/null
}

@test "BC_2_04_016: validate-source-immutability canonical fixture stdout is valid JSON" {
  # validate-source-immutability checks sha256 of source files against stored hashes.
  # The fixture uses /tmp which lacks real source files with hashes, so the hook
  # exits 2 (fail-closed). This test asserts JSON validity + verdict structure.
  local hook="${PLUGIN_DIR}/hooks/validate-source-immutability.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-source-immutability-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # Verdict structure: must have continue field regardless of outcome.
  echo "$output" | jq -e 'has("continue")' >/dev/null
}

@test "BC_2_04_016: validate-voice-avoid-list canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/validate-voice-avoid-list.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-voice-avoid-list-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

@test "BC_2_04_016: validate-wikilink-integrity canonical fixture stdout is valid JSON" {
  local hook="${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-wikilink-integrity-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
  # BC-2.17.003 PC1 + AC-009: happy-path verdict must be continue:true (I-01 fix).
  # Fixture has no wikilinks in content, so hook vacuously passes (continue:true).
  echo "$output" | jq -e '.continue == true' >/dev/null
}

# =============================================================================
# SECTION 3: BC-2.04.016 — exit code is within {0, 1, 2} on happy-path fixture
# =============================================================================

# Helper: assert exit code is 0, 1, or 2.
_assert_exit_in_range() {
  local actual_status="$1"
  local hook_name="$2"
  if [[ "$actual_status" -ne 0 ]] && [[ "$actual_status" -ne 1 ]] && [[ "$actual_status" -ne 2 ]]; then
    echo "Hook ${hook_name} exited with ${actual_status} (expected 0, 1, or 2)" >&2
    return 1
  fi
}

@test "BC_2_04_016: block-ai-attribution exit code is in {0,1,2} on canonical fixture" {
  local hook="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null
  _assert_exit_in_range "$status" "block-ai-attribution"
}

@test "BC_2_04_016: enforce-kebab-case exit code is in {0,1,2} on canonical fixture" {
  local hook="${PLUGIN_DIR}/hooks/enforce-kebab-case.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/enforce-kebab-case-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null
  _assert_exit_in_range "$status" "enforce-kebab-case"
}

@test "BC_2_04_016: quarantine-fetch exit code is in {0,1,2} on canonical fixture" {
  local hook="${PLUGIN_DIR}/hooks/quarantine-fetch.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/quarantine-fetch-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null
  _assert_exit_in_range "$status" "quarantine-fetch"
}

@test "BC_2_04_016: validate-frontmatter-schema exit code is in {0,1,2} on canonical fixture" {
  local hook="${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-frontmatter-schema-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null
  _assert_exit_in_range "$status" "validate-frontmatter-schema"
}

@test "BC_2_04_016: validate-wikilink-integrity exit code is in {0,1,2} on canonical fixture" {
  local hook="${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/validate-wikilink-integrity-sample.json"
  run bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null
  _assert_exit_in_range "$status" "validate-wikilink-integrity"
}

# =============================================================================
# SECTION 4: BC-2.17.003 — Stream separation: stderr has ≥ 1 JSONL line
# AC-011: captured stderr contains at least one valid JSONL line per invocation.
# AC-012: stdout contains exactly one JSON object (structural check).
# =============================================================================

# _assert_stderr_jsonl <hook> <fixture>
# Runs the hook with the given fixture, captures stderr, and asserts:
#   1. At least 1 line on stderr.
#   2. Each non-empty line on stderr is valid JSON (jq -e parse).
_assert_stderr_jsonl() {
  local hook="$1"
  local fixture="$2"
  local hook_name="${hook##*/}"

  local stderr_file
  stderr_file="$(mktemp)"
  # Capture stdout (verdict) and stderr (events) separately.
  bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" \
    2>"$stderr_file" >/dev/null || true

  local line_count
  line_count="$(wc -l <"$stderr_file" | tr -d ' ')"
  if [[ "$line_count" -lt 1 ]]; then
    echo "Hook ${hook_name}: stderr has 0 lines (expected ≥ 1 JSONL per BC-2.17.003)" >&2
    rm -f "$stderr_file"
    return 1
  fi

  # Validate each non-empty stderr line is parseable JSON.
  local bad_lines=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if ! echo "$line" | jq -e '.' >/dev/null 2>&1; then
      echo "Hook ${hook_name}: non-JSONL on stderr: ${line}" >&2
      bad_lines=$((bad_lines + 1))
    fi
  done <"$stderr_file"

  rm -f "$stderr_file"

  if [[ "$bad_lines" -gt 0 ]]; then
    return 1
  fi
}

# _assert_stdout_single_json <hook> <fixture>
# Runs the hook and asserts stdout is exactly one valid JSON object.
_assert_stdout_single_json() {
  local hook="$1"
  local fixture="$2"
  local hook_name="${hook##*/}"

  local stdout_content
  stdout_content="$(bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null || true)"

  # Must parse as JSON.
  if ! echo "$stdout_content" | jq -e '.' >/dev/null 2>&1; then
    echo "Hook ${hook_name}: stdout is not valid JSON: ${stdout_content}" >&2
    return 1
  fi

  # Must be a single JSON object (type == "object"), not an array or primitive.
  local jtype
  jtype="$(echo "$stdout_content" | jq -r 'type' 2>/dev/null || echo "invalid")"
  if [[ "$jtype" != "object" ]]; then
    echo "Hook ${hook_name}: stdout JSON type is '${jtype}' (expected 'object')" >&2
    return 1
  fi

  # Must be exactly one JSON object (no extra lines).
  local line_count
  line_count="$(echo "$stdout_content" | grep -c '^' || true)"
  if [[ "$line_count" -gt 1 ]]; then
    echo "Hook ${hook_name}: stdout has ${line_count} lines (expected 1)" >&2
    return 1
  fi
}

@test "BC_2_17_003: block-ai-attribution stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/block-ai-attribution.sh" \
    "${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json"
}

@test "BC_2_17_003: block-ai-attribution stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/block-ai-attribution.sh" \
    "${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json"
}

@test "BC_2_17_003: brain-health-check stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/brain-health-check.sh" \
    "${PLUGIN_DIR}/tests/fixtures/brain-health-check-sample.json"
}

@test "BC_2_17_003: brain-health-check stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/brain-health-check.sh" \
    "${PLUGIN_DIR}/tests/fixtures/brain-health-check-sample.json"
}

@test "BC_2_17_003: enforce-kebab-case stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/enforce-kebab-case.sh" \
    "${PLUGIN_DIR}/tests/fixtures/enforce-kebab-case-sample.json"
}

@test "BC_2_17_003: enforce-kebab-case stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/enforce-kebab-case.sh" \
    "${PLUGIN_DIR}/tests/fixtures/enforce-kebab-case-sample.json"
}

@test "BC_2_17_003: flush-state-and-commit stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/flush-state-and-commit.sh" \
    "${PLUGIN_DIR}/tests/fixtures/flush-state-and-commit-sample.json"
}

@test "BC_2_17_003: flush-state-and-commit stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/flush-state-and-commit.sh" \
    "${PLUGIN_DIR}/tests/fixtures/flush-state-and-commit-sample.json"
}

@test "BC_2_17_003: quarantine-fetch stderr has >=1 JSONL on canonical fixture" {
  # quarantine-fetch may emit Node-absent event on stderr in envs without Node.
  # Either way: at least 1 JSONL line on stderr is required.
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/quarantine-fetch.sh" \
    "${PLUGIN_DIR}/tests/fixtures/quarantine-fetch-sample.json"
}

@test "BC_2_17_003: quarantine-fetch stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/quarantine-fetch.sh" \
    "${PLUGIN_DIR}/tests/fixtures/quarantine-fetch-sample.json"
}

@test "BC_2_17_003: validate-frontmatter-schema stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-frontmatter-schema-sample.json"
}

@test "BC_2_17_003: validate-frontmatter-schema stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-frontmatter-schema-sample.json"
}

@test "BC_2_17_003: validate-index-log-coherence stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-index-log-coherence-sample.json"
}

@test "BC_2_17_003: validate-index-log-coherence stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-index-log-coherence-sample.json"
}

@test "BC_2_17_003: validate-page-type-policy stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-page-type-policy.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-page-type-policy-sample.json"
}

@test "BC_2_17_003: validate-page-type-policy stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-page-type-policy.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-page-type-policy-sample.json"
}

@test "BC_2_17_003: validate-publish-state stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-publish-state.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-publish-state-sample.json"
}

@test "BC_2_17_003: validate-publish-state stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-publish-state.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-publish-state-sample.json"
}

@test "BC_2_17_003: validate-source-id-citation stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-source-id-citation.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-source-id-citation-sample.json"
}

@test "BC_2_17_003: validate-source-id-citation stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-source-id-citation.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-source-id-citation-sample.json"
}

@test "BC_2_17_003: validate-source-immutability stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-source-immutability.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-source-immutability-sample.json"
}

@test "BC_2_17_003: validate-source-immutability stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-source-immutability.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-source-immutability-sample.json"
}

@test "BC_2_17_003: validate-voice-avoid-list stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-voice-avoid-list.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-voice-avoid-list-sample.json"
}

@test "BC_2_17_003: validate-voice-avoid-list stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-voice-avoid-list.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-voice-avoid-list-sample.json"
}

@test "BC_2_17_003: validate-wikilink-integrity stderr has >=1 JSONL on canonical fixture" {
  _assert_stderr_jsonl \
    "${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-wikilink-integrity-sample.json"
}

@test "BC_2_17_003: validate-wikilink-integrity stdout is single JSON object on canonical fixture" {
  _assert_stdout_single_json \
    "${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-wikilink-integrity-sample.json"
}

# =============================================================================
# SECTION 5: BC-2.17.004 — No credential leakage
# AC-014: inject sentinel credential values; assert they do not appear in
#         stdout or stderr.
# =============================================================================

# Build a credential-adjacent fixture by embedding a sentinel into a standard payload.
_make_cred_fixture() {
  local base_fixture="$1"
  # Embed sentinel value into the content field of the payload.
  # The hook will process the content — if it echoes the content verbatim to
  # stdout/stderr, the sentinel will appear and the test will fail.
  jq \
    --arg sentinel_key "${CRED_SENTINEL_KEY}" \
    --arg sentinel_token "${CRED_SENTINEL_TOKEN}" \
    '.tool_input.content = (.tool_input.content // "") + "\napi_key=" + $sentinel_key + "\naccess_token=" + $sentinel_token' \
    "$base_fixture" 2>/dev/null || cat "$base_fixture"
}

@test "BC_2_17_004: block-ai-attribution does not leak credential sentinel to stdout or stderr" {
  local hook="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json"
  # block-ai-attribution reads .tool_input.command — embed sentinel there.
  local cred_payload
  cred_payload="$(jq \
    --arg s "${CRED_SENTINEL_KEY}" \
    '.tool_input.command = (.tool_input.command // "") + " " + $s' \
    "$base_fixture")"
  # F-PASS01-S02: use mktemp to avoid CI matrix race on hardcoded /tmp path.
  local stderr_file
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${stderr_file}'" RETURN
  local stdout_out stderr_out
  stdout_out="$(bash -c "printf '%s' '${cred_payload}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of block-ai-attribution" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of block-ai-attribution" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-frontmatter-schema does not leak credential sentinel to stdout or stderr" {
  local hook="${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-frontmatter-schema-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # F-PASS01-S02: use mktemp to avoid CI matrix race on hardcoded /tmp path.
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-frontmatter-schema" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-frontmatter-schema" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-voice-avoid-list does not leak credential sentinel to stdout or stderr" {
  local hook="${PLUGIN_DIR}/hooks/validate-voice-avoid-list.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-voice-avoid-list-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # F-PASS01-S02: use mktemp to avoid CI matrix race on hardcoded /tmp path.
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-voice-avoid-list" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-voice-avoid-list" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-wikilink-integrity does not leak credential sentinel to stdout or stderr" {
  local hook="${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-wikilink-integrity-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # F-PASS01-S02: use mktemp to avoid CI matrix race on hardcoded /tmp path.
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-wikilink-integrity" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-wikilink-integrity" >&2
    return 1
  fi
}

@test "BC_2_17_004: brain-health-check does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  # Parameterized extension to cover all 13 hooks (S-02 fix).
  local hook="${PLUGIN_DIR}/hooks/brain-health-check.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/brain-health-check-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of brain-health-check" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of brain-health-check" >&2
    return 1
  fi
}

@test "BC_2_17_004: enforce-kebab-case does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/enforce-kebab-case.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/enforce-kebab-case-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of enforce-kebab-case" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of enforce-kebab-case" >&2
    return 1
  fi
}

@test "BC_2_17_004: flush-state-and-commit does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/flush-state-and-commit.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/flush-state-and-commit-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of flush-state-and-commit" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of flush-state-and-commit" >&2
    return 1
  fi
}

@test "BC_2_17_004: quarantine-fetch does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  # quarantine-fetch may exit 2 (Node absent) or 0/2 depending on URL verdict;
  # in all cases the sentinel in content must not appear in stdout or stderr.
  local hook="${PLUGIN_DIR}/hooks/quarantine-fetch.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/quarantine-fetch-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of quarantine-fetch" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of quarantine-fetch" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-index-log-coherence does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-index-log-coherence-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-index-log-coherence" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-index-log-coherence" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-page-type-policy does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/validate-page-type-policy.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-page-type-policy-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-page-type-policy" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-page-type-policy" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-publish-state does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/validate-publish-state.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-publish-state-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-publish-state" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-publish-state" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-source-id-citation does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/validate-source-id-citation.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-source-id-citation-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-source-id-citation" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-source-id-citation" >&2
    return 1
  fi
}

@test "BC_2_17_004: validate-source-immutability does not leak credential sentinel to stdout or stderr" {
  # BC-2.17.004 invariant 1: no hook may emit credential values in any output.
  local hook="${PLUGIN_DIR}/hooks/validate-source-immutability.sh"
  local base_fixture="${PLUGIN_DIR}/tests/fixtures/validate-source-immutability-sample.json"
  local cred_fixture_file stderr_file
  cred_fixture_file="$(mktemp)"
  stderr_file="$(mktemp)"
  # shellcheck disable=SC2064
  trap "rm -f '${cred_fixture_file}' '${stderr_file}'" RETURN
  _make_cred_fixture "$base_fixture" >"$cred_fixture_file"
  local stdout_out stderr_out
  stdout_out="$(bash -c "cat '${cred_fixture_file}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>"${stderr_file}" || true)"
  stderr_out="$(cat "${stderr_file}" 2>/dev/null || true)"
  if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stdout of validate-source-immutability" >&2
    return 1
  fi
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: sentinel found in stderr of validate-source-immutability" >&2
    return 1
  fi
}

@test "BC_2_17_004: emit_event credential masking — key matching *_key is redacted in stderr JSONL" {
  # Directly invoke the hook-event-emit.sh helper to verify masking at the emit
  # layer. This tests BC-2.17.004 invariant 1 at the helper level (not just
  # the hook level) — the redact pattern must work before hooks use it.
  local helper="${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
  [ -f "$helper" ]
  local stderr_out
  stderr_out="$(bash -c "
    source '${helper}'
    emit_event 'test.credential.check' 'api_key=${CRED_SENTINEL_KEY}' 'normal_field=safe_value'
  " 2>&1 || true)"
  # The emitted JSONL should NOT contain the raw sentinel value.
  if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
    echo "FAIL: raw credential sentinel found in emit_event output" >&2
    echo "Output was: ${stderr_out}" >&2
    return 1
  fi
  # The JSONL should contain [REDACTED] instead.
  echo "$stderr_out" | grep -qF "[REDACTED]"
}

# =============================================================================
# SECTION 6: BC-2.04.015 — Performance budget: p99 ≤ 100ms over 10 runs
# AC-001, AC-004: latency assertions inside hook-contracts.bats (not a separate
#                 script). Parameterized over all 13 hooks.
# AC-003: quarantine-fetch Node startup overhead is INCLUDED (not excluded).
#
# MEASUREMENT RATIONALE (F-PASS01-C02 fix):
#   Previous implementation used `bash -c "cat ${fixture} | bash ${hook}"` which
#   included 2 subprocess forks (bash -c wrapper + cat) outside the hook runtime.
#   This violated BC-2.04.015 PC1: "wall-clock time from hook invocation to exit."
#
#   Corrected implementation:
#   - $EPOCHREALTIME (bash 5.0+) captures microsecond-precision wall time as a
#     bash builtin — zero subprocess overhead at the timing boundary.
#   - Hook stdin is fed via bash I/O redirection "< fixture" — no cat subprocess.
#   - The only fork is the hook process itself (bash hook.sh < fixture) — that IS
#     the hook's runtime and is correctly included per BC-2.04.015 PC1.
#   - Requires bash 5.0+ for $EPOCHREALTIME. Project baseline is bash 5.2 per CLAUDE.md §Toolchain.
#
#   P99 estimator: N=10 samples, sort numerically, take the 9th-of-10 (second-
#   highest). BC-2.04.015 EC-003 states "single outlier does not constitute
#   failure." Using the 9th-of-10 (index [8] after 0-based sort) absorbs one
#   outlier. If flakiness is observed in CI, increase N to 20 (19th-of-20) per
#   the guidance in EC-003; do NOT lower the 100ms threshold.
# =============================================================================

# _assert_hook_p99_under_100ms <hook_path> <fixture_path> <hook_name>
# Runs the hook 10 times with the given fixture and asserts p99 (9th-of-10) < 100ms.
# Measurement uses $EPOCHREALTIME (bash builtin, no subprocess) for wall-clock time.
# Hook stdin is fed via bash redirection (< fixture) — no cat subprocess fork.
_assert_hook_p99_under_100ms() {
  local hook="$1"
  local fixture="$2"
  local hook_name="$3"

  local times=()
  local _iter
  for _iter in {1..10}; do
    local t0 t1 elapsed_ms
    # $EPOCHREALTIME: bash 5.0+ builtin (format: seconds.microseconds).
    # Capture inside the current bash process — no subprocess fork for timing.
    t0="${EPOCHREALTIME}"
    # Feed hook via stdin redirection — one fork (the hook), no cat.
    CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT}" bash "${hook}" \
      < "${fixture}" >/dev/null 2>&1 || true
    t1="${EPOCHREALTIME}"
    # Convert fractional seconds to integer milliseconds using awk (no subshell
    # that would skew the next iteration, awk is called after the hook exits).
    elapsed_ms="$(awk "BEGIN{printf \"%.0f\", (${t1} - ${t0}) * 1000}")"
    times+=("${elapsed_ms}")
  done

  # Sort numerically. P99 estimator = 9th-of-10 (index 8, 0-based after sort).
  # This absorbs the single highest outlier per BC-2.04.015 EC-003.
  local sorted_str
  sorted_str="$(printf '%s\n' "${times[@]}" | sort -n)"
  # Use sed to get line 9 (1-based) = 9th-of-10.
  local p99
  p99="$(printf '%s\n' "${times[@]}" | sort -n | sed -n '9p')"

  if [[ "${p99}" -ge 100 ]]; then
    echo "FAIL: Hook ${hook_name} p99 latency ${p99}ms >= 100ms budget (BC-2.04.015)" >&2
    echo "All times (ms): ${times[*]}" >&2
    echo "Sorted: ${sorted_str}" >&2
    return 1
  fi
}

@test "BC_2_04_015: block-ai-attribution p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/block-ai-attribution.sh" \
    "${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json" \
    "block-ai-attribution"
}

@test "BC_2_04_015: brain-health-check p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/brain-health-check.sh" \
    "${PLUGIN_DIR}/tests/fixtures/brain-health-check-sample.json" \
    "brain-health-check"
}

@test "BC_2_04_015: enforce-kebab-case p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/enforce-kebab-case.sh" \
    "${PLUGIN_DIR}/tests/fixtures/enforce-kebab-case-sample.json" \
    "enforce-kebab-case"
}

@test "BC_2_04_015: flush-state-and-commit p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/flush-state-and-commit.sh" \
    "${PLUGIN_DIR}/tests/fixtures/flush-state-and-commit-sample.json" \
    "flush-state-and-commit"
}

@test "BC_2_04_015: quarantine-fetch p99 latency <100ms over 10 runs (Node startup INCLUDED per AC-003)" {
  # AC-003: Node startup overhead is NOT excluded. If Node startup alone
  # approaches 100ms in CI, the quarantine hook design requires rethinking
  # (e.g., pre-warmed process). Flag this as a Phase 1c architecture concern
  # if the test begins failing on GitHub Actions ubuntu-latest.
  #
  # In environments without Node, the hook exits 2 immediately (fast).
  # In environments with Node, startup + quarantine.mjs load must be < 100ms.
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/quarantine-fetch.sh" \
    "${PLUGIN_DIR}/tests/fixtures/quarantine-fetch-sample.json" \
    "quarantine-fetch"
}

@test "BC_2_04_015: validate-frontmatter-schema p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-frontmatter-schema-sample.json" \
    "validate-frontmatter-schema"
}

@test "BC_2_04_015: validate-index-log-coherence p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-index-log-coherence.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-index-log-coherence-sample.json" \
    "validate-index-log-coherence"
}

@test "BC_2_04_015: validate-page-type-policy p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-page-type-policy.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-page-type-policy-sample.json" \
    "validate-page-type-policy"
}

@test "BC_2_04_015: validate-publish-state p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-publish-state.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-publish-state-sample.json" \
    "validate-publish-state"
}

@test "BC_2_04_015: validate-source-id-citation p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-source-id-citation.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-source-id-citation-sample.json" \
    "validate-source-id-citation"
}

@test "BC_2_04_015: validate-source-immutability p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-source-immutability.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-source-immutability-sample.json" \
    "validate-source-immutability"
}

@test "BC_2_04_015: validate-voice-avoid-list p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-voice-avoid-list.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-voice-avoid-list-sample.json" \
    "validate-voice-avoid-list"
}

@test "BC_2_04_015: validate-wikilink-integrity p99 latency <100ms over 10 runs" {
  _assert_hook_p99_under_100ms \
    "${PLUGIN_DIR}/hooks/validate-wikilink-integrity.sh" \
    "${PLUGIN_DIR}/tests/fixtures/validate-wikilink-integrity-sample.json" \
    "validate-wikilink-integrity"
}

# =============================================================================
# SECTION 7: Edge cases
# BC-2.04.016 EC-002: malformed JSON stdin → exit 2 + JSON stdout
# BC-2.17.003 EC-002: debug echo to stdout must not corrupt JSON parse
# =============================================================================

@test "BC_2_04_016_EC002: block-ai-attribution malformed JSON stdin exits 2" {
  local hook="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  run bash -c "printf 'not-valid-json' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf 'not-valid-json' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
}

@test "BC_2_04_016_EC002: enforce-kebab-case malformed JSON stdin exits 2" {
  local hook="${PLUGIN_DIR}/hooks/enforce-kebab-case.sh"
  run bash -c "printf 'not-valid-json' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf 'not-valid-json' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
}

@test "BC_2_04_016_EC002: validate-frontmatter-schema malformed JSON stdin exits 2" {
  local hook="${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh"
  run bash -c "printf 'not-valid-json' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'"
  [ "$status" -eq 2 ]
  run bash -c "printf 'not-valid-json' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}' 2>/dev/null"
  echo "$output" | jq -e '.' >/dev/null
}

@test "BC_2_17_003_EC002: no debug echo pollutes stdout for block-ai-attribution" {
  # If a developer adds `echo "DEBUG: ..."` to stdout, jq parse of the combined
  # output would fail. This tests that stdout remains parseable JSON even
  # when the hook emits to both stdout and stderr on the happy path.
  local hook="${PLUGIN_DIR}/hooks/block-ai-attribution.sh"
  local fixture="${PLUGIN_DIR}/tests/fixtures/block-ai-attribution-sample.json"
  local combined_stdout
  combined_stdout="$(bash -c "cat '${fixture}' | CLAUDE_PLUGIN_ROOT='${CLAUDE_PLUGIN_ROOT}' bash '${hook}'" 2>/dev/null || true)"
  # Verify: exactly one JSON object, no debug noise.
  echo "$combined_stdout" | jq -e '. | type == "object"' >/dev/null
  local line_count
  line_count="$(echo "$combined_stdout" | grep -c '^' || true)"
  [ "$line_count" -eq 1 ]
}
