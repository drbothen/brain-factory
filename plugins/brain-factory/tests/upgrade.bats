#!/usr/bin/env bats
# STORY-001 VP-009 verification tests
#
# Traces to: BC-2.14.003, BC-2.14.004, BC-2.14.005, VP-009
# Red Gate: tests for plugin.json content and hooks.json content MUST FAIL
# before implementation because both files are currently empty stubs ({}).
# Tests for directory structure PASS because stubs already created those.
#
# Run from repo root: bats plugins/brain-factory/tests/upgrade.bats

setup() {
  # Tests execute assertions relative to the plugin directory
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  PLUGIN_JSON="${PLUGIN_DIR}/.claude-plugin/plugin.json"
  HOOKS_JSON="${PLUGIN_DIR}/hooks/hooks.json"
}

# ---------------------------------------------------------------------------
# plugin.json tests
# ---------------------------------------------------------------------------

# AC-001 / BC-2.14.004 postcondition 1
@test "BC_2_14_004: plugin.json exists and is valid JSON" {
  run jq -e '.' "$PLUGIN_JSON"
  [ "$status" -eq 0 ]
}

# AC-001 / BC-2.14.004 postcondition 1-2 — RED GATE (empty {} fails these field checks)
@test "BC_2_14_004: plugin.json has required top-level fields" {
  run jq -e '.name and .displayName and .version and .description and .author and .license and .keywords and .skills and .agents and .hooks' "$PLUGIN_JSON"
  [ "$status" -eq 0 ]
}

# AC-001 / BC-2.14.004 postcondition 1 — RED GATE
@test "BC_2_14_004: plugin.json version matches semver pattern" {
  local version
  version="$(jq -r '.version' "$PLUGIN_JSON")"
  [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]
}

# AC-001 / BC-2.14.004 postcondition 1 — RED GATE
@test "BC_2_14_004: plugin.json name is brain-factory" {
  local name
  name="$(jq -r '.name' "$PLUGIN_JSON")"
  [ "$name" = "brain-factory" ]
}

# AC-002 / BC-2.14.004 postcondition 3 — PASSES (stub directories already exist)
@test "BC_2_14_004: 27 skill directories exist under skills/" {
  local count
  count="$(find "${PLUGIN_DIR}/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  [ "$count" -eq 27 ]
}

# AC-002 / BC-2.14.004 postcondition 4 — PASSES (stub directories already exist)
@test "BC_2_14_004: 14 agent directories exist under agents/" {
  local count
  count="$(find "${PLUGIN_DIR}/agents" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')"
  [ "$count" -eq 14 ]
}

# ---------------------------------------------------------------------------
# hooks.json tests
# ---------------------------------------------------------------------------

# AC-003 / BC-2.14.005 postcondition 1
@test "BC_2_14_005: hooks.json exists and is valid JSON" {
  run jq -e '.' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}

# AC-003 / BC-2.14.005 postcondition 2 — RED GATE (empty {} has 0 .sh strings)
@test "BC_2_14_005: hooks.json has exactly 13 hook script entries" {
  local count
  count="$(jq '[.. | strings | select(endswith(".sh"))] | length' "$HOOKS_JSON")"
  [ "$count" -eq 13 ]
}

# AC-003 / BC-2.14.005 postcondition 3 — RED GATE (empty {} has no CLAUDE_PLUGIN_ROOT refs)
@test "BC_2_14_005: all 13 hook paths use \${CLAUDE_PLUGIN_ROOT}" {
  local count
  count="$(grep -c '\${CLAUDE_PLUGIN_ROOT}' "$HOOKS_JSON")"
  [ "$count" -eq 13 ]
}

# AC-007 / BC-2.14.003 invariant 2 — RED GATE (empty {} passes vacuously but real content must not have these)
@test "BC_2_14_003: no hardcoded absolute paths in hooks.json" {
  # grep -qE returns 0 when a match IS found — we want NO match (non-zero)
  run grep -qE '/(Users|home|usr)/' "$HOOKS_JSON"
  [ "$status" -ne 0 ]
}

# AC-004 / BC-2.14.005 postcondition 2 — RED GATE (no paths to verify in empty {})
@test "BC_2_14_005: all hook paths in hooks.json reference existing .sh files" {
  # Extract every string value ending in .sh from hooks.json, strip the
  # ${CLAUDE_PLUGIN_ROOT}/ prefix, and verify the remainder exists under hooks/
  local paths
  paths="$(jq -r '[.. | strings | select(endswith(".sh"))] | .[]' "$HOOKS_JSON")"

  # Fail immediately if no paths found (empty hooks.json = 0 paths = Red Gate)
  [ -n "$paths" ]

  while IFS= read -r raw_path; do
    # Strip the ${CLAUDE_PLUGIN_ROOT}/ prefix to get the relative path
    local rel_path
    rel_path="${raw_path#\$\{CLAUDE_PLUGIN_ROOT\}/}"
    local abs_path="${PLUGIN_DIR}/${rel_path}"
    if [ ! -f "$abs_path" ]; then
      echo "MISSING hook file: $abs_path (from hooks.json entry: $raw_path)" >&2
      return 1
    fi
  done <<< "$paths"
}

