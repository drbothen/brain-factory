#!/usr/bin/env bats
# STORY-011 Red Gate tests: validate-publish-state.sh PostToolUse hook
# Traces to: BC-2.04.010
# VP coverage: VP-002 (PostToolUse trigger: publish state machine enforcement;
#              invalid state transition → exit 2 + E-PUBLISH-001;
#              missing status field → exit 2 + E-PUBLISH-002)
#
# RED GATE — all behavioral tests MUST FAIL until the hook is implemented.
# Structural tests (shebang, set -euo) may pass against the stub.
#
# Prior-state detection: the hook uses `git show HEAD:<file>` for Write operations
# and `tool_input.old_string` for Edit operations (per STORY-011 §Prior-state
# retrieval). Test setup initialises a git repo in BRAIN_DIR and commits the
# prior version so `git show HEAD:<path>` works for transition tests. For new-file
# tests, no prior commit exists (git show returns non-zero → no prior state).

setup() {
  PLUGIN_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  HOOK="${PLUGIN_DIR}/hooks/validate-publish-state.sh"
  FIXTURES_DIR="${PLUGIN_DIR}/tests/fixtures"
  export CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}"

  # Isolated temp brain directory with a git repo so git show HEAD:<file> works.
  BRAIN_DIR="$(mktemp -d)"
  git -C "${BRAIN_DIR}" init -q
  git -C "${BRAIN_DIR}" config user.email "test@example.com"
  git -C "${BRAIN_DIR}" config user.name "Test"
  mkdir -p "${BRAIN_DIR}/drafts/linkedin"
  mkdir -p "${BRAIN_DIR}/to-publish/linkedin"
  mkdir -p "${BRAIN_DIR}/published/linkedin"
}

teardown() {
  rm -rf "${BRAIN_DIR}"
}

# ---------------------------------------------------------------------------
# Helper: build frontmatter content string for a given status value.
# Uses a temp file and printf '%s\n' per line to avoid macOS printf '---' flag issue.
# Arguments:
#   $1 — status value (e.g. "draft", "ready", "published")
#   $2 — optional: set to "no-status" to omit the status field entirely
# Writes the content to a temp file and prints the absolute path.
# Caller must read the path and clean up if needed.
# ---------------------------------------------------------------------------
_make_content_file() {
  local status_val="$1"
  local mode="${2:-normal}"
  local tmp
  tmp="$(mktemp)"
  if [ "${mode}" = "no-status" ]; then
    {
      printf '%s\n' "---"
      printf '%s\n' "title: Test Content"
      printf '%s\n' "---"
      printf '%s\n' "# Test Content"
      printf '%s\n' ""
      printf '%s\n' "Content here."
    } > "${tmp}"
  else
    {
      printf '%s\n' "---"
      printf '%s\n' "title: Test Content"
      printf '%s\n' "status: ${status_val}"
      printf '%s\n' "---"
      printf '%s\n' "# Test Content"
      printf '%s\n' ""
      printf '%s\n' "Content here."
    } > "${tmp}"
  fi
  printf '%s' "${tmp}"
}

# ---------------------------------------------------------------------------
# Helper: build a PostToolUse payload for a Write call on a content file.
# Arguments:
#   $1 — absolute file_path embedded in the payload
#   $2 — content string (already written to file_path on disk)
# Outputs the JSON string to stdout.
# Content is embedded as a JSON string; special chars are escaped.
# ---------------------------------------------------------------------------
_payload() {
  local file_path="$1"
  local content="$2"
  # Escape content for JSON: backslash, double-quote, then replace newlines with \n.
  local escaped
  escaped="$(printf '%s' "${content}" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' '\001' | sed 's/\001/\\n/g')"
  printf '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":"%s","permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"Write","tool_input":{"file_path":"%s","content":"%s"},"tool_use_id":"test-publish-011","tool_result":{"type":"text","text":"File written","exit_code":0}}' \
    "${BRAIN_DIR}" "${file_path}" "${escaped}"
}

# ---------------------------------------------------------------------------
# Helper: write a content file with given status and commit it to git HEAD.
# Used to establish prior state that the hook reads via `git show HEAD:<path>`.
# Arguments:
#   $1 — absolute file path
#   $2 — status value (e.g. "draft", "ready", "published")
# ---------------------------------------------------------------------------
_commit_prior_state() {
  local abs_path="$1"
  local prior_status="$2"
  local tmp
  tmp="$(_make_content_file "${prior_status}")"
  cp "${tmp}" "${abs_path}"
  rm -f "${tmp}"
  git -C "${BRAIN_DIR}" add "${abs_path}"
  git -C "${BRAIN_DIR}" commit -q -m "prior state: ${prior_status}"
}

