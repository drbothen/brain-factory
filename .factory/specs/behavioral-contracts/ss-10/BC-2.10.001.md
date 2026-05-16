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
subsystem: "SS-10"
capability: "CAP-010"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.10.001: `/brain:quarantine-check <path>` scrubs prompt-injection patterns before content reaches tool-access session

## Description

`/brain:quarantine-check <path>` is the skill-level interface for the quarantine check. It reads a file (or URL content), runs it through the pattern corpus in `scripts/quarantine.mjs`, and returns a structured pass/fail verdict. This is distinct from the `quarantine-fetch.sh` hook (BC-2.04.001), which fires automatically on WebFetch events. `/brain:quarantine-check` is invoked explicitly by ingest skills before committing source content to `sources/`.

## Preconditions

1. `<path>` resolves to a readable file or URL content has been fetched.
2. `scripts/quarantine.mjs` is present at `${CLAUDE_PLUGIN_ROOT}/scripts/quarantine.mjs`.
3. Node 20+ is in PATH.

## Postconditions

**On clean content:**
1. Skill exits 0.
2. Returns: `{"verdict": "clean", "message": "Content passed quarantine check."}`.

**On injection pattern found:**
1. Skill exits 2.
2. Returns: `{"verdict": "blocked", "code": "E-QUARANTINE-001", "pattern_matched": "<name>", "message": "Prompt-injection pattern detected. Content quarantined."}`.
3. No content is committed to the brain.

## Invariants

1. The quarantine check is mandatory before ANY content from external sources reaches the brain's wiki or source layers.
2. The pattern corpus is loaded fresh on each invocation (no caching).
3. Fail-closed: if `scripts/quarantine.mjs` fails to load, exit 2.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Empty file | Clean verdict; exit 0. |
| EC-002 | Very large file (> 1MB) | Processed in full; no truncation. Performance may exceed 100ms (acceptable for skill-level check; hook-level has stricter budget). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Normal article content | `{"verdict": "clean"}`; exit 0 | happy-path |
| Content with injection patterns | `{"verdict": "blocked", "code": "E-QUARANTINE-001"}`; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-021 | Known injection patterns blocked | bats quarantine.bats |
| VP-021 | Clean content passes | bats quarantine.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-010 ("Prompt-Injection Quarantine") per brief §Scope §Phase 0/1 primitives skill #11 (`/brain:quarantine-check <path> — scrub prompt-injection patterns from content before agent access`) and §Constraints §Technical ("Prompt-injection quarantine non-optional. Every ingest pipeline MUST run `/brain:quarantine-check` before content reaches a Claude session with tool access. This is the most important rule in the entire system."). |
| Architecture Module | SS-10: Prompt-Injection Quarantine |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §Phase 0/1 primitives (#11); §Constraints §Technical |

## Related BCs

- BC-2.04.001 — related to (hook-level quarantine is the automatic equivalent)
- BC-2.10.002 — composes with (quarantine must fire on every WebFetch)
- BC-2.10.003 — depends on (pattern corpus)
