---
name: init
description: "Initialize a new brain vault with directory structure, publishing scaffold, and voice avoid-list"
argument-hint: "[path/to/brain]"
allowed-tools:
  - Read
  - Write
  - Bash
---

## Iron Law

Never overwrite files or directories the operator has customized — guard every mutation with an existence check.

## Red Flags

- Running without a target brain directory argument — default to current directory only after confirming it is the intended vault root.
- Overwriting `rules/voice-avoid-list.txt` that already exists — operators customize this file; silently clobbering it destroys their work.
- Creating directories without `mkdir -p` — fragile if a parent is missing.

## Announce-at-Start

"Initializing brain vault at [path]. Checking for existing structure before creating anything."

## Procedure

1. Resolve the target brain directory: use the provided argument, or default to `$PWD` after confirming with the operator.

2. Create the core brain vault directory structure (idempotent via `mkdir -p`):
   ```bash
   mkdir -p sources wiki briefs rules .brain
   ```

3. Scaffold publishing directories (AC-001, AC-002 — idempotent via `mkdir -p`):
   ```bash
   mkdir -p drafts/linkedin to-publish/linkedin published/linkedin
   ```
   Guard: `mkdir -p` handles the case where directories already exist without error or data loss.

4. Install voice avoid-list (AC-004, AC-005 — guard against overwrite):
   ```bash
   if [[ ! -f rules/voice-avoid-list.txt ]]; then
     cp "${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt" rules/voice-avoid-list.txt
   fi
   ```
   Guard: do NOT overwrite if the operator has already customized the file. The `[[ ! -f ... ]]` check enforces this contract.

5. Report what was created vs what was already present. List each directory/file and state `created` or `already exists`.

## Quality Bar

- All 5 core directories present: `sources/`, `wiki/`, `briefs/`, `rules/`, `.brain/`
- All 3 publishing directories present: `drafts/linkedin/`, `to-publish/linkedin/`, `published/linkedin/`
- `rules/voice-avoid-list.txt` present and contains at least 1 entry
- A pre-existing `rules/voice-avoid-list.txt` is byte-for-byte unchanged after init
- A pre-existing file in `drafts/linkedin/` is byte-for-byte unchanged after init

## Output

A summary listing each directory and file, indicating whether it was `created` or `already exists (preserved)`.
