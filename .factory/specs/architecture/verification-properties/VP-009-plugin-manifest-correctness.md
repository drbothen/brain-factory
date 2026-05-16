---
document_type: verification-property
id: VP-009
title: "Plugin manifest schema correctness"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.14.004, BC-2.14.005]
created: 2026-05-15
status: proposed
---

# VP-009: Plugin manifest schema correctness

## Property Statement

`plugins/brain-factory/.claude-plugin/plugin.json` is valid JSON with a semver `version` field, and `hooks.json.template` references exactly 13 hooks via `${CLAUDE_PLUGIN_ROOT}` paths. No hook in hooks.json.template references a non-existent hook script.

## Verification Mechanism

bats (upgrade.bats) — schema validation via jq:

```bash
@test "plugin.json is valid JSON with required fields" {
  run jq -e '
    .name and .version and .description and .author and .license
  ' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json"
  assert_success
}

@test "plugin.json version matches semver pattern" {
  local version; version="$(jq -r '.version' "${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json")"
  run echo "$version" | grep -qP '^\d+\.\d+\.\d+(-[a-zA-Z0-9.]+)?(\+[a-zA-Z0-9.]+)?$'
  assert_success "version '$version' does not match semver pattern"
}

@test "hooks.json.template references exactly 13 hooks" {
  local hook_count
  hook_count="$(jq '[.. | strings | select(endswith(".sh"))] | length' \
    "${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json.template")"
  assert_equal "$hook_count" "13"
}

@test "all hooks.json.template hook paths exist as files" {
  jq -r '[.. | strings | select(endswith(".sh"))] | .[]' \
    "${CLAUDE_PLUGIN_ROOT}/hooks/hooks.json.template" \
  | sed "s|\${CLAUDE_PLUGIN_ROOT}|${CLAUDE_PLUGIN_ROOT}|g" \
  | while read -r hook_path; do
    assert_file_exists "$hook_path" "hook path in template does not exist: $hook_path"
  done
}
```

## Assumed Prerequisites

- jq installed
- `${CLAUDE_PLUGIN_ROOT}` resolved to the plugin root during test

## Counterexamples

- plugin.json is missing the `version` field (BC-2.14.004 violation)
- plugin.json `version` is `"latest"` instead of a semver string
- hooks.json.template references 12 hooks (omitting one) or 14 (adding a phantom hook)
- hooks.json.template references `${CLAUDE_PLUGIN_ROOT}/hooks/nonexistent-hook.sh` (no corresponding .sh file)
- hooks.json.template uses a hardcoded absolute path instead of `${CLAUDE_PLUGIN_ROOT}` (BC-2.14.005 violation)

## Status

proposed — pending Phase 3 implementation of plugin manifest and test suite
