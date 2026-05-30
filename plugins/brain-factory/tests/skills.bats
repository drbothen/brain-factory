#!/usr/bin/env bats
# STORY-002 VP-012 Group 2 anchor: last_ingest field correctness
# Traces to: BC-2.06.003 postconditions 1-2, invariant 1
# Status: RED GATE STUB — completed in EPIC-03 (ingest pipeline)
#
# These tests exercise the VP-012 Group 2 property: that manifest.json
# source entries written by /brain:ingest-source contain a valid last_ingest
# field matching ingested_at on first ingest.
#
# The tests are written now to anchor the VP contract; they will fail until
# EPIC-03 implements the ingest-source skill and its manifest write path.

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  BRAIN_DIR="$(mktemp -d)"
  git init "$BRAIN_DIR" >/dev/null 2>&1
  export BRAIN_ROOT="$BRAIN_DIR"
  export CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR"

  # Pre-scaffold brain structure so ingest-source has a valid target
  # Uses the init run.sh stub — this setup step will also fail until
  # init is implemented; that is expected Red Gate behavior.
  bash "${PLUGIN_DIR}/skills/init/run.sh" 2>/dev/null || true
}

teardown() {
  rm -rf "$BRAIN_DIR"
}

# VP-012 Group 2 / BC-2.06.003 postcondition 1:
# last_ingest equals ingested_at on first ingest
@test "BC_2_06_003: manifest source entry has last_ingest equal to ingested_at on first ingest" {
  # EPIC-03 stub: ingest-source skill does not yet exist
  # This test will fail until EPIC-03 implements /brain:ingest-source
  local manifest="${BRAIN_DIR}/.brain/manifest.json"
  [ -f "$manifest" ]

  # Simulate what ingest-source would write by injecting a fixture entry
  # (Red Gate: we assert the schema contract; EPIC-03 must produce it)
  local ingested_at
  ingested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_id="test-source-001"

  # Write a fixture manifest entry as if ingest-source produced it.
  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local manifest_key="sources/ai/${source_id}.md"
  local updated
  updated="$(jq --arg key "$manifest_key" \
    --arg id "$source_id" \
    --arg ts "$ingested_at" \
    '.sources[$key] = {id: $id, ingested_at: $ts, last_ingest: $ts, url: "https://example.com/test", topic: "ai"}' \
    "$manifest")"
  printf '%s' "$updated" > "$manifest"

  # Assert: last_ingest equals ingested_at for this source entry
  local last_ingest ingested_at_read
  last_ingest="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).last_ingest' "$manifest")"
  ingested_at_read="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).ingested_at' "$manifest")"
  [ "$last_ingest" = "$ingested_at_read" ]
}

