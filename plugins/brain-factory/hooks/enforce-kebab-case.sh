#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf '"'"'{"ts":"%s","event_type":"hook.error.internal","hook_name":"enforce-kebab-case.sh","trace":"%s","code":"E-HOOK-003","reason":"unhandled error"}\n'"'"' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" >&2; exit 2' ERR
# enforce-kebab-case.sh — PreToolUse hook: filename kebab-case naming gate
# BC-2.04.011 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires BEFORE Write|Edit executes — validates that the target filename is
# kebab-case (or is on the exception list for uppercase-convention files).
# Exit 0: allow (valid kebab-case filename or exception list match)
# Exit 2: block (non-kebab-case filename, or fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>","message":"..."}
#   block → {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-NAMING-001","trace":"<uuid>","filename":"<name>","suggested":"<suggested>"}}

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "enforce-kebab-case.sh" >&2
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract file_path using pure bash _json_get_str
# (no subprocess — zero jq calls). file_path is a simple quoted string.
# Malformed/empty stdin → file_path is empty → fail-closed below.
# BC-2.04.016 invariant 4: canonical empty/malformed-stdin code is E-HOOK-001.
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
file_path="$(_json_get_str "$stdin_json" 'file_path')"

# Fail-closed if we cannot determine the file path.
# This also catches malformed/empty stdin (jq failure leaves file_path empty).
if [[ -z "$file_path" ]]; then
  emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=malformed or empty hook payload"
  printf '{"continue":false,"decision":"block","code":"E-HOOK-001","reason":"Malformed or empty hook payload.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-HOOK-001","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract basename only — the naming rule applies to the filename, not the path.
# ---------------------------------------------------------------------------
basename_val="${file_path##*/}"

# ---------------------------------------------------------------------------
# Exception list — uppercase-convention files exempt from kebab-case check.
# Exception list operates on basenames per BC-2.04.011 precondition 3 (basename-only check).
# BC invariant 3 lists .brain/STATE.md and .brain/manifest.json with path context,
# but the hook exempts STATE.md and manifest.json in any directory since it only sees basenames.
# This is intentional — the hook's scope is filename validation, not path validation.
# ---------------------------------------------------------------------------
is_exempt=false
case "$basename_val" in
CLAUDE.md | README.md | CHANGELOG.md | MANIFEST.md | LICENSE | STATE.md | manifest.json)
  is_exempt=true
  ;;
esac

if [[ "$is_exempt" == "true" ]]; then
  emit_event "naming.kebab_case.accepted" "filename=${basename_val}"
  _em_bn="$(_json_escape "${basename_val}")"
  printf '{"continue":true,"trace":"%s","message":"Filename '\''%s'\'' is on the exception list."}\n' \
    "${HOOK_TRACE_ID}" "${_em_bn}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Validate basename against kebab-case regex.
# Accepted forms:
#   - kebab-case: ^[a-z0-9][a-z0-9-]*(\.[a-z0-9]+)?$
#   - dotfiles:   ^\.[a-z0-9][a-z0-9-]*$
# ---------------------------------------------------------------------------
is_kebab=false
if [[ "$basename_val" =~ ^[a-z0-9][a-z0-9-]*(\.[a-z0-9]+)?$ ]]; then
  is_kebab=true
elif [[ "$basename_val" =~ ^\.[a-z0-9][a-z0-9-]*$ ]]; then
  is_kebab=true
fi

if [[ "$is_kebab" == "true" ]]; then
  emit_event "naming.kebab_case.accepted" "filename=${basename_val}"
  _em_bn="$(_json_escape "${basename_val}")"
  printf '{"continue":true,"trace":"%s","message":"Filename '\''%s'\'' is kebab-case."}\n' \
    "${HOOK_TRACE_ID}" "${_em_bn}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Non-conforming filename — derive suggestion and block.
# Suggestion: lowercase + replace spaces with hyphens + replace underscores with hyphens.
# ---------------------------------------------------------------------------
# Use tr for the transformation — portable and safe.
suggested="$(printf '%s' "$basename_val" | tr '[:upper:]' '[:lower:]' | tr ' _' '-')"

emit_event "naming.kebab_case.rejected" "filename=${basename_val}" "suggested=${suggested}"
_em_fn="$(_json_escape "${basename_val}")"
_em_sg="$(_json_escape "${suggested}")"
printf '{"continue":false,"decision":"block","reason":"Filename %s is not kebab-case. Suggested: %s.","hookSpecificOutput":{"hookEventName":"PreToolUse","code":"E-NAMING-001","trace":"%s","filename":"%s","suggested":"%s"}}\n' \
  "${_em_fn}" "${_em_sg}" "${HOOK_TRACE_ID}" "${_em_fn}" "${_em_sg}"
exit 2
