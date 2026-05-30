---
name: ingest-source
description: "Validate a local file path within the brain vault, read the file, write it to sources/{topic}/, update the manifest atomically, and trigger wiki generation — propagating per-page failures without silent swallow."
argument-hint: "<path> [--topic <category>]"
allowed-tools:
  - Read
  - Write
  - Bash
---

## Iron Law

Validate the file path is inside the vault before any read; sources are immutable once written; never silently swallow failed wiki pages.

## Red Flags

- Reading any file before the vault-root path check and system-directory hard block pass.
- Using `realpath` instead of `readlink -f` (not available on macOS without GNU coreutils).
- Checking duplicates by scanning `sources/` instead of reading `.brain/manifest.json`.
- Writing directly to `manifest.json` — always delegate to `manifest-write.sh` (atomic `.tmp` + `mv`).
- Invoking Defuddle — local files are read directly; no Defuddle step.
- Using `set +e` anywhere in the skill body to suppress hook-blocked write errors.
- Hardcoding `.claude/templates/` — always use `${CLAUDE_PLUGIN_ROOT}/templates/`.
- Emitting a `hook-event:emit` for an event type not pre-registered in `scripts/event-catalog.json`.

## Announce-at-Start

"Ingesting local file: <path> into topic: <topic>"

## Procedure

1. TODO(STORY-019 impl): Path validation — run `${CLAUDE_PLUGIN_ROOT}/scripts/validate-ingest-path.sh "$PATH_ARG"` (uses `readlink -f`, system-dir hard block, vault-root check via `git rev-parse --show-toplevel`, allowlist from `.brain/policies.yaml`); on exit 2 propagate E-INGEST-009 and stop.

2. TODO(STORY-019 impl): File existence check — verify the resolved path exists and is a regular readable file; on failure exit 2 with E-INGEST-011: "File not found: <path>".

3. TODO(STORY-019 impl): File type detection — inspect extension; image types (`.png`, `.jpg`, `.gif`, `.webp`, `.svg`) → exit 2 with E-INGEST-010; PDF → attempt `pdftotext <path> -`; if `pdftotext` absent → exit 2 with E-INGEST-010; markdown/text → read directly.

4. TODO(STORY-019 impl): Duplicate guard — run `jq` against `.brain/manifest.json` checking for matching slug; if found emit `ingest.source.path_rejected` event and exit 2 with E-INGEST-001: "Source already ingested as <slug>. Sources are immutable."

5. TODO(STORY-019 impl): Emit `ingest.source.started` event via `${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh` with fields `path` and `topic`.

6. TODO(STORY-019 impl): Derive slug — normalize the file basename to kebab-case (strip extension, convert non-alphanumeric to hyphens, lowercase, trim leading/trailing hyphens).

7. TODO(STORY-019 impl): Write source file — create `${BRAIN_DIR}/sources/${TOPIC}/${SLUG}.md` with YAML frontmatter: `title`, `path` (relative to brain root), `ingested_at` (ISO 8601 UTC), `source_id` (the slug), `topic`, `embedding_status: pending`; append file content as body; emit `ingest.source.written` event.

8. TODO(STORY-019 impl): Atomic manifest update — source and call `manifest_write` from `${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh` with entry `{"source_id":"<slug>","path":"<relative-path>","topic":"<topic>","ingested_at":"<ts>","last_ingest":"<ts>","chunks":[],"embeddings_model":null}`; on failure (E-INGEST-008) roll back the source file written in step 7 and exit 2.

9. TODO(STORY-019 impl): Wiki generation — run `${CLAUDE_PLUGIN_ROOT}/scripts/generate-wiki.sh "${BRAIN_DIR}" "${source_file}"`; capture JSON result envelope (`pages_attempted`, `pages_created`, `pages_failed`, `failures`); note exit code for step 11.

10. TODO(STORY-019 impl): Token logging — run `${CLAUDE_PLUGIN_ROOT}/scripts/log-tokens.sh "${BRAIN_DIR}" "${PATH_ARG}" "${SLUG}" "${input_tokens}" "${output_tokens}" "${wiki_pages_created}" "${duration_seconds}"`.

11. TODO(STORY-019 impl): Emit `ingest.source.wiki_pages_generated` event; then emit `ingest.source.completed` event; construct and output the fan-out envelope `{"source_id":"<slug>","pages_attempted":N,"pages_created":M,"pages_failed":K,"failures":[...]}`; exit 1 if `pages_failed > 0`, exit 0 if all pages succeeded.

## Quality Bar

- All tests in `plugins/brain-factory/tests/skills.bats` for ingest-source pass.
- All tests in `plugins/brain-factory/tests/integration.bats` for ingest-source pass.
- `scripts/validate-ingest-path.sh` is shellcheck-clean and shfmt-normalized.
- No `realpath` call anywhere in this skill or its helpers — `readlink -f` only.
- No `find` or `ls` call on `sources/` during ingest.
- No `set +e` anywhere in skill body or helpers (verified by meta-lint).
- No Defuddle invocation.
- Source file frontmatter contains all 6 required fields (`title`, `path`, `ingested_at`, `source_id`, `topic`, `embedding_status`).
- Manifest entry contains `path` field (not `url`) and all 7 required fields.
- Fan-out envelope `failures` array is always present, even when empty.
- `pages_attempted == pages_created + pages_failed` invariant holds in all test scenarios.
- All 5 `ingest.source.*` event types pre-registered in `scripts/event-catalog.json` before emit calls.

## Output

On full success (exit 0):
```
Ingested <path> as <slug> in topic <topic>.
{"source_id":"<slug>","pages_attempted":N,"pages_created":N,"pages_failed":0,"failures":[]}
```

On partial wiki failure (exit 1):
```
Ingested <path> as <slug> in topic <topic> (partial wiki failure).
{"source_id":"<slug>","pages_attempted":N,"pages_created":M,"pages_failed":K,"failures":[{"slug":"...","error":"E-NNN: ..."},...]}
```

On error, one of the E-INGEST-NNN error codes from `scripts/event-catalog.json` with the corresponding human-readable message.
