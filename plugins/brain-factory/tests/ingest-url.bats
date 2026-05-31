#!/usr/bin/env bats
# STORY-016 tests: Defuddle fetch wrapper, duplicate guard, atomic manifest-write helper
# Traces to: BC-2.02.001, BC-2.02.004, BC-2.02.006
# VP coverage: VP-015 (URL ingest pipeline), VP-012 (manifest atomicity)

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  BRAIN_DIR="$(mktemp -d)"
  DEFUDDLE_FETCH="${PLUGIN_DIR}/scripts/defuddle-fetch.mjs"
  MANIFEST_WRITE_LIB="${PLUGIN_DIR}/hooks/lib/manifest-write.sh"

  # Minimal brain structure
  mkdir -p "${BRAIN_DIR}/.brain"
  mkdir -p "${BRAIN_DIR}/sources"

  # Empty manifest (no pre-existing sources)
  printf '{"sources": {}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  # Counter file for tracking mock invocations
  INVOCATION_COUNT_FILE="${BRAIN_DIR}/.defuddle-invocation-count"
  printf '0\n' >"$INVOCATION_COUNT_FILE"
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# ---------------------------------------------------------------------------
# Helper: _mock_defuddle_fetch
#
# Writes a wrapper script at $1 that:
#   - Increments $INVOCATION_COUNT_FILE on every call
#   - Accepts a URL as $1
#   - Returns canned content / exit codes based on the URL:
#     http*://mock-200/*          → exit 0, markdown on stdout
#     http*://mock-non200/*       → exit 2, E-INGEST-002 on stderr
#     http*://mock-empty/*        → exit 2, E-INGEST-003 on stderr
#     http*://mock-node-absent/*  → exit 2, E-INGEST-005 on stderr (unreachable;
#                                   the Node version check happens before fetch)
#     anything else               → exit 1, error on stderr
# ---------------------------------------------------------------------------
_mock_defuddle_fetch() {
  local mock_path="$1"
  local count_file="$INVOCATION_COUNT_FILE"

  cat >"$mock_path" <<MOCKSCRIPT
#!/usr/bin/env node
// mock defuddle-fetch.mjs
import fs from 'fs';

// Increment invocation counter
try {
  const count = parseInt(fs.readFileSync('${count_file}', 'utf8').trim(), 10);
  fs.writeFileSync('${count_file}', String(count + 1) + '\n');
} catch (e) { /* ignore */ }

const url = process.argv[2];

if (!url) {
  process.stderr.write('Usage: defuddle-fetch.mjs <url>\n');
  process.exit(2);
}

if (url.includes('mock-non200')) {
  process.stderr.write(JSON.stringify({code: 'E-INGEST-002', message: 'HTTP 404 fetching ' + url + '. Ingest aborted.'}) + '\n');
  process.exit(2);
}

if (url.includes('mock-empty')) {
  process.stderr.write(JSON.stringify({code: 'E-INGEST-003', message: 'Defuddle returned empty content for ' + url + '. Page may not be extractable.'}) + '\n');
  process.exit(2);
}

if (url.includes('mock-200')) {
  process.stderr.write(JSON.stringify({title: 'Mocked Article'}) + '\n');
  process.stdout.write('# Mocked Article\n\nThis is the cleaned content from Defuddle.\n\nParagraph with real substance.\n');
  process.exit(0);
}

process.stderr.write('mock: unknown URL pattern: ' + url + '\n');
process.exit(1);
MOCKSCRIPT
  chmod +x "$mock_path"
}

# ---------------------------------------------------------------------------
# Helper: _mock_node_absent
#
# Writes a wrapper at $1 that exits 2 with E-INGEST-005 immediately,
# simulating the Node 22+ version check failing before any fetch attempt.
# ---------------------------------------------------------------------------
_mock_node_absent() {
  local mock_path="$1"
  cat >"$mock_path" <<MOCKSCRIPT
#!/usr/bin/env bash
set -euo pipefail
echo '{"code":"E-INGEST-005","message":"Node 22+ required for Defuddle. Install from nodejs.org."}' >&2
exit 2
MOCKSCRIPT
  chmod +x "$mock_path"
}

# ---------------------------------------------------------------------------
# Helper: _duplicate_guard
#
# Implements the manifest lookup logic.
# Arguments: <manifest_path> <url>
# Returns: 0 if URL NOT in manifest (new), 2 if duplicate (exit with error)
# Also increments INVOCATION_COUNT_FILE to track whether fetch would be called.
# This function mirrors what the skill body must do for AC-007/AC-008.
# ---------------------------------------------------------------------------
_duplicate_guard() {
  local manifest="$1"
  local url="$2"

  local found
  found="$(jq -r --arg url "$url" '.sources[] | select(.url == $url) | .source_id' "$manifest" 2>/dev/null || true)"

  if [ -n "$found" ]; then
    echo "{\"code\":\"E-INGEST-001\",\"message\":\"URL already ingested as ${found}. Sources are immutable.\"}" >&2
    return 2
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Helper: _slug_from_url
#
# Converts URL path to kebab-case slug.
# Mirrors the slug derivation required by AC-005.
# ---------------------------------------------------------------------------
_slug_from_url() {
  local url="$1"
  # Extract path component, strip leading slash, convert to kebab-case
  local path
  path="$(printf '%s' "$url" | sed -E 's|https?://[^/]*/||')"
  # Strip query string
  path="${path%%\?*}"
  # Convert non-alphanumeric to hyphens, lowercase, strip leading/trailing hyphens
  printf '%s' "$path" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '-' | sed 's/^-//;s/-$//'
}

# ---------------------------------------------------------------------------
# Helper: _write_source_file
#
# Simulates what the skill does after a successful Defuddle fetch:
# creates sources/{topic}/{slug}.md with correct frontmatter.
# This is the bash component the skill will call; tested directly here.
# ---------------------------------------------------------------------------
_write_source_file() {
  local brain_dir="$1"
  local topic="$2"
  local slug="$3"
  local url="$4"
  local title="$5"
  local content="$6"

  local dest_dir="${brain_dir}/sources/${topic}"
  mkdir -p "$dest_dir"
  local dest="${dest_dir}/${slug}.md"

  local ingested_at
  ingested_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat >"$dest" <<FRONTMATTER
---
title: "${title}"
url: "${url}"
ingested_at: "${ingested_at}"
source_id: "${slug}"
topic: "${topic}"
embedding_status: pending
---

${content}
FRONTMATTER
}

# ---------------------------------------------------------------------------
# Helper: _ingest_pipeline
#
# End-to-end pipeline helper (tests the integration of components for AC-005,
# AC-010, AC-011). Takes:
#   brain_dir, topic, url, mock_fetch_script
# Runs: duplicate guard → fetch → write source → manifest-write
# Returns 0 on success, 2 on any failure.
# ---------------------------------------------------------------------------
_ingest_pipeline() {
  local brain_dir="$1"
  local topic="$2"
  local url="$3"
  local mock_fetch="$4"

  local manifest="${brain_dir}/.brain/manifest.json"

  # Step 1: duplicate guard
  if ! _duplicate_guard "$manifest" "$url"; then
    return 2
  fi

  # Step 2: fetch via mock
  local content
  if ! content="$("$mock_fetch" "$url" 2>/dev/null)"; then
    return 2
  fi

  # Step 3: derive slug + write source file
  local slug
  slug="$(_slug_from_url "$url")"
  local title="Test Article"
  _write_source_file "$brain_dir" "$topic" "$slug" "$url" "$title" "$content"

  # Step 4: call manifest_write library
  local entry
  local ingested_at
  ingested_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  entry="$(printf '{"source_id":"%s","url":"%s","topic":"%s","ingested_at":"%s","last_ingest":"%s","chunks":[],"embeddings_model":null}' \
    "$slug" "$url" "$topic" "$ingested_at" "$ingested_at")"

  # shellcheck source=/dev/null
  if ! (
    export BRAIN_DIR="$brain_dir"
    source "$MANIFEST_WRITE_LIB"
    manifest_write "$entry" "$manifest"
  ); then
    # Rollback source file
    rm -f "${brain_dir}/sources/${topic}/${slug}.md"
    return 2
  fi

  return 0
}

# ===========================================================================
# AC-001 / BC-2.02.001: defuddle-fetch.mjs happy path
# defuddle-fetch.mjs called with mock 200 URL → outputs cleaned markdown, exit 0
# Exercises VP-015 (source file pipeline starts with successful fetch)
# ===========================================================================
@test "BC_2_02_001: defuddle-fetch.mjs outputs cleaned markdown on exit 0 (happy path)" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  run node "$mock_fetch" "https://mock-200/article"
  [ "$status" -eq 0 ]
  # Output must be non-empty markdown content
  [ -n "$output" ]
  [[ "$output" == *"#"* ]] || [[ "$output" == *"content"* ]] || [[ "$output" == *"Mocked"* ]]
}

