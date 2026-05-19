---
artifact_type: story
story_id: STORY-009
epic_id: EPIC-02
title: "validate-frontmatter-schema.sh: enforce embedding_status and all mandatory wiki/source fields"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P0
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.004, BC-2.04.005]
vps: [VP-002, VP-005]
dependencies: [STORY-001, STORY-006]
blocks: []
inputs:
  - architecture/subsystems/SS-04-hook-enforcement-chain.md
  - architecture/adr/ADR-002-hook-chain-contract.md
  - architecture/adr/ADR-016-hook-helper-architecture.md
  - behavioral-contracts/ss-04/BC-2.04.004.md
  - behavioral-contracts/ss-04/BC-2.04.005.md
  - architecture/verification-properties/VP-002-posttooluse-hook-trigger.md
  - architecture/verification-properties/VP-005-frontmatter-schema-conformance.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
---

# STORY-009: validate-frontmatter-schema.sh — enforce embedding_status and all mandatory wiki/source fields

## Goal

Implement `validate-frontmatter-schema.sh` as a PostToolUse hook on Write|Edit calls
targeting `wiki/**`. The hook enforces the complete mandatory-frontmatter set for wiki
pages: `title`, `type` (one of the 6 valid values), `created`, `source_ids`, and
`embedding_status` (one of `pending|computed|stale`). Any missing or invalid field is a
hard block (exit 2). This hook ensures every wiki page is v1.0 vector-retrieval ready
from day one and that the wiki type taxonomy does not drift.

## User Value

As a brain operator, I want every wiki page write to be validated against the required
frontmatter schema so that I can never accidentally create a page that would break
vector embedding or that uses an undefined wiki type, and so my wiki remains consistently
structured without manual auditing.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.04.004 | `validate-frontmatter-schema.sh` blocks wiki writes missing `embedding_status` field (exit 2) | P0 |
| BC-2.04.005 | `validate-frontmatter-schema.sh` blocks wiki writes missing other mandatory fields (exit 2) | P0 |

## Acceptance Criteria

**AC-001** — `validate-frontmatter-schema.sh` starts with `#!/usr/bin/env bash`, has
`set -euo pipefail` within the first 10 lines, reads JSON from stdin, never uses `eval`,
and every `exit` uses `0`, `1`, or `2` only.
(traces to BC-2.04.004 precondition 1; ADR-002 §hook-contract invariants)

**AC-002** — Given a wiki file write with all 5 mandatory fields present and valid
(`title`, `type: concepts`, `created`, `source_ids: []`, `embedding_status: pending`),
the hook exits 0 and stdout is `{"verdict":"allow","message":"Frontmatter schema valid.","trace":"<uuid>"}`.
(traces to BC-2.04.004 postconditions on valid embedding_status: 1–3;
BC-2.04.005 postconditions on all mandatory fields present: 1–2)

**AC-003** — Given a wiki file missing `embedding_status`, the hook exits 2 and stdout
contains `"code":"E-SCHEMA-001"` and a message naming the missing field.
(traces to BC-2.04.004 postconditions on missing embedding_status: 1–3)

**AC-004** — Given a wiki file with `embedding_status: invalid_value`, the hook exits 2
and stdout contains `"code":"E-SCHEMA-002"`. Valid values are exactly `pending`,
`computed`, `stale` (case-sensitive).
(traces to BC-2.04.004 postconditions on invalid embedding_status value: 1–3; invariant 2)

**AC-005** — Given a wiki file with no YAML frontmatter block at all (no `---` fence),
the hook exits 2 and stdout contains `"code":"E-SCHEMA-004"`.
(traces to BC-2.04.004 edge case EC-001)

**AC-006** — When `yq` is absent from PATH, the hook exits 2 and stdout contains
`"code":"E-SCHEMA-005"`. Fail-closed.
(traces to BC-2.04.004 edge case EC-003; invariant 3)

