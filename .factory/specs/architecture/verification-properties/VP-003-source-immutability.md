---
document_type: verification-property
id: VP-003
title: "Source immutability enforcement"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.04.002, BC-2.06.001]
created: 2026-05-15
status: proposed
---

# VP-003: Source immutability enforcement

## Property Statement

For any path P that exists as a key in `manifest.json`, a PostToolUse hook invocation with `input.path = P` and a Write tool will produce: exit code 2, verdict `block`, code `E-SOURCE-001`. For any path P not in manifest.json, the same invocation will produce: exit code 0, verdict `allow`.

## Verification Mechanism

bats (hooks.bats) with fixture manifest.json:

```bash
@test "validate-source-immutability.sh: existing source path → E-SOURCE-001" {
  # manifest.json fixture has "sources/ai/existing-article.md" as a key
  local payload='{"tool":"Write","input":{"path":"sources/ai/existing-article.md","content":"..."},"output":{}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-immutability.sh"
  assert_failure 2
  assert_output --partial '"code":"E-SOURCE-001"'
}

@test "validate-source-immutability.sh: new source path → allow" {
  local payload='{"tool":"Write","input":{"path":"sources/ai/new-article.md","content":"..."},"output":{}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-immutability.sh"
  assert_success
  assert_output --partial '"verdict":"allow"'
}

@test "validate-source-immutability.sh: path not in sources/ → allow (no-op)" {
  local payload='{"tool":"Write","input":{"path":"wiki/concepts/test.md","content":"..."},"output":{}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-immutability.sh"
  assert_success
}
```

**Determinism property:** same payload run twice → same stdout verdict JSON and same exit code (modulo `ts` and `trace` fields). Verified by re-running the bats test case twice in the same suite run.

## Assumed Prerequisites

- manifest.json fixture in `tests/fixtures/` with known existing and non-existing paths
- jq installed

## Counterexamples

- A second write to `sources/ai/existing-article.md` exits 0 (overwrite permitted — violates BC-2.06.001)
- The hook exits 1 (advisory) instead of 2 (block) on an existing source path (wrong severity)
- The hook does not check the `sources/` prefix and blocks all Write tool calls regardless of path

## Status

proposed — pending Phase 3 implementation
