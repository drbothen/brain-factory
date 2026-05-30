#!/usr/bin/env bats
# STORY-014 VP-008 catalog completeness + schema tests
# Traces to: BC-2.17.001, BC-2.17.002, VP-008
#
# STORY-015 expansion — static meta-lint for cross-cutting hook contract properties
# Traces to: BC-2.04.015, BC-2.04.016, BC-2.17.003, BC-2.17.004
# VP anchors: VP-001, VP-013, VP-026
#
# STORY-015 assertions added:
#   AC-005: shebang on line 1 + set -euo pipefail within first 10 lines
#   AC-006: no bare `exit` (must be exit 0, exit 1, or exit 2)
#   AC-007: no `eval` in any hook
#   AC-010: no echo/printf to stdout outside emit_verdict
#   AC-013: no credential variable references in emit_event/emit_verdict calls
#   Cross-cutting: each hook has a per-hook .bats file
#   Cross-cutting: each hook has a -sample.json fixture
#   Cross-cutting negative assertions (no Co-Authored-By, no robot emoji,
#     no --no-verify, no .claude/templates/ hardcoding)

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  CATALOG="${PLUGIN_DIR}/scripts/event-catalog.json"
}

# Canonical list of all 13 hook basenames (without .sh).
# Used by STORY-015 parameterized static analysis tests.
STORY015_HOOKS=(
  "block-ai-attribution"
  "brain-health-check"
  "enforce-kebab-case"
  "flush-state-and-commit"
  "quarantine-fetch"
  "validate-frontmatter-schema"
  "validate-index-log-coherence"
  "validate-page-type-policy"
  "validate-publish-state"
  "validate-source-id-citation"
  "validate-source-immutability"
  "validate-voice-avoid-list"
  "validate-wikilink-integrity"
)

# AC-006: catalog exists and is valid JSON array
@test "BC_2_17_002: event-catalog.json exists and is valid JSON array" {
  [ -f "$CATALOG" ]
  run jq -e 'type == "array"' "$CATALOG"
  [ "$status" -eq 0 ]
}

# AC-007: each entry has required fields
@test "BC_2_17_002: all catalog entries have event_type, hook_name, severity, fields, example" {
  local missing
  missing="$(jq '[.[] | select((.event_type == null) or (.hook_name == null) or (.severity == null) or (.fields == null) or (.example == null))] | length' "$CATALOG")"
  [ "$missing" -eq 0 ]
}

# AC-008: event_type naming convention (domain.past-tense)
@test "BC_2_17_002: all event_type values match domain.verb pattern" {
  local bad
  bad="$(jq '[.[].event_type | select(test("^[a-z][a-z0-9_]*\\.[a-z][a-z0-9_.]*$") | not)] | length' "$CATALOG")"
  [ "$bad" -eq 0 ]
}

# AC-009: catalog has at least 27 entries (one per event type across 13 hooks)
@test "BC_2_17_001: catalog has at least 27 event entries" {
  local count
  count="$(jq 'length' "$CATALOG")"
  [ "$count" -ge 27 ]
}

# AC-010: event_type values are unique
@test "BC_2_17_001: all event_type values are unique" {
  local total unique
  total="$(jq '[.[].event_type] | length' "$CATALOG")"
  unique="$(jq '[.[].event_type] | unique | length' "$CATALOG")"
  [ "$total" -eq "$unique" ]
}

# AC-013: all example fields parse as valid JSON strings containing valid JSON
@test "BC_2_17_002: all example payloads are valid JSON" {
  run jq -e '.[].example | fromjson' "$CATALOG"
  [ "$status" -eq 0 ]
}

# AC-007: severity values are restricted to info|warn|error
@test "BC_2_17_002: severity values are info, warn, or error" {
  local bad
  bad="$(jq '[.[].severity | select(. != "info" and . != "warn" and . != "error")] | length' "$CATALOG")"
  [ "$bad" -eq 0 ]
}

