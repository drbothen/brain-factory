---
document_type: subsystem-design
id: SS-18
title: "Meta-Lint and Self-Audit"
level: L3
version: "1.5"
producer: "vsdd-factory:architect"
timestamp: 2026-05-18T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-018
created: 2026-05-15
---

# SS-18: Meta-Lint and Self-Audit

## Responsibility

The factory tests itself. `meta-lint.bats` validates that brain-factory's own SKILL.md, AGENT.md, and hook scripts conform to the contracts those artifacts define. 8 category bats suites plus N per-hook bats files (one per hook script in `hooks/`) cover all hooks (≥ 3 test cases each) and all skills (integration path).

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.18.001 | `meta-lint.bats` validates SKILL.md frontmatter and canonical 6-section structure | P0 |
| BC-2.18.002 | `meta-lint.bats` validates hook scripts: shebang, `set -euo pipefail`, no bare exit, no eval | P0 |
| BC-2.18.003 | `meta-lint.bats` validates AGENT.md scope + tool-profile + routing reference | P0 |
| BC-2.18.004 | `meta-lint.bats` validates cross-cutting: no AI attribution, no `--no-verify`, no hardcoded template paths | P0 |
| BC-2.18.005 | 8 category suites + N per-hook suites cover all hooks and skills (positive + negative + edge) | P0 |

## Interfaces

**Inbound:** `tests/meta-lint.bats` and 7 other category bats suite files plus per-hook bats files; CI matrix; pre-push hook

**Outbound:** pass/fail report; structured bats TAP output

## Key Design

### Test surface organization

The test surface consists of two layers:

**Layer 1 — 8 category suites** aligned to the brief §Test architecture per Source-of-Truth
Precedence (brief is parent spec; SS-18 derives). These suites cover skill-level and
integration-level behavior. (Version cite history for audit: v0.4.15 (original) → v0.4.17
(F-PASS5-I2 update) → v0.4.18 (F-PASS7-I1 — converted to version-agnostic; §Test
architecture content unchanged across v0.4.15..v0.4.18.) → v0.4.19 (F-PASS8-O2 — Clause 2
added in v0.4.19 did not touch §Test architecture; §Test architecture content unchanged
across v0.4.15..v0.4.19.) → v0.4.20 (F-PHASE2-STEP-B-CLOSEOUT-O1 — §Test architecture
rewritten to per-hook .bats convention; `hooks.bats` removed; "9 suites" corrected to "8
category suites + N per-hook suites").)
SS-18 is aligned to brief naming per CLAUDE.md Source-of-Truth Precedence + brain-factory-001
(F-PASS2-I4 decision). Functional coverage is unchanged — the brief names reflect that
ingest and wiki manipulation are skill-level operations, and templates covers GH Action
templates plus plugin lifecycle templates.

1. `tests/meta-lint.bats` — factory self-audit (SKILL.md / AGENT.md / hook script structure)
2. `tests/skills.bats` — SS-02 + SS-03 ingest pipeline, SS-05 wiki layer (lint, rename, wikilink resolution), SS-08 content brief, SS-09 publish, SS-11 knowledge synthesis
3. `tests/templates.bats` — SS-13 GH Action templates: YAML validity, trigger config; SS-14 + SS-15 plugin lifecycle and policies templates
4. `tests/quarantine.bats` — SS-10 quarantine: injection pattern detection
5. `tests/adversary.bats` — SS-07 adversarial review: verdict schema, streak counter
6. `tests/policies.bats` — SS-15 governance: policy-add, registry-validate
7. `tests/upgrade.bats` — SS-14 plugin.json schema, migration idempotency; SS-13 template YAML
8. `tests/integration.bats` — SS-12 lobster: topological sort, headless execution; SS-16 token log; SS-01 brain init (end-to-end skill flows)

**Layer 2 — per-hook bats files** (N files, one per hook script in `plugins/brain-factory/hooks/`). Each hook script `hooks/<hook-name>.sh` has a corresponding `tests/<hook-name>.bats` file containing ≥ 3 `@test` blocks: one positive (clean payload → exit 0), one negative (violation payload → exit 2), one edge (malformed stdin → exit 2 fail-closed). Currently 13 hooks → 13 per-hook bats files. This is the canonical convention per CLAUDE.md TDD Inner Loop Discipline.

meta-lint.bats asserts existence of all 8 category suites AND asserts that every hook script in `hooks/` has a matching `tests/<hook-name>.bats` file containing ≥ 3 `@test` blocks.

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
- Has a corresponding `plugins/brain-factory/tests/<hook-name>.bats` file containing ≥ 3 `@test` blocks (positive + negative + edge case)
- shellcheck exits 0
- shfmt -d produces no diff

**REVERSED 2026-05-18 (F-PHASE2-STEP-B-CLOSEOUT-O1): Per-hook .bats files are CANONICAL per CLAUDE.md TDD Inner Loop Discipline.** The earlier F-PASS1-I8 consolidation into a single `tests/hooks.bats` was a wrong-turn decision that violated CLAUDE.md's stated convention. This section now codifies the per-hook + 8-category test surface organization.

**AGENT.md surface:**
- Frontmatter with `name`, `scope`, `tool-profile`
- Body references Agent Routing Table

**Cross-cutting:**
- No tracked file contains `Co-Authored-By: Claude`
- No tracked file contains `--no-verify`
- No `${CLAUDE_PLUGIN_ROOT}` reference points to a non-existent path

### NFR-020 — ≥ 3 test cases per hook

Each of the N hooks must have ≥ 3 test cases in its own `tests/<hook-name>.bats` file: one positive (clean payload → exit 0), one negative (violation payload → exit 2), and one edge (malformed stdin → exit 2 fail-closed). meta-lint.bats counts `@test` blocks PER PER-HOOK FILE — it opens each `tests/<hook-name>.bats` and counts the `@test` declarations within that file (not by prefix-grep across a shared file).

## Purity Classification

**Pure.** meta-lint.bats operates on the static text of source files — it does not execute the hooks or skills. It is a static analysis suite: given the hook script text, does it contain `set -euo pipefail`? This is fully deterministic.

## Dependencies

- All 18 subsystems: meta-lint validates every SKILL.md, AGENT.md, and hook script they produce
- SS-17 (Event Catalog): catalog completeness check is part of meta-lint.bats

## Test Surface

- `meta-lint.bats` IS the test surface. It runs in CI (blocking) and as part of the pre-push gate.
- Adversarial review independently verifies meta-lint passed (the adversary does not trust the implementer's self-attestation).

## Changelog

### v1.5 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1 — per-hook .bats convention cascaded from brief v0.4.20 + nfr-catalog v0.1.1 + BC-2.18.005 v1.2):**

- **§Test surface organization (formerly "§9 bats suites"):** Section renamed and rewritten. The 8 category suites listed are: `meta-lint.bats`, `skills.bats`, `templates.bats`, `quarantine.bats`, `adversary.bats`, `policies.bats`, `upgrade.bats`, `integration.bats`. The prior entry "2. `tests/hooks.bats` — all 13 hooks..." is REMOVED. Per-hook bats files (Layer 2) are now canonical: each hook script `hooks/<hook-name>.sh` has a corresponding `tests/<hook-name>.bats` with ≥ 3 `@test` blocks. meta-lint.bats asserts existence of all 8 category suites AND every per-hook file.
- **§meta-lint.bats assertions §Hook script surface:** "Has at least one named `@test` block in `tests/hooks.bats` matching the hook's filename" replaced with "Has a corresponding `plugins/brain-factory/tests/<hook-name>.bats` file containing ≥ 3 `@test` blocks (positive + negative + edge case)."
- **§Per-hook test file clarification (F-PASS1-I8 reversal):** The F-PASS1-I8 decision is REVERSED. The earlier claim "creating per-hook bats files would create a 10th+ suite in violation of NFR-019" is now recognized as a wrong-turn decision contradicting CLAUDE.md's TDD Inner Loop Discipline. The reversal paragraph replaces the F-PASS1-I8 clarification.
- **§NFR-020:** Updated from "Each of the 13 hooks must have ≥ 3 test cases in `tests/hooks.bats`" to "Each of the N hooks must have ≥ 3 test cases in its own `tests/<hook-name>.bats` file." Counting mechanism updated: meta-lint counts `@test` blocks PER PER-HOOK FILE, not by `@test "<hook>:"` prefix grep across one shared file.
- **§Responsibility:** Updated from "9 bats suites" to "8 category bats suites plus N per-hook bats files."
- **§BC Inventory:** BC-2.18.005 title updated from "9 bats suites cover 13 hooks..." to "8 category suites + N per-hook suites cover all hooks..."
- **§Interfaces:** Updated Inbound description.

Cross-references: brief v0.4.20 (§Test architecture rewritten); nfr-catalog v0.1.1 (NFR-019 + NFR-020 rewritten); BC-2.18.005 v1.2 (H1 rewritten); user direction 2026-05-18 (CLAUDE.md wins). [audit-trail]

### v1.4 (2026-05-16)

**STRUCTURAL FIX (F-PASS9-I2 — missing Changelog section):** In-file Changelog section
added. Reconstructed from ARCH-INDEX changelog entries for SS-18. Sibling-sweep of all
SS-01..SS-17 confirmed SS-02 also at v1.1+ without a Changelog — both addressed in this
burst. [audit-trail]

### v1.3 (2026-05-16)

**UPDATE (F-PASS8-O2 — audit-range extended):** §9 bats suites version-cite parenthetical
extended from "v0.4.15..v0.4.18" to "v0.4.15..v0.4.19". Brief v0.4.19 added Clause 2 to
the five-file gate; §Test architecture content is unchanged through v0.4.19. [audit-trail]

### v1.2 (2026-05-16)

**STRUCTURAL FIX (F-PASS7-I1 — version cites converted to version-agnostic shorthand):**
SS-18 §9 bats suites narrative version cites converted from version-specific to
version-agnostic form. Audit-trail version history preserved in parenthetical. [audit-trail]

### v1.1 (2026-05-15)

**STRUCTURAL FIX (F-PASS4-C2/I3 — 9-suite roster aligned to brief):** 9 bats suites
roster updated: `ingest.bats` → `skills.bats`, `wiki.bats` → `skills.bats`. Per-hook bats
file discipline clarified: all 13 hooks share `tests/hooks.bats`; creating per-hook bats
files violates NFR-019. [audit-trail]

### v1.0 (2026-05-15)

Original Phase 1c subsystem design — meta-lint and self-audit governance, 9-suite roster,
meta-lint assertion surfaces (SKILL.md, hook scripts, AGENT.md, cross-cutting).
