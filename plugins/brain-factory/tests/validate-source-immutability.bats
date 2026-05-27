#!/usr/bin/env bats
# STORY-007 tests: validate-source-immutability.sh PostToolUse hook
# Traces to: BC-2.04.002
# VP coverage: VP-003 (source immutability — existing overwrite blocked, new source allowed,
#              missing manifest fail-closed)

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-source-immutability.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory — the hook reads .brain/manifest.json relative to
  # the BRAIN_DIR env var (or cwd in production; here we use BRAIN_DIR).
  BRAIN_DIR="$(mktemp -d)"
  mkdir -p "${BRAIN_DIR}/.brain"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build a minimal PostToolUse payload for a Write|Edit call.
# Arguments:
#   $1 — absolute file_path embedded in the payload
#   $2 — tool_name (Write or Edit) [default: Write]
# Outputs the JSON string to stdout.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local tool_name="${2:-Write}"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"%s","tool_input":{"file_path":"%s","content":"---\\ntitle: Test\\n---\\n# Test"},"tool_use_id":"test-123","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${tool_name}" "${file_path}"
}

# ===========================================================================
# AC-001 / BC-2.04.002 precondition 2 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_002_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_002_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_002_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_002_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-002 / BC-2.04.002 postconditions §new source write:
# Path NOT in manifest → exit 0 + continue:true stdout + source.added stderr.
# ADR-002 v2.0 schema: {"continue":true,"trace":"...","message":"New source accepted."}
# ===========================================================================

@test "test_BC_2_04_002_new_source_not_in_manifest_exits_0" {
  # manifest-empty.json has sources:{} — no entries at all.
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/new-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_002_new_source_not_in_manifest_stdout_contains_continue_true" {
  # ADR-002 v2.0: allow → {"continue":true,...} (not the retired v1.0 verdict:allow).
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/new-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"continue":true'* ]]
}

@test "test_BC_2_04_002_new_source_stdout_contains_new_source_accepted_message" {
  # MED-002: allow stdout must contain "New source accepted." message text.
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/new-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *"New source accepted."* ]]
}

@test "test_BC_2_04_002_new_source_stdout_contains_trace_field" {
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/new-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"trace"'* ]]
}

# ===========================================================================
# AC-003 / BC-2.04.002 postconditions §overwrite attempt:
# Path IS in manifest → exit 2 + decision:block + E-SOURCE-001 stdout.
# ADR-002 v2.0 schema: {"continue":false,"decision":"block","reason":"...","hookSpecificOutput":{...}}
# ===========================================================================

@test "test_BC_2_04_002_existing_source_in_manifest_exits_2" {
  # manifest-with-source.json registers "sources/ai/existing-source.md"
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  # The hook strips BRAIN_DIR prefix to get the relative path for manifest lookup.
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_002_existing_source_stdout_contains_decision_block" {
  # ADR-002 v2.0: block → {"continue":false,"decision":"block",...} (not the retired v1.0 verdict:block).
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *'"decision":"block"'* ]]
}

@test "test_BC_2_04_002_existing_source_stdout_contains_E_SOURCE_001" {
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SOURCE-001"* ]]
}

@test "test_BC_2_04_002_error_code_in_hookSpecificOutput" {
  # HIGH-002: verify E-SOURCE-001 is at hookSpecificOutput.code (ADR-002 v2.0 schema),
  # not just anywhere in the output string. Substring match alone is insufficient.
  # Suppress stderr so $output only contains the stdout JSON (parseable by jq).
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-SOURCE-001" ]
}

@test "test_BC_2_04_002_existing_source_stdout_contains_rename_page_guidance" {
  # AC-003 stdout must mention /brain:rename-page per the BC postcondition message.
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"rename-page"* ]]
}

# ===========================================================================
# AC-004 / BC-2.04.002 invariant 2 + EC-003:
# manifest.json absent OR malformed → exit 2, fail-closed.
# ===========================================================================

@test "test_BC_2_04_002_malformed_manifest_json_exits_2_failclosed" {
  # MED-001: manifest exists but contains invalid JSON — hook must block (fail-closed).
  # BC-2.04.002 EC-003 covers both "missing" and "malformed" manifest cases.
  printf '%s\n' "not valid json" > "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/any-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_002_missing_manifest_exits_2_failclosed" {
  # BRAIN_DIR/.brain/ exists but no manifest.json inside it — deliberate absence.
  local file_path="${BRAIN_DIR}/sources/ai/any-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_002_missing_manifest_stdout_contains_E_SOURCE_002" {
  local file_path="${BRAIN_DIR}/sources/ai/any-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-SOURCE-002"* ]]
}

# ===========================================================================
# AC-005 / BC-2.04.002 invariant 1:
# Manifest is authority. Path on disk but NOT in manifest → exit 0 (allowed).
# ===========================================================================

