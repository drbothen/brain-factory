---
document_type: behavioral-contract
level: L3
version: "1.3"
status: active
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-02"
capability: "CAP-002"
lifecycle_status: active
introduced: v0.1.0
modified: [2026-05-27]
---

# Behavioral Contract BC-2.02.002: `/brain:ingest-url` produces 5–15 cross-referenced wiki pages per ingest

## Description

After the source file is written, `/brain:ingest-url` triggers the wiki page generation pipeline. The pipeline uses the brain:librarian specialist agent to extract concepts, people, frameworks, and synthesis-worthy insights from the source and creates 5–15 wiki pages. Each page is a standalone wiki entry in the correct `wiki/{type}/{slug}.md` path, with wikilinks to related pages and a `source_ids` reference to the originating source. The count of 5–15 is a tested SLA item in the v0.1 ship gate.

## Preconditions

1. The source file has been successfully written (BC-2.02.001 postconditions satisfied).
2. `brain:librarian` specialist agent is available.
3. `brain:orchestrator` coordinates the wiki generation pipeline.

## Postconditions

1. Between 5 and 15 new wiki pages are created in `wiki/{type}/{slug}.md` paths.
2. Each created wiki page passes `validate-frontmatter-schema.sh` (all mandatory fields present; `embedding_status: pending`).
3. Each created wiki page passes `validate-wikilink-integrity.sh` (all `[[slug]]` references resolve).
4. Each created wiki page has `source_ids` containing the ingest source's slug.
5. `wiki/index.md` is updated with entries for all new pages.
6. `wiki/log.md` is updated with ingest log entries.

## Invariants

1. The 5-page minimum is a hard contract: if the librarian produces fewer than 5 pages, the skill emits an advisory and the operator is prompted to manually review the source quality.
2. The 15-page maximum is a soft guidance: exceeding 15 pages generates an advisory suggesting consolidation.
3. All wiki page writes are blocked by the hook chain; any hook-rejected page is counted as a partial failure (propagated per BC-2.03.004 pattern).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Source produces fewer than 5 extractable concepts | Skill generates as many as possible; emits advisory E-INGEST-006 if fewer than 5 are produced. Does not block. |
| EC-002 | Wiki page slug collision (page already exists for the same slug) | Skip creation of the duplicate; log the skip in the ingest summary. Do not overwrite. |
| EC-003 | Wikilink-integrity hook blocks a page write | Page is counted as partial failure; other pages proceed. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Ingest of a typical 2000-word article | 5–15 wiki pages created; index updated; log updated; exit 0 | happy-path |
| Ingest of a very short page (< 500 words) | Potentially fewer than 5 pages; E-INGEST-006 advisory if < 5 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-015 | At least 5 wiki pages created on standard article ingest | bats integration.bats |
| VP-015 | All created pages pass schema validation | bats integration.bats |
| VP-015 | index.md updated after ingest | bats integration.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-002 ("URL Ingest Pipeline") per brief §Success Criteria §v0.1 ship gate ("`/brain:ingest-url` in the test brain produces 5+ wiki pages with cross-references and adversary-review PASS"). |
| Architecture Module | SS-02: URL Ingest Pipeline |
| Stories | STORY-017 |
| Source Brief Section | product-brief.md §Success Criteria §v0.1 ship gate; §Scope §Phase 0/1 primitives (#3) |

## Related BCs

- BC-2.02.001 — depends on (source write triggers this)
- BC-2.04.003 — composes with (wikilink integrity validated on each page write)
- BC-2.04.004 — composes with (schema validation on each page write)

## Changelog

### v1.3 (2026-05-30)

**BACKFILL: POL-14 auto-promotion at PR #16 merge (commit b30dd35). Originally missed in state-manager post-merge burst at PR-merge time; identified by Wave 4 Gate 3 adversary finding C01 (2026-05-30). status: draft → active. No semantic change to BC contract.**

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-017 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.
