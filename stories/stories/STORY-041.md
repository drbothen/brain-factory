---
artifact_type: story
story_id: STORY-041
epic_id: EPIC-09
title: "Adversarial review structured verdict, streak counter, and multi-pass writescore revision loop"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 8
priority: P0
subsystems: [SS-07]
behavioral_contracts: [BC-2.07.003, BC-2.07.004]
vps: [VP-010]
dependencies: [STORY-040]
blocks: [STORY-042]
inputs:
  - architecture/subsystems/SS-07-adversarial-review.md
  - behavioral-contracts/ss-07/BC-2.07.003.md
  - behavioral-contracts/ss-07/BC-2.07.004.md
  - architecture/verification-properties/VP-010-adversarial-cascade-convergence.md
input-hash: ""
# BC status: BC-2.07.003 + BC-2.07.004 assigned; status=draft per S-7.01
# Priority: P0 — BC-2.07.004 (structured verdict) is P0 per SS-07 BC Inventory; BC-2.07.003
#   (revision loop) is P1 but is grouped here because it builds on the same verdict-schema
#   infrastructure established by BC-2.07.004. Grouping avoids two sequential single-BC
#   stories with high setup overhead.
#   8 points: verdict JSON schema, streak counter state machine in STATE.md, and bounded
#   revision loop together constitute substantial implementation surface. The revision loop
#   alone has 4 invariants and 3 edge cases.
# Dependency rationale:
#   STORY-040: run.sh dispatch loop and 4 agent stubs must exist before the verdict schema
#     and revision loop can be wired in. STORY-041 extends run.sh, not replaces it.
# Subsystem anchor:
#   SS-07 owns BC-2.07.003 and BC-2.07.004 per SS-07-adversarial-review.md BC Inventory.
---

# STORY-041: Adversarial review structured verdict, streak counter, and multi-pass writescore revision loop

## Goal

Complete the `/brain:adversary-review` skill by adding the structured pass/fail verdict
schema (BC-2.07.004), the 3-CLEAN streak counter in `.brain/STATE.md` (required by
VP-010), and the bounded multi-pass writescore revision loop (BC-2.07.003). After this
story, the adversary-review skill is fully functional and the Phase 1 exit gate
criterion (three consecutive PASS verdicts) can be demonstrated.

## User Value

As a content operator, I want `/brain:adversary-review <path>` to return a structured
JSON verdict I can programmatically consume, track my three-CLEAN streak in brain state,
and optionally run a bounded revision loop so content converges to PASS without manual
re-invocation loops.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.07.003 | `/brain:adversary-review` implements multi-pass writescore revision loop | P1 |
| BC-2.07.004 | `/brain:adversary-review` returns structured pass/fail verdict with finding list | P0 |

## Acceptance Criteria

### Structured verdict schema (BC-2.07.004)

**AC-001** — Every invocation of `/brain:adversary-review <path>` returns a structured
JSON verdict on stdout with the exact schema:
```json
{
  "verdict": "PASS",
  "path": "<path>",
  "iterations": 1,
  "agents": {
    "frontmatter_validator": {"verdict": "PASS", "findings": []},
    "voice_reviewer":        {"verdict": "PASS", "findings": []},
    "structure_reviewer":    {"verdict": "PASS", "findings": []},
    "platform_reviewer":     {"verdict": "PASS", "findings": []}
  },
  "findings": [],
  "overall_score": 100
}
```
The `verdict` field is always present. `findings` is always an array (empty on PASS).
`path` reflects the argument passed to the skill.
(traces to BC-2.07.004 postcondition 1; invariant 1; invariant 2)

**AC-002** — Finding entries have the schema:
```json
{"agent": "<agent-name>", "severity": "CRITICAL|IMPORTANT|SUGGESTION|OBSERVATION",
 "description": "<text>"}
```
Valid severities are exactly: CRITICAL, IMPORTANT, SUGGESTION, OBSERVATION. A bats
fixture test validates that a mock FAIL verdict containing all four severity tiers
passes `jq` schema validation.
(traces to BC-2.07.004 invariant 3)

**AC-003** — When the overall verdict is `"PASS"`, the skill exits 0. When `"FAIL"`,
exits 1.
(traces to BC-2.07.004 postcondition 2; BC-2.07.002 postcondition 5 — shared invariant)

**AC-004** — A clean PASS (no findings) returns `{"verdict": "PASS", "findings": [],
"iterations": 1}` and exits 0.
(traces to BC-2.07.004 edge case EC-001)

### Multi-pass writescore revision loop (BC-2.07.003)

