---
document_type: behavioral-contract
level: L3
version: "1.1"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-15T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-07"
capability: "CAP-007"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.07.001: `/brain:adversary-review` runs in a different model family than the producer agent

## Description

Cognitive diversity in adversarial review requires that the `brain:adversary-reviewer` agent uses a different model family than the agent that produced the artifact under review. In brain-factory v0.x, the default pairing is Opus as producer and Sonnet as adversary (or vice versa). Both are Anthropic models — cognitive diversity does not require a second vendor. Operators may override the pairing via `.brain/policies.yaml`. This constraint is enforced at skill invocation time, not at hook level.

## Preconditions

1. `/brain:adversary-review <path>` is invoked.
2. The artifact at `<path>` was produced by an agent with a known model identifier.
3. `.brain/policies.yaml` specifies `adversary_model` or the default applies.

## Postconditions

1. The adversary agent is invoked with a model that is different from the producer's model family.
2. If model family cannot be determined (cold start), the skill uses the default pairing (Opus/Sonnet split).
3. The model pairing is logged in the review output.

## Invariants

1. Opus and Sonnet are treated as different families for adversary-review purposes in v0.x.
2. Same-model adversary review is blocked (E-ADVERSARY-001).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Producer model unknown | Use default adversary model (Sonnet if producer is unknown, per policy default). |
| EC-002 | Operator configures same model for both producer and adversary | E-ADVERSARY-001: "Adversary model must differ from producer model." Skill exits 2. |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Review of artifact produced by Opus; adversary = Sonnet | Review proceeds; pairing logged | happy-path |
| Both models configured as claude-sonnet | E-ADVERSARY-001; exit 2 | error |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-010 | Same-model adversary blocked | bats adversary.bats |
| VP-010 | Default pairing applied when producer unknown | bats adversary.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-007 ("Adversarial Review and Writescore") per brief §Constraints §Technical ("Cognitive diversity in adversary review. The `brain:adversary-reviewer` agent MUST run in a different model family than the agent that produced the work under review (in brain-factory v0.x: Opus and Sonnet are different families for adversary-review purposes)."). |
| Architecture Module | SS-07: Adversarial Review and Writescore |
| Stories | [filled by story-writer] |
| Source Brief Section | product-brief.md §Constraints §Technical; §Value Proposition §Core differentiator #2; §Open Questions #2 (Resolved) |

## Related BCs

- BC-2.07.002 — composes with
- BC-2.07.003 — composes with
- BC-2.07.004 — composes with
