---
artifact_type: story
story_id: STORY-022
epic_id: EPIC-04
title: "meta-lint.bats SKILL.md and AGENT.md validation surfaces"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-18]
behavioral_contracts: [BC-2.18.001, BC-2.18.003]
vps: [VP-006]
dependencies: [STORY-001, STORY-002, STORY-003, STORY-004, STORY-005]
blocks: [STORY-023]
inputs:
  - architecture/subsystems/SS-18-meta-lint-self-audit.md  # v1.5 (F-PHASE2-STEP-B-CLOSEOUT-O1: per-hook .bats canonical; SKILL/AGENT surfaces unchanged)
  - behavioral-contracts/ss-18/BC-2.18.001.md
  - behavioral-contracts/ss-18/BC-2.18.003.md
  - architecture/verification-properties/VP-006-meta-lint-suite.md
input-hash: ""
# BC status: all BCs assigned; status=draft per Spec-First Gate S-7.01 until PO review
# SS-18 v1.5 impact: §Test surface organization and §Hook script surface changed (bats suite
# model); the SKILL.md surface (BC-2.18.001) and AGENT.md surface (BC-2.18.003) covered by
# this story are UNCHANGED in v1.5. No AC content changes required. Inputs reference bumped
# to v1.5 for audit-trail completeness.
# Bundling rationale: BC-2.18.001 (SKILL.md surface) and BC-2.18.003 (AGENT.md surface)
# both write to the same test file (meta-lint.bats) and share the same fixture
# infrastructure (one passing SKILL.md fixture, one failing SKILL.md fixture, same for
# AGENT.md). Splitting would require two story writers to coordinate on the same bats
# file without collision. Together they produce the "factory validates its own skill and
# agent artifacts" deliverable — a coherent user-facing quality gate.
---

# STORY-022: `meta-lint.bats` SKILL.md and AGENT.md validation surfaces

## Goal

Deliver the SKILL.md surface and AGENT.md surface of `meta-lint.bats` — the bats suite
that validates the factory's own source artifacts. After this story, every `SKILL.md`
across all 26 skills and every `AGENT.md` across all 14 agents is validated by an
automated bats suite that enforces the CLAUDE.md §Meta-Lint Contract assertions.
Failures are caught in CI and at pre-push, not during adversarial review.

## User Value

As a brain-factory developer, I want `bats tests/meta-lint.bats` to verify that every
SKILL.md has correct frontmatter, canonical section ordering, a non-empty Iron Law, at
least one Red Flag bullet, a numbered Procedure, and no hardcoded `.claude/templates/`
paths — and that every AGENT.md has the required frontmatter fields, an Agent Routing
Table reference, and explicit tool enumeration — so that non-conformant factory artifacts
are caught before they reach adversarial review.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.18.001 | `meta-lint.bats` validates SKILL.md frontmatter and canonical 6-section structure | P0 |
| BC-2.18.003 | `meta-lint.bats` validates AGENT.md scope + tool-profile + routing reference | P0 |

## Acceptance Criteria

### SKILL.md Validation Surface (BC-2.18.001)

**AC-001** — `meta-lint.bats` has a `@test` block for each of the following SKILL.md
assertions: (a) frontmatter present with `name`, `description`, `argument-hint`,
`allowed-tools` fields all non-empty; (b) `name` field value matches the skill's
directory name; (c) body contains the six section headings in canonical order:
`Iron Law`, `Red Flags`, `Announce-at-Start`, `Procedure`, `Quality Bar`, `Output`;
(d) Iron Law section body is non-empty and its content is ≤ 200 characters;
(e) Red Flags section has ≥ 1 bullet (line matching `^\s*[-*]` or numbered item);
(f) Procedure section has ≥ 1 numbered item (`^\d+\.`); (g) no occurrence of
`.claude/templates/` anywhere in the body.
(traces to BC-2.18.001 postcondition 1; invariant 1)

**AC-002** — When all 26 skills pass all assertions, `bats tests/meta-lint.bats` exits 0.
(traces to BC-2.18.001 postcondition 2)

**AC-003** — When a SKILL.md is missing the `Iron Law` section, the test for assertion
(c) fails with a message that includes the skill name and the missing section heading.
The failure does NOT produce an undifferentiated "assertion failed" — it must name the
artifact and the violated assertion.
(traces to BC-2.18.001 edge case EC-001)

