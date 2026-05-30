---
document_type: verification-property
id: VP-017
title: "Hook enforcement: kebab-case filename gate and AI attribution block"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-18T00:00:00
verifies_bcs: [BC-2.04.011, BC-2.04.012, BC-2.04.017]
created: 2026-05-15
status: proposed
---

# VP-017: Hook enforcement: kebab-case filename gate and AI attribution block

## Property Statement

**Kebab-case enforcement (BC-2.04.011):** `enforce-kebab-case.sh` fires on every
PreToolUse Write or Edit event. For any target filename not matching
`^[a-z0-9][a-z0-9-]*(\.[a-z0-9]+)?$`, the hook exits 2 with a verdict carrying
`E-NAMING-001` and a suggested kebab-case conversion. Known uppercase-convention
exceptions (CLAUDE.md, README.md, CHANGELOG.md, MANIFEST.md, LICENSE) exit 0.
Valid kebab-case filenames exit 0.

**AI attribution block (BC-2.04.012):** `block-ai-attribution.sh` fires on every
PreToolUse Bash tool event. It scans the bash command string for three forbidden
patterns: the `Co-Authored-By: Claude` string, the robot emoji (`🤖`), and the string
"Generated with Claude Code". Any match exits 2 with `E-ATTR-001`. Clean bash commands
exit 0.

**stdout/stderr separation for hook event emission (BC-2.04.017):** Both hooks emit
at least one JSONL event on stderr per invocation. stdout contains exactly one JSON
verdict object. For both hooks, `jq empty <stdout>` succeeds on every code path
including error paths.

## Verification Mechanism

bats (`tests/enforce-kebab-case.bats` + `tests/block-ai-attribution.bats`):

```bash
# --- enforce-kebab-case.sh tests ---

@test "enforce-kebab-case: valid kebab-case filename → exit 0" {
  local payload='{"tool":"Write","input":{"path":"wiki/concepts/ai-agents.md"},"output":{}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh"
  assert_success
  assert_output --partial '"verdict":"allow"'
}

@test "enforce-kebab-case: space in filename → exit 2 E-NAMING-001 with suggestion" {
  local payload='{"tool":"Write","input":{"path":"wiki/concepts/AI Agents.md"},"output":{}}'
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-NAMING-001"'
  assert_output --partial 'ai-agents'  # suggested kebab conversion
}

@test "enforce-kebab-case: underscore in filename → exit 2 E-NAMING-001" {
  local payload='{"tool":"Write","input":{"path":"wiki/concepts/ai_agents.md"},"output":{}}'
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-NAMING-001"'
}

@test "enforce-kebab-case: CLAUDE.md exception → exit 0" {
  local payload='{"tool":"Write","input":{"path":"CLAUDE.md"},"output":{}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh"
  assert_success
}

@test "enforce-kebab-case: malformed stdin → exit 2 fail-closed" {
  run bash -c "echo 'not-json' | '${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh'"
  assert_failure 2
}

@test "enforce-kebab-case: stdout is valid JSON on all code paths (BC-2.04.017)" {
  for payload in \
    '{"tool":"Write","input":{"path":"ok.md"},"output":{}}' \
    '{"tool":"Write","input":{"path":"Bad Name.md"},"output":{}}' \
    'not-json'; do
    run bash -c "printf '%s' '$payload' | \
      '${CLAUDE_PLUGIN_ROOT}/hooks/enforce-kebab-case.sh' 2>/dev/null"
    run jq empty <<< "$output"
    assert_success "stdout is not valid JSON for payload: $payload"
  done
}

# --- block-ai-attribution.sh tests ---

@test "block-ai-attribution: clean git commit → exit 0" {
  local payload='{"tool":"Bash","input":{"command":"git commit -m \"feat: add feature\""}}'
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh"
  assert_success
}

@test "block-ai-attribution: Co-Authored-By: Claude in commit → exit 2 E-ATTR-001" {
  local cmd='git commit -m "feat\n\nCo-Authored-By: Claude Opus"'
  local payload="{\"tool\":\"Bash\",\"input\":{\"command\":\"${cmd}\"}}"
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-ATTR-001"'
}

@test "block-ai-attribution: robot emoji in command → exit 2 E-ATTR-001" {
  local payload='{"tool":"Bash","input":{"command":"echo 🤖 done"}}'
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-ATTR-001"'
}

@test "block-ai-attribution: Generated with Claude Code string → exit 2 E-ATTR-001" {
  local payload='{"tool":"Bash","input":{"command":"echo Generated with Claude Code"}}'
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-ATTR-001"'
}

@test "block-ai-attribution: stderr has JSONL event on every code path (BC-2.04.017)" {
  for payload in \
    '{"tool":"Bash","input":{"command":"git status"}}' \
    '{"tool":"Bash","input":{"command":"echo Co-Authored-By: Claude"}}'; do
    run bash -c "printf '%s' '$payload' | \
      '${CLAUDE_PLUGIN_ROOT}/hooks/block-ai-attribution.sh' 2>&1 >/dev/null"
    run jq empty <<< "$output"
    assert_success "stderr JSONL is not valid JSON for payload: $payload"
  done
}
```

## Assumed Prerequisites

- `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation in test context
- Both hook scripts are `chmod +x`
- `jq` in PATH for verdict parsing and JSONL validation

## Counterexamples

- `enforce-kebab-case.sh` uses string prefix check on the full path (not just the basename)
  and incorrectly blocks valid paths like `wiki/concepts/ai-agents.md` because `wiki/`
  starts with a lowercase letter but conceptually doesn't fail the rule
- `block-ai-attribution.sh` exits 0 on malformed stdin — this violates the fail-closed
  guarantee (NFR-016) and allows a malformed payload to masquerade as a clean command
- Either hook produces non-JSON output on stdout for any code path — `jq empty` assertions
  catch this class of defect

## Status

proposed — pending Phase 3 implementation of enforce-kebab-case.sh, block-ai-attribution.sh,
and their per-hook .bats files

## Changelog

### v1.1 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE — §Verification Mechanism and §Status updated to per-hook .bats convention):** Mechanism changed from `bats (hooks.bats)` to `bats (tests/enforce-kebab-case.bats + tests/block-ai-attribution.bats)`. §Status reference to "hooks.bats" updated to "their per-hook .bats files". Each hook's tests live in its own per-hook file. Cascades from SS-18 v1.5 per-hook .bats reversal (F-PHASE2-STEP-B-CLOSEOUT-O1). [audit-trail]