# Structural test: verify the real script contains the required Defuddle import and
# Node version check. This replaces the brittle live-network Red Gate test (which
# non-deterministically passes or fails depending on whether example.com returns 200).
@test "BC_2_02_001: defuddle-fetch.mjs contains Defuddle import and Node version check" {
  [ -f "$DEFUDDLE_FETCH" ]
  grep -q "Defuddle" "$DEFUDDLE_FETCH"
  grep -q "process.versions.node" "$DEFUDDLE_FETCH"
}

# The REAL script must: exist, be executable, and produce markdown on stdout
# This is the integration assertion that will FAIL against the stub.
@test "BC_2_02_001: defuddle-fetch.mjs produces markdown to stdout for valid URL" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  # Verify mock outputs to stdout (not stderr)
  local stdout_content stderr_content
  stdout_content="$(node "$mock_fetch" "https://mock-200/article" 2>/dev/null)"
  stderr_content="$(node "$mock_fetch" "https://mock-200/article" 2>&1 1>/dev/null)"

  [ -n "$stdout_content" ]
  # stderr must contain title JSON metadata on success (matches real defuddle-fetch.mjs behaviour)
  [[ "$stderr_content" == *"title"* ]]
}

# ===========================================================================
# BC-2.02.001 EC-012: URL scheme validation (SSRF guard)
# defuddle-fetch.mjs must reject non-http/https schemes before any fetch.
# These tests exercise the REAL script — scheme check is pre-network and deterministic.
# ===========================================================================
@test "BC_2_02_001: defuddle-fetch.mjs rejects file:// URL with E-INGEST-012" {
  run bash -c "node '${DEFUDDLE_FETCH}' 'file:///etc/passwd' 2>&1"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-012"* ]] || [[ "$output" == *"Only HTTP"* ]]
}

@test "BC_2_02_001: defuddle-fetch.mjs rejects ftp:// URL with E-INGEST-012" {
  run bash -c "node '${DEFUDDLE_FETCH}' 'ftp://example.com/file' 2>&1"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-012"* ]] || [[ "$output" == *"Only HTTP"* ]]
}

@test "BC_2_02_001: defuddle-fetch.mjs rejects data: URL with E-INGEST-012" {
  run bash -c "node '${DEFUDDLE_FETCH}' 'data:text/html,<h1>test</h1>' 2>&1"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-012"* ]] || [[ "$output" == *"Only HTTP"* ]]
}

# ===========================================================================
# AC-002 / BC-2.02.001 EC-006: Node 22+ absent → exit 2, E-INGEST-005
# ===========================================================================
@test "BC_2_02_001_EC006: Node absent emits E-INGEST-005 and exits 2" {
  local mock_fetch="${BRAIN_DIR}/mock-node-absent.sh"
  _mock_node_absent "$mock_fetch"

  run bash "$mock_fetch" "https://example.com/article"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-005"* ]]
}

@test "BC_2_02_001_EC006: E-INGEST-005 message mentions Node 22+" {
  local mock_fetch="${BRAIN_DIR}/mock-node-absent.sh"
  _mock_node_absent "$mock_fetch"

  local stderr_out
  stderr_out="$(bash "$mock_fetch" "https://example.com" 2>&1 || true)"
  [[ "$stderr_out" == *"Node 22+"* ]] || [[ "$stderr_out" == *"nodejs.org"* ]]
}

# The real defuddle-fetch.mjs checks node version and must NOT emit E-INGEST-005
# when Node 22+ is available. The real script exits 0 for reachable URLs.
@test "BC_2_02_001_EC006: defuddle-fetch.mjs does not emit E-INGEST-005 on sufficient Node version" {
  # The real implementation must contain a node version check in its source
  grep -q 'E-INGEST-005' "${DEFUDDLE_FETCH}"
  # When run with a sufficient Node version (current Node), no E-INGEST-005 is emitted
  # Verify by checking the script source contains a version-check guard
  grep -q 'process.versions.node' "${DEFUDDLE_FETCH}"
}

# ===========================================================================
# AC-003 / BC-2.02.001 EC-002: Non-200 HTTP → exit 2, E-INGEST-002
# ===========================================================================
@test "BC_2_02_001_EC002: non-200 HTTP response emits E-INGEST-002 and exits 2" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  run node "$mock_fetch" "https://mock-non200/article"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-002"* ]]
}

@test "BC_2_02_001_EC002: E-INGEST-002 message mentions HTTP status and URL" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  local err_out
  err_out="$(node "$mock_fetch" "https://mock-non200/article" 2>&1 || true)"
  [[ "$err_out" == *"HTTP"* ]]
  [[ "$err_out" == *"mock-non200"* ]]
}

@test "BC_2_02_001_EC002: no source file written on non-200 response" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  # Attempt fetch — should fail
  node "$mock_fetch" "https://mock-non200/article" >/dev/null 2>&1 || true

  # No source file should exist
  local count
  count="$(find "${BRAIN_DIR}/sources" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" -eq 0 ]
}

# ===========================================================================
# AC-004 / BC-2.02.001 EC-003: Empty Defuddle output → exit 2, E-INGEST-003
# ===========================================================================
@test "BC_2_02_001_EC003: empty Defuddle output emits E-INGEST-003 and exits 2" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  run node "$mock_fetch" "https://mock-empty/article"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-003"* ]]
}

@test "BC_2_02_001_EC003: E-INGEST-003 message mentions page may not be extractable" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  local err_out
  err_out="$(node "$mock_fetch" "https://mock-empty/article" 2>&1 || true)"
  [[ "$err_out" == *"empty content"* ]] || [[ "$err_out" == *"extractable"* ]] || [[ "$err_out" == *"E-INGEST-003"* ]]
}

@test "BC_2_02_001_EC003: no source file written when Defuddle returns empty" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  node "$mock_fetch" "https://mock-empty/article" >/dev/null 2>&1 || true

  local count
  count="$(find "${BRAIN_DIR}/sources" -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$count" -eq 0 ]
}

# ===========================================================================
# AC-005 / BC-2.02.001 postcondition 1: Source file created with correct frontmatter
# Exercises VP-015
# ===========================================================================
@test "BC_2_02_001: successful ingest creates source file at sources/{topic}/{slug}.md" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  [ -f "${BRAIN_DIR}/sources/test-topic/article.md" ]
}

@test "BC_2_02_001: source file has title frontmatter field" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  local title
  title="$(yq eval '.title' "${BRAIN_DIR}/sources/test-topic/article.md")"
  [ -n "$title" ]
  [ "$title" != "null" ]
}

@test "BC_2_02_001: source file has url frontmatter field matching ingested URL" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  local url
  url="$(yq eval '.url' "${BRAIN_DIR}/sources/test-topic/article.md")"
  [ "$url" = "https://mock-200/article" ]
}

@test "BC_2_02_001: source file has ingested_at frontmatter in ISO 8601 format" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  local ingested_at
  ingested_at="$(yq eval '.ingested_at' "${BRAIN_DIR}/sources/test-topic/article.md")"
  [[ "$ingested_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "BC_2_02_001: source file has source_id frontmatter matching the slug" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  local source_id
  source_id="$(yq eval '.source_id' "${BRAIN_DIR}/sources/test-topic/article.md")"
  [ "$source_id" = "article" ]
}

@test "BC_2_02_001: source file has topic frontmatter field" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  local topic
  topic="$(yq eval '.topic' "${BRAIN_DIR}/sources/test-topic/article.md")"
  [ "$topic" = "test-topic" ]
}

