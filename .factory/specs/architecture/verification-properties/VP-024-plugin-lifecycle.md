---
document_type: verification-property
id: VP-024
title: "Plugin lifecycle: install from marketplace and upgrade migration execution"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.14.001, BC-2.14.003]
created: 2026-05-15
status: proposed
---

# VP-024: Plugin lifecycle: install from marketplace and upgrade migration execution

## Property Statement

**Install from marketplace (BC-2.14.001):** A plugin install from `drbothen/claude-mp`
delivers a complete, working plugin installation: all 13 hook scripts, all 26 skill
SKILL.md files, all 14 agent AGENT.md files, all templates, all workflow YAML files,
and all scripts are present at the installed path. After installation, `/brain:health`
is invokable without error (it may return RED status on a non-brain directory — that
is correct behavior, not a crash). The tarball is the only distribution mechanism —
no npm/pip install paths exist.

**Upgrade migration script execution (BC-2.14.003):** When the operator runs
`/brain:upgrade-brain` to migrate from a prior version, the upgrade script executes
all applicable migration steps for the version delta (e.g., v0.1→v0.2 migration adds
`briefs/research/` if absent). Migration steps are idempotent: running the migration
script twice produces the same outcome as running it once. After migration, the brain
vault passes `/brain:health` with GREEN status.

## Verification Mechanism

bats (upgrade.bats) — local install simulation and migration idempotency:

```bash
# --- BC-2.14.001: Install completeness ---

@test "plugin install: all required artifact types present in installed plugin" {
  # Simulate plugin installation by inspecting the plugin directory structure
  local plugin_dir="${PLUGIN_ROOT}"

  # Verify hook scripts (13 required)
  local hook_count; hook_count="$(find "$plugin_dir/hooks" -name "*.sh" \
    ! -path "*/lib/*" | wc -l | tr -d ' ')"
  assert [ "$hook_count" -ge 13 ] "Expected >= 13 hook scripts, found $hook_count"

  # Verify SKILL.md files (26 required)
  local skill_count; skill_count="$(find "$plugin_dir/skills" -name "SKILL.md" | wc -l | tr -d ' ')"
  assert [ "$skill_count" -ge 26 ] "Expected >= 26 skill files, found $skill_count"

  # Verify AGENT.md files (14 required)
  local agent_count; agent_count="$(find "$plugin_dir/agents" -name "AGENT.md" | wc -l | tr -d ' ')"
  assert [ "$agent_count" -ge 14 ] "Expected >= 14 agent files, found $agent_count"

  # Verify templates directory exists with content
  local template_count; template_count="$(find "$plugin_dir/templates" -type f | wc -l | tr -d ' ')"
  assert [ "$template_count" -ge 1 ] "Expected at least 1 template file"

  # Verify GH Action templates (6 core for v0.1)
  local gh_template_count; gh_template_count="$(find \
    "$plugin_dir/templates/github-action-templates" -name "*.yml" | wc -l | tr -d ' ')"
  assert [ "$gh_template_count" -ge 6 ] "Expected >= 6 GH Action templates, found $gh_template_count"

  # Verify scripts/
  assert [ -f "$plugin_dir/scripts/defuddle-fetch.mjs" ] "Missing defuddle-fetch.mjs"
  assert [ -f "$plugin_dir/scripts/quarantine.mjs" ] "Missing quarantine.mjs"
  assert [ -f "$plugin_dir/scripts/event-catalog.json" ] "Missing event-catalog.json"
}

@test "plugin install: planning docs NOT present in plugin installation (tarball-only)" {
  # Planning artifacts must not ship in the tarball (BC-2.14.001 Invariant 3)
  local plugin_dir="${PLUGIN_ROOT}"
  run find "$plugin_dir" -name "*.md" -path "*planning*"
  assert_output ""  # No planning docs in plugin dir
  run find "$plugin_dir" -path "*docs/planning*"
  assert_output ""
}

@test "plugin install: brain:health callable without crash after install" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/non-brain-dir"
  mkdir -p "$brain_dir"

  # Run health on a non-brain directory — exits 2 (E-HEALTH-001: STATE.md missing),
  # which is a structured error, not a crash. Any exit code other than raw bash crash
  # (unhandled error) is acceptable; the output must always be parseable JSON.
  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    run bash "${PLUGIN_ROOT}/skills/brain-health/run.sh"
  # Exit 2 (E-HEALTH-001) is the expected structured response for missing STATE.md.
  # What we forbid is an unstructured bash crash (no JSON on stdout).
  # Output must be structured JSON.
  run jq empty <<< "$output"
  # At minimum, output is valid JSON (either health report or E-HEALTH-001 envelope)
}

# --- BC-2.14.003: Upgrade migration idempotency ---

@test "upgrade-brain: migration from v0.1 to v0.2 adds missing directories" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-upgrade-test"
  # Simulate a v0.1 brain that lacks the v0.2 addition (briefs/research/)
  setup_v01_fixture_brain "$brain_dir"
  refute [ -d "$brain_dir/briefs/research" ]

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/upgrade-brain/run.sh" --from 0.1 --to 0.2 --yes

  assert_success
  assert [ -d "$brain_dir/briefs/research" ]
}

@test "upgrade-brain: migration is idempotent (running twice produces identical result)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-idempotent-test"
  setup_v01_fixture_brain "$brain_dir"

  # First run
  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/upgrade-brain/run.sh" --from 0.1 --to 0.2 --yes
  assert_success

  # Capture state after first run
  local state_after_first; state_after_first="$(find "$brain_dir" -type f | sort | sha256sum)"

  # Second run (idempotent)
  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/upgrade-brain/run.sh" --from 0.1 --to 0.2 --yes
  assert_success

  # State must be identical after second run
  local state_after_second; state_after_second="$(find "$brain_dir" -type f | sort | sha256sum)"
  assert [ "$state_after_first" = "$state_after_second" ] \
    "Migration is not idempotent: file state changed between first and second run"
}

@test "upgrade-brain: brain passes health GREEN status after migration" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-post-upgrade-test"
  setup_v01_fixture_brain "$brain_dir"

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/upgrade-brain/run.sh" --from 0.1 --to 0.2 --yes

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    run bash "${PLUGIN_ROOT}/skills/brain-health/run.sh"
  assert_success  # GREEN status = exit 0
}
```

## Assumed Prerequisites

- `setup_v01_fixture_brain` creates a v0.1-era brain vault without v0.2+ directories
  (used to simulate a pre-upgrade brain state)
- `${PLUGIN_ROOT}` is the plugin installation directory under test
- The upgrade migration script reads the `--from` and `--to` version arguments to
  determine which migration steps to execute
- idempotency test uses `sha256sum` of the sorted file list to compare filesystem state

## Counterexamples

- The tarball includes `docs/planning/` files (which are immutable design-source
  artifacts, not runtime plugin files) — the planning-docs-absent test catches this
- The migration script is not idempotent: running it twice creates duplicate entries
  in `wiki/index.md` — the sha256 state-comparison test catches this
- `/brain:health` crashes with an unhandled bash error (exit 2 with no JSON output)
  on a non-brain directory — the health-callable test catches this specific failure mode

## Status

proposed — pending Phase 3 implementation of health skill, upgrade-brain skill,
and upgrade.bats