**AC-007** — Given a wiki file missing any of the other 4 mandatory fields (`title`,
`type`, `created`, `source_ids`), the hook exits 2 and stdout contains
`"code":"E-SCHEMA-006"` and a `missing_fields` array naming all absent fields.
(traces to BC-2.04.005 postconditions on missing mandatory field: 1–3)

**AC-008** — Given a wiki file with `type: concept` (singular — not in the allowed set),
the hook exits 2 and stdout contains `"code":"E-SCHEMA-007"`. All 6 valid type values
(`concepts`, `people`, `frameworks`, `syntheses`, `observations`, `questions`) are
accepted when present; any other value is rejected.
(traces to BC-2.04.005 postconditions on invalid type: 1–3; invariant 2)

**AC-009** — Given a write to `sources/ai/slug.md` (not `wiki/**`), the hook applies the
sources schema (different field set: `title`, `url`, `ingested_at`, `source_id`, `topic`).
The `embedding_status` requirement does NOT apply to source writes.
(traces to BC-2.04.005 invariant 3; BC-2.04.004 invariant 1)

**AC-010** — `embedding_status: null` is treated as an invalid value (exits 2 with
E-SCHEMA-002), not as a missing field.
(traces to BC-2.04.004 edge case EC-002)

**AC-011** — Given a blocked payload (any error), stderr contains JSONL with
`"event_type":"frontmatter.schema.violated"`, `"hook_name":"validate-frontmatter-schema.sh"`,
and a field identifying the violated constraint (`"missing_field"` or `"missing_fields"`
or `"invalid_field"`). Given a valid payload, stderr contains
`"event_type":"frontmatter.schema.validated"`.
(traces to BC-2.04.004 postconditions: missing field step 3, valid step 3;
BC-2.04.005 postconditions: missing step 3, all-valid step 2; BC-2.04.017 event catalog)

**AC-012** — `shellcheck` exits 0. `shfmt -d -i 2` produces no diff.
(traces to CLAUDE.md §Conventions)

## Tasks

1. **[failing test — Red Gate]** Extend `plugins/brain-factory/tests/hooks.bats` with
   VP-002 and VP-005 assertions in failing state:
   - Test: complete valid wiki frontmatter → exit 0.
   - Test: missing `embedding_status` → exit 2 + E-SCHEMA-001.
   - Test: `embedding_status: invalid_value` → exit 2 + E-SCHEMA-002.
   - Test: `embedding_status: null` → exit 2 + E-SCHEMA-002.
   - Test: no frontmatter → exit 2 + E-SCHEMA-004.
   - Test: `yq` absent in PATH → exit 2 + E-SCHEMA-005.
   - Test: missing `title` → exit 2 + E-SCHEMA-006.
   - Test: missing `type` → exit 2 + E-SCHEMA-006.
   - Test: `type: concept` (invalid) → exit 2 + E-SCHEMA-007.
   - Parameterized test: all 6 valid type values pass.
   - Test: source path write → applies sources schema (no embedding_status check).
   Create fixtures: `wiki-page-full-valid.md`, `wiki-page-missing-embedding.md`,
   `wiki-page-bad-embedding.md`, `wiki-page-no-frontmatter.md`, `wiki-page-missing-title.md`,
   `wiki-page-bad-type.md`, `source-page-valid.md`.
   Run bats — confirm all new tests fail.

