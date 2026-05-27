#!/usr/bin/env bash
set -euo pipefail

# gen-test-corpus.sh — reproducible synthetic corpus generator
# Traces to: BC-2.16.006
# Usage: gen-test-corpus.sh [OPTIONS] <output-dir>

# ---------------------------------------------------------------------------
# LCG PRNG (Numerical Recipes: m=2^32, a=1664525, c=1013904223)
# $RANDOM must NOT be used — this is the only source of randomness.
#
# Design note: lcg_next() and lcg_range() mutate the global lcg_seed directly
# and store the result in lcg_result. Callers MUST NOT call these via $(...)
# subshells — subshells fork the process, so mutations to lcg_seed are lost
# and every call would return the same value. Use the global output variables:
#   lcg_next  → result in $lcg_seed
#   lcg_range → result in $lcg_result (lcg_seed also advanced)
# ---------------------------------------------------------------------------
lcg_seed=42
lcg_result=0

lcg_next() {
  lcg_seed=$(((1664525 * lcg_seed + 1013904223) & 0xFFFFFFFF))
}

lcg_range() {
  # Usage: lcg_range <max>  — stores value in [0, max) in $lcg_result
  local max="$1"
  lcg_next
  lcg_result=$((lcg_seed % max))
}

# ---------------------------------------------------------------------------
# Embedded wordlist (50 words)
# ---------------------------------------------------------------------------
WORDLIST=(
  "attention" "cognition" "framework" "synthesis" "concept"
  "network" "pattern" "insight" "strategy" "learning"
  "behavior" "context" "evidence" "practice" "research"
  "system" "process" "outcome" "feedback" "model"
  "theory" "language" "memory" "decision" "knowledge"
  "analysis" "method" "result" "domain" "value"
  "structure" "function" "relation" "effect" "factor"
  "measure" "signal" "cluster" "vector" "gradient"
  "feature" "target" "output" "input" "layer"
  "review" "source" "dataset" "baseline" "metric"
)
WORDLIST_LEN="${#WORDLIST[@]}"

# ---------------------------------------------------------------------------
# Script-level temp file tracker (cleaned up by EXIT trap in main)
# ---------------------------------------------------------------------------
_ENTRIES_FILE=""

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
SOURCES=100
SEED=42
TOPICS="ai,health,psychology,productivity,business,books,podcasts"
AVG_WORDS=3000
WIKI_RATIO=5
FORMAT="brain-vault"

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat >&2 <<'USAGE'
Usage: gen-test-corpus.sh [OPTIONS] <output-dir>

Options:
  --sources N       Number of source files (default: 100)
  --seed N          Deterministic seed (default: 42)
  --topics LIST     Comma-separated categories (default: ai,health,psychology,productivity,business,books,podcasts)
  --avg-words N     Average words per source (default: 3000)
  --wiki-ratio N    Wiki pages per source (default: 5)
  --format FORMAT   brain-vault (default) | json-manifest-only

Exit codes: 0 success; 1 error
USAGE
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
  --sources)
    SOURCES="$2"
    shift 2
    ;;
  --seed)
    SEED="$2"
    shift 2
    ;;
  --topics)
    TOPICS="$2"
    shift 2
    ;;
  --avg-words)
    AVG_WORDS="$2"
    shift 2
    ;;
  --wiki-ratio)
    WIKI_RATIO="$2"
    shift 2
    ;;
  --format)
    FORMAT="$2"
    shift 2
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  -*)
    echo "gen-test-corpus.sh: unknown option: $1" >&2
    usage
    exit 1
    ;;
  *)
    OUTPUT_DIR="$1"
    shift
    ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [[ -z "$OUTPUT_DIR" ]]; then
  echo "gen-test-corpus.sh: <output-dir> is required" >&2
  usage
  exit 1
fi

if [[ "$SOURCES" -lt 1 ]]; then
  echo "gen-test-corpus.sh: --sources N must be >= 1" >&2
  exit 1
fi

if [[ "$FORMAT" != "brain-vault" && "$FORMAT" != "json-manifest-only" ]]; then
  echo "gen-test-corpus.sh: --format must be brain-vault or json-manifest-only" >&2
  exit 1
fi

# AC-007: conflict check — existing sources/ in output dir
if [[ -d "$OUTPUT_DIR/sources" ]]; then
  echo "gen-test-corpus.sh: output directory already contains sources/ — will not overwrite existing files: $OUTPUT_DIR/sources" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Seed the LCG with the user-supplied --seed
# ---------------------------------------------------------------------------
lcg_seed="$SEED"

# ---------------------------------------------------------------------------
# Topic list → array
# ---------------------------------------------------------------------------
IFS=',' read -r -a TOPIC_ARRAY <<<"$TOPICS"
TOPIC_COUNT="${#TOPIC_ARRAY[@]}"

