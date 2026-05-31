#!/usr/bin/env bash
set -euo pipefail

# generate-wiki.sh
# Wiki page generation orchestrator.
# Parses a source file and generates 5-15 wiki pages under wiki/{type}/.
#
# Usage: generate-wiki.sh <brain_dir> <source_file_path> [event_prefix]
#
#   event_prefix — optional; prefix for the wiki_pages_generated structured event.
#                  Defaults to "ingest.url" for backward compatibility.
#                  Pass "ingest.source" when called from /brain:ingest-source.
#
# Stdout: JSON fan-out envelope {"pages_attempted": N, "pages_created": M, "pages_failed": K, "failures": [...]}
# Stderr: structured events ({event_prefix}.wiki_pages_generated) + E-INGEST-006 advisory (<5 pages)
#
# Exit codes:
#   0 — all pages succeeded (or < 5 pages: advisory emitted but still exits 0)
#   1 — partial failure (some pages failed)

BRAIN_DIR="${1:?Usage: generate-wiki.sh <brain_dir> <source_file_path>}"
SOURCE_FILE="${2:?Usage: generate-wiki.sh <brain_dir> <source_file_path>}"
EVENT_PREFIX="${3:-ingest.url}"

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HELPER="${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"

if [ ! -f "$HELPER" ]; then
  printf '{"ts":"%s","event_type":"hook.helper.missing","hook_name":"%s","trace":"00000000-0000-0000-0000-000000000000","code":"E-HOOK-002","reason":"hook-event-emit.sh not found"}\n' \
    "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" "${BASH_SOURCE[0]##*/}" >&2
  exit 1
fi
# shellcheck source=/dev/null
source "$HELPER"

# ---------------------------------------------------------------------------
# Extract source metadata from frontmatter
# ---------------------------------------------------------------------------
SOURCE_SLUG="$(yq eval '.source_id // ""' "$SOURCE_FILE" 2>/dev/null || true)"
SOURCE_TITLE="$(yq eval '.title // ""' "$SOURCE_FILE" 2>/dev/null || true)"

if [ -z "$SOURCE_SLUG" ]; then
  SOURCE_SLUG="$(basename "$SOURCE_FILE" .md)"
fi
if [ -z "$SOURCE_TITLE" ]; then
  SOURCE_TITLE="$SOURCE_SLUG"
fi

# Extract body content (after frontmatter)
BODY="$(awk '
  BEGIN { in_fm = 0; past_fm = 0; fence = 0 }
  /^---$/ && fence < 2 {
    fence++
    if (fence == 1) { in_fm = 1; next }
    if (fence == 2) { in_fm = 0; past_fm = 1; next }
  }
  past_fm { print }
' "$SOURCE_FILE")"

# ---------------------------------------------------------------------------
# _to_slug <string>
# Convert a string to kebab-case slug
# ---------------------------------------------------------------------------
_to_slug() {
  printf '%s' "$1" |
    tr '[:upper:]' '[:lower:]' |
    tr -cs '[:alnum:]-' '-' |
    sed 's/^-*//;s/-*$//'
}

# ---------------------------------------------------------------------------
# _write_wiki_page <type> <slug> <title>
# Writes one wiki page; returns 0 on success, 1 on collision, 2 on fail
# ---------------------------------------------------------------------------
_write_wiki_page() {
  local page_type="$1"
  local page_slug="$2"
  local page_title="$3"
  local page_dir="${BRAIN_DIR}/wiki/${page_type}"
  local page_path="${page_dir}/${page_slug}.md"

  # Ensure wiki type directory exists; guard failure as per-page failure
  local mkdir_err_file
  mkdir_err_file="$(mktemp)"
  if ! mkdir -p "$page_dir" 2>"$mkdir_err_file"; then
    LAST_WRITE_ERR="$(cat "$mkdir_err_file" 2>/dev/null || true)"
    rm -f "$mkdir_err_file"
    return 2
  fi
  rm -f "$mkdir_err_file"

  # Slug collision check: existing file is a FAILED page (BC-2.03.004)
  if [ -f "$page_path" ]; then
    return 1
  fi

  # Escape double quotes in title to produce valid YAML
  local safe_title="${page_title//\"/\\\"}"

  # Attempt to write the page.
  # Capture stderr from the write attempt to propagate actionable diagnostics
  # into the failure entry (I2: no blanket 2>/dev/null suppression).
  local write_err_file
  write_err_file="$(mktemp)"
  if ! cat >"$page_path" 2>"$write_err_file" <<PAGEEOF; then
---
title: "${safe_title}"
type: ${page_type}
embedding_status: pending
source_ids: [${SOURCE_SLUG}]
---

# ${page_title}

*Generated from source: [[${SOURCE_SLUG}]]*
PAGEEOF
    LAST_WRITE_ERR="$(cat "$write_err_file" 2>/dev/null || true)"
    rm -f "$write_err_file"
    return 2
  fi
  rm -f "$write_err_file"

  return 0
}

