---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-TBD"
capability: "CAP-004"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.04.006: `validate-index-log-coherence.sh` blocks index/log writes that break coherence invariant (exit 2)

## Description

`validate-index-log-coherence.sh` fires on PostToolUse (Write|Edit on `wiki/index.md` or `wiki/log.md`). It enforces that the wiki index and ingest log remain coherent: every page listed in `index.md` has a corresponding entry in `log.md` (and vice versa for ingest-log entries). Liu's 6-month practitioner report documented index-log drift as a failure mode that causes orphan pages to accumulate silently. This hook prevents drift at write time.

## Preconditions

1. PostToolUse fires on Write|Edit to `wiki/index.md` or `wiki/log.md`.
2. Both `wiki/index.md` and `wiki/log.md` are readable.

## Postconditions

**On coherence violation (index has page not in log, or vice versa):**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-WIKI-003", "message": "Index-log coherence violation: [<slug>] appears in index but not in log.", "trace": "<uuid>"}`.

**On coherent state:**
1. Hook exits 0. stdout: `{"verdict": "allow", ...}`.

## Invariants

1. Both files are read atomically from disk at hook execution time — no caching.
2. Fail-closed: if either file is unreadable, exit 2 with E-WIKI-004.
3. The coherence check runs on EVERY write to either file, not only on "suspicious" writes.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Brand-new brain with empty index and log | Both empty → coherent → exit 0. |
| EC-002 | log.md exists but index.md is missing | Exit 2 with E-WIKI-004 (fail-closed). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Coherent index + log (all slugs match) | `{"verdict": "allow", ...}`; exit 0 | happy-path |
| Index has `slug-a` but log does not | `{"verdict": "block", "code": "E-WIKI-003", ...}`; exit 2 | error |
| Both files empty (new brain) | `{"verdict": "allow", ...}`; exit 0 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Coherence violation → exit 2 | bats hooks.bats |
| VP-TBD | Coherent state → exit 0 | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#7 `validate-index-log-coherence.sh`) and §Prior Art ("Liu's 6-month report: documents drift, hallucination, and ownership-noise failure modes"). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#7); §Prior Art |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.05.001 — related to (lint-wiki checks the same coherence property)
