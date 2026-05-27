#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'exit 2' ERR
# validate-source-immutability.sh — PostToolUse hook: source immutability enforcement
# BC-2.04.002 | VP-003 | ADR-002 v2.0 | ADR-015 (manifest schema) | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — checks .brain/manifest.json to block overwriting existing sources.
# Exit 0: allow (new source) | Exit 2: block (existing source or fail-closed on error)

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-source-immutability.sh" >&2
  printf '{"verdict":"block","code":"E-HOOK-002","message":"Hook helper missing; cannot safely proceed.","trace":"00000000-0000-0000-0000-000000000000"}\n'
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
  emit_verdict "{\"verdict\":\"block\",\"code\":\"E-SOURCE-003\",\"message\":\"Malformed or empty JSON on stdin; cannot safely proceed.\",\"trace\":\"${HOOK_TRACE_ID}\"}"
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
  emit_verdict "{\"verdict\":\"block\",\"code\":\"E-SOURCE-003\",\"message\":\"Missing file_path or brain directory in payload; cannot verify source immutability.\",\"trace\":\"${HOOK_TRACE_ID}\"}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ADR-015: manifest keys are relative paths (e.g. "sources/ai/article.md").
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Check that .brain/manifest.json exists and is readable — fail-closed.
# EC-003: missing manifest → E-SOURCE-002.
# ---------------------------------------------------------------------------
manifest="${brain_dir}/.brain/manifest.json"
if [[ ! -r "$manifest" ]]; then
  emit_event "source.immutability.check_failed" "code=E-SOURCE-002" "reason=manifest not found"
  emit_verdict "{\"verdict\":\"block\",\"code\":\"E-SOURCE-002\",\"message\":\"Manifest not found — cannot verify source immutability.\",\"trace\":\"${HOOK_TRACE_ID}\"}"
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
  emit_verdict "{\"verdict\":\"block\",\"code\":\"E-SOURCE-001\",\"message\":\"Source file ${relative_path} already exists in manifest. Sources are immutable. Use /brain:rename-page to rename.\",\"trace\":\"${HOOK_TRACE_ID}\"}"
  exit 2
fi

# ---------------------------------------------------------------------------
# New source — allow the write.
# ---------------------------------------------------------------------------
emit_event "source.added" "path=${relative_path}"
emit_verdict "{\"verdict\":\"allow\",\"message\":\"New source accepted.\",\"trace\":\"${HOOK_TRACE_ID}\"}"
exit 0
