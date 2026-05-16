---
document_type: verification-property
id: VP-020
title: "Publishing pipeline: state machine enforcement and LinkedIn API call shape"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.09.001, BC-2.09.004, BC-2.09.005]
created: 2026-05-15
status: proposed
---

# VP-020: Publishing pipeline: state machine enforcement and LinkedIn API call shape

## Property Statement

**State machine enforcement (BC-2.09.004):** The `validate-publish-state.sh` hook
enforces the three-state publish machine: `draft` (file in `drafts/{platform}/`) →
`ready` (file in `to-publish/{platform}/`) → `published` (file in `published/{platform}/`).
Valid transitions (`draft → ready`, `ready → published`) exit 0. Invalid transitions
(`draft → published`, `published → ready`, `published → draft`, `ready → draft`) exit 2
with E-PUBLISH-001. Location and `status` frontmatter field must be consistent; mismatch
exits 2 with E-PUBLISH-001.

**LinkedIn Posts API call shape (BC-2.09.001):** `/brain:publish-content <file>` posts
to LinkedIn via the Posts API (Community Management — not the deprecated UGC API). The
API call includes the correct endpoint, authentication header, and request body shape.
On 201 response: file is moved to `published/linkedin/` and frontmatter updated with
`status: published`, `published_at`, and `linkedin_post_id`. The file is NOT moved until
the API confirms success.

**Directory structure (BC-2.09.005):** The three directories `drafts/linkedin/`,
`to-publish/linkedin/`, and `published/linkedin/` must exist in the brain vault.
Files are located in the correct directory for their current state.

## Verification Mechanism

bats (hooks.bats + skills.bats with LinkedIn DTU mock):

```bash
# --- validate-publish-state.sh hook tests ---

@test "validate-publish-state: ready-state file in to-publish/ → exit 0" {
  local payload; payload="$(jq -n '{
    "tool": "Write",
    "input": {
      "path": "to-publish/linkedin/my-post.md",
      "content": "---\nstatus: ready\ntitle: My Post\n---\nContent."
    },
    "output": {}
  }')"
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-publish-state.sh"
  assert_success
}

@test "validate-publish-state: draft→published skip is blocked with E-PUBLISH-001" {
  local payload; payload="$(jq -n '{
    "tool": "Write",
    "input": {
      "path": "drafts/linkedin/my-draft.md",
      "content": "---\nstatus: published\ntitle: My Post\n---\nContent."
    },
    "output": {}
  }')"
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/validate-publish-state.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-PUBLISH-001"'
}

@test "validate-publish-state: published→draft regression blocked with E-PUBLISH-001" {
  local payload; payload="$(jq -n '{
    "tool": "Write",
    "input": {
      "path": "published/linkedin/old-post.md",
      "content": "---\nstatus: draft\ntitle: Old Post\n---\nContent."
    },
    "output": {}
  }')"
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/validate-publish-state.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-PUBLISH-001"'
}

@test "validate-publish-state: location-status mismatch blocked (file in to-publish with status draft)" {
  local payload; payload="$(jq -n '{
    "tool": "Write",
    "input": {
      "path": "to-publish/linkedin/mismatch-post.md",
      "content": "---\nstatus: draft\ntitle: Mismatch\n---\nContent."
    },
    "output": {}
  }')"
  run bash -c "echo '$payload' | '${CLAUDE_PLUGIN_ROOT}/hooks/validate-publish-state.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-PUBLISH-001"'
}

# --- LinkedIn API call shape (DTU mock) ---

@test "publish-content: LinkedIn Posts API call uses Community Management endpoint" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-publish-test"
  setup_fixture_brain "$brain_dir"
  mkdir -p "$brain_dir/to-publish/linkedin" "$brain_dir/published/linkedin"

  cat > "$brain_dir/to-publish/linkedin/test-post.md" <<'EOF'
---
title: Test LinkedIn Post
status: ready
---
This is a test post under 3000 characters.
EOF

  # Start LinkedIn DTU mock that captures request details
  local mock_log="${BATS_TEST_TMPDIR}/linkedin-mock.log"
  start_linkedin_dtu_mock "$mock_log"

  BRAIN_ROOT="$brain_dir" LINKEDIN_API_BASE="http://localhost:${DTU_PORT}" \
    bash "${PLUGIN_ROOT}/skills/publish-content/run.sh" \
    "$brain_dir/to-publish/linkedin/test-post.md" --yes

  assert_success

  # Verify Posts API endpoint used (not deprecated UGC)
  run grep '"endpoint"' "$mock_log"
  assert_output --partial '/rest/posts'  # Posts API endpoint
  refute_output --partial '/ugcPosts'    # must NOT use deprecated UGC endpoint

  # File moved to published/
  assert [ -f "$brain_dir/published/linkedin/test-post.md" ]
  refute [ -f "$brain_dir/to-publish/linkedin/test-post.md" ]

  # Frontmatter updated
  run yq eval '.status' "$brain_dir/published/linkedin/test-post.md"
  assert_output "published"
  run yq eval '.linkedin_post_id' "$brain_dir/published/linkedin/test-post.md"
  refute_output "null"
}

@test "publish-content: file NOT moved until API confirms 201 success" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-publish-fail-test"
  setup_fixture_brain "$brain_dir"
  mkdir -p "$brain_dir/to-publish/linkedin"

  cat > "$brain_dir/to-publish/linkedin/fail-post.md" <<'EOF'
---
title: Fail Post
status: ready
---
Content.
EOF

  # DTU mock configured to return 500
  BRAIN_ROOT="$brain_dir" LINKEDIN_API_MOCK_STATUS=500 \
    LINKEDIN_API_BASE="http://localhost:${DTU_PORT}" \
    bash "${PLUGIN_ROOT}/skills/publish-content/run.sh" \
    "$brain_dir/to-publish/linkedin/fail-post.md" --yes
  assert_failure

  # File must remain in to-publish/ — not moved
  assert [ -f "$brain_dir/to-publish/linkedin/fail-post.md" ]
  refute [ -f "$brain_dir/published/linkedin/fail-post.md" ]
}
```

## Assumed Prerequisites

- `start_linkedin_dtu_mock` helper starts a lightweight HTTP mock server on `${DTU_PORT}`
  that logs request details to `$mock_log` and returns configurable status codes
- `setup_fixture_brain` creates an initialized brain
- `yq` in PATH for frontmatter assertions
- LinkedIn DTU mock is in the test infrastructure at `tests/dtu/linkedin-mock.sh`

## Counterexamples

- The state machine hook checks `status` frontmatter alone without cross-referencing the
  file's actual directory location — location-status mismatch goes undetected; the
  mismatch bats test catches this gap
- The publish skill moves the file optimistically (before API confirmation), then rolls
  back on failure — this creates a window where `published/` contains a file that was not
  actually published; the API-fail test catches this by verifying the file is still in
  `to-publish/` after a 500 response
- The skill uses the deprecated UGC API endpoint (`/ugcPosts`) instead of the Posts API
  (`/rest/posts`) — the endpoint assertion in the DTU mock log catches this

## Status

proposed — pending Phase 3 implementation of validate-publish-state.sh, publish-content
skill, LinkedIn DTU mock, and hooks.bats / skills.bats