2. **[impl]** Implement `plugins/brain-factory/hooks/validate-frontmatter-schema.sh`
   per BC-2.04.004 and BC-2.04.005:
   - `#!/usr/bin/env bash` + `set -euo pipefail`
   - Check `yq` is in PATH; exit 2 with E-SCHEMA-005 if absent
   - Extract the written file path from stdin JSON payload
   - Determine schema type from path: `wiki/**` → wiki schema; `sources/**` → sources
     schema; other paths → skip (exit 0)
   - For wiki schema:
     - Parse YAML frontmatter using `yq eval` on the file; exit 2 with E-SCHEMA-004 if no
       frontmatter found
     - Check each mandatory field: `title`, `type`, `created`, `source_ids`,
       `embedding_status`; collect all missing fields
     - If any missing: emit E-SCHEMA-001 (if only `embedding_status`) or E-SCHEMA-006
       (other/multiple fields) stdout + `frontmatter.schema.violated` JSONL stderr; exit 2
     - Validate `embedding_status` value against `pending|computed|stale`; emit E-SCHEMA-002
       if invalid
     - Validate `type` value against the 6 valid values; emit E-SCHEMA-007 if invalid
   - For sources schema: check `title`, `url`, `ingested_at`, `source_id`, `topic`
   - On success: emit `frontmatter.schema.validated` JSONL stderr; exit 0

3. **[green]** Run `bats plugins/brain-factory/tests/hooks.bats` — all VP-005 tests pass.

4. **[green]** Run `shellcheck` and `shfmt -d -i 2` on the hook script — clean.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Complete wiki frontmatter (all 5 fields valid) | exit 0; `{"verdict":"allow",...}` | happy-path | BC-2.04.004 + BC-2.04.005 |
| Wiki page missing `embedding_status` | exit 2; `{"code":"E-SCHEMA-001",...}` | error | BC-2.04.004 |
| Wiki page with `embedding_status: invalid_value` | exit 2; `{"code":"E-SCHEMA-002",...}` | error | BC-2.04.004 |
| Wiki page with `embedding_status: null` | exit 2; `{"code":"E-SCHEMA-002",...}` | edge-case | BC-2.04.004 EC-002 |
| Wiki page with no frontmatter at all | exit 2; `{"code":"E-SCHEMA-004",...}` | edge-case | BC-2.04.004 EC-001 |
| `yq` not in PATH | exit 2; `{"code":"E-SCHEMA-005",...}` | edge-case | BC-2.04.004 EC-003 |
| Wiki page missing `title` | exit 2; `{"code":"E-SCHEMA-006","missing_fields":["title"],...}` | error | BC-2.04.005 |
| Wiki page with `type: concept` (invalid) | exit 2; `{"code":"E-SCHEMA-007",...}` | error | BC-2.04.005 |
| Wiki page with `type: concepts` (valid) | exit 0 | happy-path | BC-2.04.005 |
| `source_ids: []` (empty list on wiki page) | exit 0 (allowed) | edge-case | BC-2.04.005 EC-003 |
| Write to `sources/ai/slug.md` with sources schema | exit 0 (different schema applied) | edge-case | BC-2.04.005 invariant 3 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-002 | PostToolUse hook trigger on wiki writes | `tests/hooks.bats` |
| VP-005 | Missing `embedding_status` → exit 2 | `tests/hooks.bats` |
| VP-005 | Valid `embedding_status` → exit 0 | `tests/hooks.bats` |
| VP-005 | All 5 mandatory fields enforced | `tests/hooks.bats` (one test per field) |
| VP-005 | All 6 valid type values pass | `tests/hooks.bats` (parameterized) |
| VP-005 | Invalid type value → exit 2 | `tests/hooks.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-04-hook-enforcement-chain.md`, ADR-002:

1. `validate-frontmatter-schema.sh` is a **PostToolUse** hook (matcher: `Write|Edit` on
   `wiki/**`). Also applies to `sources/**` with a different schema.
2. The `embedding_status` check applies **only to `wiki/**` paths**. Source files have a
   different mandatory-field set. The hook MUST detect the path prefix and apply the
   correct schema.
3. `yq` is required for frontmatter parsing. If `yq` is absent: fail-closed (exit 2 with
   E-SCHEMA-005). Do NOT use `grep`/`awk` to parse YAML — YAML parsing requires `yq`.
4. All error codes (`E-SCHEMA-001` through `E-SCHEMA-007`) are defined in the error
   taxonomy. Do NOT invent new codes outside this range without flagging as "NEW — add to
   taxonomy."
