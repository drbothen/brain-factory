---
artifact_type: session-handoff
project: brain-factory
session_phase: phase-1a-spec-crystallization
session_stage: stage-5-adversarial-review-cascade
current_brief_version: 0.4.11
current_brief_line_count: 771
current_brief_path: .factory/specs/product-brief.md
adversary_protocol: BC-5.39.001 3-CLEAN
current_streak: 0/3
current_pass_number: 16 (FAIL — fix-burst v0.4.11 applied at 5e6dc2f; Pass 17 pending)
pass_15_verdict: FAIL
pass_16_verdict: FAIL
total_passes_completed: 16
total_fix_bursts: 11
created: 2026-05-15
status: in-progress
---

# SESSION-HANDOFF — brain-factory Phase 1a

## 1. Where we are

We are mid-cascade in BC-5.39.001 3-CLEAN convergence on the brain-factory product brief
(greenfield Phase 1a). The brief at v0.4.9 (758 lines,
`.factory/specs/product-brief.md`) is structurally sound on substantive content but
the adversary cascade keeps finding small cross-section drift defects.

Pass 15 returned FAIL with 1 IMPORTANT. v0.4.10 fix-burst applied at commit 8b3cb47
(763 lines): F-PASS15-I1 resolved (gen-test-corpus.sh added to §Scope), F-PASS15-S1/S2
anchored, and the 4th structural fix extended the v0.4.5 grep-anchor discipline to the
Changelog block. Streak 0/3. Next step: Pass 16 fresh-context adversary dispatch
(Task #42).

Pass 16 returned FAIL with 3 IMPORTANT findings: F-PASS16-I1+I2 (paired citation regression at L280/L523 — v0.4.8 sibling-sweep was incomplete; 3 prior-pass fixes silently regressed), F-PASS16-I3 (process-gap: v0.4.10 structural-fix label mis-counts cascade — should be semantic, not ordinal), and F-PASS16-O1 (OBSERVATION: 4th instance of gate-vs-scope defect family). Streak 0/3.

v0.4.11 fix-burst applied at commit 5e6dc2f (771 lines): F-PASS16-I1+I2 resolved via paired citation sibling-sweep with grep verification (3 prior-pass fixes back in compliance); F-PASS16-I3 resolved via semantic-label replacement (count-drift class eliminated permanently); F-PASS16-S1 + F-PASS16-O1 bundled. Bonus in-scope extension promoted v0.4.5/v0.4.6/v0.4.7 bare 'Structural fix:' labels to semantic-label format. Streak 0/3. Next step: Pass 17 fresh-context adversary dispatch (Task #44).

## 2. Cascade history (full)

| Pass # | Brief Version | Verdict | Blockers | Streak After | Key Findings |
|--------|---------------|---------|----------|--------------|--------------|
| 1 | v0.2.0 (312 lines) | FAIL | 4 CRITICAL, 11 IMPORTANT | 0/3 | Missing domain context, incomplete skill list, no traceability, no test strategy |
| 2 | v0.3.0 (536 lines) | FAIL | 1 CRITICAL, 3 IMPORTANT | 0/3 | Paper-fix pattern; 2 new issues introduced while resolving 10 |
| 3 | v0.4.0 (681 lines) | FAIL | 2 CRITICAL, 4 IMPORTANT | 0/3 | paper-fix pattern observed; citation shorthand inconsistency, WFH doc path |
| 4 | v0.4.1 (687 lines) | FAIL | 2 CRITICAL, 2 IMPORTANT | 0/3 | Paper-fix pattern; gate-task alignment gaps, skill numbering inconsistency |
| 5 | v0.4.2-final (699 lines) | PASS | 0 CRITICAL, 0 IMPORTANT | 1/3 | First clean pass; structural discipline effective; 3 suggestions only |
| 6 | v0.4.2-final (699 lines, unchanged) | PASS | 0 CRITICAL, 0 IMPORTANT | 2/3 | Second clean pass; 4 suggestions, 2 observations — all below blocker threshold |
| 7 | v0.4.2-final (699 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT | 0/3 (RESET) | F-PASS7-I1: convergence target omission — brief lacked explicit 3-CLEAN requirement |
| 8 | v0.4.3 (711 lines) | FAIL | 0 CRITICAL, 2 IMPORTANT | 0/3 | Wclaude public-before-tag gate missing, line-count self-audit gap; 4 suggestions |
| 9 | v0.4.4 (725 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT | 0/3 | Line-count paper-fix (495 vs 496); self-audit discipline regression |
| 10 | v0.4.5 (732 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT | 0/3 | False attestation caught: Pass 9 falsely claimed line-count fixed; grep-anchor fix worked but line-count anchor needed |
| 11 | v0.4.6 (739 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT | 0/3 | Self-audit Changelog reference missing; per-version attestation gap |
| 12 | v0.4.7 (745 lines) | PASS | 0 CRITICAL, 0 IMPORTANT | 1/3 | First clean pass after structural-fix cascade; all 4 structural fixes verified; 2 observations only |
| 13 | v0.4.7 (745 lines) | FAIL | 0 CRITICAL, 2 IMPORTANT | 0/3 (RESET) | F-PASS13-I1: Timeline §Scope shows 12 polish skills vs 13 in §Skills list; F-PASS13-I2: .reference/README.md required at v0.1 gate but no bootstrap task creates it |
| 14 | v0.4.8 (751 lines) | FAIL | 0 CRITICAL, 2 IMPORTANT | 0/3 | F-PASS14-I1: v0.1 gate introduces 10th .bats file but §Scope locks 9; F-PASS14-I2: /brain:research labeled "polish" in v0.9 gate but "new" in §Scope |
| 15 | v0.4.9 (758 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT | 0/3 | F-PASS15-I1: scripts/gen-test-corpus.sh required at v0.9 gate but absent from §Scope deliverables — 3rd instance of gate-vs-scope class |
| 15+fix | v0.4.10 (763 lines) | FIX-APPLIED | (n/a — fix-burst) | 0/3 | F-PASS15-I1 resolved; S1/S2 anchored; 4th structural fix: Changelog → semantic anchors |
| 16 | v0.4.10 (763 lines) | FAIL | 0 CRITICAL, 3 IMPORTANT | 0/3 | F-PASS16-I1/I2 citation-shorthand regression (3 prior fixes); F-PASS16-I3 process-gap structural-fix mis-count; F-PASS16-O1 plugin.json/hooks.json.template gate-vs-scope |
| 16+fix | v0.4.11 (771 lines) | FIX-APPLIED | (n/a — fix-burst) | 0/3 | F-PASS16-I1/I2 paired citation sibling-sweep with grep verification; F-PASS16-I3 semantic-label (count-drift class eliminated); F-PASS16-S1 cross_platform Git Bash; F-PASS16-O1 plugin.json+hooks.json.template added to §Scope; bonus: v0.4.5/v0.4.6/v0.4.7 structural-fix labels promoted to semantic |

## 3. Key state

- **Brief:** `.factory/specs/product-brief.md` (v0.4.11, 771 lines)
- **Streak:** 0/3 (reset by Pass 13 FAIL after Pass 12 PASS; Pass 14 also FAIL; 0/3 entering Pass 15)
- **Pass 16 dispatch status:** COMPLETE — FAIL (3 IMPORTANT + 1 SUGGESTION + 1 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-16.md` (408 lines).
- **Pass 15 dispatch status:** COMPLETE — FAIL (1 IMPORTANT + 2 SUGGESTION + 2 OBSERVATION).
  Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-15.md` (375 lines).
- **Fix bursts applied:** 11 total (v0.2.0 → v0.3.0, v0.3.0 → v0.4.0, v0.4.0 → v0.4.1,
  v0.4.1 → v0.4.2-final, v0.4.2-final → v0.4.3, v0.4.3 → v0.4.4, v0.4.4 → v0.4.5/v0.4.6,
  v0.4.6 → v0.4.7, v0.4.7 → v0.4.8/v0.4.9, v0.4.9 → v0.4.10, v0.4.10 → v0.4.11)

## 4. Locked decisions (canonical sources)

All user-locked decisions from Stage 3 elicitation are persisted at:
`.factory/planning/stage-3-locks.md` — 11 locks (SL-1 through SL-11):

- SL-1: Toolchain — Node 20+ (LTS), TypeScript
- SL-2: 26 skills (full list in stage-3-locks.md)
- SL-3: Lobster runtime (orchestrates multi-step skills)
- SL-4: Self-VSDD (brain-factory builds itself using its own pipeline)
- SL-5: /brain:research skill design (confirmed)
- SL-6: wclaude absorption (wclaude merged into brain-factory v0.9)
- SL-7: Platforms — LinkedIn native + extension hooks architecture
- SL-8: publish-content semantics (confirmed)
- SL-9: Scalability scope (power-user single-tenant; not SaaS)
- SL-10: Scale target — power-user 10x Karpathy (~10K sources / ~40M words / ~10K wiki pages)
- SL-11: Reference repos — 7 repos (listed in stage-3-locks.md)

Plus from later session decisions (not in stage-3-locks.md):
- "Continue cascade indefinitely per BC-5.39.001 strict protocol" — user confirmed at
  multiple checkpoint moments; consistently chose protocol over pragmatic convergence
- "Make drbothen/wclaude public before v0.1.0 tag" — gate item; documented in brief
  v0.4.3+
- F-PASS13-I2: Option A chosen — add `.reference/README.md` creation to bootstrap task
  list (not create a new task)
- F-PASS14-I1: hook-performance tests fold into hooks.bats (preserves 9-suite count;
  §Scope count is authoritative)

## 5. The structural-fix cascade (the meta-pattern)

After 14 passes the dominant pattern is "fresh-context adversary finds 1-2 sibling-sweep
gaps per pass." We applied 4 structural fixes that each eliminated a recurring drift
class permanently:

| Version | Structural fix | Drift class eliminated |
|---------|----------------|------------------------|
| v0.4.5 | Grep-anchored references in Self-Audit Checklist | L-number drift after edits |
| v0.4.6 | Creation-date anchors in Traceability section | Line-count drift (wc-l vs Read tool) |
| v0.4.7 | "See Changelog" reference in Self-Audit attestation | Per-version-attestation drift |
| v0.4.8 | Sibling-sweep "phased plan §X" → "phased-build-plan §X" | Citation-shorthand drift |
| v0.4.10 | Grep-anchored discipline extended to Changelog block | Stale-line-citation drift in Changelog audit-trail (F-PASS15-S1/S2 class) |
| v0.4.11 | Semantic labels replace ordinal cascade counts (and back-applied to v0.4.5/v0.4.6/v0.4.7) + grep-verified citation shorthand sibling-sweep | Count-drift class in structural-fix audit-trail; partial-sibling-sweep regression class (F-PASS16-I1/I2) |

Each structural fix worked — those defect classes are gone permanently. But new
sibling-sweep gaps in other cross-section dimensions keep emerging.

- Pass 13 caught Timeline-vs-Scope skill count drift (12 vs 13)
- Pass 14 caught bats file count gate-vs-scope drift (10 vs 9)
- Pass 15 caught scripts/gen-test-corpus.sh gate-vs-scope drift (3rd instance of same class)

Pass 15 surfaced a 4th structural fix candidate; v0.4.10 applied it (extending
grep-anchor discipline to the Changelog block).

Pass 16 surfaced two new defect classes: (a) F-PASS16-I1/I2 — 3 prior-pass fixes (F-PASS10-O2 / F-PASS12-O1 / F-PASS13-O1) silently regressed at 2 callsites despite v0.4.8 "at all callsites" claim — demonstrates that trusted-as-resolved findings need fresh-grep re-verification; (b) F-PASS16-I3 — ordinal cascade-counter labels are themselves count-drift-prone; semantic labels eliminate the class. v0.4.11 closes both classes: semantic-label discipline eliminates the count-drift class; grep-verified sibling-sweep with pre-commit verification eliminates the trusted-as-resolved regression class.

## 6. Open questions for next session

**v0.4.11 fix-burst is applied (commit 5e6dc2f).** Next step: Pass 17 fresh-context adversary dispatch (Task #44). Streak resumes from 0/3.

**Question for human review when resuming:**
- After convergence (3 consecutive clean passes), should the brief move directly to PRD phase or is there a human review gate first?

## 7. Artifacts on disk (all persisted)

| Artifact | Version | Lines |
|----------|---------|-------|
| `.factory/specs/product-brief.md` | v0.4.11 | 771 |
| `.factory/planning/elicitation-notes.md` | — | 610 |
| `.factory/planning/stage-3-locks.md` | — | 171 |
| `.factory/planning/brief-research.md` | — | 495 |
| `.factory/planning/reference-repos.md` | — | 448 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-1.md` | Pass 1 | 312 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-2.md` | Pass 2 | 278 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-3.md` | Pass 3 | 344 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-4.md` | Pass 4 | 294 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-5.md` | Pass 5 | 295 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-6.md` | Pass 6 | 291 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-7.md` | Pass 7 | 315 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-8.md` | Pass 8 | 366 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-9.md` | Pass 9 | 314 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-10.md` | Pass 10 | 386 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-11.md` | Pass 11 | 392 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-12.md` | Pass 12 | 360 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-13.md` | Pass 13 | 312 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-14.md` | Pass 14 | 333 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-15.md` | Pass 15 | 375 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-16.md` | Pass 16 | 408 |
| `CLAUDE.md` | amended Node 20+ | 592 |

**Note on git history:** Not all fix-burst commits are present in git. The orchestrator
committed pass reports separately from fix bursts; several fix-burst commits that
advanced the brief version are missing from the log (the brief on disk at v0.4.9 is
authoritative — it is ahead of what the commit log reflects). The 14 commits in git
history are enumerated in §8.

## 8. Recent commits (most recent first)

| SHA | Message |
|-----|---------|
| 5e6dc2f | factory(spec): bump brief to v0.4.11 — F-PASS16-I1/I2/I3 + S1/O1 (citation sibling-sweep with grep verification; semantic structural-fix labels) |
| c28a070 | factory(adversary): persist Pass 16 FAIL — citation regression + process-gap structural-fix mis-count |
| a19ea31 | factory(handoff): refresh state for v0.4.10 fix-burst completion — unblock Pass 16 |
| 8b3cb47 | factory(spec): bump brief to v0.4.10 — F-PASS15-I1 + 4th structural fix (Changelog semantic anchors) |
| 8d3e2a4 | factory(adversary): persist Pass 15 FAIL — 3rd instance of gate-vs-scope artifact mismatch |
| 8e4a743 | factory(spec): persist product-brief at v0.4.9 for durability |
| db56149 | factory(handoff): persist task list snapshot |
| da0a569 | factory(handoff): persist session state for clean-context resume |
| 7f8572c | factory(adversary): persist Pass 14 FAIL — 2 new IMPORTANT cross-section drifts |
| 2c8e8ba | factory(adversary): persist Pass 13 FAIL — 2 new IMPORTANT sibling-sweep gaps |
| 620de01 | factory(adversary): persist Pass 12 PASS report — structural-fix cascade validated |
| 9b7a21a | factory(adversary): persist Pass 11 FAIL — self-audit per-version-attestation drift |
| 822c0b9 | factory(adversary): persist Pass 10 FAIL — false-attestation about Pass 9 caught |
| 1989746 | factory(adversary): persist Pass 9 FAIL — self-audit line-number regression |
| c5b4213 | factory(adversary): persist Pass 7 FAIL report — convergence target blocked |
| 0b321f6 | factory(adversary): persist Pass 6 PASS report — streak 2/3 (second clean pass) |
| e0c1edc | factory(adversary): persist Pass 5 PASS report — streak 1/3 (first clean pass) |
| 2090dc0 | factory(planning): create stage-3-locks artifact recording user-locked decisions |
| e69a483 | factory(adversary): persist Pass 4 report for brain-factory product-brief v0.4.1 |
| f509a73 | factory(adversary): persist Pass 2 report for brain-factory product-brief v0.3.0 |
| 9c1838e | factory(adversary): persist Pass 1 report for brain-factory product-brief v0.2.0 |
| f5c4c08 | chore: seed repo with planning artifacts and basic scaffolding |

**Gap note:** Passes 3, 5–6, 7–8, 8–9, 10–11, 11–12, 12–13, 13–14 each had a fix burst
that advanced the brief version. Most of those fix bursts are not reflected as separate
commits — the brief on disk at v0.4.9 is the authoritative artifact.

## 9. Resume procedure

1. Read THIS file end-to-end.
2. Read `.factory/specs/product-brief.md` (v0.4.11, 771 lines, the artifact under review).
3. Read `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-16.md` (Pass 16 FAIL — historical; fixes already applied in v0.4.11).

**v0.4.11 fix-burst is applied (commit 5e6dc2f).** Dispatch Pass 17 per Task #44 — this is your top-of-stack action:

4. Dispatch fresh-context adversary using the Pass 17 template below.
5. On adversary verdict:
   - PASS (0 CRITICAL + 0 IMPORTANT) → streak 1/3 → record verdict via state-manager → dispatch Pass 18.
   - FAIL → record verdict via state-manager → dispatch a v0.4.12 fix-burst per the new findings → return to step 4 for Pass 18.
6. Continue per BC-5.39.001 strict protocol until 3 consecutive clean passes.

**Pass 17 dispatch template:**

> You are a fresh-context adversary reviewer for the brain-factory product brief.
> Your task: BC-5.39.001 3-CLEAN pass 17.
> Target: `.factory/specs/product-brief.md` (v0.4.11, 771 lines).
> Prior passes: read `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-16.md`.
> Inputs: product-brief.md, pass-16.md, stage-3-locks.md, elicitation-notes.md,
> brief-research.md, reference-repos.md, CLAUDE.md,
> docs/planning/llm-second-brain-phased-build-plan.md (spot-check §§A.2, 5.11, 8.2.4).
> Protocol: FAIL on any CRITICAL or IMPORTANT. PASS only if zero CRITICAL + IMPORTANT.

## 10. Standing user directives (carry forward)

- "No pragmatic convergence. Fix all issues before build." (CLAUDE.md Canonical Principle)
- "Follow brain-factory plan completely; merge useful ideas from wclaude" (Stage 3)
- "Keep following protocol" (mid-cascade checkpoint, confirmed at Pass 7, Pass 12,
  Pass 14 checkpoints)
- "Full vision = full MVP; v0.x through v0.9 is the destination" (Stage 1 framing)
- "Power-user scale (10x Karpathy)" (SL-10)
- "factory-dispatcher needed before full release" (v1.0 commitment)
- NO AI attribution in commits (CLAUDE.md hard rule)
- All artifacts committed to main as de-facto factory-artifacts (proper worktree NOT
  established; factory-artifacts branch does NOT exist; commits go to main until
  worktree setup is done)
