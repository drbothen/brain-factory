#!/usr/bin/env bash
set -euo pipefail
# ADVISORY-ONLY trap: any unhandled error exits 0 (safe fallback, never block).
# BC-2.04.008 invariant: this hook is purely advisory — it always exits with code 0.
trap 'printf "%s\n" "{\"continue\":true}" ; exit 0' ERR
# validate-voice-avoid-list.sh — PostToolUse hook: voice avoid-list advisory
# BC-2.04.008 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — scans briefs/content/*-draft.md for voice
# avoid-list terms. Advisory only: always exits 0 regardless of findings.
# Exit 0 always (advisory): stdout contains continue:true in all cases.
# stdout protocol (ADR-002 v2.0):
#   no match  → {"continue":true}
#   match     → {"continue":true,"systemMessage":"Voice avoid-list terms found: <list>",
#                "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-VOICE-001","matches":[...]}}
#   no list   → {"continue":true,"systemMessage":"...",
#                "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-VOICE-002"}}
#   error     → {"continue":true}  (safe fallback — never blocks)

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"
AVOID_LIST="${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt"

# ---------------------------------------------------------------------------
# Source the event-emit helper (advisory fallback if missing — never block).
# Events are best-effort; absence of the helper does not prevent the advisory.
# ---------------------------------------------------------------------------
_helper_loaded=false
if [ -f "$HELPER" ]; then
  # shellcheck disable=SC1090,SC1091
  source "$HELPER" && _helper_loaded=true
fi

if [[ "$_helper_loaded" == "false" ]]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-voice-avoid-list.sh" >&2
fi

# Provide a no-op emit_event when helper did not load.
if ! declare -f emit_event >/dev/null 2>&1; then
  emit_event() { :; }
fi

# ---------------------------------------------------------------------------
# Check if the avoid-list file exists and is readable.
# Advisory response with E-VOICE-002 if missing (never block).
# Checked early so tests with a fake plugin root without a helper still get
# E-VOICE-002 rather than a silent fallback.
# ---------------------------------------------------------------------------
if [[ ! -f "$AVOID_LIST" ]] || [[ ! -r "$AVOID_LIST" ]]; then
  emit_event "voice.avoid_list.skipped" "reason=avoid_list_not_found" "path=$AVOID_LIST"
  jq -cn \
    '{"continue":true,"systemMessage":"Voice avoid-list not found; advisory skipped.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-VOICE-002"}}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract file_path using pure bash _json_get_str
# (no subprocess). Advisory fallback on malformed input — never block.
# Malformed/empty JSON → file_path empty → skip.
# ---------------------------------------------------------------------------
stdin_json="$(cat)" || true
file_path="$(_json_get_str "$stdin_json" 'file_path')"

if [[ -z "$file_path" ]]; then
  emit_event "voice.avoid_list.skipped" "reason=malformed_or_missing_file_path"
  printf '%s\n' '{"continue":true}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Read the file content from disk.
# Advisory fallback if the file cannot be read.
# ---------------------------------------------------------------------------
if [[ ! -f "$file_path" ]] || [[ ! -r "$file_path" ]]; then
  emit_event "voice.avoid_list.skipped" "reason=target_file_unreadable" "path=$file_path"
  printf '%s\n' '{"continue":true}'
  exit 0
fi

file_content="$(cat "$file_path")" || true

# ---------------------------------------------------------------------------
# Scan for avoid-list matches (case-insensitive, fixed-string).
# Collect unique matching terms.
# ---------------------------------------------------------------------------
matched_terms=()

while IFS= read -r term || [[ -n "$term" ]]; do
  # Skip blank lines.
  [[ -z "$term" ]] && continue
  # grep -iFc: case-insensitive fixed-string count match.
  match_count="$(printf '%s' "$file_content" | grep -iFc "$term" 2>/dev/null || true)"
  if [[ "$match_count" -gt 0 ]]; then
    matched_terms+=("$term")
  fi
done <"$AVOID_LIST"

# ---------------------------------------------------------------------------
# Emit result based on whether matches were found.
# ---------------------------------------------------------------------------
if [[ "${#matched_terms[@]}" -eq 0 ]]; then
  emit_event "voice.avoid_list.passed" "path=$file_path"
  printf '%s\n' '{"continue":true}'
  exit 0
fi

# Build the JSON matches array and display string from matched_terms.
# Pure bash array construction — no jq subprocess needed.
matches_json="["
matches_display=""
_mfirst=true
for _mt in "${matched_terms[@]}"; do
  _esc="$(_json_escape "${_mt}")"
  if [[ "$_mfirst" == "true" ]]; then
    matches_json="${matches_json}\"${_esc}\""
    matches_display="${_mt}"
    _mfirst=false
  else
    matches_json="${matches_json},\"${_esc}\""
    matches_display="${matches_display}, ${_mt}"
  fi
done
matches_json="${matches_json}]"

emit_event "voice.avoid_list.matched" "path=$file_path" "match_count=${#matched_terms[@]}"

_em_msg="$(_json_escape "Voice avoid-list terms found: ${matches_display}")"
printf '{"continue":true,"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-VOICE-001","matches":%s}}\n' \
  "${_em_msg}" "${matches_json}"
exit 0
