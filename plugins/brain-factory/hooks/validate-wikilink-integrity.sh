#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'echo "Wikilink integrity hook blocked: internal error." >&2; exit 2' ERR
# validate-wikilink-integrity.sh — PostToolUse hook: wikilink integrity enforcement
# BC-2.04.003 | VP-004 | VP-002 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — checks [[slug]] wikilinks against wiki/index.md.
# Exit 0: allow (all slugs resolve, no wikilinks, or non-wiki path)
# Exit 2: block (broken slug found, missing index, or fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>","message":"..."}
#   block → {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"<E-NNN>","trace":"<uuid>"}}
#          + human-readable message on stderr

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-wikilink-integrity.sh" >&2
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":$trace}}'
  echo "Wikilink integrity hook blocked: internal error." >&2
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
    --arg code "E-WIKI-002" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Wikilink integrity hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract fields from the payload
# ---------------------------------------------------------------------------
file_path="$(printf '%s' "$stdin_json" | jq -r '.tool_input.file_path // empty')"
brain_dir="$(printf '%s' "$stdin_json" | jq -r '.cwd // empty')"
# BRAIN_DIR env var takes precedence (used in test environments and local invocation).
brain_dir="${BRAIN_DIR:-${brain_dir}}"

# Fail-closed if we cannot determine the brain directory or file path.
if [[ -z "$file_path" ]] || [[ -z "$brain_dir" ]]; then
  emit_event "wiki.wikilink.check_failed" "code=E-WIKI-002" "reason=missing file_path or brain_dir in payload"
  jq -cn \
    --arg code "E-WIKI-002" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Wikilink integrity hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract content from payload (Write provides content in tool_input.content;
# Edit may not have full content — read from disk as fallback).
# ---------------------------------------------------------------------------
content="$(printf '%s' "$stdin_json" | jq -r '.tool_input.content // empty')"
if [[ -z "$content" ]] && [[ -f "$file_path" ]]; then
  content="$(cat "$file_path")"
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Early exit for non-wiki paths — this hook only validates wiki/** files.
# BC-2.04.003 precondition 1: only fires for Write|Edit on wiki/** paths.
# ---------------------------------------------------------------------------
if [[ "$relative_path" != wiki/* ]]; then
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Non-wiki path; wikilink check skipped." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract all [[slug]] wikilinks from content (portable BSD grep, no -P flag).
# ---------------------------------------------------------------------------
slugs="$(printf '%s' "$content" | grep -o '\[\[[^]]*\]\]' | sed 's/^\[\[//;s/\]\]$//' || true)"

# No wikilinks → vacuously valid.
if [[ -z "$slugs" ]]; then
  emit_event "wiki.wikilink.validated" "path=${relative_path}" "slug_count=0"
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "All wikilinks valid." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Verify wiki/index.md exists and is readable — fail-closed (E-WIKI-002).
# ---------------------------------------------------------------------------
index_file="${brain_dir}/wiki/index.md"
if [[ ! -r "$index_file" ]]; then
  emit_event "wiki.wikilink.check_failed" "code=E-WIKI-002" "reason=wiki/index.md not found"
  jq -cn \
    --arg code "E-WIKI-002" \
    --arg msg "wiki/index.md not found — cannot verify wikilinks." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Wikilink integrity hook blocked: wiki/index.md not found at ${index_file}." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Check each slug against wiki/index.md — collect broken slugs.
# A slug matches if wiki/index.md contains that slug string (as part of a path).
# ---------------------------------------------------------------------------
broken=""
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  if ! grep -q "${slug}" "${index_file}"; then
    broken="${broken:+${broken}, }[[${slug}]]"
  fi
done <<<"$slugs"

# ---------------------------------------------------------------------------
# Emit result.
# ---------------------------------------------------------------------------
if [[ -n "$broken" ]]; then
  emit_event "wiki.wikilink.broken" "broken_slugs=${broken}" "path=${relative_path}"
  jq -cn \
    --arg code "E-WIKI-001" \
    --arg reason "Broken wikilink(s): ${broken} in ${relative_path}. No matching wiki page found." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$reason,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Wikilink integrity hook blocked: Broken wikilink(s): ${broken} in ${relative_path}." >&2
  exit 2
fi

emit_event "wiki.wikilink.validated" "path=${relative_path}"
jq -cn --arg trace "${HOOK_TRACE_ID}" \
  --arg msg "All wikilinks valid." \
  '{"continue":true,"trace":$trace,"message":$msg}'
exit 0
