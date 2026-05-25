---
artifact_type: story
story_id: STORY-042
epic_id: EPIC-09
title: "Governance policies initialization — .brain/policies.yaml with 10 baseline policies"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-15]
behavioral_contracts: [BC-2.15.001]
vps: []
dependencies: [STORY-001, STORY-041]
blocks: [STORY-043]
inputs:
  - architecture/subsystems/SS-15-governance-policies.md
  - behavioral-contracts/ss-15/BC-2.15.001.md
input-hash: ""
# BC status: BC-2.15.001 assigned; status=draft per S-7.01
# Priority: P1 — governance policies are required for Phase 2 operator trust surface.
#   Not blocking Phase 1 exit gate (adversary-review is P0; policy init is P1).
#   5 points: the core work is writing the `policies.yaml` template with 10 baseline
#   entries, extending `/brain:init` to copy it, and writing the bats test suite.
#   Lower complexity than the adversary dispatch stories because the behavioral surface
#   is a template copy + YAML validation rather than multi-agent orchestration.
# Dependency rationale:
#   STORY-001: /brain:init skill must exist before its policy-copy phase can be extended.
#   STORY-041: adversary review uses `adversary_model` and `max_adversary_iterations`
#     from policies.yaml — the 10 baseline policies must include these fields. STORY-041
#     reads from policies.yaml; STORY-042 writes the template that creates it. Run
#     STORY-041 before STORY-042 to confirm which policy fields the adversary skill needs.
# Subsystem anchor:
#   SS-15 owns BC-2.15.001 per SS-15-governance-policies.md BC Inventory.
#   Dependency on SS-01 (/brain:init) is documented in SS-15 Dependencies section.
---

# STORY-042: Governance policies initialization — `.brain/policies.yaml` with 10 baseline policies

## Goal

Deliver the `.brain/policies.yaml` governance configuration by creating the
`templates/policies.yaml` template (pre-populated with all 10 baseline policies)
and extending `/brain:init` to copy it to `.brain/policies.yaml` during scaffold.
After this story, a fresh `/brain:init` produces a parseable 10-policy governance
file that all downstream skills (adversary review, hooks, lint-wiki) can read.

## User Value

As a brain vault operator, I want `/brain:init` to create a `.brain/policies.yaml`
file with 10 pre-configured governance policies so that the vault is governed from
day one without manual configuration.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.15.001 | `.brain/policies.yaml` initialized with 10 baseline policies by `/brain:init` | P1 |

## Acceptance Criteria

### Policy initialization (BC-2.15.001)

**AC-001** — When `/brain:init` runs its template-expansion phase on a fresh directory
(no existing `.brain/`), it copies `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml`
to `.brain/policies.yaml`. After init completes, the file exists and is valid YAML
(`yq eval '.' .brain/policies.yaml` exits 0).
(traces to BC-2.15.001 postcondition 1; postcondition 2)

**AC-002** — The initialized `.brain/policies.yaml` contains exactly 10 baseline
policies. The bats test runs `yq eval '.policies | length' .brain/policies.yaml`
and asserts the result is `10`.
(traces to BC-2.15.001 postcondition 1; invariant 1)

**AC-003** — The 10 baseline policies are present with the expected IDs and names:
POL-001 (`source-immutability`), POL-002 (`wikilink-integrity`),
POL-003 (`frontmatter-schema`), POL-004 (`page-type-policy`),
POL-005 (`kebab-case-naming`), POL-006 (`no-ai-attribution`),
POL-007 (`quarantine-coverage`), POL-008 (`voice-avoid-list`),
POL-009 (`source-id-citation`), POL-010 (`publish-state-machine`).
The bats test extracts all 10 IDs via `yq` and asserts each is present.
(traces to BC-2.15.001 postcondition 1; invariant 1; SS-15 "10 baseline policies" list)

**AC-004** — The initialized policies.yaml contains at minimum these required
configuration fields:
- `adversary_model: "claude-sonnet-4-6"` (for BC-2.07.001 default adversary pairing)
- `max_adversary_iterations: 3` (for BC-2.07.003 revision loop bound)
- `max_ingest_tokens_per_chunk: 50000` (for BC-2.02.003 chunk token budget)
A bats test reads each field via `yq` and asserts the value is non-empty and matches
the documented default.
(traces to BC-2.15.001 postcondition 3)

**AC-005** — When `/brain:init` cannot find `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml`
(missing or corrupt plugin installation), it exits 2 with error
`E-INIT-004: "Plugin root not found — reinstall brain-factory"`.
`.brain/policies.yaml` is NOT created. The scaffold is rolled back (`.brain/` removed).
(traces to BC-2.15.001 edge case EC-001)

