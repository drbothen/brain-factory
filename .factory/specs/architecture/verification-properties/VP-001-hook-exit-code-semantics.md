---
document_type: verification-property
id: VP-001
title: "Hook exit-code semantics coverage"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.04.016, BC-2.04.015]
created: 2026-05-15
status: proposed
---

# VP-001: Hook exit-code semantics coverage

## Property Statement

For every hook script in `plugins/brain-factory/hooks/`, the following holds:
- A clean stdin payload (no violations) results in exit code 0 and a `{"verdict":"allow",...}` stdout JSON
- A violating stdin payload (specific violation for that hook) results in exit code 2 and a `{"verdict":"block","code":"E-SCOPE-NNN",...}` stdout JSON
- A malformed stdin payload (invalid JSON) results in exit code 2 (fail-closed per NFR-016)
- No hook exits with any code other than 0, 1, or 2

## Verification Mechanism

bats (hooks.bats) — each hook has ≥ 3 test cases per NFR-020:

```bash
@test "quarantine-fetch.sh: clean URL → exit 0 allow" {
  echo '{"tool":"WebFetch","input":{"url":"https://paulgraham.com/think.html"}}' \
    | "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh"
  assert_success
  assert_output --partial '"verdict":"allow"'
}

@test "quarantine-fetch.sh: injected content → exit 2 block E-QUARANTINE-001" {
  echo '{"tool":"WebFetch","input":{"url":"https://injected.example.com"}}' \
    | "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh"
  assert_failure 2
  assert_output --partial '"code":"E-QUARANTINE-001"'
}

@test "quarantine-fetch.sh: malformed stdin → exit 2 fail-closed" {
  echo 'not-valid-json' | "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh"
  assert_failure 2
}
```

This pattern repeats for all 13 hooks.

## Assumed Prerequisites

- jq installed (make setup)
- Hook scripts are chmod +x
- Test fixtures in `tests/fixtures/` provide representative payloads per hook

## Counterexamples (what would falsify this property)

- A hook exits 0 on malformed stdin (violates fail-closed guarantee NFR-016)
- A hook exits 3 or any code not in {0, 1, 2} (violates BC-2.04.016)
- A hook emits a verdict JSON without the `trace` field (violates interface-definitions.md §2)
- The p99 latency measurement for any hook exceeds 100ms (violates BC-2.04.015)

## Status

proposed — pending Phase 3 implementation of hooks.bats
