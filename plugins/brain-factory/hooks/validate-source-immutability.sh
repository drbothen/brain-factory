#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'echo "Source immutability hook blocked: internal error." >&2; exit 2' ERR
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
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":$trace}}'
  echo "Source immutability hook blocked: internal error." >&2
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
    --arg code "E-SOURCE-003" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source immutability hook blocked: malformed or empty hook payload." >&2
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
  emit_event "source.immutability.check_failed" "code=E-SOURCE-003" "reason=missing file_path or brain_dir in payload"
  jq -cn \
    --arg code "E-SOURCE-003" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source immutability hook blocked: malformed or empty hook payload." >&2
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
  jq -cn --arg trace "${HOOK_TRACE_ID}" '{"continue":true,"trace":$trace}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Check that .brain/manifest.json exists and is readable — fail-closed.
# EC-003: missing manifest → E-SOURCE-002.
# ---------------------------------------------------------------------------
manifest="${brain_dir}/.brain/manifest.json"
if [[ ! -r "$manifest" ]]; then
  emit_event "source.immutability.check_failed" "code=E-SOURCE-002" "reason=manifest not found"
  jq -cn \
    --arg code "E-SOURCE-002" \
    --arg msg "Manifest not found — cannot verify source immutability." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source immutability hook blocked: manifest not found at ${manifest}. Cannot verify source immutability." >&2
  exit 2
fi

# Check manifest is valid JSON (fail-closed on malformed) — EC-003 covers both missing and malformed.
if ! jq empty "$manifest" 2>/dev/null; then
  emit_event "source.immutability.check_failed" "code=E-SOURCE-002" "reason=manifest malformed"
  jq -cn \
    --arg code "E-SOURCE-002" \
    --arg msg "Manifest malformed — cannot verify source immutability." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source immutability hook blocked: manifest malformed at ${manifest}. Cannot verify source immutability." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Manifest lookup — check whether the relative path is registered.
# ADR-015: non-null .sources[$path] means the source already exists.
# ---------------------------------------------------------------------------
existing="$(jq -r --arg path "$relative_path" '.sources[$path] // empty' "$manifest")"

if [[ -n "$existing" ]]; then
  # Existing source — block the overwrite (immutability violation).
  emit_event "source.immutability.violated" "path=${relative_path}" "code=E-SOURCE-001"
  jq -cn \
    --arg code "E-SOURCE-001" \
    --arg path "$relative_path" \
    --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Source file already exists in manifest. Sources are immutable. Use /brain:rename-page to rename." \
    '{"continue":false,"decision":"block","reason":("\($path): " + $msg),"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source immutability hook blocked: ${relative_path} already exists in manifest. Sources are immutable. Use /brain:rename-page to rename." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# New source — allow the write.
# ---------------------------------------------------------------------------
emit_event "source.added" "path=${relative_path}"
jq -cn --arg trace "${HOOK_TRACE_ID}" --arg msg "New source accepted." \
  '{"continue":true,"trace":$trace,"message":$msg}'
exit 0