# ---------------------------------------------------------------------------
# Derive candidate wiki pages from source content
#
# Strategy:
#   1. H2 section headings → concepts or syntheses
#   2. Capitalized "Name Name" patterns in body → people
#   3. Tool/framework names from known patterns → frameworks
#   4. Synthesized observation from title → observations
#   5. Question derived from title → questions
# ---------------------------------------------------------------------------

# Arrays for candidate pages: parallel arrays of type and title
PAGE_TYPES=()
PAGE_TITLES=()

# 1. Extract H2 section headings from body → concepts/syntheses
while IFS= read -r heading; do
  # Strip "## " prefix
  title="${heading#\#\# }"
  title="${title#\# }"
  if [ -n "$title" ] && [ "$title" != "Key Components" ]; then
    if [[ "$title" == *"Scaling"* ]] || [[ "$title" == *"Application"* ]] ||
      [[ "$title" == *"Synthes"* ]] || [[ "$title" == *"Overview"* ]]; then
      PAGE_TYPES+=("syntheses")
    else
      PAGE_TYPES+=("concepts")
    fi
    PAGE_TITLES+=("$title")
  fi
done < <(printf '%s\n' "$BODY" | grep -E '^#{1,2} ' | head -8)

# 2. Extract capitalized names (likely people: "FirstName LastName" pattern)
# Only match at word boundaries: preceded by start-of-line or space (not CamelCase compounds).
# Exclude common org/location/concept names and short stop-words.
while IFS= read -r name; do
  if [ -n "$name" ]; then
    PAGE_TYPES+=("people")
    PAGE_TITLES+=("$name")
  fi
done < <(printf '%s\n' "$BODY" |
  grep -oE '(^|[ \t])[A-Z][a-z]{2,} [A-Z][a-z]{2,}' |
  sed 's/^[[:space:]]*//' |
  grep -v '^The \|^In \|^Is \|^This \|^These \|^Each \|^All \|^For \|^With \|^From \|^By \|^At \|^On \|^Of \|^Key \|^Main \|^Self \|^Large \|^Multi \|^Deep \|^Open \|^Pre \|^Post \|^Flash \|^Vision \|^Deep \|^Modern ' |
  grep -v 'Brain\|Brain$\|Networks\|Models\|Learning\|Language\|Attention\|Training\|Transformers\|Framework\|System\|Architecture\|Research\|Position\|Scale\|Code' |
  sort -u | head -4)

# 3. Extract tool/framework names using section content
# Look for known framework/tool indicators in the body
while IFS= read -r tool; do
  if [ -n "$tool" ]; then
    PAGE_TYPES+=("frameworks")
    PAGE_TITLES+=("$tool")
  fi
done < <(printf '%s\n' "$BODY" | grep -oE '\b(PyTorch|JAX|HuggingFace|FlashAttention|DeepSpeed|TensorFlow|Transformers|BERT|GPT|ViT)\b' |
  sort -u | head -4)

# 4. Synthesize an observation page from source title
OBS_TITLE="Key Insights from: ${SOURCE_TITLE}"
PAGE_TYPES+=("observations")
PAGE_TITLES+=("$OBS_TITLE")

# 5. Generate a question page from source title
Q_TITLE="Open Questions on ${SOURCE_TITLE}"
PAGE_TYPES+=("questions")
PAGE_TITLES+=("$Q_TITLE")

# If source title is non-trivial, also add a concept page for the topic itself
if [ -n "$SOURCE_TITLE" ] && [ "$SOURCE_TITLE" != "$SOURCE_SLUG" ]; then
  PAGE_TYPES+=("concepts")
  PAGE_TITLES+=("$SOURCE_TITLE")
fi

# ---------------------------------------------------------------------------
# Write pages with fan-out error handling
# Limit to 15 pages maximum (BC-2.02.002 postcondition 1: 5-15 pages)
# ---------------------------------------------------------------------------
MAX_PAGES=15
PAGES_ATTEMPTED=0
PAGES_CREATED=0
PAGES_FAILED=0
FAILURES=()
HAD_FAILURE=0
LAST_WRITE_ERR=""
write_diag=""

declare -A SEEN_SLUGS
declare -a CREATED_SLUGS
declare -a CREATED_TYPES