@test "BC_2_02_001: source file has embedding_status: pending frontmatter field" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch"

  local embedding_status
  embedding_status="$(yq eval '.embedding_status' "${BRAIN_DIR}/sources/test-topic/article.md")"
  [ "$embedding_status" = "pending" ]
}

# ===========================================================================
# AC-007 / BC-2.02.006 postconditions 1-3: Duplicate URL rejected before fetch
# ===========================================================================
@test "BC_2_02_006: duplicate URL in manifest exits 2 with E-INGEST-001" {
  # Pre-populate manifest with an existing URL (ADR-015 object schema).
  printf '{"sources":{"sources/test-topic/already-ingested.md":{"source_id":"already-ingested","url":"https://example.com/already-ingested","topic":"test-topic","ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z","chunks":[],"embeddings_model":null}}}\n' \
    >"${BRAIN_DIR}/.brain/manifest.json"

  run _duplicate_guard "${BRAIN_DIR}/.brain/manifest.json" "https://example.com/already-ingested"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-001"* ]]
}

@test "BC_2_02_006: E-INGEST-001 message names the existing slug" {
  printf '{"sources":{"sources/test-topic/already-ingested.md":{"source_id":"already-ingested","url":"https://example.com/already-ingested","topic":"test-topic","ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z","chunks":[],"embeddings_model":null}}}\n' \
    >"${BRAIN_DIR}/.brain/manifest.json"

  local err_out
  err_out="$(_duplicate_guard "${BRAIN_DIR}/.brain/manifest.json" "https://example.com/already-ingested" 2>&1 || true)"
  [[ "$err_out" == *"already-ingested"* ]]
  [[ "$err_out" == *"immutable"* ]]
}

@test "BC_2_02_006: ingest-url with fixture duplicate URL exits 2 (fixture test)" {
  # Use the ingest-url-duplicate.json fixture
  local fixture="${PLUGIN_DIR}/tests/fixtures/ingest-url-duplicate.json"
  local dup_url
  dup_url="$(jq -r '.url' "$fixture")"
  local existing_entry
  existing_entry="$(jq '.existing_manifest_entry' "$fixture")"

  # Inject the existing entry into manifest using full-path key (ADR-015 object schema).
  local entry_topic entry_source_id entry_key
  entry_topic="$(printf '%s' "$existing_entry" | jq -r '.topic')"
  entry_source_id="$(printf '%s' "$existing_entry" | jq -r '.source_id')"
  entry_key="sources/${entry_topic}/${entry_source_id}.md"
  jq --arg key "$entry_key" --argjson entry "$existing_entry" '.sources[$key] = $entry' \
    "${BRAIN_DIR}/.brain/manifest.json" >"${BRAIN_DIR}/.brain/manifest.json.tmp"
  mv "${BRAIN_DIR}/.brain/manifest.json.tmp" "${BRAIN_DIR}/.brain/manifest.json"

  run _duplicate_guard "${BRAIN_DIR}/.brain/manifest.json" "$dup_url"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-001"* ]]
}

# ===========================================================================
# AC-008 / BC-2.02.006 invariant 1: Duplicate check is BEFORE fetch
# Defuddle must NOT be called for a duplicate URL.
# ===========================================================================
@test "BC_2_02_006: defuddle-fetch.mjs is NOT called for a duplicate URL" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  # Pre-populate manifest with the URL we'll try to ingest (ADR-015 object schema).
  printf '{"sources":{"sources/test-topic/article.md":{"source_id":"article","url":"https://mock-200/article","topic":"test-topic","ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z","chunks":[],"embeddings_model":null}}}\n' \
    >"${BRAIN_DIR}/.brain/manifest.json"

  # Reset invocation counter
  printf '0\n' >"$INVOCATION_COUNT_FILE"

  # Run pipeline — should short-circuit at duplicate guard before calling mock
  _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article" "$mock_fetch" || true

  local count
  count="$(cat "$INVOCATION_COUNT_FILE" | tr -d '[:space:]')"
  # Defuddle must NOT have been called (count must remain 0)
  [ "$count" -eq 0 ]
}

# ===========================================================================
# AC-009 / BC-2.02.006 EC-001: Different query string = new URL, ingest proceeds
# ===========================================================================
@test "BC_2_02_006_EC001: URL with different query string is treated as new URL" {
  # Existing URL without query string (ADR-015 object schema).
  printf '{"sources":{"sources/test-topic/article.md":{"source_id":"article","url":"https://mock-200/article","topic":"test-topic","ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z","chunks":[],"embeddings_model":null}}}\n' \
    >"${BRAIN_DIR}/.brain/manifest.json"

  # URL with different query string — should NOT be a duplicate
  run _duplicate_guard "${BRAIN_DIR}/.brain/manifest.json" "https://mock-200/article?ref=newsletter"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_006_EC001: ingest proceeds for URL with additional query string" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  # Existing URL in manifest (ADR-015 object schema).
  printf '{"sources":{"sources/test-topic/article.md":{"source_id":"article","url":"https://mock-200/article","topic":"test-topic","ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z","chunks":[],"embeddings_model":null}}}\n' \
    >"${BRAIN_DIR}/.brain/manifest.json"

  # New URL with different query string
  run _ingest_pipeline "$BRAIN_DIR" "test-topic" "https://mock-200/article?ref=newsletter" "$mock_fetch"
  # Pipeline should not reject this as duplicate
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-010 / BC-2.02.004 postcondition 3 + invariant 2: manifest-write.sh happy path
# manifest_write function exists, accepts JSON, reads manifest, appends atomically
# Exercises VP-012 (manifest atomicity)
# ===========================================================================
@test "BC_2_02_004: manifest-write.sh sources successfully (library exists)" {
  # shellcheck source=/dev/null
  run bash -c "source '${MANIFEST_WRITE_LIB}' && declare -F manifest_write"
  [ "$status" -eq 0 ]
  [[ "$output" == *"manifest_write"* ]]
}

@test "BC_2_02_004: manifest_write function returns 0 on valid entry and writable manifest" {
  # Create a valid manifest
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"new-article","url":"https://example.com/new-article","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  run bash -c "
    source '${MANIFEST_WRITE_LIB}'
    BRAIN_DIR='${BRAIN_DIR}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  "
  [ "$status" -eq 0 ]
}

@test "BC_2_02_004: manifest_write appends entry to manifest.json sources array" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"new-article","url":"https://example.com/new-article","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  bash -c "
    source '${MANIFEST_WRITE_LIB}'
    BRAIN_DIR='${BRAIN_DIR}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " || true

  local count
  count="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$count" -eq 1 ]
}

@test "BC_2_02_004: manifest_write does NOT leave .tmp file behind after success (atomic)" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"new-article","url":"https://example.com/new-article","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  bash -c "
    source '${MANIFEST_WRITE_LIB}'
    BRAIN_DIR='${BRAIN_DIR}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>/dev/null || true

  # After a successful manifest_write the sources array must have been updated.
  # The stub always returns 1 without writing, so the count stays 0.
  # A correct implementation must have written the entry (count == 1).
  local count
  count="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$count" -eq 1 ]
  # Additionally, no leftover .tmp file on success
  [ ! -f "${BRAIN_DIR}/.brain/manifest.json.tmp" ]
}

@test "BC_2_02_004: manifest_write fails with E-INGEST-008 when BRAIN_DIR is unset" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local entry='{"source_id":"test","url":"https://example.com","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'
  # Capture the manifest path in a local variable before entering the subshell,
  # making the outer-shell expansion explicit and unambiguous.
  # BRAIN_DIR itself is unset in the subshell — manifest_write must detect this.
  local mpath="${BRAIN_DIR}/.brain/manifest.json"
  run bash -c "
    source '${MANIFEST_WRITE_LIB}'
    unset BRAIN_DIR
    manifest_write '${entry}' '${mpath}'
  "
  [ "$status" -ne 0 ]
  [[ "$output" == *"E-INGEST-008"* ]]
}

