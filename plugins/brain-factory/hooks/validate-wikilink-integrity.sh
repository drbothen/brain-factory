#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf '"'"'{"ts":"%s","event_type":"hook.error.internal","hook_name":"validate-wikilink-integrity.sh","trace":"%s","code":"E-HOOK-003","reason":"unhandled error"}\n'"'"' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" >&2; exit 2' ERR
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
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract fields in a single jq call.
# Extracts file_path, cwd, and content together (performance: one subprocess
# vs four; malformed JSON → empty → fail-closed).
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
# Extract all three fields with pure bash _json_get_str (zero subprocesses).
# content is JSON-encoded (\\n for newlines); decode with pure bash below.
file_path="$(_json_get_str "$stdin_json" 'file_path')"
_cwd_raw="$(_json_get_str "$stdin_json" 'cwd')"
_content_raw="$(_json_get_str "$stdin_json" 'content')"
# Decode JSON string escapes (pure bash, no subprocess). Order: \\ first.
_content_tmp="${_content_raw//\\\\/\\}"
_content_tmp="${_content_tmp//\\n/
}"
_content_tmp="${_content_tmp//\\t/	}"
_content_tmp="${_content_tmp//\\\"/\"}"
# BRAIN_DIR env var takes precedence (used in test environments and local invocation).
brain_dir="${BRAIN_DIR:-${_cwd_raw}}"

# Fail-closed if we cannot determine the brain directory or file path.
# This also catches malformed/empty stdin (jq failure leaves file_path empty).
if [[ -z "$file_path" ]] || [[ -z "$brain_dir" ]]; then
  emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=malformed or empty hook payload"
  printf '{"continue":false,"decision":"block","code":"E-HOOK-001","reason":"Malformed or empty hook payload.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-001","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Use content from payload (Write provides it); fall back to reading from disk
# (Edit may not have full content in payload).
# ---------------------------------------------------------------------------
content="$_content_tmp"
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
  printf '{"continue":true,"trace":"%s","message":"Non-wiki path; wikilink check skipped."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract all [[slug]] wikilinks from content (portable BSD grep, no -P flag).
# ---------------------------------------------------------------------------
slugs="$(printf '%s' "$content" | grep -o '\[\[[^]]*\]\]' | sed 's/^\[\[//;s/\]\]$//' || true)"

# No wikilinks → vacuously valid.
if [[ -z "$slugs" ]]; then
  emit_event "wiki.wikilink.validated" "path=${relative_path}" "slug_count=0"
  printf '{"continue":true,"trace":"%s","message":"All wikilinks valid."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Verify wiki/index.md exists and is readable — fail-closed (E-WIKI-002).
# ---------------------------------------------------------------------------
index_file="${brain_dir}/wiki/index.md"
if [[ ! -r "$index_file" ]]; then
  emit_event "wiki.wikilink.check_failed" "code=E-WIKI-002" "reason=wiki/index.md not found"
  printf '{"continue":false,"decision":"block","reason":"wiki/index.md not found — cannot verify wikilinks.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-WIKI-002","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Check each slug against wiki/index.md — collect broken slugs into array.
# A slug matches if wiki/index.md contains /${slug}.md as a path component.
# ---------------------------------------------------------------------------
broken_arr=()
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  # Use -F (fixed string) and match the slug as a complete path component to
  # avoid regex metacharacter issues and substring false-positives (F-002).
  if ! grep -Fq "/${slug}.md" "${index_file}"; then
    broken_arr+=("${slug}")
  fi
done <<<"$slugs"

# ---------------------------------------------------------------------------
# Build broken_slugs JSON array and display string (pure bash — no jq subprocess).
# BC-2.04.003 requires array, not string — F-005.
# ---------------------------------------------------------------------------
broken_json="["
broken_display=""
_bfirst=true
for _bslug in "${broken_arr[@]+"${broken_arr[@]}"}"; do
  _besc="$(_json_escape "${_bslug}")"
  if [[ "$_bfirst" == "true" ]]; then
    broken_json="${broken_json}\"${_besc}\""
    broken_display="[[${_bslug}]]"
    _bfirst=false
  else
    broken_json="${broken_json},\"${_besc}\""
    broken_display="${broken_display}, [[${_bslug}]]"
  fi
done
broken_json="${broken_json}]"

# ---------------------------------------------------------------------------
# Emit result.
# ---------------------------------------------------------------------------
if [[ "${#broken_arr[@]}" -gt 0 ]]; then
  emit_event "wiki.wikilink.broken" "broken_slugs=${broken_display}" "path=${relative_path}"
  _em_reason="$(_json_escape "Broken wikilink(s): ${broken_display} in ${relative_path}. No matching wiki page found.")"
  printf '{"continue":false,"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-WIKI-001","trace":"%s","details":{"broken_slugs":%s}}}\n' \
    "${_em_reason}" "${HOOK_TRACE_ID}" "${broken_json}"
  exit 2
fi

_validated_count="$(printf '%s\n' "$slugs" | grep -c . || true)"
emit_event "wiki.wikilink.validated" "path=${relative_path}" "slug_count=${_validated_count}"
printf '{"continue":true,"trace":"%s","message":"All wikilinks valid."}\n' \
  "${HOOK_TRACE_ID}"
exit 0
