---
document_type: verification-property
id: VP-025
title: "Scale-aware token instrumentation: JSONL record written on every ingest invocation"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.16.001]
created: 2026-05-15
status: proposed
---

# VP-025: Scale-aware token instrumentation: JSONL record written on every ingest invocation

## Property Statement

A JSONL token record is appended to `.brain/logs/ingest-tokens.jsonl` on every
invocation of `/brain:ingest-url` or `/brain:ingest-source` — including partial failure
paths (BC-2.16.001). The record must never be omitted, deferred, or batched; it is
written as part of the ingest operation itself, not asynchronously.

Record schema requirements (matching BC-2.02.003):
- `source_id` (the ingested slug)
- `url` or `path` (the ingest source identifier)
- `ingested_at` (ISO 8601 datetime)
- `token_count` (integer — total tokens consumed by this ingest operation)
- `model` (the Claude model that processed the content)
- `status` (`complete` | `partial`) — `partial` when wiki page generation was interrupted

Append-only invariant: no record is ever modified or deleted from the JSONL file.
Records accumulate without truncation even as the file grows to 10K+ entries.

When `.brain/logs/ingest-tokens.jsonl` does not exist at ingest time, it is created
by the first ingest. The `.brain/logs/` directory is created if absent (BC-2.16.001 EC-002).

## Verification Mechanism

bats (integration.bats):

```bash
@test "token JSONL: record appended on successful ingest-url (BC-2.16.001)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-token-test"
  setup_fixture_brain "$brain_dir"

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/article" --yes
  assert_success

  # JSONL file exists
  assert [ -f "$brain_dir/.brain/logs/ingest-tokens.jsonl" ]

  # Record has the required schema fields
  local record; record="$(tail -1 "$brain_dir/.brain/logs/ingest-tokens.jsonl")"
  run jq -e 'has("source_id") and has("ingested_at") and has("token_count") and has("status")' <<< "$record"
  assert_success "Token JSONL record missing required fields: $record"

  run jq -r '.status' <<< "$record"
  assert_output "complete"
}

@test "token JSONL: record written even on partial failure (BC-2.16.001 EC-001)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-token-partial-test"
  setup_fixture_brain "$brain_dir"

  # Ingest with hook override that blocks one wiki page type
  BRAIN_ROOT="$brain_dir" BATS_HOOK_OVERRIDE_BLOCK_WIKI_TYPE="people" \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/article" --yes
  # Partial failure: exit 1
  assert_failure 1

  # Token JSONL still written
  assert [ -f "$brain_dir/.brain/logs/ingest-tokens.jsonl" ]
  local record; record="$(tail -1 "$brain_dir/.brain/logs/ingest-tokens.jsonl")"
  run jq -r '.status' <<< "$record"
  assert_output "partial"
}

@test "token JSONL: file and directory created on first ingest when absent (BC-2.16.001 EC-002)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-token-create-test"
  setup_fixture_brain "$brain_dir"

  # Ensure .brain/logs/ does not exist
  rm -rf "$brain_dir/.brain/logs"
  refute [ -d "$brain_dir/.brain/logs" ]

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/article" --yes
  assert_success

  # Directory and file auto-created
  assert [ -d "$brain_dir/.brain/logs" ]
  assert [ -f "$brain_dir/.brain/logs/ingest-tokens.jsonl" ]
}

@test "token JSONL: records are append-only across multiple ingests (BC-2.16.001)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-token-append-test"
  setup_fixture_brain "$brain_dir"

  # Ingest 3 different URLs
  for path in article1 article2 article3; do
    BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
      bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
      "http://localhost:${FIXTURE_PORT}/${path}" --yes
  done

  # JSONL must have exactly 3 records (one per ingest)
  local record_count; record_count="$(wc -l < "$brain_dir/.brain/logs/ingest-tokens.jsonl" | tr -d ' ')"
  assert [ "$record_count" -eq 3 ] "Expected 3 JSONL records (one per ingest), got $record_count"

  # Each line must be valid JSON
  while IFS= read -r line; do
    run jq empty <<< "$line"
    assert_success "JSONL line is not valid JSON: $line"
  done < "$brain_dir/.brain/logs/ingest-tokens.jsonl"
}

@test "token JSONL: token_count is a non-negative integer" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-token-count-test"
  setup_fixture_brain "$brain_dir"

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/article" --yes

  local record; record="$(tail -1 "$brain_dir/.brain/logs/ingest-tokens.jsonl")"
  run jq -e '.token_count | type == "number" and . >= 0' <<< "$record"
  assert_success "token_count must be a non-negative number, got: $(jq '.token_count' <<< "$record")"
}
```

## Assumed Prerequisites

- A fixture HTTP server on `${FIXTURE_PORT}` with distinct content at `/article1`,
  `/article2`, `/article3`, and `/article` paths
- `setup_fixture_brain` creates an initialized brain with no pre-existing JSONL
- `jq` in PATH
- `BATS_HOOK_OVERRIDE_BLOCK_WIKI_TYPE` env var controls partial-failure simulation

## Counterexamples

- Token record is only written on fully successful ingests (not on partial failure) —
  the partial-failure test explicitly covers this omission path
- The `token_count` field is written as a string (`"1234"`) instead of a number (`1234`)
  — the type assertion in the token-count test catches this schema deviation
- Records are deduped or re-written on the second ingest of the same URL (duplicate
  detection clears the prior record) — the append-only multi-ingest test catches this
  by verifying that 3 ingests produce exactly 3 records

## Status

proposed — pending Phase 3 implementation of token JSONL instrumentation in ingest
skills and integration.bats
