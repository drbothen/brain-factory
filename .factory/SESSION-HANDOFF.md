---
artifact_type: session-handoff
project: brain-factory
session_phase: phase-1d-adversarial-spec-review
session_stage: phase-1d-cascade-pass-13-closed-ready-for-pass-14
current_brief_version: 0.4.19
current_brief_path: .factory/specs/product-brief.md
current_prd_version: 0.1.9
current_prd_path: .factory/specs/prd/index.md
current_bc_index_path: .factory/specs/behavioral-contracts/BC-INDEX.md
current_bc_index_version: 0.1.8
current_architecture_version: 0.1.15
current_arch_index_path: .factory/specs/architecture/ARCH-INDEX.md
current_vp_index_version: 0.1.6
total_bc_count: 95
total_adr_count: 17
total_ss_design_count: 18
total_vp_count: 27
p0_vp_coverage: "64/64 P0 BCs covered"
phase_1b_completion_commit: 7935faa
phase_1b_initial_commit: 23e3a91
phase_1c_completion_commits: [b7679ee, 7e8f96f, cd6c3ba, 1a10e45, d89ea4b]
adversary_protocol: BC-5.39.001 3-CLEAN
current_streak: "0/3 (reset after Pass 7 FAIL; has not recovered)"
current_pass_number: 13 (FAIL — 2C+3I+2O; persist commit a2fab66; architect 52b7f19; state-mgr FINAL this commit)
phase_1b_status: COMPLETED — PRD v0.1.1 landed; consistency audit closed; Phase 1c authorized
phase_1c_status: COMPLETED — architecture v0.1.1 + SS-NN backfill across BCs/PRD/BC-INDEX; consistency audit closed; five-file gate canonical; 64/64 P0 BC VP coverage
phase_1d_status: IN-PROGRESS — 13 passes complete; 28+ fix-bursts committed; streak 0/3; Pass 13 closed; ready for Pass 14 (chat-only adversary dispatch per F-PASS12-O1)
cascade_status: CLOSED — v0.4.15 is the final Phase 1a Stage 5 artifact
total_passes_completed: 23
total_fix_bursts: 15
total_phase_1d_passes_completed: 13
total_phase_1d_fix_bursts: 28 (Pass 13: architect 52b7f19 + state-mgr FINAL this commit; no PO burst)
phase_1d_pass_1_verdict: FAIL
phase_1d_pass_2_verdict: FAIL
phase_1d_pass_3_verdict: FAIL
phase_1d_pass_4_verdict: FAIL
phase_1d_pass_5_verdict: FAIL
phase_1d_pass_6_verdict: FAIL
phase_1d_pass_7_verdict: FAIL
phase_1d_pass_8_verdict: FAIL
phase_1d_pass_9_verdict: FAIL
phase_1d_pass_10_verdict: FAIL
phase_1d_pass_11_verdict: FAIL
phase_1d_pass_12_verdict: FAIL
phase_1d_pass_13_verdict: FAIL
created: 2026-05-15
last_updated: 2026-05-16
status: phase-1d-cascade-active-pass-13-closed
---

# SESSION-HANDOFF — brain-factory Phase 1a / Phase 1b / Phase 1c / Phase 1d

## 1. Where we are

**Phase 1a CLOSED. Phase 1b COMPLETED. Phase 1c COMPLETED. Phase 1d IN-PROGRESS — Pass 13 closed; ready for Pass 14 dispatch (13 passes, 28+ fix-bursts committed, streak 0/3).**

The brain-factory product brief (Phase 1a) reached BC-5.39.001 3-CLEAN convergence at Pass 23 on v0.4.15 (802 lines, commit 9ff0504). Phase 1a Stage 5 is CLOSED.

Phase 1b (PRD) has been completed. PRD v0.1.1 landed at commit 7935faa. The PRD package comprises 95 BCs across 18 subsystems, 1 BC-INDEX, 4 supplements, and 1 PRD index.

Phase 1c (Architecture) has been completed. Architecture v0.1.1 landed via 5 commits (b7679ee, 7e8f96f, cd6c3ba, 1a10e45, d89ea4b). ARCH-INDEX + 17 ADRs + 18 SS-NN designs + 27 VPs (64/64 P0 BC coverage).

