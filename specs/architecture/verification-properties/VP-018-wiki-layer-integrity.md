---
document_type: verification-property
id: VP-018
title: "Wiki layer: page schema, embedding state machine, and partial-failure fan-out"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.05.001, BC-2.05.003, BC-2.05.004, BC-2.05.005]
created: 2026-05-15
status: proposed
---

# VP-018: Wiki layer: page schema, embedding state machine, and partial-failure fan-out

## Property Statement

**Seven-check lint health pass (BC-2.05.001):** `/brain:lint-wiki` runs all seven
checks — (1) wikilink integrity, (2) frontmatter schema, (3) index-log coherence,
(4) orphan pages, (5) page-type taxonomy, (6) source ID citation validity,
(7) embedding_status presence — and emits a structured JSON report. All seven checks
run on every invocation (no skipping). On a synthetic 10K-page wiki, total wall-clock
duration is under 600 seconds.

**Rename-page slug immutability (BC-2.05.003):** The `rename-page` skill, not direct
`mv`, is the only correct path for changing a wiki page slug after creation. Renaming
via direct `mv` would break backlinks; the `rename-page` skill updates all wikilink
references before moving the file.

**Embedding state machine (BC-2.05.004):** The `embedding_status` field in wiki page
frontmatter follows a one-way state machine: `pending → indexing → indexed`. Reverse
transitions are blocked. A page in `indexed` state cannot revert to `pending` except
via explicit `/brain:re-embed` with operator confirmation.

**Partial-failure fan-out structure (BC-2.05.005):** When a batch wiki operation
encounters per-page hook blocks, the operation continues processing remaining pages
and returns a structured partial-failure report listing each blocked page with its
E-SCOPE-NNN code. The successfully written pages are not rolled back.

## Verification Mechanism

bats (skills.bats + integration.bats):

```bash
# --- BC-2.05.001: lint-wiki seven-check pass ---

@test "lint-wiki: all 7 checks present in output report on healthy wiki" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-lint-test"
  setup_fixture_brain_with_pages "$brain_dir" 100

  run bash "${PLUGIN_ROOT}/skills/lint-wiki/run.sh" --brain "$brain_dir"
  assert_success
  # All 7 check names present in JSON report
  for check in wikilink-integrity frontmatter-schema index-log-coherence \
    orphan-pages page-type-taxonomy source-id-citation embedding-status-presence; do
    assert_output --partial "\"name\":\"$check\""
  done
  assert_output --partial '"overall":"PASS"'
}

@test "lint-wiki: broken wikilink causes check-1 FAIL with issues list" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-broken-link-test"
  setup_fixture_brain "$brain_dir"
  # Write a page with a broken wikilink
  cat > "$brain_dir/wiki/concepts/test-page.md" <<'EOF'
---
title: Test Page
created: "2026-05-15"
embedding_status: pending
source_ids: [fixture-source]
---
See [[nonexistent-page]] for more.
EOF

  run bash "${PLUGIN_ROOT}/skills/lint-wiki/run.sh" --brain "$brain_dir"
  assert_failure 1
  assert_output --partial '"name":"wikilink-integrity"'
  assert_output --partial '"status":"FAIL"'
  assert_output --partial 'nonexistent-page'
}

# --- BC-2.05.004: embedding state machine ---

@test "wiki embedding_status: pending→indexing→indexed transitions are valid" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-embed-test"
  setup_fixture_brain "$brain_dir"
  local page="$brain_dir/wiki/concepts/embed-test.md"
  # Create page with embedding_status: pending
  cat > "$page" <<'EOF'
---
title: Embed Test
created: "2026-05-15"
embedding_status: pending
source_ids: [fixture]
---
Content here.
EOF

  # Transition pending → indexing (valid)
  yq eval '.embedding_status = "indexing"' -i "$page"
  run bash "${PLUGIN_ROOT}/hooks/validate-frontmatter-schema.sh" \
    < <(echo "{\"tool\":\"Write\",\"input\":{\"path\":\"wiki/concepts/embed-test.md\"},\"output\":{}}")
  assert_success

  # Transition indexing → indexed (valid)
  yq eval '.embedding_status = "indexed"' -i "$page"
  run bash "${PLUGIN_ROOT}/hooks/validate-embedding-state.sh" \
    < <(echo "{\"tool\":\"Write\",\"input\":{\"path\":\"wiki/concepts/embed-test.md\",\
\"content\":$(jq -Rs . < "$page")},\"output\":{}}")
  assert_success
}

@test "wiki embedding_status: indexed→pending reverse transition is blocked" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-embed-reverse-test"
  setup_fixture_brain "$brain_dir"
  local page="$brain_dir/wiki/concepts/embed-reverse.md"
  cat > "$page" <<'EOF'
---
title: Reverse Test
embedding_status: indexed
source_ids: [fixture]
---
Content.
EOF

  # Attempt to set embedding_status back to pending — hook must block
  run bash "${PLUGIN_ROOT}/hooks/validate-embedding-state.sh" \
    < <(printf '{"tool":"Write","input":{"path":"wiki/concepts/embed-reverse.md",
"content":"---\ntitle: Reverse Test\nembedding_status: pending\nsource_ids: [fixture]\n---\nContent.\n"},"output":{}}')
  assert_failure 2
  assert_output --partial '"code":"E-EMBED-001"'
}

# --- BC-2.05.005: partial-failure fan-out ---

@test "batch wiki write: per-page failures reported individually, successes not rolled back" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-batch-test"
  setup_fixture_brain "$brain_dir"

  # Simulate a batch that writes 3 pages, where 1 is blocked by the hook
  run bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/batch-article" \
    --inject-hook-block-for-type=people \
    --brain "$brain_dir" --yes
  # Partial failure exit 1 (not exit 2)
  assert_failure 1
  # Report structure with per-page outcomes
  assert_output --partial '"status":"partial"'
  assert_output --partial '"blocked_pages"'
  # Committed pages NOT rolled back
  local written_count; written_count="$(find "$brain_dir/wiki" -name "*.md" \
    ! -name "index.md" ! -name "log.md" | wc -l | tr -d ' ')"
  assert [ "$written_count" -ge 1 ] "All pages rolled back — partial failure should preserve committed pages"
}
```

## Assumed Prerequisites

- `setup_fixture_brain_with_pages` creates a brain with N pre-generated wiki pages
- `validate-embedding-state.sh` exists as a PostToolUse hook enforcing the state machine
  (this may be merged into `validate-frontmatter-schema.sh` — VP is agnostic to the
  implementation file name; the behavior is what must hold)
- `yq` available for direct frontmatter manipulation in tests
- Scale test (10K pages / 600s) runs in the CI slow-test lane, gated by `BATS_SLOW=1`

## Counterexamples

- `lint-wiki` skips the orphan-pages check on empty wiki (vacuously passes) but the report
  does not emit the check name — the seven-check report assertion catches this gap
- A batch wiki write that encounters a blocked page calls `exit 2` on the first failure
  instead of continuing — this violates the partial-failure fan-out contract; the
  bats batch test catches the incorrect exit code and the missing `blocked_pages` field
- The `embedding_status` field is validated as a free-form string rather than an enum —
  a value like `"queued"` would be accepted silently; the state-machine hook must enumerate
  the valid values (`pending`, `indexing`, `indexed`) and reject all others

## Status

proposed — pending Phase 3 implementation of lint-wiki skill, validate-embedding-state.sh,
and the batch partial-failure mechanism in skills.bats
