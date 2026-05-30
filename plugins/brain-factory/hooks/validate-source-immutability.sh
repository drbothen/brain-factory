#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf '"'"'{"ts":"%s","event_type":"hook.error.internal","hook_name":"validate-source-immutability.sh","trace":"%s","code":"E-HOOK-003","reason":"unhandled error"}\n'"'"' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" >&2; exit 2' ERR
# validate-source-immutability.sh — PostToolUse hook: source immutability enforcement
# BC-2.04.002 | VP-003 | ADR-002 v2.0 | ADR-015 (manifest schema) | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — checks .brain/manifest.json to block overwriting existing sources.
# Exit 0: allow (new source or non-source path) | Exit 2: block (existing source or fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>"}
#   block → {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"<E-NNN>","trace":"<uuid>"}}
#          + human-readable message on stderr

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-source-immutability.sh" >&2
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract fields in a single jq call.
# (performance: one subprocess vs three; malformed JSON → empty → fail-closed).
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
file_path="$(_json_get_str "$stdin_json" 'file_path')"
_cwd_raw="$(_json_get_str "$stdin_json" 'cwd')"
# BRAIN_DIR env var takes precedence (used in test environments and local invocation).
brain_dir="${BRAIN_DIR:-${_cwd_raw}}"

# Fail-closed if we cannot determine the brain directory or file path.
# This also catches malformed/empty stdin (jq failure leaves file_path empty).
if [[ -z "$file_path" ]] || [[ -z "$brain_dir" ]]; then
  emit_event "hook.input.invalid" "code=E-HOOK-001" "reason=malformed or empty hook payload"
  printf '{"continue":false,"decision":"block","reason":"Malformed or empty hook payload.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SOURCE-003","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ADR-015: manifest keys are relative paths (e.g. "sources/ai/article.md").
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Early exit for non-source paths — this hook only protects sources/**
# BC-2.04.002 precondition 1: only fires for Write|Edit on sources/** paths.
# ---------------------------------------------------------------------------
if [[ "$relative_path" != sources/* ]]; then
  printf '{"continue":true,"trace":"%s"}\n' "${HOOK_TRACE_ID}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Check that .brain/manifest.json exists and is readable — fail-closed.
# EC-003: missing manifest → E-SOURCE-002.
# ---------------------------------------------------------------------------
manifest="${brain_dir}/.brain/manifest.json"
if [[ ! -r "$manifest" ]]; then
  emit_event "source.immutability.check_failed" "code=E-SOURCE-002" "reason=manifest not found"
  printf '{"continue":false,"decision":"block","reason":"Manifest not found — cannot verify source immutability.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SOURCE-002","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# Check manifest is valid JSON (fail-closed on malformed) — EC-003 covers both missing and malformed.
if ! jq empty "$manifest" 2>/dev/null; then
  emit_event "source.immutability.check_failed" "code=E-SOURCE-002" "reason=manifest malformed"
  printf '{"continue":false,"decision":"block","reason":"Manifest malformed — cannot verify source immutability.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SOURCE-002","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Manifest lookup — check whether the relative path is registered.
# ADR-015: non-null .sources[$path] means the source already exists.
# ---------------------------------------------------------------------------
existing="$(jq -r --arg path "$relative_path" '.sources[$path] // ""' "$manifest" 2>/dev/null || true)"

if [[ -n "$existing" ]]; then
  # Existing source — block the overwrite (immutability violation).
  emit_event "source.immutability.violated" "path=${relative_path}" "code=E-SOURCE-001"
  _em_path="$(_json_escape "${relative_path}")"
  printf '{"continue":false,"decision":"block","reason":"Source file %s already exists in manifest. Sources are immutable. Use /brain:rename-page to rename.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SOURCE-001","trace":"%s"}}\n' \
    "${_em_path}" "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# New source — allow the write.
# ---------------------------------------------------------------------------
emit_event "source.added" "path=${relative_path}"
printf '{"continue":true,"trace":"%s","message":"New source accepted."}\n' "${HOOK_TRACE_ID}"
exit 0
