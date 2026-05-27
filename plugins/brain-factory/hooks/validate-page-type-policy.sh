#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'echo "Page type policy hook blocked: internal error." >&2; exit 2' ERR
# validate-page-type-policy.sh — PostToolUse hook: wiki page type directory enforcement
# BC-2.04.007 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — validates that wiki pages are placed in a
# canonical type subdirectory.
# Exit 0: allow (valid type, exempt path, or non-wiki path)
# Exit 2: block (invalid type, direct wiki root write, or fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>","message":"..."}
#   block → {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"<E-WIKI-NNN>","trace":"<uuid>",...}}

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-page-type-policy.sh" >&2
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":$trace}}'
  echo "Page type policy hook blocked: internal error." >&2
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload
# ---------------------------------------------------------------------------
stdin_json="$(cat)"

# Validate JSON is parseable — fail-closed on malformed or empty stdin.
if ! printf '%s' "$stdin_json" | jq empty 2>/dev/null; then
  jq -cn \
    --arg code "E-WIKI-003" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Page type policy hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract fields from the payload
# ---------------------------------------------------------------------------
file_path="$(printf '%s' "$stdin_json" | jq -r '.tool_input.file_path // empty')"
brain_dir="$(printf '%s' "$stdin_json" | jq -r '.cwd // empty')"
# BRAIN_DIR env var takes precedence (used in test environments and local invocation).
brain_dir="${BRAIN_DIR:-${brain_dir}}"

# Fail-closed if we cannot determine the file path.
if [[ -z "$file_path" ]]; then
  jq -cn \
    --arg code "E-WIKI-003" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Page type policy hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Path routing — only wiki/** is in scope for this hook.
# Non-wiki paths are a no-op (exit 0 immediately).
# ---------------------------------------------------------------------------
if [[ "$relative_path" != wiki/* ]]; then
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Non-wiki path; page type policy check skipped." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Exempt paths: wiki/index.md and wiki/log.md are special files, not typed
# pages. Bypass page-type enforcement for these two paths.
# ---------------------------------------------------------------------------
wiki_rel="${relative_path#wiki/}"
if [[ "$wiki_rel" == "index.md" ]] || [[ "$wiki_rel" == "log.md" ]]; then
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Exempt wiki path; page type policy skipped." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract the type directory — the first path segment after wiki/.
# E-WIKI-006: direct write to wiki/ root (depth-1 file, no subdirectory).
# ---------------------------------------------------------------------------
# wiki_rel is now the path relative to wiki/ (e.g. "concepts/ai-agents.md")
# If it has no slash, the file is directly in wiki/ root — that is forbidden.
if [[ "$wiki_rel" != */* ]]; then
  emit_event "wiki.page_type.rejected" "path=$file_path" "code=E-WIKI-006"
  jq -cn \
    --arg code "E-WIKI-006" \
    --arg msg "Wiki page must be in a type directory (wiki/<type>/). Direct writes to wiki/ root are not allowed." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Page type policy hook blocked: direct wiki root write is not allowed." >&2
  exit 2
fi

# Extract the type directory (first segment before the slash).
type_dir="${wiki_rel%%/*}"

# ---------------------------------------------------------------------------
# Validate the type directory against the canonical 6 types.
# E-WIKI-005: unrecognized type directory.
# ---------------------------------------------------------------------------
type_valid=false
case "$type_dir" in
concepts | people | frameworks | syntheses | observations | questions)
  type_valid=true
  ;;
esac

if [[ "$type_valid" != "true" ]]; then
  emit_event "wiki.page_type.rejected" "path=$file_path" "invalid_type=$type_dir"
  jq -cn \
    --arg code "E-WIKI-005" \
    --arg type_dir "$type_dir" \
    --arg path "$file_path" \
    --arg msg "Invalid wiki type directory '${type_dir}' in path ${file_path}. Must be one of: concepts, people, frameworks, syntheses, observations, questions." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace,"invalid_type":$type_dir}}'
  echo "Page type policy hook blocked: invalid wiki type '${type_dir}'." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Valid type — allow.
# ---------------------------------------------------------------------------
emit_event "wiki.page_type.accepted" "path=$file_path"
jq -cn --arg trace "${HOOK_TRACE_ID}" \
  --arg type_dir "$type_dir" \
  --arg msg "Wiki page type '${type_dir}' accepted." \
  '{"continue":true,"trace":$trace,"message":$msg}'
exit 0