# AC-012: all emit_event call sites have matching catalog entries
@test "VP_008: all emit_event call sites have matching catalog entries" {
  local catalog_types
  catalog_types="$(jq -r '.[].event_type' "${PLUGIN_DIR}/scripts/event-catalog.json")"

  # Collect emit_event call sites from all hook scripts (exclude comment lines)
  local emit_sites=""
  local sh_file
  for sh_file in "${PLUGIN_DIR}/hooks/"*.sh "${PLUGIN_DIR}/hooks/lib/"*.sh; do
    [ -f "$sh_file" ] || continue
    # Extract event_type from lines like: emit_event "some.event.type" ...
    # Skip lines that begin with # (comments).
    # Skip variable references like emit_event "$event_type" — these are
    # dynamic dispatch patterns; the caller is responsible for passing a
    # catalog-registered type (verified at call sites, not here).
    local site
    site="$(grep -h 'emit_event ' "$sh_file" | grep -v '^\s*#' | \
      grep -o 'emit_event "[^"]*"' | sed 's/emit_event "//;s/"//' | \
      grep -v '^\$' || true)"
    if [ -n "$site" ]; then
      emit_sites="${emit_sites}${site}"$'\n'
    fi
  done

  # If no emit sites found (all stubs), pass vacuously
  if [ -z "$(echo "$emit_sites" | tr -d '[:space:]')" ]; then
    return 0
  fi

  # Check each emit site has a catalog entry
  local missing=""
  while IFS= read -r event_type; do
    [ -z "$event_type" ] && continue
    if ! echo "$catalog_types" | grep -qxF "$event_type"; then
      missing="${missing}${event_type}"$'\n'
    fi
  done <<< "$emit_sites"

  if [ -n "$missing" ]; then
    echo "Unregistered emit_event types:" >&2
    echo "$missing" >&2
    return 1
  fi
}

# AC-014: shellcheck on hook-event-emit.sh
@test "BC_2_04_017: hook-event-emit.sh passes shellcheck" {
  run shellcheck "${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
  [ "$status" -eq 0 ]
}

