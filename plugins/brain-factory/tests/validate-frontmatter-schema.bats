#!/usr/bin/env bats
# STORY-009 tests: validate-frontmatter-schema.sh PostToolUse hook
# Traces to: BC-2.04.004, BC-2.04.005
# VP coverage:
#   VP-002 (PostToolUse hook trigger on wiki writes)
#   VP-005 (frontmatter schema conformance — embedding_status + all mandatory fields)
#
# ADR-002 v2.0 schema is authoritative for all stdout assertions:
#   allow  → {"continue":true,...}         (not retired v1.0 "verdict":"allow")
#   block  → {"decision":"block",...}      (not retired v1.0 "verdict":"block")
# The story spec AC-002 references the retired v1.0 "verdict" field; ADR-002 v2.0 wins
# per CLAUDE.md §Source-of-Truth Precedence rule 2 (ADR supersedes).

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-frontmatter-schema.sh"
  FIXTURE_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory.  The hook determines schema from path prefix
  # (wiki/** vs sources/**) relative to the file_path embedded in the payload.
  BRAIN_DIR="$(mktemp -d)"
  mkdir -p "${BRAIN_DIR}/wiki/technology"
  mkdir -p "${BRAIN_DIR}/sources/ai"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PostToolUse Write payload.
# The hook reads frontmatter from tool_input.content (the written content string).
# Arguments:
#   $1 — absolute file_path embedded in the payload
#   $2 — content string (full markdown file, including frontmatter)
#   $3 — tool_name: Write or Edit [default: Write]
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local content="$2"
  local tool_name="${3:-Write}"
  # Escape content for JSON embedding via python3 json.dumps (same pattern as STORY-008)
  local escaped_content
  escaped_content="$(printf '%s' "${content}" | python3 -c 'import sys,json; print(json.dumps(sys.stdin.read()))')"
  # json.dumps wraps in quotes — strip the surrounding quotes
  escaped_content="${escaped_content:1:${#escaped_content}-2}"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"%s"},"tool_use_id":"test-009","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${file_path}" "${escaped_content}"
}

# ===========================================================================
# AC-001 / BC-2.04.004 precondition 1 + ADR-002 §hook-contract invariants:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# These are structural tests and PASS against the stub (they test the file's
# static properties, not its runtime behavior).
# ===========================================================================

@test "test_BC_2_04_004_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_004_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_004_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_004_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-007 / CLAUDE.md §Conventions §shellcheck + shfmt:
# Hook must pass shellcheck and shfmt normalization checks.
# These are structural and PASS against the stub.
# ===========================================================================

@test "test_BC_2_04_004_hook_passes_shellcheck" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_004_hook_passes_shfmt_normalization" {
  run shfmt -d -i 2 "${HOOK}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# hooks.json registration: PostToolUse Write|Edit matcher must include
# validate-frontmatter-schema.sh (VP-002 — hook fires on wiki writes).
# This is structural and PASSES against the current hooks.json.
# ===========================================================================

@test "test_BC_2_04_004_hooks_json_PostToolUse_entry_includes_validate_frontmatter_schema" {
  run python3 -c "
import json, sys
with open('${PLUGIN_DIR}/hooks/hooks.json') as f:
    data = json.load(f)
hooks = data.get('hooks', {})
post = hooks.get('PostToolUse', [])
found = False
for entry in post:
    for h in entry.get('hooks', []):
        cmd = h.get('command', '')
        if 'validate-frontmatter-schema.sh' in cmd:
            found = True
            break
if not found:
    print('ERROR: No PostToolUse entry pointing to validate-frontmatter-schema.sh', file=sys.stderr)
    sys.exit(1)
print('PASS')
"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_004_hooks_json_validate_frontmatter_entry_uses_CLAUDE_PLUGIN_ROOT_path" {
  run grep -q 'CLAUDE_PLUGIN_ROOT.*validate-frontmatter-schema.sh\|validate-frontmatter-schema.sh.*CLAUDE_PLUGIN_ROOT' \
    "${PLUGIN_DIR}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# BEHAVIORAL TESTS — all of these FAIL against the stub (stub exits 0, no-op).
# ===========================================================================

# ===========================================================================
# AC-002 / BC-2.04.004 postconditions on valid wiki frontmatter:
# All 5 mandatory fields present + valid → exit 0 + continue:true stdout.
# ADR-002 v2.0: allow → {"continue":true,...}
# ===========================================================================

@test "BC_2_04_004: valid wiki frontmatter exits 0 with continue:true" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-full-valid.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/valid-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_004: valid wiki frontmatter stdout contains trace field" {
  # The ADR-002 v2.0 allow response must carry a trace field for auditability.
  # The stub emits nothing — this test fails because the output is empty.
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-full-valid.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/valid-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"trace"'* ]]
}

# ===========================================================================
# AC-003 / BC-2.04.004 postconditions on missing embedding_status:
# Missing embedding_status → exit 2 + E-SCHEMA-001.
# ===========================================================================

@test "BC_2_04_004: missing embedding_status exits 2" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "BC_2_04_004: missing embedding_status stdout contains E-SCHEMA-001" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-001"* ]]
}

