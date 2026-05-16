---
document_type: verification-property
id: VP-012
title: "Manifest write atomicity and last_ingest field correctness"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.03.002, BC-2.06.003]
created: 2026-05-15
status: proposed
---

# VP-012: Manifest write atomicity and last_ingest field correctness

## Property Statement

This VP covers two related manifest correctness properties:

**P1 — Write atomicity (BC-2.03.002):** A manifest.json write that is interrupted between the mktemp write and the mv step leaves the original manifest.json unchanged. The manifest is never in a partial-write state visible to concurrent readers or subsequent hook invocations. After a successful write, manifest.json is valid JSON.

**P2 — last_ingest field correctness (BC-2.06.003):** After a successful source ingest, the per-source entry in manifest.json contains a `last_ingest` field populated with an ISO 8601 timestamp string. In v0.x sources are write-once (immutable after creation), so `last_ingest` equals `ingested_at` for the same operation. The field must be present, non-null, and parseable as ISO 8601 (not an empty string or a Unix epoch integer).

## Verification Mechanism

bats (integration.bats) — two test groups:

### Group 1: Write atomicity (BC-2.03.002)

```bash
@test "manifest-write.sh: interrupted write leaves original intact" {
  local vault="${TEMP_BRAIN}"
  local manifest="${vault}/.brain/manifest.json"
  
  # Establish baseline manifest
  echo '{"version":"1","sources":{},"last_updated":"2026-01-01"}' > "$manifest"
  local original; original="$(cat "$manifest")"
  
  # Simulate interrupted write by overriding mv with a failing version
  mv() { return 1; }
  export -f mv
  
  # Attempt to write new content
  run bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh" \
    "$manifest" '{"version":"1","sources":{"sources/ai/test.md":{}},"last_updated":"2026-01-15"}'
  assert_failure
  
  # Original manifest unchanged
  local after; after="$(cat "$manifest")"
  assert_equal "$original" "$after"
  
  # No temp file leaked
  assert_equal "0" "$(ls "${manifest}."* 2>/dev/null | wc -l)"
  
  unset -f mv
}

@test "manifest-write.sh: successful write produces valid JSON" {
  run bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh" \
    "${TEMP_BRAIN}/.brain/manifest.json" \
    '{"version":"1","sources":{},"last_updated":"2026-01-15"}'
  assert_success
  run jq -e '.' "${TEMP_BRAIN}/.brain/manifest.json"
  assert_success "manifest.json is not valid JSON after write"
}
```

### Group 2: last_ingest field correctness (BC-2.06.003)

```bash
@test "ingest: manifest entry has last_ingest field after source ingest" {
  # Run full ingest on a fixture markdown source
  run bash "${CLAUDE_PLUGIN_ROOT}/skills/ingest-source/run.sh" \
    "${BATS_TEST_DIRNAME}/fixtures/sample-source.md" \
    --vault "${TEMP_BRAIN}"
  assert_success

  # Locate the manifest entry for the ingested source
  local manifest="${TEMP_BRAIN}/.brain/manifest.json"
  local last_ingest
  last_ingest="$(jq -r '.sources | to_entries[0].value.last_ingest' "$manifest")"

  # Field must be present and non-null
  refute [ "$last_ingest" = "null" ]
  refute [ -z "$last_ingest" ]

  # Field must be ISO 8601 parseable (YYYY-MM-DDThh:mm:ssZ format)
  assert_output - <<'ISO'
  # date -d parses ISO 8601; if it fails, last_ingest is malformed
ISO
  run date -d "$last_ingest" "+%s"
  assert_success "last_ingest field '${last_ingest}' is not ISO 8601"
}

@test "ingest: last_ingest equals ingested_at in write-once v0.x" {
  run bash "${CLAUDE_PLUGIN_ROOT}/skills/ingest-source/run.sh" \
    "${BATS_TEST_DIRNAME}/fixtures/sample-source.md" \
    --vault "${TEMP_BRAIN}"
  assert_success

  local manifest="${TEMP_BRAIN}/.brain/manifest.json"
  local ingested_at; ingested_at="$(jq -r '.sources | to_entries[0].value.ingested_at' "$manifest")"
  local last_ingest; last_ingest="$(jq -r '.sources | to_entries[0].value.last_ingest' "$manifest")"

  # In v0.x sources are write-once; the two timestamps are set in the same operation
  assert_equal "$ingested_at" "$last_ingest"
}
```

## Assumed Prerequisites

- `manifest-write.sh` helper exists in `hooks/lib/` (ADR-016)
- `ingest-source/run.sh` skill available in test context (Phase 3 deliverable)
- Temp directory available for test vault
- `tests/fixtures/sample-source.md` fixture present

## Counterexamples

**Atomicity counterexamples (P1):**
- `manifest.json` is written directly (without tmp-file + mv pattern) — if the process is killed mid-write, the file is partially written (invalid JSON)
- The temp file from a failed write is not cleaned up (file leak — would confuse subsequent manifest reads)
- A successful write produces JSON with an extraneous trailing newline that makes it unparseable by `jq` (malformed output)

**last_ingest counterexamples (P2):**
- The `last_ingest` field is absent from the manifest entry after a successful ingest (violates BC-2.06.003)
- The `last_ingest` field is present but contains a Unix epoch integer instead of an ISO 8601 string (wrong format)
- The `last_ingest` field is an empty string (null-equivalent — violates the non-null requirement)

## Status

proposed — pending Phase 3 implementation of manifest-write.sh and ingest-source skill

## Changelog

### v1.1 (2026-05-16)

**STRUCTURAL FIX (F-PASS2-C3):** Extended VP-012 to cover BC-2.06.003 (`last_ingest` field
correctness). VP-012 frontmatter claimed BC-2.06.003 but the Property Statement and bats
tests covered only manifest atomicity. Added Group 2 test harness asserting: `last_ingest`
field present, non-null, ISO 8601 parseable, and equal to `ingested_at` (write-once v0.x
invariant). Title updated to reflect dual scope. VP-INDEX matrix and coverage summary
updated to 64/64 with SS-06 row amended.