# ===========================================================================
# AC-008 / BC-2.04.010 precondition 1 + ADR-002 §hook-contract:
# Structural contract — shebang, set -euo pipefail, no eval, no bare exit.
# ===========================================================================

@test "test_BC_2_04_010_hook_starts_with_correct_shebang" {
  run head -1 "${HOOK}"
  [ "$status" -eq 0 ]
  [ "$output" = "#!/usr/bin/env bash" ]
}

@test "test_BC_2_04_010_hook_has_set_euo_pipefail_within_first_10_lines" {
  run bash -c "head -10 '${HOOK}' | grep -q 'set -euo pipefail'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_010_hook_does_not_use_eval" {
  # eval is forbidden per CLAUDE.md §Forbidden patterns — shell injection surface.
  run grep -n '\beval\b' "${HOOK}"
  # grep exits 0 when it finds a match — we want NO match (exit 1 from grep).
  [ "$status" -ne 0 ]
}

@test "test_BC_2_04_010_hook_has_no_bare_exit_without_code" {
  # Every exit must be followed by 0, 1, or 2. Bare 'exit' with no argument forbidden.
  local bare_exits
  bare_exits="$(grep -E '^\s*exit\s*$' "${HOOK}" || true)"
  [ -z "$bare_exits" ]
}

# ===========================================================================
# AC-009 / BC-2.04.010 postconditions §valid/new + EC-001:
# New file (not tracked in git) with status: draft → exit 0.
# No prior commit → git show HEAD:<path> fails → prior_status="" → creation.
# ===========================================================================

@test "test_BC_2_04_010_new_file_status_draft_exits_0" {
  # File does NOT exist in git history → new file case → exit 0.
  local file_path="${BRAIN_DIR}/drafts/linkedin/new-post.md"
  local tmp
  tmp="$(_make_content_file "draft")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-010 / BC-2.04.010 postconditions §valid transition + invariant 1:
# draft → ready: exit 0.
# ready → published: exit 0.
# ===========================================================================

@test "test_BC_2_04_010_draft_to_ready_exits_0" {
  # Prior state: draft committed to git.
  # New state: ready written to disk.
  # Hook reads prior state via git show HEAD:<path> → validates draft→ready → exit 0.
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "ready")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_010_ready_to_published_exits_0" {
  # Prior state: ready committed to git.
  # New state: published written to disk.
  local file_path="${BRAIN_DIR}/to-publish/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "ready"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# AC-011 / BC-2.04.010 postconditions §invalid + EC-002:
# draft → published (skipping ready) → exit 2 + E-PUBLISH-001.
# ===========================================================================

@test "test_BC_2_04_010_draft_to_published_exits_2_with_E_PUBLISH_001" {
  # Prior state: draft committed to git.
  # New state: published — skips ready → invalid transition.
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-001"* ]]
}

@test "test_BC_2_04_010_draft_to_published_stdout_contains_from_and_to_state" {
  # BC-2.04.010 postcondition: message must include the from-state and to-state.
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"draft"* ]]
  [[ "$output" == *"published"* ]]
}

@test "test_BC_2_04_010_draft_to_published_E_PUBLISH_001_in_structured_field" {
  # HIGH: verify E-PUBLISH-001 is at the structured code field, not just anywhere in output.
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.code // .hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-PUBLISH-001" ]
}

# ===========================================================================
# AC-012 / BC-2.04.010 invariant 2:
# Reverse transition published → draft → exit 2 + E-PUBLISH-001.
# ===========================================================================

@test "test_BC_2_04_010_published_to_draft_exits_2_with_E_PUBLISH_001" {
  # Prior state: published committed to git.
  # New state: draft — reverse transition, always blocked.
  local file_path="${BRAIN_DIR}/published/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "published"

  local tmp
  tmp="$(_make_content_file "draft")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-001"* ]]
}

@test "test_BC_2_04_010_ready_to_draft_exits_2_with_E_PUBLISH_001" {
  # ready → draft is also a reverse transition, always blocked.
  local file_path="${BRAIN_DIR}/to-publish/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "ready"

  local tmp
  tmp="$(_make_content_file "draft")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-001"* ]]
}

# ===========================================================================
# AC-013 / BC-2.04.010 invariant 4 + EC-003:
# status field absent → exit 2 + E-PUBLISH-002.
# ===========================================================================

@test "test_BC_2_04_010_missing_status_exits_2_with_E_PUBLISH_002" {
  # File has frontmatter but no status field → exit 2 + E-PUBLISH-002.
  local file_path="${BRAIN_DIR}/drafts/linkedin/no-status-post.md"
  local tmp
  tmp="$(_make_content_file "" "no-status")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-002"* ]]
}