@test "BC_2_04_004: missing embedding_status stdout E-SCHEMA-001 at hookSpecificOutput.code" {
  # Structural assertion: error code at the correct JSON path, not just a substring match.
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("hookSpecificOutput",{}).get("code",""))' 2>/dev/null || true)"
  [ "$code" = "E-SCHEMA-001" ]
}

@test "BC_2_04_004: missing embedding_status stdout contains decision block" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *'"decision":"block"'* ]]
}

# ===========================================================================
# AC-004 / BC-2.04.004 postconditions on invalid embedding_status value:
# embedding_status: invalid_value → exit 2 + E-SCHEMA-002.
# ===========================================================================

@test "BC_2_04_004: invalid embedding_status exits 2 with E-SCHEMA-002" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-bad-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/bad-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-002"* ]]
}

@test "BC_2_04_004: invalid embedding_status E-SCHEMA-002 at hookSpecificOutput.code" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-bad-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/bad-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("hookSpecificOutput",{}).get("code",""))' 2>/dev/null || true)"
  [ "$code" = "E-SCHEMA-002" ]
}

# ===========================================================================
# AC-010 / BC-2.04.004 edge case EC-002:
# embedding_status: null → treated as invalid value (E-SCHEMA-002), not missing (E-SCHEMA-001).
# ===========================================================================

@test "BC_2_04_004: embedding_status null exits 2 with E-SCHEMA-002" {
  # Inline content — null value is a distinct case from absent field.
  local content
  content="$(printf '%s' '---
title: Null Embedding
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: null
---

# Null Embedding')"
  local file_path="${BRAIN_DIR}/wiki/technology/null-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-002"* ]]
}

@test "BC_2_04_004: embedding_status null does not emit E-SCHEMA-001 (missing vs invalid distinction)" {
  local content
  content="$(printf '%s' '---
title: Null Embedding
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: null
---

# Null Embedding')"
  local file_path="${BRAIN_DIR}/wiki/technology/null-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" != *"E-SCHEMA-001"* ]]
}

# ===========================================================================
# AC-005 / BC-2.04.004 edge case EC-001:
# No YAML frontmatter block (no --- fence) → exit 2 + E-SCHEMA-004.
# ===========================================================================

@test "BC_2_04_004: no frontmatter exits 2 with E-SCHEMA-004" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-no-frontmatter.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/no-frontmatter.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-004"* ]]
}

@test "BC_2_04_004: no frontmatter E-SCHEMA-004 at hookSpecificOutput.code" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-no-frontmatter.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/no-frontmatter.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("hookSpecificOutput",{}).get("code",""))' 2>/dev/null || true)"
  [ "$code" = "E-SCHEMA-004" ]
}

# ===========================================================================
# AC-006 / BC-2.04.004 edge case EC-003 + invariant 3:
# yq absent from PATH → exit 2 + E-SCHEMA-005 (fail-closed).
# ===========================================================================

