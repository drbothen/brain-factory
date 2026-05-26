---
name: init
description: "Initialize a new brain vault: scaffold all directories, copy templates, write manifest.json and policies.yaml"
argument-hint: ""
allowed-tools:
  - Bash
---

## Iron Law

Never overwrite files the operator has customized — guard every write with an existence check.

## Red Flags

- Running in a directory that already has `.brain/` — the operator may have a working brain here.
- `CLAUDE_PLUGIN_ROOT` is not set — templates cannot be located; abort before writing anything.
- Writing any file under `${CLAUDE_PLUGIN_ROOT}/` — init only writes to `${BRAIN_ROOT}`.

## Announce-at-Start

"Initializing brain vault at ${BRAIN_ROOT}. Creating directories and copying templates."

## Procedure

1. Set `BRAIN_ROOT="${BRAIN_ROOT:-$PWD}"` and verify `CLAUDE_PLUGIN_ROOT` is set; exit 1 if missing.
2. Create all required directories with `mkdir -p`: source topic dirs, wiki type dirs, briefs dirs, inbox, `.brain/logs`, `.github/workflows`, `rules`, and publishing dirs.
3. Copy `CLAUDE.md` from `${CLAUDE_PLUGIN_ROOT}/templates/claude-md-template.md` to `${BRAIN_ROOT}/CLAUDE.md`.
4. Copy `.brain/STATE.md` from `${CLAUDE_PLUGIN_ROOT}/templates/state-md-template.md`.
5. Copy `.brain/policies.yaml` from `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml`.
6. Copy each wiki type template from `${CLAUDE_PLUGIN_ROOT}/templates/wiki-{type}-template.md` to `${BRAIN_ROOT}/wiki/{type}/_template.md`.
7. Write `wiki/index.md` and `wiki/log.md` with minimal frontmatter.
8. Copy all 6 GitHub Action workflow templates from `${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/` to `.github/workflows/`.
9. Copy `rules/voice-avoid-list.txt` from `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt` only if the file does not already exist.
10. Write `.brain/manifest.json` with canonical schema: version 1, empty sources, ISO8601 last_updated, null embeddings_model, empty chunks array.

## Quality Bar

- All 22+ directories exist after init.
- All required files exist: `.brain/manifest.json`, `.brain/STATE.md`, `.brain/policies.yaml`, `wiki/index.md`, `wiki/log.md`, `CLAUDE.md`, `rules/voice-avoid-list.txt`, 6 workflow YAMLs, 6 wiki type templates.
- `manifest.json` is valid JSON with canonical schema fields.
- `policies.yaml` contains exactly 10 baseline policy entries.
- Each wiki `_template.md` has `embedding_status: pending` in YAML frontmatter.
- No files are written under `${CLAUDE_PLUGIN_ROOT}/`.
- `rules/voice-avoid-list.txt` is not overwritten if it already exists.

## Output

A shell script (`run.sh`) executes the scaffold. On success it exits 0. On missing `CLAUDE_PLUGIN_ROOT` it prints an error to stderr and exits 1.
