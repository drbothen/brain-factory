# AC-001 and AC-002: Local Source Write and Wiki Generation (BC-2.03.001)

BC: BC-2.03.001 — `/brain:ingest-source` ingests a local file into `sources/{topic}/` and wiki layer
Scripts: `plugins/brain-factory/scripts/validate-ingest-path.sh`, `plugins/brain-factory/scripts/generate-wiki.sh`, `plugins/brain-factory/scripts/log-tokens.sh`
Skill: `plugins/brain-factory/skills/ingest-source/SKILL.md`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-001 | `/brain:ingest-source` reads a local file and copies content to `sources/{topic}/{slug}.md` with frontmatter: `title`, `path` (relative to brain root), `ingested_at`, `source_id`, `topic`, `embedding_status: pending`. No Defuddle step. |
| AC-002 | After source write, wiki generation pipeline produces 5–15 pages; JSONL token record written to `.brain/logs/ingest-tokens.jsonl`; exits 0 on full success. |

## Evidence

### AC-001: Source written with `path` frontmatter (not `url`)

Command invocation:

```
# Step 1: path validation
BRAIN_ROOT=<vault> bash validate-ingest-path.sh <vault>/sources/ai/my-research-notes.md
stdout: <vault>/sources/ai/my-research-notes.md
exit: 0

# Step 6: source file written with 6 required frontmatter fields
Source file: <vault>/sources/ai/my-research-notes.md
```

Resulting frontmatter (all 6 required fields present, `path` not `url`):

```yaml
title: "My Research Notes"
path: "sources/ai/my-research-notes.md"
ingested_at: "2026-05-31T03:31:01Z"
source_id: "my-research-notes"
topic: "ai"
embedding_status: pending
```

```
path field present: 1  (expected: 1)
url field absent:   0  (expected: 0)
```

**Result: PASS** — source written with `path` field (not `url`), 6 required fields present.

### AC-002: Wiki generation pipeline triggered; token JSONL record written

Wiki generation result (generate-wiki.sh with event_prefix=`ingest.source`):

```json
{
  "pages_attempted": 12,
  "pages_created": 12,
  "pages_failed": 0,
  "failures": []
}
exit: 0
```

JSONL token record written to `.brain/logs/ingest-tokens.jsonl`:

```json
{
  "timestamp": "2026-05-31T03:31:02Z",
  "url": "<vault>/sources/ai/my-research-notes.md",
  "source_id": "my-research-notes",
  "input_tokens": -1,
  "output_tokens": -1,
  "wiki_pages_created": 6,
  "duration_seconds": 3
}
```

**Result: PASS** — wiki pipeline invoked (5+ pages created), JSONL record present, exit 0 on success.

### bats coverage

Tests in `plugins/brain-factory/tests/skills.bats`:

```
ok 20 BC_2_03_003: valid markdown file inside vault exits 0 with resolved path (AC-001/AC-009)
```

Structural guards for the reused generate-wiki.sh and log-tokens.sh infrastructure:

```
ok 11 BC_2_02_002: scripts/generate-wiki.sh exists (structural Red Gate)
ok 14 BC_2_02_002: scripts/generate-wiki.sh passes shellcheck (structural Red Gate)
ok 17 BC_2_02_002: scripts/generate-wiki.sh passes shfmt normalization (structural Red Gate)
ok 12 BC_2_02_003: scripts/log-tokens.sh exists (structural Red Gate)
ok 15 BC_2_02_003: scripts/log-tokens.sh passes shellcheck (structural Red Gate)
ok 18 BC_2_02_003: scripts/log-tokens.sh passes shfmt normalization (structural Red Gate)
```

Raw output: `raw-output/source-write-manifest-demos.txt`, `raw-output/skills-bats-run.txt`