**AC-004** — When a SKILL.md has an Iron Law section body exceeding 200 characters,
the test for assertion (d) fails with a message: `"Iron Law too long in <skill-name>."`.
(traces to BC-2.18.001 edge case EC-002)

**AC-005** — When a SKILL.md contains `.claude/templates/` in its body, assertion (g)
fails with the path and occurrence context.
(traces to BC-2.18.001 canonical test vector 3)

**AC-006** — The SKILL.md test cases use fixture files in
`tests/fixtures/meta-lint/`: a `valid-skill/SKILL.md` fixture that passes all assertions
and an `invalid-skill-missing-iron-law/SKILL.md` fixture that fails assertion (c).
Tests reference fixtures, not the live plugin skills, so the test suite runs even when
the plugin skills are stubs.
(traces to BC-2.18.001; general bats fixture discipline)

**AC-007** — A secondary test validates the 26 live SKILL.md files: iterates over
`plugins/brain-factory/skills/*/SKILL.md` and asserts all assertions pass for each.
When running against the live plugin (post Phase 3), this test catches regressions on
individual skills. During Phase 2 (before skill implementation), this test is skipped
if the `skills/` directory is empty or contains only stubs; the fixture-based tests
in AC-006 still run.
(traces to BC-2.18.001 postcondition 1)

### AGENT.md Validation Surface (BC-2.18.003)

**AC-008** — `meta-lint.bats` has a `@test` block for each of the following AGENT.md
assertions: (a) frontmatter present with `name`, `scope`, `tool-profile` fields
non-empty; (b) body contains the exact substring `Agent Routing Table` (case-sensitive;
no paraphrase accepted); (c) `allowed-tools` and `denied-tools` are explicitly
enumerated — at least one of them is non-empty (an AGENT.md with both empty is a
failure); (d) filename and directory are kebab-case lowercase.
(traces to BC-2.18.003 postcondition 1; invariants 1–2)

**AC-009** — When all 14 agents pass all assertions, the AGENT.md test group exits 0.
(traces to BC-2.18.003 postcondition 2)

**AC-010** — When an AGENT.md has `tool-profile` in frontmatter but the body lists
zero `allowed-tools` and zero `denied-tools`, the assertion fails. An empty
`tool-profile` section is not equivalent to a complete tool-profile declaration.
(traces to BC-2.18.003 edge case EC-001)

**AC-011** — When an AGENT.md references the routing table using paraphrased text
(e.g., "see the routing rules") instead of the exact string `Agent Routing Table`,
assertion (b) fails with a message: `"<agent-name> AGENT.md does not contain 'Agent
Routing Table' substring."`.
(traces to BC-2.18.003 edge case EC-002)

**AC-012** — Fixture files exist: `tests/fixtures/meta-lint/valid-agent/AGENT.md`
(passes all assertions) and `tests/fixtures/meta-lint/invalid-agent-no-routing/AGENT.md`
(missing routing table reference; fails assertion (b)).
(traces to BC-2.18.003; bats fixture discipline)

**AC-013** — A secondary test validates the 14 live AGENT.md files in
`plugins/brain-factory/agents/` — same Phase 2 skip-if-empty discipline as AC-007.
(traces to BC-2.18.003 postcondition 1)

## Tasks

1. **[stub]** Create `plugins/brain-factory/tests/meta-lint.bats` with an empty test
   file: correct bats shebang, `load test_helper.bash`, and a placeholder `@test "meta-lint: placeholder" { true; }`. This is the stub that makes meta-lint.bats exist without any failing tests yet.

2. **[failing test — Red Gate]** Add failing `@test` blocks for all SKILL.md assertions
   (AC-001 through AC-007) and AGENT.md assertions (AC-008 through AC-013) to
   `tests/meta-lint.bats`. Create fixture files:
   - `tests/fixtures/meta-lint/valid-skill/SKILL.md` — a compliant minimal SKILL.md.
   - `tests/fixtures/meta-lint/invalid-skill-missing-iron-law/SKILL.md` — SKILL.md with
     Iron Law section absent.
   - `tests/fixtures/meta-lint/invalid-skill-hardcoded-path/SKILL.md` — SKILL.md with
     `.claude/templates/foo.md` in body.
   - `tests/fixtures/meta-lint/invalid-skill-long-iron-law/SKILL.md` — SKILL.md with
     Iron Law section body > 200 chars.
   - `tests/fixtures/meta-lint/valid-agent/AGENT.md` — a compliant minimal AGENT.md.
   - `tests/fixtures/meta-lint/invalid-agent-no-routing/AGENT.md` — AGENT.md missing
     `Agent Routing Table` substring.
   - `tests/fixtures/meta-lint/invalid-agent-empty-tools/AGENT.md` — AGENT.md with
     empty `allowed-tools: []` and empty `denied-tools: []`.
   Run bats — confirm all new tests fail (Red Gate confirmed).

