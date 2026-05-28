#!/usr/bin/env bash
set -euo pipefail

# /brain:health — six-dimensional convergence health check
# Usage: BRAIN_ROOT=/path/to/brain bash run.sh
# Env vars:
#   BRAIN_ROOT — target directory (default: $PWD)
#
# Exit codes:
#   0 — success (JSON health report emitted to stdout)
#   2 — unrecoverable error (E-HEALTH-001: STATE.md missing or unreadable)
#
# BC-2.01.006 | STORY-004

BRAIN_ROOT="${BRAIN_ROOT:-$PWD}"

# Token budget constants (BC-2.01.006 Architecture Compliance Rule 4).
# Changing these requires a BC update.
# shellcheck disable=SC2034
readonly TOKEN_BASELINE=50000          # 50K tokens — baseline reference, not evaluated at runtime
readonly TOKEN_YELLOW_THRESHOLD=100000 # 2x baseline
readonly TOKEN_RED_THRESHOLD=200000    # 4x baseline

# ---------------------------------------------------------------------------
# _health_error: emit ADR-002 JSON error envelope to stdout and exit 2
# ---------------------------------------------------------------------------
_health_error() {
  local code="$1" message="$2"
  local trace
  if trace="$(/usr/bin/uuidgen 2>/dev/null)"; then
    :
  elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    trace="$(</proc/sys/kernel/random/uuid)"
  else
    trace="${RANDOM}-${RANDOM}-${RANDOM}-${RANDOM}"
  fi
  # JSON-escape the message: backslash first, then double-quote, then control chars.
  message="${message//\\/\\\\}"
  message="${message//\"/\\\"}"
  message="${message//$'\t'/\\t}"
  message="${message//$'\n'/\\n}"
  printf '{"level":"error","code":"%s","message":"%s","trace":"%s"}\n' \
    "$code" "$message" "$trace"
  exit 2
}

# ---------------------------------------------------------------------------
# Pre-flight check: .brain/STATE.md must exist and be readable.
# AC-006 / BC-2.01.006 edge case EC-002
# ---------------------------------------------------------------------------
state_file="${BRAIN_ROOT}/.brain/STATE.md"

if [[ ! -f "$state_file" ]]; then
  _health_error "E-HEALTH-001" \
    "Brain state file missing — run \`/brain:init\` or \`/brain:cold-start-recover\`."
fi

# ---------------------------------------------------------------------------
# Dimension: capture
# RED  — inbox/ directory missing
# YELLOW — inbox/ has > 50 items
# GREEN  — otherwise
# ---------------------------------------------------------------------------
capture_status="GREEN"
capture_detail="Inbox directory healthy."

if [[ ! -d "${BRAIN_ROOT}/inbox" ]]; then
  capture_status="RED"
  capture_detail="Inbox directory missing — run /brain:init to repair."
else
  inbox_count=0
  while IFS= read -r -d '' _file; do
    inbox_count=$((inbox_count + 1))
  done < <(find "${BRAIN_ROOT}/inbox" -maxdepth 1 -mindepth 1 -print0 2>/dev/null)
  if [[ "$inbox_count" -gt 50 ]]; then
    capture_status="YELLOW"
    capture_detail="${inbox_count} items in inbox — run /brain:inbox-review to process."
  fi
fi

# ---------------------------------------------------------------------------
# Dimension: sources
# RED    — manifest.json missing or invalid JSON
# RED    — 30-day token avg > TOKEN_RED_THRESHOLD
# YELLOW — 30-day token avg > TOKEN_YELLOW_THRESHOLD (and ≤ RED threshold)
# GREEN  — ingest-tokens.jsonl missing → EC-001 (brand-new brain, no history yet)
# YELLOW — ingest-tokens.jsonl exists but source_count=0
# GREEN  — manifest valid, token avg ≤ TOKEN_YELLOW_THRESHOLD
#
# Precedence: manifest errors → token budget → source count → GREEN/history message
# ---------------------------------------------------------------------------
sources_status="GREEN"
sources_detail=""
source_count=0

manifest_file="${BRAIN_ROOT}/.brain/manifest.json"
if [[ ! -f "$manifest_file" ]]; then
  sources_status="RED"
  sources_detail="manifest.json missing — brain data index is corrupt. Run /brain:init to repair."
