---
document_type: subsystem-design
id: SS-18
title: "Meta-Lint and Self-Audit"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-018
created: 2026-05-15
---

# SS-18: Meta-Lint and Self-Audit

## Responsibility

The factory tests itself. `meta-lint.bats` validates that brain-factory's own SKILL.md, AGENT.md, and hook scripts conform to the contracts those artifacts define. 9 bats suites cover all 13 hooks (≥ 3 test cases each) and all skills (integration path).

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.18.001 | `meta-lint.bats` validates SKILL.md frontmatter and canonical 6-section structure | P0 |
| BC-2.18.002 | `meta-lint.bats` validates hook scripts: shebang, `set -euo pipefail`, no bare exit, no eval | P0 |
| BC-2.18.003 | `meta-lint.bats` validates AGENT.md scope + tool-profile + routing reference | P0 |
| BC-2.18.004 | `meta-lint.bats` validates cross-cutting: no AI attribution, no `--no-verify`, no hardcoded template paths | P0 |
| BC-2.18.005 | 9 bats suites cover 13 hooks and all skills (positive + negative + edge) | P0 |

## Interfaces

**Inbound:** `tests/meta-lint.bats` and 8 other bats suite files; CI matrix; pre-push hook

**Outbound:** pass/fail report; structured bats TAP output

## Key Design

### 9 bats suites

The 9 bats suites (NFR-019 — exactly 9), aligned to brief v0.4.15 §Test architecture per
Source-of-Truth Precedence (brief is parent spec; SS-18 derives). An earlier draft of this
section used `ingest.bats` and `wiki.bats` (more functional naming for SS-02/03 and SS-05);
brief v0.4.15 commits to `skills.bats` and `templates.bats` as the broader category names.
SS-18 is aligned to brief naming per CLAUDE.md Source-of-Truth Precedence + brain-factory-001
(F-PASS2-I4 decision). Functional coverage is unchanged — the brief names reflect that
ingest and wiki manipulation are skill-level operations, and templates covers GH Action
templates plus plugin lifecycle templates.

1. `tests/meta-lint.bats` — factory self-audit (SKILL.md / AGENT.md / hook script structure)
2. `tests/hooks.bats` — all 13 hooks: exit codes, stdin fixtures, stderr JSONL, stdout verdict
3. `tests/skills.bats` — SS-02 + SS-03 ingest pipeline, SS-05 wiki layer (lint, rename, wikilink resolution), SS-08 content brief, SS-09 publish, SS-11 knowledge synthesis
4. `tests/templates.bats` — SS-13 GH Action templates: YAML validity, trigger config; SS-14 + SS-15 plugin lifecycle and policies templates
5. `tests/quarantine.bats` — SS-10 quarantine: injection pattern detection
6. `tests/adversary.bats` — SS-07 adversarial review: verdict schema, streak counter
7. `tests/policies.bats` — SS-15 governance: policy-add, registry-validate
8. `tests/upgrade.bats` — SS-14 plugin.json schema, migration idempotency; SS-13 template YAML
9. `tests/integration.bats` — SS-12 lobster: topological sort, headless execution; SS-16 token log; SS-01 brain init (end-to-end skill flows)

### meta-lint.bats assertions (BC-2.18.001..BC-2.18.004)

**SKILL.md surface:**
- Frontmatter present; `name`, `description`, `argument-hint`, `allowed-tools` fields non-empty
- `name` matches directory name
- Body has 6-section structure in order: Iron Law, Red Flags, Announce-at-Start, Procedure, Quality Bar, Output
- Iron Law section ≤ 200 chars
- Red Flags section has ≥ 1 bullet
- Procedure section has ≥ 1 numbered item
- No `.claude/templates/` hardcoded path

**Hook script surface:**
- First line is `#!/usr/bin/env bash`
- `set -euo pipefail` within first 10 lines
- No bare `exit` (every `exit` followed by 0, 1, or 2)
- No `eval`
- Has at least one named `@test` block in `tests/hooks.bats` matching the hook's filename (e.g., `@test "quarantine-fetch.sh: ..."`) — all 13 hooks share the single `tests/hooks.bats` file per NFR-019; per-hook `.bats` files are NOT created
- shellcheck exits 0
- shfmt -d produces no diff

**Per-hook test file clarification (F-PASS1-I8 decision):** The canonical test roster is exactly 9 bats files (NFR-019). All hook tests live in `tests/hooks.bats`. The meta-lint assertion is not "does a per-hook `.bats` file exist?" but "does `tests/hooks.bats` contain ≥ 3 `@test` blocks prefixed with the hook's filename?". Creating per-hook bats files would create a 10th+ suite in violation of NFR-019.

**AGENT.md surface:**
- Frontmatter with `name`, `scope`, `tool-profile`
- Body references Agent Routing Table

**Cross-cutting:**
- No tracked file contains `Co-Authored-By: Claude`
- No tracked file contains `--no-verify`
- No `${CLAUDE_PLUGIN_ROOT}` reference points to a non-existent path

### NFR-020 — ≥ 3 test cases per hook

Each of the 13 hooks must have ≥ 3 test cases in `tests/hooks.bats`: one positive (clean payload → exit 0), one negative (violation payload → exit 2), and one edge (malformed stdin → exit 2 fail-closed). meta-lint.bats counts test cases per hook by grepping `@test "quarantine-fetch.sh:"` style prefixes.

## Purity Classification

**Pure.** meta-lint.bats operates on the static text of source files — it does not execute the hooks or skills. It is a static analysis suite: given the hook script text, does it contain `set -euo pipefail`? This is fully deterministic.

## Dependencies

- All 18 subsystems: meta-lint validates every SKILL.md, AGENT.md, and hook script they produce
- SS-17 (Event Catalog): catalog completeness check is part of meta-lint.bats

## Test Surface

- `meta-lint.bats` IS the test surface. It runs in CI (blocking) and as part of the pre-push gate.
- Adversarial review independently verifies meta-lint passed (the adversary does not trust the implementer's self-attestation).