@test "BC_2_04_004: yq absent from PATH exits 2 with E-SCHEMA-005" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-full-valid.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/valid-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  # Build an isolated PATH directory containing only the required tools, definitively
  # excluding yq regardless of where it is installed on the CI runner.
  local isolated_dir
  isolated_dir="$(mktemp -d)"
  local cmd cmd_path
  for cmd in jq bash env printf cat awk head date python3; do
    cmd_path="$(command -v "$cmd" 2>/dev/null || true)"
    [[ -n "$cmd_path" ]] && ln -sf "$cmd_path" "${isolated_dir}/${cmd}"
  done
  run bash -c "printf '%s' '${payload}' | PATH='${isolated_dir}' CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  rm -rf "$isolated_dir"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-005"* ]]
}

# ===========================================================================
# AC-007 / BC-2.04.005 postconditions on missing mandatory field:
# Missing title → exit 2 + E-SCHEMA-006 + missing_fields array naming the field.
# ===========================================================================

@test "BC_2_04_005: missing title exits 2 with E-SCHEMA-006" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-title.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-title.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-006"* ]]
}

@test "BC_2_04_005: missing title stdout contains title in missing_fields" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-title.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-title.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local missing
  missing="$(printf '%s' "$output" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(json.dumps(d.get("hookSpecificOutput",{}).get("missing_fields",[])))' 2>/dev/null || true)"
  [[ "$missing" == *"title"* ]]
}

# ===========================================================================
# AC-008 / BC-2.04.005 postconditions on invalid type:
# type: concept (not in allowed set) → exit 2 + E-SCHEMA-007.
# ===========================================================================

@test "BC_2_04_005: invalid type exits 2 with E-SCHEMA-007" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-bad-type.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/bad-type.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-007"* ]]
}

@test "BC_2_04_005: invalid type E-SCHEMA-007 at hookSpecificOutput.code" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-bad-type.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/bad-type.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("hookSpecificOutput",{}).get("code",""))' 2>/dev/null || true)"
  [ "$code" = "E-SCHEMA-007" ]
}

# ===========================================================================
# AC-008 / BC-2.04.005 invariant 2 — all 6 valid type values are accepted.
# Parameterized via separate @test blocks (bats has no native parametrize).
# Each valid type: concepts, people, frameworks, syntheses, observations, questions.
# ===========================================================================

@test "BC_2_04_005: type concepts is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Concepts Page
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Concepts')"
  local file_path="${BRAIN_DIR}/wiki/technology/concepts-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_005: type people is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: People Page
type: people
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# People')"
  local file_path="${BRAIN_DIR}/wiki/technology/people-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_005: type frameworks is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Frameworks Page
type: frameworks
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Frameworks')"
  local file_path="${BRAIN_DIR}/wiki/technology/frameworks-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_005: type syntheses is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Syntheses Page
type: syntheses
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Syntheses')"
  local file_path="${BRAIN_DIR}/wiki/technology/syntheses-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_005: type observations is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Observations Page
type: observations
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Observations')"
  local file_path="${BRAIN_DIR}/wiki/technology/observations-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_005: type questions is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Questions Page
type: questions
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Questions')"
  local file_path="${BRAIN_DIR}/wiki/technology/questions-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-009 / BC-2.04.005 invariant 3 + BC-2.04.004 invariant 1:
# Write to sources/** → applies sources schema (title, url, ingested_at,
# source_id, topic). embedding_status requirement does NOT apply.
# ===========================================================================

@test "BC_2_04_005: source path applies sources schema — exits 0 without embedding_status" {
  local content
  content="$(cat "${FIXTURE_DIR}/source-page-valid.md")"
  local file_path="${BRAIN_DIR}/sources/ai/valid-source.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_005: source path does not require embedding_status field" {
  # A source page without embedding_status must succeed (sources schema does not include it).
  local content
  content="$(printf '%s' '---
title: Source Without Embedding Status
url: https://example.com/article
ingested_at: 2026-01-01T00:00:00Z
source_id: no-embed-source
topic: ml
---

# Source Without Embedding Status')"
  local file_path="${BRAIN_DIR}/sources/ai/no-embed-source.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# BC-2.04.004 invariant 1 — non-wiki, non-source path → early exit 0 (skip).
# The hook must not validate paths outside wiki/** and sources/**.
# ===========================================================================

@test "BC_2_04_004: non-wiki non-source path exits 0 skip" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-no-frontmatter.md")"
  local file_path="${BRAIN_DIR}/briefs/brief-001.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# Edge cases: malformed / empty stdin → exit 2, fail-closed.
# BC-2.04.004 invariant 3 (fail-closed on unreadable input).
# ===========================================================================

@test "BC_2_04_004: malformed stdin exits 2 failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "BC_2_04_004: empty stdin exits 2 failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

# ===========================================================================
# AC-011 / VP-005 / BC-2.04.004 postconditions §event emission:
# Blocked wiki write → stderr JSONL contains frontmatter.schema.violated.
# Valid wiki write → stderr JSONL contains frontmatter.schema.validated.
# ===========================================================================

@test "VP_005: violated schema emits frontmatter.schema.violated event to stderr" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"frontmatter.schema.violated"* ]]
}