@test "test_BC_2_04_010_missing_status_E_PUBLISH_002_in_structured_field" {
  # HIGH: verify E-PUBLISH-002 is at the structured code field, not just a bare substring.
  local file_path="${BRAIN_DIR}/drafts/linkedin/no-status-post.md"
  local tmp
  tmp="$(_make_content_file "" "no-status")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}' 2>/dev/null"
  [ "$status" -eq 2 ]
  local code
  code="$(printf '%s' "$output" | jq -r '.code // .hookSpecificOutput.code' 2>/dev/null || true)"
  [ "$code" = "E-PUBLISH-002" ]
}

# ===========================================================================
# AC-014 / BC-2.04.010 postconditions §event emission:
# Invalid transition → stderr contains publish.state.transition_rejected + from_state + to_state.
# Valid/new → stderr contains publish.state.transition_accepted.
# ===========================================================================

@test "test_BC_2_04_010_invalid_emits_rejected_event" {
  # BC-2.04.010 postcondition: stderr JSONL contains "publish.state.transition_rejected".
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"publish.state.transition_rejected"* ]]
}

@test "test_BC_2_04_010_valid_emits_accepted_event" {
  # BC-2.04.010 postcondition: stderr JSONL contains "publish.state.transition_accepted".
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "ready")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)"
  [[ "$stderr_out" == *"publish.state.transition_accepted"* ]]
}

@test "test_BC_2_04_010_rejected_event_has_correct_from_to" {
  # Parse stderr JSONL for transition_rejected and verify from_state and to_state fields.
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true

  local from_state
  from_state="$(printf '%s\n' "$stderr_out" | grep 'publish.state.transition_rejected' | jq -r '.from_state' 2>/dev/null || true)"
  local to_state
  to_state="$(printf '%s\n' "$stderr_out" | grep 'publish.state.transition_rejected' | jq -r '.to_state' 2>/dev/null || true)"
  [ "$from_state" = "draft" ]
  [ "$to_state" = "published" ]
}

@test "test_BC_2_04_010_rejected_event_contains_hook_name" {
  # Verify hook_name in the rejected event.
  local file_path="${BRAIN_DIR}/drafts/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  local stderr_out
  stderr_out="$(printf '%s' "${payload}" | CLAUDE_PLUGIN_ROOT="${PLUGIN_DIR}" BRAIN_DIR="${BRAIN_DIR}" bash "${HOOK}" 2>&1 1>/dev/null)" || true
  [[ "$stderr_out" == *"validate-publish-state.sh"* ]]
}

# ===========================================================================
# AC-015 / CLAUDE.md §Conventions §shellcheck:
# Hook must pass shellcheck.
# ===========================================================================

@test "test_BC_2_04_010_shellcheck_clean" {
  run shellcheck "${HOOK}"
  [ "$status" -eq 0 ]
}

# ===========================================================================
# Edge cases: malformed stdin + empty stdin → fail-closed (exit 2).
# BC-2.04.010 invariant 4: status mandatory; unreadable input treated as missing status.
# ===========================================================================

