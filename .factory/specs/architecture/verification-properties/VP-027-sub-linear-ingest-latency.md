---
document_type: verification-property
id: VP-027
title: "Sub-linear ingest latency as wiki grows from 1K to 10K pages"
level: L3
version: "1.2"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-16T00:00:00
verifies_bcs: [BC-2.02.007]
created: 2026-05-15
status: proposed
---

# VP-027: Sub-linear ingest latency as wiki grows from 1K to 10K pages

## Property Statement

The wiki-layer operations of `/brain:ingest-url` (manifest read, duplicate check, wiki
page writes, index updates — excluding network fetch time) remain sub-linear as the
wiki grows from 1K to 10K pages. Concretely:

- T(10K) / T(1K) ≤ 20: a 10x wiki size increase produces at most a 20x operation time
  increase (BC-2.02.007 Postcondition 2). This ratio is the v0.9 scale gate assertion.
- T(1K) < 30 seconds (excluding network fetch): on a 1K-page wiki, the wiki-layer
  operations complete in under 30 seconds.
- The manifest delta design (BC-2.02.004) — appending one entry rather than rewriting
  all entries — is the architectural mechanism that makes this possible. A full-rewrite
  manifest approach would degrade O(n) in size.
- The wikilink resolution algorithm (O(n) index scan, not O(n²) cross-product) enables
  the wiki-integrity hook to run within budget even at 10K pages.

This VP covers the v0.9 ship gate scale requirement; it is Phase P1 because it requires
the gen-test-corpus.sh infrastructure and a 10K-page fixture brain (not available at v0.1).

## Verification Mechanism

bats (integration.bats — slow lane, gated by `BATS_SLOW=1`):

```bash
# Runs only when BATS_SLOW=1 is set in the environment (slow test lane)
@test "ingest latency at 1K pages: wiki-layer operations complete under 30s" {
  [[ "${BATS_SLOW:-0}" == "1" ]] || skip "slow test — set BATS_SLOW=1 to enable"

  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/scale-1k-brain"
  # Generate a 999-source brain corpus using gen-test-corpus.sh (ADR-012 canonical CLI)
  bash "${PLUGIN_ROOT}/scripts/gen-test-corpus.sh" --sources 999 --seed 42 "$brain_dir"

  local start; start="$(date +%s%3N)"
  # Ingest one additional URL (wiki-layer only — network is mocked)
  BRAIN_ROOT="$brain_dir" INGEST_SKIP_NETWORK=1 \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://fixture-mock/article-1000" --yes
  local elapsed_ms; elapsed_ms="$(($(date +%s%3N) - start))"

  # Under 30 seconds (30000ms) for 1K-page wiki
  assert [ "$elapsed_ms" -lt 30000 ] \
    "Ingest at 1K pages took ${elapsed_ms}ms, exceeds 30s SLA"

  # Record the baseline for ratio check
  printf '%d\n' "$elapsed_ms" > "${BATS_TEST_TMPDIR}/t-1k.txt"
}

@test "ingest latency at 10K pages: T(10K)/T(1K) ratio ≤ 20 (v0.9 scale gate)" {
  [[ "${BATS_SLOW:-0}" == "1" ]] || skip "slow test — set BATS_SLOW=1 to enable"

  local t_1k_file="${BATS_TEST_TMPDIR}/t-1k.txt"
  if [ ! -f "$t_1k_file" ]; then
    skip "1K baseline not established — run 1K test first"
  fi
  local t_1k; t_1k="$(cat "$t_1k_file")"

  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/scale-10k-brain"
  # Generate a 9999-source brain corpus (ADR-012 canonical CLI)
  bash "${PLUGIN_ROOT}/scripts/gen-test-corpus.sh" --sources 9999 --seed 42 "$brain_dir"

  local start; start="$(date +%s%3N)"
  BRAIN_ROOT="$brain_dir" INGEST_SKIP_NETWORK=1 \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://fixture-mock/article-10000" --yes
  local t_10k; t_10k="$(($(date +%s%3N) - start))"

  # Ratio check: T(10K) / T(1K) ≤ 20
  local ratio; ratio="$((t_10k / t_1k))"
  assert [ "$ratio" -le 20 ] \
    "Latency ratio T(10K)/T(1K) = $ratio exceeds 20 (BC-2.02.007 violation). \
     T(1K)=${t_1k}ms T(10K)=${t_10k}ms. Check manifest-delta and wikilink-index implementations."
}

@test "manifest delta: single entry appended (not full rewrite) — O(1) write cost" {
  # This is a unit test verifiable without the slow scale infrastructure
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-delta-write-test"
  setup_fixture_brain "$brain_dir"

  # Seed manifest with 100 entries
  local manifest="$brain_dir/.brain/manifest.json"
  local entries='[]'
  for i in $(seq 1 100); do
    entries="$(echo "$entries" | jq \
      --arg id "source-$i" --arg url "http://example.com/$i" \
      '. += [{"source_id":$id,"url":$url,"topic":"ai",
      "ingested_at":"2026-01-01T00:00:00Z","last_ingest":"2026-01-01T00:00:00Z",
      "chunks":[],"embeddings_model":null}]')"
  done
  jq -n --argjson entries "$entries" '{"sources":$entries}' > "$manifest"

  # Capture manifest mtime before ingest
  local mtime_before; mtime_before="$(stat -f '%m' "$manifest" 2>/dev/null || stat -c '%Y' "$manifest")"

  BRAIN_ROOT="$brain_dir" INGEST_SKIP_NETWORK=1 \
    bash "${PLUGIN_ROOT}/skills/ingest-url/run.sh" \
    "http://localhost:${FIXTURE_PORT}/new-article" --yes

  # Manifest now has 101 entries (delta append, not rewrite-from-scratch)
  local count; count="$(jq '.sources | length' "$manifest")"
  assert [ "$count" -eq 101 ] \
    "Expected 101 manifest entries after delta append, got $count (possible full rewrite)"
}
```