@test "VP_005: violated schema stderr event contains hook_name validate-frontmatter-schema.sh" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-missing-embedding.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-embedding.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-frontmatter-schema.sh"* ]]
}

@test "VP_005: valid schema emits frontmatter.schema.validated event to stderr" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-full-valid.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/valid-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"frontmatter.schema.validated"* ]]
}

@test "VP_005: valid schema stderr event contains hook_name validate-frontmatter-schema.sh" {
  local content
  content="$(cat "${FIXTURE_DIR}/wiki-page-full-valid.md")"
  local file_path="${BRAIN_DIR}/wiki/technology/valid-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"validate-frontmatter-schema.sh"* ]]
}

# ===========================================================================
# AC-007 / BC-2.04.005: missing multiple fields — all absent fields listed.
# Ensures the hook collects ALL missing fields, not just the first one found.
# ===========================================================================

@test "BC_2_04_005: missing multiple mandatory fields exits 2 with E-SCHEMA-006" {
  # Page with title, type, and embedding_status present — but missing BOTH created and source_ids.
  # This ensures the hook reaches E-SCHEMA-006 (not E-SCHEMA-001 for missing embedding_status)
  # and collects ALL missing non-embedding fields in the missing_fields array.
  local content
  content="$(printf '%s' '---
title: Partial Page
type: concepts
embedding_status: pending
---

# Partial Page')"
  local file_path="${BRAIN_DIR}/wiki/technology/partial-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-006"* ]]
  # Both missing fields must appear in the output.
  [[ "$output" == *"created"* ]]
  [[ "$output" == *"source_ids"* ]]
}

# ===========================================================================
# BC-2.04.005 test vector: source_ids: [] (empty list) is valid on wiki page.
# BC-2.04.005 EC-003 — empty list for source_ids is explicitly allowed.
# ===========================================================================

@test "BC_2_04_005: source_ids empty list is valid on wiki page — exits 0" {
  # The full-valid fixture already uses source_ids: [] — this is explicit coverage.
  local content
  content="$(printf '%s' '---
title: Empty Source Ids
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Empty Source Ids')"
  local file_path="${BRAIN_DIR}/wiki/technology/empty-source-ids.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# BC-2.04.004 invariant 2 — embedding_status is case-sensitive.
# "Pending" (capital P) must be rejected as invalid (not in pending|computed|stale).
# ===========================================================================

@test "BC_2_04_004: embedding_status Pending uppercase is rejected with E-SCHEMA-002" {
  local content
  content="$(printf '%s' '---
title: Case Sensitive Test
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: Pending
---

# Case Sensitive')"
  local file_path="${BRAIN_DIR}/wiki/technology/case-sensitive.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-002"* ]]
}

# ===========================================================================
# BC-2.04.004 invariant 2 — all three valid embedding_status values accepted.
# computed and stale (in addition to pending tested above in AC-002).
# ===========================================================================

@test "BC_2_04_004: embedding_status computed is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Computed Page
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: computed
---

# Computed')"
  local file_path="${BRAIN_DIR}/wiki/technology/computed-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_004: embedding_status stale is valid — exits 0" {
  local content
  content="$(printf '%s' '---
title: Stale Page
type: concepts
created: 2026-01-01
source_ids: []
embedding_status: stale
---

# Stale')"
  local file_path="${BRAIN_DIR}/wiki/technology/stale-page.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# C02 / BC-2.04.005: missing type field → exit 2 + E-SCHEMA-006
# (type is a mandatory wiki field; its absence is a missing-field violation,
# not an invalid-value violation — E-SCHEMA-007 requires the key to be present)
# ===========================================================================

@test "BC_2_04_005: missing type exits 2 with E-SCHEMA-006" {
  local content
  content="$(printf '%s' '---
title: Missing Type
created: 2026-01-01
source_ids: []
embedding_status: pending
---

# Missing Type')"
  local file_path="${BRAIN_DIR}/wiki/technology/missing-type.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-006"* ]]
  [[ "$output" == *"type"* ]]
}

