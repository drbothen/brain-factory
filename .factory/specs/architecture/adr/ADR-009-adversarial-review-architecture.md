---
document_type: adr
id: ADR-009
title: "Adversarial review architecture: cognitive-diversity model family; fresh-context information asymmetry; BC-5.39.001 3-CLEAN"
status: accepted
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-16T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-009: Adversarial review architecture

## Context

brain-factory's cognitive-diversity adversarial review (KD-002) is not just a spec-phase quality gate — it is baked into the product itself via `/brain:adversary-review`. The same review pattern that drove the 23-pass Phase 1a cascade is shipped as a feature for users reviewing their briefs, syntheses, and published pieces.

The architecture must specify: which model family pairs are valid, what "fresh context" means in practice, how the BC-5.39.001 3-CLEAN protocol is implemented as a skill, and how this integrates with wclaude's four validation agents.

## Decision

### Model family diversity

BC-2.07.001: the adversary agent MUST run in a different model family than the producer agent. Default pairing for v0.x:
- Producer: Claude Sonnet (the operator's default session model)
- Adversary: Claude Opus (dispatched via the `adversary-review` skill's `allowed-tools` agent dispatch)

The distinction "different model family" means different capability tier within the Claude family (Sonnet vs Opus), not a different vendor. Research confirms that within-family model diversity (Opus reviewing Sonnet output) produces meaningful cognitive diversity — the larger model applies different reasoning patterns and catches different failure modes than the producing model.

### Fresh-context information asymmetry

The adversary agent receives:
- The artifact under review (brief, synthesis, published piece)
- The evaluation rubric (from the adversary-review skill's Iron Law and quality bar)
- NO prior conversation history with the producer agent

This information asymmetry is the architectural guarantee of independence. Implemented by dispatching the adversary agent in a fresh Agent call (not continuing the current conversation). The adversary's verdict cannot be influenced by the producer's self-assessment or explanation.

### BC-5.39.001 3-CLEAN protocol as a skill

`/brain:adversary-review <path>` implements the 3-CLEAN protocol for content artifacts:
1. Dispatch adversary agent (fresh context, Opus) with the artifact and rubric
2. Parse the structured verdict (BC-2.07.004): `{"verdict": "pass|fail", "findings": [...]}`
3. If pass: increment streak counter in `.brain/STATE.md`; if streak ≥ 3, declare convergence
4. If fail: reset streak to 0; surface findings; operator may revise and re-invoke
5. Emit structured event to `.brain/logs/review-YYYY-MM-DD.jsonl`

For spec artifacts (during the VSDD pipeline itself, not as a brain feature), the same protocol runs at the pipeline level (Phase 1d, Phase 5 adversarial refinement).

### wclaude four validation agents integration (BC-2.07.002)

`/brain:adversary-review` dispatches all four wclaude validation agents:
1. Frontmatter validation (checks title, tags, status, publication_date fields)
2. Voice analysis (checks against voice-avoid-list, tone consistency)
3. Structure review (checks section flow, ONE THING / PROOF / TRANSFORMATION adherence)
4. Platform compliance (checks LinkedIn character limits, link formatting, etc.)

Each agent returns a structured finding list. The adversary agent synthesizes all four finding lists into a single verdict. The full adversary pass report is written to `.brain/cycles/<period>/adversary-pass-NNN.md` for audit trail.

### Spec-level vs content-level adversarial review

The same architectural pattern applies at two levels:
- **Spec level (VSDD pipeline):** Phase 1d adversary reviews the full spec package (current PRD + architecture). Fresh-context Opus reads specs; adversary findings drive fix-bursts; 3-CLEAN convergence required before Phase 2.
- **Content level (brain feature):** `/brain:adversary-review` applies the same protocol to user content artifacts. Streak tracking lives in `.brain/STATE.md`.

## Consequences

**Positive:**
- Model family diversity is an architectural guarantee, not a best-effort recommendation
- Fresh-context dispatch ensures the adversary cannot be anchored by producer reasoning
- 3-CLEAN protocol is verifiable: streak counter in STATE.md is the machine-readable evidence (VP-010)
- The same pattern used to build brain-factory (23 Phase 1a passes) ships as a product feature

**Negative:**
- Opus dispatch costs more tokens than Sonnet (higher per-token price)
- 3-CLEAN convergence for a typical brief may require 2–4 invocations before streak ≥ 3

**Neutral:**
- The wclaude four-agent integration reuses patterns from the wclaude absorption (SL-6, SL-8)

## References

- KD-002 (cognitive-diversity adversarial review differentiator)
- SL-6, SL-8 (wclaude absorption decisions)
- BC-2.07.001 (different model family requirement)
- BC-2.07.002 (four wclaude validation agents)
- BC-2.07.003 (multi-pass writescore revision loop)
- BC-2.07.004 (structured pass/fail verdict)
- BC-5.39.001 (3-CLEAN protocol — VSDD pipeline protocol)
- VP-010 (adversarial cascade convergence verification property)

## Changelog

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS6-I2:** §Spec-level vs content-level (within §Decision) narrative cite corrected from "PRD v0.1.1 + architecture" to "PRD v0.1.6 + architecture". ARCH-INDEX v0.1.7 entry records: "ADR-009 §Decision (Spec-level vs content-level) corrected: 'PRD v0.1.1 + architecture' → 'PRD v0.1.6 + architecture'." [audit-trail]
- **F-PASS7-I1-arch:** §Spec-level vs content-level narrative cite further converted from "PRD v0.1.6 + architecture" to version-agnostic "current PRD + architecture". ARCH-INDEX v0.1.8 entry records: "ADR-009: 'PRD v0.1.6 + architecture' → 'current PRD + architecture'." [audit-trail]