for i in "${!PAGE_TITLES[@]}"; do
  # Stop if we've already attempted the maximum
  if [ "$PAGES_ATTEMPTED" -ge "$MAX_PAGES" ]; then
    break
  fi

  page_title="${PAGE_TITLES[$i]}"
  page_type="${PAGE_TYPES[$i]}"
  page_slug="$(_to_slug "$page_title")"

  # Skip empty slugs
  if [ -z "$page_slug" ]; then
    continue
  fi

  # Skip duplicate slugs within this run
  if [ -n "${SEEN_SLUGS[$page_slug]+x}" ]; then
    continue
  fi
  SEEN_SLUGS["$page_slug"]=1

  PAGES_ATTEMPTED=$((PAGES_ATTEMPTED + 1))

  # Attempt to write the page
  write_result=0
  _write_wiki_page "$page_type" "$page_slug" "$page_title" || write_result=$?

  case "$write_result" in
  0)
    PAGES_CREATED=$((PAGES_CREATED + 1))
    CREATED_SLUGS+=("$page_slug")
    CREATED_TYPES+=("$page_type")
    ;;
  1)
    # Slug collision — counts as a FAILED page (BC-2.03.004); invariant: attempted = created + failed
    PAGES_FAILED=$((PAGES_FAILED + 1))
    HAD_FAILURE=1
    FAILURES+=("$(jq -n \
      --arg slug "$page_slug" \
      --arg type "$page_type" \
      --arg error "E-INGEST-014: Wiki page generation failed for '${page_slug}': slug already exists. Other pages preserved." \
      '{slug:$slug,type:$type,error:$error}')")
    ;;
  *)
    # Write failure — capture diagnostics from LAST_WRITE_ERR (set by _write_wiki_page)
    PAGES_FAILED=$((PAGES_FAILED + 1))
    HAD_FAILURE=1
    write_diag="${LAST_WRITE_ERR:-write failed}"
    LAST_WRITE_ERR=""
    FAILURES+=("$(jq -n \
      --arg slug "$page_slug" \
      --arg type "$page_type" \
      --arg error "E-INGEST-014: Wiki page generation failed for '${page_slug}': ${write_diag}. Other pages preserved." \
      '{slug:$slug,type:$type,error:$error}')")
    ;;
  esac
done

# ---------------------------------------------------------------------------
# Update wiki/index.md and wiki/log.md
# ---------------------------------------------------------------------------
INDEX_FILE="${BRAIN_DIR}/wiki/index.md"
LOG_FILE="${BRAIN_DIR}/wiki/log.md"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

if [ -f "$INDEX_FILE" ] && [ "$PAGES_CREATED" -gt 0 ]; then
  printf '\n## Ingest: %s (%s)\n' "$SOURCE_SLUG" "$NOW" >>"$INDEX_FILE"
  for i in "${!CREATED_SLUGS[@]}"; do
    printf '%s\n' "- [[${CREATED_SLUGS[$i]}]] (${CREATED_TYPES[$i]})" >>"$INDEX_FILE"
  done
fi

if [ -f "$LOG_FILE" ]; then
  printf '\n## %s — %s\n' "$NOW" "$SOURCE_SLUG" >>"$LOG_FILE"
  printf 'Pages created: %d, failed: %d\n' "$PAGES_CREATED" "$PAGES_FAILED" >>"$LOG_FILE"
fi

# ---------------------------------------------------------------------------
# Build failures JSON array via jq (safe: no string concatenation)
# ---------------------------------------------------------------------------
FAILURES_JSON="$(
  if [ "${#FAILURES[@]}" -eq 0 ]; then
    printf '[]'
  else
    # Each element in FAILURES is a valid JSON object produced by jq -n above.
    # Collect them as a newline-delimited stream and slurp into an array.
    printf '%s\n' "${FAILURES[@]}" | jq -s '.'
  fi
)"

# ---------------------------------------------------------------------------
# Emit structured event on stderr (CLAUDE.md §Logging: structured events on stderr)
# ---------------------------------------------------------------------------
emit_event "${EVENT_PREFIX}.wiki_pages_generated" \
  "source_id=${SOURCE_SLUG}" \
  "pages_created=${PAGES_CREATED}" \
  "pages_failed=${PAGES_FAILED}"

# ---------------------------------------------------------------------------
# Emit E-INGEST-006 advisory on stderr if fewer than 5 pages produced
# ---------------------------------------------------------------------------
if [ "$PAGES_CREATED" -lt 5 ]; then
  printf '{"level":"warn","code":"E-INGEST-006","message":"Fewer than 5 wiki pages generated (%d). Source may have limited extractable concepts."}\n' \
    "$PAGES_CREATED" >&2
fi

# ---------------------------------------------------------------------------
# Output fan-out envelope on stdout (built via jq for safety)
# ---------------------------------------------------------------------------
jq -n \
  --argjson attempted "$PAGES_ATTEMPTED" \
  --argjson created "$PAGES_CREATED" \
  --argjson failed "$PAGES_FAILED" \
  --argjson failures "$FAILURES_JSON" \
  '{pages_attempted:$attempted,pages_created:$created,pages_failed:$failed,failures:$failures}'

# ---------------------------------------------------------------------------
# Exit code: 1 if any failure (write failure OR slug collision); 0 if all success
# BC-2.03.004: slug collision is a FAILED page; pages_failed > 0 → exit 1
# ---------------------------------------------------------------------------
if [ "$HAD_FAILURE" -eq 1 ]; then
  exit 1
fi

exit 0
