# AC-005 and AC-006: File-Not-Found and Duplicate-Slug Guards (BC-2.03.001)

BC: BC-2.03.001 — canonical test vector (file not found) and edge case EC-003 (duplicate slug)
Script: `plugins/brain-factory/scripts/validate-ingest-path.sh`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-005 | File does not exist at resolved path → E-INGEST-011: "File not found: `<path>`"; exit 2. No file read performed. |
| AC-006 | Same slug already in `.brain/manifest.json` → E-INGEST-001: "Source already ingested as `<slug>`. Sources are immutable."; exit 2. No file read or wiki generation. |

## Evidence

### AC-005: Nonexistent file — E-INGEST-011 exit 2

```
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh <vault>/sources/does-not-exist.md
stdout: {"level":"error","code":"E-INGEST-011","message":"File not found: /private/<vault>/sources/does-not-exist.md"}
exit: 2
```

**Result: PASS** — missing file detected after vault-root check; E-INGEST-011 emitted, exit 2.

### AC-006: Already-ingested slug — E-INGEST-001 exit 2

```
Manifest seeded with slug: my-article
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh <vault>/sources/ai/my-article.md
stdout: {"level":"error","code":"E-INGEST-001","message":"Source already ingested as my-article. Sources are immutable."}
exit: 2
```

Manifest pre-populated with entry:
```json
{
  "source_id": "my-article",
  "path": "sources/ai/my-article.md",
  "topic": "ai",
  "ingested_at": "<ts>",
  "last_ingest": "<ts>",
  "chunks": [],
  "embeddings_model": null
}
```

**Result: PASS** — duplicate slug found in manifest before any file read; E-INGEST-001 emitted, exit 2.

### bats coverage

```
ok 29 BC_2_03_001: nonexistent file emits E-INGEST-011 exit 2 (AC-005)
ok 34 BC_2_03_001: already-ingested slug in manifest emits E-INGEST-001 exit 2 (AC-006)
```

Raw output: `raw-output/validate-ingest-path-demos.txt` (DEMO 7, DEMO 11), `raw-output/skills-bats-run.txt`
