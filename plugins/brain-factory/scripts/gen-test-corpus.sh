#!/usr/bin/env bash
set -euo pipefail

# gen-test-corpus.sh — reproducible synthetic corpus generator
# Traces to: BC-2.16.006
# Usage: gen-test-corpus.sh [OPTIONS] <output-dir>

# ---------------------------------------------------------------------------
# LCG PRNG (Numerical Recipes: m=2^32, a=1664525, c=1013904223)
# $RANDOM must NOT be used — this is the only source of randomness.
# ---------------------------------------------------------------------------
lcg_seed=42

lcg_next() {
  lcg_seed=$(((1664525 * lcg_seed + 1013904223) & 0xFFFFFFFF))
  echo "$lcg_seed"
}

lcg_range() {
  # Usage: lcg_range <max>  — returns a value in [0, max)
  local max="$1"
  local val
  val="$(lcg_next)"
  echo $((val % max))
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

# Generate approximately AVG_WORDS words of content using the LCG
generate_content() {
  local word_count="$AVG_WORDS"
  local words=()
  local i=0
  while [[ $i -lt word_count ]]; do
    local idx
    idx="$(lcg_range "$WORDLIST_LEN")"
    words+=("${WORDLIST[$idx]}")
    i=$((i + 1))
  done
  echo "${words[*]}"
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

    local content
    content="$(generate_content)"

    cat >"$src_file" <<FRONTMATTER
---
type: source
slug: $slug
topic: $topic
created_at: "2026-01-01T00:00:00Z"
immutability_hash: ""
---

$content
FRONTMATTER

    i=$((i + 1))
  done
}

# ---------------------------------------------------------------------------
# Generate manifest.json (N-1 entries; last source omitted)
# ---------------------------------------------------------------------------
generate_manifest() {
  local n="$1"   # total source count
  local out="$2" # output dir

  mkdir -p "$out/.brain"

  # Build jq args: N-1 entries (indices 1..N-1)
  local jq_sources='{}'
  local i=1
  while [[ $i -le $((n - 1)) ]]; do
    local topic_idx
    topic_idx=$(((i - 1) % TOPIC_COUNT))
    local topic="${TOPIC_ARRAY[$topic_idx]}"
    local slug
    slug="source-$(zpad3 "$i")"
    local key="sources/$topic/$slug.md"

    jq_sources="$(
      echo "$jq_sources" | jq \
        --arg k "$key" \
        --arg slug "$slug" \
        --arg topic "$topic" \
        '. + {($k): {"slug": $slug, "topic": $topic, "ingested_at": "2026-01-01T00:00:00Z", "chunks": [], "embeddings_model": null}}'
    )"

    i=$((i + 1))
  done

  jq -n \
    --argjson sources "$jq_sources" \
    '{"brain_version": "0.1.0", "sources": $sources}' \
    >"$out/.brain/manifest.json"
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
mkdir -p "$OUTPUT_DIR"

if [[ "$FORMAT" == "json-manifest-only" ]]; then
  generate_manifest "$SOURCES" "$OUTPUT_DIR"
else
  generate_sources "$SOURCES" "$OUTPUT_DIR"
  generate_manifest "$SOURCES" "$OUTPUT_DIR"
  generate_wiki "$SOURCES" "$OUTPUT_DIR" "$WIKI_RATIO"
fi

exit 0