# BC-2.14.005 postcondition 2: correct event types
@test "BC_2_14_005: hooks.json has correct event type keys" {
  # Must have exactly these 4 event type keys
  local keys
  keys="$(jq -r '.hooks | keys[]' "$HOOKS_JSON" | sort)"
  local expected
  expected="$(printf 'PostToolUse\nPreToolUse\nSessionStart\nStop' | sort)"
  [ "$keys" = "$expected" ]
}

@test "BC_2_14_005: quarantine-fetch is PreToolUse with WebFetch matcher" {
  run jq -e '.hooks.PreToolUse[] | select(.matcher == "WebFetch") | .hooks[] | select(.command | endswith("quarantine-fetch.sh"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}

@test "BC_2_14_005: enforce-kebab-case is PreToolUse with Write|Edit matcher" {
  run jq -e '.hooks.PreToolUse[] | select(.matcher == "Write\\|Edit") | .hooks[] | select(.command | endswith("enforce-kebab-case.sh"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}

@test "BC_2_14_005: block-ai-attribution is PreToolUse with Bash matcher" {
  run jq -e '.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[] | select(.command | endswith("block-ai-attribution.sh"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}

@test "BC_2_14_005: 8 PostToolUse validation hooks with Write|Edit matcher" {
  local count
  count="$(jq '[.hooks.PostToolUse[] | select(.matcher == "Write\\|Edit") | .hooks[] | .command] | length' "$HOOKS_JSON")"
  [ "$count" -eq 8 ]
}

@test "BC_2_14_005: flush-state-and-commit is Stop event" {
  run jq -e '.hooks.Stop[] | .hooks[] | select(.command | endswith("flush-state-and-commit.sh"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}

@test "BC_2_14_005: brain-health-check is SessionStart event" {
  run jq -e '.hooks.SessionStart[] | .hooks[] | select(.command | endswith("brain-health-check.sh"))' "$HOOKS_JSON"
  [ "$status" -eq 0 ]
}

@test "BC_2_14_005: all hook entries have timeout field" {
  local without_timeout
  without_timeout="$(jq '[.. | objects | select(.type == "command" and (.timeout == null))] | length' "$HOOKS_JSON")"
  [ "$without_timeout" -eq 0 ]
}

# ---------------------------------------------------------------------------
# Directory structure tests (AC-005 / BC-2.14.003 postcondition 1)
# These PASS because stubs created the directories already.
# ---------------------------------------------------------------------------

@test "BC_2_14_003: required directory .claude-plugin/ exists" {
  [ -d "${PLUGIN_DIR}/.claude-plugin" ]
}

@test "BC_2_14_003: required directory skills/ exists" {
  [ -d "${PLUGIN_DIR}/skills" ]
}

@test "BC_2_14_003: required directory agents/ exists" {
  [ -d "${PLUGIN_DIR}/agents" ]
}

@test "BC_2_14_003: required directory hooks/ exists" {
  [ -d "${PLUGIN_DIR}/hooks" ]
}

@test "BC_2_14_003: required directory hooks/lib/ exists" {
  [ -d "${PLUGIN_DIR}/hooks/lib" ]
}

@test "BC_2_14_003: required directory workflows/ exists" {
  [ -d "${PLUGIN_DIR}/workflows" ]
}

@test "BC_2_14_003: required directory templates/ exists" {
  [ -d "${PLUGIN_DIR}/templates" ]
}

@test "BC_2_14_003: required directory templates/github-action-templates/ exists" {
  [ -d "${PLUGIN_DIR}/templates/github-action-templates" ]
}

@test "BC_2_14_003: required directory rules/ exists" {
  [ -d "${PLUGIN_DIR}/rules" ]
}

@test "BC_2_14_003: required directory bin/ exists" {
  [ -d "${PLUGIN_DIR}/bin" ]
}

@test "BC_2_14_003: required directory tests/ exists" {
  [ -d "${PLUGIN_DIR}/tests" ]
}

@test "BC_2_14_003: required directory tests/fixtures/ exists" {
  [ -d "${PLUGIN_DIR}/tests/fixtures" ]
}

# AC-007 / BC-2.14.003 invariant 2
@test "BC_2_14_003: no hardcoded absolute paths in hooks/ skills/ agents/ or .claude-plugin/" {
  # grep -rE returns 0 when matches are found — we want NO matches (non-zero exit)
  run grep -rE --include="*.sh" --include="*.json" --include="*.md" \
    '/(Users|home)/[^ ]+' \
    "${PLUGIN_DIR}/hooks/" \
    "${PLUGIN_DIR}/skills/" \
    "${PLUGIN_DIR}/agents/" \
    "${PLUGIN_DIR}/.claude-plugin/"
  [ "$status" -ne 0 ]
}