3. **[impl]** Implement SKILL.md assertions in `meta-lint.bats`:
   - Helper function `check_skill_frontmatter_fields <file>`: uses `yq` to assert
     `name`, `description`, `argument-hint`, `allowed-tools` are non-empty.
   - Helper function `check_skill_sections <file>`: uses `grep -n` to verify the 6
     canonical section headings appear in order.
   - Helper function `check_skill_iron_law_length <file>`: extracts Iron Law section
     body, asserts `wc -c` ≤ 200.
   - Helper function `check_skill_red_flags_bullet <file>`: asserts Red Flags section
     has ≥ 1 bullet line.
   - Helper function `check_skill_procedure_numbered <file>`: asserts Procedure section
     has ≥ 1 line matching `^\d+\.`.
   - Helper function `check_skill_no_claude_templates <file>`: `grep -r` for
     `.claude/templates/`; asserts no match.
   - Fixture-based `@test` blocks using the fixtures from step 2.
   - Live-skills `@test` block that iterates `plugins/brain-factory/skills/*/SKILL.md`
     (skip if empty).

4. **[impl]** Implement AGENT.md assertions in `meta-lint.bats`:
   - Helper function `check_agent_frontmatter_fields <file>`: asserts `name`, `scope`,
     `tool-profile` non-empty.
   - Helper function `check_agent_routing_table <file>`: `grep -F "Agent Routing Table"`;
     asserts match.
   - Helper function `check_agent_tool_enumeration <file>`: asserts at least one of
     `allowed-tools`, `denied-tools` is non-empty in the body.
   - Fixture-based `@test` blocks.
   - Live-agents `@test` block iterating `plugins/brain-factory/agents/*/AGENT.md`
     (skip if empty).

5. **[green]** Run `bats tests/meta-lint.bats` — all new tests pass.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| `valid-skill/SKILL.md` fixture | All SKILL.md assertions pass | happy-path | BC-2.18.001 |
| `invalid-skill-missing-iron-law/SKILL.md` | Section check FAIL; names missing heading | error | BC-2.18.001 EC-001 |
| `invalid-skill-long-iron-law/SKILL.md` | Iron Law length check FAIL; message includes skill name | error | BC-2.18.001 EC-002 |
| `invalid-skill-hardcoded-path/SKILL.md` | `.claude/templates/` check FAIL; path identified | error | BC-2.18.001 canonical test vector 3 |
| `valid-agent/AGENT.md` fixture | All AGENT.md assertions pass | happy-path | BC-2.18.003 |
| `invalid-agent-no-routing/AGENT.md` | Routing table check FAIL; exact message | error | BC-2.18.003 EC-002 |
| `invalid-agent-empty-tools/AGENT.md` | Tool enumeration check FAIL; empty enumeration flagged | edge-case | BC-2.18.003 EC-001 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-006 | All 26 skills pass meta-lint SKILL.md assertions | `tests/meta-lint.bats` |
| VP-006 | All 14 agents pass meta-lint AGENT.md assertions | `tests/meta-lint.bats` |
| VP-006 | No `.claude/templates/` paths in any SKILL.md | `tests/meta-lint.bats` (grep assertion) |

## Architecture Compliance Rules

From `architecture/subsystems/SS-18-meta-lint-self-audit.md`:

1. `meta-lint.bats` is a STATIC analysis suite. It reads the text of source files; it
   does NOT execute skills, hooks, or agents. Every assertion uses text-matching tools
   (`grep`, `yq`, `wc`, `awk`) — never `bash` or `source`.
2. The meta-lint.bats file is one of the exactly 8 category bats suite files. Adding it
   does NOT increase the category suite count beyond 8 when combined with STORY-023.
   STORY-022 creates `meta-lint.bats`; STORY-023 extends it. The 8-category + per-hook
   completeness gate is verified by BC-2.18.005 (owned by STORY-023).