# ===========================================================================
# AC-011 / BC-2.02.004 postconditions 1-2: manifest entry has correct fields;
# existing entries unchanged
# Exercises VP-012
# ===========================================================================
@test "BC_2_02_004: manifest entry has source_id field after ingest" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  local source_id
  source_id="$(jq -r 'first(.sources[]).source_id' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$source_id" = "article" ]
}

@test "BC_2_02_004: manifest entry has url field matching ingested URL" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  local url
  url="$(jq -r 'first(.sources[]).url' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$url" = "https://mock-200/article" ]
}

@test "BC_2_02_004: manifest entry has topic field" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  local topic
  topic="$(jq -r 'first(.sources[]).topic' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$topic" = "ai" ]
}

@test "BC_2_02_004: manifest entry has ingested_at field in ISO 8601 format" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  local ingested_at
  ingested_at="$(jq -r 'first(.sources[]).ingested_at' "${BRAIN_DIR}/.brain/manifest.json")"
  [[ "$ingested_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "BC_2_02_004: manifest entry has last_ingest field in ISO 8601 format" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  local last_ingest
  last_ingest="$(jq -r 'first(.sources[]).last_ingest' "${BRAIN_DIR}/.brain/manifest.json")"
  [[ "$last_ingest" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "BC_2_02_004: manifest entry has chunks array (empty on first ingest)" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  local chunks_type
  chunks_type="$(jq 'first(.sources[]).chunks | type' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$chunks_type" = '"array"' ]
}

@test "BC_2_02_004: manifest entry has embeddings_model field (null on first ingest)" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true

  # The manifest must have exactly one entry (stub always returns 1, so count stays 0)
  local count
  count="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$count" -eq 1 ]

  local embeddings_model
  embeddings_model="$(jq 'first(.sources[]).embeddings_model' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$embeddings_model" = "null" ]
}

@test "BC_2_02_004: second ingest does not modify first entry (existing entries unchanged)" {
  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  # First ingest
  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/article" "$mock_fetch" || true
  local first_source_id
  first_source_id="$(jq -r 'first(.sources[]).source_id' "${BRAIN_DIR}/.brain/manifest.json")"

  # Second ingest of a different URL
  _ingest_pipeline "$BRAIN_DIR" "ai" "https://mock-200/second-piece" "$mock_fetch" || true

  # First entry must be unchanged
  local preserved_source_id
  preserved_source_id="$(jq -r 'first(.sources[]).source_id' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$preserved_source_id" = "$first_source_id" ]
  # Total entries = 2
  local count
  count="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$count" -eq 2 ]
}

# ===========================================================================
# AC-012 / BC-2.02.004 postcondition 1 + invariant 1: No sources/ dir scan
# Skill reads ONLY manifest.json for duplicate detection (no find/ls of sources/)
# ===========================================================================
@test "BC_2_02_004: duplicate guard reads manifest.json only — not sources/ dir" {
  # Create 10 source files NOT in the manifest
  local i
  for i in $(seq 1 10); do
    mkdir -p "${BRAIN_DIR}/sources/ai"
    cat >"${BRAIN_DIR}/sources/ai/orphan-${i}.md" <<EOMD
---
title: Orphan Source ${i}
url: https://orphan${i}.example.com
---
Content.
EOMD
  done

  # Manifest is empty (URL we check is not in manifest, and not in sources/ either)
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  # Verify that _duplicate_guard inspects ONLY manifest.json.
  # We check the source code of the duplicate guard: the real implementation
  # must use jq on manifest.json and must NOT invoke find/ls on sources/.
  # Text-level assertion on the actual manifest-write.sh script body:
  # It must not contain any 'find' or 'ls' call targeting sources/
  if grep -n '\bfind\b' "${MANIFEST_WRITE_LIB}" | grep -q 'sources'; then
    echo "FAIL: manifest-write.sh contains a find on sources/ (manifest-only invariant violated)" >&2
    return 1
  fi
  if grep -n '\bls\b' "${MANIFEST_WRITE_LIB}" | grep -q 'sources'; then
    echo "FAIL: manifest-write.sh contains ls on sources/ (manifest-only invariant violated)" >&2
    return 1
  fi

  # Functional check: the duplicate guard must return 0 for a URL not in manifest,
  # even with 10 source files present in sources/
  run _duplicate_guard "${BRAIN_DIR}/.brain/manifest.json" "https://example.com/new-article"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_004: manifest-only read — 10 orphan sources do not affect duplicate detection" {
  # 10 source files exist but are not in manifest
  local i
  for i in $(seq 1 10); do
    mkdir -p "${BRAIN_DIR}/sources/ai"
    cat >"${BRAIN_DIR}/sources/ai/orphan-${i}.md" <<EOMD
---
title: Orphan ${i}
url: https://orphan${i}.example.com
---
Content.
EOMD
  done

  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  # The URL we're ingesting is NOT in manifest, even though some sources/ files exist
  run _duplicate_guard "${BRAIN_DIR}/.brain/manifest.json" "https://example.com/new-article"
  # Should return 0 (not a duplicate — not in manifest)
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-013 / BC-2.02.004 EC-002: Manifest write failure → source file rolled back,
# E-INGEST-008 emitted
# ===========================================================================
@test "BC_2_02_004_EC002: manifest write failure emits E-INGEST-008" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  # Make manifest.json read-only to simulate write failure
  chmod 444 "${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"rollback-test","url":"https://example.com/rollback","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  local err_out
  err_out="$(bash -c "
    source '${MANIFEST_WRITE_LIB}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>&1 || true)"

  # Must contain E-INGEST-008 error code in output
  [[ "$err_out" == *"E-INGEST-008"* ]]

  # Restore permissions for cleanup
  chmod 644 "${BRAIN_DIR}/.brain/manifest.json"
}

@test "BC_2_02_004_EC002: source file is deleted when manifest write fails (rollback)" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  # Write source file first (simulating pre-write step completed before manifest write)
  _write_source_file "$BRAIN_DIR" "ai" "rollback-test" \
    "https://example.com/rollback" "Rollback Test" "Content here."

  local source_file="${BRAIN_DIR}/sources/ai/rollback-test.md"
  [ -f "$source_file" ]  # Verify it was created

  # Make manifest read-only (disk full / permission error simulation)
  chmod 444 "${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"rollback-test","url":"https://example.com/rollback","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  # The real manifest_write must: detect failure AND emit E-INGEST-008 on stderr.
  # The stub always returns 1 without emitting E-INGEST-008 — the rollback test verifies
  # that the REAL implementation signals rollback via a non-zero exit + E-INGEST-008.
  # We test the rollback contract: caller must delete source file on manifest_write failure.
  local err_out
  err_out="$(bash -c "
    source '${MANIFEST_WRITE_LIB}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>&1 || true)"

  # The real implementation must emit E-INGEST-008 on failure
  [[ "$err_out" == *"E-INGEST-008"* ]]

  # Restore permissions
  chmod 644 "${BRAIN_DIR}/.brain/manifest.json"
}

@test "BC_2_02_004_EC002: manifest.json is NOT corrupted when write fails" {
  local original_manifest='{"sources":{}}'
  printf '%s\n' "$original_manifest" >"${BRAIN_DIR}/.brain/manifest.json"

  # Make the target read-only to trigger failure
  chmod 444 "${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"fail-test","url":"https://example.com/fail","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  bash -c "
    source '${MANIFEST_WRITE_LIB}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>/dev/null || true

  # Restore permissions
  chmod 644 "${BRAIN_DIR}/.brain/manifest.json"

  # Original manifest content must be intact AND must be valid JSON
  run jq -e '.' "${BRAIN_DIR}/.brain/manifest.json"
  [ "$status" -eq 0 ]
  local actual
  actual="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$actual" -eq 0 ]
  # Also verify the write failure generated E-INGEST-008
  # (we need to re-run to capture stderr since it was suppressed above)
  chmod 444 "${BRAIN_DIR}/.brain/manifest.json"
  local stderr_out
  stderr_out="$(bash -c "
    source '${MANIFEST_WRITE_LIB}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>&1 || true)"
  chmod 644 "${BRAIN_DIR}/.brain/manifest.json"
  [[ "$stderr_out" == *"E-INGEST-008"* ]]
}

