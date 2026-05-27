#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'echo "Index-log coherence hook blocked: internal error." >&2; exit 2' ERR
# validate-index-log-coherence.sh — PostToolUse hook: wiki index/log coherence
# BC-2.04.006 | VP-002 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — bidirectional check:
#   1. Every slug in wiki/index.md must appear in wiki/log.md (index→log)
#   2. Every slug in wiki/log.md must appear in wiki/index.md (log→index)
# Exit 0: allow (all slugs coherent, non-target path, or vacuous coherence)
# Exit 2: block (missing slug in either direction, missing file, or fail-closed on error)
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
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-index-log-coherence.sh" >&2
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":$trace}}'
  echo "Index-log coherence hook blocked: internal error." >&2
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
    --arg code "E-WIKI-004" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Index-log coherence hook blocked: malformed or empty hook payload." >&2
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
  emit_event "wiki.index_log.check_failed" "code=E-WIKI-004" "reason=missing file_path or brain_dir in payload"
  jq -cn \
    --arg code "E-WIKI-004" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Index-log coherence hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Early exit for paths other than wiki/index.md or wiki/log.md.
# BC-2.04.006 precondition 1: only fires when index or log is written.
# ---------------------------------------------------------------------------
if [[ "$relative_path" != "wiki/index.md" ]] && [[ "$relative_path" != "wiki/log.md" ]]; then
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Non-index/log path; coherence check skipped." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Both wiki/index.md and wiki/log.md must be readable — fail-closed (E-WIKI-004).
# ---------------------------------------------------------------------------
index_file="${brain_dir}/wiki/index.md"
log_file="${brain_dir}/wiki/log.md"

if [[ ! -r "$index_file" ]] || [[ ! -r "$log_file" ]]; then
  emit_event "wiki.index_log.check_failed" "code=E-WIKI-004" "reason=wiki/index.md or wiki/log.md not found"
  jq -cn \
    --arg code "E-WIKI-004" \
    --arg msg "wiki/index.md or wiki/log.md not found — cannot verify coherence." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Index-log coherence hook blocked: wiki/index.md or wiki/log.md not readable." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract slugs from wiki/index.md — parse markdown links [Title](path.md)
# and extract the basename (filename without extension).
# Portable: no grep -P; uses grep -o + sed.
# ---------------------------------------------------------------------------
index_slugs="$(grep -o '\[[^]]*\]([^)]*\.md)' "${index_file}" | sed 's/.*(\(.*\)\.md)/\1/' | sed 's|.*/||' || true)"

# ---------------------------------------------------------------------------
# Extract slugs from wiki/log.md — same pattern.
# ---------------------------------------------------------------------------
log_slugs="$(grep -o '\[[^]]*\]([^)]*\.md)' "${log_file}" | sed 's/.*(\(.*\)\.md)/\1/' | sed 's|.*/||' || true)"

# Both empty — vacuously coherent.
if [[ -z "$index_slugs" ]] && [[ -z "$log_slugs" ]]; then
  emit_event "wiki.index_log.coherence_verified" "path=${relative_path}" "slug_count=0"
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Index-log coherence verified." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Direction 1: check each index slug appears in wiki/log.md.
# Use -F (fixed string) and match as complete path component (F-002).
# ---------------------------------------------------------------------------
missing=""
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  if ! grep -Fq "/${slug}.md" "${log_file}"; then
    missing="${missing:+${missing}, }${slug}"
  fi
done <<<"$index_slugs"

# ---------------------------------------------------------------------------
# Direction 2: check each log slug appears in wiki/index.md (F-001).
# BC-2.04.006 "and vice versa" — log-only slugs are E-WIKI-003 violations.
# ---------------------------------------------------------------------------
log_only=""
while IFS= read -r slug; do
  [[ -z "$slug" ]] && continue
  if ! grep -Fq "/${slug}.md" "${index_file}"; then
    log_only="${log_only:+${log_only}, }${slug}"
  fi
done <<<"$log_slugs"

# Combine all missing slugs for the violation report.
all_missing=""
[[ -n "$missing" ]] && all_missing="${missing}"
if [[ -n "$log_only" ]]; then
  all_missing="${all_missing:+${all_missing}, }${log_only}"
fi

# ---------------------------------------------------------------------------
# Emit result.
# ---------------------------------------------------------------------------
if [[ -n "$all_missing" ]]; then
  emit_event "wiki.index_log.coherence_violated" "missing_slugs=${all_missing}" "path=${relative_path}"
  jq -cn \
    --arg code "E-WIKI-003" \
    --arg reason "Index-log coherence violation: slug(s) missing from counterpart file: ${all_missing}." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$reason,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Index-log coherence hook blocked: slug(s) missing from counterpart file: ${all_missing}." >&2
  exit 2
fi

emit_event "wiki.index_log.coherence_verified" "path=${relative_path}"
jq -cn --arg trace "${HOOK_TRACE_ID}" \
  --arg msg "Index-log coherence verified." \
  '{"continue":true,"trace":$trace,"message":$msg}'
exit 0
