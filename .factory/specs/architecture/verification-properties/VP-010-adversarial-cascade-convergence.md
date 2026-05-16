---
document_type: verification-property
id: VP-010
title: "Adversarial 3-CLEAN convergence"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
verifies_bcs: [BC-2.07.001, BC-2.07.002, BC-2.07.003, BC-2.07.004]
created: 2026-05-15
status: proposed
---

# VP-010: Adversarial 3-CLEAN convergence

## Property Statement

Running `/brain:adversary-review <path>` on a production-quality artifact (brief, synthesis, or published piece that has been revised to address all prior adversary findings) produces a `{"verdict":"pass"}` on three consecutive invocations. The streak counter in `.brain/STATE.md` reaches and stays at 3. This is the BC-5.39.001 3-CLEAN protocol applied at the content level.

## Verification Mechanism

Adversary cascade protocol (not bats — this is a multi-agent protocol):

1. Write a known-good fixture artifact (brief that satisfies all four validation agent rubrics)
2. Run `/brain:adversary-review tests/fixtures/good-brief.md`
3. Assert verdict is `pass` (first pass)
4. Run `/brain:adversary-review tests/fixtures/good-brief.md` again (second pass)
5. Assert verdict is `pass` (second pass)
6. Run `/brain:adversary-review tests/fixtures/good-brief.md` again (third pass)
7. Assert verdict is `pass` (third pass)
8. Assert `.brain/STATE.md` streak counter = 3
9. Assert that a known-bad fixture (`tests/fixtures/bad-brief.md` with known voice violations) produces `verdict: fail` and streak resets to 0

The adversary must be dispatched in a fresh Agent context for each of the three passes (no conversation history shared between passes).

**Structural verification (bats-checkable):**
```bash
@test "adversary-review: structured verdict JSON schema" {
  # Mock adversary output for schema validation
  local verdict='{"verdict":"pass","streak":3,"findings":[],"pass_report":"..."}'
  run echo "$verdict" | jq -e '.verdict and (.streak | type == "number") and (.findings | type == "array")'
  assert_success
}

@test "adversary-review: streak counter in STATE.md after 3 passes" {
  # After simulating 3 clean passes via mock adversary
  local streak; streak="$(yq '.adversary_streak' "${TEMP_BRAIN}/.brain/STATE.md")"
  assert_equal "$streak" "3"
}
```

## Assumed Prerequisites

- Claude Code Opus model available for adversary dispatch
- `.brain/STATE.md` initialized
- Fixture artifacts: `tests/fixtures/good-brief.md` and `tests/fixtures/bad-brief.md`

## Counterexamples

- `/brain:adversary-review` uses the same model as the producer (violates BC-2.07.001 cognitive-diversity)
- The streak counter increments even when `verdict: fail` is returned (incorrect state machine)
- The adversary is dispatched in the same conversation context as the producer (no fresh-context information asymmetry — violates ADR-009)
- A known-bad artifact passes adversarial review (false positive — adversary effectiveness not validated)

## Status

proposed — pending Phase 3 implementation of adversary-review skill