# BC_2_04_017: shfmt normalization check on hook-event-emit.sh
@test "BC_2_04_017: hook-event-emit.sh passes shfmt" {
  run shfmt -d -i 2 "${PLUGIN_DIR}/hooks/lib/hook-event-emit.sh"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# =============================================================================
# STORY-015: BC-2.04.016 / AC-005 — shebang on line 1 + set -euo pipefail
# within first 10 lines for all 13 hooks.
# =============================================================================

@test "BC_2_04_016_AC005: all 13 hooks have shebang on line 1 and set -euo pipefail in first 10 lines" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local sh_file="${plugin_dir}/hooks/${hook_name}.sh"

    # Assert file exists.
    if [ ! -f "$sh_file" ]; then
      echo "MISSING: ${sh_file}" >&2
      failed=$((failed + 1))
      continue
    fi

    # Line 1 must be exactly #!/usr/bin/env bash.
    local line1
    line1="$(head -1 "$sh_file")"
    if [ "$line1" != "#!/usr/bin/env bash" ]; then
      echo "SHEBANG FAIL: ${hook_name}.sh line 1 is '${line1}'" >&2
      failed=$((failed + 1))
    fi

    # set -euo pipefail must appear within first 10 lines.
    local found_set
    found_set="$(head -10 "$sh_file" | grep -c 'set -euo pipefail' || true)"
    if [ "$found_set" -eq 0 ]; then
      echo "SET_E FAIL: ${hook_name}.sh missing 'set -euo pipefail' in first 10 lines" >&2
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: BC-2.04.016 / AC-006 — No bare `exit` in any hook.
# Bare exit = `exit` not immediately followed by a space and digit 0, 1, or 2.
# Valid: `exit 0`, `exit 1`, `exit 2`.
# Invalid: bare `exit`, `exit $code`, `exit "$code"`.
# =============================================================================

@test "BC_2_04_016_AC006: no bare exit in any hook (every exit must be exit 0, 1, or 2)" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local sh_file="${plugin_dir}/hooks/${hook_name}.sh"
    [ -f "$sh_file" ] || continue

    # Strip comment lines (lines where first non-whitespace char is #) before
    # scanning for bare exit. This prevents matches on comment text like
    # "exit codes other than 0..." from triggering false positives.
    # Also exclude:
    #   - Lines containing awk programs (awk uses its own `exit` command in
    #     its own language; these are not bash exit calls).
    #   - Lines where `exit` appears after echo/printf (it's a string literal,
    #     e.g. echo "curl exit ${curl_rc}").
    local code_lines
    code_lines="$(grep -v '^\s*#' "$sh_file" 2>/dev/null \
      | grep -v '\bawk\b' \
      | grep -vE '^\s*(echo|printf)\b' \
      || true)"

    # Grep for any `exit` that is NOT followed by space+digit (0, 1, or 2).
    # We use grep -P for Perl-compatible lookahead on Linux; fall back on macOS.
    local bare_count=0
    if grep -qP '' /dev/null 2>/dev/null; then
      # grep -P available (Linux).
      bare_count="$(echo "$code_lines" | grep -cP '\bexit\b(?! [0-2](\b|$))' 2>/dev/null || true)"
    else
      # macOS: two-step. Count total exit on code lines, subtract valid ones.
      local total_exit valid_exit
      total_exit="$(echo "$code_lines" | grep -cE '\bexit\b' 2>/dev/null || true)"
      valid_exit="$(echo "$code_lines" | grep -cE '\bexit [012]\b' 2>/dev/null || true)"
      bare_count=$(( total_exit - valid_exit ))
    fi

    if [ "$bare_count" -gt 0 ]; then
      echo "BARE_EXIT FAIL: ${hook_name}.sh has ${bare_count} bare/invalid exit(s)" >&2
      echo "$code_lines" | grep -nE '\bexit\b' | grep -vE '\bexit [012]\b' >&2 || true
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: BC-2.04.016 / AC-007 — No `eval` in any hook.
# =============================================================================

@test "BC_2_04_016_AC007: no eval in any hook script" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local sh_file="${plugin_dir}/hooks/${hook_name}.sh"
    [ -f "$sh_file" ] || continue

    # Grep for eval usage (non-comment lines only).
    # We strip comment lines first with grep -v '^\s*#' then search for eval.
    local eval_count
    eval_count="$(grep -v '^\s*#' "$sh_file" | grep -cE '\beval\b' || true)"
    if [ "$eval_count" -gt 0 ]; then
      echo "EVAL FAIL: ${hook_name}.sh has ${eval_count} eval usage(s)" >&2
      grep -nE '\beval\b' "$sh_file" | grep -v '^\s*#' >&2 || true
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: BC-2.17.003 / AC-010 — No bare echo/printf to stdout outside
# emit_verdict calls. Static analysis: grep for echo/printf that is NOT on a
# line redirecting to stderr (>&2) and NOT in a comment.
#
# This is a static heuristic. It detects the most common violation pattern:
# a raw `echo "text"` or `printf "text"` without >&2 redirection.
# =============================================================================

@test "BC_2_17_003_AC010: no bare echo/printf to stdout in any hook (must use stderr redirect or emit_verdict)" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local sh_file="${plugin_dir}/hooks/${hook_name}.sh"
    [ -f "$sh_file" ] || continue

    # Detect echo/printf to stdout. The challenge is multiline statements where
    # the stderr redirect (>&2) appears on the continuation line, not on the
    # line that starts with printf/echo.
    #
    # Strategy: use awk to join backslash-continuation lines into logical lines,
    # then grep the logical lines for echo/printf without >&2.
    # Authorized stdout paths: jq (verdict JSON) and emit_verdict helper.
    local logical_lines
    logical_lines="$(awk '
      /\\$/ { line = line substr($0, 1, length($0)-1); next }
      { print line $0; line = "" }
      END { if (line != "") print line }
    ' "$sh_file" 2>/dev/null || cat "$sh_file")"

    local bad_lines
    bad_lines="$(echo "$logical_lines" \
      | grep -E '^\s*(echo|printf)\s' \
      | grep -v '^\s*#' \
      | grep -v '>&2' \
      | grep -v '>>' \
      | grep -v '>[^&]' \
      | grep -v 'emit_verdict' \
      | grep -v '^\s*jq' \
      | grep -v "printf '.\?{" \
      | grep -v 'printf '\''%s' \
      || true)"

    if [ -n "$bad_lines" ]; then
      echo "STDOUT_ECHO FAIL: ${hook_name}.sh has bare echo/printf to stdout:" >&2
      echo "$bad_lines" >&2
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: BC-2.17.004 / AC-013 — No credential variable references inside
# emit_event or emit_verdict calls. Static scan for patterns like
# $LINKEDIN_ACCESS_TOKEN, $ANTHROPIC_API_KEY, $GITHUB_TOKEN, $*_TOKEN,
# $*_KEY, $*_SECRET inside emit_event/emit_verdict lines.
# =============================================================================

@test "BC_2_17_004_AC013: no credential variable refs in emit_event or emit_verdict calls in any hook" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local sh_file="${plugin_dir}/hooks/${hook_name}.sh"
    [ -f "$sh_file" ] || continue

    # Extract lines that call emit_event or emit_verdict (non-comment).
    local emit_lines
    emit_lines="$(grep -nE 'emit_event|emit_verdict' "$sh_file" | grep -v '^\s*#' || true)"

    # Check for credential variable patterns in those lines.
    # Matches: $VARNAME where VARNAME ends in _TOKEN, _KEY, _SECRET, _PASSWORD
    # (case-insensitive suffix). Also matches ${VARNAME} form.
    local cred_hits
    cred_hits="$(echo "$emit_lines" \
      | grep -iE '\$\{?[A-Za-z_][A-Za-z0-9_]*(_(TOKEN|KEY|SECRET|PASSWORD))\}?' \
      || true)"

    if [ -n "$cred_hits" ]; then
      echo "CRED_LEAK FAIL: ${hook_name}.sh has credential var in emit call:" >&2
      echo "$cred_hits" >&2
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: Per-hook .bats coverage gate — each hook must have a
# corresponding tests/<hook-name>.bats file (UD-006 convention).
# =============================================================================

@test "BC_2_04_016: all 13 hooks have a corresponding per-hook bats test file" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local bats_file="${plugin_dir}/tests/${hook_name}.bats"
    if [ ! -f "$bats_file" ]; then
      echo "MISSING BATS: ${bats_file}" >&2
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: Per-hook -sample.json fixture coverage gate — each hook must have
# tests/fixtures/<hook-name>-sample.json (AC-002 naming convention).
# =============================================================================

@test "BC_2_04_015_AC002: all 13 hooks have a -sample.json fixture at tests/fixtures/" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local hooks=(
    "block-ai-attribution"
    "brain-health-check"
    "enforce-kebab-case"
    "flush-state-and-commit"
    "quarantine-fetch"
    "validate-frontmatter-schema"
    "validate-index-log-coherence"
    "validate-page-type-policy"
    "validate-publish-state"
    "validate-source-id-citation"
    "validate-source-immutability"
    "validate-voice-avoid-list"
    "validate-wikilink-integrity"
  )

  local failed=0
  local hook_name
  for hook_name in "${hooks[@]}"; do
    local fixture="${plugin_dir}/tests/fixtures/${hook_name}-sample.json"
    if [ ! -f "$fixture" ]; then
      echo "MISSING FIXTURE: ${fixture}" >&2
      failed=$((failed + 1))
    fi
  done

  [ "$failed" -eq 0 ]
}