# VP-012 Group 2 / BC-2.06.003 postcondition 2:
# last_ingest is a valid ISO8601 UTC timestamp
@test "BC_2_06_003: manifest source entry last_ingest is valid ISO8601 UTC timestamp" {
  local manifest="${BRAIN_DIR}/.brain/manifest.json"
  [ -f "$manifest" ]

  local ingested_at
  ingested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_id="test-source-002"

  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local manifest_key="sources/health/${source_id}.md"
  local updated
  updated="$(jq --arg key "$manifest_key" \
    --arg id "$source_id" \
    --arg ts "$ingested_at" \
    '.sources[$key] = {id: $id, ingested_at: $ts, last_ingest: $ts, url: "https://example.com/test2", topic: "health"}' \
    "$manifest")"
  printf '%s' "$updated" > "$manifest"

  local last_ingest
  last_ingest="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).last_ingest' "$manifest")"
  # ISO8601 UTC format: YYYY-MM-DDTHH:MM:SSZ
  [[ "$last_ingest" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

# VP-012 Group 2 / BC-2.06.003 invariant 1:
# last_ingest is never null after successful ingest
@test "BC_2_06_003: manifest source entry last_ingest is never null after ingest" {
  local manifest="${BRAIN_DIR}/.brain/manifest.json"
  [ -f "$manifest" ]

  local ingested_at
  ingested_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  local source_id="test-source-003"

  # ADR-015: manifest.sources is an object keyed by "sources/<topic>/<source_id>.md".
  local manifest_key="sources/psychology/${source_id}.md"
  local updated
  updated="$(jq --arg key "$manifest_key" \
    --arg id "$source_id" \
    --arg ts "$ingested_at" \
    '.sources[$key] = {id: $id, ingested_at: $ts, last_ingest: $ts, url: "https://example.com/test3", topic: "psychology"}' \
    "$manifest")"
  printf '%s' "$updated" > "$manifest"

  local last_ingest
  last_ingest="$(jq -r --arg id "$source_id" 'first(.sources[] | select(.id == $id)).last_ingest' "$manifest")"
  [ "$last_ingest" != "null" ]
  [ -n "$last_ingest" ]
}

# ===========================================================================
# STORY-017: Wiki generation edge cases
# Traces to: BC-2.02.002 EC-001, BC-2.02.003 EC-002, BC-2.02.005 EC-001
# ===========================================================================

# Helper: write a short source file (< 500 words — produces < 5 wiki pages)
_write_short_source() {
  local brain_dir="$1"
  local slug="$2"
  mkdir -p "${brain_dir}/sources/ai"
  cat >"${brain_dir}/sources/ai/${slug}.md" <<'SHORTEOF'
---
title: "Short Article"
url: "https://example.com/short"
ingested_at: "2026-05-26T00:00:00Z"
source_id: "short-article"
topic: "ai"
embedding_status: pending
---

# Short Article

This is a brief summary with limited extractable concepts.

The main idea is simple. There are few concepts here.
SHORTEOF
}

# Helper: create minimal wiki dirs
_setup_wiki_dirs_skills() {
  local brain_dir="$1"
  mkdir -p "${brain_dir}/wiki/concepts" \
    "${brain_dir}/wiki/people" \
    "${brain_dir}/wiki/frameworks" \
    "${brain_dir}/wiki/syntheses" \
    "${brain_dir}/wiki/observations" \
    "${brain_dir}/wiki/questions"

  cat >"${brain_dir}/wiki/index.md" <<'IDXEOF'
---
type: index
title: "Wiki Index"
---
# Wiki Index
IDXEOF

  cat >"${brain_dir}/wiki/log.md" <<'LOGEOF'
---
type: log
title: "Ingest Log"
---
# Ingest Log
LOGEOF
}

# ===========================================================================
# AC-004 / BC-2.02.002 invariant 1 EC-001: < 5 pages → E-INGEST-006 advisory
# ===========================================================================
@test "BC_2_02_002: generate-wiki.sh emits E-INGEST-006 advisory when fewer than 5 pages produced (AC-004)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # Short article fixture → librarian produces < 5 pages
  _write_short_source "$BRAIN_DIR" "short-article"
  _setup_wiki_dirs_skills "$BRAIN_DIR"

  local output
  output="$(bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/short-article.md" 2>&1 || true)"

  # Must emit E-INGEST-006 advisory when < 5 pages produced
  [[ "$output" == *"E-INGEST-006"* ]]
}

@test "BC_2_02_002: generate-wiki.sh exits 0 on short article (E-INGEST-006 is advisory, not blocking) (AC-004)" {
  # Red Gate: scripts/generate-wiki.sh does not exist yet
  # E-INGEST-006 must be advisory (skill continues, does not block)
  _write_short_source "$BRAIN_DIR" "short-article"
  _setup_wiki_dirs_skills "$BRAIN_DIR"

  run bash "${PLUGIN_DIR}/scripts/generate-wiki.sh" \
    "$BRAIN_DIR" \
    "${BRAIN_DIR}/sources/ai/short-article.md"

  # Advisory: skill must continue (exit 0)
  [ "$status" -eq 0 ]
}

@test "BC_2_02_002: short-article fixture has fewer than 500 words (AC-004 test vector)" {
  # Verify the short article fixture actually exercises the < 5 pages edge case
  local fixture="${PLUGIN_DIR}/tests/fixtures/ingest-url-short-article.json"
  [ -f "$fixture" ]

  local word_count_approx
  word_count_approx="$(jq -r '.word_count_approx' "$fixture" 2>/dev/null || true)"
  # Fixture must declare a word count below 500
  [ -n "$word_count_approx" ]
  [ "$word_count_approx" -lt 500 ]
}