Phase 1d (Adversarial spec review) is IN-PROGRESS. 13 passes completed (all FAIL), 28+ fix-bursts committed. Current spec versions: brief v0.4.19, PRD v0.1.9, BC-INDEX v0.1.8, ARCH-INDEX v0.1.15 (52b7f19), VP-INDEX v0.1.6. Streak 0/3.

**Pass 12 closure note:** Pass 12 persist commit landed at a58de7e (2C+3I+2O). Architect burst 71c51b3 fixed F-PASS12-C1 (SS-NN classify — all 18 SS-NN confirmed Case A, 16 bumped to v1.1 with Changelog sections) + F-PASS12-I1 (hallucinated item names corrected in F-PASS11-C2 Changelog) + F-PASS12-I2 (SS-NN Changelog discipline tightened to any-content-edit trigger). PO burst ecbe056 fixed F-PASS12-C2 (PRD v0.1.8 → v0.1.9 + BC-INDEX v0.1.7 → v0.1.8 canonical-baseline timestamp sweep across 100 of 101 in-scope files; nfr-catalog retained at 2026-05-15). Pass 12 FINAL 0781716 re-pinned ARCH-INDEX inherits_from from prd@v0.1.8 → prd@v0.1.9. Pass 12 is clean (1 architect + 1 PO + 1 state-mgr FINAL 0781716 = 3 commits). The state-mgr FINAL 0781716 left a `[this burst]` placeholder for its own SHA — back-filled in Pass 13 state-mgr FINAL.

**Pass 13 closure note:** Pass 13 persist commit landed at a2fab66 (2C+3I+2O). Architect burst 52b7f19 fixed F-PASS13-C1 (count-balance correction: 34 + 28 = 62 ≠ 64; corrected to 34 bumped + 30 retained = 64 architecture artifacts; count-balance Self-Audit sub-rule codified) + F-PASS13-C2 (architecture artifact Changelog discipline extended from SS-NN scope to all three artifact types: 8 ADRs and 5 VPs back-filled to v1.1 with Changelog sections; bash sweep updated) + F-PASS13-I2 (stale PO follow-up instruction replaced with closure narrative; 134 bumped + 31 retained = 165 total in-scope) + F-PASS13-I3 (F-PASS11-C2/I2 credit-drift reconciled; F-PASS11-C2 list corrected from six items to five). No PO burst this pass — architect handled all routed findings. Pass 13 state-mgr FINAL adopts the new self-SHA-free FINAL-marker format (no `[this burst]` placeholder; textual marker used instead). Pass 13 is clean (1 architect + 1 state-mgr FINAL = 2 commits).

**TD-VSDD-053-spirit advisory:** Pass 11 produced 5 commits in one logical cycle (a3a83b1 + 343c378 + c35de6f + e37f1e3 + 7ea3f71). Pass 12 is clean. Pass 13 is clean. Going-forward: orchestrator dispatches with explicit single-commit-per-burst instructions. FINAL-marker format change (Pass 13): cascade table FINAL rows now carry "state-mgr FINAL ✓ (this commit)" — no SHA placeholder, no back-fill burst needed.

**Next action for fresh-context orchestrator:** Dispatch Pass 14 adversary per BC-5.39.001 cascade protocol. Pass 14 dispatch MUST use chat-only output protocol (no Write/Commit instructions to adversary; orchestrator routes persistence via state-manager).

## 2. Cascade history — Phase 1a (full, 23 passes)

See SESSION-HANDOFF prior versions or `.factory/cycles/v0.1-phase-1a-brief/adversary-pass-{1..23}.md` for the complete Phase 1a cascade table. Summary: 23 passes, 15 fix-bursts, 4 levels of recursion surfaced and closed. Brief v0.4.15 is final.

## 3. Key state