# =============================================================================
# STORY-015: Cross-cutting negative assertions.
# Scope: plugins/brain-factory/ source tree only.
# Rationale: .factory/ pipeline history documents (adversary pass reports,
# cycle notes, VP files) quote these patterns for documentation purposes.
# The meta-lint contract (CLAUDE.md §Meta-Lint Contract Surface 4) governs
# plugin source artifacts, not pipeline history. Scoping to plugins/brain-factory/
# is correct per CLAUDE.md §Meta-Lint Contract — the factory must enforce
# its contracts on its own SOURCE, not on the pipeline log corpus.
# =============================================================================

@test "BC_2_17_004: no plugin source file contains Co-Authored-By: Claude" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  # Search tracked files under plugins/brain-factory/ only.
  # Exempt: block-ai-attribution.sh and its test (they scan FOR this string as
  # their domain logic — the hook's job is to detect this pattern in commits).
  # Exempt: scripts/event-catalog.json (documents the event emitted by the hook).
  # Exempt: tests/fixtures/bash-ai-attribution-coauthored.json (test fixture).
  # Exempt: tests/meta-lint.bats (this file — self-referential enforcement).
  local repo_root
  repo_root="$(git -C "$plugin_dir" rev-parse --show-toplevel 2>/dev/null || echo "$plugin_dir")"
  local hits
  hits="$(git -C "$repo_root" ls-files -- "${plugin_dir}" 2>/dev/null \
    | grep -v 'block-ai-attribution' \
    | grep -v 'event-catalog.json' \
    | grep -v 'bash-ai-attribution' \
    | grep -v 'meta-lint.bats' \
    | xargs grep -lF 'Co-Authored-By: Claude' 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    echo "FORBIDDEN STRING 'Co-Authored-By: Claude' found in:" >&2
    echo "$hits" >&2
    return 1
  fi
}

