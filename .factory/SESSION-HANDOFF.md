---
artifact_type: session-handoff
project: brain-factory
session_phase: phase-1a-spec-crystallization
session_stage: stage-5-adversarial-review-cascade
current_brief_version: 0.4.14
current_brief_line_count: 786
current_brief_path: .factory/specs/product-brief.md
adversary_protocol: BC-5.39.001 3-CLEAN
current_streak: 2/3
current_pass_number: 21 (PASS — 0 CRITICAL, 0 IMPORTANT, 1 SUGGESTION, 1 OBSERVATION; second consecutive clean pass; Pass 22 pending toward 3/3 convergence)
pass_15_verdict: FAIL
pass_16_verdict: FAIL
pass_17_verdict: FAIL
pass_18_verdict: FAIL
pass_19_verdict: FAIL
pass_20_verdict: PASS
pass_21_verdict: PASS
total_passes_completed: 21
total_fix_bursts: 14
created: 2026-05-15
status: in-progress
---

# SESSION-HANDOFF — brain-factory Phase 1a

## 1. Where we are

We are mid-cascade in BC-5.39.001 3-CLEAN convergence on the brain-factory product brief
(greenfield Phase 1a). The brief at v0.4.14 (786 lines,
`.factory/specs/product-brief.md`) is structurally sound on substantive content.

Pass 19 returned FAIL with the FIRST CRITICAL finding of the cascade
(F-PASS19-C1, [process-gap]): the v0.4.13 Self-Audit Checklist enforcement gate
FAILED its own self-test. The gate command (a grep for literal line-number anchors
in the brief, excluding "WSL2") was supposed to return zero matches, but returned
two matches in the v0.4.13 changelog entry that introduced the gate. The recursion
of the narrow-fix-with-broad-announcement pattern reached fourth-level
(Pass 16 → Pass 17 → Pass 18 → Pass 19). Cultural-checklist enforcement
(read at delivery time by humans) is empirically proven structurally insufficient
to break this recursion class.

v0.4.14 fix-burst applied at commit 7035315 (786 lines): F-PASS19-C1 LOCAL closure
(rewrote the v0.4.13 changelog entry using a writing-technique principle —
describe literal-line-number defects in semantic terms, never quote the literal
token). F-PASS19-S1 gate hardening (added self-reference exclusion to the gate
command). The hardened gate now PASSES its own self-test cleanly (zero output).

**Pass 20 returned PASS** (0 CRITICAL, 0 IMPORTANT, 1 SUGGESTION, 1 OBSERVATION). **Streak: 1/3** — first clean pass since Pass 12 (eight passes ago). The fourth-level recursion of the narrow-fix-with-broad-announcement pattern is structurally closed via the v0.4.14 writing-technique principle and gate hardening. The hardened Self-Audit Checklist enforcement command returns zero output cleanly. F-PASS20-S1 (extend gate to cover handoff) and F-PASS20-O1 (soften historical claim wording) are non-blocking SUGGESTION/OBSERVATION-grade and will bundle into the next applicable fix-burst rather than triggering a v0.4.15 burst on their own.

