---
document_type: behavioral-contract
level: L3
version: "1.2"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-01"
capability: "CAP-001"
lifecycle_status: active
introduced: v0.1.0
modified: []
deprecated: null
deprecated_by: null
replacement: null
retired: null
removed: null
removal_reason: null
---

# Behavioral Contract BC-2.01.003: `/brain:init` rejects non-git-repo target directory with E-INIT-001

## Description

`/brain:init` requires a git repository to function. The first check the skill performs is `git rev-parse --git-dir`; if this exits non-zero, the skill aborts with a structured error before touching any files. This is documented as a Red Flag in the skill's `SKILL.md` and enforced at runtime. The error message must name the exact command the operator needs to run to fix the issue.

## Preconditions

1. `/brain:init` is invoked in a directory where `git rev-parse --git-dir` exits non-zero (no git repository present or ancestor chain terminates without finding `.git/`).

## Postconditions

1. The skill exits with code 2.
2. The skill emits a structured JSON error on stdout: `{"level": "error", "code": "E-INIT-001", "message": "brain:init requires a git repository — run `git init -b main` first", "trace": "<uuid>"}`.
3. No files are created or modified in the working directory.
4. No subdirectories are created.

## Invariants

1. The git-repo check is the FIRST check performed — before any file system writes, before any template resolution.
2. If the check fails, the skill does not attempt to recover or prompt for confirmation.

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Working directory is inside a git repo but not the root | `git rev-parse --git-dir` succeeds; init proceeds. The brain is initialized at the current working directory, not at the git root. This is intentional and documented. |
| EC-002 | Working directory is a bare git repository | `git rev-parse --git-dir` succeeds on a bare repo; however, init requires a working tree. Skill must detect bare repo (`git rev-parse --is-bare-repository` = true) and emit E-INIT-007 with message "brain:init requires a working-tree repository — bare repos are not supported." |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Temp directory with no `.git/` | `{"code": "E-INIT-001", ...}`; exit 2; no files created | error |
| `/tmp` directory (definitely not a git repo) | `{"code": "E-INIT-001", ...}`; exit 2 | error |
| Directory inside a valid git repo (non-bare) | Init proceeds normally | happy-path |
| Bare git repository (`git init --bare`) | `{"code": "E-INIT-007", ...}`; exit 2 | edge-case |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-014 | E-INIT-001 emitted on non-git directory | bats unit assertion |
| VP-014 | No files created on error exit | bats file-system assertion |
| VP-014 | Git check is first operation (no file writes before check) | bats + bash trace |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-001 ("Brain Initialization and Scaffold") per brief §Scope §Phase 0/1 primitives skill #1 and §Target Users §Non-users ("Users without git/GitHub" — `/brain:init` requires `git init -b main`). This BC covers the error-case branch of the init contract. |
| L2 Domain Invariants | N/A |
| Architecture Module | SS-01: Brain Initialization and Scaffold |
| Stories | STORY-003 |
| Source Brief Section | product-brief.md §Target Users §Non-users, §Scope §Phase 0/1 primitives |

## Related BCs

- BC-2.01.001 — depends on (this is the error branch of BC-2.01.001)

## Architecture Anchors

- `architecture/subsystems/SS-01-brain-init-scaffold.md`

## Story Anchor

STORY-003

## VP Anchors

- VP-014 — Brain init scaffold completeness (bats integration.bats)

## Changelog

### v1.2 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-003; Story Anchor updated from [S-TBD] to STORY-003. No semantic change to BC contract.