3. Meta-lint rules MUST NOT be weakened to make a failing fixture pass. If the fixture
   reveals a false positive in the assertion logic, fix the assertion logic (not the
   fixture). The fixture is ground truth for the failing case.
4. Every new helper function in `meta-lint.bats` must be named with a `check_` prefix
   and accept the target file as its first argument. This enables clear error messages
   that name both the assertion and the file.
5. The word-boundary rule for exit detection applies here too: when checking SKILL.md
   body for `exit` (STORY-023 hook surface), use `\bexit\b` not substring match.

**Forbidden dependencies:**
- `meta-lint.bats`: must NOT `source` or call any hook script (static analysis only).
- `meta-lint.bats`: must NOT call `claude` or any LLM API.
- `meta-lint.bats`: must NOT call `shellcheck` on SKILL.md files (SKILL.md is markdown,
  not a bash script; shellcheck is for `.sh` files — STORY-023 applies shellcheck to
  hooks).

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `yq` | 4.x+ | Frontmatter field extraction (`name`, `scope`, etc.) |
| `grep` | POSIX | Section heading detection; substring search |
| `wc` | POSIX | Iron Law length check |
| `awk` | POSIX | Section body extraction |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/tests/meta-lint.bats` | Create | SKILL.md + AGENT.md validation surfaces (extended by STORY-023) |
| `plugins/brain-factory/tests/fixtures/meta-lint/valid-skill/SKILL.md` | Create | Passing SKILL.md fixture |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-skill-missing-iron-law/SKILL.md` | Create | SKILL.md with Iron Law absent |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-skill-hardcoded-path/SKILL.md` | Create | SKILL.md with `.claude/templates/` path |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-skill-long-iron-law/SKILL.md` | Create | SKILL.md with Iron Law > 200 chars |
| `plugins/brain-factory/tests/fixtures/meta-lint/valid-agent/AGENT.md` | Create | Passing AGENT.md fixture |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-agent-no-routing/AGENT.md` | Create | AGENT.md missing routing table reference |
| `plugins/brain-factory/tests/fixtures/meta-lint/invalid-agent-empty-tools/AGENT.md` | Create | AGENT.md with empty tool lists |

Files NOT to modify: any file under `.factory/`, `plugin.json`, `hooks.json.template`,
any prior STORY-NNN.md, any existing bats files.

## Previous Story Intelligence

STORY-001 through STORY-005 produced the plugin scaffold including initial stub
`skills/*/SKILL.md` and `agents/*/AGENT.md` files. Confirm those stubs exist so the
live-skills and live-agents `@test` blocks have something to iterate over. If stubs do
not yet exist (Phase 2 pre-implementation), the live-file test blocks must gracefully
skip (not fail) on an empty directory. Add skip-if-empty guards.

The CLAUDE.md §Meta-Lint Contract section is the authoritative source of truth for the
assertion list. This story's ACs are derived from that section, not invented. Before
implementing any assertion, re-read CLAUDE.md §Meta-Lint Contract to confirm alignment.

N/A for previous-story lessons beyond the above (this is a new test surface, not a
continuation of a prior story in this epic).

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~3,200 |
| SS-18 subsystem design | ~1,500 |
| BC-2.18.001, BC-2.18.003 files | ~2,000 |
| VP-006 file | ~800 |
| CLAUDE.md §Meta-Lint Contract section | ~2,500 |
| Existing bats files (for reference) | ~2,000 |
| **Total** | **~12,000** |

Well within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Hook script validation surface (BC-2.18.002) — STORY-023.
- Cross-cutting validation surface (BC-2.18.004) — STORY-023.
- 8-category + per-hook completeness gate (BC-2.18.005) — STORY-023.
- Actual implementation of any SKILL.md or AGENT.md files — those are Phase 3 (TDD
  implementation stories). This story creates the test harness and fixtures only.

## Anchors

- BC-2.18.001: `behavioral-contracts/ss-18/BC-2.18.001.md`
- BC-2.18.003: `behavioral-contracts/ss-18/BC-2.18.003.md`
- VP-006: `architecture/verification-properties/VP-006-meta-lint-suite.md`
- SS-18: `architecture/subsystems/SS-18-meta-lint-self-audit.md`
- CLAUDE.md §Meta-Lint Contract: authoritative assertion list
