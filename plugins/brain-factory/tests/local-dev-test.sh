#!/usr/bin/env bash
set -euo pipefail

# local-dev-test.sh — §5.10 end-to-end convenience script for STORY-003
# Exercises run.sh against a temp brain dir and asserts on filesystem output
# and SLA compliance.  Run manually during development; also consumed by
# run-all.sh when it invokes the local-dev surface.
#
# Usage:  bash plugins/brain-factory/tests/local-dev-test.sh
# Env:    CLAUDE_PLUGIN_ROOT  (defaults to the plugin dir relative to this script)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-${PLUGIN_DIR}}"

_pass() { printf '[PASS] %s\n' "$1"; }
_fail() {
  printf '[FAIL] %s\n' "$1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# assert_under_5_minutes
# Creates a temp git-init'd brain dir, runs run.sh, measures elapsed time,
# asserts < 300 s and checks briefs/research/ was created.
# ---------------------------------------------------------------------------
assert_under_5_minutes() {
  local brain_dir
  brain_dir="$(mktemp -d)"
  git -C "$brain_dir" init -q

  local start="$SECONDS"
  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT" \
    bash "${PLUGIN_DIR}/skills/init/run.sh"
  local exit_code="$?"
  local elapsed=$((SECONDS - start))

  if [[ "$exit_code" -ne 0 ]]; then
    rm -rf "$brain_dir"
    _fail "run.sh exited ${exit_code} (expected 0)"
  fi

  if [[ "$elapsed" -ge 300 ]]; then
    rm -rf "$brain_dir"
    _fail "brain:init took ${elapsed}s, exceeds 5-minute SLA"
  fi
  _pass "SLA: init completed in ${elapsed}s (< 300s)"

  # AC-001 / BC-2.01.005: briefs/research/ must exist
  if [[ ! -d "${brain_dir}/briefs/research" ]]; then
    rm -rf "$brain_dir"
    _fail "briefs/research/ not created by init"
  fi
  _pass "briefs/research/ exists after init"

  # Spot-check a few other required dirs
  local required_dirs=(
    "sources/ai"
    "wiki/concepts"
    "inbox"
    "briefs/daily"
    "briefs/weekly"
    "briefs/monthly"
    "briefs/content"
    "briefs/decisions"
    ".brain/logs"
    ".github/workflows"
    "rules"
  )
  for d in "${required_dirs[@]}"; do
    if [[ ! -d "${brain_dir}/${d}" ]]; then
      rm -rf "$brain_dir"
      _fail "Required directory missing after init: ${d}"
    fi
  done
  _pass "All required directories present"

  rm -rf "$brain_dir"
}

# ---------------------------------------------------------------------------
# assert_error_path: verify a specific error code is emitted on stdout
# $1 = test label, $2 = expected E-INIT-NNN code, $3..= env overrides + run.sh
# ---------------------------------------------------------------------------
assert_error_path() {
  local label="$1"
  local expected_code="$2"
  shift 2

  local actual_output actual_exit=0
  # "$@" is the full command to run; capture stdout; capture exit code
  actual_output="$("$@" 2>/dev/null)" || actual_exit=$?

  if [[ "$actual_exit" -ne 2 ]]; then
    _fail "${label}: expected exit 2 got exit ${actual_exit}"
  fi

  local actual_code
  actual_code="$(printf '%s' "$actual_output" | jq -r '.code' 2>/dev/null || true)"

  if [[ "$actual_code" != "$expected_code" ]]; then
    _fail "${label}: expected code=${expected_code} got code=${actual_code}"
  fi
  _pass "${label}: got expected ${expected_code} (exit 2)"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

printf 'local-dev-test.sh — STORY-003 end-to-end\n'
printf 'PLUGIN_DIR=%s\n' "$PLUGIN_DIR"
printf '\n'

# SLA + scaffold check (this is the primary assertion)
assert_under_5_minutes

# Smoke-test error paths (mirrors the bats tests for quick local verification)
non_git="$(mktemp -d)"
assert_error_path \
  "E-INIT-001 non-git dir" \
  "E-INIT-001" \
  env BRAIN_ROOT="$non_git" CLAUDE_PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT" \
  bash "${PLUGIN_DIR}/skills/init/run.sh"
rm -rf "$non_git"

existing_brain="$(mktemp -d)"
git -C "$existing_brain" init -q
mkdir -p "${existing_brain}/.brain"
assert_error_path \
  "E-INIT-002 existing .brain/" \
  "E-INIT-002" \
  env BRAIN_ROOT="$existing_brain" CLAUDE_PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT" \
  bash "${PLUGIN_DIR}/skills/init/run.sh"
rm -rf "$existing_brain"

wiki_conflict="$(mktemp -d)"
git -C "$wiki_conflict" init -q
mkdir -p "${wiki_conflict}/wiki"
assert_error_path \
  "E-INIT-005 wiki/ conflict" \
  "E-INIT-005" \
  env BRAIN_ROOT="$wiki_conflict" CLAUDE_PLUGIN_ROOT="$CLAUDE_PLUGIN_ROOT" \
  bash "${PLUGIN_DIR}/skills/init/run.sh"
rm -rf "$wiki_conflict"

printf '\nAll local-dev-test assertions passed.\n'
