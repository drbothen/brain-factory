---
artifact_type: story
story_id: STORY-043
epic_id: EPIC-09
title: "Policy registry management — /brain:policy-add and /brain:policy-registry-validate"
status: draft
created: 2026-05-18
tdd_mode: strict
phase: 2
points: 5
priority: P1
subsystems: [SS-15]
behavioral_contracts: [BC-2.15.002, BC-2.15.003]
vps: []
dependencies: [STORY-042]
blocks: []
inputs:
  - architecture/subsystems/SS-15-governance-policies.md
  - behavioral-contracts/ss-15/BC-2.15.002.md
  - behavioral-contracts/ss-15/BC-2.15.003.md
input-hash: ""
# BC status: BC-2.15.002 + BC-2.15.003 assigned; status=draft per S-7.01
# Priority: P1 — operator-facing policy management surface; not blocking Phase 1 exit.
#   5 points: both skills are thin wrappers over yq operations (append + validate).
#   The pure-function schema validator is the most testable surface and drives the
#   bats coverage. Two skills in one story is justified because they share the same
#   schema definition and the same fixture policies.yaml from STORY-042. Splitting
#   into two stories would create two 2-point stories with 80% setup overlap.
# Dependency rationale:
#   STORY-042: policies.yaml template and 10 baseline policies must exist before
#     policy-add and policy-registry-validate can be implemented and tested.
# Subsystem anchor:
#   SS-15 owns BC-2.15.002 and BC-2.15.003 per SS-15-governance-policies.md BC Inventory.
---

# STORY-043: Policy registry management — `/brain:policy-add` and `/brain:policy-registry-validate`

## Goal

Deliver the two operator-facing policy management skills: `/brain:policy-add <id> <body>`
for extending the governance registry with schema-validated new policies (BC-2.15.002),
and `/brain:policy-registry-validate` for bulk-auditing all policies in
`.brain/policies.yaml` against the schema (BC-2.15.003). Together these complete the
SS-15 Governance and Policies subsystem.

## User Value

As a brain vault operator, I want to extend the governance policy registry with custom
policies and validate the entire registry in bulk so that I can tailor brain-factory's
governance rules to my team's workflow without corrupting the policy file.

## Behavioral Contracts

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.15.002 | `/brain:policy-add <id> <body>` registers new policy with schema validation | P1 |
| BC-2.15.003 | `/brain:policy-registry-validate` validates all policies against schema | P1 |

## Acceptance Criteria

### Policy-add (BC-2.15.002)

**AC-001** — When `/brain:policy-add POL-011 '{id: "POL-011", name: "my-policy",
description: "Custom.", enforcement: "manual", severity: "advise"}'` is invoked and
`POL-011` does not already exist in `.brain/policies.yaml`, the policy is appended
to the `.policies` array. The file remains valid YAML after append (verified with
`yq eval '.'`). Exit 0.
(traces to BC-2.15.002 postcondition 1; postcondition 2; postcondition 4)

**AC-002** — After a successful `/brain:policy-add`, the new policy is accessible via
`yq eval '.policies[] | select(.id == "POL-011")' .brain/policies.yaml` and returns
the correct entry.
(traces to BC-2.15.002 postcondition 3)

**AC-003** — The append operation is atomic: either the policy is appended and the file
is valid YAML, or the file is not modified. A bats test simulates a corrupt YAML body
(missing closing quote) and verifies the file is unchanged after the error.
(traces to BC-2.15.002 invariant 2)

**AC-004** — When the policy ID already exists (e.g., `POL-001`), `/brain:policy-add`
exits 2 with error `E-POLICY-001: "Policy ID 'POL-001' already exists."`. The
`.brain/policies.yaml` file is not modified.
(traces to BC-2.15.002 invariant 1; edge case EC-001)

**AC-005** — When the policy body is not valid YAML (e.g., `{id: "POL-011", name:`
with unclosed brace), `/brain:policy-add` exits 2 with error
`E-POLICY-002: "Policy body is not valid YAML."`. The file is not modified.
(traces to BC-2.15.002 edge case EC-002)

**AC-006** — When the policy body is valid YAML but missing a required field
(e.g., no `name` key), `/brain:policy-add` exits 2 with
`E-POLICY-003: "Policy body missing required field: name."`. The file is not modified.
A bats test cycles through each of the 5 required fields (`id`, `name`, `description`,
`enforcement`, `severity`) being absent and asserts E-POLICY-003 fires each time.
(traces to SS-15 "required fields per policy"; production-grade default per CLAUDE.md §Canonical Principle)

### Policy-registry-validate (BC-2.15.003)

**AC-007** — When `/brain:policy-registry-validate` is invoked on a `.brain/policies.yaml`
with all 10 valid baseline policies, it returns:
`{"valid_count": 10, "invalid_count": 0, "issues": []}` on stdout and exits 0.
(traces to BC-2.15.003 postcondition 1; postcondition 2; invariant 1)