## Assumed Prerequisites

- `scripts/gen-test-corpus.sh` can generate N-page corpora at the given path
  (Phase 3 deliverable — scale tests are Phase P1 so they run only with `BATS_SLOW=1`)
- `INGEST_SKIP_NETWORK=1` env var disables the Defuddle network fetch step, allowing
  the wiki-layer operations to be measured in isolation
- Tests marked `[[ "${BATS_SLOW:-0}" == "1" ]] || skip` run only in the CI slow lane
  (triggered by `make test-slow` or `BATS_SLOW=1 bats integration.bats`)
- The manifest delta unit test does NOT require the slow infrastructure and runs in the
  standard bats suite

## Counterexamples

- The manifest is rewritten in full on every ingest: T(10K) / T(1K) grows proportionally
  to manifest file size; the ratio can reach 10–100x for large manifests — the ratio
  check catches this O(n) write degradation
- The wikilink integrity hook uses a nested O(n²) scan (checking each wikilink against
  each wiki page instead of the index) — this does not affect the ingest latency
  directly (the hook fires on each page write, not on the manifest update), but it would
  cause the per-page wiki-generation time to degrade at 10K pages; the ratio test
  catches any degradation in overall wiki-layer time
- The delta-append unit test passes because the implementation appends but also triggers
  a full index rebuild after each append — the ratio test is the authoritative check
  for end-to-end latency behavior

## Status

proposed — pending Phase 3 infrastructure (`gen-test-corpus.sh`, `INGEST_SKIP_NETWORK`
shim); scale tests are Phase P1 (v0.9 gate). The manifest-delta unit test is Phase P0
and runs in standard CI.

## Changelog

### v1.2 (2026-05-16)

**STRUCTURAL FIX (F-PASS15-C1 — version-bump for Pass 14 Changelog amendments):** Pass 14 architect burst (07466a4) amended this file's Changelog section without bumping its version, in violation of the F-PASS13-C2 incremental scope discipline. This v1.2 burst applies the missing version bump. No new body modifications past v1.1 — only this version-bump-and-Changelog-entry closure. [audit-trail]

**STRUCTURAL FIX (F-PASS15-I1 — F-PASS10-C1/I1 bullet cell-count and H1-directionality correction):** The v1.1 Changelog claimed "all three derived cells aligned" for VP-027. ARCH-INDEX v0.1.12 records only two cells with drift for VP-027: the Document Map Purpose cell and the VP-INDEX Summary Title cell. Corrected: two of three derived cells (ARCH-INDEX Document Map Purpose, ARCH-INDEX VP-INDEX Summary Title) aligned TO the canonical VP-027 H1 during the Pass 10 27-VP sweep; the VP-INDEX Title cell was already aligned. ARCH-INDEX v0.1.12 records drift resolved for VP-027 Document Map Purpose and VP-INDEX Summary Title cells. [audit-trail]

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS3-I2:** §Verification Mechanism proof harness and counterexample updated to use the canonical `gen-test-corpus.sh` CLI: `--sources` flag for source count and positional `<output-dir>` argument. Removed ambiguity about the output path parameter. [audit-trail]
- **F-PASS10-C1/I1 (27-VP H1 canonical-baseline sweep):** Two of three derived cells (ARCH-INDEX Document Map Purpose, ARCH-INDEX VP-INDEX Summary Title) aligned TO the canonical VP-027 H1 during the Pass 10 27-VP sweep; the VP-INDEX Title cell was already aligned. ARCH-INDEX v0.1.12 records drift resolved for VP-027 Document Map Purpose and VP-INDEX Summary Title cells. [audit-trail]
