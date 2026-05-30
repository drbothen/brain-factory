#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'printf '"'"'{"ts":"%s","event_type":"hook.error.internal","hook_name":"validate-frontmatter-schema.sh","trace":"%s","code":"E-HOOK-003","reason":"unhandled error"}\n'"'"' "$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)" "${HOOK_TRACE_ID:-00000000-0000-0000-0000-000000000000}" >&2; exit 2' ERR
# validate-frontmatter-schema.sh — PostToolUse hook: frontmatter schema enforcement
# BC-2.04.004 | BC-2.04.005 | VP-005 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — validates YAML frontmatter on wiki/** and sources/** files.
# Exit 0: allow (schema valid, non-wiki/source path)
# Exit 2: block (schema violation, missing yq, fail-closed on error)
# stdout protocol (ADR-002 v2.0):
#   allow → {"continue":true,"trace":"<uuid>","message":"..."}
#   block → {"continue":false,"decision":"block","reason":"<text>",
#             "hookSpecificOutput":{"hookEventName":"PostToolUse","code":"<E-SCHEMA-NNN>","trace":"<uuid>"}}
#
# Performance: subprocess count on happy path minimised for BC-2.04.015 (<100ms p99):
#   - _json_get_str (pure bash) extracts file_path, cwd, content from stdin (0 subprocesses)
#   - Pure bash JSON string decode for content (no jq subprocess)
#   - Pure bash loop extracts frontmatter block (no awk subprocess)
#   - Pure bash loop checks embedding_status key presence (no yq/grep subprocess)
#   - Single yq call outputs field values as plain lines (no second jq parse step)
#   - All verdict output uses printf + _json_escape (no jq -cn subprocesses)

HELPER="${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"

# ---------------------------------------------------------------------------
# Early yq check — before sourcing helper to avoid bash 3.x compat issues
# in the helper when the test intentionally strips yq from PATH.
# E-SCHEMA-005: yq absent → fail-closed. Uses null trace (helper not yet sourced).
# ---------------------------------------------------------------------------
if ! command -v yq >/dev/null 2>&1; then
  printf '{"ts":"%s","event_type":"hook.tool.missing","hook_name":"validate-frontmatter-schema.sh","trace":"00000000-0000-0000-0000-000000000000","code":"E-SCHEMA-005","reason":"yq not found in PATH"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" >&2
  printf '{"continue":false,"decision":"block","reason":"yq is required for frontmatter validation but was not found in PATH.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-005","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi

# ---------------------------------------------------------------------------
# Source the event-emit helper (fail-closed if missing)
# ---------------------------------------------------------------------------
if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-frontmatter-schema.sh" >&2
  printf '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":"00000000-0000-0000-0000-000000000000"}}\n'
  exit 2
fi
# shellcheck disable=SC1090,SC1091
source "$HELPER"