- **Brief:** `.factory/specs/product-brief.md` (v0.4.19, commit 1c0251c)
- **PRD:** `.factory/specs/prd/index.md` (v0.1.9, commit ecbe056)
- **BC-INDEX:** `.factory/specs/behavioral-contracts/BC-INDEX.md` (v0.1.8, commit ecbe056)
- **ARCH-INDEX:** `.factory/specs/architecture/ARCH-INDEX.md` (v0.1.15, commit 52b7f19)
- **VP-INDEX:** `.factory/specs/architecture/verification-properties/VP-INDEX.md` (v0.1.6, commit a3a83b1)
- **ADRs:** 17 (ADR-001 through ADR-017, all `status: accepted`; 8 now at v1.1 with Changelog sections)
- **SS-NN designs:** 18 (SS-01 through SS-18; all 18 at v1.1 or higher with Changelog sections)
- **VPs:** 27 (VP-001 through VP-027; 64/64 P0 BC coverage; 5 now at v1.1 with Changelog sections)
- **Total BCs:** 95 across 18 subsystems (SS-TBD fully eliminated)
- **Phase 1a streak:** 3/3 — CASCADE CONVERGED on v0.4.15 (Phase 1a Stage 5 CLOSED)
- **Phase 1b status:** COMPLETED at commit 7935faa (PRD v0.1.1)
- **Phase 1c status:** COMPLETED — architecture v0.1.1 across 5 commits (b7679ee through d89ea4b)
- **Phase 1d status:** IN-PROGRESS — 13 passes complete; 28+ fix-bursts committed; streak 0/3
- **Five-file gate:** canonical (brief + handoff + prd/index.md + BC-INDEX.md + ARCH-INDEX.md)

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
- "Continue cascade indefinitely per BC-5.39.001 strict protocol" — user confirmed at multiple checkpoint moments
- "Make drbothen/wclaude public before v0.1.0 tag" — gate item; documented in brief v0.4.3+
- F-PASS13-I2: Option A chosen — add `.reference/README.md` creation to bootstrap task list
- F-PASS14-I1: hook-performance tests fold into hooks.bats (preserves 9-suite count)
- GH Action template count canonical: 19 (planning artifact 18 superseded per ADR-013)
- api-retry.sh dual-copy pattern: `hooks/lib/` for Claude Code context; `scripts/lib/` for GH Actions context (ADR-016)

## 5. Structural-fix disciplines (Phase 1a — 13 confirmed disciplines)

| Version | Structural fix | Drift class eliminated |
|---------|----------------|------------------------|
| v0.4.5 | Grep-anchored references in Self-Audit Checklist | Line-number drift after edits |
| v0.4.6 | Creation-date anchors in Traceability section | Line-count drift |
| v0.4.7 | "See Changelog" reference in Self-Audit attestation | Per-version-attestation drift |
| v0.4.8 | Sibling-sweep "phased plan §X" → "phased-build-plan §X" | Citation-shorthand drift |
| v0.4.10 | Grep-anchored discipline extended to Changelog block | Stale-line-citation drift in Changelog |
| v0.4.11 | Semantic labels + grep-verified citation shorthand sibling-sweep | Count-drift class; partial-sibling-sweep regression |
| v0.4.12 | v0.4.8 bullets back-filled with STRUCTURAL FIX headings; coverage claim sharpened | Audit-trail completeness drift |
| v0.4.13 | Local fix + enforcement gate for writing-technique principle | Third-level recursion of narrow-fix-broad-announcement |
| v0.4.14 | Writing-technique principle + gate hardening (self-reference exclusion) | Fourth-level recursion |
| v0.4.15 | Gate extended to two-file for-loop; exclusion-list-extension protocol; historical absolute-immutability wording softened | Gate-coverage gap; exclusion-protocol omission; audit-trail overstatement |

## 6. Phase 1d disciplines (10 confirmed, Pass 12 added)

