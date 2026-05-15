# TASK-LIST — brain-factory Session Snapshot

> Snapshot taken at handoff: 2026-05-15. 16 adversary passes complete + v0.4.11 fix-burst
> applied. Streak: 0/3. Top-of-stack: Task #44 (Pass 17 fresh-context adversary dispatch).
> See SESSION-HANDOFF.md §9 for resume procedure.

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
| 40 | COMPLETED | Persist Pass 15 + refresh handoff state | All three artifacts persisted. Commits: 8d3e2a4 (pass-15), 6072814 (handoff), 989bd20 (task-list). |
| 41 | COMPLETED | Fix-burst v0.4.9 → v0.4.10 per Pass 15 findings | Applied at commit 8b3cb47 (brief v0.4.9→v0.4.10; 758→763 lines). F-PASS15-I1 resolved (gen-test-corpus.sh added to §Scope); F-PASS15-S1/S2 anchored; 4th structural fix extended grep-anchor discipline to Changelog block. |
| 42 | COMPLETED | Pass 16 adversary dispatch | FAIL: 3 IMPORTANT (F-PASS16-I1/I2 citation-shorthand regression, F-PASS16-I3 process-gap structural-fix mis-count); 1 SUGGESTION (F-PASS16-S1 cross_platform); 1 OBSERVATION (F-PASS16-O1 plugin.json/hooks.json.template gate-vs-scope). Streak: 0/3. Report persisted via state-manager (orchestrator dispatch — adversary read-only profile). |
| 43 | COMPLETED | Fix-burst v0.4.10 → v0.4.11 per Pass 16 findings | Applied at commit 5e6dc2f (brief v0.4.10→v0.4.11; 763→771 lines). F-PASS16-I1+I2 paired citation sibling-sweep with grep verification (3 prior-pass fixes back in compliance); F-PASS16-I3 semantic-label replacement (count-drift class eliminated); F-PASS16-S1 cross_platform Git Bash; F-PASS16-O1 plugin.json+hooks.json.template added to §Scope. Bonus in-scope: v0.4.5/v0.4.6/v0.4.7 structural-fix labels promoted to semantic-label format. |
| 44 | PENDING | Pass 17 adversary dispatch | Unblocked. Fresh-context dispatch ready. Streak resumes from 0/3. |

## Next steps (in dependency order)

1. ~~(done) Task #40: persist Pass 15 + refresh handoff state~~
2. ~~(done at 8b3cb47) Task #41: v0.4.10 fix-burst — F-PASS15-I1 resolved, S1/S2 anchored, 4th structural fix applied~~
3. ~~Task #42: Pass 16 fresh-context adversary dispatch (done — FAIL)~~
4. ~~(done at 5e6dc2f) Task #43: v0.4.11 fix-burst — F-PASS16-I1/I2/I3 + S1/O1 resolved; semantic labels + grep-verified sibling-sweep~~
5. **Task #44: Pass 17 fresh-context adversary dispatch**
6. Continue until streak 3/3 → mark Task 6 (Stage 6 Finalize) as ready
7. After convergence: execute Task 23 (post-convergence git cleanup)