**Pass 21 returned PASS** (0 CRITICAL, 0 IMPORTANT, 1 SUGGESTION [F-PASS21-S1: gate exclusion-list commentary improvement], 1 OBSERVATION [F-PASS21-O1: SL-1 handoff paraphrase drift — TypeScript not in stage-3-locks.md; corrected in THIS commit]). **Streak: 2/3** — second consecutive clean pass. ONE pass away from 3/3 convergence (the cascade goal). The recursion class remains structurally closed (gate self-test clean on both brief and handoff). F-PASS21-S1 (brief edit) deferred to post-convergence cleanup or next applicable fix-burst. Next step: Pass 22 fresh-context adversary dispatch (Task #52) toward 3/3.

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
| 17 | v0.4.11 (771 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT | 0/3 | F-PASS17-I1 process-gap (v0.4.11 audit-trail completeness claim overbroad — v0.4.8 has 2 unlabeled structural-fix bullets); recurrence of "narrow-fix announced broadly" pattern |
| 17+fix | v0.4.12 (776 lines) | FIX-APPLIED | (n/a — fix-burst) | 0/3 | F-PASS17-I1 audit-trail back-fill (10 STRUCTURAL FIX headings; v0.4.8 entries promoted); F-PASS17-S1 semantic anchors at §SL-9/§SL-10; F-PASS17-S2 cross_platform flatten |
| 18 | v0.4.12 (776 lines) | FAIL | 0 CRITICAL, 1 IMPORTANT (process-gap) | 0/3 | F-PASS18-I1 third-level recursion: v0.4.12 changelog entry cites a literal line-number anchor; regresses v0.4.10 STRUCTURAL FIX (Changelog audit-trail discipline); cross-doc breach in handoff §5 |
| 18+fix | v0.4.13 (782 lines) | FIX-APPLIED | (n/a — fix-burst) | 0/3 | F-PASS18-I1 closed (local + brief-level enforcement via new Self-Audit Checklist item); F-PASS18-S1 closed; F-PASS18-O2 closed (sibling-sweep); recursion broken at writing layer |
| 19 | v0.4.13 (782 lines) | FAIL | 1 CRITICAL, 1 IMPORTANT | 0/3 | F-PASS19-C1 4th-level recursion: v0.4.13 enforcement gate fails own self-test; F-PASS19-I1 handoff sibling-sweep gap |
| 19+fix | v0.4.14 (786 lines) | FIX-APPLIED | (n/a — fix-burst) | 0/3 | F-PASS19-C1 LOCAL closure via writing-technique principle (no literal-line-number-token quotations); F-PASS19-S1 gate hardening (self-reference exclusion); hardened gate passes own self-test |
| 20 | v0.4.14 (786 lines) | **PASS** | 0 CRITICAL, 0 IMPORTANT | **1/3** | First clean pass since Pass 12; recursion class structurally closed; F-PASS20-S1 (handoff coverage gap) + F-PASS20-O1 (historical wording) non-blocking; bundle into next applicable fix-burst |
| 21 | v0.4.14 (786 lines, unchanged) | **PASS** | 0 CRITICAL, 0 IMPORTANT | **2/3** | Second consecutive clean pass; recursion class stable; F-PASS21-S1 (brief; deferable) + F-PASS21-O1 (handoff §4 SL-1 TypeScript drift; CORRECTED this commit) |

## 3. Key state

- **Brief:** `.factory/specs/product-brief.md` (v0.4.14, 786 lines)
- **Streak:** **2/3** (Pass 20 + Pass 21 PASS)
- **Pass 21 dispatch status:** COMPLETE — **PASS** (0 CRITICAL + 0 IMPORTANT + 1 SUGGESTION + 1 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-21.md`. Recursion depth: 0 (structurally closed across two consecutive passes).
- **Pass 20 dispatch status:** COMPLETE — **PASS** (0 CRITICAL + 0 IMPORTANT + 1 SUGGESTION + 1 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-20.md`. Recursion depth observed: 0 (structurally closed).
- **Pass 19 dispatch status:** COMPLETE — FAIL (1 CRITICAL [process-gap, 4th-level recursion] + 1 IMPORTANT + 1 SUGGESTION + 1 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-19.md`.
- **Pass 18 dispatch status:** COMPLETE — FAIL (1 IMPORTANT + 2 SUGGESTION + 2 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-18.md`.
- **Pass 17 dispatch status:** COMPLETE — FAIL (1 IMPORTANT + 2 SUGGESTION + 2 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-17.md` (373 lines).
- **Pass 16 dispatch status:** COMPLETE — FAIL (3 IMPORTANT + 1 SUGGESTION + 1 OBSERVATION). Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-16.md` (408 lines).
- **Pass 15 dispatch status:** COMPLETE — FAIL (1 IMPORTANT + 2 SUGGESTION + 2 OBSERVATION).
  Report at `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-15.md` (375 lines).
- **Fix bursts applied:** 14 total (v0.2.0 → v0.3.0, v0.3.0 → v0.4.0, v0.4.0 → v0.4.1,
  v0.4.1 → v0.4.2-final, v0.4.2-final → v0.4.3, v0.4.3 → v0.4.4, v0.4.4 → v0.4.5/v0.4.6,
  v0.4.6 → v0.4.7, v0.4.7 → v0.4.8/v0.4.9, v0.4.9 → v0.4.10, v0.4.10 → v0.4.11, v0.4.11 → v0.4.12, v0.4.12 → v0.4.13, v0.4.13 → v0.4.14)

## 4. Locked decisions (canonical sources)

All user-locked decisions from Stage 3 elicitation are persisted at:
`.factory/planning/stage-3-locks.md` — 11 locks (SL-1 through SL-11):

- SL-1: Toolchain — Node 20+
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
| v0.4.5 | Grep-anchored references in Self-Audit Checklist | Line-number drift after edits |
| v0.4.6 | Creation-date anchors in Traceability section | Line-count drift (wc-l vs Read tool) |
| v0.4.7 | "See Changelog" reference in Self-Audit attestation | Per-version-attestation drift |
| v0.4.8 | Sibling-sweep "phased plan §X" → "phased-build-plan §X" | Citation-shorthand drift |
| v0.4.10 | Grep-anchored discipline extended to Changelog block | Stale-line-citation drift in Changelog audit-trail (F-PASS15-S1/S2 class) |
| v0.4.11 | Semantic labels replace ordinal cascade count in v0.4.10 entry + grep-verified citation shorthand sibling-sweep at 2 callsites (F-PASS16-I1/I2/I3 closure) | Count-drift class in structural-fix audit-trail; partial-sibling-sweep regression class (F-PASS16-I1/I2) |
| v0.4.12 | (a) v0.4.8 changelog bullets back-filled with STRUCTURAL FIX headings; v0.4.11 'all structural-fix headings' coverage claim sharpened (b) semantic anchor cleanup at v0.9 ship gate (§SL-9/§SL-10 references) | Audit-trail completeness drift (narrow-fix-with-broad-announcement recurrence class) |
| v0.4.13 | (a) Local fix: v0.4.12 changelog literal line-number anchor → semantic anchor (b) ENFORCEMENT: new Self-Audit Checklist item asserting `grep \bL[0-9]+\b ... | grep -v WSL2` clean before commit — converts v0.4.10 cultural claim to brief-level enforced | Third-level recursion of narrow-fix-broad-announcement pattern; v0.4.10 audit-trail discipline regression |
| v0.4.14 | (a) Local closure of fourth-level recursion using writing-technique principle: describe literal-line-number defects in semantic terms, never quote the literal token (b) Gate hardening: added self-reference exclusion to the Self-Audit Checklist enforcement command | Fourth-level recursion of narrow-fix-with-broad-announcement (cultural-checklist enforcement empirically insufficient) |

Each structural fix worked — those defect classes are gone permanently. But new
sibling-sweep gaps in other cross-section dimensions keep emerging.

- Pass 13 caught Timeline-vs-Scope skill count drift (12 vs 13)
- Pass 14 caught bats file count gate-vs-scope drift (10 vs 9)
- Pass 15 caught scripts/gen-test-corpus.sh gate-vs-scope drift (3rd instance of same class)

Pass 15 surfaced a 4th structural fix candidate; v0.4.10 applied it (extending
grep-anchor discipline to the Changelog block).

Pass 16 surfaced two new defect classes: (a) F-PASS16-I1/I2 — 3 prior-pass fixes (F-PASS10-O2 / F-PASS12-O1 / F-PASS13-O1) silently regressed at 2 callsites despite v0.4.8 "at all callsites" claim — demonstrates that trusted-as-resolved findings need fresh-grep re-verification; (b) F-PASS16-I3 — ordinal cascade-counter labels are themselves count-drift-prone; semantic labels eliminate the class. v0.4.11 closes both classes: semantic-label discipline eliminates the count-drift class; grep-verified sibling-sweep with pre-commit verification eliminates the trusted-as-resolved regression class.

Pass 17 surfaces a recursive pattern: fixes that announce broad coverage (v0.4.8 "at all callsites"; v0.4.11 "all structural-fix headings") often deliver narrow coverage. v0.4.12 closes the audit-trail completeness drift class by back-filling all missing STRUCTURAL FIX headings (10 total now in the Changelog block) and sharpening the v0.4.11 coverage claim. The narrow-fix-with-broad-announcement recurrence pattern is structurally addressed — future structural fixes must declare the STRUCTURAL FIX heading at write-time.

v0.4.13 closes the recursion structurally — the new Self-Audit Checklist enforcement item makes the v0.4.10 'permanent elimination' claim machine-verifiable. Future fix-bursts cannot reintroduce literal line-number anchors in the brief without failing the Self-Audit Checklist gate.

Pass 19 surfaced the cascade's first CRITICAL finding — empirically proving that cultural-checklist enforcement is structurally insufficient at fourth-level recursion. v0.4.14 broke the recursion at the writing layer via a writing-technique principle. v0.4.15 (if needed) escalates to a write-time machine-enforced hook script.

Pass 20 is the first clean pass since Pass 12. The recursion class is structurally closed at recursion depth 0. The cascade is now converging toward 2/3 then 3/3.

Pass 21 confirms two consecutive clean passes (streak 2/3). Pass 22 will determine 3/3 convergence.

## 6. Open questions for next session

**Pass 21 PASSED. Streak 2/3.** Next step: Pass 22 fresh-context adversary dispatch (Task #52) toward 3/3. Do NOT trigger a v0.4.15 fix-burst — F-PASS21-S1/O1 are non-blocking; F-PASS21-O1 is corrected in THIS commit (handoff §4 SL-1 TypeScript drop); F-PASS21-S1 (brief edit) bundles into post-convergence cleanup.

**Question for human review (escalation — not triggered by Pass 20):** Should v0.4.15 escalate to a write-time machine-enforced hook script (e.g., `.factory/hooks/validate-changelog-anchors.sh` invoked by lefthook or factory-dispatcher), or continue with the writing-technique principle alone? The Pass 19 adversary recommended machine enforcement; Pass 20 did NOT surface a fifth-level recursion, so the escalation question remains open for human adjudication but is not presently triggered.

**Question for human review when resuming:**
- After convergence (3 consecutive clean passes), should the brief move directly to PRD phase or is there a human review gate first?

## 7. Artifacts on disk (all persisted)

| Artifact | Version | Lines |
|----------|---------|-------|
| `.factory/specs/product-brief.md` | v0.4.14 | 786 |
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
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-17.md` | Pass 17 | 373 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-18.md` | Pass 18 | 193 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-19.md` | Pass 19 | 169 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-20.md` | Pass 20 | 167 |
| `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-21.md` | Pass 21 | 159 |
| `CLAUDE.md` | amended Node 20+ | 592 |

**Note on git history:** Not all fix-burst commits are present in git. The orchestrator
committed pass reports separately from fix bursts; several fix-burst commits that
advanced the brief version are missing from the log (the brief on disk at v0.4.14 is
authoritative — it is ahead of what the commit log reflects). The 14 commits in git
history are enumerated in §8.

## 8. Recent commits (most recent first)

| SHA | Message |
|-----|---------|
| (this commit) | factory(adversary): persist Pass 21 PASS + correct F-PASS21-O1 handoff §4 SL-1 paraphrase; streak 2/3 |
| 5c54640 | factory(adversary): persist Pass 20 PASS — first clean pass since Pass 12; recursion class structurally closed; streak 1/3 |
| c0297f9 | factory(adversary): persist Pass 19 FAIL + handoff sibling-sweep + v0.4.14 state refresh |
| 7035315 | factory(spec): bump brief to v0.4.14 — F-PASS19-C1 4th-level-recursion closure (writing-technique principle + gate hardening) |
| 4b2f357 | factory(handoff): backfill Pass 18 commit SHA in §8 commit log |
| ea9b314 | factory(adversary): persist Pass 18 FAIL + v0.4.13 state refresh + F-PASS18-S2/O1 + handoff §5 sibling-sweep |
| 2e5f3b2 | factory(spec): bump brief to v0.4.13 — F-PASS18-I1 third-level-recursion closure (local fix + Self-Audit enforcement) + S1/O2 |
| e41e3a9 | factory(handoff): refresh state for v0.4.12 fix-burst completion — unblock Pass 18 |
| ed6e705 | factory(spec): bump brief to v0.4.12 — F-PASS17-I1 audit-trail back-fill + S1/S2 (semantic anchors + cross_platform flatten) |
| 74af72b | factory(adversary): persist Pass 17 FAIL + correct handoff §5 v0.4.11 row (F-PASS17-O2) |
| 5e4d419 | factory(handoff): refresh state for v0.4.11 fix-burst completion — unblock Pass 17 |
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
commits — the brief on disk at v0.4.14 is the authoritative artifact.

## 9. Resume procedure

1. Read THIS file end-to-end.
2. Read `.factory/specs/product-brief.md` (v0.4.14, 786 lines).
3. Read `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-21.md` (Pass 21 PASS — second consecutive clean).

**Pass 21 PASSED. Streak 2/3. ONE pass away from convergence.** Dispatch Pass 22 per Task #52:

4. Dispatch fresh-context adversary using Pass 22 template.
5. On adversary verdict:
   - PASS (0 CRITICAL + 0 IMPORTANT) → **streak 3/3 → CASCADE CONVERGED** → record verdict via state-manager → mark Task #6 (Stage 6 Finalize) ready → bundle deferred findings (F-PASS20-S1/O1, F-PASS21-S1/O1) into Task #53 (post-convergence cleanup) → on cleanup completion, advance Phase 1a → Phase 1b (PRD phase).
   - FAIL → record verdict via state-manager → streak 0/3 RESET → v0.4.15 fix-burst (bundle all deferred findings) → restart cascade from 0/3.
6. Continue per BC-5.39.001 strict protocol.

**Note for Pass 22 adversary:** Pass 21 confirmed recursion class is closed across two consecutive passes. Pass 22 should re-verify (gate self-test clean) AND apply fresh-context novelty hunt for any defect-class the prior 21 passes missed. Pass 22 IS the convergence test — even one new IMPORTANT resets the streak to 0/3.

**Pass 22 dispatch template (CONVERGENCE TEST):**

> You are a fresh-context adversary reviewer for the brain-factory product brief.
> Your task: BC-5.39.001 3-CLEAN pass 22 — CONVERGENCE TEST (streak 2/3; one PASS ends the cascade).
> Target: `.factory/specs/product-brief.md` (v0.4.14, 786 lines).
> Prior passes: read `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-21.md`.
> Inputs: product-brief.md, pass-21.md, stage-3-locks.md, elicitation-notes.md,
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