| Pass | Discipline | Scope |
|------|-----------|-------|
| 4 | Sweep-by-canonical-pattern | Incremental + canonical-baseline |
| 5 | last_updated freshness check | Incremental + canonical-baseline |
| 6 | inherits_from chain integrity + plain-prose `line N` gate | Incremental + canonical-baseline |
| 7 | Sequential pass-closure discipline + Option B parallel-burst hazard mitigation | Incremental + canonical-baseline |
| 8 | Operational state doc path-currency check (test -e) | Incremental + canonical-baseline |
| 9 | In-document title-cell sibling-sweep (ARCH-INDEX Doc Map vs VP-INDEX Summary) | Incremental + canonical-baseline |
| 10 | Dual-scope discipline (every codified discipline declares both incremental and canonical-baseline scope) | Incremental + canonical-baseline |
| 11 | Timestamp tri-partite semantic (F-PASS11-C1/I3) + retroactive dual-scope audit (F-PASS11-C2) + adversary pre-flight (F-PASS11-O1) | Incremental + canonical-baseline |
| 12 | SS-NN Changelog discipline tightened to any-content-edit trigger (F-PASS12-I2) | Incremental + canonical-baseline |
| 12 | Adversary dispatch chat-only protocol — no Write/Commit instructions to adversary (F-PASS12-O1) | Incremental |
| 13 | Architecture artifact Changelog discipline extended to all SS/ADR/VP artifact types; bash sweep updated; 8 ADRs + 5 VPs back-filled (F-PASS13-C2) | Incremental + canonical-baseline |
| 13 | Count balance check Self-Audit sub-rule — N bumped + M retained must equal total artifact count in same clause (F-PASS13-C1) | Incremental + canonical-baseline |
| 13 | Cascade table FINAL-marker format change — "✓ (this commit)" textual marker replaces self-SHA placeholder; no back-fill bursts needed (F-PASS13-I1) | Incremental |

## 7. Artifacts on disk (all persisted, last committed versions)

| Artifact | Version | Notes |
|----------|---------|-------|
| `.factory/specs/product-brief.md` | v0.4.19 | commit 1c0251c |
| `.factory/specs/prd/index.md` | v0.1.9 | commit ecbe056 |
| `.factory/specs/behavioral-contracts/BC-INDEX.md` | v0.1.8 | commit ecbe056 |
| `.factory/specs/architecture/ARCH-INDEX.md` | v0.1.15 | commit 52b7f19; inherits_from prd@v0.1.9 (re-pinned at 0781716) |
| `.factory/specs/architecture/adr/ADR-001-*.md` through `ADR-017-*.md` | accepted | 17 files; 8 (ADR-003/004/006/009/010/012/013/016) bumped to v1.1 with Changelog at 52b7f19 |
| `.factory/specs/architecture/subsystems/SS-01-*.md` through `SS-18-*.md` | v1.1+ | 18 files; all 18 at v1.1+ with Changelog sections |
| `.factory/specs/architecture/verification-properties/VP-INDEX.md` | v0.1.6 | commit a3a83b1 |
| `.factory/specs/architecture/verification-properties/VP-001-*.md` through `VP-027-*.md` | various | 27 files; 5 (VP-004/014/021/026/027) bumped to v1.1 with Changelog at 52b7f19 |

## 8. Recent commits (most recent first)

