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
capability: "CAP-003"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.03.003: `/brain:ingest-source` rejects paths outside the brain vault root

## Description

To prevent accidental ingestion of system files or credential files, `/brain:ingest-source` validates that the provided path resolves within the brain vault root (or an explicitly allow-listed path in `.brain/policies.yaml`). Any path that resolves to a system directory or outside the vault is rejected before reading.

## Preconditions

1. The path argument is provided.
2. The brain vault root is known (the directory containing `.brain/`).

## Postconditions

**On out-of-vault path:**
1. Exit 2 with E-INGEST-009: "Path '<resolved-path>' is outside the brain vault. Only vault-relative paths are allowed."
2. No file read performed.

**On in-vault path:**
1. Continue with ingest (BC-2.03.001).

## Invariants

1. Path resolution uses `realpath` to handle symlinks and `..` traversal.
2. System directories (`/etc/`, `/usr/`, `/var/`, `/sys/`, `/proc/`) are always blocked regardless of policy.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Symlink inside vault pointing outside vault | Resolved path is outside vault → E-INGEST-009. |
| EC-002 | Operator policy explicitly allows `/Users/jmagady/Downloads/` | Path resolution proceeds if policy permits the path. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| `./sources/ai/my-article.md` (in vault) | Ingest proceeds | happy-path |
| `/etc/passwd` | E-INGEST-009; exit 2 | error |
| `../../outside-vault/file.md` | E-INGEST-009; exit 2 (resolved path is outside vault) | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-TBD | Out-of-vault path blocked | bats skills.bats |
| VP-TBD | System directories always blocked | bats skills.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-003 ("Source Ingest Pipeline") per brief §Scope §Phase 0/1 primitives (#4) and §Constraints §Technical ("Engine read-only at runtime. State lives exclusively in the target's `.brain/`."). |
| Architecture Module | [filled by architect] |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Constraints §Technical |

## Related BCs

- BC-2.03.001 — composes with (path check is first gate in ingest)