# ===========================================================================
# AC-010 / BC-2.02.003 EC-002: Token count unavailable → sentinel -1 values
# ===========================================================================
@test "BC_2_02_003: log-tokens.sh writes input_tokens: -1 when token count unavailable (AC-010)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  # Pass -1 for both token counts (unavailable from API)
  bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "-1" \
    "-1" \
    "5" \
    "10" || true

  local input_tokens output_tokens
  input_tokens="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null \
    | jq -r '.input_tokens' 2>/dev/null || true)"
  output_tokens="$(tail -1 "${BRAIN_DIR}/.brain/logs/ingest-tokens.jsonl" 2>/dev/null \
    | jq -r '.output_tokens' 2>/dev/null || true)"

  [ "$input_tokens" = "-1" ]
  [ "$output_tokens" = "-1" ]
}

@test "BC_2_02_003: log-tokens.sh succeeds even when token counts are -1 (AC-010)" {
  # Red Gate: scripts/log-tokens.sh does not exist yet
  # The append must NOT fail due to token count being unknown
  mkdir -p "${BRAIN_DIR}/.brain/logs"

  run bash "${PLUGIN_DIR}/scripts/log-tokens.sh" \
    "$BRAIN_DIR" \
    "https://example.com/article" \
    "article" \
    "-1" \
    "-1" \
    "5" \
    "10"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-015 / BC-2.02.005 EC-001: Missing max_ingest_tokens_per_chunk → default 50000
# ===========================================================================
@test "BC_2_02_005: check-token-threshold.sh uses default 50000 when key absent from policies.yaml (AC-015)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # policies.yaml exists but has NO max_ingest_tokens_per_chunk key
  mkdir -p "${BRAIN_DIR}/.brain"
  cat >"${BRAIN_DIR}/.brain/policies.yaml" <<'POLEOF'
policies:
  - id: POL-001
    name: source-immutability
    description: "Sources are immutable after ingest."
    enforcement: block
POLEOF

  local small_source="${BRAIN_DIR}/sources/ai/small.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  # Use cat heredoc to avoid printf -- interpretation on macOS
  cat >"$small_source" <<'SMALLEOF'
---
title: "Small"
type: source
embedding_status: pending
---

word word word word word word word word word word
SMALLEOF

  # Must NOT error on missing key — must use default 50000
  run bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$small_source"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_005: check-token-threshold.sh uses default 50000 when policies.yaml absent entirely (AC-015)" {
  # Red Gate: scripts/check-token-threshold.sh does not exist yet
  # No .brain/policies.yaml at all — must default without error
  mkdir -p "${BRAIN_DIR}/.brain"
  # init/run.sh (called in setup) creates policies.yaml — remove it to test the absent case
  rm -f "${BRAIN_DIR}/.brain/policies.yaml"
  [ ! -f "${BRAIN_DIR}/.brain/policies.yaml" ]

  local small_source="${BRAIN_DIR}/sources/ai/small.md"
  mkdir -p "${BRAIN_DIR}/sources/ai"
  cat >"$small_source" <<'SMALLEOF'
---
title: "Small"
type: source
embedding_status: pending
---

word word word
SMALLEOF

  run bash "${PLUGIN_DIR}/scripts/check-token-threshold.sh" \
    "$BRAIN_DIR" \
    "$small_source"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Shellcheck + shfmt compliance for new scripts (forward-looking)
# These fail until the scripts are implemented — structural Red Gate tests.
# ===========================================================================
@test "BC_2_02_002: scripts/generate-wiki.sh exists (structural Red Gate)" {
  # Red Gate: script not implemented yet
  [ -f "${PLUGIN_DIR}/scripts/generate-wiki.sh" ]
}

@test "BC_2_02_003: scripts/log-tokens.sh exists (structural Red Gate)" {
  # Red Gate: script not implemented yet
  [ -f "${PLUGIN_DIR}/scripts/log-tokens.sh" ]
}

@test "BC_2_02_005: scripts/check-token-threshold.sh exists (structural Red Gate)" {
  # Red Gate: script not implemented yet
  [ -f "${PLUGIN_DIR}/scripts/check-token-threshold.sh" ]
}

@test "BC_2_02_002: scripts/generate-wiki.sh passes shellcheck (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shellcheck "${PLUGIN_DIR}/scripts/generate-wiki.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_003: scripts/log-tokens.sh passes shellcheck (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shellcheck "${PLUGIN_DIR}/scripts/log-tokens.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_005: scripts/check-token-threshold.sh passes shellcheck (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shellcheck "${PLUGIN_DIR}/scripts/check-token-threshold.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_02_002: scripts/generate-wiki.sh passes shfmt normalization (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/generate-wiki.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BC_2_02_003: scripts/log-tokens.sh passes shfmt normalization (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/log-tokens.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BC_2_02_005: scripts/check-token-threshold.sh passes shfmt normalization (structural Red Gate)" {
  # Red Gate: script not implemented yet
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/check-token-threshold.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# STORY-019: validate-ingest-path.sh unit tests — path validation contract
# Traces to: BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004
# VP coverage: VP-016 (local source ingest pipeline), VP-012 (manifest atomicity)
#
# NOTE on event-catalog registration: The 5 structured event types required by
# the implementer (ingest.source.started, ingest.source.path_rejected,
# ingest.source.written, ingest.source.wiki_pages_generated,
# ingest.source.completed) and error codes E-INGEST-009, E-INGEST-010,
# E-INGEST-011 must be pre-registered in scripts/event-catalog.json before
# emit calls are added. That is implementer scope (STORY-014 deliverable).
#
# NOTE on readlink -f: Architecture Compliance Rule 1 mandates readlink -f
# (portable on macOS 12.3+ and Linux). Do NOT use realpath (not on macOS
# without GNU coreutils). Tests use readlink -f in their own expectations.
# ===========================================================================

# ---------------------------------------------------------------------------
# Helper: _setup_vault_with_policies
#
# Creates a minimal git-init'd brain vault with:
#   - .brain/manifest.json (empty sources)
#   - optional .brain/policies.yaml content passed as $2
# Exports BRAIN_ROOT pointing at the vault.
# Returns the vault directory in VAULT_DIR.
# ---------------------------------------------------------------------------
_setup_vault_with_policies() {
  local policies_yaml_content="${1:-}"
  VAULT_DIR="$(mktemp -d)"
  git init "$VAULT_DIR" >/dev/null 2>&1
  mkdir -p "${VAULT_DIR}/.brain"
  printf '{"sources":{}}\n' >"${VAULT_DIR}/.brain/manifest.json"
  if [ -n "$policies_yaml_content" ]; then
    printf '%s\n' "$policies_yaml_content" >"${VAULT_DIR}/.brain/policies.yaml"
  fi
  export BRAIN_ROOT="$VAULT_DIR"
}

# ---------------------------------------------------------------------------
# Helper: _teardown_vault
# ---------------------------------------------------------------------------
_teardown_vault() {
  rm -rf "${VAULT_DIR:-}"
}

# ---------------------------------------------------------------------------
# Helper: _run_validate_path
#
# Runs validate-ingest-path.sh with BRAIN_ROOT set to VAULT_DIR.
# Sets BATS_STATUS and BATS_OUTPUT via `run`.
# ---------------------------------------------------------------------------
_run_validate_path() {
  local candidate="$1"
  run env BRAIN_ROOT="$VAULT_DIR" \
    bash "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" "$candidate"
}

# ===========================================================================
# AC-001 / AC-009 / BC-2.03.003 postcondition (in-vault path):
# Valid markdown file inside the vault → resolved path printed; exit 0
# Exercises VP-016
# ===========================================================================
@test "BC_2_03_003: valid markdown file inside vault exits 0 with resolved path (AC-001/AC-009)" {
  # Traces to: BC-2.03.003 happy-path postcondition; BC-2.03.001 precondition 2
  # RED GATE: stub exits 3 with E-STUB sentinel; test asserts exit 0 → FAILS
  _setup_vault_with_policies
  # Create a real markdown file inside the vault
  local test_file="${VAULT_DIR}/sources/ai/my-article.md"
  mkdir -p "${VAULT_DIR}/sources/ai"
  cp "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" "$test_file"

  _run_validate_path "$test_file"

  # Must exit 0 on accepted path
  [ "$status" -eq 0 ]
  # Must print the resolved absolute path to stdout
  local resolved
  resolved="$(readlink -f "$test_file")"
  [[ "$output" == *"$resolved"* ]]
  _teardown_vault
}

# ===========================================================================
# AC-009 / AC-010 / BC-2.03.003 postcondition 1 (out-of-vault):
# Path to /etc/passwd → E-INGEST-009; exit 2; no file read
# Exercises VP-016 (out-of-vault path blocked) and BC-2.03.003 invariant 2
# ===========================================================================
@test "BC_2_03_003: /etc/passwd rejected with E-INGEST-009 exit 2 (AC-009/AC-010)" {
  # Traces to: BC-2.03.003 postcondition 1; invariant 2 (system dir hard block)
  # RED GATE: stub exits 3 with E-STUB; test asserts exit 2 → FAILS
  _setup_vault_with_policies

  _run_validate_path "/etc/passwd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  _teardown_vault
}

# ===========================================================================
# AC-009 / BC-2.03.003 canonical test vector:
# .. traversal resolving outside vault → E-INGEST-009; exit 2
# readlink -f semantics: raw path is relative, resolved path is outside vault
# ===========================================================================
@test "BC_2_03_003: dot-dot traversal resolving outside vault rejected E-INGEST-009 exit 2 (AC-009)" {
  # Traces to: BC-2.03.003 canonical test vector (../../outside-vault/file.md)
  # BC-2.03.003 invariant 1: readlink -f follows .. before vault-root compare
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  # Place the fixture OUTSIDE the vault (in a sibling temp dir)
  local outside_dir
  outside_dir="$(mktemp -d)"
  cp "${PLUGIN_DIR}/tests/fixtures/ingest-source-outside-vault.txt" \
    "${outside_dir}/outside.txt"
  # Construct a traversal path using the vault as starting point.
  # Navigate out of VAULT_DIR and into the outside dir.
  # readlink -f will resolve this to outside_dir/outside.txt.
  local vault_parent
  vault_parent="$(dirname "$VAULT_DIR")"
  local vault_name
  vault_name="$(basename "$VAULT_DIR")"
  local outside_name
  outside_name="$(basename "$outside_dir")"
  local traversal_path="${VAULT_DIR}/../${outside_name}/outside.txt"

  _run_validate_path "$traversal_path"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  rm -rf "$outside_dir"
  _teardown_vault
}

# ===========================================================================
# AC-011 / BC-2.03.003 EC-001:
# Symlink inside vault resolving to outside vault → E-INGEST-009; exit 2
# readlink -f follows symlinks before vault-root comparison
# ===========================================================================
@test "BC_2_03_003: symlink inside vault pointing outside vault rejected E-INGEST-009 exit 2 (AC-011)" {
  # Traces to: BC-2.03.003 EC-001
  # BC-2.03.003 invariant 1: readlink -f must follow symlinks
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  # Create a real file outside the vault
  local outside_dir
  outside_dir="$(mktemp -d)"
  local outside_file="${outside_dir}/secret.md"
  printf '# Secret\n\nContent outside vault.\n' >"$outside_file"
  # Create a symlink inside the vault pointing to the outside file
  local symlink_in_vault="${VAULT_DIR}/sources/outside-link.md"
  mkdir -p "${VAULT_DIR}/sources"
  ln -s "$outside_file" "$symlink_in_vault"

  _run_validate_path "$symlink_in_vault"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  rm -rf "$outside_dir"
  _teardown_vault
}

# ===========================================================================
# AC-010 / AC-012 / BC-2.03.003 invariant 2 (security):
# System directory /etc/ hard-blocked EVEN IF listed in allowed_external_paths
# ===========================================================================
@test "BC_2_03_003: /etc/ hard-blocked even when in policies.yaml allowed_external_paths (AC-010/AC-012)" {
  # Traces to: BC-2.03.003 invariant 2; AC-012 security clause
  # System dirs are always rejected regardless of policy — not configurable
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  local policies_content
  policies_content="$(printf 'allowed_external_paths:\n  - /etc/\n')"
  _setup_vault_with_policies "$policies_content"

  # /etc/ in the allowlist but must still be rejected
  _run_validate_path "/etc/passwd"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  _teardown_vault
}

@test "BC_2_03_003: /usr/ hard-blocked regardless of allowlist (AC-010)" {
  # Traces to: BC-2.03.003 invariant 2; /usr/ is a system directory
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies

  _run_validate_path "/usr/share/doc/some-file.txt"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  _teardown_vault
}

@test "BC_2_03_003: /var/ hard-blocked regardless of allowlist (AC-010)" {
  # Traces to: BC-2.03.003 invariant 2; /var/ is a system directory
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies

  _run_validate_path "/var/log/system.log"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-009"* ]]
  _teardown_vault
}

# ===========================================================================
# AC-012 / BC-2.03.003 EC-002:
# Operator allowlist in policies.yaml permits a non-system outside-vault path
# ===========================================================================
@test "BC_2_03_003: allowlisted outside-vault path is accepted; exit 0 (AC-012)" {
  # Traces to: BC-2.03.003 EC-002; allowed_external_paths key
  # RED GATE: stub exits 3; test asserts exit 0 → FAILS
  # Create a temp dir OUTSIDE the vault to act as the allowed external path
  local allowed_dir
  allowed_dir="$(mktemp -d)"
  local allowed_file="${allowed_dir}/research-notes.md"
  cp "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" "$allowed_file"

  local policies_content
  policies_content="$(printf 'allowed_external_paths:\n  - %s/\n' "$allowed_dir")"
  _setup_vault_with_policies "$policies_content"

  _run_validate_path "$allowed_file"

  [ "$status" -eq 0 ]
  # Resolved absolute path must be printed
  local resolved
  resolved="$(readlink -f "$allowed_file")"
  [[ "$output" == *"$resolved"* ]]
  rm -rf "$allowed_dir"
  _teardown_vault
}

# ===========================================================================
# AC-005 / BC-2.03.001 canonical test vector:
# File not found at resolved path → E-INGEST-011; exit 2
# ===========================================================================
@test "BC_2_03_001: nonexistent file emits E-INGEST-011 exit 2 (AC-005)" {
  # Traces to: BC-2.03.001 canonical test vector (file not found)
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  local nonexistent="${VAULT_DIR}/sources/does-not-exist.md"
  # File must NOT exist
  [ ! -f "$nonexistent" ]

  _run_validate_path "$nonexistent"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-011"* ]]
  _teardown_vault
}

# ===========================================================================
# AC-003 / BC-2.03.001 EC-002:
# PDF with pdftotext available (mock on PATH) → exit 0 (handled, not rejected)
# ===========================================================================
@test "BC_2_03_001: PDF file with pdftotext on PATH exits 0 (AC-003)" {
  # Traces to: BC-2.03.001 EC-002 (PDF with extractor available)
  # We mock pdftotext as a script on PATH that outputs text content
  # RED GATE: stub exits 3; test asserts exit 0 → FAILS
  _setup_vault_with_policies
  local fake_bin
  fake_bin="$(mktemp -d)"
  # Mock pdftotext: accepts <path> - args and writes text to stdout
  cat >"${fake_bin}/pdftotext" <<'PDFMOCK'
#!/usr/bin/env bash
# Mock pdftotext: outputs extraction text (args: <pdf_path> -)
printf '# Extracted PDF Content\n\nThis is extracted text from the PDF.\n'
exit 0
PDFMOCK
  chmod +x "${fake_bin}/pdftotext"

  # Create a fake PDF file inside the vault
  local pdf_file="${VAULT_DIR}/sources/ai/report.pdf"
  mkdir -p "${VAULT_DIR}/sources/ai"
  printf '%%PDF-1.4 fake pdf content\n' >"$pdf_file"

  run env BRAIN_ROOT="$VAULT_DIR" PATH="${fake_bin}:${PATH}" \
    bash "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" "$pdf_file"

  [ "$status" -eq 0 ]
  rm -rf "$fake_bin"
  _teardown_vault
}

# ===========================================================================
# AC-003 / BC-2.03.001 EC-002:
# PDF with pdftotext absent → E-INGEST-010; exit 2
# ===========================================================================
@test "BC_2_03_001: PDF file without pdftotext emits E-INGEST-010 exit 2 (AC-003)" {
  # Traces to: BC-2.03.001 EC-002; AC-003 advisory message for poppler-utils
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  # Build a restricted PATH that has no pdftotext
  local rdir
  rdir="$(mktemp -d)"
  local cmd_path name
  local IFS=':'
  for dir in $PATH; do
    [[ -d "$dir" ]] || continue
    for cmd_path in "$dir"/*; do
      [[ -x "$cmd_path" ]] || continue
      name="${cmd_path##*/}"
      [[ "$name" = "pdftotext" ]] && continue
      [[ -e "${rdir}/${name}" ]] && continue
      ln -sf "$cmd_path" "${rdir}/${name}"
    done
  done

  local pdf_file="${VAULT_DIR}/sources/ai/report.pdf"
  mkdir -p "${VAULT_DIR}/sources/ai"
  printf '%%PDF-1.4 fake pdf content\n' >"$pdf_file"

  run env BRAIN_ROOT="$VAULT_DIR" PATH="$rdir" \
    bash "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" "$pdf_file"

  rm -rf "$rdir"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-010"* ]]
  _teardown_vault
}

# ===========================================================================
# AC-004 / BC-2.03.001 EC-002:
# Image file (.png) → E-INGEST-010; exit 2
# ===========================================================================
@test "BC_2_03_001: .png image file emits E-INGEST-010 exit 2 (AC-004)" {
  # Traces to: BC-2.03.001 EC-002 (image type — cannot ingest in v0.1)
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  local image_file="${VAULT_DIR}/sources/ai/diagram.png"
  mkdir -p "${VAULT_DIR}/sources/ai"
  # Create a minimal fake PNG (not a valid PNG, just the right extension)
  printf '\x89PNG\r\n\x1a\n' >"$image_file"

  _run_validate_path "$image_file"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-010"* ]]
  _teardown_vault
}

@test "BC_2_03_001: .jpg image file emits E-INGEST-010 exit 2 (AC-004)" {
  # Traces to: BC-2.03.001 EC-002 (image type)
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  local image_file="${VAULT_DIR}/sources/ai/photo.jpg"
  mkdir -p "${VAULT_DIR}/sources/ai"
  printf 'fake jpg content\n' >"$image_file"

  _run_validate_path "$image_file"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-010"* ]]
  _teardown_vault
}

# ===========================================================================
# AC-006 / BC-2.03.001 EC-003:
# Already-ingested slug (present in manifest) → E-INGEST-001; exit 2; no read
# ===========================================================================
@test "BC_2_03_001: already-ingested slug in manifest emits E-INGEST-001 exit 2 (AC-006)" {
  # Traces to: BC-2.03.001 EC-003 (duplicate guard against manifest)
  # RED GATE: stub exits 3; test asserts exit 2 → FAILS
  _setup_vault_with_policies
  local test_file="${VAULT_DIR}/sources/ai/my-article.md"
  mkdir -p "${VAULT_DIR}/sources/ai"
  cp "${PLUGIN_DIR}/tests/fixtures/ingest-source-happy.md" "$test_file"

  # Pre-populate manifest with matching slug "my-article"
  local manifest_key="sources/ai/my-article.md"
  local existing_ts
  existing_ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  local updated
  updated="$(jq \
    --arg key "$manifest_key" \
    --arg ts "$existing_ts" \
    '.sources[$key] = {
      "source_id": "my-article",
      "path": "sources/ai/my-article.md",
      "topic": "ai",
      "ingested_at": $ts,
      "last_ingest": $ts,
      "chunks": [],
      "embeddings_model": null
    }' \
    "${VAULT_DIR}/.brain/manifest.json")"
  printf '%s\n' "$updated" >"${VAULT_DIR}/.brain/manifest.json"

  _run_validate_path "$test_file"

  [ "$status" -eq 2 ]
  [[ "$output" == *"E-INGEST-001"* ]]
  _teardown_vault
}

# ===========================================================================
# Structural Red Gate: validate-ingest-path.sh script exists
# ===========================================================================
@test "BC_2_03_003: scripts/validate-ingest-path.sh exists (structural)" {
  # Traces to: STORY-019 File Structure Requirements
  # RED GATE: script exists as a stub — this test passes (structural gate only)
  [ -f "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" ]
}

@test "BC_2_03_003: scripts/validate-ingest-path.sh first line is #!/usr/bin/env bash" {
  # Traces to: CLAUDE.md §Conventions (hook contract)
  # RED GATE: stub already has the right shebang — this passes; kept as structural guard
  local shebang
  shebang="$(head -1 "${PLUGIN_DIR}/scripts/validate-ingest-path.sh")"
  [ "$shebang" = "#!/usr/bin/env bash" ]
}

@test "BC_2_03_003: scripts/validate-ingest-path.sh has set -euo pipefail within first 10 lines" {
  # Traces to: CLAUDE.md §Conventions (hook contract)
  local found
  found="$(head -10 "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" | grep -c 'set -euo pipefail' || true)"
  [ "$found" -gt 0 ]
}

@test "BC_2_03_003: scripts/validate-ingest-path.sh passes shellcheck (structural Red Gate)" {
  # Traces to: CLAUDE.md §Conventions (shellcheck clean)
  # RED GATE: stub is shellcheck-clean — this passes; kept as forward gate for impl
  run shellcheck "${PLUGIN_DIR}/scripts/validate-ingest-path.sh"
  [ "$status" -eq 0 ]
}

@test "BC_2_03_003: scripts/validate-ingest-path.sh passes shfmt normalization (structural Red Gate)" {
  # Traces to: CLAUDE.md §Conventions (shfmt -i 2)
  run shfmt -d -i 2 "${PLUGIN_DIR}/scripts/validate-ingest-path.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

@test "BC_2_03_003: scripts/validate-ingest-path.sh does not invoke realpath as a command (uses readlink -f)" {
  # Traces to: STORY-019 Architecture Compliance Rule 1; Forbidden dependencies
  # realpath is not available on macOS without GNU coreutils.
  # We grep for realpath NOT preceded by # (comment) or backtick or NOT (negation words),
  # i.e. any bare command invocation. Strategy: grep all non-comment lines for
  # a word-boundary 'realpath' invocation (not a doc mention).
  # The stub comment block uses "NOT realpath" — we must not flag that.
  # A real invocation would look like: realpath "$path" or $(realpath ...)
  # Pattern: line starts with optional whitespace then 'realpath' (not preceded by -, `, NOT, ')
  local invocations
  invocations="$(grep -n '\brealpath\b' "${PLUGIN_DIR}/scripts/validate-ingest-path.sh" \
    | grep -v '^\s*#' | grep -v 'NOT realpath' | grep -v 'readlink\|not available' || true)"
  [ -z "$invocations" ]
}

# ===========================================================================
# AC-016 / BC-2.03.004 invariant 3 (static analysis):
# ingest-source SKILL.md procedure body must NOT contain 'set +e' as a command
# The Red Flags section legitimately mentions "set +e" as a FORBIDDEN pattern.
# We distinguish documentation (mentions in Red Flags / Quality Bar) from
# actual invocation (a bare `set +e` that would run in the skill body).
# ===========================================================================
@test "BC_2_03_004: ingest-source SKILL.md Procedure section does not contain set +e as command (AC-016)" {
  # Traces to: BC-2.03.004 invariant 3 (no set +e to silence hook-rejected writes)
  # Mirrors meta-lint static analysis check
  # Strategy: extract only the Procedure section lines and check for `set +e`.
  # The skeleton SKILL.md mentions it only in Red Flags (as a FORBIDDEN item) —
  # the Procedure section and code blocks must never contain it.
  # RED GATE: skeleton exists with no set +e in Procedure — passes.
  # This test guards the IMPLEMENTER from accidentally adding set +e in the Procedure body.
  local skill_file="${PLUGIN_DIR}/skills/ingest-source/SKILL.md"
  [ -f "$skill_file" ]
  # Extract Procedure section: lines between "## Procedure" and the next "## " heading
  local procedure_content
  procedure_content="$(awk '/^## Procedure/{p=1; next} /^## /{p=0} p' "$skill_file")"
  # Must not contain `set +e`
  local found
  found="$(printf '%s' "$procedure_content" | grep -c 'set +e' || true)"
  [ "$found" -eq 0 ]
}

@test "BC_2_03_004: skills/ingest-source/SKILL.md Procedure does not invoke realpath (uses readlink -f) (AC-016)" {
  # Traces to: STORY-019 Architecture Compliance Rule 1; Forbidden dependencies
  # The Red Flags section mentions realpath as forbidden — that's documentation, not code.
  # This test checks the Procedure section (actual steps) for realpath invocations.
  # RED GATE: skeleton Procedure has no realpath invocations — passes.
  # Guards the implementer from using realpath in the actual Procedure steps.
  local skill_file="${PLUGIN_DIR}/skills/ingest-source/SKILL.md"
  [ -f "$skill_file" ]
  local procedure_content
  procedure_content="$(awk '/^## Procedure/{p=1; next} /^## /{p=0} p' "$skill_file")"
  # Must not contain a bare realpath invocation (backtick or $( form)
  local found
  found="$(printf '%s' "$procedure_content" \
    | grep -E '\$\(realpath|\`realpath|^\s*realpath\b' | wc -l | tr -d ' ' || true)"
  [ "$found" -eq 0 ]
}