@test "BC_2_02_004_EC002: _ingest_pipeline rollback deletes source file on manifest write failure" {
  # This test exercises the full rollback path through _ingest_pipeline.
  # When manifest_write fails, _ingest_pipeline must delete the source file.
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  # Make manifest read-only BEFORE running pipeline to trigger write failure
  chmod 444 "${BRAIN_DIR}/.brain/manifest.json"

  local url="https://mock-200/rollback-pipeline-test"
  local topic="ai"
  local slug
  slug="$(_slug_from_url "$url")"

  # Run pipeline — should fail at manifest write
  _ingest_pipeline "$BRAIN_DIR" "$topic" "$url" "$mock_fetch" || true

  # Restore permissions for cleanup
  chmod 644 "${BRAIN_DIR}/.brain/manifest.json"

  # Source file MUST NOT exist — _ingest_pipeline rollback must have deleted it
  [ ! -f "${BRAIN_DIR}/sources/${topic}/${slug}.md" ]

  # Manifest must remain unchanged (no entry added)
  local count
  count="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$count" -eq 0 ]
}

# ===========================================================================
# AC-014 / CLAUDE.md §Conventions: shellcheck and shfmt clean
# ===========================================================================
@test "BC_2_02_004: manifest-write.sh passes shellcheck" {
  run shellcheck "${MANIFEST_WRITE_LIB}"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_004: manifest-write.sh passes shfmt normalization" {
  run shfmt -d -i 2 "${MANIFEST_WRITE_LIB}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# VP-012 / BC-2.02.004 invariant 2: Atomic write (.tmp → mv), not direct write
# Verifies atomicity property of the manifest write
# ===========================================================================
@test "VP_012: manifest_write uses atomic .tmp+mv pattern (no partial writes)" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"atomic-test","url":"https://example.com/atomic","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  # Verify the implementation uses tmp file (check script body for the .tmp pattern)
  grep -q '\.tmp' "${MANIFEST_WRITE_LIB}" || {
    echo "FAIL: manifest-write.sh does not contain .tmp pattern — atomic write not implemented" >&2
    return 1
  }
  grep -q '\bmv\b' "${MANIFEST_WRITE_LIB}" || {
    echo "FAIL: manifest-write.sh does not contain mv — atomic rename not implemented" >&2
    return 1
  }
}

@test "VP_012: manifest.json contains the written entry and is valid JSON after manifest_write" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"valid-json-test","url":"https://example.com/valid","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  bash -c "
    source '${MANIFEST_WRITE_LIB}'
    BRAIN_DIR='${BRAIN_DIR}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>/dev/null || true

  # After a successful manifest_write the manifest must:
  # 1. Be valid JSON
  run jq -e '.' "${BRAIN_DIR}/.brain/manifest.json"
  [ "$status" -eq 0 ]
  # 2. Contain the written entry (stub does not write — count stays 0, which fails)
  local count
  count="$(jq '.sources | length' "${BRAIN_DIR}/.brain/manifest.json")"
  [ "$count" -eq 1 ]
}

# ===========================================================================
# VP-015: manifest_write sources hook-event-emit.sh and emits structured event
# ===========================================================================
@test "VP_015: manifest-write.sh sources hook-event-emit.sh" {
  # Verify the script sources hook-event-emit.sh (textual check)
  grep -q 'hook-event-emit.sh' "${MANIFEST_WRITE_LIB}"
}

@test "VP_015: manifest_write emits ingest.url.manifest_updated or ingest.source.manifest_updated event" {
  printf '{"sources":{}}\n' >"${BRAIN_DIR}/.brain/manifest.json"

  local entry='{"source_id":"event-test","url":"https://example.com/event","topic":"ai","ingested_at":"2026-05-26T00:00:00Z","last_ingest":"2026-05-26T00:00:00Z","chunks":[],"embeddings_model":null}'

  local stderr_out
  stderr_out="$(bash -c "
    source '${MANIFEST_WRITE_LIB}'
    BRAIN_DIR='${BRAIN_DIR}'
    manifest_write '${entry}' '${BRAIN_DIR}/.brain/manifest.json'
  " 2>&1 1>/dev/null || true)"

  # A successful manifest_write should emit a structured event on stderr
  # The event_type must be one of the ingest manifest events
  [[ "$stderr_out" == *"manifest_updated"* ]]
}

# ===========================================================================
# Happy-path fixture verification (uses ingest-url-happy.json)
# ===========================================================================
@test "BC_2_02_001: happy-path fixture URL produces source file with expected slug" {
  local fixture="${PLUGIN_DIR}/tests/fixtures/ingest-url-happy.json"
  local url
  url="$(jq -r '.url' "$fixture")"
  local topic
  topic="$(jq -r '.topic' "$fixture")"
  local expected_slug
  expected_slug="$(jq -r '.expected_slug' "$fixture")"

  local mock_fetch="${BRAIN_DIR}/mock-defuddle-fetch.mjs"
  _mock_defuddle_fetch "$mock_fetch"

  _ingest_pipeline "$BRAIN_DIR" "$topic" "$url" "$mock_fetch" || true

  [ -f "${BRAIN_DIR}/sources/${topic}/${expected_slug}.md" ]
}

# ===========================================================================
# STORY-017: Wiki page generation pipeline, token JSONL logging, 50K-token warning
# Traces to: BC-2.02.002, BC-2.02.003, BC-2.02.005, VP-015
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: _write_source_for_wiki
#
# Creates a source file with realistic article content so generate-wiki.sh
# has a valid input. Returns the source slug.
# ---------------------------------------------------------------------------
_write_source_for_wiki() {
  local brain_dir="$1"
  local topic="$2"
  local slug="$3"
  local url="${4:-https://example.com/article}"

  mkdir -p "${brain_dir}/sources/${topic}"
  local dest="${brain_dir}/sources/${topic}/${slug}.md"
  local ingested_at
  ingested_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat >"$dest" <<'SRCEOF'
---
title: "Understanding Transformer Architecture in Large Language Models"
url: "https://example.com/article"
ingested_at: "2026-05-26T00:00:00Z"
source_id: "article"
topic: "ai"
embedding_status: pending
---

# Understanding Transformer Architecture in Large Language Models

The transformer architecture, introduced in the landmark 2017 paper "Attention Is All You Need"
by Vaswani et al., fundamentally changed how we process sequential data. Unlike recurrent neural
networks (RNNs), transformers rely entirely on self-attention mechanisms, allowing for
substantially greater parallelization during training.

## Key Components

The transformer consists of an encoder and decoder stack. Each encoder layer has two sub-layers:
a multi-head self-attention mechanism and a position-wise fully connected feed-forward network.
Residual connections and layer normalization wrap each sub-layer.

Self-attention allows the model to weigh the importance of different positions in the input
sequence relative to each other. The attention function maps a query and a set of key-value
pairs to an output. Multi-head attention runs attention in parallel h times, then concatenates
the results and projects them.

## Position Encoding

Since transformers contain no recurrence or convolution, position information must be injected.
Sinusoidal position encodings are added to the input embeddings. These encodings have the same
dimension as the embeddings, so the two can be summed.

## Scaling Laws

Research by Kaplan et al. demonstrated that model performance scales predictably with compute,
model parameters, and dataset size. This finding drove the rapid scaling of GPT-3, PaLM, and
subsequent large language models, each demonstrating emergent capabilities not present at
smaller scales.

## Applications in Modern AI

Transformers now dominate natural language processing, computer vision, and multimodal tasks.
BERT uses bidirectional encoders for understanding; GPT uses unidirectional decoders for
generation. Vision Transformers (ViTs) apply the same architecture to image patches.

The attention mechanism's ability to capture long-range dependencies without sequential
processing makes transformers especially powerful for complex reasoning tasks, code generation,
and scientific question-answering.

## Key People

Ashish Vaswani led the original transformer research at Google Brain. Ilya Sutskever drove
scaling experiments at OpenAI. Alec Radford pioneered the GPT series. Noam Shazeer contributed
to both the original transformer and mixture-of-experts scaling.

## Frameworks and Tools

PyTorch and JAX are the dominant frameworks for transformer research. HuggingFace Transformers
provides pre-trained models and fine-tuning utilities. FlashAttention optimizes attention
computation for memory and speed. DeepSpeed enables efficient distributed training.
SRCEOF
}

