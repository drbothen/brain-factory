#!/usr/bin/env bash
set -euo pipefail

# /brain:init — scaffold a complete brain vault in the target directory
# Usage: BRAIN_ROOT=/path/to/brain bash run.sh
# Env vars:
#   BRAIN_ROOT         — target directory (default: $PWD)
#   CLAUDE_PLUGIN_ROOT — plugin root for reading templates (must be set)

BRAIN_ROOT="${BRAIN_ROOT:-$PWD}"

# ---------------------------------------------------------------------------
# Validate required env
# ---------------------------------------------------------------------------

if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  echo "ERROR: CLAUDE_PLUGIN_ROOT is not set" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# AC-001: Create all required directories
# ---------------------------------------------------------------------------

mkdir -p \
  "${BRAIN_ROOT}/sources/ai" \
  "${BRAIN_ROOT}/sources/health" \
  "${BRAIN_ROOT}/sources/psychology" \
  "${BRAIN_ROOT}/sources/productivity" \
  "${BRAIN_ROOT}/sources/business" \
  "${BRAIN_ROOT}/sources/books" \
  "${BRAIN_ROOT}/sources/podcasts" \
  "${BRAIN_ROOT}/wiki/concepts" \
  "${BRAIN_ROOT}/wiki/people" \
  "${BRAIN_ROOT}/wiki/frameworks" \
  "${BRAIN_ROOT}/wiki/syntheses" \
  "${BRAIN_ROOT}/wiki/observations" \
  "${BRAIN_ROOT}/wiki/questions" \
  "${BRAIN_ROOT}/inbox" \
  "${BRAIN_ROOT}/briefs/daily" \
  "${BRAIN_ROOT}/briefs/weekly" \
  "${BRAIN_ROOT}/briefs/monthly" \
  "${BRAIN_ROOT}/briefs/content" \
  "${BRAIN_ROOT}/briefs/decisions" \
  "${BRAIN_ROOT}/.brain/logs" \
  "${BRAIN_ROOT}/.github/workflows" \
  "${BRAIN_ROOT}/rules" \
  "${BRAIN_ROOT}/drafts/linkedin" \
  "${BRAIN_ROOT}/to-publish/linkedin" \
  "${BRAIN_ROOT}/published/linkedin"

# ---------------------------------------------------------------------------
# AC-002/AC-007: Copy CLAUDE.md from template
# ---------------------------------------------------------------------------

cp "${CLAUDE_PLUGIN_ROOT}/templates/claude-md-template.md" \
  "${BRAIN_ROOT}/CLAUDE.md"

# ---------------------------------------------------------------------------
# AC-002/AC-006 (STATE.md): Copy STATE.md from template
# ---------------------------------------------------------------------------

cp "${CLAUDE_PLUGIN_ROOT}/templates/state-md-template.md" \
  "${BRAIN_ROOT}/.brain/STATE.md"

# ---------------------------------------------------------------------------
# AC-004: Copy policies.yaml from template
# ---------------------------------------------------------------------------

cp "${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml" \
  "${BRAIN_ROOT}/.brain/policies.yaml"

# ---------------------------------------------------------------------------
# AC-005: Copy wiki type templates (one per type directory)
# ---------------------------------------------------------------------------

cp "${CLAUDE_PLUGIN_ROOT}/templates/wiki-concept-template.md" \
  "${BRAIN_ROOT}/wiki/concepts/_template.md"

cp "${CLAUDE_PLUGIN_ROOT}/templates/wiki-person-template.md" \
  "${BRAIN_ROOT}/wiki/people/_template.md"

cp "${CLAUDE_PLUGIN_ROOT}/templates/wiki-framework-template.md" \
  "${BRAIN_ROOT}/wiki/frameworks/_template.md"

cp "${CLAUDE_PLUGIN_ROOT}/templates/wiki-synthesis-template.md" \
  "${BRAIN_ROOT}/wiki/syntheses/_template.md"

cp "${CLAUDE_PLUGIN_ROOT}/templates/wiki-observation-template.md" \
  "${BRAIN_ROOT}/wiki/observations/_template.md"

cp "${CLAUDE_PLUGIN_ROOT}/templates/wiki-question-template.md" \
  "${BRAIN_ROOT}/wiki/questions/_template.md"

# ---------------------------------------------------------------------------
# AC-002: Create wiki/index.md and wiki/log.md
# ---------------------------------------------------------------------------

cat >"${BRAIN_ROOT}/wiki/index.md" <<'EOF'
---
type: index
title: Wiki Index
---

# Wiki Index

This file is the canonical index of all wiki pages.

## Page Types

- [Concepts](concepts/)
- [People](people/)
- [Frameworks](frameworks/)
- [Syntheses](syntheses/)
- [Observations](observations/)
- [Questions](questions/)
EOF

cat >"${BRAIN_ROOT}/wiki/log.md" <<'EOF'
---
type: log
title: Wiki Log
---

# Wiki Log

Chronological record of wiki page additions and modifications.
EOF

# ---------------------------------------------------------------------------
# AC-008: Copy GitHub Action workflow templates
# ---------------------------------------------------------------------------

cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/daily-brain.yml" \
  "${BRAIN_ROOT}/.github/workflows/daily-brain.yml"

cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/weekly-brain.yml" \
  "${BRAIN_ROOT}/.github/workflows/weekly-brain.yml"

cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/ingest-rss.yml" \
  "${BRAIN_ROOT}/.github/workflows/ingest-rss.yml"

cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/ingest-bookmarks.yml" \
  "${BRAIN_ROOT}/.github/workflows/ingest-bookmarks.yml"

cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/brain-health-check.yml" \
  "${BRAIN_ROOT}/.github/workflows/brain-health-check.yml"

cp "${CLAUDE_PLUGIN_ROOT}/templates/github-action-templates/adversary-review.yml" \
  "${BRAIN_ROOT}/.github/workflows/adversary-review.yml"

# ---------------------------------------------------------------------------
# AC-009: Copy voice-avoid-list.txt (guard: don't overwrite if exists)
# ---------------------------------------------------------------------------

if [[ ! -f "${BRAIN_ROOT}/rules/voice-avoid-list.txt" ]]; then
  cp "${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt" \
    "${BRAIN_ROOT}/rules/voice-avoid-list.txt"
fi

# ---------------------------------------------------------------------------
# AC-003: Write manifest.json with canonical schema
# ---------------------------------------------------------------------------

last_updated="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat >"${BRAIN_ROOT}/.brain/manifest.json" <<EOF
{
  "version": "1",
  "sources": {},
  "last_updated": "${last_updated}",
  "embeddings_model": null,
  "chunks": []
}
EOF

exit 0
