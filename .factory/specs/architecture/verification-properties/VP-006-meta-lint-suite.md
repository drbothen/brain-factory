---
document_type: verification-property
id: VP-006
title: "Meta-lint factory self-audit"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
verifies_bcs: [BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.004, BC-2.18.005]
created: 2026-05-15
status: proposed
---

# VP-006: Meta-lint factory self-audit

## Property Statement

Running `bats tests/meta-lint.bats` against the brain-factory plugin source produces zero failures. This means: every SKILL.md has valid frontmatter and 6-section structure; every hook script has shebang + `set -euo pipefail` + no bare exit + no eval + a corresponding bats test file; every AGENT.md declares scope + tool-profile + routing reference; no tracked file contains AI attribution tokens, `--no-verify`, or hardcoded `.claude/templates/` paths.

## Verification Mechanism

meta-lint.bats — static analysis of the plugin source tree:

```bash
@test "every SKILL.md has Iron Law section" {
  for skill_dir in "${CLAUDE_PLUGIN_ROOT}"/skills/*/; do
    local skill_file="${skill_dir}/SKILL.md"
    assert_file_exists "$skill_file"
    run grep -q "^## Iron Law" "$skill_file"
    assert_success "SKILL.md in $skill_dir missing Iron Law section"
  done
}

@test "every hook script has set -euo pipefail in first 10 lines" {
  for hook in "${CLAUDE_PLUGIN_ROOT}"/hooks/*.sh; do
    run head -10 "$hook" | grep -q "set -euo pipefail"
    assert_success "$hook missing set -euo pipefail in first 10 lines"
  done
}

@test "no hook script contains bare exit" {
  for hook in "${CLAUDE_PLUGIN_ROOT}"/hooks/*.sh; do
    run grep -n "^[[:space:]]*exit[[:space:]]*$" "$hook"
    assert_failure "bare exit found in $hook"
  done
}

@test "no tracked file contains Co-Authored-By: Claude" {
  run git grep -l "Co-Authored-By: Claude" -- '*.md' '*.sh' '*.yaml' '*.json'
  assert_failure "AI attribution found in tracked files"
}
```

The property is falsified if meta-lint.bats has any failing test. Failing meta-lint is a P1 adversarial finding — the factory cannot enforce its contracts on users if it doesn't enforce them on its own source.

## Assumed Prerequisites

- git installed (for `git grep` cross-cutting checks)
- Plugin source tree exists at `${CLAUDE_PLUGIN_ROOT}`

## Counterexamples

- A SKILL.md is added without the Iron Law section (meta-lint would catch this)
- A hook script uses bare `exit` (meta-lint would catch this)
- An AGENT.md is added without a routing reference (meta-lint would catch this)

## Status

proposed — pending Phase 3 implementation of meta-lint.bats
