# TASK-LIST — brain-factory Session Snapshot

> Snapshot taken at handoff: 2026-05-15. 15 adversary passes complete (Pass 15 = FAIL
> with 1 IMPORTANT). Streak: 0/3. Top-of-stack: Task #41 (v0.4.10 fix-burst). See
> SESSION-HANDOFF.md §9 for resume procedure.

## Task Status

| ID | Status | Subject | Notes |
|----|--------|---------|-------|
| 1 | COMPLETED | Stage 1: Initial discovery conversation | Human described brain-factory vision |
| 2 | COMPLETED | Stage 2: Research synthesis | brief-research.md + reference-repos.md produced |
| 3 | COMPLETED | Stage 3: Elicitation — SL-1 through SL-11 locked | stage-3-locks.md produced (171 lines) |
| 4 | COMPLETED | Draft product-brief v0.1 | First draft from elicitation output |
| 5 | COMPLETED | Draft product-brief v0.2.0 | Expanded with domain context + traceability scaffolding |
| 6 | PENDING | Stage 6: Finalize brief and advance to PRD | Awaits cascade convergence (3-CLEAN) |
| 7 | COMPLETED | Pass 1 adversary dispatch | FAIL: 4 CRITICAL, 11 IMPORTANT |
| 8 | COMPLETED | Fix-burst v0.2.0 → v0.3.0 | Resolved 10 of 12 Pass 1 findings; 2 new issues introduced |
| 9 | COMPLETED | Pass 2 adversary dispatch | FAIL: 1 CRITICAL, 3 IMPORTANT |
| 10 | COMPLETED | Fix-burst v0.3.0 → v0.4.0 | Addressed CRITICAL + IMPORTANT; paper-fix pattern noted |
| 11 | COMPLETED | Pass 3 adversary dispatch | FAIL: 2 CRITICAL, 4 IMPORTANT |
| 12 | COMPLETED | Fix-burst v0.4.0 → v0.4.1 | Structural improvements; paper-fix pattern partially observed |
| 13 | COMPLETED | Pass 4 adversary dispatch | FAIL: 2 CRITICAL, 2 IMPORTANT |
| 14 | COMPLETED | Fix-burst v0.4.1 → v0.4.2-final | Structural discipline applied; stage-3-locks.md created |
| 15 | COMPLETED | Pass 5 adversary dispatch | PASS: 0 CRITICAL, 0 IMPORTANT — streak 1/3 |
| 16 | COMPLETED | Pass 6 adversary dispatch | PASS: 0 CRITICAL, 0 IMPORTANT — streak 2/3 |
| 17 | COMPLETED | Pass 7 adversary dispatch | FAIL: 1 IMPORTANT (convergence-target omission) — streak RESET 0/3 |
| 18 | COMPLETED | Fix-burst v0.4.2-final → v0.4.3 | Added 3-CLEAN requirement + wclaude public gate |
| 19 | COMPLETED | Pass 8 adversary dispatch | FAIL: 2 IMPORTANT (wclaude gate detail, line-count discipline) |
| 20 | COMPLETED | Fix-burst v0.4.3 → v0.4.4 | Added wclaude gate detail; line-count fix attempted |
| 21 | COMPLETED | Pass 9 adversary dispatch | FAIL: 1 IMPORTANT (paper-fix on line count — 495 vs 496) |
| 22 | COMPLETED | Fix-burst v0.4.4 → v0.4.5 | Structural fix: grep-anchored references in Self-Audit |
| 23 | PENDING | Post-convergence cleanup — commit all artifact versions to git | Awaits cascade convergence; brief has advanced further than git history reflects |
| 24 | COMPLETED | Pass 10 adversary dispatch | FAIL: 1 IMPORTANT (false attestation — Pass 9 line-count claim) |
| 25 | COMPLETED | Fix-burst v0.4.5 → v0.4.6 | Structural fix: creation-date anchors in Traceability |
| 26 | COMPLETED | Pass 11 adversary dispatch | FAIL: 1 IMPORTANT (per-version attestation gap in Self-Audit) |
| 27 | COMPLETED | Fix-burst v0.4.6 → v0.4.7 | Structural fix: "See Changelog" reference added to Self-Audit |
| 28 | COMPLETED | Pass 12 adversary dispatch | PASS: 0 CRITICAL, 0 IMPORTANT — streak 1/3; all 4 structural fixes verified |
| 29 | COMPLETED | Checkpoint: confirm continue per BC-5.39.001 strict protocol | User confirmed "keep following protocol" |
| 30 | COMPLETED | Pass 13 adversary dispatch | FAIL: 2 IMPORTANT — streak RESET 0/3 (F-PASS13-I1 skill count, F-PASS13-I2 .reference/README.md) |
| 31 | COMPLETED | Resolve F-PASS13-I2 Option A/B decision | User chose Option A: add .reference/README.md to bootstrap task |
| 32 | COMPLETED | Fix-burst v0.4.7 → v0.4.8 | Fixed I1 (skill count 12→13), I2 (bootstrap task updated) |
| 33 | COMPLETED | Pass 14 adversary dispatch | FAIL: 2 IMPORTANT (F-PASS14-I1 bats count 10 vs 9; F-PASS14-I2 /brain:research label) |
| 34 | COMPLETED | Resolve F-PASS14-I1 bats count decision | hook-performance tests fold into hooks.bats; 9-suite count preserved |
| 35 | COMPLETED | Fix-burst v0.4.8 → v0.4.9 | Fixed I1 (bats count) + I2 (/brain:research label "new" in Scope) |
| 36 | COMPLETED | Commit Pass 14 FAIL report | SHA: 7f8572c |
| 37 | COMPLETED | Amend CLAUDE.md with Node 20+ constraint | L5 updated at Stage 3 |
| 38 | COMPLETED | Author SESSION-HANDOFF.md | Initial handoff; written at session boundary |
| 39 | COMPLETED | Pass 15 adversary dispatch | FAIL: 1 IMPORTANT (F-PASS15-I1: scripts/gen-test-corpus.sh missing from §Scope); 2 SUGGESTION (F-PASS15-S1/S2: stale Changelog line refs); 2 OBSERVATION. Streak: 0/3 |
| 40 | IN-PROGRESS | Persist Pass 15 + refresh handoff state | Writing adversary-pass-15.md, SESSION-HANDOFF.md, TASK-LIST.md |
| 41 | PENDING | Fix-burst v0.4.9 → v0.4.10 per Pass 15 findings | TOP-OF-STACK. Fix F-PASS15-I1 (add gen-test-corpus.sh to §Scope); bundle S1/S2 (Changelog semantic anchors); consider 4th structural fix (Changelog line-refs → semantic anchors) |
| 42 | PENDING | Pass 16 adversary dispatch | Blocked on #41. Streak resumes from 0/3. |

## Next steps (in dependency order)

1. Complete Task #40 (this task — commit handoff state)
2. Task #41: v0.4.10 fix-burst — add `scripts/gen-test-corpus.sh` to §Scope (F-PASS15-I1, blocker), bundle S1/S2 Changelog semantic-anchor fixes, optionally apply 4th structural fix
3. Task #42: Pass 16 fresh-context adversary dispatch — streak resumes from 0/3
4. Continue until streak 3/3 → mark Task 6 (Stage 6 Finalize) as ready
5. After convergence: execute Task 23 (post-convergence git cleanup)
