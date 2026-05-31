# Evidence Report — STORY-019
# Local source ingest: path validation, manifest delta, wiki generation, and partial-failure fan-out

story_id: STORY-019
branch: feature/STORY-019
source_head: ee2b7d3 (feature/STORY-019 HEAD)
develop_head: 21533b0
recorded: 2026-05-30
toolchain: bats 1.10+, shellcheck 0.10+, shfmt 3.7+

## Summary

All 17 acceptance criteria for STORY-019 are covered by the current implementation.
Evidence was captured by running bats test suites and functional CLI demos against
the converged code at feature/STORY-019 HEAD (ee2b7d3).

Test execution results:
- `skills.bats`: 44 tests, 44 passed, 0 failed
  - 25 tests directly trace to STORY-019 BCs (BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004)
  - 2 BLOCKER-1 regression tests (BC-2.03.003 invariant 1 — nonexistent-intermediate `..` escape)
  - 2 static analysis tests (AC-016: `set +e` and `realpath` absence)
  - 15 pre-existing STORY-017 tests (no regressions)
- `shellcheck`: 0 warnings across all 4 scripts (validate-ingest-path.sh, generate-wiki.sh, log-tokens.sh, manifest-write.sh)
- `shfmt -d -i 2`: 0 diffs on validate-ingest-path.sh and generate-wiki.sh
- Functional demos: all 11 path-validation scenarios captured; all 3 fan-out scenarios captured; source-write and manifest demos captured

## Deliverables

| File | Description |
|------|-------------|
| `plugins/brain-factory/scripts/validate-ingest-path.sh` | Path validation gate: `readlink -f` resolution, vault-root check, system-dir hard block, allowlist, file existence, file type (PDF/image), duplicate slug |
| `plugins/brain-factory/scripts/generate-wiki.sh` | Wiki page generation orchestrator (STORY-017 deliverable, reused); emits partial-failure fan-out envelope |
| `plugins/brain-factory/scripts/log-tokens.sh` | JSONL token record appender (STORY-017 deliverable, reused) |
| `plugins/brain-factory/hooks/lib/manifest-write.sh` | Atomic manifest write helper (STORY-016 deliverable, reused); `path` field for local-source entries |
| `plugins/brain-factory/skills/ingest-source/SKILL.md` | Full skill body: 10-step procedure, Red Flags, Iron Law, Quality Bar |

## AC to Evidence Mapping

| AC | BC | Description | Evidence File | Status |
|----|----|-------------|---------------|--------|
| AC-001 | BC-2.03.001 | Source written to `sources/{topic}/{slug}.md` with `path` frontmatter (not `url`), 6 required fields | ac-001-002-source-write-wiki.md | PASS |
| AC-002 | BC-2.03.001 | Wiki generation pipeline triggered; JSONL token record written; exit 0 on success | ac-001-002-source-write-wiki.md | PASS |
| AC-003 | BC-2.03.001 | PDF with `pdftotext` → exit 0; PDF without `pdftotext` → E-INGEST-010 exit 2 | ac-003-004-pdf-image-types.md | PASS |
| AC-004 | BC-2.03.001 | Image files (`.png`, `.jpg`, etc.) → E-INGEST-010 exit 2 | ac-003-004-pdf-image-types.md | PASS |
| AC-005 | BC-2.03.001 | File not found → E-INGEST-011 exit 2; no read | ac-005-006-error-guards.md | PASS |
| AC-006 | BC-2.03.001 | Duplicate slug in manifest → E-INGEST-001 exit 2; no read | ac-005-006-error-guards.md | PASS |
| AC-007 | BC-2.03.002 | Manifest entry appended with 7 fields; `path` field (not `url`) per BC-2.03.002 invariant 1 | ac-007-008-manifest-delta.md | PASS |
| AC-008 | BC-2.03.002 | Existing entries preserved; atomic `.tmp` + `mv`; E-INGEST-008 + rollback on failure | ac-007-008-manifest-delta.md | PASS |
| AC-009 | BC-2.03.003 | `readlink -f` resolution; out-of-vault path → E-INGEST-009 exit 2; no read | ac-009-012-path-validation.md | PASS |
| AC-010 | BC-2.03.003 | System dirs (`/etc/`, `/usr/`, `/var/`, `/sys/`, `/proc/`) hard-blocked regardless of allowlist | ac-009-012-path-validation.md | PASS |
| AC-011 | BC-2.03.003 | Symlink inside vault resolving outside vault → E-INGEST-009 exit 2 (`readlink -f` follows symlink) | ac-009-012-path-validation.md | PASS |
| AC-012 | BC-2.03.003 | `allowed_external_paths` in policies.yaml permits non-system outside-vault paths; system dirs still blocked | ac-009-012-path-validation.md | PASS |
| AC-013 | BC-2.03.004 | Fan-out envelope `{source_id, pages_attempted, pages_created, pages_failed, failures}` present; `pages_failed>0` → exit 1 | ac-013-017-fanout-envelope.md | PASS |
| AC-014 | BC-2.03.004 | Failed pages listed in `failures[]` with slug and E-INGEST-014 error; no silent omission; `failures` always present | ac-013-017-fanout-envelope.md | PASS |
| AC-015 | BC-2.03.004 | `pages_attempted == pages_created + pages_failed` invariant holds in all scenarios | ac-013-017-fanout-envelope.md | PASS |
| AC-016 | BC-2.03.004 | `set +e` absent from skill Procedure section; `realpath` not invoked (static analysis) | ac-013-017-fanout-envelope.md | PASS |
| AC-017 | BC-2.03.004 | All pages fail → exit 1 with complete failure list; source file and manifest preserved | ac-013-017-fanout-envelope.md | PASS |

## Raw Output Files

| File | Contents |
|------|----------|
| `raw-output/skills-bats-run.txt` | Full 44-test bats run of skills.bats (includes all STORY-019 BC tests) |
| `raw-output/shellcheck-shfmt-run.txt` | shellcheck + shfmt output for validate-ingest-path.sh, generate-wiki.sh, log-tokens.sh, manifest-write.sh (zero violations) |
| `raw-output/validate-ingest-path-demos.txt` | 11 functional demos: in-vault accept, /etc/ block, dot-dot traversal, symlink escape, /etc/-in-allowlist block, allowlist accept, file-not-found, PDF+pdftotext, PDF-no-pdftotext, .png image, duplicate slug |
| `raw-output/fanout-envelope-demos.txt` | 3 fan-out scenarios: full success (pages_failed=0), partial failure (1 collision), all-fail (pages_created=0) |
| `raw-output/source-write-manifest-demos.txt` | AC-001: source frontmatter with path field; AC-007: manifest_write entry; AC-008: existing entries preserved; AC-002: JSONL token record |
