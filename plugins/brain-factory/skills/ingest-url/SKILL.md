---
name: ingest-url
description: "Fetch a URL via Defuddle, write cleaned content to sources/{topic}/, and record the entry in manifest.json — rejecting duplicates before any fetch."
argument-hint: "<url> [topic]"
allowed-tools:
  - Read
  - Write
  - Bash
---

## Iron Law

Never write a source file or update the manifest without first checking manifest.json for the URL; sources are immutable once ingested.

## Red Flags

- Calling Defuddle or writing any file before the duplicate guard passes.
- Scanning `sources/` directory to detect duplicates instead of reading `manifest.json`.
- Writing directly to `manifest.json` — always use `manifest-write.sh` (atomic `.tmp` + `mv`).
- Proceeding after a non-zero exit from `defuddle-fetch.mjs` or `manifest-write.sh`.
- Using `.claude/templates/` paths — always use `${CLAUDE_PLUGIN_ROOT}/templates/`.

## Announce-at-Start

"Ingesting URL: <url> into topic: <topic>"

## Procedure

1. **Node 22+ check.** Verify `node --version` returns v22 or higher. If not, exit with E-INGEST-005: "Node 22+ required for Defuddle. Install from nodejs.org."

2. **Read manifest and run duplicate guard.** Run `jq -r --arg url "$URL" '.sources[] | select(.url == $url) | .source_id' "${BRAIN_DIR}/.brain/manifest.json"`. If a slug is returned, emit `ingest.url.rejected_duplicate` via `hook-event-emit.sh` with fields `url` and `existing_slug`, then exit with E-INGEST-001: "URL already ingested as <slug>. Sources are immutable." If no duplicate found, emit `ingest.url.started` via `hook-event-emit.sh` with fields `url` and `topic`.

3. **Fetch and clean with Defuddle.** Run `node "${CLAUDE_PLUGIN_ROOT}/scripts/defuddle-fetch.mjs" "$URL"`. On non-zero exit, propagate the error (E-INGEST-002 for non-200 HTTP or network error, E-INGEST-003 for empty content, E-INGEST-012 for invalid/unsupported URL scheme — only http:// and https:// are permitted). On success, capture cleaned markdown from stdout; extract title from stderr JSON metadata (`{"title":"..."}`).

4. **Derive slug.** Normalize the URL path to kebab-case: strip scheme+host, strip query string, convert non-alphanumeric to hyphens, lowercase, trim leading/trailing hyphens.

5. **Write source file.** Create `${BRAIN_DIR}/sources/${TOPIC}/${SLUG}.md` with YAML frontmatter: `title`, `url`, `ingested_at` (ISO 8601 UTC), `source_id` (the slug), `topic`, `embedding_status: pending`. Append Defuddle output as the body. Emit `ingest.url.source_written` via `hook-event-emit.sh` with fields `url`, `topic`, `slug`, and `file_path`.

6. **Atomic manifest update.** Export `BRAIN_DIR` and source `${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh`. Call `manifest_write '{"source_id":"<slug>","url":"<url>","topic":"<topic>","ingested_at":"<ts>","last_ingest":"<ts>","chunks":[],"embeddings_model":null}' "${BRAIN_DIR}/.brain/manifest.json"`. On failure (E-INGEST-008), delete the source file written in step 5 and exit with the error.

7. **[STORY-017 stub] Wiki generation.** Wiki page generation from the ingested source is not implemented in this story. STORY-017 will replace this stub with the wiki generation and token-logging pipeline.

8. **Report success.** Output: "Ingested <url> as <slug> in topic <topic>."

## Quality Bar

- All 54 tests in `plugins/brain-factory/tests/ingest-url.bats` pass.
- `manifest-write.sh` is shellcheck-clean and shfmt-normalized.
- No `find` or `ls` call on `sources/` during ingest.
- Source file contains all 6 required frontmatter fields.
- Manifest entry contains all 7 required fields.
- Duplicate URL rejected before Defuddle is called (verified by invocation counter).

## Output

On success:
```
Ingested <url> as <slug> in topic <topic>.
```

On failure, one of the E-INGEST-NNN error codes from `scripts/event-catalog.json` with the corresponding human-readable message.