| SHA | Message |
|-----|---------|
| this commit | factory(state): Phase 1d Pass 13 FINAL — STATE refresh + Pass 12 back-fill (0781716) + Pass 13 row with new self-SHA-free FINAL-marker format (F-PASS13-I1 closure) + discipline catalog #14-16 |
| 52b7f19 | factory(spec): architecture v0.1.14 → v0.1.15 — Phase 1d Pass 13 architect (F-PASS13-C1 count correction + F-PASS13-C2 ADR/VP sibling-sweep + 13-file back-fill + F-PASS13-I2 stale instruction closure + F-PASS13-I3 credit-drift) |
| a2fab66 | factory(adversary): persist Phase 1d Pass 13 FAIL — 2 CRITICAL + 3 IMPORTANT + 2 OBSERVATIONS |
| 0781716 | factory(state): Phase 1d Pass 12 FINAL — STATE refresh + cascade table backfill (Pass 11 5-commit history + Pass 12 row) + TD-VSDD-053-spirit advisory + Pass 13 chat-only dispatch directive |
| ecbe056 | factory(spec): PRD v0.1.8 → v0.1.9 + BC-INDEX v0.1.7 → v0.1.8 — Phase 1d Pass 12 PO (F-PASS12-C2 canonical-baseline timestamp sweep) |
| 71c51b3 | factory(spec): architecture v0.1.13 → v0.1.14 — Phase 1d Pass 12 architect (F-PASS12-C1 SS-NN classify + F-PASS12-I1 narrative reconciliation + F-PASS12-I2 Changelog discipline tightened) |
| a58de7e | factory(adversary): persist Phase 1d Pass 12 FAIL — 2 CRITICAL + 3 IMPORTANT + 2 OBSERVATIONS |
| c35de6f | factory(spec): ARCH-INDEX correct v0.1.13 F-PASS11-C2 changelog entry (hallucinated filenames → actual inventory) [TD-VSDD-053-spirit corrective burst within Pass 11] |
| 343c378 | factory(spec): ARCH-INDEX add missing v0.1.13 Changelog entry [TD-VSDD-053-spirit corrective burst within Pass 11] |
| 7ea3f71 | factory(state): back-fill Pass 11 state-mgr FINAL SHA e37f1e3 into cascade table [TD-VSDD-053-spirit back-fill within Pass 11] |
| e37f1e3 | factory(state): Phase 1d Pass 11 FINAL — STATE refresh + 8-sub-check FINAL discipline |
| a3a83b1 | factory(spec): architecture v0.1.12 → v0.1.13 + VP-INDEX v0.1.5 → v0.1.6 — Phase 1d Pass 11 architect |
| 63cf130 | factory(adversary): persist Phase 1d Pass 11 FAIL — 2 CRITICAL + 3 IMPORTANT |
| c468276 | factory(state): Phase 1d Pass 10 FINAL — STATE refresh + extended FINAL discipline (7 sub-checks) |
| cc9ba18 | factory(spec): architecture v0.1.11 → v0.1.12 + VP-INDEX v0.1.4 → v0.1.5 — Phase 1d Pass 10 architect |
| 5a61476 | factory(adversary): persist Phase 1d Pass 10 FAIL — 2 CRITICAL + 3 IMPORTANT |

## 9. Resume procedure

**PHASE 1a CLOSED. PHASE 1b COMPLETED. PHASE 1c COMPLETED. PHASE 1d IN-PROGRESS — Pass 13 closed; ready for Pass 14.**

**For a fresh-context orchestrator session:** Read `.factory/STATE.md` FIRST — it is the canonical entry point.

In summary:
1. Run `vsdd-factory:devops-engineer` factory-worktree-health (BLOCKING preflight; expect intentional non-canonical layout per §10)
2. Read CLAUDE.md, STATE.md, THIS FILE, TASK-LIST.md, then adversary-pass-13.md
3. Dispatch Pass 14 adversary per BC-5.39.001 cascade protocol — MUST use chat-only output protocol (no Write/Commit instructions to adversary per F-PASS12-O1)
4. Repeat cascade until streak 3/3

Carry forward to Phase 1d: writing-technique principle (including plain-prose `line N`), five-file gate, exclusion-list-extension protocol, no blanket-coverage wording, single-commit-per-burst, NO AI attribution. Full discipline catalog in STATE.md.

## 10. Standing user directives (carry forward)

- "No pragmatic convergence. Fix all issues before build." (CLAUDE.md Canonical Principle)
- "Follow brain-factory plan completely; merge useful ideas from wclaude" (Stage 3)
- "Keep following protocol" (confirmed at multiple cascade checkpoints)
- "Full vision = full MVP; v0.x through v0.9 is the destination" (Stage 1 framing)
- "Power-user scale (10x Karpathy)" (SL-10)
- "factory-dispatcher needed before full release" (v1.0 commitment)
- NO AI attribution in commits (CLAUDE.md hard rule)
- All artifacts committed to main as de-facto factory-artifacts (proper worktree NOT established; factory-artifacts branch does NOT exist; commits go to main until worktree setup is done)
- **Phase 1b/1c/1d sequence pre-authorized by user 2026-05-15.** Orchestrator does NOT re-ask between sub-phases; only re-asks at major phase boundaries (Phase 1 → Phase 2, etc.).

## 11. Phase 1b PRD Entry — COMPLETED

**Commit 23e3a91** — PRD v0.1.0 initial creation. **Commit 7935faa** — PRD v0.1.0 → v0.1.1 fix-burst (4 of 5 findings closed). Independent orchestrator verification: CLEAN.