**AC-006** — When `/brain:init` is run on a directory that already has `.brain/`
(re-init attempt), it exits 2 with `E-INIT-002` before reaching the policy-copy phase.
The existing `.brain/policies.yaml` is NOT overwritten.
(traces to BC-2.15.001 edge case EC-002)

**AC-007** — After `/brain:init` copies `templates/policies.yaml`, the policy file
is immediately parseable by `yq eval '.'`. The template MUST NOT contain YAML
syntax errors. The bats test that validates AC-001 implicitly catches template syntax
errors.
(traces to BC-2.15.001 edge case EC-003 — malformed template detected at test time)

**AC-008** — Every policy entry in the template has all required fields: `id` (POL-NNN),
`name` (kebab-case), `description` (non-empty string), `enforcement` (hook|skill|manual),
`severity` (block|advise|manual). A bats test validates all 10 entries with `yq` field
extraction.
(traces to SS-15 "policies.yaml schema" — required fields per entry)

## Tasks

1. **[failing tests — Red Gate]** Create `plugins/brain-factory/tests/policies.bats`
   with failing tests:
   - `"policy-init: 10 baseline policies present after init (BC-2.15.001)"`.
   - `"policy-init: policies.yaml is valid YAML (BC-2.15.001 postcondition 2)"`.
   - `"policy-init: required config fields present: adversary_model, max_adversary_iterations, max_ingest_tokens_per_chunk"`.
   - `"policy-init: all 10 policy IDs present (POL-001..POL-010)"`.
   - `"policy-init: all 10 policies have required schema fields"`.
   - `"policy-init: missing template → E-INIT-004; exit 2; .brain/ rolled back (EC-001)"`.
   - `"policy-init: re-init → E-INIT-002; exit 2; existing policies.yaml untouched (EC-002)"`.

   Run bats — confirm all 7 tests fail (Red Gate confirmed).

2. **[impl — policies.yaml template]** Create
   `plugins/brain-factory/templates/policies.yaml` with all 10 baseline policies
   and the three required configuration fields. Use the schema:
   ```yaml
   config:
     adversary_model: "claude-sonnet-4-6"
     max_adversary_iterations: 3
     max_ingest_tokens_per_chunk: 50000

   policies:
     - id: "POL-001"
       name: "source-immutability"
       description: "Sources are write-once. No overwrite without explicit rename flow."
       enforcement: "hook"
       hook: "validate-source-immutability.sh"
       severity: "block"
     # POL-002 through POL-010...
   ```
   All 10 policy entries must have all required fields. Template must pass
   `yq eval '.' templates/policies.yaml` (no syntax errors).

3. **[impl — init extension]** Extend `/brain:init` (STORY-001 artifact,
   `plugins/brain-factory/skills/init/run.sh`) to copy the policies template:
   - After `.brain/` directory creation, copy
     `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml` → `.brain/policies.yaml`.
   - If template missing: emit `E-INIT-004`, roll back `.brain/` (remove it), exit 2.
   - If `.brain/` already exists (re-init guard from STORY-001): this is already
     handled by the existing E-INIT-002 guard — verify the guard fires before the
     policy copy phase. Do NOT add a second guard.

4. **[green]** Run `bats plugins/brain-factory/tests/policies.bats`. All 7 tests pass.
   Run `bats plugins/brain-factory/tests/init.bats` (STORY-001 tests) to verify the
   init extension does not break existing init tests.
   `shellcheck` + `shfmt -d -i 2` on modified `run.sh` — zero findings.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| Fresh init; `yq eval '.' .brain/policies.yaml` | Valid YAML; exit 0 | happy-path | BC-2.15.001 canonical test vector 1 |
| `yq eval '.policies | length' .brain/policies.yaml` | `10` | happy-path | BC-2.15.001 invariant 1 |
| Init with template file absent | E-INIT-004; exit 2; no `.brain/` left | error | BC-2.15.001 canonical test vector 2 |
| Init on directory with existing `.brain/` | E-INIT-002; exit 2; existing policies.yaml untouched | edge-case | BC-2.15.001 canonical test vector 3 |
| `yq eval '.config.adversary_model'` | `"claude-sonnet-4-6"` | happy-path | BC-2.15.001 postcondition 3 |
| `yq eval '.config.max_adversary_iterations'` | `3` | happy-path | BC-2.15.001 postcondition 3 |
| policies.yaml with two entries sharing the same `id` | `yq eval '.'` detects duplicate key YAML error | edge-case | BC-2.15.003 EC-001 (tested via meta-lint of template at authoring time) |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no P0 VP — P1 BC) | 10 baseline policies present after init | `tests/policies.bats` |
| (no P0 VP — P1 BC) | Template syntax valid | `tests/policies.bats` AC-001 implicit check |
| (no P0 VP — P1 BC) | Re-init guard fires before policy copy | `tests/policies.bats` EC-002 |