5. JSONL events emitted via `hooks/lib/hook-event-emit.sh` (ADR-016).
6. The 6 valid wiki type values are exactly: `concepts`, `people`, `frameworks`,
   `syntheses`, `observations`, `questions` — case-sensitive lowercase. No aliases, no
   singular forms.

**Forbidden dependencies:** `validate-frontmatter-schema.sh` must NOT depend on Node.js
or any non-standard tool beyond bash, jq, yq, and grep.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.x+ | CLAUDE.md §Conventions; ADR-001 |
| `jq` | 1.6+ | ADR-002 §hook-stdin-parsing |
| `yq` | 4.x+ | BC-2.04.004 precondition 3; CLAUDE.md §Build & Test |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.9+ | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (`-i 2`) | CLAUDE.md §Conventions |

No Node.js required.

## File Structure Requirements

Files to create/modify:

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/hooks/validate-frontmatter-schema.sh` | Modify (replace stub) | Full implementation per BC-2.04.004 + BC-2.04.005 |
| `plugins/brain-factory/tests/hooks.bats` | Extend | VP-002 + VP-005 assertions |
| `plugins/brain-factory/tests/fixtures/wiki-page-full-valid.md` | Create | All 5 mandatory fields; valid values |
| `plugins/brain-factory/tests/fixtures/wiki-page-missing-embedding.md` | Create | Missing `embedding_status` |
| `plugins/brain-factory/tests/fixtures/wiki-page-bad-embedding.md` | Create | `embedding_status: invalid_value` |
| `plugins/brain-factory/tests/fixtures/wiki-page-no-frontmatter.md` | Create | No `---` fence |
| `plugins/brain-factory/tests/fixtures/wiki-page-missing-title.md` | Create | `title` absent |
| `plugins/brain-factory/tests/fixtures/wiki-page-bad-type.md` | Create | `type: concept` (invalid) |
| `plugins/brain-factory/tests/fixtures/source-page-valid.md` | Create | Valid sources schema fields |

Files NOT to modify: `hooks.json.template`, `plugin.json`, any file under `.factory/`.

## Previous Story Intelligence

STORY-007 and STORY-008 established `tests/hooks.bats` and the fixture pattern. This
story adds new test cases to the same file. STORY-008 confirmed the `awk`/`grep` pattern
for wikilink extraction; this story uses `yq` for YAML parsing (different tool — ensure
`yq` is installed via `make setup` before running bats). The path-routing logic (wiki vs
sources) is new in this story and requires careful path-prefix detection.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,000 |
| SS-04 subsystem design | ~1,500 |
| ADR-002 hook chain contract | ~1,500 |
| ADR-016 helper architecture | ~1,000 |
| BC-2.04.004, BC-2.04.005 files | ~1,600 |
| VP-002, VP-005 files | ~800 |
| hooks.bats prior stories' content | ~1,000 |
| Test output context | ~500 |
| **Total** | **~10,900** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `validate-page-type-policy.sh` (path-based type enforcement) — STORY-010; this story
  enforces the `type` frontmatter field value, not the directory path
- Sources-layer immutability check — STORY-007
- `embedding_status` state machine transitions (pending → computed → stale) — EPIC-04
  wiki layer stories (BC-2.05.006)

## Anchors

- BC-2.04.004: `behavioral-contracts/ss-04/BC-2.04.004.md`
- BC-2.04.005: `behavioral-contracts/ss-04/BC-2.04.005.md`
- VP-002: `architecture/verification-properties/VP-002-posttooluse-hook-trigger.md`
- VP-005: `architecture/verification-properties/VP-005-frontmatter-schema-conformance.md`
- SS-04: `architecture/subsystems/SS-04-hook-enforcement-chain.md`
- ADR-002: `architecture/adr/ADR-002-hook-chain-contract.md`
- ADR-016: `architecture/adr/ADR-016-hook-helper-architecture.md`
