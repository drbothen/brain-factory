#!/usr/bin/env bash
set -euo pipefail
# Fail-closed trap: any unhandled error exits 2 (block).
# ADR-002 v2.0: exit codes other than 0 are treated as blocking errors.
trap 'echo "Source citation hook blocked: internal error." >&2; exit 2' ERR
# validate-source-id-citation.sh — PostToolUse hook: source citation integrity enforcement
# BC-2.04.009 | VP-002 | ADR-002 v2.0 | ADR-016 (event emission)
# Fires AFTER Write|Edit executes — validates that source_ids in wiki page frontmatter
# resolve to entries in .brain/manifest.json.
# Exit 0: allow (all citations resolved, empty list, or non-wiki path)
# Exit 2: block (unresolved citation, manifest absent, or fail-closed on error)
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
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "validate-source-id-citation.sh" >&2
  jq -cn \
    --arg trace "00000000-0000-0000-0000-000000000000" \
    '{"continue":false,"decision":"block","reason":"Hook helper missing; cannot safely proceed.","hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-HOOK-002","trace":$trace}}'
  echo "Source citation hook blocked: internal error." >&2
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
    --arg code "E-WIKI-008" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source citation hook blocked: malformed or empty hook payload." >&2
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
  jq -cn \
    --arg code "E-WIKI-008" \
    --arg msg "Malformed or empty hook payload." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source citation hook blocked: malformed or empty hook payload." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Compute the relative path by stripping the brain_dir prefix.
# ---------------------------------------------------------------------------
relative_path="${file_path#"${brain_dir}/"}"

