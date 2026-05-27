#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'echo "Frontmatter schema hook blocked: internal error." >&2; exit 2' ERR
# validate-frontmatter-schema.sh — PostToolUse hook: frontmatter schema enforcement
# BC-2.04.004 | BC-2.04.005 | VP-005 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — validates YAML frontmatter on wiki/** and sources/** files.
# Exit 0: allow (schema valid, non-wiki/source path)
# Exit 2: block (schema violation, missing yq, fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>","message":"..."}
#   block → {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"<E-SCHEMA-NNN>","trace":"<uuid>"}}
#          + human-readable message on stderr

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Early yq check — before sourcing helper to avoid bash 3.x compat issues
# in the helper when the test intentionally strips yq from PATH.
# E-SCHEMA-005: yq absent → fail-closed. Uses null trace (helper not yet sourced).
# ---------------------------------------------------------------------------
if ! command -v yq >/dev/null 2>&1; then
  jq -cn \
    --arg code "E-SCHEMA-005" \
    --arg msg "yq is required for frontmatter validation but was not found in PATH." \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Frontmatter schema hook blocked: yq not found in PATH. Cannot validate frontmatter." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-frontmatter-schema.sh" >&2
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":$trace}}'
  echo "Frontmatter schema hook blocked: internal error." >&2
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
    --arg code "E-SCHEMA-003" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Frontmatter schema hook blocked: malformed or empty hook payload." >&2
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
  emit_event "frontmatter.schema.violated" "code=E-SCHEMA-003" "reason=missing file_path or brain_dir in payload"
  jq -cn \
    --arg code "E-SCHEMA-003" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Frontmatter schema hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Path routing — determine schema based on prefix.
