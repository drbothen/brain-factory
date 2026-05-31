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

1. **Path validation.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/validate-ingest-path.sh" "$PATH_ARG"` with `BRAIN_ROOT` set to the brain vault root. The script resolves paths with `readlink -f` (portable on macOS 12.3+ and Linux), applies a system-directory hard block, checks vault-root via `git rev-parse --show-toplevel`, reads the operator allowlist from `.brain/policies.yaml`, checks file existence, checks file type (image → E-INGEST-010 exit 2; PDF without `pdftotext` → E-INGEST-010 exit 2), and checks for duplicate slug in `.brain/manifest.json` (E-INGEST-001 exit 2). On exit 2, emit `ingest.source.path_rejected` event via `${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh` with fields `path` and `code`, then propagate the error and stop. On exit 0, capture the resolved absolute path from stdout.

2. **Emit `ingest.source.started`.** Source `${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh` and call `emit_event "ingest.source.started" "path=${PATH_ARG}" "topic=${TOPIC}"`.

3. **Read file content.** For markdown/text: read file directly. For PDF (pdftotext available — already verified by validate-ingest-path.sh): run `pdftotext "${RESOLVED_PATH}" -` to extract text; capture the output as `CONTENT`. For images: validate-ingest-path.sh already exited 2 before reaching this step.

4. **Derive slug.** Normalize the file basename (without extension) to kebab-case: `slug="$(printf '%s' "$(basename "${RESOLVED_PATH%.*}")" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]-' '-' | sed 's/^-*//;s/-*$//')"`.

5. **Extract title.** Use the first `# Heading` in the file body as the title. If none found, use the slug as the title.

6. **Write source file.** Create `${BRAIN_DIR}/sources/${TOPIC}/${SLUG}.md` with YAML frontmatter: `title`, `path` (relative to brain root, e.g. `sources/${TOPIC}/${SLUG}.md`), `ingested_at` (ISO 8601 UTC), `source_id` (the slug), `topic`, `embedding_status: pending`. Append the file content as the body. Do NOT use `url` field — local-source entries use `path` (BC-2.03.002 invariant 1). Emit `ingest.source.written` event via `hook-event-emit.sh` with fields `path`, `topic`, `slug`, and `file_path`.

7. **Atomic manifest update.** Source `${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh`. Call `manifest_write '{"source_id":"<slug>","path":"<relative-path>","topic":"<topic>","ingested_at":"<ts>","last_ingest":"<ts>","chunks":[],"embeddings_model":null}' "${BRAIN_DIR}/.brain/manifest.json" "ingest.source.manifest_updated"`. On failure (E-INGEST-008), delete the source file written in step 6 and exit 2 with the error.

8. **Wiki generation.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/generate-wiki.sh" "${BRAIN_DIR}" "${source_file}" "ingest.source"`. Capture the JSON result envelope from stdout: `pages_attempted`, `pages_created`, `pages_failed`, `failures`. Note the exit code (0 = all succeeded, 1 = partial failure) for step 10. Note: `generate-wiki.sh` is the sole emitter of `ingest.source.wiki_pages_generated` (it emits automatically on stderr). Do NOT re-emit this event from the skill — doing so would double-count the event.

9. **Token logging.** Run `bash "${CLAUDE_PLUGIN_ROOT}/scripts/log-tokens.sh" "${BRAIN_DIR}" "${PATH_ARG}" "${SLUG}" "-1" "-1" "${pages_created}" "${duration_seconds}"` where `pages_created` is from the generate-wiki.sh envelope and `duration_seconds` is elapsed time since step 2.

10. **Emit `ingest.source.completed` and report.** Emit `ingest.source.completed` event via `hook-event-emit.sh` with fields `path`, `source_id`, `wiki_pages_created`, `duration_seconds`. Output the fan-out envelope: `{"source_id":"<slug>","pages_attempted":N,"pages_created":M,"pages_failed":K,"failures":[{"slug":"...","error":"E-NNN: ..."},...]}`. If `pages_failed == 0`, output "Ingested <path> as <slug> in topic <topic>." and exit 0. If `pages_failed > 0`, output "Ingested <path> as <slug> in topic <topic> (partial wiki failure)." and exit 1 (advisory — ingest succeeded but wiki generation was incomplete). The `failures` array is ALWAYS present even when empty.

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
- All `ingest.source.*` event types emitted by this skill (started, path_rejected, written, completed) and by generate-wiki.sh (wiki_pages_generated) are pre-registered in `scripts/event-catalog.json` before emit calls.

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
