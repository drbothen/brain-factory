---
document_type: verification-property
id: VP-011
title: "Quarantine on every WebFetch"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
verifies_bcs: [BC-2.10.002, BC-2.04.001]
created: 2026-05-15
status: proposed
---

# VP-011: Quarantine on every WebFetch

## Property Statement

Every invocation of the WebFetch tool in a brain-factory Claude Code session triggers `quarantine-fetch.sh` as a PreToolUse hook before the fetch executes. No skill or agent can invoke WebFetch without the quarantine hook firing first.

## Verification Mechanism

bats (quarantine.bats) — end-to-end via the local-dev-test harness:

```bash
@test "quarantine fires on every WebFetch in plugin session" {
  # Run a test skill that invokes WebFetch
  bash "${CLAUDE_PLUGIN_ROOT}/tests/local-dev-test.sh" --scenario quarantine-coverage
  
  # Count WebFetch invocations in the session log
  local fetch_count; fetch_count="$(grep '"tool":"WebFetch"' "${TEMP_BRAIN}/.brain/logs/hooks-$(date +%Y-%m-%d).jsonl" | wc -l)"
  # Count quarantine-fetch.sh PreToolUse events
  local quarantine_count; quarantine_count="$(grep '"hook_name":"quarantine-fetch.sh"' "${TEMP_BRAIN}/.brain/logs/hooks-$(date +%Y-%m-%d).jsonl" | wc -l)"
  
  assert_equal "$fetch_count" "$quarantine_count" \
    "quarantine did not fire for all WebFetch calls: fetch=$fetch_count quarantine=$quarantine_count"
}

@test "quarantine blocks known injection pattern" {
  echo '{"tool":"WebFetch","input":{"url":"https://attacker.example.com/inject"}}' \
    | "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh"
  assert_failure 2
  assert_output --partial '"code":"E-QUARANTINE-001"'
}

@test "quarantine curl timeout → exit 2 fail-closed" {
  # Simulate curl timeout by pointing at an unreachable address
  QUARANTINE_CURL_TIMEOUT=1 \
  echo '{"tool":"WebFetch","input":{"url":"http://10.255.255.1/"}}' \
    | "${CLAUDE_PLUGIN_ROOT}/hooks/quarantine-fetch.sh"
  assert_failure 2
}
```

The coverage assertion (quarantine count = WebFetch count) is the key property. It verifies that the `WebFetch` matcher in hooks.json.template is correctly registered and that the Claude Code harness fires it for every WebFetch tool call.

## Assumed Prerequisites

- Plugin installed with hooks.json.template registered
- `.brain/logs/` captures hook events (JSONL)
- Test harness invokes WebFetch at least once via `/brain:ingest-url` in the test scenario

## Counterexamples

- A skill invokes WebFetch via a renamed tool call that doesn't match the `WebFetch` matcher (bypass)
- quarantine-fetch.sh is not registered in hooks.json.template for all WebFetch matchers (registration gap)
- curl timeout causes the hook to exit 0 instead of 2 (fail-open — violates NFR-016)

## Status

proposed — pending Phase 3 implementation of quarantine.bats
