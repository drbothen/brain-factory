---
document_type: subsystem-design
id: SS-07
title: "Adversarial Review and Writescore"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-16T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
capability_anchor: CAP-007
created: 2026-05-15
---

# SS-07: Adversarial Review and Writescore

## Responsibility

Applies the cognitive-diversity adversarial review pattern (KD-002) to user content artifacts. Dispatches an Opus adversary in fresh context, runs four wclaude validation agents, implements the 3-CLEAN streak protocol, and returns a structured verdict.

## BC Inventory

| BC ID | Title | Priority |
|-------|-------|----------|
| BC-2.07.001 | `/brain:adversary-review` runs in different model family than producer | P0 |
| BC-2.07.002 | Dispatches all four wclaude validation agents | P0 |
| BC-2.07.003 | Implements multi-pass writescore revision loop | P1 |
| BC-2.07.004 | Returns structured pass/fail verdict with finding list | P0 |

## Interfaces

**Inbound:** `/brain:adversary-review <path>`; the path points to a brief, synthesis, or published piece in the vault

**Outbound:** structured verdict JSON written to `.brain/cycles/<period>/adversary-pass-NNN.md`; streak counter updated in `.brain/STATE.md`; structured events

## Key Design (references ADR-009)

### Four validation agents (BC-2.07.002)

Each agent receives the artifact and returns a structured finding list:
1. `agents/frontmatter-validator/AGENT.md` — checks title, tags, status, publication_date schema
2. `agents/voice-reviewer/AGENT.md` — checks voice-avoid-list compliance; tone consistency with author voice rules
3. `agents/structure-reviewer/AGENT.md` — checks ONE THING / PROOF / TRANSFORMATION format; section flow
4. `agents/platform-reviewer/AGENT.md` — checks LinkedIn character limits, link formatting, platform-specific constraints

### Adversary synthesis

The adversary agent (Opus, fresh context) receives all four finding lists and synthesizes:
```json
{
  "verdict": "pass|fail",
  "streak": 0,
  "findings": [
    {"agent": "voice-reviewer", "severity": "important", "text": "..."}
  ],
  "pass_report": ".brain/cycles/2026-Q2/adversary-pass-001.md"
}
```

If `verdict: pass`, streak counter increments. If streak ≥ 3, the artifact is declared converged. If `verdict: fail`, streak resets to 0; findings are surfaced to the operator for revision.

### Multi-pass writescore loop (BC-2.07.003)

The writescore loop is implemented in the `/brain:adversary-review` skill body: after the initial adversary pass, if the verdict is fail, the skill optionally invokes writescore analysis and surfaces revision guidance before the operator can re-invoke. This is a P1 feature (v0.9) — the initial release (v0.1) returns the verdict and findings without the automated revision loop.

## Purity Classification

**Effectful shell.** The adversary dispatch, agent invocations, and file writes are all effectful. The finding classification logic (severity tiers) is deterministic and bats-testable with fixture finding lists.

## Dependencies

- SS-08 (Content Brief and Writing): artifacts under review are produced by SS-08 skills
- SS-17 (Event Catalog): review events emitted

## Test Surface

- `tests/adversary.bats` — structured verdict JSON schema validation; streak counter increments correctly; finding list non-empty on known bad artifact
- Integration: end-to-end review of fixture brief → assert pass/fail verdict returned

## Changelog

### v1.1 (2026-05-16)

**STRUCTURAL FIX (F-PASS4-C2 — canonical test path sweep):** `bats/`-prefixed path references replaced with canonical `tests/` form per the sweep-by-canonical-pattern discipline established in ARCH-INDEX v0.1.5. Functional coverage unchanged. [audit-trail]

**RETROACTIVE CLASSIFICATION (F-PASS12-I2 — SS-NN Changelog discipline):** This file had content edits past initial creation but remained at v1.0 without a Changelog section, escaping the Pass 9 / Pass 10-I2 discipline. Bumped to v1.1 with Changelog added per F-PASS12-I2 resolution. [audit-trail]

### v1.0 (2026-05-15)

Original Phase 1c subsystem design — adversarial review and writescore, 3-CLEAN cascade
protocol, cognitive-diversity adversary pattern, structured verdict JSON schema.
