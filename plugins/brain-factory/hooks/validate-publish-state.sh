#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf '"'"'{"ts":"%s","event_type":"hook.error.internal","hook_name":"validate-publish-state.sh","trace":"%s","code":"E-HOOK-003","reason":"unhandled error"}\n'"'"' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" >&2; exit 2' ERR
# validate-publish-state.sh — PostToolUse hook: publish state machine enforcement
# BC-2.04.010 | VP-002 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — validates publish status transitions in content files.
# Valid transitions: draft->ready, ready->published (same-state writes are idempotent).
# Exit 0: allow (valid transition, new draft file, idempotent write, or out-of-scope path)
# Exit 2: block (invalid transition, missing status, or fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow -> {"continue":true,"trace":"<uuid>","message":"..."}
#   block -> {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"<E-PUBLISH-NNN>","trace":"<uuid>",...}}

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-publish-state.sh" >&2
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract fields using pure bash _json_get_str.
# The content field may contain U+0001 control chars (test helper encoding);
# _json_get_str handles this safely — jq rejects such payloads.
# (performance: zero subprocesses for field extraction vs four jq calls).
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
file_path="$(_json_get_str "$stdin_json" 'file_path')"
tool_name="$(_json_get_str "$stdin_json" 'tool_name')"
_cwd_raw="$(_json_get_str "$stdin_json" 'cwd')"
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
# Compute the relative path by stripping the brain_dir prefix.
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Path routing — only drafts/**, to-publish/**, published/** are in scope.
# Non-content paths are a no-op (exit 0 immediately).
# ---------------------------------------------------------------------------
in_scope=false
case "$relative_path" in
drafts/* | to-publish/* | published/*)
  in_scope=true
  ;;
esac

if [[ "$in_scope" != "true" ]]; then
  printf '{"continue":true,"trace":"%s","message":"Non-content path; publish state check skipped."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Extract the NEW status from the file on disk (PostToolUse — already written).
# ---------------------------------------------------------------------------
if [[ ! -r "$file_path" ]]; then
  emit_event "publish.state.check_failed" "code=E-PUBLISH-002" "reason=cannot read content file"
  printf '{"continue":false,"decision":"block","reason":"Cannot read content file for publish state check.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-PUBLISH-002","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# Extract frontmatter from file (between first two --- lines).
new_frontmatter="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$file_path")"

# Extract status field from frontmatter.
# Use || true to tolerate grep exit 1 when status field is absent.
new_status="$(printf '%s\n' "$new_frontmatter" | grep '^status:' | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '[:space:]' || true)"

# Missing status field -> E-PUBLISH-002 (BC-2.04.010 invariant 4).
if [[ -z "$new_status" ]]; then
  emit_event "publish.state.check_failed" "code=E-PUBLISH-002" "reason=missing status field in content file"
  printf '{"continue":false,"decision":"block","reason":"Missing status field in content file.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-PUBLISH-002","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Determine the PRIOR status.
# For Edit: parse old_string from the payload.
# For Write: use git show HEAD:<relative_path> to read prior committed version.
# If no prior state (new file), prior_status="".
# ---------------------------------------------------------------------------
prior_status=""

if [[ "$tool_name" == "Edit" ]]; then
  # For Edit operations: extract status from old_string in payload.
  old_string="$(printf '%s' "$stdin_json" | jq -r '.tool_input.old_string // ""' 2>/dev/null || true)"
  if [[ -n "$old_string" ]]; then
    old_frontmatter="$(printf '%s\n' "$old_string" | awk '/^---$/{n++; next} n==1{print} n>=2{exit}')"
    prior_status="$(printf '%s\n' "$old_frontmatter" | grep '^status:' | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '[:space:]' || true)"
  fi
else
  # For Write operations: read prior committed version from git HEAD.
  prior_content=""
  if prior_content="$(git -C "$brain_dir" show "HEAD:${relative_path}" 2>/dev/null)"; then
    :
  else
    prior_content=""
  fi
  if [[ -n "$prior_content" ]]; then
    prior_frontmatter="$(printf '%s\n' "$prior_content" | awk '/^---$/{n++; next} n==1{print} n>=2{exit}')"
    prior_status="$(printf '%s\n' "$prior_frontmatter" | grep '^status:' | head -1 | sed 's/^status:[[:space:]]*//' | tr -d '[:space:]' || true)"
  fi
fi

# ---------------------------------------------------------------------------
# State machine validation.
# ---------------------------------------------------------------------------
if [[ -z "$prior_status" ]]; then
  # New file (no prior state) — only draft is allowed as initial status.
  if [[ "$new_status" != "draft" ]]; then
    emit_event "publish.state.transition_rejected" \
      "path=$relative_path" "from_state=" "to_state=$new_status"
    _em_ns="$(_json_escape "${new_status}")"
    printf '{"continue":false,"decision":"block","reason":"Invalid initial state: new content files must start as draft, not %s.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-PUBLISH-001","trace":"%s","from_state":"","to_state":"%s"}}\n' \
      "${_em_ns}" "${HOOK_TRACE_ID}" "${_em_ns}"
    exit 2
  fi
  # New draft file — allow.
  emit_event "publish.state.transition_accepted" "path=$relative_path" "to_state=$new_status"
  printf '{"continue":true,"trace":"%s","message":"New content file created as draft."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# Prior state exists — validate the transition.
# Idempotent writes (same state) are always allowed.
if [[ "$prior_status" == "$new_status" ]]; then
  emit_event "publish.state.transition_accepted" "path=$relative_path" "to_state=$new_status"
  printf '{"continue":true,"trace":"%s","message":"Idempotent state write accepted."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# Check valid transitions: draft->ready, ready->published.
# Use string comparison — no Unicode arrow to avoid shellcheck issues.
transition_valid=false
if [[ "$prior_status" == "draft" && "$new_status" == "ready" ]]; then
  transition_valid=true
elif [[ "$prior_status" == "ready" && "$new_status" == "published" ]]; then
  transition_valid=true
fi

if [[ "$transition_valid" != "true" ]]; then
  emit_event "publish.state.transition_rejected" \
    "path=$relative_path" "from_state=$prior_status" "to_state=$new_status"
  _em_from="$(_json_escape "${prior_status}")"
  _em_to="$(_json_escape "${new_status}")"
  printf '{"continue":false,"decision":"block","reason":"Invalid state transition: '\''%s'\'' -> '\''%s'\''. Valid transitions: draft->ready, ready->published.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-PUBLISH-001","trace":"%s","from_state":"%s","to_state":"%s"}}\n' \
    "${_em_from}" "${_em_to}" "${HOOK_TRACE_ID}" "${_em_from}" "${_em_to}"
  exit 2
fi

# Valid transition — allow.
emit_event "publish.state.transition_accepted" "path=$relative_path" "to_state=$new_status"
_em_from="$(_json_escape "${prior_status}")"
_em_to="$(_json_escape "${new_status}")"
printf '{"continue":true,"trace":"%s","message":"State transition accepted: %s -> %s."}\n' \
  "${HOOK_TRACE_ID}" "${_em_from}" "${_em_to}"
exit 0