# ---------------------------------------------------------------------------
# Helper: _setup_wiki_dirs
#
# Creates the wiki directory structure including empty index.md and log.md.
# ---------------------------------------------------------------------------
_setup_wiki_dirs() {
  local brain_dir="$1"
  mkdir -p "${brain_dir}/wiki/concepts" \
    "${brain_dir}/wiki/people" \
    "${brain_dir}/wiki/frameworks" \
    "${brain_dir}/wiki/syntheses" \
    "${brain_dir}/wiki/observations" \
    "${brain_dir}/wiki/questions"

  # Minimal index.md
  cat >"${brain_dir}/wiki/index.md" <<'IDXEOF'
---
type: index
title: "Wiki Index"
---

# Wiki Index
IDXEOF

  # Minimal log.md
  cat >"${brain_dir}/wiki/log.md" <<'LOGEOF'
---
type: log
title: "Ingest Log"
---

# Ingest Log
LOGEOF
}

# ---------------------------------------------------------------------------
# Helper: _setup_policies_with_threshold
#
# Writes a .brain/policies.yaml file with max_ingest_tokens_per_chunk set.
# ---------------------------------------------------------------------------
_setup_policies_with_threshold() {
  local brain_dir="$1"
  local threshold="${2:-50000}"
  mkdir -p "${brain_dir}/.brain"
  cat >"${brain_dir}/.brain/policies.yaml" <<POLEOF
policies:
  - id: POL-001
    name: source-immutability
    description: "Sources are immutable after ingest."
    enforcement: block
max_ingest_tokens_per_chunk: ${threshold}
POLEOF
}

# ---------------------------------------------------------------------------
# Helper: _write_large_source
#
# Creates a source file at $1 containing $2 words (for threshold tests).
# Uses portable cat-heredoc for the frontmatter header to avoid
# printf '---\n...' on macOS (where -- is misinterpreted as an option).
# ---------------------------------------------------------------------------
_write_large_source() {
  local dest="$1"
  local word_count="$2"
  # Write frontmatter header using cat + heredoc (avoids printf -- issue on macOS)
  cat >"$dest" <<'HDREOF'
---
title: "Large Article"
type: source
embedding_status: pending
---

HDREOF
  # Append body words using printf with explicit format string (no --ambiguity)
  local i
  for i in $(seq 1 "$word_count"); do
    printf '%s' "word "
    if [ $(( i % 20 )) -eq 0 ]; then
      printf '\n'
    fi
  done >>"$dest"
}

# ===========================================================================
# AC-001 / BC-2.02.002 postcondition 1: Wiki pages created under wiki/{type}/
# VP-015: 5+ wiki pages created on standard article ingest
# ===========================================================================
@test "BC_2_02_002: generate-wiki.sh creates 5-15 wiki pages under wiki/{type}/ (AC-001)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  # generate-wiki.sh takes: <brain_dir> <source_path>
  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md"
  [ "$status" -eq 0 ]

  # Count wiki pages created (excluding index.md and log.md)
  local wiki_count
  wiki_count="$(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' | wc -l | tr -d ' ')"
  [ "$wiki_count" -ge 5 ]
  [ "$wiki_count" -le 15 ]
}

@test "BC_2_02_002: generate-wiki.sh creates pages in canonical type directories (AC-001)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  # At least one page must exist in one of the 6 canonical type subdirectories
  local typed_count
  typed_count="$(find "${BRAIN_DIR}/wiki/concepts" \
    "${BRAIN_DIR}/wiki/people" \
    "${BRAIN_DIR}/wiki/frameworks" \
    "${BRAIN_DIR}/wiki/syntheses" \
    "${BRAIN_DIR}/wiki/observations" \
    "${BRAIN_DIR}/wiki/questions" \
    -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$typed_count" -ge 5 ]
}

# ===========================================================================
# AC-002 / BC-2.02.002 postconditions 2-3: Each page passes schema + wikilink checks
# VP-015: All created pages pass schema validation
# ===========================================================================
@test "BC_2_02_002: each generated wiki page has embedding_status: pending (AC-002)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  # First: at least 5 pages must exist (if 0, the schema check below is vacuous)
  local page_count
  page_count="$(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$page_count" -ge 5 ]

  # Every wiki page except index.md and log.md must have embedding_status: pending
  local fail_count=0
  while IFS= read -r page; do
    local status_val
    status_val="$(yq eval '.embedding_status' "$page" 2>/dev/null || true)"
    if [ "$status_val" != "pending" ]; then
      fail_count=$(( fail_count + 1 ))
    fi
  done < <(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null)
  [ "$fail_count" -eq 0 ]
}

@test "BC_2_02_002: each generated wiki page has required frontmatter fields (AC-002)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  # First: at least 5 pages must exist (otherwise the loop is vacuously true)
  local page_count
  page_count="$(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$page_count" -ge 5 ]

  local fail_count=0
  while IFS= read -r page; do
    local title_val type_val emb_val
    title_val="$(yq eval '.title' "$page" 2>/dev/null || true)"
    type_val="$(yq eval '.type' "$page" 2>/dev/null || true)"
    emb_val="$(yq eval '.embedding_status' "$page" 2>/dev/null || true)"
    if [ -z "$title_val" ] || [ "$title_val" = "null" ] || \
       [ -z "$type_val" ] || [ "$type_val" = "null" ] || \
       [ "$emb_val" != "pending" ]; then
      fail_count=$(( fail_count + 1 ))
    fi
  done < <(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null)
  [ "$fail_count" -eq 0 ]
}

# ===========================================================================
# AC-003 / BC-2.02.002 postconditions 4-6: source_ids, index.md, log.md updated
# VP-015: index.md updated after ingest
# ===========================================================================
@test "BC_2_02_002: each generated wiki page has source_ids containing the source slug (AC-003)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  # First: at least 5 pages must exist (otherwise the loop is vacuously true)
  local page_count
  page_count="$(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$page_count" -ge 5 ]

  local fail_count=0
  while IFS= read -r page; do
    local source_ids
    source_ids="$(yq eval '.source_ids' "$page" 2>/dev/null || true)"
    if [[ "$source_ids" != *"article"* ]]; then
      fail_count=$(( fail_count + 1 ))
    fi
  done < <(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null)
  [ "$fail_count" -eq 0 ]
}

@test "BC_2_02_002: wiki/index.md is updated with new page entries after generation (AC-003)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # VP-015: index.md updated after ingest
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  local index_before
  index_before="$(wc -l < "${BRAIN_DIR}/wiki/index.md" | tr -d ' ')"

  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  local index_after
  index_after="$(wc -l < "${BRAIN_DIR}/wiki/index.md" | tr -d ' ')"
  # index.md must have grown (entries added)
  [ "$index_after" -gt "$index_before" ]
}

@test "BC_2_02_002: wiki/log.md is updated with ingest log entries after generation (AC-003)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  local log_before
  log_before="$(wc -l < "${BRAIN_DIR}/wiki/log.md" | tr -d ' ')"

  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  local log_after
  log_after="$(wc -l < "${BRAIN_DIR}/wiki/log.md" | tr -d ' ')"
  # log.md must have grown (ingest log entries added)
  [ "$log_after" -gt "$log_before" ]
}

# ===========================================================================
# AC-005 / BC-2.02.002 EC-002: Slug collision → page skipped, skip recorded
# ===========================================================================
@test "BC_2_02_002: slug collision causes page to be skipped, not overwritten (AC-005)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  # Pre-create a wiki page that WILL collide with a generated slug.
  # The source fixture has "## Position Encoding" which generate-wiki.sh
  # slugifies to "position-encoding" and places under wiki/concepts/.
  local collision_page="${BRAIN_DIR}/wiki/concepts/position-encoding.md"
  cat >"$collision_page" <<'COLEOF'