**AC-005** — When the initial adversary pass returns FAIL and the artifact is not a
read-only source file (checked via `manifest.json` `layer` field), the skill enters the
revision loop: proposes revisions, applies them (requires operator `[y/N]` confirmation
prompt in the skill's interactive mode), then re-runs all four validation agents.
(traces to BC-2.07.003 precondition 1; precondition 2)

**AC-006** — The maximum iteration count is read from `.brain/policies.yaml` field
`max_adversary_iterations` (default: 3). The bats test uses a mock policies.yaml with
`max_adversary_iterations: 2` and verifies the loop stops after 2 iterations without
passing.
(traces to BC-2.07.003 precondition 3; invariant 2)

**AC-007** — When an artifact passes within the iteration limit (pass on second
iteration), the skill exits 0 with `"verdict": "PASS"` and `"iterations": 2`. Each
iteration's result is included in the `iterations_log` field.
(traces to BC-2.07.003 postcondition 1)

**AC-008** — When maximum iterations are reached and the artifact still fails, the skill
exits 1 with `"verdict": "FAIL"` and all iteration results included in `iterations_log`.
(traces to BC-2.07.003 postcondition 2; edge case EC-002)

**AC-009** — Each revision pass runs all four validation agents — no partial re-runs
(BC-2.07.003 invariant 1). A bats test exercises a two-iteration loop with mock agents
and asserts that `iterations_log[1].agents` and `iterations_log[2].agents` each contain
results from all four agents.
(traces to BC-2.07.003 invariant 1)

**AC-010** — Each iteration's writescore is recorded as `overall_score` in that
iteration's log entry. A bats fixture test asserts `iterations_log[0].overall_score`
is a non-negative integer.
(traces to BC-2.07.003 postcondition 3)

**AC-011** — When the artifact passes on the first pass (no revision loop needed), the
`iterations_log` contains exactly one entry and the skill exits 0 immediately (no
loop entered).
(traces to BC-2.07.003 edge case EC-001)

### Streak counter state machine (VP-010)

**AC-012** — After a `"PASS"` verdict, the adversary streak counter in
`.brain/STATE.md` field `adversary_streak` increments by 1. After three consecutive
PASS verdicts, `adversary_streak` reaches 3 and the skill logs `"converged": true` in
the verdict JSON.
(traces to VP-010 — streak counter; BC-2.07.004 postcondition 1 `overall_score` field)

**AC-013** — After a `"FAIL"` verdict, `adversary_streak` resets to 0 in
`.brain/STATE.md`. A bats test simulates a PASS, PASS, FAIL sequence and asserts
`adversary_streak = 0` after the FAIL.
(traces to VP-010 — streak resets; BC-2.07.004 invariant 1)

**AC-014** — A bats structural test reads a mock adversary verdict JSON and asserts:
`(.verdict and (.streak | type == "number") and (.findings | type == "array"))` — the
schema is valid per VP-010 structural verification pattern.
(validates VP-010 structural bats verification method)

## Tasks

1. **[failing tests — Red Gate]** Extend
   `plugins/brain-factory/tests/adversary.bats` with failing tests:

   Verdict schema (BC-2.07.004):
   - `"adversary-review: structured verdict JSON schema valid (BC-2.07.004)"`.
   - `"adversary-review: finding severity tiers valid (BC-2.07.004 invariant 3)"`.
   - `"adversary-review: clean PASS → findings empty; exit 0 (BC-2.07.004 EC-001)"`.

   Revision loop (BC-2.07.003):
   - `"adversary-review: revision loop bounded by max_iterations from policies.yaml"`.
   - `"adversary-review: pass on 2nd iteration → iterations=2; exit 0 (BC-2.07.003)"`.
   - `"adversary-review: max iterations reached → FAIL; all iterations in log (EC-002)"`.
   - `"adversary-review: each revision pass runs all 4 agents (BC-2.07.003 invariant 1)"`.
   - `"adversary-review: first-pass pass → 1 iteration; loop not entered (EC-001)"`.

   Streak counter (VP-010):
   - `"adversary-review: streak counter increments on PASS (VP-010)"`.
   - `"adversary-review: streak resets to 0 on FAIL (VP-010)"`.
   - `"adversary-review: streak counter in STATE.md after 3 passes = 3 (VP-010)"`.
   - `"adversary-review: structured verdict JSON schema — VP-010 structural check"`.

   Run bats on all adversary tests — confirm all 12 new tests fail (Red Gate confirmed).
   The 8 tests from STORY-040 should remain green.

2. **[impl — verdict schema emitter]** Extend `run.sh` to emit the structured verdict
   JSON with all required fields: `verdict`, `path`, `iterations`, `agents`,
   `findings`, `overall_score`, `converged` (when streak ≥ 3).

3. **[impl — streak state machine]** Implement streak counter logic in
   `skills/adversary-review/lib/streak.sh`:
   - Read `adversary_streak` from `.brain/STATE.md` via `yq`.
   - On PASS: increment; write back.
   - On FAIL: reset to 0; write back.
   - On `adversary_streak ≥ 3`: emit `"converged": true` in verdict JSON.
   Make streak counter tests green.

4. **[impl — revision loop]** Implement the bounded revision loop in `run.sh`:
   - Read `max_adversary_iterations` from `.brain/policies.yaml` (default: 3).
   - Loop: if verdict is FAIL and iteration count < max, propose revisions and
     re-run all four agents.
   - Track each iteration's score and agent results in `iterations_log`.
   - On PASS or max iterations reached: emit final verdict JSON; exit.
   Make revision loop tests green.

5. **[impl — full validation agent stubs → implementation]** Implement the four
   validation agent AGENT.md bodies (stubs created in STORY-040) with their actual
   review rubrics per SS-07:
   - `frontmatter-validator`: checks title, tags, status, publication_date schema.
   - `voice-reviewer`: checks voice-avoid-list compliance; tone consistency.
   - `structure-reviewer`: checks ONE THING / PROOF / TRANSFORMATION format.
   - `platform-reviewer`: checks LinkedIn character limits, link formatting.
   Each AGENT.md must follow CLAUDE.md §Agent contract (scope + tool-profile +
   routing table reference).

6. **[green]** Run `bats plugins/brain-factory/tests/adversary.bats`. All 20 tests
   (8 from STORY-040 + 12 new) pass. `shellcheck` + `shfmt -d -i 2` on all new/
   modified scripts — zero findings.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Clean artifact, first pass | `{"verdict": "PASS", "findings": [], "iterations": 1}`; exit 0 | happy-path | BC-2.07.004 EC-001 |
| Artifact with 2 CRITICAL findings | `{"verdict": "FAIL", "findings": [{"severity": "CRITICAL", ...}, ...]}`; exit 1 | error | BC-2.07.004 canonical test vector 2 |
| Fails initially; passes after 1 revision | `{"iterations": 2, "verdict": "PASS"}`; exit 0 | happy-path | BC-2.07.003 canonical test vector 1 |
| Fails all 3 iterations | `{"iterations": 3, "verdict": "FAIL"}`; all iteration data; exit 1 | edge-case | BC-2.07.003 canonical test vector 2 |
| Three consecutive PASSes | `adversary_streak = 3`; `"converged": true` in verdict | happy-path | VP-010 |
| PASS, PASS, FAIL sequence | `adversary_streak = 0` after FAIL | edge-case | VP-010 streak reset |
| `max_adversary_iterations: 2` in policies | Loop stops at 2 iterations | edge-case | BC-2.07.003 invariant 2 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| VP-010 | Revision loop bounded by max_iterations | `tests/adversary.bats` — `"revision loop bounded"` |
| VP-010 | Each pass re-runs all 4 agents | `tests/adversary.bats` — `"4 agents per pass"` |
| VP-010 | Streak counter increments on PASS, resets on FAIL | `tests/adversary.bats` — streak tests |
| VP-010 | Streak reaches 3 → converged | `tests/adversary.bats` — `"streak = 3 after 3 passes"` |
| VP-010 | Structural verdict JSON schema valid | `tests/adversary.bats` — `jq` schema check |
| VP-010 | Known-bad artifact → verdict: fail | `tests/adversary.bats` — bad-brief fixture |

## Architecture Compliance Rules

From `architecture/subsystems/SS-07-adversarial-review.md`:

1. The streak counter is stored in `.brain/STATE.md` field `adversary_streak`. This
   is a brain-vault state field, not a plugin-level field. The `streak.sh` helper
   MUST use `yq eval '.adversary_streak = N' -i .brain/STATE.md` for writes.
   Do NOT store streak in any plugin-owned config — it is vault state.

2. The multi-pass writescore loop is implemented in the `/brain:adversary-review`
   skill body (run.sh), NOT as a separate hook. SS-07 Key Design explicitly calls
   this out: "The writescore loop is implemented in the `/brain:adversary-review`
   skill body."

3. The revision loop requires operator confirmation before applying revisions
   (precondition: artifact is editable and not read-only source). The `[y/N]` prompt
   in the skill's interactive mode satisfies BC-2.07.003 precondition 2. In bats testing,
   simulate `y` confirmation via stdin fixture.

4. The v0.1 release (initial phase): the revision loop is a P1 feature per
   SS-07 Key Design ("the initial release (v0.1) returns the verdict and findings without
   the automated revision loop"). However, the BC assigns this story full P0 delivery
   scope. The bats tests must cover the revision loop regardless of which version ships
   it — the story delivers the complete functionality.

5. `streak.sh` is a **pure-with-state** function: pure in its logic (given streak N
   and verdict V, return N+1 or 0) but effectful in its STATE.md write. Place the
   pure increment/reset logic in a separate testable function; test it with fixture
   STATE.md files.

**Forbidden dependencies:**
- Do NOT write streak counter to any file other than `.brain/STATE.md`.
- Do NOT short-circuit the revision loop at < max_iterations if FAIL is encountered —
  the loop must always run until PASS or max_iterations is exhausted.
- Do NOT invent additional severity tiers beyond CRITICAL/IMPORTANT/SUGGESTION/OBSERVATION.
  Any new tier requires a BC amendment by the product-owner.
- `run.sh` must NOT call `exit` without explicit code 0 or 1 (BC-2.07.004 postcondition 2).

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions |
| `jq` | 1.7+ (latest: 1.8.1) | Verdict JSON schema validation |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | `.brain/STATE.md` streak reads/writes; policies.yaml max_iterations. **Ubuntu note:** `apt install yq` installs the WRONG tool (kislyuk/yq, Python-based). Use `snap install yq`. |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/adversary-review/run.sh` | Modify | Add verdict schema emitter, streak wiring, revision loop |
| `plugins/brain-factory/skills/adversary-review/lib/streak.sh` | Create | Streak counter logic — increment/reset; STATE.md writes |
| `plugins/brain-factory/agents/frontmatter-validator/AGENT.md` | Modify | Complete review rubric (stubs from STORY-040) |
| `plugins/brain-factory/agents/voice-reviewer/AGENT.md` | Modify | Complete review rubric |
| `plugins/brain-factory/agents/structure-reviewer/AGENT.md` | Modify | Complete review rubric |
| `plugins/brain-factory/agents/platform-reviewer/AGENT.md` | Modify | Complete review rubric |
| `plugins/brain-factory/tests/adversary.bats` | Modify | Add 12 new failing tests (Red Gate), then green |

Files NOT to modify: any `.factory/` artifact, any existing hook script, `plugin.json`,
any prior story file.

## Previous Story Intelligence

STORY-040 created `run.sh`, `model-family.sh`, four stub AGENT.md files, and
`tests/adversary.bats` with 8 green tests covering model-diversity and 4-agent dispatch.
This story extends `run.sh` to emit the structured verdict and adds the revision loop.

Critical: verify STORY-040's 8 bats tests remain green after adding the structured
verdict schema in Task 2. The verdict JSON fields added here (`iterations_log`,
`converged`) are additive — they must not break the existing `overall_issues` field
structure validated by STORY-040 tests.

The fixture files `tests/fixtures/good-brief.md` and `tests/fixtures/bad-brief.md`
created in STORY-040 are reused by the revision loop tests here. The bad-brief fixture
must contain at least one voice-avoid-list violation and one LinkedIn length violation
to produce deterministic FAIL verdicts for the loop tests.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~5,200 |
| SS-07 subsystem design | ~700 |
| BC-2.07.003 file | ~600 |
| BC-2.07.004 file | ~600 |
| VP-010 file | ~600 |
| STORY-040 (run.sh + model-family.sh — predecessor context) | ~600 |
| `.brain/policies.yaml` template (max_adversary_iterations field) | ~200 |
| Existing adversary.bats (8 passing tests) | ~400 |
| **Total** | **~8,900** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Model diversity enforcement and 4-agent dispatch — delivered in STORY-040.
- Governance policies initialization — STORY-042 scope (BC-2.15.001).
- `/brain:policy-add` and `/brain:policy-registry-validate` — STORY-043 scope.
- Plugin tarball packaging — no explicit BC in this epic; covered by meta-lint (VP-006).
- Writescore score computation algorithm — the score is produced by individual validation
  agents as part of their finding aggregation. The adversary skill reads and records
  scores; it does not compute them independently.

## Anchors

- BC-2.07.003: `behavioral-contracts/ss-07/BC-2.07.003.md`
- BC-2.07.004: `behavioral-contracts/ss-07/BC-2.07.004.md`
- VP-010: `architecture/verification-properties/VP-010-adversarial-cascade-convergence.md`
- SS-07: `architecture/subsystems/SS-07-adversarial-review.md`
- STORY-040: `stories/stories/STORY-040.md` (adversary dispatch core — predecessor)