# ===========================================================================
# I02 / BC-2.04.005 invariant 3: sources schema negative test.
# Source page missing url and topic → exit 2 + E-SCHEMA-006.
# ===========================================================================

@test "BC_2_04_005: source missing mandatory fields exits 2 with E-SCHEMA-006" {
  # Source page has title, ingested_at, source_id — but is missing url and topic.
  local content
  content="$(printf '%s' '---
title: Bad Source
ingested_at: 2026-01-01T00:00:00Z
source_id: bad-source
---

# Bad Source')"
  local file_path="${BRAIN_DIR}/sources/ai/bad-source.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-006"* ]]
  [[ "$output" == *"url"* ]]
  [[ "$output" == *"topic"* ]]
}

# ===========================================================================
# I03 / BC-2.04.004 invariant 3: malformed YAML frontmatter → exit 2 + E-SCHEMA-003.
# The hook must catch yq parse failures explicitly, not via generic ERR trap.
# ===========================================================================

@test "BC_2_04_004: malformed YAML frontmatter exits 2 with E-SCHEMA-003" {
  # Frontmatter with an unterminated flow sequence — invalid YAML that yq cannot parse.
  local content
  content="$(printf '%s' '---
title: [unterminated
---

# Bad YAML')"
  local file_path="${BRAIN_DIR}/wiki/technology/bad-yaml.md"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-003"* ]]
}

# ===========================================================================
# BC-2.04.004 Edit-tool disk-read fallback:
# When tool_name=Edit, tool_input.content is absent; hook reads from disk.
# These two tests exercise lines 111-113 of the hook (the fallback path).
# ===========================================================================

@test "BC_2_04_004: Edit tool_name reads frontmatter from disk (valid wiki page)" {
  # Write a valid wiki page to disk so the hook can read it.
  mkdir -p "${BRAIN_DIR}/wiki/concepts"
  printf '%s\n' \
    '---' \
    'title: Edit Test' \
    'type: concepts' \
    'created: 2026-01-01' \
    'source_ids: []' \
    'embedding_status: pending' \
    '---' \
    '' \
    '# Edit Test' \
    > "${BRAIN_DIR}/wiki/concepts/edit-test.md"

  local file_path="${BRAIN_DIR}/wiki/concepts/edit-test.md"
  # Build Edit payload WITHOUT content field — jq omits the key entirely.
  local payload
  payload="$(jq -cn \
    --arg cwd "${BRAIN_DIR}" \
    --arg fp "${file_path}" \
    '{"session_id":"test","cwd":$cwd,"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":$fp,"old_string":"Edit Test","new_string":"Edited Test","replace_all":false},"tool_use_id":"edit-001","tool_result":{"type":"text","text":"Edit applied","exit_code":0}}')"

  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "BC_2_04_004: Edit tool_name reads frontmatter from disk (missing embedding_status)" {
  # Write an invalid wiki page to disk — missing required embedding_status field.
  mkdir -p "${BRAIN_DIR}/wiki/concepts"
  printf '%s\n' \
    '---' \
    'title: Edit Bad' \
    'type: concepts' \
    'created: 2026-01-01' \
    'source_ids: []' \
    '---' \
    '' \
    '# Edit Bad' \
    > "${BRAIN_DIR}/wiki/concepts/edit-bad.md"

  local file_path="${BRAIN_DIR}/wiki/concepts/edit-bad.md"
  local payload
  payload="$(jq -cn \
    --arg cwd "${BRAIN_DIR}" \
    --arg fp "${file_path}" \
    '{"session_id":"test","cwd":$cwd,"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":$fp,"old_string":"old","new_string":"new","replace_all":false},"tool_use_id":"edit-002","tool_result":{"type":"text","text":"Edit applied","exit_code":0}}')"

  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SCHEMA-001"* ]]
}
