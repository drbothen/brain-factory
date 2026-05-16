---
document_type: verification-property
id: VP-015
title: "URL ingest pipeline: Defuddle fetch to manifest delta to wiki pages"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004, BC-2.02.006]
created: 2026-05-15
status: proposed
---

# VP-015: URL ingest pipeline: Defuddle fetch to manifest delta to wiki pages

## Property Statement

For a valid URL not yet in the manifest, `/brain:ingest-url <url>` executes the
complete ingest pipeline:

1. `scripts/defuddle-fetch.mjs` is invoked — never raw curl or WebFetch on raw HTML
   (BC-2.02.001 Invariant 1).
2. The source file `sources/{topic}/{slug}.md` is created with mandatory frontmatter
   including `embedding_status: pending` (BC-2.02.001 Postcondition 1).
3. `.brain/manifest.json` is updated with the new entry containing all required fields:
   `source_id`, `url`, `topic`, `ingested_at`, `last_ingest`, `chunks`, `embeddings_model`
   (BC-2.02.004 contract).
4. Between 5 and 15 wiki pages are created in `wiki/{type}/{slug}.md` paths; each passes
   frontmatter schema validation; each has `source_ids` containing the ingest source slug
   (BC-2.02.002).
5. A JSONL token record is appended to `.brain/logs/ingest-tokens.jsonl` (BC-2.02.003).
6. The skill exits 0 with a summary line.

Duplicate URL re-ingest is blocked with E-INGEST-001 and exit 2. Non-200 HTTP responses
block with E-INGEST-002. Quarantine-hook block propagates as E-INGEST-004.
Sub-linear manifest delta: manifest is updated with ONLY the new entry (delta update),
not a full rewrite of all entries (BC-2.02.006).

## Verification Mechanism

bats (integration.bats) — end-to-end ingest on a fixture brain with a mock URL:

```bash
@test "ingest-url: source file, manifest, wiki pages, token JSONL all written on success" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-ingest-test"
  # Setup: initialized brain with fixture URL mock (localhost test server or fixture content)
  setup_fixture_brain "$brain_dir"
  local test_url="http://localhost:${FIXTURE_PORT}/article"

  CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" BRAIN_ROOT="$brain_dir" \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" "$test_url" --yes

  assert_success

  # Source file created (BC-2.02.001)
  local slug; slug="localhost-article"
  assert [ -f "$brain_dir/sources/ai/${slug}.md" ] "Source file not created"
  run yq eval '.embedding_status' "$brain_dir/sources/ai/${slug}.md"
  assert_output "pending"

  # Manifest updated with all required fields (BC-2.02.004)
  run jq --arg sid "$slug" '.sources[] | select(.source_id == $sid)' \
    "$brain_dir/.brain/manifest.json"
  assert_output --partial '"url"'
  assert_output --partial '"ingested_at"'
  assert_output --partial '"chunks"'
  assert_output --partial '"embeddings_model"'

  # Wiki pages created (BC-2.02.002) — between 5 and 15
  local wiki_count; wiki_count="$(find "$brain_dir/wiki" -name "*.md" \
    ! -name "index.md" ! -name "log.md" | wc -l | tr -d ' ')"
  assert [ "$wiki_count" -ge 5 ] "Expected >= 5 wiki pages, got $wiki_count"
  assert [ "$wiki_count" -le 15 ] "Expected <= 15 wiki pages, got $wiki_count"

  # Token JSONL record written (BC-2.02.003)
  assert [ -f "$brain_dir/.brain/logs/ingest-tokens.jsonl" ] "Token JSONL not created"
  local record_count; record_count="$(wc -l < "$brain_dir/.brain/logs/ingest-tokens.jsonl" | tr -d ' ')"
  assert [ "$record_count" -ge 1 ] "Token JSONL has no records"
}

@test "ingest-url: duplicate URL rejected with E-INGEST-001 (BC-2.02.001 EC-001)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-dup-test"
  setup_fixture_brain "$brain_dir"
  local test_url="http://localhost:${FIXTURE_PORT}/article"
  # First ingest succeeds
  BRAIN_ROOT="$brain_dir" bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" "$test_url" --yes
  # Second ingest fails
  run bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" "$test_url" --yes
  assert_failure 2
  assert_output --partial '"code":"E-INGEST-001"'
}

@test "ingest-url: manifest delta is a new entry only, not a full rewrite (BC-2.02.006)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-delta-test"
  setup_fixture_brain "$brain_dir"
  # Seed manifest with a pre-existing entry
  jq '.sources += [{"source_id":"existing","url":"http://existing.example","topic":"ai",
    "ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z",
    "chunks":[],"embeddings_model":null}]' \
    "$brain_dir/.brain/manifest.json" > "${brain_dir}/.brain/manifest.json.tmp"
  mv "${brain_dir}/.brain/manifest.json.tmp" "$brain_dir/.brain/manifest.json"

  BRAIN_ROOT="$brain_dir" bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/new-article" --yes

  # Both entries present (delta adds, doesn't replace)
  local source_count; source_count="$(jq '.sources | length' "$brain_dir/.brain/manifest.json")"
  assert [ "$source_count" -eq 2 ] "Expected 2 manifest entries, got $source_count"
  run jq '.sources[] | select(.source_id == "existing")' "$brain_dir/.brain/manifest.json"
  assert_output --partial '"existing"'
}
```

## Assumed Prerequisites

- A fixture HTTP server (or mock) runs on `${FIXTURE_PORT}` during bats execution
  (managed by `tests/setup_file` / `tests/teardown_file` helpers)
- `setup_fixture_brain` helper initializes a temp brain directory with an empty manifest
- `PLUGIN_ROOT` env var resolves to the plugin installation directory in the test environment
- `jq` and `yq` are in PATH

## Counterexamples

- The manifest is fully rewritten on each ingest rather than delta-updated — at 10K sources
  this grows from O(1) per write to O(n) per write, breaking the sub-linear latency guarantee
- Token JSONL is not written on a partial failure (some wiki pages blocked by hook) — the
  record must always be written, with `status: partial` to reflect the incomplete state
- Fewer than 5 wiki pages are created for a typical-length article without emitting the
  advisory — the wiki-count floor assertion catches this
- The source file is created using `scripts/defuddle-fetch.mjs` not being invoked (raw curl
  fallback) — a process-trace assertion in the bats test would catch the deviation

## Status

proposed — pending Phase 3 implementation of ingest-url skill and integration.bats