# ---------------------------------------------------------------------------
# Early exit for non-wiki paths — this hook only applies to wiki/**
# BC-2.04.009 precondition 1: only fires for Write|Edit on wiki/** paths.
# ---------------------------------------------------------------------------
if [[ "$relative_path" != wiki/* ]]; then
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Non-wiki path; source citation check skipped." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Read the file from disk (PostToolUse — file already written).
# ---------------------------------------------------------------------------
if [[ ! -r "$file_path" ]]; then
  jq -cn \
    --arg code "E-WIKI-008" \
    --arg msg "Cannot read wiki file for source citation check." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source citation hook blocked: cannot read file at ${file_path}." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Extract source_ids from YAML frontmatter.
# Frontmatter is the block between the first two --- lines.
# Supports inline flow-sequence: source_ids: [slug1, slug2]
# Supports block sequence:
#   source_ids:
#     - slug1
#     - slug2
# ---------------------------------------------------------------------------
frontmatter="$(awk '/^---$/{n++; next} n==1{print} n>=2{exit}' "$file_path")"

# Check if source_ids field exists in frontmatter at all.
if ! printf '%s\n' "$frontmatter" | grep -q '^source_ids:'; then
  # No source_ids field — vacuously satisfied (AC-005).
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "No source_ids field; citation check vacuously satisfied." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# Extract the source_ids line.
source_ids_line="$(printf '%s\n' "$frontmatter" | grep '^source_ids:')"
slugs=()

if printf '%s' "$source_ids_line" | grep -qE '^\s*source_ids:\s*\['; then
  # Inline format: source_ids: [slug1, slug2, ...]
  # Extract content between [ and ].
  inner="$(printf '%s' "$source_ids_line" | sed 's/.*\[//; s/\].*//')"
  if [[ -z "$inner" ]] || printf '%s' "$inner" | grep -qE '^\s*$'; then
    # Empty inline list — vacuously satisfied.
    jq -cn --arg trace "${HOOK_TRACE_ID}" \
      --arg msg "Empty source_ids list; citation check vacuously satisfied." \
      '{"continue":true,"trace":$trace,"message":$msg}'
    exit 0
  fi
  # Split on commas, strip whitespace from each slug.
  while IFS= read -r raw; do
    slug="${raw#"${raw%%[![:space:]]*}"}"
    slug="${slug%"${slug##*[![:space:]]}"}"
    if [[ -n "$slug" ]]; then
      slugs+=("$slug")
    fi
  done < <(printf '%s\n' "$inner" | tr ',' '\n')
else
  # Block format: collect indented lines after source_ids:
  in_source_ids=false
  while IFS= read -r line; do
    if printf '%s' "$line" | grep -qE '^source_ids:'; then
      in_source_ids=true
      continue
    fi
    if [[ "$in_source_ids" == "true" ]]; then
      # Lines starting with whitespace + "- " are list items.
      if printf '%s' "$line" | grep -qE '^\s+-\s'; then
        slug="$(printf '%s' "$line" | sed 's/^\s*-\s*//')"
        slug="${slug#"${slug%%[![:space:]]*}"}"
        slug="${slug%"${slug##*[![:space:]]}"}"
        if [[ -n "$slug" ]]; then
          slugs+=("$slug")
        fi
      else
        # Non-list line ends the source_ids block.
        in_source_ids=false
      fi
    fi
  done < <(printf '%s\n' "$frontmatter")
fi

# If slugs array is empty — vacuously satisfied.
if [[ "${#slugs[@]}" -eq 0 ]]; then
  jq -cn --arg trace "${HOOK_TRACE_ID}" \
    --arg msg "Empty source_ids list; citation check vacuously satisfied." \
    '{"continue":true,"trace":$trace,"message":$msg}'
  exit 0
fi

# ---------------------------------------------------------------------------
# Check that .brain/manifest.json exists and is readable — fail-closed.
# EC: missing manifest → E-WIKI-008.
# ---------------------------------------------------------------------------
manifest="${brain_dir}/.brain/manifest.json"
if [[ ! -r "$manifest" ]]; then
  jq -cn \
    --arg code "E-WIKI-008" \
    --arg msg "Cannot read .brain/manifest.json — source citation verification impossible." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source citation hook blocked: manifest not found at ${manifest}." >&2
  exit 2
fi

# Check manifest is valid JSON (fail-closed on malformed).
if ! jq empty "$manifest" 2>/dev/null; then
  jq -cn \
    --arg code "E-WIKI-008" \
    --arg msg "Cannot read .brain/manifest.json — source citation verification impossible." \
    --arg trace "${HOOK_TRACE_ID}" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":$code,"trace":$trace}}'
  echo "Source citation hook blocked: manifest malformed at ${manifest}." >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# For each slug in source_ids: check if it exists as a key in manifest.sources.
# Collect all unresolved slugs (AC-004: report ALL, not just first).
# ---------------------------------------------------------------------------
unresolved=()
for slug in "${slugs[@]}"; do
  # ADR-015: manifest.sources is an object keyed by full relative path
  # (e.g. "sources/ai/valid-source.md"). Convert the slug (e.g. "ai/valid-source")
  # to the full-path manifest key before lookup.
  manifest_key="sources/${slug}.md"
  exists="$(jq -r --arg key "$manifest_key" '.sources[$key] // empty' "$manifest")"
  if [[ -z "$exists" ]]; then
    unresolved+=("$slug")
    emit_event "source.citation.unresolved" "path=$relative_path" "missing_source_id=$slug"
  fi
done

# ---------------------------------------------------------------------------
# Decision: block if any unresolved, allow if all resolved.
# ---------------------------------------------------------------------------
if [[ "${#unresolved[@]}" -gt 0 ]]; then
  # Build a comma-separated list of unresolved slugs for the reason string.
  unresolved_list="${unresolved[0]}"
  for i in "${!unresolved[@]}"; do
    if [[ "$i" -gt 0 ]]; then
      unresolved_list="${unresolved_list}, ${unresolved[$i]}"
    fi
  done

  # Build the JSON array for hookSpecificOutput.unresolved.
  unresolved_json="$(printf '%s\n' "${unresolved[@]}" | jq -R . | jq -s .)"

  jq -cn \
    --arg msg "Unresolved source citations: ${unresolved_list}. No matching entries in manifest.json." \
    --arg trace "${HOOK_TRACE_ID}" \
    --argjson unresolved_arr "$unresolved_json" \
    '{"continue":false,"decision":"block","reason":$msg,"hookSpecificOutput":{"hookEventName":"PostToolUse","code":"E-WIKI-007","trace":$trace,"unresolved":$unresolved_arr}}'
  echo "Source citation hook blocked: unresolved source citations: ${unresolved_list}." >&2
  exit 2
fi

# All citations resolved — allow.
emit_event "source.citation.resolved" "path=$relative_path"
jq -cn --arg trace "${HOOK_TRACE_ID}" \
  --arg msg "All source citations resolved." \
  '{"continue":true,"trace":$trace,"message":$msg}'
exit 0
