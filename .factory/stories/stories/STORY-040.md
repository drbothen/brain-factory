---
artifact_type: story
story_id: STORY-040
epic_id: EPIC-09
title: "Adversarial review core dispatch — cognitive diversity gate and four-agent validation"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-07]
behavioral_contracts: [BC-2.07.001, BC-2.07.002]
vps: [VP-010]
dependencies: [STORY-001, STORY-002]
blocks: [STORY-041]
inputs:
  - architecture/subsystems/SS-07-adversarial-review.md
  - behavioral-contracts/ss-07/BC-2.07.001.md
  - behavioral-contracts/ss-07/BC-2.07.002.md
  - architecture/verification-properties/VP-010-adversarial-cascade-convergence.md
input-hash: ""
# BC status: BC-2.07.001 + BC-2.07.002 assigned; status=draft per S-7.01
# Priority: P0 — required for Phase 1 exit gate (adversary-review PASS on fresh ingest).
#   8 points: the `/brain:adversary-review` skill dispatches a multi-agent protocol
#   (Opus adversary + 4 validation agents), enforces model-family constraint, logs model
#   pairing, and aggregates all four agent finding lists. The skill body is the heaviest
#   part of SS-07; the 3-CLEAN streak state machine and multi-pass revision loop are
#   separate (STORY-041). 8 points reflects the multi-agent dispatch wiring and
#   cognitive-diversity enforcement.
# Dependency rationale:
#   STORY-001: plugin.json and skill registration must exist before adversary skill registers.
#   STORY-002: hook chain (PostToolUse) registers adversary skill into the manifest.
# Subsystem anchor:
#   SS-07 owns BC-2.07.001 and BC-2.07.002 per SS-07-adversarial-review.md BC Inventory.
#   Both BCs are P0 priority per that inventory — critical path for Phase 1 exit gate.
---

# STORY-040: Adversarial review core dispatch — cognitive diversity gate and four-agent validation

## Goal

Deliver the `/brain:adversary-review <path>` skill body with two of its four behavioral
contracts: (1) the cognitive-diversity gate that blocks same-model adversary dispatch
(BC-2.07.001), and (2) the dispatch of all four wclaude validation agents with aggregated
finding collection (BC-2.07.002). This is the P0 foundation of SS-07; without it the
Phase 1 exit gate criterion ("adversary-review PASS on a fresh ingest") cannot be met.

## User Value

As a content operator, I want `/brain:adversary-review <path>` to run four independent
validation agents (voice, structure, frontmatter, platform compliance) in a different
model family from the producing agent, so that cognitive-diversity quality review is
enforced before content ships.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.07.001 | `/brain:adversary-review` runs in a different model family than the producer agent | P0 |
| BC-2.07.002 | `/brain:adversary-review` dispatches all four wclaude validation agents | P0 |

## Acceptance Criteria

### Cognitive diversity enforcement (BC-2.07.001)

**AC-001** — When `/brain:adversary-review <path>` is invoked and `.brain/policies.yaml`
specifies `adversary_model: claude-sonnet-4-6` while the producer model is detected as
`claude-opus-4-5`, the adversary agent is dispatched with `claude-sonnet-4-6`. The
model pairing is logged in the review output as:
`{"model_pairing": {"producer": "claude-opus-4-5", "adversary": "claude-sonnet-4-6"}}`.
(traces to BC-2.07.001 postcondition 1; postcondition 3)