else
  # Validate JSON and extract source count.
  if ! source_count="$(jq '.sources | length' "$manifest_file" 2>/dev/null)"; then
    sources_status="RED"
    sources_detail="manifest.json is invalid JSON — brain data index is corrupt."
  fi
fi

# Token budget check (only when sources dimension is not already RED from manifest).
# AC-005 / BC-2.01.006 postcondition 4
# Architecture Compliance Rule 5: use awk (not jq) to parse JSONL.
token_log="${BRAIN_ROOT}/.brain/logs/ingest-tokens.jsonl"
if [[ "$sources_status" != "RED" ]]; then
  if [[ ! -f "$token_log" ]]; then
    # AC-004 / EC-001: missing log → GREEN (brand-new brain with no ingest history).
    # Source count is NOT checked when no token log exists — this is the brand-new state.
    sources_status="GREEN"
    sources_detail="No ingest history yet."
  else
    # Token log exists: compute 30-day trailing average using awk.
    # Each JSONL line format: {"date":"YYYY-MM-DD","tokens":NNN,...}
    # Extract "tokens" field value using awk field-split on '"tokens":'.
    cutoff_date="$(date -u -v-30d +%Y-%m-%d 2>/dev/null || date -u -d '-30 days' +%Y-%m-%d 2>/dev/null || date -u +%Y-%m-%d)"

    token_avg=0
    token_avg="$(awk -F'"tokens":' -v cutoff="$cutoff_date" '
      NF > 1 {
        # Extract date from the line: split on "date":" to get the date value
        n = split($0, parts, "\"date\":\"")
        if (n > 1) {
          date_val = substr(parts[2], 1, 10)
        } else {
          date_val = ""
        }
        # Extract tokens value: take field 2, extract leading integer
        tok = $2
        gsub(/[^0-9].*/, "", tok)
        tok_num = tok + 0
        # Include only entries within the 30-day window
        if (date_val >= cutoff && tok_num > 0) {
          total += tok_num
          count++
        }
      }
      END {
        if (count > 0) {
          printf "%d", total / count
        } else {
          printf "0"
        }
      }
    ' "$token_log" 2>/dev/null)" || token_avg=0

    if [[ "$token_avg" -gt "$TOKEN_RED_THRESHOLD" ]]; then
      sources_status="RED"
      sources_detail="30-day trailing average ${token_avg} tokens: token budget critical (exceeds 4x baseline ${TOKEN_RED_THRESHOLD}). Reduce ingest frequency."
    elif [[ "$token_avg" -gt "$TOKEN_YELLOW_THRESHOLD" ]]; then
      sources_status="YELLOW"
      sources_detail="30-day trailing average ${token_avg} tokens: token budget alert (exceeds 2x baseline ${TOKEN_YELLOW_THRESHOLD})."
    elif [[ "$source_count" -eq 0 ]]; then
      # Token log exists but no sources in manifest → YELLOW.
      sources_status="YELLOW"
      sources_detail="No sources ingested yet — run /brain:ingest-url or /brain:ingest-pdf."
    else
      sources_status="GREEN"
      sources_detail="${source_count} source(s) indexed."
    fi
  fi
fi

# ---------------------------------------------------------------------------
# Dimension: wiki
# YELLOW — 0 markdown files under wiki/ (excluding index.md, log.md, _template.md)
# GREEN  — ≥1 real wiki page found
# ---------------------------------------------------------------------------
wiki_status="GREEN"
wiki_detail="Wiki pages indexed."

wiki_count=0
if [[ -d "${BRAIN_ROOT}/wiki" ]]; then
  while IFS= read -r -d '' wiki_file; do
    base="$(basename "$wiki_file")"
    if [[ "$base" != "index.md" && "$base" != "log.md" && "$base" != _template* ]]; then
      wiki_count=$((wiki_count + 1))
    fi
  done < <(find "${BRAIN_ROOT}/wiki" -name "*.md" -print0 2>/dev/null)
fi

if [[ "$wiki_count" -eq 0 ]]; then
  wiki_status="YELLOW"
  wiki_detail="No wiki pages yet — ingest your first source."
fi

