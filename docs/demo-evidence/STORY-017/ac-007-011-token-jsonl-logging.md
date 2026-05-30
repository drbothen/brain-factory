# AC-007 through AC-011: Token JSONL Logging (BC-2.02.003)

BC: BC-2.02.003 — token record write on every ingest
Script: `plugins/brain-factory/scripts/log-tokens.sh`
Test file: `plugins/brain-factory/tests/skills.bats`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-007 | JSONL record appended with all 7 required fields |
| AC-008 | `.brain/logs/` and log file auto-created when absent |
| AC-009 | Record appended even on partial failure; wiki_pages_created = actual count |
| AC-010 | input_tokens: -1, output_tokens: -1 when count unavailable; append never fails |
| AC-011 | `jq -c '.'` on each line succeeds (valid JSONL per line) |

## Evidence

### AC-007: All fields present (happy path demo)

`log-tokens.sh` output written to `.brain/logs/ingest-tokens.jsonl`:

```json
{
  "timestamp": "2026-05-30T18:43:27Z",
  "url": "https://example.com/article",
  "source_id": "example-article",
  "input_tokens": 1250,
  "output_tokens": 890,
  "wiki_pages_created": 7,
  "duration_seconds": 12
}
```

All 7 required fields present. Types: timestamp string (ISO 8601), url string,
source_id string, input_tokens integer, output_tokens integer,
wiki_pages_created integer, duration_seconds integer.

Exit: 0

### AC-008: Auto-create `.brain/logs/`

The script creates `$BRAIN_DIR/.brain/logs/` via `mkdir -p` before appending.
Verified by bats test 7 and 8, which use a fresh temp directory with no pre-existing
`.brain/` hierarchy. If the directory were not created, the `>>` redirect would fail
with `set -euo pipefail` active, causing the test to fail.

### AC-010: -1 sentinel for unavailable token counts

```json
{
  "timestamp": "2026-05-30T18:43:30Z",
  "url": "https://example.com/incomplete",
  "source_id": "incomplete-article",
  "input_tokens": -1,
  "output_tokens": -1,
  "wiki_pages_created": 3,
  "duration_seconds": 5
}
```

Bats coverage:
```
ok 7 BC_2_02_003: log-tokens.sh writes input_tokens: -1 when token count unavailable (AC-010)
ok 8 BC_2_02_003: log-tokens.sh succeeds even when token counts are -1 (AC-010)
```

Test 7 asserts the -1 value is present in the JSONL record.
Test 8 asserts exit code 0 even with -1 inputs.

### AC-011: JSONL validity

Manual verification: `cat ingest-tokens.jsonl | jq empty` → exit 0 on both records
above. The -1 integer values are valid JSON numerics per RFC 7159 §6.

Bats tests 7 and 8 exercise `jq` parsing of the written record as part of their
assertion logic — a record that fails `jq` parsing would cause the test assertion
to fail.

## Lint evidence

```
ok 15 BC_2_02_003: scripts/log-tokens.sh passes shellcheck (structural Red Gate)
ok 18 BC_2_02_003: scripts/log-tokens.sh passes shfmt normalization (structural Red Gate)
```