**AC-002** — When the producer model cannot be determined (cold start / no metadata in
the artifact's frontmatter), the skill defaults to Sonnet as the adversary model and
logs `{"model_pairing": {"producer": "unknown", "adversary": "claude-sonnet-4-6",
"fallback_applied": true}}`.
(traces to BC-2.07.001 postcondition 2; edge case EC-001)

**AC-003** — When `.brain/policies.yaml` configures the same model for both producer
and adversary (e.g., both `claude-sonnet-4-6`), the skill exits 2 with error
`E-ADVERSARY-001: "Adversary model must differ from producer model."`. No review is
conducted.
(traces to BC-2.07.001 invariant 2; edge case EC-002)

**AC-004** — Opus (`claude-opus-4-*`) and Sonnet (`claude-sonnet-4-*`) are treated as
different model families. The family check compares the model-family prefix
(e.g., `claude-opus` vs `claude-sonnet`) — not the full model ID. A bats fixture test
exercises a `claude-opus-4-5` / `claude-sonnet-4-6` pairing and asserts `family_mismatch: true`.
(traces to BC-2.07.001 invariant 1)

### Four-agent dispatch (BC-2.07.002)

**AC-005** — When `/brain:adversary-review <path>` is invoked with a valid markdown
file and all four validation agents are registered in the plugin manifest, all four
agents are dispatched: `brain:frontmatter-validator`, `brain:voice-reviewer`,
`brain:structure-reviewer`, `brain:platform-reviewer`. Each agent receives the artifact
content and returns a structured finding list.
(traces to BC-2.07.002 postcondition 1; postcondition 2)

**AC-006** — The consolidated result JSON has the form:
```json
{
  "verdict": "PASS",
  "agents": {
    "frontmatter_validator": {"verdict": "PASS", "findings": []},
    "voice_reviewer":        {"verdict": "PASS", "findings": []},
    "structure_reviewer":    {"verdict": "PASS", "findings": []},
    "platform_reviewer":     {"verdict": "PASS", "findings": []}
  },
  "overall_issues": []
}
```
All four agent results appear in `agents`; the consolidated `overall_issues` array
aggregates all findings from all four agents.
(traces to BC-2.07.002 postcondition 3)

**AC-007** — If any single agent returns a FAIL verdict, the overall verdict field is
`"FAIL"`. A bats test uses a mock adversary response where
`platform_reviewer.verdict = "FAIL"` and asserts the overall verdict is `"FAIL"`.
All four agents still appear in the `agents` object (no short-circuit on first fail).
(traces to BC-2.07.002 postcondition 4; invariant 1)

**AC-008** — The skill exits 0 when overall verdict is `"PASS"`; exits 1 when overall
verdict is `"FAIL"`.
(traces to BC-2.07.002 postcondition 5)

**AC-009** — All four agents run in the adversary model family (not the producer model
family), consistent with AC-001.
(traces to BC-2.07.002 invariant 2)

**AC-010** — When one agent errors (e.g., network timeout simulated in bats with a mock
that exits non-zero), the overall verdict is `"FAIL"` with an `error` field on the
failing agent's result. The other three agents' results are still reported.
(traces to BC-2.07.002 edge case EC-001)

**AC-011** — When the artifact has no frontmatter (EC-002), the
`brain:frontmatter-validator` agent reports a missing-frontmatter finding and returns
`{"verdict": "FAIL", "findings": [{"severity": "CRITICAL", "description":
"No frontmatter block found"}]}`. The overall verdict is `"FAIL"`.
(traces to BC-2.07.002 edge case EC-002)

## Tasks

1. **[failing tests — Red Gate]** Add failing `@test` blocks to
   `plugins/brain-factory/tests/adversary.bats`:

   Model-diversity (BC-2.07.001):
   - `"adversary-review: Opus/Sonnet pairing → family_mismatch: true (BC-2.07.001)"`.
   - `"adversary-review: unknown producer → Sonnet default applied (BC-2.07.001 EC-001)"`.
   - `"adversary-review: same-model config → E-ADVERSARY-001; exit 2 (BC-2.07.001 EC-002)"`.

   Four-agent dispatch (BC-2.07.002):
   - `"adversary-review: all 4 agents dispatched; consolidated JSON schema valid (BC-2.07.002)"`.
   - `"adversary-review: any agent FAIL → overall FAIL; no short-circuit (BC-2.07.002)"`.
   - `"adversary-review: exit 0 on PASS; exit 1 on FAIL"`.
   - `"adversary-review: agent error → overall FAIL; others still reported (EC-001)"`.
   - `"adversary-review: no frontmatter → frontmatter-validator FAIL (EC-002)"`.

   Run bats — confirm all 8 tests fail (Red Gate confirmed).

2. **[stub]** Create
   `plugins/brain-factory/skills/adversary-review/SKILL.md` with required frontmatter
   (`name`, `description`, `argument-hint`, `allowed-tools`), canonical 6-section
   structure (Iron Law / Red Flags / Announce-at-Start / Procedure / Quality Bar /
   Output). Body: stub comments only — failing tests first.

3. **[stub — validation agents]** Create stub AGENT.md files for:
   - `plugins/brain-factory/agents/frontmatter-validator/AGENT.md`
   - `plugins/brain-factory/agents/voice-reviewer/AGENT.md`
   - `plugins/brain-factory/agents/structure-reviewer/AGENT.md`
   - `plugins/brain-factory/agents/platform-reviewer/AGENT.md`

   Each stub must declare scope, tool-profile, and link to the Agent Routing Table per
   CLAUDE.md §Agent contract. Bodies: stub comments only — agents implemented in
   STORY-041 when the verdict schema is finalized.

4. **[impl — model-family comparator]** Implement the family-comparator pure function
   in `plugins/brain-factory/skills/adversary-review/lib/model-family.sh`:
   - Input: two model IDs (producer, adversary).
   - Output: `{"family_mismatch": true|false, "producer_family": "...",
     "adversary_family": "..."}` on stdout.
   - Families: `claude-opus` matches `claude-opus-*`; `claude-sonnet` matches
     `claude-sonnet-*`.
   - On same family: emit `{"family_mismatch": false}`, exit 2 (block).
   - On unknown producer: default adversary to Sonnet, `"fallback_applied": true`.
   Make bats model-diversity tests green.

5. **[impl — four-agent dispatcher]** Implement the dispatch loop in
   `plugins/brain-factory/skills/adversary-review/run.sh`:
   - Read `adversary_model` from `.brain/policies.yaml` (via `yq`).
   - Check model family via `model-family.sh`; exit 2 on E-ADVERSARY-001.
   - Invoke each of the four validation agents (mock via fixture scripts in bats; real
     Agent tool invocations in the skill body) and collect structured finding JSON.
   - Aggregate into consolidated result JSON.
   - Exit 0 on PASS; exit 1 on FAIL.
   Make all 8 bats tests green.

6. **[green]** Run `bats plugins/brain-factory/tests/adversary.bats`. All 8 tests pass.
   Run `shellcheck` + `shfmt -d -i 2` on all new/modified `.sh` files — zero findings.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Opus producer + Sonnet adversary config | `family_mismatch: true`; review proceeds | happy-path | BC-2.07.001 canonical test vector 1 |
| Same-model config (both Sonnet) | E-ADVERSARY-001; exit 2 | error | BC-2.07.001 canonical test vector 2 |
| Unknown producer model | Sonnet default applied; `fallback_applied: true` | edge-case | BC-2.07.001 EC-001 |
| High-quality article, all 4 agents PASS | `{"verdict": "PASS"}`; exit 0 | happy-path | BC-2.07.002 canonical test vector 1 |
| Article with LinkedIn-incompatible length | platform_reviewer FAIL; overall FAIL; exit 1 | error | BC-2.07.002 canonical test vector 2 |
| One agent network error | overall FAIL; error noted; other 3 agents reported | edge-case | BC-2.07.002 EC-001 |
| Artifact with no frontmatter | frontmatter-validator FAIL; overall FAIL | edge-case | BC-2.07.002 EC-002 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-010 | Same-model adversary blocked | `tests/adversary.bats` — `E-ADVERSARY-001 exit 2` |
| VP-010 | Default pairing applied when producer unknown | `tests/adversary.bats` — `fallback_applied` |
| VP-010 | All 4 agents dispatched; return results | `tests/adversary.bats` — schema validation |
| VP-010 | Any agent FAIL → overall FAIL | `tests/adversary.bats` — no-short-circuit test |

## Architecture Compliance Rules

From `architecture/subsystems/SS-07-adversarial-review.md`:

1. The adversary agent must run in a fresh Agent context (no conversation history shared
   with the producer). This is enforced via the Agent tool invocation pattern — each
   adversary dispatch creates a new subagent thread, never reusing the producer's context.

2. Structural finding-severity tiers are deterministic and bats-testable with fixture
   finding lists: CRITICAL (blocks shipment), IMPORTANT (should fix), SUGGESTION
   (optional), OBSERVATION (informational). Any code classifying findings must use only
   these four tiers — no additional tiers.

3. All four validation agents ALWAYS run — no short-circuit on first FAIL (BC-2.07.002
   invariant 1). An implementation that returns early after the first failing agent is
   a P0 behavioral contract violation.

4. The `model-family.sh` comparator is a **pure function** (no file I/O, no network,
   no side effects) and must be placed in `skills/adversary-review/lib/`. Pure functions
   are bats-testable with `run echo "..." | bash model-family.sh` patterns. Do NOT inline
   the family comparison logic inside `run.sh` — the comparator must be independently
   testable.

5. `.brain/policies.yaml` is the single source of truth for `adversary_model` and
   `producer_model` configuration. The skill MUST read from this file via `yq` — never
   from hardcoded defaults in `run.sh`. The hardcoded Sonnet fallback is only for the
   cold-start case when the producer model cannot be determined from artifact frontmatter.

**Forbidden dependencies:**
- No hardcoded model IDs in `run.sh` (use `yq` to read from policies.yaml).
- `model-family.sh` must NOT read from `.brain/` — it is a pure function taking two
  string arguments.
- No `eval` anywhere in hook or skill scripts (project-wide ban, CLAUDE.md §Conventions).
- `run.sh` must NOT directly invoke `/usr/bin/time` — memory measurement is SS-16 scope
  (STORY-039), not SS-07.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 3.2+ | macOS compat |
| `jq` | 1.6+ | JSON consolidation |
| `yq` | 4.x+ | policies.yaml reads |
| `bats-core` | 1.10+ | CLAUDE.md §Build & Test |
| `shellcheck` | 0.8+ | CLAUDE.md §Conventions |
| `shfmt` | 3.x+ | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/adversary-review/SKILL.md` | Create | Skill definition with canonical 6-section structure |
| `plugins/brain-factory/skills/adversary-review/run.sh` | Create | Dispatch loop — reads policies.yaml; invokes 4 agents; aggregates |
| `plugins/brain-factory/skills/adversary-review/lib/model-family.sh` | Create | Pure function — model-family comparator |
| `plugins/brain-factory/agents/frontmatter-validator/AGENT.md` | Create | Stub agent definition |
| `plugins/brain-factory/agents/voice-reviewer/AGENT.md` | Create | Stub agent definition |
| `plugins/brain-factory/agents/structure-reviewer/AGENT.md` | Create | Stub agent definition |
| `plugins/brain-factory/agents/platform-reviewer/AGENT.md` | Create | Stub agent definition |
| `plugins/brain-factory/tests/adversary.bats` | Create | 8 failing tests (Red Gate), then green |
| `plugins/brain-factory/tests/fixtures/good-brief.md` | Create | Known-good fixture for PASS testing |
| `plugins/brain-factory/tests/fixtures/bad-brief.md` | Create | Known-bad fixture (voice violations) for FAIL testing |

Files NOT to modify: any `.factory/` artifact, any existing hook script, `plugin.json`,
any prior story file.

## Previous Story Intelligence

N/A — first story in EPIC-09.

STORY-001 and STORY-002 (EPIC-01) established the plugin manifest and hook registration
patterns. The adversary skill must register in `plugin.json` under the `skills` array
using the same pattern established there. Check STORY-001 for the canonical skill
registration format before writing `run.sh`.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,800 |
| SS-07 subsystem design | ~700 |
| BC-2.07.001 file | ~600 |
| BC-2.07.002 file | ~600 |
| VP-010 file | ~600 |
| STORY-001 (plugin.json pattern context) | ~500 |
| `.brain/policies.yaml` template (10 baseline policies) | ~400 |
| **Total** | **~8,200** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Multi-pass writescore revision loop — STORY-041 scope (BC-2.07.003).
- Structured JSON verdict schema definition — STORY-041 scope (BC-2.07.004).
- Streak counter state machine in `.brain/STATE.md` — STORY-041 scope.
- Full validation agent implementation (voice, structure, platform logic) — STORY-041
  scope. This story creates stub AGENT.md files only.
- Governance policies initialization — STORY-042 scope (BC-2.15.001).
- Plugin tarball packaging — no explicit BC in this epic; covered by meta-lint (VP-006).

## Anchors

- BC-2.07.001: `behavioral-contracts/ss-07/BC-2.07.001.md`
- BC-2.07.002: `behavioral-contracts/ss-07/BC-2.07.002.md`
- VP-010: `architecture/verification-properties/VP-010-adversarial-cascade-convergence.md`
- SS-07: `architecture/subsystems/SS-07-adversarial-review.md`
- STORY-001: `stories/stories/STORY-001.md` (plugin manifest — prerequisite)
- STORY-002: `stories/stories/STORY-002.md` (hook chain — prerequisite)