## Architecture Compliance Rules

From `architecture/subsystems/SS-15-governance-policies.md`:

1. `templates/policies.yaml` is the source of truth for the baseline policy set.
   `/brain:init` always copies from this template — it NEVER generates policy content
   inline. The template is committed to the plugin repository and versioned with the
   plugin.

2. The template path reference in `init/run.sh` MUST use `${CLAUDE_PLUGIN_ROOT}/templates/policies.yaml`
   — never `.claude/templates/...`. This is the project-wide template-path discipline
   from CLAUDE.md §Conventions.

3. The `config` section (with `adversary_model`, `max_adversary_iterations`,
   `max_ingest_tokens_per_chunk`) is separate from the `policies` array in the YAML
   structure. Skills that read configuration fields use `yq eval '.config.adversary_model'`
   — not `.policies[] | select(.id == "POL-XXX")`. This separates runtime configuration
   from governance policy enumeration.

4. The `.brain/` rollback on E-INIT-004 must use `rm -rf "${BRAIN_DIR}"` where
   `BRAIN_DIR` is the computed absolute path (never `rm -rf .brain/` — that would fail
   if cwd is not the vault root). Verify the rollback path is the same directory that
   was created at the start of the init sequence.

5. Schema validation of the template at authoring time is enforced by **meta-lint**
   (`tests/meta-lint.bats`), not by the init script at runtime. The init script copies
   the template and validates the copy with `yq eval '.'` (YAML parse check only).
   Field-level schema validation (required fields per policy) is the responsibility of
   `/brain:policy-registry-validate` (STORY-043).

**Forbidden dependencies:**
- Do NOT hardcode any policy content inline in `init/run.sh`. All policy content lives
  in `templates/policies.yaml`.
- Do NOT use `cp` without checking exit code — if the copy fails, E-INIT-004 must fire.
  Use `cp "${PLUGIN_ROOT}/templates/policies.yaml" "${BRAIN_DIR}/policies.yaml" || {
  echo "E-INIT-004"; exit 2; }` pattern.
- `init/run.sh` must NOT call `/brain:policy-registry-validate` during init — that is
  an operator-invoked command, not an init-time gate. The init-time check is YAML
  parse-only (`yq eval '.' .brain/policies.yaml`).

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | policies.yaml validation and field reads. **Ubuntu note:** `apt install yq` installs the WRONG tool (kislyuk/yq, Python-based). Use `snap install yq`. |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/templates/policies.yaml` | Create | 10 baseline policies + config section |
| `plugins/brain-factory/skills/init/run.sh` | Modify | Add policy template copy phase |
| `plugins/brain-factory/tests/policies.bats` | Create | 7 failing tests (Red Gate), then green |

Files NOT to modify: any `.factory/` artifact, any existing hook script, `plugin.json`,
any prior story file, `tests/init.bats` (existing tests must stay green).

## Previous Story Intelligence

STORY-001 (EPIC-01) delivered the core `/brain:init` skill (`skills/init/run.sh`) and
its bats test suite (`tests/init.bats`). Before modifying `init/run.sh`, read STORY-001
to understand the existing init phases and the E-INIT-002 re-init guard location.
The policy copy MUST be inserted after `.brain/` directory creation and before the
final "init complete" success message. Do NOT move or duplicate the E-INIT-002 guard.

STORY-041 (EPIC-09) extended `/brain:adversary-review` to read `adversary_model` and
`max_adversary_iterations` from `.brain/policies.yaml`. Run STORY-041's adversary.bats
tests with the new policies.yaml in place to confirm the fields are read correctly.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,200 |
| SS-15 subsystem design | ~600 |
| BC-2.15.001 file | ~600 |
| STORY-001 (init/run.sh — context for extension) | ~500 |
| STORY-041 (policies.yaml field usage — context) | ~300 |
| **Total** | **~6,200** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- `/brain:policy-add` — STORY-043 scope (BC-2.15.002).
- `/brain:policy-registry-validate` — STORY-043 scope (BC-2.15.003).
- Validation of individual policy field schemas at init time — STORY-043 scope.
- `adversary_model` configuration enforcement — already delivered in STORY-040/041;
  this story only ensures the field exists in the initialized template.

## Anchors

- BC-2.15.001: `behavioral-contracts/ss-15/BC-2.15.001.md`
- SS-15: `architecture/subsystems/SS-15-governance-policies.md`
- STORY-001: `stories/stories/STORY-001.md` (init skill — prerequisite for extension)
- STORY-041: `stories/stories/STORY-041.md` (adversary policies.yaml reads — context)