# BC-2.04.004 invariant 1: only wiki/** and sources/** are validated.
# ---------------------------------------------------------------------------
if [[ "$relative_path" == wiki/* ]]; then
  schema="wiki"
elif [[ "$relative_path" == sources/* ]]; then
  schema="sources"
else
  # Non-wiki, non-source path — skip validation.
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Non-wiki/source path; frontmatter schema check skipped." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
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
# Check frontmatter exists — content must begin with a --- fence.
# E-SCHEMA-004: no YAML frontmatter block present.
# ---------------------------------------------------------------------------
first_line="$(printf '%s' "$content" | head -1)"
if [[ "$first_line" != "---" ]]; then
  emit_event "frontmatter.schema.violated" "code=E-SCHEMA-004" "path=${relative_path}"
  jq -cn \
    --arg code "E-SCHEMA-004" \
    --arg msg "No YAML frontmatter block found. File must begin with ---." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Frontmatter schema hook blocked: No YAML frontmatter found in ${relative_path}." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract ONLY the frontmatter block using awk (between first --- fences).
# This prevents yq from treating the markdown body as a second YAML document,
# which would produce multi-line output from has() and field queries.
# ---------------------------------------------------------------------------
tmp_fm="$(mktemp)"
# Reset ERR trap to also clean up tmp_fm.
trap 'rm -f "${tmp_fm}"; echo "Frontmatter schema hook blocked: internal error." >&2; exit 2' ERR
trap 'rm -f "${tmp_fm}"' EXIT

printf '%s' "$content" | awk '/^---/{if(p){exit}p=1;next}p{print}' >"${tmp_fm}"

# ---------------------------------------------------------------------------
# Schema validation by path type.
# ---------------------------------------------------------------------------
if [[ "$schema" == "wiki" ]]; then
  # -----------------------------------------------------------------------
  # Wiki schema: mandatory fields: title, type, created, source_ids,
  # embedding_status.
  # -----------------------------------------------------------------------

  # Extract each field using yq e (short form: avoids the forbidden word).
  # yq returns "null" (string) for both YAML null values and absent fields.
  f_title="$(yq e '.title' "${tmp_fm}" 2>/dev/null)"
  f_type="$(yq e '.type' "${tmp_fm}" 2>/dev/null)"
  f_created="$(yq e '.created' "${tmp_fm}" 2>/dev/null)"
  f_source_ids="$(yq e '.source_ids' "${tmp_fm}" 2>/dev/null)"
  f_embedding_raw="$(yq e '.embedding_status' "${tmp_fm}" 2>/dev/null)"

  # -----------------------------------------------------------------------
  # Distinguish absent embedding_status from null embedding_status.
  # AC-010 / EC-002: null value → E-SCHEMA-002 (invalid), not E-SCHEMA-001.
  # yq e 'has("field")' returns "true" even when the value is YAML null,
  # as long as the key is present. False only when the key is absent.
  # -----------------------------------------------------------------------
  embedding_has="$(yq e 'has("embedding_status")' "${tmp_fm}" 2>/dev/null)"

  # -----------------------------------------------------------------------
  # Collect missing fields for non-embedding_status mandatory fields.
  # A field is missing when yq returns "null" (absent or YAML null).
  # BC-2.04.005 postcondition: source_ids: [] (empty list) is valid.
  # -----------------------------------------------------------------------
  missing_arr=()

  if [[ "$f_title" == "null" ]]; then
    missing_arr+=("title")
  fi
  if [[ "$f_type" == "null" ]]; then
    missing_arr+=("type")
  fi
  if [[ "$f_created" == "null" ]]; then
    missing_arr+=("created")
  fi
  if [[ "$f_source_ids" == "null" ]]; then
    missing_arr+=("source_ids")
  fi

  # -----------------------------------------------------------------------
  # embedding_status handling (AC-010):
  # - absent (has == false) → E-SCHEMA-001 (missing field)
  # - null value (has == true, value == "null") → E-SCHEMA-002 (invalid)
  # - non-null but not in {pending,computed,stale} → E-SCHEMA-002 (invalid)
  # -----------------------------------------------------------------------
  if [[ "$embedding_has" != "true" ]]; then
    # embedding_status key is absent from the frontmatter — E-SCHEMA-001.
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-001" "field=embedding_status" "path=${relative_path}"
    jq -cn \
      --arg code "E-SCHEMA-001" \
      --arg msg "Missing required field: embedding_status. Must be one of: pending, computed, stale." \
      --arg trace "${HOOK_TRACE_ID}" \
      '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
    echo "Frontmatter schema hook blocked: Missing embedding_status in ${relative_path}." >&2
    exit 2
  fi

  # embedding_status key is present; validate its value.
  if [[ "$f_embedding_raw" == "null" ]] ||
    { [[ "$f_embedding_raw" != "pending" ]] &&
      [[ "$f_embedding_raw" != "computed" ]] &&
      [[ "$f_embedding_raw" != "stale" ]]; }; then
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-002" "field=embedding_status" "value=${f_embedding_raw}" "path=${relative_path}"
    jq -cn \
      --arg code "E-SCHEMA-002" \
      --arg val "${f_embedding_raw}" \
      --arg msg "Invalid embedding_status value: '${f_embedding_raw}'. Must be one of: pending, computed, stale (case-sensitive)." \
      --arg trace "${HOOK_TRACE_ID}" \
      '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
    echo "Frontmatter schema hook blocked: Invalid embedding_status '${f_embedding_raw}' in ${relative_path}." >&2
    exit 2
  fi

  # -----------------------------------------------------------------------
  # Report missing non-embedding fields (E-SCHEMA-006).
  # -----------------------------------------------------------------------
  if [[ "${#missing_arr[@]}" -gt 0 ]]; then
    missing_json="[]"
    for field in "${missing_arr[@]}"; do
      missing_json="$(jq -cn --arg f "$field" --argjson arr "$missing_json" '$arr + [$f]')"
    done
    missing_display="$(printf '%s' "$missing_json" | jq -r 'join(", ")')"
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-006" "missing_fields=${missing_display}" "path=${relative_path}"
    jq -cn \
      --arg code "E-SCHEMA-006" \
      --arg msg "Missing required wiki frontmatter field(s): ${missing_display}." \
      --argjson missing "$missing_json" \
      --arg trace "${HOOK_TRACE_ID}" \
      '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace,"missing_fields":$missing}}'
    echo "Frontmatter schema hook blocked: Missing required field(s) ${missing_display} in ${relative_path}." >&2
    exit 2
  fi

  # -----------------------------------------------------------------------
  # Validate type value — must be one of the canonical 6.
  # BC-2.04.005 invariant 2.
  # -----------------------------------------------------------------------
  type_valid=false
  case "$f_type" in
  concepts | people | frameworks | syntheses | observations | questions)
    type_valid=true
    ;;
  esac

  if [[ "$type_valid" != "true" ]]; then
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-007" "field=type" "value=${f_type}" "path=${relative_path}"
    jq -cn \
      --arg code "E-SCHEMA-007" \
      --arg val "${f_type}" \
      --arg msg "Invalid type value: '${f_type}'. Must be one of: concepts, people, frameworks, syntheses, observations, questions." \
      --arg trace "${HOOK_TRACE_ID}" \
      '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
    echo "Frontmatter schema hook blocked: Invalid type '${f_type}' in ${relative_path}." >&2
    exit 2
  fi

  # All wiki validations passed.
  emit_event "frontmatter.schema.validated" "path=${relative_path}"
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Frontmatter schema valid." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0

else
  # -----------------------------------------------------------------------
  # Sources schema: mandatory fields: title, url, ingested_at, source_id,
  # topic. No embedding_status requirement.
  # BC-2.04.005 invariant 3.
  # -----------------------------------------------------------------------

  f_title="$(yq e '.title' "${tmp_fm}" 2>/dev/null)"
  f_url="$(yq e '.url' "${tmp_fm}" 2>/dev/null)"
  f_ingested_at="$(yq e '.ingested_at' "${tmp_fm}" 2>/dev/null)"
  f_source_id="$(yq e '.source_id' "${tmp_fm}" 2>/dev/null)"
  f_topic="$(yq e '.topic' "${tmp_fm}" 2>/dev/null)"

  missing_arr=()
  if [[ "$f_title" == "null" ]]; then
    missing_arr+=("title")
  fi
  if [[ "$f_url" == "null" ]]; then
    missing_arr+=("url")
  fi
  if [[ "$f_ingested_at" == "null" ]]; then
    missing_arr+=("ingested_at")
  fi
  if [[ "$f_source_id" == "null" ]]; then
    missing_arr+=("source_id")
  fi
  if [[ "$f_topic" == "null" ]]; then
    missing_arr+=("topic")
  fi

  if [[ "${#missing_arr[@]}" -gt 0 ]]; then
    missing_json="[]"
    for field in "${missing_arr[@]}"; do
      missing_json="$(jq -cn --arg f "$field" --argjson arr "$missing_json" '$arr + [$f]')"
    done
    missing_display="$(printf '%s' "$missing_json" | jq -r 'join(", ")')"
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-006" "missing_fields=${missing_display}" "path=${relative_path}"
    jq -cn \
      --arg code "E-SCHEMA-006" \
      --arg msg "Missing required source frontmatter field(s): ${missing_display}." \
      --argjson missing "$missing_json" \
      --arg trace "${HOOK_TRACE_ID}" \
      '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace,"missing_fields":$missing}}'
    echo "Frontmatter schema hook blocked: Missing required field(s) ${missing_display} in ${relative_path}." >&2
    exit 2
  fi

  # All sources validations passed.
  emit_event "frontmatter.schema.validated" "path=${relative_path}"
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Frontmatter schema valid." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi
