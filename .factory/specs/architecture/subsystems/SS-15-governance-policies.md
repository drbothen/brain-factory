---
document_type: subsystem-design
id: SS-15
title: "Governance and Policies"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-015
created: 2026-05-15
---

# SS-15: Governance and Policies

## Responsibility

Initializes `.brain/policies.yaml` with 10 baseline policies, supports adding new policies via `/brain:policy-add`, and validates all policies against the schema via `/brain:policy-registry-validate`.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.15.001 | `.brain/policies.yaml` initialized with 10 baseline policies by `/brain:init` | P1 |
| BC-2.15.002 | `/brain:policy-add <id> <body>` registers new policy with schema validation | P1 |
| BC-2.15.003 | `/brain:policy-registry-validate` validates all policies against schema | P1 |

## Interfaces

**Inbound:** `/brain:policy-add <id> <body>`; `/brain:policy-registry-validate`

**Outbound:** updated `.brain/policies.yaml`; validation report

## Key Design

### policies.yaml schema

```yaml
policies:
  - id: "POL-001"
    name: "source-immutability"
    description: "Sources are write-once. No overwrite without explicit rename flow."
    enforcement: "hook"
    hook: "validate-source-immutability.sh"
    severity: "block"
  # ... 9 more baseline policies
```

Required fields per policy: `id` (POL-NNN), `name` (kebab-case), `description` (string), `enforcement` (hook|skill|manual), `severity` (block|advise|manual).

### 10 baseline policies

`/brain:init` writes these 10 baseline policies (from `templates/policies.yaml`):
1. POL-001: source-immutability (hook enforcement)
2. POL-002: wikilink-integrity (hook enforcement)
3. POL-003: frontmatter-schema (hook enforcement)
4. POL-004: page-type-policy (hook enforcement)
5. POL-005: kebab-case-naming (hook enforcement)
6. POL-006: no-ai-attribution (hook enforcement)
7. POL-007: quarantine-coverage (hook enforcement)
8. POL-008: voice-avoid-list (hook enforcement — advisory)
9. POL-009: source-id-citation (hook enforcement)
10. POL-010: publish-state-machine (hook enforcement)

### Policy addition and validation

`/brain:policy-add <id> <body>` appends a new policy to `.brain/policies.yaml` after schema validation. The `id` must be unique (checked against existing policies via `yq` lookup). The `body` is a YAML block that must contain all required fields.

`/brain:policy-registry-validate` reads all policies and validates each against the schema using `yq eval`. Returns structured result: `{"total": N, "valid": N, "invalid": [...]}`.

## Purity Classification

**Mixed.** Schema validation (given a YAML string, does it conform to the schema?) is a pure function testable with fixture YAML. The file write and yq lookup are effectful.

## Dependencies

- SS-01 (Brain Init): baseline policies written during init
- SS-04 (Hook Chain): hook-enforced policies are backed by the 13 registered hooks

## Test Surface

- `tests/policies.bats` — 10 baseline policies present after init; policy-add with valid schema → appended; policy-add with missing field → E-POLICY-001; policy-registry-validate on fixture with invalid entry → invalid count > 0