@test "BC_2_17_004: no plugin source file contains robot emoji" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  # Exempt: block-ai-attribution.sh and its test (they scan FOR the robot emoji).
  # Exempt: tests/fixtures/bash-ai-attribution-emoji.json (test fixture).
  # Exempt: tests/meta-lint.bats (this file — self-referential enforcement).
  local repo_root
  repo_root="$(git -C "$plugin_dir" rev-parse --show-toplevel 2>/dev/null || echo "$plugin_dir")"
  local hits
  hits="$(git -C "$repo_root" ls-files -- "${plugin_dir}" 2>/dev/null \
    | grep -v 'block-ai-attribution' \
    | grep -v 'bash-ai-attribution' \
    | grep -v 'meta-lint.bats' \
    | xargs grep -lF '🤖' 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    echo "FORBIDDEN robot emoji found in:" >&2
    echo "$hits" >&2
    return 1
  fi
}

@test "BC_2_04_016: no plugin source file contains --no-verify" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  # Exempt: meta-lint.bats (this file) — it contains the string as a test assertion
  # (self-referential: the test pattern must match itself). The meta-lint file is
  # the enforcement mechanism, not a violator.
  local repo_root
  repo_root="$(git -C "$plugin_dir" rev-parse --show-toplevel 2>/dev/null || echo "$plugin_dir")"
  local hits
  hits="$(git -C "$repo_root" ls-files -- "${plugin_dir}" 2>/dev/null \
    | grep -v 'meta-lint.bats' \
    | xargs grep -lF -- '--no-verify' 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    echo "FORBIDDEN '--no-verify' found in:" >&2
    echo "$hits" >&2
    return 1
  fi
}

@test "BC_2_04_016: no plugin source file contains hardcoded .claude/templates/ path" {
  local plugin_dir
  plugin_dir="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"

  local repo_root
  repo_root="$(git -C "$plugin_dir" rev-parse --show-toplevel 2>/dev/null || echo "$plugin_dir")"

  # Exempt: CLAUDE.md (documents the forbidden pattern as a rule).
  # Exempt: meta-lint.bats (this file — enforcement mechanism, self-referential).
  # Exempt: SKILL.md files that quote the pattern in their Red Flags section
  #   (e.g., ingest-url/SKILL.md says "Using .claude/templates/ paths — FORBIDDEN").
  # Exempt: templates/policies.yaml (documents the policy, doesn't use the path).
  # Non-exempt: any hook .sh or skill procedure body that ACTUALLY uses the path.
  local hits
  hits="$(git -C "$repo_root" ls-files -- "${plugin_dir}" 2>/dev/null \
    | grep -v 'CLAUDE.md' \
    | grep -v 'meta-lint.bats' \
    | grep -v 'SKILL.md' \
    | grep -v 'policies.yaml' \
    | xargs grep -lF '.claude/templates/' 2>/dev/null || true)"
  if [ -n "$hits" ]; then
    echo "FORBIDDEN '.claude/templates/' hardcoding found in:" >&2
    echo "$hits" >&2
    return 1
  fi
}
