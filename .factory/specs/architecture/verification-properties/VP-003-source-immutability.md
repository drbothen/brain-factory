---
document_type: verification-property
id: VP-003
title: "Source immutability enforcement"
level: L3
version: "1.2"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-18T00:00:00
verifies_bcs: [BC-2.04.002, BC-2.06.001]
created: 2026-05-15
status: proposed
---

# VP-003: Source immutability enforcement

## Property Statement

For any path P that exists as a key in `manifest.json`, a PostToolUse hook invocation with `tool_input.path = P` and a Write tool will produce: exit code 2, decision `block`, code `E-SOURCE-001`. For any path P not in manifest.json, the same invocation will produce: exit code 0, `continue: true`.

## Verification Mechanism

bats (`tests/validate-source-immutability.bats`) with fixture manifest.json:

```bash
@test "validate-source-immutability.sh: existing source path → E-SOURCE-001" {
  # manifest.json fixture has "sources/ai/existing-article.md" as a key
  local payload='{"tool_name":"Write","tool_input":{"path":"sources/ai/existing-article.md","content":"..."}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-immutability.sh"
  assert_failure 2
  assert_output --partial '"code":"E-SOURCE-001"'
}

@test "validate-source-immutability.sh: new source path → allow" {
  local payload='{"tool_name":"Write","tool_input":{"path":"sources/ai/new-article.md","content":"..."}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-source-immutability.sh"
  assert_success
  assert_output --partial '"continue":true'
}

@test "validate-source-immutability.sh: path not in sources/ → allow (no-op)" {
  local payload='{"tool_name":"Write","tool_input":{"path":"wiki/concepts/test.md","content":"..."}}'
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
- The hook exits 1 on an existing source path (exit 1 = debug log only, not a block; exit 2 is required)
- The hook does not check the `sources/` prefix and blocks all Write tool calls regardless of path

## Status

proposed — pending Phase 3 implementation

## Changelog

### v1.2 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** §Property Statement updated `input.path` → `tool_input.path`, `verdict block` → `decision block`, `verdict allow` → `continue: true`. §Verification Mechanism fixture payloads updated: `"tool":"Write"` → `"tool_name":"Write"`, `"input":{...}` → `"tool_input":{...}`, `"output":{}` removed (PostToolUse `tool_result` absent in fixture per interface spec), `'"verdict":"allow"'` → `'"continue":true'`. §Counterexamples updated exit 1 advisory semantics (exit 1 = debug log only). [audit-trail]

### v1.1 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE — §Verification Mechanism updated to per-hook .bats convention):** Mechanism changed from `bats (hooks.bats) with fixture manifest.json` to `bats (tests/validate-source-immutability.bats) with fixture manifest.json`. The hook tests now live in the per-hook file `tests/validate-source-immutability.bats`. Cascades from SS-18 v1.5 per-hook .bats reversal (F-PHASE2-STEP-B-CLOSEOUT-O1). [audit-trail]