**AC-008** — When one policy is malformed (missing `severity` field), the command
returns `{"valid_count": 9, "invalid_count": 1, "issues": ["POL-XXX: missing required
field: severity"]}` and exits 1.
(traces to BC-2.15.003 postcondition 1; postcondition 2 — exit 1 on any invalid)

**AC-009** — When `.brain/policies.yaml` contains two entries with the same `id`
(duplicate key scenario per EC-001), the validator detects the duplicate and reports
it in `issues`: `"duplicate id: POL-001"`. `invalid_count` includes the duplicate.
Exit 1.
(traces to BC-2.15.003 edge case EC-001)

**AC-010** — When a policy's `id` field collides with a baseline policy ID but was
added via `/brain:policy-add` (BC-2.15.003 EC-002 mis-registration scenario), the
validator detects the collision and includes it in `issues`. The operator must remove
the duplicate manually.
(traces to BC-2.15.003 edge case EC-002)

**AC-011** — When `.brain/policies.yaml` is an empty file (zero bytes), the validator
returns `{"valid_count": 0, "invalid_count": 0, "issues": ["YAML parse failed: empty
file"]}` and exits 1 with error `E-POLICY-002`.
(traces to BC-2.15.003 edge case EC-003)

**AC-012** — All policies in the file are validated — not just new ones. The `valid_count`
plus `invalid_count` equals the total number of entries in the `policies` array.
A bats test with 10 valid + 1 invalid policy asserts `valid_count + invalid_count = 11`.
(traces to BC-2.15.003 invariant 1)

## Tasks

1. **[failing tests — Red Gate]** Extend `plugins/brain-factory/tests/policies.bats`
   with failing tests:

   Policy-add (BC-2.15.002):
   - `"policy-add: unique policy → appended; valid YAML; exit 0 (BC-2.15.002)"`.
   - `"policy-add: new policy accessible via yq select"`.
   - `"policy-add: append is atomic — corrupt body → file unchanged (BC-2.15.002 invariant 2)"`.
   - `"policy-add: duplicate ID → E-POLICY-001; exit 2 (BC-2.15.002 EC-001)"`.
   - `"policy-add: invalid YAML body → E-POLICY-002; exit 2 (BC-2.15.002 EC-002)"`.
   - `"policy-add: missing required field → E-POLICY-003; exit 2 (each of 5 fields)"`.

   Policy-registry-validate (BC-2.15.003):
   - `"policy-registry-validate: 10 valid policies → valid_count=10; exit 0 (BC-2.15.003)"`.
   - `"policy-registry-validate: 1 malformed policy → invalid_count=1; exit 1"`.
   - `"policy-registry-validate: duplicate id → detected in issues; exit 1 (EC-001)"`.
   - `"policy-registry-validate: empty file → YAML parse failed; exit 1 (EC-003)"`.
   - `"policy-registry-validate: all policies validated; count = valid + invalid (invariant 1)"`.

   Run bats on policies.bats — confirm all 11 new tests fail (Red Gate confirmed).
   The 7 tests from STORY-042 should remain green.

2. **[impl — schema validator pure function]** Implement
   `plugins/brain-factory/skills/policy-add/lib/policy-schema.sh`:
   - Input: YAML string (single policy entry) on stdin.
   - Output: `{"valid": true}` or `{"valid": false, "missing_field": "<name>",
     "error": "E-POLICY-003: ..."}` on stdout.
   - Checks: valid YAML parse (via `yq eval '.'`), presence of all 5 required fields.
   - Pure function: no file I/O. Bats-testable with `run echo "..." | bash policy-schema.sh`.
   Make the missing-required-field and invalid-YAML bats tests green.

3. **[impl — /brain:policy-add skill]** Create
   `plugins/brain-factory/skills/policy-add/SKILL.md` (canonical 6-section structure)
   and `plugins/brain-factory/skills/policy-add/run.sh`:
   - Read existing IDs via `yq eval '.policies[].id'`.
   - Check for duplicate ID; exit 2 with E-POLICY-001 if found.
   - Parse policy body via `policy-schema.sh`; exit 2 with E-POLICY-002 or E-POLICY-003
     on schema failure.
   - Atomic append: write to tmp file, validate with `yq eval '.'`, then `mv` to
     replace `.brain/policies.yaml`.
   - Exit 0 on success.
   Make policy-add tests green.

