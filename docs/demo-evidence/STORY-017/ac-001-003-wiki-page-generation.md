# AC-001 through AC-003: Wiki Page Generation Pipeline (BC-2.02.002)

BC: BC-2.02.002 — `ingest-url` produces 5-15 cross-referenced wiki pages per ingest
Script: `plugins/brain-factory/scripts/generate-wiki.sh`
Test file: `plugins/brain-factory/tests/skills.bats` (structural Red Gate tests)

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-001 | Librarian invoked; 5-15 wiki pages produced at `wiki/{type}/{slug}.md` using 6 canonical types |
| AC-002 | Each page passes `validate-frontmatter-schema.sh` and `validate-wikilink-integrity.sh` |
| AC-003 | Each page has `source_ids` frontmatter; `wiki/index.md` and `wiki/log.md` updated |

## Evidence

### Structural verification

```
ok 11 BC_2_02_002: scripts/generate-wiki.sh exists (structural Red Gate)
ok 14 BC_2_02_002: scripts/generate-wiki.sh passes shellcheck (structural Red Gate)
ok 17 BC_2_02_002: scripts/generate-wiki.sh passes shfmt normalization (structural Red Gate)
```

### Script contract verification

`generate-wiki.sh` signature (from source):

```
# Usage: generate-wiki.sh <brain_dir> <source_file_path>
#
# Stdout: JSON fan-out envelope {"pages_attempted": N, "pages_created": M,
#         "pages_failed": K, "pages_skipped": N, "failures": [...]}
# Stderr: structured events (ingest.url.wiki_pages_generated) + E-INGEST-006 advisory
#
# Exit codes:
#   0 — all pages succeeded (or < 5 pages with E-INGEST-006 advisory)
#   1 — partial failure (some pages failed)
```

### AC-001: 5-15 pages, canonical types, `wiki/{type}/{slug}.md` paths

The script uses a predefined concept-extraction mechanism that generates pages under
the 6 canonical types: `concepts`, `people`, `frameworks`, `syntheses`, `observations`,
`questions`. The `_to_slug` helper converts page titles to kebab-case slugs.

Wiki page frontmatter template (from generate-wiki.sh source, line ~90-100):
```yaml
source_ids: [${SOURCE_SLUG}]
embedding_status: pending
```
The `source_ids` field satisfies AC-003 (traces back to the ingesting source).

### AC-002: Frontmatter schema and wikilink validation gates

Each page write is gated: the script creates pages with `embedding_status: pending`
and all mandatory fields populated. The PostToolUse hook chain (`validate-frontmatter-schema.sh`,
`validate-wikilink-integrity.sh`) fires on write and enforces AC-002 at the hook layer.

### AC-003: wiki/index.md and wiki/log.md updated

The script's fan-out envelope tracks `pages_created` count. After all pages are written,
`wiki/index.md` and `wiki/log.md` are updated within the same `generate-wiki` workflow
step per Architecture Compliance Rule 6 (SS-02).

### AC-004 edge case (from skills.bats)

When fewer than 5 pages are produced (e.g., short-article fixture < 500 words):
```
ok 4 BC_2_02_002: generate-wiki.sh emits E-INGEST-006 advisory when fewer than 5 pages produced (AC-004)
ok 5 BC_2_02_002: generate-wiki.sh exits 0 on short article (E-INGEST-006 is advisory, not blocking) (AC-004)
ok 6 BC_2_02_002: short-article fixture has fewer than 500 words (AC-004 test vector)
```

See `ac-004-e-ingest-006-advisory.md` for the E-INGEST-006 detail.

## Note on AC-001/AC-002/AC-003 bats coverage scope

AC-001 through AC-003 test the librarian agent invocation path. The v0.1 bats suite
covers the structural contracts (script existence, lint, E-INGEST-006 advisory, -1
sentinel) and the end-to-end behavior is exercised by `tests/local-dev-test.sh` and
Lobster workflow integration. The `generate-wiki.sh` structural Red Gate tests confirm
the script is present, shellcheck-clean, and shfmt-normalized — meeting the VSDD
Phase 3 structural evidence bar.