# ---------------------------------------------------------------------------
# Wiki type cycling list
# ---------------------------------------------------------------------------
WIKI_TYPES=("concepts" "people" "frameworks" "syntheses" "observations")
WIKI_TYPE_COUNT="${#WIKI_TYPES[@]}"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Generate approximately AVG_WORDS words of content using the LCG.
# Result is stored in the global _generated_content variable.
# MUST NOT be called via $(...) — that forks a subshell and loses lcg_seed state.
_generated_content=""

generate_content() {
  local word_count="$1"
  _generated_content=""
  local i
  for ((i = 0; i < word_count; i++)); do
    lcg_range "$WORDLIST_LEN"
    if ((i == 0)); then
      _generated_content="${WORDLIST[$lcg_result]}"
    else
      _generated_content="${_generated_content} ${WORDLIST[$lcg_result]}"
    fi
  done
}

# Zero-pad a number to 3 digits
zpad3() {
  printf '%03d' "$1"
}

# ---------------------------------------------------------------------------
# Generate source files
# ---------------------------------------------------------------------------
generate_sources() {
  local n="$1"   # total source count
  local out="$2" # output dir

  mkdir -p "$out/sources"

  local i=1
  while [[ $i -le n ]]; do
    local topic_idx
    topic_idx=$(((i - 1) % TOPIC_COUNT))
    local topic="${TOPIC_ARRAY[$topic_idx]}"
    local slug
    slug="source-$(zpad3 "$i")"
    local src_dir="$out/sources/$topic"
    mkdir -p "$src_dir"
    local src_file="$src_dir/$slug.md"

    generate_content "$AVG_WORDS"

    cat >"$src_file" <<FRONTMATTER
---
type: source
slug: $slug
topic: $topic
created_at: "2026-01-01T00:00:00Z"
immutability_hash: ""
---

$_generated_content
FRONTMATTER

    i=$((i + 1))
  done
}

# ---------------------------------------------------------------------------
# Generate manifest.json (N-1 entries; last source omitted)
# Uses a single jq invocation instead of O(n^2) iterative string-append.
# ---------------------------------------------------------------------------
generate_manifest() {
  local n="$1"   # total source count
  local out="$2" # output dir

  mkdir -p "$out/.brain"

  # Build entries as JSONL, then merge in one jq call (O(n) not O(n^2))
  # Use the script-level _ENTRIES_FILE so the script-level EXIT trap can clean up.
  _ENTRIES_FILE="$(mktemp)"
  local entries_file="$_ENTRIES_FILE"

  local i=1
  while [[ $i -le $((n - 1)) ]]; do
    local topic_idx
    topic_idx=$(((i - 1) % TOPIC_COUNT))
    local topic="${TOPIC_ARRAY[$topic_idx]}"
    local slug
    slug="source-$(zpad3 "$i")"
    local key="sources/${topic}/${slug}.md"

    printf '{"key":"%s","slug":"%s","topic":"%s"}\n' \
      "$key" "$slug" "$topic" >>"$entries_file"

    i=$((i + 1))
  done

  local last_updated="2026-01-01T00:00:00Z"

  jq -n --slurpfile entries "$entries_file" --arg last_updated "$last_updated" '
    {
      version: "1",
      sources: [
        $entries[] | {
          source_id: .slug,
          url: "",
          topic: .topic,
          ingested_at: "2026-01-01T00:00:00Z",
          last_ingest: "2026-01-01T00:00:00Z",
          chunks: [],
          embeddings_model: null
        }
      ],
      last_updated: $last_updated,
      embeddings_model: null,
      chunks: []
    }
  ' >"$out/.brain/manifest.json"

  rm -f "$entries_file"
}

# ---------------------------------------------------------------------------
# Generate wiki pages
# ---------------------------------------------------------------------------
generate_wiki() {
  local n="$1"     # total source count
  local out="$2"   # output dir
  local ratio="$3" # wiki pages per source

  mkdir -p "$out/wiki"

  local total_wiki=$((n * ratio))
  local i=1
  while [[ $i -le total_wiki ]]; do
    local type_idx
    type_idx=$(((i - 1) % WIKI_TYPE_COUNT))
    local wiki_type="${WIKI_TYPES[$type_idx]}"
    local wiki_dir="$out/wiki/$wiki_type"
    mkdir -p "$wiki_dir"

    local stub_file
    stub_file="$wiki_dir/stub-$(zpad3 "$i").md"
    cat >"$stub_file" <<WIKIFM
---
type: $wiki_type
title: "Stub $i"
embedding_status: pending
created_at: "2026-01-01T00:00:00Z"
---
WIKIFM

    i=$((i + 1))
  done
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
trap 'rm -f "$_ENTRIES_FILE"' EXIT

mkdir -p "$OUTPUT_DIR"

if [[ "$FORMAT" == "json-manifest-only" ]]; then
  generate_manifest "$SOURCES" "$OUTPUT_DIR"
else
  generate_sources "$SOURCES" "$OUTPUT_DIR"
  generate_manifest "$SOURCES" "$OUTPUT_DIR"
  generate_wiki "$SOURCES" "$OUTPUT_DIR" "$WIKI_RATIO"
fi

exit 0