4. **[impl — /brain:policy-registry-validate skill]** Create
   `plugins/brain-factory/skills/policy-registry-validate/SKILL.md` and
   `plugins/brain-factory/skills/policy-registry-validate/run.sh`:
   - Parse entire `.brain/policies.yaml` with `yq eval`.
   - Exit 1 with E-POLICY-002 on YAML parse failure (empty or corrupt file).
   - Iterate all policies; for each: call `policy-schema.sh` to validate.
   - Detect duplicate IDs by sorting all `.policies[].id` values and checking for
     adjacent duplicates.
   - Emit `{"valid_count": N, "invalid_count": M, "issues": [...]}`.
   - Exit 0 on all valid; exit 1 if any invalid.
   Make policy-registry-validate tests green.

5. **[green]** Run `bats plugins/brain-factory/tests/policies.bats`. All 18 tests
   (7 from STORY-042 + 11 new) pass. `shellcheck` + `shfmt -d -i 2` on all new/
   modified scripts — zero findings.

## Test Vectors

| Input | Expected Output | Category | Source |
|-------|----------------|----------|--------|
| New unique policy (all fields) | Appended; valid YAML; exit 0 | happy-path | BC-2.15.002 canonical test vector 1 |
| Duplicate ID (POL-001) | E-POLICY-001; exit 2 | error | BC-2.15.002 canonical test vector 2 |
| Invalid YAML body (unclosed brace) | E-POLICY-002; exit 2 | error | BC-2.15.002 EC-002 |
| Body missing `description` field | E-POLICY-003: "missing required field: description"; exit 2 | error | SS-15 schema requirement |
| Valid 10-policy file | `{"valid_count": 10, "invalid_count": 0}`; exit 0 | happy-path | BC-2.15.003 canonical test vector 1 |
| File with one malformed policy | `{"valid_count": 9, "invalid_count": 1, "issues": [...]}`; exit 1 | error | BC-2.15.003 canonical test vector 2 |
| File with duplicate ID (two POL-001 entries) | `{"...", "issues": ["duplicate id: POL-001"]}`; exit 1 | edge-case | BC-2.15.003 EC-001 |
| Empty policies.yaml file | `{"...", "issues": ["YAML parse failed: empty file"]}`; exit 1 | edge-case | BC-2.15.003 EC-003 |

## Verification Evidence

| VP | Property | Test Location |
|----|----------|---------------|
| (no P0 VP — P1 BCs) | Unique policy appended; file valid | `tests/policies.bats` |
| (no P0 VP — P1 BCs) | Duplicate ID rejected | `tests/policies.bats` |
| (no P0 VP — P1 BCs) | All policies validated in bulk | `tests/policies.bats` |
| (no P0 VP — P1 BCs) | Malformed policy detected | `tests/policies.bats` |

## Architecture Compliance Rules

From `architecture/subsystems/SS-15-governance-policies.md`:

1. Schema validation (given a YAML string, does it conform to the schema?) is a
   **pure function** placed in `skills/policy-add/lib/policy-schema.sh`. Both
   `/brain:policy-add` and `/brain:policy-registry-validate` call this shared
   function. Do NOT duplicate the validation logic in two separate scripts.

2. The atomic append in `policy-add/run.sh` uses the write-to-tmp-then-mv pattern:
   ```bash
   yq eval ".policies += [${new_policy}]" .brain/policies.yaml > /tmp/policies.yaml.tmp
   yq eval '.' /tmp/policies.yaml.tmp > /dev/null || { echo "E-POLICY-002"; rm -f /tmp/...; exit 2; }
   mv /tmp/policies.yaml.tmp .brain/policies.yaml
   ```
   Never use in-place write (`yq -i`) without the intermediate validation step.

3. Duplicate ID detection in `policy-registry-validate/run.sh` uses:
   `yq eval '.policies[].id' file | sort | uniq -d` — this is a pure shell pipeline
   that produces the duplicate IDs without loading the whole file into memory.