# ---------------------------------------------------------------------------
# Read stdin JSON payload and extract file_path, cwd, and content using
# pure bash _json_get_str (zero subprocesses — eliminates the jq call that
# was the second-most expensive operation on the hot path after yq).
# Malformed JSON → _json_get_str returns empty → file_path empty → fail-closed.
# content may be multi-line with JSON \n escapes — decode with pure bash.
# ---------------------------------------------------------------------------
stdin_json="$(cat)"
file_path="$(_json_get_str "$stdin_json" 'file_path')"
_cwd_raw="$(_json_get_str "$stdin_json" 'cwd')"
_content_raw="$(_json_get_str "$stdin_json" 'content')"
# Decode JSON string escape sequences (pure bash, no subprocess).
# Order matters: decode \\ before other sequences to avoid double-decode.
_content_tmp="${_content_raw//\\\\/\\}"
_content_tmp="${_content_tmp//\\n/
}"
_content_tmp="${_content_tmp//\\t/	}"
_content_tmp="${_content_tmp//\\\"/\"}"
content="$_content_tmp"
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
# Path routing — determine schema based on prefix.
# BC-2.04.004 invariant 1: only wiki/** and sources/** are validated.
# ---------------------------------------------------------------------------
if [[ "$relative_path" == wiki/* ]]; then
  schema="wiki"
elif [[ "$relative_path" == sources/* ]]; then
  schema="sources"
else
  # Non-wiki, non-source path — skip validation.
  printf '{"continue":true,"trace":"%s","message":"Non-wiki/source path; frontmatter schema check skipped."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi

# ---------------------------------------------------------------------------
# Fall back to reading from disk if content was not in the payload
# (Edit tool may not provide full content).
# ---------------------------------------------------------------------------
if [[ -z "$content" ]] && [[ -f "$file_path" ]]; then
  content="$(cat "$file_path")"
fi

# ---------------------------------------------------------------------------
# Check frontmatter exists — content must begin with a --- fence.
# Pure bash: no head subprocess.
# E-SCHEMA-004: no YAML frontmatter block present.
# ---------------------------------------------------------------------------
first_line="${content%%$'\n'*}"
if [[ "$first_line" != "---" ]]; then
  emit_event "frontmatter.schema.violated" "code=E-SCHEMA-004" "path=${relative_path}"
  printf '{"continue":false,"decision":"block","reason":"No YAML frontmatter block found. File must begin with ---.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-004","trace":"%s"}}\n' \
    "${HOOK_TRACE_ID}"
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract ONLY the frontmatter block using a pure bash loop (no awk subprocess).
# Strips the first --- line, accumulates lines until the closing --- fence.
# ---------------------------------------------------------------------------
_fm_content=""
_in_fm=false
while IFS= read -r _fm_line; do
  if [[ "$_in_fm" == false && "$_fm_line" == "---" ]]; then
    _in_fm=true
  elif [[ "$_in_fm" == true && "$_fm_line" == "---" ]]; then
    break
  elif [[ "$_in_fm" == true ]]; then
    _fm_content="${_fm_content}${_fm_line}"$'\n'
  fi
done <<<"$content"

# ---------------------------------------------------------------------------
# Schema validation by path type.
# ---------------------------------------------------------------------------
if [[ "$schema" == "wiki" ]]; then
  # -----------------------------------------------------------------------
  # Wiki schema: mandatory fields: title, type, created, source_ids,
  # embedding_status.
  # -----------------------------------------------------------------------

  # -----------------------------------------------------------------------
  # Check embedding_status key presence with pure bash (no yq/grep subprocess).
  # Must be done BEFORE the yq field-extraction call to avoid the yq4 multi-
  # expression has() bug: in yq4, has("X") returns true inside an object
  # literal that also reads .X, even when X is absent.
  # -----------------------------------------------------------------------
  embedding_has="false"
  while IFS= read -r _line; do
    if [[ "$_line" == "embedding_status:"* ]]; then
      embedding_has="true"
      break
    fi
  done <<<"$_fm_content"

  # -----------------------------------------------------------------------
  # Single yq call: extract all wiki field values as plain lines (no second
  # jq parse step — saves ~29ms subprocess vs the prior @tsv jq approach).
  # Output order: title, type, created, has_source_ids, embedding_status.
  # Malformed YAML → yq exits non-zero → fail-closed.
  # -----------------------------------------------------------------------
  f_title="" f_type="" f_created="" f_has_src="" f_embedding_raw=""
  if ! {
    IFS= read -r f_title
    IFS= read -r f_type
    IFS= read -r f_created
    IFS= read -r f_has_src
    IFS= read -r f_embedding_raw
  } < <(printf '%s' "$_fm_content" | yq e \
    '(.title // "null"), (.type // "null"), ((.created // "null") | tostring), (has("source_ids") | tostring), (.embedding_status // "null")' \
    - 2>/dev/null); then
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-003" "path=${relative_path}"
    printf '{"continue":false,"decision":"block","reason":"Malformed YAML frontmatter: yq could not parse the frontmatter block.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-003","trace":"%s"}}\n' \
      "${HOOK_TRACE_ID}"
    exit 2
  fi

  # -----------------------------------------------------------------------
  # Collect missing fields for non-embedding_status mandatory fields.
  # A field is "null" when yq returns "null" (absent or YAML null).
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
  if [[ "$f_has_src" != "true" ]]; then
    missing_arr+=("source_ids")
  fi

  # -----------------------------------------------------------------------
  # embedding_status handling (AC-010):
  # - absent (embedding_has == false) → E-SCHEMA-001 (missing field)
  # - null value (embedding_has == true, value == "null") → E-SCHEMA-002 (invalid)
  # - non-null but not in {pending,computed,stale} → E-SCHEMA-002 (invalid)
  # -----------------------------------------------------------------------
  if [[ "$embedding_has" != "true" ]]; then
    # embedding_status key is absent from the frontmatter — E-SCHEMA-001.
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-001" "missing_field=embedding_status" "path=${relative_path}"
    printf '{"continue":false,"decision":"block","reason":"Missing required field: embedding_status. Must be one of: pending, computed, stale.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-001","trace":"%s"}}\n' \
      "${HOOK_TRACE_ID}"
    exit 2
  fi

  # embedding_status key is present; validate its value.
  if [[ "$f_embedding_raw" == "null" ]] ||
    { [[ "$f_embedding_raw" != "pending" ]] &&
      [[ "$f_embedding_raw" != "computed" ]] &&
      [[ "$f_embedding_raw" != "stale" ]]; }; then
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-002" "invalid_field=embedding_status" "invalid_value=${f_embedding_raw}" "path=${relative_path}"
    _em_val="$(_json_escape "${f_embedding_raw}")"
    printf '{"continue":false,"decision":"block","reason":"Invalid embedding_status value: '\''%s'\''. Must be one of: pending, computed, stale (case-sensitive).","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-002","trace":"%s"}}\n' \
      "${_em_val}" "${HOOK_TRACE_ID}"
    exit 2
  fi

  # -----------------------------------------------------------------------
  # Report missing non-embedding fields (E-SCHEMA-006).
  # Pure bash JSON array + display string (no jq subprocesses per element).
  # -----------------------------------------------------------------------
  if [[ "${#missing_arr[@]}" -gt 0 ]]; then
    missing_json="["
    missing_display=""
    _mfirst=true
    for _mf in "${missing_arr[@]}"; do
      _mesc="$(_json_escape "${_mf}")"
      if [[ "$_mfirst" == "true" ]]; then
        missing_json="${missing_json}\"${_mesc}\""
        missing_display="${_mf}"
        _mfirst=false
      else
        missing_json="${missing_json},\"${_mesc}\""
        missing_display="${missing_display}, ${_mf}"
      fi
    done
    missing_json="${missing_json}]"
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-006" "missing_fields=${missing_display}" "path=${relative_path}"
    _em_disp="$(_json_escape "Missing required wiki frontmatter field(s): ${missing_display}.")"
    printf '{"continue":false,"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-006","trace":"%s","missing_fields":%s}}\n' \
      "${_em_disp}" "${HOOK_TRACE_ID}" "${missing_json}"
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
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-007" "invalid_field=type" "invalid_value=${f_type}" "path=${relative_path}"
    _em_tv="$(_json_escape "${f_type}")"
    printf '{"continue":false,"decision":"block","reason":"Invalid type value: '\''%s'\''. Must be one of: concepts, people, frameworks, syntheses, observations, questions.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-007","trace":"%s"}}\n' \
      "${_em_tv}" "${HOOK_TRACE_ID}"
    exit 2
  fi

  # All wiki validations passed.
  emit_event "frontmatter.schema.validated" "path=${relative_path}"
  printf '{"continue":true,"trace":"%s","message":"Frontmatter schema valid."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0

else
  # -----------------------------------------------------------------------
  # Sources schema: mandatory fields: title, url, ingested_at, source_id,
  # topic. No embedding_status requirement.
  # BC-2.04.005 invariant 3.
  # -----------------------------------------------------------------------

  # Single yq call outputs field values as plain lines (no second jq step).
  f_title="" f_url="" f_ingested_at="" f_source_id="" f_topic=""
  if ! {
    IFS= read -r f_title
    IFS= read -r f_url
    IFS= read -r f_ingested_at
    IFS= read -r f_source_id
    IFS= read -r f_topic
  } < <(printf '%s' "$_fm_content" | yq e \
    '(.title // "null"), (.url // "null"), (.ingested_at // "null"), (.source_id // "null"), (.topic // "null")' \
    - 2>/dev/null); then
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-003" "path=${relative_path}"
    printf '{"continue":false,"decision":"block","reason":"Malformed YAML frontmatter: yq could not parse the frontmatter block.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-003","trace":"%s"}}\n' \
      "${HOOK_TRACE_ID}"
    exit 2
  fi

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
    missing_json="["
    missing_display=""
    _mfirst=true
    for _mf in "${missing_arr[@]}"; do
      _mesc="$(_json_escape "${_mf}")"
      if [[ "$_mfirst" == "true" ]]; then
        missing_json="${missing_json}\"${_mesc}\""
        missing_display="${_mf}"
        _mfirst=false
      else
        missing_json="${missing_json},\"${_mesc}\""
        missing_display="${missing_display}, ${_mf}"
      fi
    done
    missing_json="${missing_json}]"
    emit_event "frontmatter.schema.violated" "code=E-SCHEMA-006" "missing_fields=${missing_display}" "path=${relative_path}"
    _em_disp="$(_json_escape "Missing required source frontmatter field(s): ${missing_display}.")"
    printf '{"continue":false,"decision":"block","reason":"%s","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-SCHEMA-006","trace":"%s","missing_fields":%s}}\n' \
      "${_em_disp}" "${HOOK_TRACE_ID}" "${missing_json}"
    exit 2
  fi

  # All sources validations passed.
  emit_event "frontmatter.schema.validated" "path=${relative_path}"
  printf '{"continue":true,"trace":"%s","message":"Frontmatter schema valid."}\n' \
    "${HOOK_TRACE_ID}"
  exit 0
fi