@test "test_BC_2_04_002_path_on_disk_but_not_in_manifest_exits_0" {
  # Use empty manifest — no entries.
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  # Create the file on disk inside the temp brain.
  mkdir -p "${BRAIN_DIR}/sources/ai"
  {
    printf '%s\n' "---"
    printf '%s\n' "title: Orphan"
    printf '%s\n' "---"
    printf '%s\n' "# Orphan"
  } > "${BRAIN_DIR}/sources/ai/orphan.md"
  # The file exists on disk but is absent from manifest — hook must allow.
  local file_path="${BRAIN_DIR}/sources/ai/orphan.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  # ADR-002 v2.0: allow → {"continue":true,...}
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# MED-001 / VP-003 / BC-2.04.002 precondition 1:
# Non-source paths (wiki, briefs) → exit 0, no-op (early return).
# The hook only protects sources/** — all other paths are passthrough.
# ===========================================================================

@test "VP_003_non_source_path_wiki_exits_0_noop" {
  # Wiki path — not under sources/ — hook must pass through without manifest lookup.
  # No manifest needed since the hook exits early for non-source paths.
  local file_path="${BRAIN_DIR}/wiki/technology/some-page.md"
  local payload
  payload="$(_payload "${file_path}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
  # ADR-002 v2.0: no-op allow → {"continue":true,...}
  [[ "$output" == *'"continue":true'* ]]
}

# ===========================================================================
# AC-006 / VP-003 / BC-2.04.002 postconditions §event emission:
# Blocked overwrite → stderr JSONL contains source.immutability.violated.
# Allowed new source → stderr JSONL contains source.added.
# ===========================================================================

@test "test_BC_2_04_002_VP_003_blocked_source_emits_immutability_violated_event_to_stderr" {
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  # Capture stderr separately; swallow exit code (hook exits 2 = non-zero).
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"source.immutability.violated"* ]]
}

@test "test_BC_2_04_002_VP_003_blocked_source_stderr_event_contains_hook_name" {
  cp "${FIXTURES_DIR}/manifest-with-source.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/existing-source.md"
  local payload
  payload="$(_payload "${file_path}" "Edit")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-source-immutability.sh"* ]]
}

@test "test_BC_2_04_002_VP_003_allowed_source_emits_source_added_event_to_stderr" {
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/new-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"source.added"* ]]
}

@test "test_BC_2_04_002_VP_003_allowed_source_stderr_event_contains_hook_name" {
  cp "${FIXTURES_DIR}/manifest-empty.json" "${BRAIN_DIR}/.brain/manifest.json"
  local file_path="${BRAIN_DIR}/sources/ai/new-source.md"
  local payload
  payload="$(_payload "${file_path}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"validate-source-immutability.sh"* ]]
}

# ===========================================================================
# Edge case: malformed (non-JSON) stdin → exit 2, fail-closed.
# BC-2.04.002 invariant 2 applies to any unreadable input.
# ===========================================================================

@test "test_BC_2_04_002_malformed_json_stdin_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_002_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

# ===========================================================================
# AC-007 / CLAUDE.md §Conventions §shellcheck + shfmt:
# Hook must pass shellcheck and shfmt normalization checks.
# ===========================================================================

@test "test_BC_2_04_002_hook_passes_shellcheck" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_002_hook_passes_shfmt_normalization" {
  run shfmt -d -i 2 "${HOOK}"
  [ "$status" -eq 0 ]
  [ -z "$output" ]
}

# ===========================================================================
# hooks.json registration: PostToolUse Write|Edit matcher must include
# validate-source-immutability.sh (BC-2.04.002 precondition 1 — hook fires on
# Write|Edit targeting sources/**).
# ===========================================================================

@test "test_BC_2_04_002_hooks_json_has_PostToolUse_section" {
  run grep -q '"PostToolUse"' "${PLUGIN_DIR}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_002_hooks_json_PostToolUse_entry_includes_validate_source_immutability" {
  # Verify the hooks.json PostToolUse Write|Edit chain references
  # validate-source-immutability.sh using ${CLAUDE_PLUGIN_ROOT}.
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
        if 'validate-source-immutability.sh' in cmd:
            found = True
            break
if not found:
    print('ERROR: No PostToolUse entry pointing to validate-source-immutability.sh', file=sys.stderr)
    sys.exit(1)
print('PASS')
"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_002_hooks_json_validate_source_entry_uses_CLAUDE_PLUGIN_ROOT_path" {
  run grep -q 'CLAUDE_PLUGIN_ROOT.*validate-source-immutability.sh\|validate-source-immutability.sh.*CLAUDE_PLUGIN_ROOT' "${PLUGIN_DIR}/hooks/hooks.json"
  [ "$status" -eq 0 ]
}
