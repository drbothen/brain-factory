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
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract file_path + cwd using pure bash
# _json_get_str (no subprocess — zero jq calls for simple string fields).
# Both fields are simple quoted strings; _json_get_str is safe here.
# Malformed/empty stdin → file_path and cwd are empty → fail-closed below.
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
file_path="$(_json_get_str "$stdin_json" 'file_path')"
_cwd_raw="$(_json_get_str "$stdin_json" 'cwd')"
# BRAIN_DIR env var takes precedence (used in test environments and local invocation).
brain_dir="${BRAIN_DIR:-${_cwd_raw}}"

# Fail-closed if we cannot determine the file path.
# This also catches malformed/empty stdin (jq failure leaves file_path empty).
if [[ -z "$file_path" ]]; then
  printf '{"continue":false,"decision":"block","reason":"Malformed or empty hook payload.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-WIKI-003","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
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
  printf '{"continue":true,"trace":"%s","message":"Non-wiki path; page type policy check skipped."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Exempt paths: wiki/index.md and wiki/log.md are special files, not typed
# pages. Bypass page-type enforcement for these two paths.
# ---------------------------------------------------------------------------
wiki_rel="${relative_path#wiki/}"
if [[ "$wiki_rel" == "index.md" ]] || [[ "$wiki_rel" == "log.md" ]]; then
  printf '{"continue":true,"trace":"%s","message":"Exempt wiki path; page type policy skipped."}\n' \
    "${HOOK_TRACE_ID}"
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
  printf '{"continue":false,"decision":"block","reason":"Wiki page must be in a type directory (wiki/<type>/). Direct writes to wiki/ root are not allowed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-WIKI-006","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
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
  emit_event "wiki.page_type.rejected" "path=$file_path" "code=E-WIKI-005" "invalid_type=$type_dir"
  _em_td="$(_json_escape "${type_dir}")"
  _em_fp="$(_json_escape "${file_path}")"
  printf '{"continue":false,"decision":"block","reason":"Invalid wiki type directory '\''%s'\'' in path %s. Must be one of: concepts, people, frameworks, syntheses, observations, questions.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-WIKI-005","trace":"%s","invalid_type":"%s"}}\n' \
    "${_em_td}" "${_em_fp}" "${HOOK_TRACE_ID}" "${_em_td}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Valid type — allow.
# ---------------------------------------------------------------------------
emit_event "wiki.page_type.accepted" "path=$file_path"
_em_td="$(_json_escape "${type_dir}")"
printf '{"continue":true,"trace":"%s","message":"Wiki page type '\''%s'\'' accepted."}\n' \
  "${HOOK_TRACE_ID}" "${_em_td}"
exit 0