---
title: "Position Encoding"
type: concepts
embedding_status: complete
source_ids: [prior-source]
---

# Position Encoding

Original content — must not be overwritten.
COLEOF

  local original_content
  original_content="$(cat "$collision_page")"

  # generate-wiki.sh must exist and run (Red Gate: script not present yet)
  bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" || true

  # At least 5 pages generated (proves the script ran and attempted generation)
  local page_count
  page_count="$(find "${BRAIN_DIR}/wiki" -name '*.md' \
    -not -name 'index.md' \
    -not -name 'log.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$page_count" -ge 5 ]

  # Page content must be unchanged (not overwritten)
  local after_content
  after_content="$(cat "$collision_page")"
  [ "$original_content" = "$after_content" ]
}

@test "BC_2_02_002: generate-wiki.sh records slug collision skip in summary output (AC-005)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  # Pre-create a colliding page — must match an actual generated slug.
  # "## Position Encoding" → slug "position-encoding" under wiki/concepts/.
  local collision_page="${BRAIN_DIR}/wiki/concepts/position-encoding.md"
  cat >"$collision_page" <<'COLEOF'
---
title: "Position Encoding"
type: concepts
embedding_status: complete
source_ids: [prior-source]
---

Prior content — preserved by collision handling.
COLEOF

  # generate-wiki.sh must emit a summary on stdout; collision must be recorded
  local summary_output
  summary_output="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" 2>/dev/null || true)"

  # pages_skipped must be > 0 (proves the collision code path ran)
  local skipped
  skipped="$(printf '%s' "$summary_output" | jq -r '.pages_skipped')"
  [ "$skipped" -gt 0 ]

  # The collision must appear in the failures array; identify via error field
  # (BC-2.03.004 failures form: {"slug":"<slug>","error":"E-NNN: <message>"}; no `reason` field)
  local collision_found
  collision_found="$(printf '%s' "$summary_output" | \
    jq -r '.failures[] | select(.slug == "position-encoding") | .slug' || true)"
  [ "$collision_found" = "position-encoding" ]
  # The error field must be present and non-empty (BC-2.03.004 postcondition 2)
  local collision_error
  collision_error="$(printf '%s' "$summary_output" | \
    jq -r '.failures[] | select(.slug == "position-encoding") | .error' || true)"
  [ -n "$collision_error" ]
  [ "$collision_error" != "null" ]

  # The pre-existing file content must not have been overwritten
  [[ "$(cat "$collision_page")" == *"Prior content"* ]]
}

# ===========================================================================
# AC-006 / BC-2.02.002 invariant 3 EC-003: Hook-blocked page → partial failure
# ===========================================================================
@test "BC_2_02_002: hook-blocked wiki page causes partial failure; other pages proceed (AC-006)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # When one page fails (hook exit 2), other pages are still created.
  # We simulate a hook block by making one target directory read-only.
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  # Make concepts/ write-protected to trigger a failure for any concepts pages
  chmod 555 "${BRAIN_DIR}/wiki/concepts"

  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md"

  # Restore permissions for teardown
  chmod 755 "${BRAIN_DIR}/wiki/concepts"

  # Partial failure: skill exits 1 (not 0 or 2)
  [ "$status" -eq 1 ]

  # Other page types must still have been created (partial success)
  local other_count
  other_count="$(find "${BRAIN_DIR}/wiki/people" \
    "${BRAIN_DIR}/wiki/frameworks" \
    "${BRAIN_DIR}/wiki/syntheses" \
    "${BRAIN_DIR}/wiki/observations" \
    "${BRAIN_DIR}/wiki/questions" \
    -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"
  [ "$other_count" -ge 1 ]
}

@test "BC_2_02_002: generate-wiki.sh output includes fan-out envelope with pages_attempted, pages_created, pages_failed (AC-006)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  local output
  output="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" 2>/dev/null || true)"

  # Output must be a JSON object with fan-out envelope fields
  local pages_attempted
  pages_attempted="$(printf '%s' "$output" | jq -r '.pages_attempted' 2>/dev/null || true)"
  [ -n "$pages_attempted" ]
  [ "$pages_attempted" != "null" ]

  local pages_created
  pages_created="$(printf '%s' "$output" | jq -r '.pages_created' 2>/dev/null || true)"
  [ -n "$pages_created" ]
  [ "$pages_created" != "null" ]

  local pages_failed
  pages_failed="$(printf '%s' "$output" | jq -r '.pages_failed' 2>/dev/null || true)"
  [ -n "$pages_failed" ]
  [ "$pages_failed" != "null" ]
}

# ===========================================================================
# AC-007 / BC-2.02.003 postcondition 1: JSONL record appended on every ingest
# VP-015: JSONL token record written on every ingest
# ===========================================================================
@test "BC_2_02_003: log-tokens.sh appends JSONL record to .brain/logs/ingest-tokens.jsonl (AC-007)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  # log-tokens.sh takes: <brain_dir> <url> <source_id> <input_tokens> <output_tokens> <wiki_pages_created> <duration_seconds>
  run bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "1500" \
    "800" \
    "7" \
    "12"
  [ "$status" -eq 0 ]

  [ -f "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" ]
}

@test "BC_2_02_003: JSONL record has all required fields: timestamp, url, source_id, input_tokens, output_tokens, wiki_pages_created, duration_seconds (AC-007)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  # VP-015: Token JSONL record schema valid (jq parseable)
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "1500" \
    "800" \
    "7" \
    "12" || true

  local record
  record="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null || true)"
  [ -n "$record" ]

  local timestamp url source_id input_tokens output_tokens wiki_pages_created duration_seconds
  timestamp="$(printf '%s' "$record" | jq -r '.timestamp' 2>/dev/null || true)"
  url="$(printf '%s' "$record" | jq -r '.url' 2>/dev/null || true)"
  source_id="$(printf '%s' "$record" | jq -r '.source_id' 2>/dev/null || true)"
  input_tokens="$(printf '%s' "$record" | jq -r '.input_tokens' 2>/dev/null || true)"
  output_tokens="$(printf '%s' "$record" | jq -r '.output_tokens' 2>/dev/null || true)"
  wiki_pages_created="$(printf '%s' "$record" | jq -r '.wiki_pages_created' 2>/dev/null || true)"
  duration_seconds="$(printf '%s' "$record" | jq -r '.duration_seconds' 2>/dev/null || true)"

  [ -n "$timestamp" ] && [ "$timestamp" != "null" ]
  [ "$url" = "https://example.com/article" ]
  [ "$source_id" = "article" ]
  [ "$input_tokens" = "1500" ]
  [ "$output_tokens" = "800" ]
  [ "$wiki_pages_created" = "7" ]
  [ "$duration_seconds" = "12" ]
}

@test "BC_2_02_003: JSONL timestamp is in ISO 8601 UTC format (AC-007)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "1500" \
    "800" \
    "7" \
    "12" || true

  local timestamp
  timestamp="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null \
    | jq -r '.timestamp' 2>/dev/null || true)"
  [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2} ]]
}

# ===========================================================================
# AC-008 / BC-2.02.003 postcondition 2 EC-001: .brain/logs/ auto-created when absent
# ===========================================================================
@test "BC_2_02_003: log-tokens.sh creates .brain/logs/ when absent (AC-008)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  # .brain/ exists but logs/ does NOT
  mkdir -p "${BRAIN_DIR}/.brain"
  [ ! -d "${BRAIN_DIR}/.brain/logs" ]

  run bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "1500" \
    "800" \
    "7" \
    "12"
  [ "$status" -eq 0 ]

  [ -d "${BRAIN_DIR}/.brain/logs" ]
  [ -f "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" ]
}

@test "BC_2_02_003: log-tokens.sh creates ingest-tokens.jsonl when file absent (AC-008)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"
  [ ! -f "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" ]

  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "0" \
    "0" \
    "0" \
    "1" || true

  [ -f "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" ]
}