4. Error codes E-POLICY-001, E-POLICY-002, E-POLICY-003 are defined in this story.
   These codes are NEW — not in any prior error taxonomy file. They must be added to
   `docs/planning/` or the error taxonomy supplement in `.factory/specs/prd-supplements/`
   (the orchestrator routes this to the product-owner after STORY-043 merges; this
   story documents the new codes inline in the skill's Red Flags section).

5. The `policy-registry-validate` skill outputs JSON to stdout and human-readable
   summary to stderr. Hooks reading this skill's output use stdout JSON.
   `jq -e '.valid_count == .valid_count + .invalid_count'`-style assertions in bats
   must read stdout only.

**Forbidden dependencies:**
- Do NOT use `eval` in any hook or skill script (project-wide ban).
- `policy-schema.sh` must NOT write to any file — it is a pure function.
- `policy-add/run.sh` must NOT call `/brain:policy-registry-validate` — validation
  is done by `policy-schema.sh` on the new entry only. Full-registry validation is
  an explicit operator command, not an implicit side-effect of adding a policy.
- Do NOT hardcode the list of 10 baseline policy IDs in the validation logic — read
  them dynamically from policies.yaml. Hardcoded IDs would break when operators add
  custom policies with IDs above POL-010.

## Library and Framework Requirements

| Tool | Version | Constraint Source |
|------|---------|-------------------|
| `bash` | 5.0+ (macOS: requires Homebrew bash; system bash is 3.2) | CLAUDE.md §Conventions |
| `jq` | 1.7+ (latest: 1.8.1) | Verdict JSON schema validation; count assertions |
| `yq` | 4.x+ (mikefarah/yq; latest: 4.53.2) | policies.yaml reads, duplicate detection, schema validation. **Ubuntu note:** `apt install yq` installs the WRONG tool (kislyuk/yq, Python-based). Use `snap install yq`. |
| `bats-core` | 1.10+ (latest: 1.13.0) | CLAUDE.md §Build & Test |
| `shellcheck` | 0.10+ (latest: 0.11.0) | CLAUDE.md §Conventions |
| `shfmt` | 3.7+ (latest: 3.13.1) | CLAUDE.md §Conventions |

## File Structure Requirements

| Path | Action | Notes |
|------|--------|-------|
| `plugins/brain-factory/skills/policy-add/SKILL.md` | Create | Canonical 6-section structure; Iron Law, Red Flags |
| `plugins/brain-factory/skills/policy-add/run.sh` | Create | Duplicate check + schema validation + atomic append |
| `plugins/brain-factory/skills/policy-add/lib/policy-schema.sh` | Create | Pure function — schema validation; shared by both skills |
| `plugins/brain-factory/skills/policy-registry-validate/SKILL.md` | Create | Canonical 6-section structure |
| `plugins/brain-factory/skills/policy-registry-validate/run.sh` | Create | Full-registry validation + duplicate detection + JSON output |
| `plugins/brain-factory/tests/policies.bats` | Modify | Add 11 new failing tests (Red Gate), then green |

Files NOT to modify: any `.factory/` artifact, any existing hook script, `plugin.json`,
any prior story file, `templates/policies.yaml` (STORY-042 output — do not alter).

## Previous Story Intelligence

STORY-042 created `templates/policies.yaml` (10 baseline policies + `config` section)
and extended `init/run.sh` to copy it. STORY-043 builds on top of the initialized
`.brain/policies.yaml` — the bats tests in this story MUST set up a fixture
`.brain/policies.yaml` from the STORY-042 template in their `setup()` function.

Pattern for bats setup in policies.bats:
```bash
setup() {
  export TEMP_BRAIN; TEMP_BRAIN="$(mktemp -d)"
  cp "${PLUGIN_ROOT}/templates/policies.yaml" "${TEMP_BRAIN}/.brain/policies.yaml"
}
teardown() {
  rm -rf "${TEMP_BRAIN}"
}
```

The shared `policy-schema.sh` pure function is placed in `skills/policy-add/lib/`
(not in a shared `lib/` root). The `policy-registry-validate/run.sh` sources it via
`source "${SKILL_ROOT}/../policy-add/lib/policy-schema.sh"`. If this cross-skill
sourcing is too brittle, extract to `plugins/brain-factory/lib/policy-schema.sh`
(shared lib root). Make this call at implementation time — either path is acceptable,
but the function must NOT be duplicated.

## Token Budget Estimate

| Component | Estimated Tokens |
|-----------|-----------------|
| This story spec | ~4,800 |
| SS-15 subsystem design | ~600 |
| BC-2.15.002 file | ~600 |
| BC-2.15.003 file | ~600 |
| STORY-042 (policies.yaml template + init extension — predecessor context) | ~500 |
| Existing policies.bats (7 passing tests) | ~400 |
| **Total** | **~7,500** |

Within 20% of a 200K-token context window (~40K). No split required.

## Out of Scope

- Governance policy initialization (10 baseline policies) — STORY-042 scope.
- Adding error codes E-POLICY-001/002/003 to the canonical error taxonomy supplement —
  this is a product-owner task post-merge (route via orchestrator after STORY-043 merges).
- Lefthook integration for the brain vault (pre-commit/pre-push hooks that run
  policy-registry-validate) — no explicit BC in this epic; potential future story.
- Plugin tarball packaging and claude-mp marketplace publishing — no explicit BC in
  EPIC-09 maps to this; covered by meta-lint (VP-006) and plugin lifecycle (EPIC-01).

## Anchors

- BC-2.15.002: `behavioral-contracts/ss-15/BC-2.15.002.md`
- BC-2.15.003: `behavioral-contracts/ss-15/BC-2.15.003.md`
- SS-15: `architecture/subsystems/SS-15-governance-policies.md`
- STORY-042: `stories/stories/STORY-042.md` (policies.yaml template — prerequisite)