## 12. Phase 1c Architecture Entry — COMPLETED

**5 commits (b7679ee through d89ea4b).** Architecture v0.1.1 achieved. 64/64 P0 BC coverage. Five-file gate canonical. Independent orchestrator verification: CLEAN.

## 13. Phase 1d Adversarial Cascade — IN-PROGRESS-PAUSED

Phase 1d BC-5.39.001 3-CLEAN cascade started at commit 484bc05. All 13 passes to date have returned FAIL.

| Pass | Verdict | Findings | Persist SHA | Fix-burst SHAs | Streak after |
|------|---------|----------|-------------|----------------|--------------|
| 1 | FAIL | 7C+12I+5S+4O | 484bc05 | architect f5adb81 + PO 034f0cc | 0/3 |
| 2 | FAIL | 4C+8I+3S+4O | 15eee88 | architect 4fe045a + PO 5023852 | 0/3 |
| 3 | FAIL | 2C+4I+2S+2O | c3f32db | architect 2df98db + PO c6617bd | 0/3 |
| 4 | FAIL | 3C+3I | 984f9d6 | architect b68a52b + PO ee67abb | 0/3 |
| 5 | FAIL | 2C+3I | ba8ea7f | architect d588aa7 + PO 96a2a14 | 0/3 |
| 6 | FAIL | 2C+3I | 533d7db | architect 0827566 + PO e0e143c | 0/3 |
| 7 | FAIL | 2C+3I | 90acdbf | architect 7e60898 + PO 1c0251c + state-mgr FINAL fd033d1 | 0/3 |
| 8 | FAIL | 1C+3I | a6917e4 | architect bf34582 + state-mgr FINAL 35fd7c2 | 0/3 |
| 9 | FAIL | 1C+2I | 3296100 | architect 8c7dc97 + state-mgr FINAL 47824c4 | 0/3 |
| 10 | FAIL | 2C+3I | 5a61476 | architect cc9ba18 + state-mgr FINAL c468276 | 0/3 |
| 11 | FAIL | 2C+3I | 63cf130 | architect a3a83b1 + 343c378 (header correction) + c35de6f (inventory correction) + state-mgr FINAL e37f1e3 + 7ea3f71 (back-fill) | 0/3 |
| 12 | FAIL | 2C+3I+2O | a58de7e | architect 71c51b3 + PO ecbe056 + state-mgr FINAL 0781716 | 0/3 |
| 13 | FAIL | 2C+3I+2O | a2fab66 | architect 52b7f19 + state-mgr FINAL ✓ (this commit) | 0/3 |

**CRITICAL trajectory:** 7→4→2→3→2→2→2→1→1→2→2→2→2. Stable at 2 for four passes; novel-class findings driving persistence.

**Pass 13 findings summary:** 2 CRITICAL + 3 IMPORTANT + 2 OBSERVATIONS. Report at `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-13.md`.

**Pass reports:** `.factory/cycles/v0.1-phase-1d-spec/adversary-pass-{1..13}.md`

**Pass 13 closure:** persist a2fab66 + architect 52b7f19 + state-mgr FINAL ✓ (this commit). No PO burst this pass.

**Pass 11 TD-VSDD-053-spirit note:** Pass 11 produced 5 commits in one logical cycle (a3a83b1 + 343c378 + c35de6f + e37f1e3 + 7ea3f71). The three corrective bursts (343c378: missing changelog header; c35de6f: hallucinated inventory names; 7ea3f71: state-mgr back-fill SHA) survive the hook detector (no banned commit-subject pattern) but represent spirit violations. Not retroactively rebased; recorded as audit trail.

**Pass 12 state-mgr FINAL (0781716) back-fill note:** Pass 12 state-mgr FINAL left a `[this burst]` placeholder in the cascade table. Back-filled with actual SHA 0781716 in Pass 13 state-mgr FINAL. No structural rebase — this is an audit-trail correction in the subsequent pass, which is now the documented single-pass-cleanup pattern. Pass 13 adopts the new self-SHA-free format; no further back-fill needed going forward.