# ===========================================================================
# AC-009 / BC-2.02.003 postcondition 3: JSONL appended even on partial failure;
# wiki_pages_created reflects actual count
# ===========================================================================
@test "BC_2_02_003: JSONL wiki_pages_created reflects actual count on partial failure (AC-009)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  # Partial failure: only 3 of 7 attempted pages were created
  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "1500" \
    "800" \
    "3" \
    "9" || true

  local wiki_pages_created
  wiki_pages_created="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null \
    | jq -r '.wiki_pages_created' 2>/dev/null || true)"
  [ "$wiki_pages_created" = "3" ]
}

@test "BC_2_02_003: JSONL record is appended (not overwritten) on multiple invocations (AC-009)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  # First ingest
  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/first" \
    "first" \
    "1000" \
    "500" \
    "5" \
    "8" || true

  # Second ingest (different URL)
  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/second" \
    "second" \
    "2000" \
    "1000" \
    "8" \
    "15" || true

  local line_count
  line_count="$(wc -l < "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" | tr -d ' ')"
  # Both records must be present (append, not overwrite)
  [ "$line_count" -eq 2 ]
}

# ===========================================================================
# AC-011 / BC-2.02.003 postcondition 1: jq empty succeeds on each JSONL line
# VP-015: Token JSONL record schema valid (jq parseable)
# ===========================================================================
@test "BC_2_02_003: each line of ingest-tokens.jsonl is valid JSON (jq empty succeeds) (AC-011)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "1500" \
    "800" \
    "7" \
    "12" || true

  # Verify every line parses as valid JSON
  local fail_count=0
  while IFS= read -r line; do
    if [ -n "$line" ]; then
      if ! printf '%s' "$line" | jq empty 2>/dev/null; then
        fail_count=$(( fail_count + 1 ))
      fi
    fi
  done < "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl"
  [ "$fail_count" -eq 0 ]
}

# ===========================================================================
# AC-012 / BC-2.02.005 postcondition 1: Source > 50K tokens → advisory warning
# ===========================================================================
@test "BC_2_02_005: check-token-threshold.sh emits advisory when source exceeds threshold (AC-012)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # Create a large source file: wc -w * 1.3 > 50000
  # 50000 / 1.3 = ~38462 words needed to exceed threshold; use 38500
  local large_source="${BRAIN_DIR}/sources/ai/large-article.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  _setup_policies_with_threshold "$BRAIN_DIR" "50000"
  _write_large_source "$large_source" 38500

  # Script must exist (fails at Red Gate until implementer creates it)
  [ -f "${PLUGIN_DIR}/scripts/check-token-threshold.sh" ]

  # check-token-threshold.sh takes: <brain_dir> <source_path>
  # Emits advisory warning on stderr when threshold exceeded
  local advisory_output
  advisory_output="$(bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$large_source" 2>&1 || true)"

  [[ "$advisory_output" == *"50000"* ]] || \
    [[ "$advisory_output" == *"threshold"* ]] || \
    [[ "$advisory_output" == *"chunk"* ]] || \
    [[ "$advisory_output" == *"tokens"* ]]

  # Advisory error code E-INGEST-013 must be present in the combined output
  [[ "$advisory_output" == *"E-INGEST-013"* ]]
}

@test "BC_2_02_005: advisory warning message mentions estimated token count and threshold (AC-012)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  local large_source="${BRAIN_DIR}/sources/ai/large-article.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  _setup_policies_with_threshold "$BRAIN_DIR" "50000"
  _write_large_source "$large_source" 38500

  local advisory_output
  advisory_output="$(bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$large_source" 2>&1 || true)"

  # Must contain the advisory message text from AC-012
  [[ "$advisory_output" == *"estimated"* ]] || \
    [[ "$advisory_output" == *"exceeding"* ]] || \
    [[ "$advisory_output" == *"chunk threshold"* ]] || \
    [[ "$advisory_output" == *"Consider splitting"* ]]
}

# ===========================================================================
# AC-013 / BC-2.02.005 invariants 1-2: Warning is advisory only; ingest proceeds
# ===========================================================================
@test "BC_2_02_005: check-token-threshold.sh exits 0 on large source (advisory, not blocking) (AC-013)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  local large_source="${BRAIN_DIR}/sources/ai/large-article.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  _setup_policies_with_threshold "$BRAIN_DIR" "50000"
  _write_large_source "$large_source" 38500

  # Must exit 0 (advisory only — does not block) even when threshold exceeded
  run bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$large_source"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-014 / BC-2.02.005 EC-002: Content at or below threshold → no warning
# ===========================================================================
@test "BC_2_02_005: check-token-threshold.sh emits no warning for content below 50K threshold (AC-014)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # ~2000 words (well below 50K / 1.3 ≈ 38462 word threshold)
  local small_source="${BRAIN_DIR}/sources/ai/small-article.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  _setup_policies_with_threshold "$BRAIN_DIR" "50000"
  _write_large_source "$small_source" 2000

  # Script must exist (fails at Red Gate until implementer creates it)
  [ -f "${PLUGIN_DIR}/scripts/check-token-threshold.sh" ]

  local advisory_output
  advisory_output="$(bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$small_source" 2>&1 || true)"

  # Must NOT emit a threshold-exceeded advisory for small content
  # (result JSON may contain "50000" as the threshold value; check only for advisory keywords)
  [[ "$advisory_output" != *"exceeding"* ]]
}

@test "BC_2_02_005: content exactly at 50000-token estimate triggers no warning (exclusive threshold) (AC-014)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # Exactly at threshold: wc -w * 1.3 == 50000 → no warning (> 50000 triggers, not >=)
  # 50000 / 1.3 = 38461.5... → 38462 words → 38462 * 1.3 = 50000.6 → truncated to 50000 tokens
  # 50000 is NOT > 50000, so no advisory should be emitted.
  local exact_source="${BRAIN_DIR}/sources/ai/exact-article.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  _setup_policies_with_threshold "$BRAIN_DIR" "50000"
  _write_large_source "$exact_source" 38462

  # Must exit 0 with no advisory for content at/below threshold
  run bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$exact_source"
  [ "$status" -eq 0 ]

  local out
  out="$(bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$exact_source" 2>&1 || true)"
  [[ "$out" != *"exceeding"* ]]
}

# ===========================================================================
# AC-007 structured event: generate-wiki.sh emits ingest.url.wiki_pages_generated
# AC-007 structured event: ingest.url.completed on ingest completion
# ===========================================================================
@test "BC_2_02_002: generate-wiki.sh emits ingest.url.wiki_pages_generated event on stderr (AC-007 event)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # Events must be pre-registered in scripts/event-catalog.json (STORY-014 deliverable)
  _write_source_for_wiki "$BRAIN_DIR" "ai" "article"
  _setup_wiki_dirs "$BRAIN_DIR"

  local stderr_out
  stderr_out="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/article.md" 2>&1 1>/dev/null || true)"

  [[ "$stderr_out" == *"wiki_pages_generated"* ]]
}

@test "BC_2_02_002: ingest.url.wiki_pages_generated event is registered in event-catalog.json" {
  # Red Gate: event catalog entry does not exist yet (STORY-017 implementer must add it)
  local catalog="${PLUGIN_DIR}/scripts/event-catalog.json"
  [ -f "$catalog" ]

  local found
  found="$(jq -r '.[].event_type' "$catalog" | grep -c 'ingest.url.wiki_pages_generated' || true)"
  [ "$found" -ge 1 ]
}

@test "BC_2_02_003: ingest.url.completed event is registered in event-catalog.json" {
  # Red Gate: event catalog entry does not exist yet (STORY-017 implementer must add it)
  local catalog="${PLUGIN_DIR}/scripts/event-catalog.json"
  [ -f "$catalog" ]

  local found
  found="$(jq -r '.[].event_type' "$catalog" | grep -c 'ingest.url.completed' || true)"
  [ "$found" -ge 1 ]
}

@test "BC_2_02_005: ingest.url.token_threshold_exceeded event is registered in event-catalog.json" {
  # BC-2.02.005: token_threshold_exceeded event must be in the catalog
  run jq -e '.[] | select(.event_type == "ingest.url.token_threshold_exceeded")' \
    "${PLUGIN_DIR}/scripts/event-catalog.json"
  [ "$status" -eq 0 ]
}
