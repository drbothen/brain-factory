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
subsystem: "SS-04"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.003: `validate-wikilink-integrity.sh` blocks wiki writes with broken wikilinks (exit 2)

## Description

`validate-wikilink-integrity.sh` fires on PostToolUse (Write|Edit on `wiki/*`). It validates that every wikilink in the written page (`[[slug]]` syntax) resolves to an existing file in `wiki/{type}/{slug}.md` via the wiki index (`wiki/index.md`). Broken wikilinks accumulate into orphan-page drift — documented as a 6-month failure mode by practitioner Nguyen. Hard block (exit 2) prevents broken-link accumulation.

## Preconditions

1. Claude Code fires PostToolUse on Write|Edit targeting `wiki/**`.
2. `wiki/index.md` exists and is readable.
3. `awk` is available for wikilink extraction.

## Postconditions

**On broken wikilink found:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-WIKI-001", "message": "Broken wikilink [[<slug>]] in <path>. No matching wiki page found.", "trace": "<uuid>"}`.
3. Reports ALL broken links in a single response (not just the first).
4. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "wiki.wikilink.broken", "hook_name": "validate-wikilink-integrity.sh", "path": "<path>", "broken_slugs": ["<slug>"]}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On all wikilinks resolve:**
1. Hook exits 0.
2. stdout: `{"verdict": "allow", "message": "All wikilinks valid.", "trace": "<uuid>"}`.
3. Hook emits JSONL event to stderr: `{"ts": "<ISO8601>", "event_type": "wiki.wikilink.validated", "hook_name": "validate-wikilink-integrity.sh", "path": "<path>"}`. (Past-tense verb per SS-17 §Event-type naming convention.)

**On no wikilinks in file:**
1. Hook exits 0 (no links = no broken links).

## Invariants

1. Resolution is index-first: check `wiki/index.md` for the slug entry (O(n) scan). Do NOT scan all wiki files on every write (O(n²)).
2. Fail-closed: if `wiki/index.md` is missing or unreadable, hook exits 2 with E-WIKI-002.
3. Wikilink syntax: `[[slug]]` only (no path qualifiers). The hook resolves slugs against `wiki/{type}/{slug}.md` by scanning the index, not by searching the filesystem directly.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | File has no wikilinks | Exit 0 (vacuously true). |
| EC-002 | wiki/index.md missing | Exit 2 with E-WIKI-002 (fail-closed). |
| EC-003 | Multiple broken wikilinks in one file | All broken slugs reported in single `message` array field. Still exits 2. |
| EC-004 | Wikilink to a page being created in the same write batch | Edge: the link might resolve once the batch completes. Hook reports a block; the skill must ensure the index is updated before writing pages that reference each other. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Wiki page with all valid `[[slug]]` wikilinks | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Wiki page with `[[nonexistent-slug]]` | `{"verdict": "block", "code": "E-WIKI-001", ...}`; exit 2 | error |
| Wiki page with zero wikilinks | `{"verdict": "allow", ...}`; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-002, VP-004 | Broken wikilink → exit 2 | bats hooks.bats |
| VP-002, VP-004 | Valid wikilinks → exit 0 | bats hooks.bats |
| VP-002, VP-004 | O(n) resolution (index-first, not filesystem scan) | bats performance assertion |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#6 `validate-wikilink-integrity.sh`) and §Prior Art ("Nguyen's 6-month practitioner report: documents index-log drift and orphan-page accumulation"). |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#6); §Prior Art §Real-world practitioner reports |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.05.001 — related to (lint-wiki also checks wikilinks at bulk-audit time)
- BC-2.04.006 — related to (index coherence hook is co-dependent)
