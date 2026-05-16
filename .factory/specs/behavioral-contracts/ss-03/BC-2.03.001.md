---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-03"
capability: "CAP-003"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.03.001: `/brain:ingest-source` ingests a local file into `sources/{topic}/` and wiki layer

## Description

`/brain:ingest-source <path>` is the local-file ingest variant. The operator provides a path to a local file (PDF, markdown, text). The skill reads the file, converts it to the source markdown format, writes it to `sources/{topic}/{slug}.md`, updates the manifest, and triggers wiki page generation. Unlike `/brain:ingest-url`, there is no Defuddle fetch — the file is read directly. The quarantine check is still applied to the file content before it reaches the wiki-generation pipeline.

## Preconditions

1. Working directory is a valid brain.
2. `<path>` is an absolute path or path relative to the brain root.
3. `<path>` resolves to an existing readable file.
4. The file is not already in `.brain/manifest.json` (by canonical slug).

## Postconditions

1. File content is written to `sources/{topic}/{slug}.md` with mandatory source frontmatter.
2. `.brain/manifest.json` updated with new entry.
3. 5–15 wiki pages generated (same pipeline as BC-2.02.002).
4. JSONL token record written to `.brain/logs/ingest-tokens.jsonl`.
5. Skill exits 0 with ingest summary.

## Invariants

1. The source path must resolve WITHIN the brain vault or to an explicitly allowed outside path (per policy). Paths to `/etc/`, `/usr/`, system directories are blocked with E-INGEST-009.
2. Same manifest-delta-only constraint as BC-2.02.004.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Path outside brain vault | E-INGEST-009; exit 2. |
| EC-002 | Binary file (PDF, image) | PDF: extract text via `pdftotext` or similar if available; fallback to raw bytes → error if not extractable. Image: E-INGEST-010. |
| EC-003 | File already ingested (same slug in manifest) | E-INGEST-001 (same as URL duplicate). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Valid markdown file at `~/notes/my-article.md` | Source written; manifest updated; wiki pages created; exit 0 | happy-path |
| Path to `/etc/passwd` | E-INGEST-009; exit 2 | error |
| File not found | E-INGEST-011: "File not found: <path>"; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Valid local file ingested successfully | bats skills.bats |
| VP-TBD | Out-of-vault path blocked | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-003 ("Source Ingest Pipeline") per brief §Scope §Phase 0/1 primitives skill #4 (`/brain:ingest-source <path>`). |
| Architecture Module | SS-03: Source Ingest Pipeline |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#4) |

## Related BCs

- BC-2.02.001 — related to (URL ingest is the parallel skill)
- BC-2.03.002 — composes with
- BC-2.03.003 — composes with
- BC-2.03.004 — composes with
