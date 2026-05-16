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

# Behavioral Contract BC-2.04.011: `enforce-kebab-case.sh` blocks file writes with non-kebab-case filenames (exit 2)

## Description

`enforce-kebab-case.sh` fires on PreToolUse (Write|Edit). It validates that the target filename is kebab-case (lowercase letters, hyphens, digits; no spaces, no underscores, no uppercase letters) before the write is allowed. Wiki filename immutability (brain-factory-002) depends on filenames being kebab-case from creation — renames break backlinks. The hook blocks at PreToolUse so no bad filename ever reaches the filesystem.

## Preconditions

1. PreToolUse fires on Write or Edit.
2. The target file path is extractable from the stdin payload.
3. The kebab-case rule applies to the filename (basename), not the full path. Directory names are exempt from this hook (though directory names are also kebab-case by convention).

## Postconditions

**On non-kebab-case filename:**
1. Hook exits 2.
2. stdout: `{"verdict": "block", "code": "E-NAMING-001", "message": "Filename '<name>' is not kebab-case. Rename to '<suggested-kebab-name>' before writing.", "trace": "<uuid>"}`.
3. The suggested name converts the input to kebab-case (lowercase, spaces→hyphens, underscores→hyphens).

**On kebab-case filename:**
1. Hook exits 0.

## Invariants

1. Kebab-case pattern: `^[a-z0-9][a-z0-9-]*(\.[a-z0-9]+)?$` (lowercase, hyphens, optional extension).
2. The hook applies to ALL Write/Edit calls — not only wiki files. This catches hook scripts, skill files, and template files with bad names too.
3. Known exceptions: `.brain/STATE.md`, `.brain/manifest.json`, `CLAUDE.md`, `README.md`, `CHANGELOG.md`, `MANIFEST.md`, `LICENSE`. These uppercase-convention files are excluded from the check. The hook maintains an explicit exception list.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Writing `CLAUDE.md` | Exempt. Exit 0. |
| EC-002 | Writing `wiki/concepts/My Page.md` | E-NAMING-001; exit 2. Suggestion: `my-page.md`. |
| EC-003 | Writing `wiki/concepts/my_page.md` (underscore) | E-NAMING-001; exit 2. Suggestion: `my-page.md`. |
| EC-004 | Writing `wiki/concepts/my-page.md` | Exit 0. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Target: `wiki/concepts/ai-agents.md` | exit 0 | happy-path |
| Target: `wiki/concepts/AI Agents.md` | E-NAMING-001; exit 2 | error |
| Target: `wiki/concepts/ai_agents.md` | E-NAMING-001; exit 2 | error |
| Target: `CLAUDE.md` | exit 0 (exempt) | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-017 | Non-kebab-case names blocked | bats hooks.bats |
| VP-017 | Valid kebab-case names pass | bats hooks.bats |
| VP-017 | Exception list covers known uppercase files | bats hooks.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-004 ("Hook Enforcement Chain") per brief §Scope §13 bash hooks (#3 `enforce-kebab-case.sh`) and CLAUDE.md §Conventions ("Filenames are kebab-case, lowercase, no spaces. Wiki filenames are IMMUTABLE after creation"). |
| Architecture Module | SS-04: Hook Enforcement Chain |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Scope §13 bash hooks (#3); CLAUDE.md brain-factory-002 |

## Related BCs

- BC-2.04.016 — composes with
- BC-2.05.003 — related to (rename-page skill is the correct path for slug changes)