# ---------------------------------------------------------------------------
# Dimension: synthesis
# YELLOW — 0 files in briefs/weekly/
# GREEN  — ≥1 file present
# ---------------------------------------------------------------------------
synthesis_status="GREEN"
synthesis_detail="Weekly briefs present."

synthesis_count=0
if [[ -d "${BRAIN_ROOT}/briefs/weekly" ]]; then
  while IFS= read -r -d '' _sfile; do
    synthesis_count=$((synthesis_count + 1))
  done < <(find "${BRAIN_ROOT}/briefs/weekly" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
fi

if [[ "$synthesis_count" -eq 0 ]]; then
  synthesis_status="YELLOW"
  synthesis_detail="No weekly briefs yet — run /brain:weekly-synthesis to generate."
fi

# ---------------------------------------------------------------------------
# Dimension: output
# YELLOW — 0 files in briefs/content/
# GREEN  — ≥1 file present
# ---------------------------------------------------------------------------
output_status="GREEN"
output_detail="Content briefs present."

output_count=0
if [[ -d "${BRAIN_ROOT}/briefs/content" ]]; then
  while IFS= read -r -d '' _ofile; do
    output_count=$((output_count + 1))
  done < <(find "${BRAIN_ROOT}/briefs/content" -mindepth 1 -maxdepth 1 -print0 2>/dev/null)
fi

if [[ "$output_count" -eq 0 ]]; then
  output_status="YELLOW"
  output_detail="No content briefs yet — run /brain:draft-content-brief to generate."
fi

# ---------------------------------------------------------------------------
# Dimension: reflection
# YELLOW — STATE.md exists but is empty
# GREEN  — STATE.md exists and non-empty
# (RED case for missing STATE.md handled above in pre-flight — never reaches here)
# ---------------------------------------------------------------------------
reflection_status="GREEN"
reflection_detail="Brain state file healthy."

if [[ ! -s "$state_file" ]]; then
  reflection_status="YELLOW"
  reflection_detail="Brain STATE.md is empty — run /brain:health --repair to rebuild."
fi

# ---------------------------------------------------------------------------
# Aggregate: overall = RED if any RED; YELLOW if any YELLOW and no RED; else GREEN.
# AC-002 / BC-2.01.006 postcondition 3 / invariant 1
# ---------------------------------------------------------------------------
overall="GREEN"
for dim_status in "$capture_status" "$sources_status" "$wiki_status" \
  "$synthesis_status" "$output_status" "$reflection_status"; do
  if [[ "$dim_status" == "RED" ]]; then
    overall="RED"
    break
  fi
done

if [[ "$overall" != "RED" ]]; then
  for dim_status in "$capture_status" "$sources_status" "$wiki_status" \
    "$synthesis_status" "$output_status" "$reflection_status"; do
    if [[ "$dim_status" == "YELLOW" ]]; then
      overall="YELLOW"
      break
    fi
  done
fi

# ---------------------------------------------------------------------------
# Emit JSON report to stdout.
# AC-001 / BC-2.01.006 postconditions 1-2
# ---------------------------------------------------------------------------
last_checked="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq -nc \
  --arg capture_status "$capture_status" \
  --arg capture_detail "$capture_detail" \
  --arg sources_status "$sources_status" \
  --arg sources_detail "$sources_detail" \
  --arg wiki_status "$wiki_status" \
  --arg wiki_detail "$wiki_detail" \
  --arg synthesis_status "$synthesis_status" \
  --arg synthesis_detail "$synthesis_detail" \
  --arg output_status "$output_status" \
  --arg output_detail "$output_detail" \
  --arg reflection_status "$reflection_status" \
  --arg reflection_detail "$reflection_detail" \
  --arg overall "$overall" \
  --arg last_checked "$last_checked" \
  '{
    "dimensions": {
      "capture":    {"status": $capture_status,    "detail": $capture_detail},
      "sources":    {"status": $sources_status,    "detail": $sources_detail},
      "wiki":       {"status": $wiki_status,       "detail": $wiki_detail},
      "synthesis":  {"status": $synthesis_status,  "detail": $synthesis_detail},
      "output":     {"status": $output_status,     "detail": $output_detail},
      "reflection": {"status": $reflection_status, "detail": $reflection_detail}
    },
    "overall": $overall,
    "last_checked": $last_checked
  }'

exit 0
