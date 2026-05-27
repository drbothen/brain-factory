#!/usr/bin/env bash
set -euo pipefail
# brain-health-check.sh — SessionStart lifecycle hook: brain health banner
# BC-2.04.014 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires on the SessionStart event. Reads .brain/STATE.md frontmatter and
# emits a health banner. Advisory only on unhealthy state — NEVER exits 2.
# Exit codes:
#   0 — success (GREEN or not a brain session)
#   1 — advisory (RED/YELLOW state or unreadable STATE.md — session still opens)

# ADVISORY ERR trap: unhandled errors exit 0 so session open is never blocked.
trap 'printf "%s\n" "{\"continue\":true,\"systemMessage\":\"Health check encountered an error.\"}" ; exit 0' ERR

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# Source event-emit helper (advisory fallback if missing — never block).
_helper_loaded=false
if [ -f "$HELPER" ]; then
  # shellcheck disable=SC1090,SC1091
  source "$HELPER" && _helper_loaded=true
fi

if [[ "$_helper_loaded" == "false" ]]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "brain-health-check.sh" >&2
fi

# Provide a no-op emit_event when helper did not load.
if ! declare -f emit_event >/dev/null 2>&1; then
  emit_event() { :; }
fi

# ---------------------------------------------------------------------------
# Read stdin JSON payload.
# ---------------------------------------------------------------------------
stdin_json="$(cat)" || true

# ---------------------------------------------------------------------------
# Determine brain directory: prefer BRAIN_DIR env, fall back to cwd in payload.
# ---------------------------------------------------------------------------
brain_dir="${BRAIN_DIR:-$(printf '%s' "$stdin_json" | jq -r '.cwd // empty' 2>/dev/null || true)}"

# ---------------------------------------------------------------------------
# Check if this is a brain session (has .brain/STATE.md).
# EC-001: not a brain session → exit 0 silently.
# ---------------------------------------------------------------------------
state_file="${brain_dir}/.brain/STATE.md"

if [[ ! -f "$state_file" ]]; then
  emit_event "brain.health.skipped" "reason=not_a_brain_session"
  jq -cn --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"trace":$trace,"message":"Not a brain session."}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract YAML frontmatter from STATE.md using awk.
# ---------------------------------------------------------------------------
frontmatter="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$state_file")" || true

# ---------------------------------------------------------------------------
# Parse overall_health from frontmatter.
# Prefer yq (mikefarah/yq) using direct expression syntax (no subcommand).
# Fall back to grep only when yq is not available.
# If yq is available and returns empty, the YAML is malformed → UNREADABLE.
# ---------------------------------------------------------------------------
overall_health=""
_yq_available=false

if command -v yq >/dev/null 2>&1; then
  _yq_available=true
  overall_health="$(printf '%s' "$frontmatter" | yq '.overall_health // ""' - 2>/dev/null)" || overall_health=""
fi

if [[ "$_yq_available" == "false" ]]; then
  # yq not available — grep fallback (best-effort; malformed values pass through).
  overall_health="$(printf '%s' "$frontmatter" | grep '^overall_health:' | sed 's/.*: *//' | tr -d '[:space:]')" || overall_health=""
fi

# ---------------------------------------------------------------------------
# Handle unreadable / unparseable STATE.md.
# An empty result from yq means the YAML was malformed or key is missing.
# ---------------------------------------------------------------------------
if [[ -z "$overall_health" ]] || [[ "$overall_health" == "null" ]]; then
  emit_event "brain.health.checked" "overall_state=UNREADABLE"
  jq -cn --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"systemMessage":"Brain STATE.md unreadable — run /brain:health for diagnosis.","hookSpecificOutput":{"hookEventName":"SessionStart","code":"E-HEALTH-003","trace":$trace,"overall_state":"UNREADABLE"}}'
  exit 1
fi

# ---------------------------------------------------------------------------
# GREEN — all healthy.
# ---------------------------------------------------------------------------
if [[ "$overall_health" == "GREEN" ]]; then
  emit_event "brain.health.checked" "overall_state=GREEN"
  jq -cn --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
    '{"continue":true,"trace":$trace,"message":"Brain health: GREEN. All dimensions healthy."}'
  exit 0
fi

# ---------------------------------------------------------------------------
# RED or YELLOW — emit advisory with dimension summary.
# ---------------------------------------------------------------------------
issues_summary=""
dims_csv=""

if command -v yq >/dev/null 2>&1; then
  # Extract red_dimensions as a compact summary (key: value pairs).
  issues_summary="$(printf '%s' "$frontmatter" | yq '.red_dimensions // [] | .[] | to_entries | .[] | (.key + " (" + .value + ")")' - 2>/dev/null | tr '\n' ';' | sed 's/;$//;s/;/, /g')" || issues_summary=""
  # Build dims_csv: comma-separated list of RED/YELLOW dimension names.
  dims_csv="$(printf '%s' "$frontmatter" | yq '.red_dimensions // [] | .[] | keys | .[0]' - 2>/dev/null | tr '\n' ',' | sed 's/,$//')" || dims_csv=""
fi

if [[ -z "$issues_summary" ]]; then
  # Fallback: list non-GREEN dimensions from the dimensions map.
  issues_summary="$(printf '%s' "$frontmatter" | grep -E '^\s+[a-z]+:' | grep -v 'GREEN' | awk '{print $1}' | tr -d ':' | tr '\n' ',' | sed 's/,$//' | sed 's/,/, /g')" || issues_summary=""
fi

if [[ -z "$dims_csv" ]] && [[ -n "$issues_summary" ]]; then
  # Fallback dims_csv from issues_summary if yq path above yielded nothing.
  dims_csv="$(printf '%s' "$frontmatter" | grep -E '^\s+[a-z]+:' | grep -v 'GREEN' | awk '{print $1}' | tr -d ':' | tr '\n' ',' | sed 's/,$//')" || dims_csv=""
fi

issue_msg="Brain health: ${overall_health}."
if [[ -n "$issues_summary" ]]; then
  issue_msg="Brain health: ${overall_health}. Issues: ${issues_summary}"
fi

emit_event "brain.health.checked" "overall_state=${overall_health}" "red_dimensions=${dims_csv}"
jq -cn \
  --arg msg "$issue_msg" \
  --arg state "$overall_health" \
  --arg trace "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" \
  '{"continue":true,"systemMessage":$msg,"hookSpecificOutput":{"hookEventName":"SessionStart","code":"E-HEALTH-002","trace":$trace,"overall_state":$state}}'
exit 1
