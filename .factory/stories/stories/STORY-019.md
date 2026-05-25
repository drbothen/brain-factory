---
artifact_type: story
story_id: STORY-019
epic_id: EPIC-03
title: "Local source ingest: path validation, manifest delta, wiki generation, and partial-failure fan-out"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-03]
behavioral_contracts: [BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004]
vps: [VP-016, VP-012]
dependencies: [STORY-016, STORY-017, STORY-014]
blocks: []
inputs:
  - architecture/subsystems/SS-03-source-ingest-pipeline.md
  - behavioral-contracts/ss-03/BC-2.03.001.md
  - behavioral-contracts/ss-03/BC-2.03.002.md
  - behavioral-contracts/ss-03/BC-2.03.003.md
  - behavioral-contracts/ss-03/BC-2.03.004.md
  - architecture/verification-properties/VP-016-source-ingest-pipeline.md
  - architecture/verification-properties/VP-012-manifest-atomicity.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# Bundling rationale: BC-2.03.001 (local file ingest), BC-2.03.002 (manifest delta),
# BC-2.03.003 (out-of-vault rejection), and BC-2.03.004 (partial-failure fan-out) are
# all one skill's contract surface — `/brain:ingest-source`. They cannot be meaningfully
# split across stories because they are preconditions and postconditions of the same
# single operation. BC-2.03.003 (path check) is the first gate; BC-2.03.001 (file write)
# is the happy path; BC-2.03.002 (manifest delta) is the postcondition; BC-2.03.004
# (fan-out) is the error contract. Four BCs = one complete skill contract.
---

# STORY-019: Local source ingest — path validation, manifest delta, wiki generation, and partial-failure fan-out

## Goal

Deliver the `/brain:ingest-source <path>` skill: the local-file variant of the ingest
pipeline. This skill reads a local file (markdown, text, or PDF), validates the path is
within the brain vault, writes the source to `sources/{topic}/{slug}.md`, updates the
manifest via the shared `manifest-write.sh` helper (STORY-016), and triggers the wiki
page generation pipeline (STORY-017 infrastructure). It propagates per-page failures via
the canonical partial-failure fan-out envelope — no silent swallow of hook-blocked writes.

## User Value

As a brain operator, I want to run `/brain:ingest-source ~/notes/my-research.md` and
have the local file ingested into my brain's source layer with the same quality guarantees
as URL ingest — path safety, duplicate detection, manifest tracking, wiki page generation,
and transparent error reporting when any individual wiki page fails to write.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.03.001 | `/brain:ingest-source` ingests a local file into `sources/{topic}/` and wiki layer | P0 |
| BC-2.03.002 | `/brain:ingest-source` writes manifest delta entry on every successful ingest | P0 |
| BC-2.03.003 | `/brain:ingest-source` rejects paths outside the brain vault root | P0 |
| BC-2.03.004 | `/brain:ingest-source` propagates partial-failure fan-out (per-page results; no silent swallow) | P0 |

## Acceptance Criteria

### Local File Ingest (BC-2.03.001)

**AC-001** — `/brain:ingest-source <path> [--topic <category>]` reads the local file at
`<path>` and copies its content to `sources/{topic}/{slug}.md` with source frontmatter:
`title`, `path` (relative to brain root), `ingested_at` (ISO 8601), `source_id` (slug),
`topic`, `embedding_status: pending`. There is NO Defuddle step — local files are read
directly.
(traces to BC-2.03.001 postcondition 1; invariant 1 — path must be within vault or allowed)

**AC-002** — After source write, the wiki page generation pipeline (same
`brain:librarian`-based pipeline as STORY-017) is triggered, producing 5–15 wiki pages.
A JSONL token record is written to `.brain/logs/ingest-tokens.jsonl`. Skill exits 0 with
ingest summary on full success.
(traces to BC-2.03.001 postconditions 2–5)

**AC-003** — For PDF files: if `pdftotext` (poppler-utils) is available in PATH, the skill
invokes `pdftotext <path> -` to extract text before writing to the source file. If
`pdftotext` is unavailable, the skill emits an advisory: "PDF extraction requires
poppler-utils (`pdftotext`). Install via your OS package manager or convert manually."
and exits 2 with E-INGEST-010.
(traces to BC-2.03.001 edge case EC-002 — binary file handling)

**AC-004** — For image files (`.png`, `.jpg`, `.gif`, `.webp`, `.svg`), the skill exits 2
with E-INGEST-010: "Image files cannot be ingested in v0.1. Convert to text or markdown
first."
(traces to BC-2.03.001 edge case EC-002 — image type)

**AC-005** — If the file does not exist at the resolved path, the skill exits 2 with
E-INGEST-011: "File not found: <path>".
(traces to BC-2.03.001 canonical test vector — file not found)

**AC-006** — If the file has already been ingested (same slug appears in `.brain/manifest.json`),
the skill exits 2 with E-INGEST-001: "Source already ingested as <slug>. Sources are immutable."
No file read or wiki generation is performed.
(traces to BC-2.03.001 edge case EC-003)

### Manifest Delta Entry (BC-2.03.002)

**AC-007** — On successful ingest, `hooks/lib/manifest-write.sh` is called to append a new
entry to `.brain/manifest.json`:
`{"source_id": "<slug>", "path": "<relative-path>", "topic": "<topic>",
"ingested_at": "<ISO8601>", "last_ingest": "<ISO8601>", "chunks": [], "embeddings_model": null}`.
Note: local-source entries use `path` (not `url`) as the distinguishing field.
(traces to BC-2.03.002 postcondition 1; invariant 1)

**AC-008** — Existing manifest entries are NOT modified. The manifest write is atomic
(`.tmp` + `mv` via `manifest-write.sh`). If the write fails, the source file is rolled
back and E-INGEST-008 is emitted.
(traces to BC-2.03.002 postconditions 2–3; edge case EC-001)

### Out-of-Vault Path Rejection (BC-2.03.003)

**AC-009** — Before any file read, `/brain:ingest-source` resolves the provided path to an
absolute path using `readlink -f` (handling `..` traversal and symlinks). If the resolved
path is NOT prefixed by the brain vault root (`git rev-parse --show-toplevel`), the skill
exits 2 with E-INGEST-009: "Path '<resolved-path>' is outside the brain vault. Only
vault-relative paths are allowed." No file is read.
(traces to BC-2.03.003 postcondition 1 on out-of-vault path; invariants 1–2)

**AC-010** — System directories (`/etc/`, `/usr/`, `/var/`, `/sys/`, `/proc/`) are ALWAYS
blocked regardless of `.brain/policies.yaml` allowlist. This is a hard block, not a
configurable policy.
(traces to BC-2.03.003 invariant 2)

**AC-011** — A symlink inside the vault that resolves to a path outside the vault is
rejected (resolved path check, not raw path check). `readlink -f` is used to follow
symlinks before the vault-root comparison.
(traces to BC-2.03.003 edge case EC-001)

**AC-012** — An operator-defined allowlist in `.brain/policies.yaml` (key:
`allowed_external_paths: ["/Users/jmagady/Downloads/"]`) permits ingesting files from
explicitly listed outside-vault paths. The path validation checks the allowlist AFTER the
system-directory block (system directories are always rejected even if listed in the
allowlist).
(traces to BC-2.03.003 edge case EC-002)

### Partial-Failure Fan-Out (BC-2.03.004)

**AC-013** — The skill's result summary includes the canonical fan-out envelope:
`{"source_id": "<slug>", "pages_attempted": N, "pages_created": M, "pages_failed": K,
"failures": [{"slug": "<slug>", "error": "E-NNN: <message>"}, ...]}`.
When `pages_failed > 0`, the skill exits 1 (advisory). When `pages_failed == 0`, exits 0.
(traces to BC-2.03.004 postconditions 1–2; invariant 1)

**AC-014** — Failed pages (e.g., hook-rejected writes) are listed in the `failures` array
with their slug and error code. No failed page is silently omitted. The `failures` array is
never absent from the result even when empty.
(traces to BC-2.03.004 postcondition 3; invariant 2)

**AC-015** — The `pages_attempted = pages_created + pages_failed` invariant is enforced.
Verified in bats: inject a hook failure for exactly one of N pages; assert
`pages_failed == 1` and `pages_created == N - 1` and `pages_attempted == N`.
(traces to BC-2.03.004 invariant 1)

**AC-016** — `set +e` is NEVER used in the skill body to swallow hook-rejected writes.
Meta-lint bats checks for `set +e` in all skill bodies. (Static analysis assertion.)
(traces to BC-2.03.004 invariant 3)

**AC-017** — When ALL pages fail (0 of N created), the skill exits 1 with the complete
failure list. The source file and manifest entry still stand; the operator is told to
investigate the hook rejections.
(traces to BC-2.03.004 edge case EC-001)

## Tasks

1. **[prerequisite check]** Verify STORY-016 landed (`hooks/lib/manifest-write.sh` exists)
   and STORY-017 landed (wiki generation pipeline in `skills/ingest-url/SKILL.md` is
   implemented). The local source ingest reuses both of these.

2. **[failing test — Red Gate]** Add failing bats tests to `tests/skills.bats`:
   - Valid markdown file at a vault path → source written; manifest updated; exit 0.
   - Path outside vault (`/etc/passwd`) → E-INGEST-009; exit 2; no file read.
   - `..` traversal outside vault → E-INGEST-009; exit 2 (readlink -f resolution).
   - Symlink inside vault resolving outside vault → E-INGEST-009; exit 2.
   - File not found → E-INGEST-011; exit 2.
   - Already-ingested slug → E-INGEST-001; exit 2; no file read.
   - PDF with `pdftotext` available (mock) → extracted text used; exit 0.
   - PDF with `pdftotext` absent (mock) → E-INGEST-010; exit 2.
   - Image file → E-INGEST-010; exit 2.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[failing test — Red Gate]** Add failing bats tests to `tests/integration.bats`:
   - Successful ingest → source file written; manifest has `path` field (not `url`); 5+
     wiki pages created; token record in log.
   - 10 pages planned; 1 hook-blocked → `pages_failed: 1`; `pages_created: 9`; exit 1.
   - All pages blocked → `pages_created: 0`; `pages_failed: N`; source + manifest stand.
   - `pages_attempted == pages_created + pages_failed` invariant.
   - System directory `/etc/` blocked even if in allowlist (mock allowlist test).
   Run bats — confirm all new tests fail.

4. **[impl]** Implement `skills/ingest-source/SKILL.md` (full skill body):
   - Path validation: `readlink -f`, vault-root check, allowlist check, system-dir hard block.
   - File type detection: markdown/text → direct read; PDF → `pdftotext`; image → error.
   - Duplicate guard against manifest (same as URL ingest, checking slug instead of URL).
   - Source write to `sources/{topic}/{slug}.md` with correct frontmatter (using `path`).
   - Call `hooks/lib/manifest-write.sh` for atomic manifest update.
   - Call wiki generation pipeline (same as STORY-017 infrastructure).
   - Token logging (same log step as STORY-017).
   - Partial-failure fan-out envelope construction and reporting.
   - Structured events: `ingest.source.started`, `ingest.source.path_rejected`,
     `ingest.source.written`, `ingest.source.wiki_pages_generated`, `ingest.source.completed`.

5. **[green]** Run `bats tests/skills.bats` — all new path-validation and error-path tests pass.

6. **[green]** Run `bats tests/integration.bats` — all new ingest integration and fan-out tests pass.

7. **[green]** Run `shellcheck` on any bash helper added by this story. `shfmt -d -i 2`
   produces no diff.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Valid markdown at vault path | Source written; manifest entry with `path` field; 5+ wiki pages; exit 0 | happy-path | BC-2.03.001 |
| Path to `/etc/passwd` | E-INGEST-009; exit 2; no read | error | BC-2.03.003 |
| `../../outside-vault/file.md` | E-INGEST-009; exit 2 (readlink -f resolves to outside vault) | error | BC-2.03.003 |
| Symlink in vault → outside vault | E-INGEST-009; exit 2 (readlink -f follows symlink) | error | BC-2.03.003 EC-001 |
| File not found | E-INGEST-011; exit 2 | error | BC-2.03.001 |
| Already-ingested slug | E-INGEST-001; exit 2; no read | error | BC-2.03.001 EC-003 |
| PDF file; pdftotext available | Extracted text used as source content; exit 0 | edge-case | BC-2.03.001 EC-002 |
| PDF file; pdftotext absent | E-INGEST-010; exit 2 | error | BC-2.03.001 EC-002 |
| Image file (.png) | E-INGEST-010; exit 2 | error | BC-2.03.001 EC-002 |
| 10 pages planned; 1 hook-blocked | pages_failed: 1; pages_created: 9; exit 1 | edge-case | BC-2.03.004 |
| All 0 pages created (all blocked) | pages_created: 0; pages_failed: N; source + manifest stand; exit 1 | error | BC-2.03.004 EC-001 |
| pages_attempted = pages_created + pages_failed | Invariant holds in all scenarios | invariant | BC-2.03.004 invariant 1 |
| Manifest write failure | Source rolled back; E-INGEST-008; exit 2 | error | BC-2.03.002 EC-001 |
| Allowed external path in policies.yaml | Ingest proceeds for the allowed path | edge-case | BC-2.03.003 EC-002 |
| Allowed external path = system directory | E-INGEST-009; exit 2 (system dirs always blocked) | security | BC-2.03.003 invariant 2 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-016 | Valid local file ingested successfully | `tests/skills.bats` |
| VP-016 | Out-of-vault path blocked | `tests/skills.bats` |
| VP-016 | System directories always blocked | `tests/skills.bats` |
| VP-016 | Partial failure reported accurately | `tests/integration.bats` |
| VP-016 | No silent swallow on failed pages | `tests/integration.bats` (inject hook failure) |
| VP-012 | Manifest entry with `path` field written | `tests/skills.bats` |
| VP-012 | Manifest write atomic | `tests/integration.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-03-source-ingest-pipeline.md`:

1. Path validation uses `readlink -f` to follow symlinks and resolve `..` before comparing
   to vault root. Raw string comparison of the input path is NOT sufficient.
   (BC-2.03.003 invariant 1)
   **Use `readlink -f` instead of `realpath`** — `readlink -f` is available on macOS 12.3+
   (Monterey and later, including Sequoia) AND all Linux distributions. Do NOT use `realpath`
   (not available on macOS without GNU coreutils). Do NOT use `grealpath`.
2. The vault root is determined via `git rev-parse --show-toplevel` — NOT from a hardcoded
   path or config variable. This ensures the vault root is always correct even when the
   brain is in a subdirectory.
3. Local-source manifest entries use `path` field (relative to brain root), not `url`.
   Both fields MUST NOT appear in the same entry. (BC-2.03.002 invariant 1)
4. The shared `hooks/lib/manifest-write.sh` helper (STORY-016 deliverable) is called for
   the manifest write. `/brain:ingest-source` does NOT reimplement manifest write logic.
5. The partial-failure fan-out envelope format is identical to BC-2.03.004:
   `{"pages_attempted": N, "pages_created": M, "pages_failed": K, "failures": [...]}`.
   This is the SAME format used by `/brain:ingest-url` (STORY-017) for consistency.
6. Structured events `ingest.source.started`, `ingest.source.path_rejected`,
   `ingest.source.written`, `ingest.source.wiki_pages_generated`, `ingest.source.completed`
   must all be pre-registered in `scripts/event-catalog.json` (STORY-014 deliverable).
   Verify these rows exist before adding emit calls.

**Forbidden dependencies:**
- No Defuddle invocation in this skill. Local files are read directly.
- No `find` or `ls` of `sources/` during ingest (manifest-delta constraint, same as SS-02).
- No `set +e` anywhere in the skill body or helpers.
- Do NOT use `realpath` — it is not available on macOS without GNU coreutils installation.
  Use `readlink -f` which is portable across macOS 12.3+ and Linux.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions; ADR-001 |
| `readlink -f` | macOS 12.3+ and Linux (built-in) | Path resolution (BC-2.03.003 invariant 1) — use instead of `realpath` |
| `git rev-parse --show-toplevel` | Any git version | Vault root detection |
| `pdftotext` | poppler-utils (optional) | PDF text extraction (AC-003) |
| `jq` | 1.7+ (latest: 1.8.1) | Manifest manipulation; fan-out envelope JSON |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

Note: `readlink -f` is the portable path-resolution tool for this skill. It is available
on macOS 12.3+ (Monterey and later, including Sequoia 25.x) and all Linux distributions
natively. No Homebrew installation required. Do NOT use `realpath` (GNU coreutils only)
or `grealpath` (Homebrew alias). The operator platform is macOS Darwin 25.x per project env.

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/ingest-source/SKILL.md` | Create | Full skill body: path check → file read → source write → manifest → wiki → log |
| `plugins/brain-factory/tests/skills.bats` | Extend | Path validation + error path + PDF/image assertions |
| `plugins/brain-factory/tests/integration.bats` | Extend | Ingest integration + partial-failure fan-out |
| `plugins/brain-factory/tests/fixtures/ingest-source-happy.md` | Create | Valid markdown fixture for happy-path bats |
| `plugins/brain-factory/tests/fixtures/ingest-source-outside-vault.txt` | Create | Path-outside-vault error fixture (path reference only; not in vault) |

Files NOT to modify: `hooks/lib/manifest-write.sh`, `scripts/defuddle-fetch.mjs`,
`skills/ingest-url/SKILL.md` (URL ingest, STORY-016/017 owned), `scripts/event-catalog.json`
(STORY-014 owns; only ask STORY-014 to pre-populate the 5 ingest.source.* events), any
`.factory/` file, any prior STORY-NNN.md.

## Previous Story Intelligence

STORY-016 delivered `hooks/lib/manifest-write.sh` and the URL ingest infrastructure.
This story uses `manifest-write.sh` directly — do NOT reimplement manifest write. The
atomic write semantics (`.tmp` + `mv`) are inherited by calling the shared helper.

STORY-017 delivered the wiki page generation and token logging steps. The local source
ingest uses the same pipeline steps — the `brain:librarian` invocation and the
`.brain/logs/ingest-tokens.jsonl` append are the same code path. Reuse STORY-017's
generate-wiki and log-tokens workflow steps rather than duplicating them in the
`ingest-source` skill body.

The SS-03 key design note (SS-03-source-ingest-pipeline.md §Key Design) explicitly
states the ingest-source workflow mirrors the URL pipeline "with two key differences:
no Defuddle step and path validation before write." This story is the mirror — keep it
DRY with respect to STORY-017's infrastructure.

STORY-014 pre-populated `scripts/event-catalog.json` with all structured event types.
The five `ingest.source.*` event types (`ingest.source.started`, `ingest.source.path_rejected`,
`ingest.source.written`, `ingest.source.wiki_pages_generated`, `ingest.source.completed`)
must be in the catalog before this story's emit calls are added.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,500 |
| SS-03 subsystem design | ~1,200 |
| BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004 files | ~3,500 |
| VP-016, VP-012 files | ~1,200 |
| skills.bats + integration.bats existing content | ~3,000 |
| event-catalog.json (STORY-014 deliverable) | ~2,000 |
| manifest-write.sh (STORY-016 deliverable) | ~1,000 |
| **Total** | **~15,400** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- URL ingest (`/brain:ingest-url`) — STORY-016 and STORY-017.
- `brain:librarian` agent implementation — EPIC-04 (wiki layer).
- Source immutability hook (`validate-source-immutability.sh`) — EPIC-02 (BC-2.04.002).
- Sub-linear latency gate for local source ingest — not a separate BC; the manifest-delta
  contract (BC-2.02.004 invariant applied equally to SS-03) is inherently sub-linear via
  the shared manifest-write helper.
- Knowledge synthesis and connection (`/brain:connect`, `/brain:synthesize`) — EPIC-05.

## Anchors

- BC-2.03.001: `behavioral-contracts/ss-03/BC-2.03.001.md`
- BC-2.03.002: `behavioral-contracts/ss-03/BC-2.03.002.md`
- BC-2.03.003: `behavioral-contracts/ss-03/BC-2.03.003.md`
- BC-2.03.004: `behavioral-contracts/ss-03/BC-2.03.004.md`
- VP-016: `architecture/verification-properties/VP-016-source-ingest-pipeline.md`
- VP-012: `architecture/verification-properties/VP-012-manifest-atomicity.md`
- SS-03: `architecture/subsystems/SS-03-source-ingest-pipeline.md`