@test "test_BC_2_04_010_malformed_json_exits_2_failclosed" {
  run bash -c "printf 'not valid json' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

@test "test_BC_2_04_010_empty_stdin_exits_2_failclosed" {
  run bash -c "printf '' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
}

# ---------------------------------------------------------------------------
# Helper: build a PostToolUse payload for an Edit call on a content file.
# For Edit operations the hook reads prior status from tool_input.old_string.
# Uses jq --arg to correctly JSON-encode multi-line strings — the manual
# tr/sed approach strips the \n escape sequences before jq can parse them,
# causing the hook to see old_string as a single concatenated line and fail
# to parse frontmatter from it.
# Arguments:
#   $1 — absolute file_path embedded in the payload
#   $2 — old_string content (the prior version of the file — contains old frontmatter)
#   $3 — new_string content (the replacement content — contains new frontmatter)
# Outputs JSON to a temp file and prints the temp file path.
# Caller must read the temp file and clean it up.
# ---------------------------------------------------------------------------
_edit_payload_file() {
  local file_path="$1"
  local old_string="$2"
  local new_string="$3"
  local tmp
  tmp="$(mktemp)"
  jq -cn \
    --arg cwd "${BRAIN_DIR}" \
    --arg file_path "${file_path}" \
    --arg old_string "${old_string}" \
    --arg new_string "${new_string}" \
    '{"session_id":"test-session","transcript_path":"/tmp/transcript","cwd":$cwd,"permission_mode":"default","effort":{"level":"medium"},"hook_event_name":"PostToolUse","tool_name":"Edit","tool_input":{"file_path":$file_path,"old_string":$old_string,"new_string":$new_string},"tool_use_id":"test-publish-edit-011","tool_result":{"type":"text","text":"File edited","exit_code":0}}' \
    > "${tmp}"
  printf '%s' "${tmp}"
}

# ===========================================================================
# Finding 1: Edit tool code path — hook reads prior status from old_string.
# BC-2.04.010 postconditions §valid transition + §invalid transition.
# ===========================================================================

@test "test_BC_2_04_010_edit_draft_to_ready_exits_0" {
  # Edit payload: old_string has status: draft, file on disk has status: ready.
  # Hook reads prior status from old_string (not git) → validates draft→ready → exit 0.
  local file_path="${BRAIN_DIR}/drafts/linkedin/edit-post.md"

  # Write the NEW version (ready) to disk — PostToolUse fires after the edit.
  local new_tmp
  new_tmp="$(_make_content_file "ready")"
  cp "${new_tmp}" "${file_path}"
  rm -f "${new_tmp}"

  # Build old_string content (draft status frontmatter).
  local old_tmp
  old_tmp="$(_make_content_file "draft")"
  local old_content new_content
  old_content="$(cat "${old_tmp}")"
  rm -f "${old_tmp}"
  new_content="$(cat "${file_path}")"

  local payload_file
  payload_file="$(_edit_payload_file "${file_path}" "${old_content}" "${new_content}")"
  run bash -c "cat '${payload_file}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  rm -f "${payload_file}"
  [ "$status" -eq 0 ]
}

@test "test_BC_2_04_010_edit_draft_to_published_exits_2" {
  # Edit payload: old_string has status: draft, file on disk has status: published.
  # Skips ready → invalid transition → exit 2 + E-PUBLISH-001.
  local file_path="${BRAIN_DIR}/drafts/linkedin/edit-post.md"

  # Write the NEW version (published) to disk.
  local new_tmp
  new_tmp="$(_make_content_file "published")"
  cp "${new_tmp}" "${file_path}"
  rm -f "${new_tmp}"

  # Build old_string content (draft status frontmatter).
  local old_tmp
  old_tmp="$(_make_content_file "draft")"
  local old_content new_content
  old_content="$(cat "${old_tmp}")"
  rm -f "${old_tmp}"
  new_content="$(cat "${file_path}")"

  local payload_file
  payload_file="$(_edit_payload_file "${file_path}" "${old_content}" "${new_content}")"
  run bash -c "cat '${payload_file}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  rm -f "${payload_file}"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-001"* ]]
}

# ===========================================================================
# Finding 2: published → ready reverse transition untested.
# BC-2.04.010 invariant 2: reverse transitions are always blocked.
# ===========================================================================

@test "test_BC_2_04_010_published_to_ready_exits_2_with_E_PUBLISH_001" {
  # Prior state: published committed to git.
  # New state: ready — reverse transition, always blocked.
  local file_path="${BRAIN_DIR}/published/linkedin/my-post.md"
  _commit_prior_state "${file_path}" "published"

  local tmp
  tmp="$(_make_content_file "ready")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-001"* ]]
}

# ===========================================================================
# Finding 3: New file with non-draft initial status untested.
# BC-2.04.010 postconditions §new file: only draft is valid initial status.
# ===========================================================================

@test "test_BC_2_04_010_new_file_status_published_exits_2_with_E_PUBLISH_001" {
  # No prior git history for this file → new file case.
  # New file written with status: published → must be rejected (must start as draft).
  local file_path="${BRAIN_DIR}/drafts/linkedin/brand-new-published.md"
  local tmp
  tmp="$(_make_content_file "published")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 2 ]
  [[ "$output" == *"E-PUBLISH-001"* ]]
}

# ===========================================================================
# Finding 5: Same-state idempotent write untested.
# BC-2.04.010 postconditions §idempotent: same-state writes are always allowed.
# ===========================================================================

@test "test_BC_2_04_010_same_state_draft_to_draft_exits_0" {
  # Prior state: draft committed to git.
  # New state: draft (no change) — idempotent write → exit 0.
  local file_path="${BRAIN_DIR}/drafts/linkedin/idempotent-post.md"
  _commit_prior_state "${file_path}" "draft"

  local tmp
  tmp="$(_make_content_file "draft")"
  cp "${tmp}" "${file_path}"
  rm -f "${tmp}"
  local content
  content="$(cat "${file_path}")"
  local payload
  payload="$(_payload "${file_path}" "${content}")"
  run bash -c "printf '%s' '${payload}' | CLAUDE_PLUGIN_ROOT='${PLUGIN_DIR}' BRAIN_DIR='${BRAIN_DIR}' bash '${HOOK}'"
  [ "$status" -eq 0 ]
}
