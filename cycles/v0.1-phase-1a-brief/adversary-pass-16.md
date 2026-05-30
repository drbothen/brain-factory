---
artifact_type: adversary-pass-report
pass_number: 16
cascade: brain-factory-product-brief-v0.4.10
target_file: .factory/specs/product-brief.md
target_version: 0.4.10
adversary_protocol: BC-5.39.001 3-CLEAN
streak_before: 0/3
streak_after: 0/3 (HOLD)
created: 2026-05-15
author: vsdd-factory:adversary
finding_count_critical: 0
finding_count_important: 3
finding_count_suggestion: 1
finding_count_observation: 1
finding_count_process_gap: 1
verdict: FAIL
paper_fix_pattern_observed: false
structural_fixes_holding: 6
prior_pass_fixes_holding: 15
prior_pass_fixes_regressed: 3
adversary_tool_profile_note: read-only (Read/Grep/Glob); report persisted by orchestrator via state-manager
---

# Adversarial Review — Pass 16

**Target file:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md` (v0.4.10, 763 lines)
**Cascade:** BC-5.39.001 3-CLEAN convergence; brain-factory product brief
**Streak before:** 0/3
**Verdict:** **FAIL** (3 IMPORTANT, 1 SUGGESTION, 1 OBSERVATION; 1 process-gap tag overlapping I3)

---

## A. Pass 15 Fix Verification

| Pass 15 finding | v0.4.10 claim | Verification |
|---|---|---|
| F-PASS15-I1 (`scripts/gen-test-corpus.sh` in §Scope) | Added to §Scope Additional v0.x deliverables | **VERIFIED.** Grep `scripts/gen-test-corpus` returns L56 (changelog), L115 (v0.4.1 changelog historical), L356 (v0.9 gate body), L505 (§Scope deliverables enumeration). New L505 bullet reads: "`scripts/gen-test-corpus.sh` — synthetic-corpus generator producing N source files + manifest.json for the v0.9 scale test (Phase 3 deliverable owned by devops-engineer, designed during Phase 1c architecture, built during Phase 3 alongside scale-test execution)." |
| F-PASS15-S1 ("line 301" → semantic anchor) | "per line 301" → "see the embedding_status enforcement gate item below" | **VERIFIED.** L60 now reads: "parallel to embedding_status treatment, see the embedding_status enforcement gate item below". |
| F-PASS15-S2 ("§Scope §399" → semantic anchor) | "§Scope §399" → "matching §Scope's 'Phase 2–3 new skill' header" | **VERIFIED.** L61 now reads: "matching §Scope's 'Phase 2–3 new skill' header". |
| F-PASS15-O1 (skill gate-item parenthetical) | Optional — not actioned | Accepted as observation. |
| F-PASS15-O2 (Q#3 wording ambiguity) | Optional — not actioned | Accepted as observation. |

All three blocking Pass 15 fixes verified.

## B. Structural-Fix Cascade Verification (now SIX structural fixes)

| Structural fix | Grep test | Result |
|---|---|---|
| v0.4.5 (L-numbers → grep-anchors) | `\bL[0-9]+\b` body | 0 matches **PASS** |
| v0.4.6 (line-counts → creation-date anchors) | `\b[0-9]{3}-line\b` | 0 matches **PASS** |
| v0.4.7 (per-version annotations) | `v0\.[34]\.\d+:` in Self-Audit | 0 matches **PASS** |
| v0.4.8 (citation shorthand) | `phased plan §\|plugin plan §` body | 0 matches in body; only L68 (v0.4.8 changelog describing the fix) **PASS** |
| v0.4.8 (§Changelog notation) | `§Changelog` body | 0 body matches; only L69 (v0.4.8 changelog describing the fix) **PASS** |
| **v0.4.10 (NEW — Changelog semantic-anchor discipline)** | Active line citations inside Changelog block | Only historical citations in v0.4.10 entry describing the fix being made. All v0.4.9–v0.4.1 changelog body entries use semantic anchors. **PASS** |

All six structural-fix disciplines hold. (But see F-PASS16-I3 below: v0.4.10's self-label of "4th in cascade" mis-counts the cascade.)

## C. Pass 5–15 Regression Check

| Earlier finding | v0.4.10 status |
|---|---|
| Pass 7 F-PASS7-I1 (12→13 hook sibling-sweep) | STILL CORRECT |
| Pass 8 F-PASS8-I1 (/brain:research v0.9 timing) | STILL CORRECT |
| Pass 8 F-PASS8-I2 (Perplexity MCP opt-in) | STILL CORRECT |
| Pass 9 F-PASS9-I1 (Self-Audit L-numbers) | STRUCTURALLY VERIFIED |
| Pass 10 F-PASS10-I1 (line-count drift) | STRUCTURALLY VERIFIED |
| **Pass 10 F-PASS10-O2 (`plan §A.2` → `phased-build-plan §A.2`)** | **REGRESSION at L280 and L523 — see F-PASS16-I1/I2** |
| Pass 11 F-PASS11-I1 (per-version attestation) | STRUCTURALLY VERIFIED |
| **Pass 12 F-PASS12-O1 (citation shorthand)** | **REGRESSION at L280 and L523 — see F-PASS16-I1/I2** |
| Pass 12 F-PASS12-O2 (§Changelog notation) | STILL CORRECT |
| Pass 13 F-PASS13-I1 (Timeline-Scope 12-vs-13 polish skills) | STILL CORRECT |
| Pass 13 F-PASS13-I2 (.reference/README.md gate-vs-task) | STILL CORRECT |
| **Pass 13 F-PASS13-O1 (citation shorthand sibling-sweep)** | **REGRESSION at L280 and L523 — see F-PASS16-I1/I2** |
| Pass 14 F-PASS14-I1 (hook-perf.bats phantom suite) | STILL CORRECT |
| Pass 14 F-PASS14-I2 (skill #26 polish label) | STILL CORRECT |
| Pass 14 F-PASS14-S1 (Q#4 Phase 3) | STILL CORRECT |
| Pass 14 F-PASS14-O1 (local-dev-test.sh in §Scope) | STILL CORRECT |
| Pass 15 F-PASS15-I1 (gen-test-corpus.sh in §Scope) | STRUCTURALLY VERIFIED |
| Pass 15 F-PASS15-S1 ("line 301" → semantic anchor) | STRUCTURALLY VERIFIED |
| Pass 15 F-PASS15-S2 ("§Scope §399" → semantic anchor) | STRUCTURALLY VERIFIED |

**14 fixes preserved; 3 prior-pass fixes regressed at the same 2 callsites (L280, L523).** The v0.4.8 "sibling-sweep at all callsites" claim was incomplete — a partial-fix that survived 3 passes by being trusted rather than re-grepped.

## D. Standard Cumulative Checks

### Enumerated counts (11)

| Count | Frontmatter | Body | Verdict |
|---|---|---|---|
| 26 skills | L27 | L135 (Vision); §Scope 13+12+1=26 (L380–L410); v0.9 gate L331 | CONSISTENT |
| 14 agents | L28 | L135; §Scope 10+4=14 (L418–L434) | CONSISTENT |
| 13 hooks | L29 | L135; §Scope 12+1=13 (L440–L455); v0.1 gate L298, L304; v0.9 gate L330; v1.0 gate L364 | CONSISTENT |
| 19 GH Actions total | L30 | L135; §Scope 6+9+4=19 (L461–L484); v0.5 milestone L321 | CONSISTENT |
| 15 author-committed | L31 | §Scope 6+9=15 (L461–L478) | CONSISTENT |
| 4 community-optional | L32 | §Scope 4 (L480–L484) | CONSISTENT |
| 9 bats suites | (not frontmatter) | L310; L496 (8 functional + meta-lint = 9) | CONSISTENT |
| 8 wclaude absorptions | wclaude_absorption keyword | L225; L618; L729 | CONSISTENT |
| 7 reference repos | L48 | L208; L640; L642–L654 (numbered 1–7) | CONSISTENT |
| 10 baseline policies | (not numeric) | L160; L491; L493 | CONSISTENT |
| 6 wiki types | (plan §3.4 cite) | L262; L491 | CONSISTENT |

### Citation accuracy spot-check (5 samples)

| # | Citation | Verified against source |
|---|---|---|
| 1 | L212 → phased-build-plan §8.2.4 + §10.5 (`diff_count = 0`) | VERIFIED |
| 2 | L262 → plan.md §3.4 (6 wiki types) | VERIFIED |
| 3 | L345 → stage-3-locks.md SL-9 (§132), SL-10 (§144) | VERIFIED |
| 4 | L491 → phased-build-plan §A.2 (9-subdir layout) | VERIFIED |
| 5 | L700 → phased-build-plan §A.2 (5 briefs subdirs) | VERIFIED |

5/5 citations VERIFIED. (But see F-PASS16-I1/I2 for stale citation shorthand at L280 and L523 — issue is shorthand notation, not target accuracy.)

---

## Critical Findings

(none)

---

## Important Findings

### F-PASS16-I1 [IMPORTANT] — L280 `plan §A.4` citation violates Citation Conventions block; regresses F-PASS10-O2 / F-PASS12-O1 / F-PASS13-O1 sibling-sweep

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Line:** 280 (Scalability Design Principles §6 Commitment)
- **Confidence:** HIGH

**Evidence:**

Line 280: "**`validate-frontmatter-schema.sh` hook enforces presence on `wiki/*` writes** (PostToolUse on Write|Edit; scope includes both `wiki/*` and `sources/*` per `plan §A.4`, but the `embedding_status` requirement applies only to `wiki/*` since ..."

The Citation Conventions block at L714 states: "'plan.md' refers to `docs/planning/llm-second-brain-plan.md`; 'phased-build-plan.md' refers to `docs/planning/llm-second-brain-phased-build-plan.md`; 'plugin-plan.md' refers to `docs/planning/llm-second-brain-plugin-plan.md`."

§A.4 (Bash hooks) lives in `phased-build-plan.md` at line 913 (verified via Grep). It does NOT exist in `plan.md`. Therefore `plan §A.4` resolves under Citation Conventions to `llm-second-brain-plan.md §A.4` — which does not exist.

This citation should read either `phased-build-plan.md §A.4` or `phased-build-plan §A.4`.

**This regresses three prior-pass fixes:**
- F-PASS10-O2 (v0.4.6): "Disambiguated 'plan §A.2' → 'phased-build-plan §A.2' at 5 callsites; added Citation Conventions note"
- F-PASS12-O1 (v0.4.8): "Sibling-swept 'phased plan §X' → 'phased-build-plan §X' and 'plugin plan §X' → 'plugin-plan.md §X' at all callsites"
- F-PASS13-O1 (v0.4.8): Same sibling-sweep claim

The v0.4.8 fix-burst claimed the sibling-sweep was complete ("at all callsites"). The current body has at least 2 callsites that still use the stale shorthand — see F-PASS16-I2 for the paired second.

**Why IMPORTANT (not SUGGESTION):**

This is a Pass-10/12/13 cited-as-resolved finding that is now confirmed unresolved. Per the Partial-Fix Regression Discipline (S-7.01), regression of three prior-pass fixes at the same defect class with blast radius = 2 callsites in the body is HIGH-severity → IMPORTANT. The defect also actively misleads the reader (the citation cannot be resolved to a real section).

**Fix options:**

1. Change L280 `plan §A.4` → `phased-build-plan.md §A.4`.
2. Bundle with F-PASS16-I2 as a single sibling-sweep fix with grep verification.

### F-PASS16-I2 [IMPORTANT] — L523 `Plugin plan §3.15` citation violates v0.4.8 sibling-sweep; should be `plugin-plan.md §3.15`

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Line:** 523 (§Scope §Out of scope for v0.x §Worktree-mounted .brain/ state)
- **Confidence:** HIGH

**Evidence:**

Line 523: "**Worktree-mounted `.brain/` state.** Plugin plan §3.15 marks it OPTIONAL advanced. Default for new installs is plain (no worktree). Not committed in v0.x."

Per F-PASS12-O1 / F-PASS13-O1 (v0.4.8 changelog L68): "Sibling-swept 'plugin plan §X' → 'plugin-plan.md §X' at all callsites."

§3.15 (Worktree-Mounted State) does exist in `plugin-plan.md` at L217 (verified via Grep). So the citation target is correct, but the shorthand "Plugin plan" violates the sibling-sweep discipline. Should be `plugin-plan.md §3.15`.

Same defect class as F-PASS16-I1 (paired sibling). Two body callsites both regress the v0.4.8 sibling-sweep claim.

**Why IMPORTANT (not SUGGESTION):**

Same reasoning as F-PASS16-I1 — this is one of two cooperating callsites that demonstrate the v0.4.8 "at all callsites" claim was incomplete. Severity per S-7.01: blast radius = 2 callsites (the pair) → HIGH → IMPORTANT.

**Fix options:**

1. Change L523 `Plugin plan §3.15` → `plugin-plan.md §3.15`.
2. Bundle with F-PASS16-I1 — full grep-sweep for stale shorthand patterns: `plan §[A-Z0-9]` (case-sensitive), `Plugin plan §`, `Phased plan §`, etc. Verify zero residual callsites after the sweep.

**Why this is fresh-context-novel:**

Pass 12 and Pass 13 both claimed the sibling-sweep was complete. Prior passes 14, 15 did not re-run the grep — they trusted the v0.4.8 changelog claim. Pass 16 fresh-context re-runs the grep without that prior trust and discovers two residual callsites.

### F-PASS16-I3 [IMPORTANT, process-gap] — v0.4.10 changelog self-labels structural fix as "4th in cascade"; actual count is 6th by fix and 5th by version — eat-your-own-dog-food count error

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Line:** 57 (v0.4.10 changelog header)
- **Confidence:** HIGH

**Evidence:**

Line 57: "**STRUCTURAL FIX (4th in cascade):** replaced all line-number citations in the Changelog block with semantic anchors — extends the v0.4.5 grep-anchor discipline to the Changelog audit-trail section..."

Cascade enumeration (verified against Pass 15 §B verification table and the brief's own Changelog block):

| # | Version | Structural fix |
|---|---|---|
| 1 | v0.4.5 | L-numbers → grep-anchors (Self-Audit) |
| 2 | v0.4.6 | line-counts → creation-date anchors (Traceability) |
| 3 | v0.4.7 | per-version annotations collapsed (Self-Audit) |
| 4 | v0.4.8 | citation shorthand → canonical filenames |
| 5 | v0.4.8 | §Changelog notation → "Changelog block at top of brief" |
| 6 | v0.4.10 | Changelog line citations → semantic anchors (THIS FIX) |

By fix-count: v0.4.10 is the **6th** structural fix. By version-count: v0.4.10 is the **5th** version-with-structural-fix (v0.4.5, v0.4.6, v0.4.7, v0.4.8, v0.4.10). Either way, "4th" is wrong.

Pass 15 frontmatter explicitly stated `structural_fixes_holding: 5 (v0.4.5/v0.4.6/v0.4.7/v0.4.8 citation/§Changelog)` — i.e., 5 fixes prior to v0.4.10. Adding v0.4.10 should yield 6, not 4.

**Why IMPORTANT (not SUGGESTION):**

Eat-your-own-dog-food violation. The v0.4.10 fix is explicitly about ENFORCING structural-fix discipline against the Changelog audit-trail section. The fix itself contains a counting error in the audit-trail entry that records the fix. A reader auditing the cascade history would conclude there have been 4 structural fixes total (3 prior + this one), missing two of them. This actively corrupts the audit trail the fix purports to harden.

The pattern matches the production-grade default's "paper-fix" smell: the fix renames the count but doesn't reconcile it with reality. Per CLAUDE.md Canonical Principle Rule 4 + TD-VSDD-059 (paper-fix detection), this is a structural defect, not stylistic.

**Why this is fresh-context-novel:**

Pass 15's recommended next-action ("Consider a structural fix for the Changelog block… extending the v0.4.5 discipline") did not specify a count for the new structural fix in cascade sequence. The fix-burst author picked "4th" without cross-checking against the actual cascade enumeration. Pass 16 fresh-context re-derives the cascade enumeration from the Changelog block and flags the mismatch.

**Tag: [process-gap]** — the structural-fix cascade counter itself has no machine-greppable verification. A meta-fix would replace ordinal-numeric structural-fix labels with semantic labels (e.g., "STRUCTURAL FIX (Changelog audit-trail discipline)") so future fixes don't accumulate count-drift in the meta-language describing the discipline.

**Fix options:**

1. Change L57 "**STRUCTURAL FIX (4th in cascade):**" → "**STRUCTURAL FIX (6th in cascade):**" (counting individual fixes).
2. OR "**STRUCTURAL FIX (5th version-step in cascade):**" (counting by version).
3. **OR remove the count and use a semantic anchor like "**STRUCTURAL FIX (Changelog audit-trail discipline):**"** — eliminates the count-drift class entirely, matching the spirit of the v0.4.5 structural-fix family. **(Recommended — production-grade fix.)**

---

## Suggestions

### F-PASS16-S1 [SUGGESTION] — Frontmatter `cross_platform` field omits "Git Bash" though body cites it as the Windows-via-v0.x path in 4+ places

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Line:** 42 (frontmatter); 195, 334, 515, 546 (body)
- **Confidence:** MEDIUM

**Evidence:**

Frontmatter L42: `cross_platform: macOS + Linux + WSL2 (native Windows = v1.0)`

Body L195: "Operators on Windows install Git Bash or WSL2."
Body L334: "Cross-platform: at least one operator on each of {macOS, Linux, Windows-via-Git-Bash or WSL2}"
Body L515: "v0.x operators on Windows use Git Bash or WSL2."
Body L546: "Windows via Git Bash or WSL2."

Frontmatter `cross_platform` value lists `WSL2` but omits `Git Bash`, while the body uniformly cites both as v0.x Windows-supported paths. Frontmatter ↔ body drift.

**Why SUGGESTION (not OBSERVATION):**

Frontmatter is a structured, machine-greppable surface. A future agent might key off `cross_platform` and miss the Git-Bash path. Per the Frontmatter↔Body Coherence Review Axis, every frontmatter enumerated field should be derivable from body content. Currently it's not.

**Why this is fresh-context-novel:**

Prior passes cross-checked count fields (skill count, agent count, hook count) but not the enumerated-string fields.

**Fix options:**

1. Change L42 → `cross_platform: macOS + Linux + (Windows via Git Bash or WSL2) (native Windows = v1.0)`
2. OR `cross_platform: macOS + Linux + Git-Bash + WSL2 (native Windows = v1.0)`.

---

## Observations

### F-PASS16-O1 [OBSERVATION] — `plugin.json` and `hooks.json.template` are required by v0.1 ship gate (L297, L300) and v1.0 ship gate (L366) but not explicitly enumerated in §Scope Additional v0.x deliverables — 4th instance of gate-vs-scope defect family

- **File:** `/Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md`
- **Lines:** 297, 300 (v0.1 gate); 366 (v1.0 gate); §Scope §Additional v0.x deliverables block L490–L508
- **Confidence:** HIGH for the gap; MEDIUM for the severity (these are arguably implicit-tarball-infrastructure)

**Evidence:**

v0.1 gate L297: "`plugin.json` valid, version 0.1.0."
v0.1 gate L300: "`hooks.json.template` valid JSON; references all hooks via `${CLAUDE_PLUGIN_ROOT}`."
v1.0 gate L366: "`hooks.json.template` wires Claude Code → factory-dispatcher → WASM plugins."

§Scope §Additional v0.x deliverables (L490–L508):
- L502: "Per-platform hooks.json variants (darwin-arm64, ...)" — refers to runtime-resolved `hooks.json` per-platform, but `hooks.json.template` is upstream and not enumerated.
- `plugin.json` is NOT enumerated.

Same defect-class signature as F-PASS13-I2 (`.reference/README.md`), F-PASS14-O1 (`local-dev-test.sh`), and F-PASS15-I1 (`scripts/gen-test-corpus.sh`).

**Why OBSERVATION (not IMPORTANT):**

`plugin.json` and `hooks.json.template` are baseline plugin infrastructure that any Claude Code plugin MUST have to load. They are arguably implicit in "Plugin repo with full Phase 1 folder structure" (L296) and "Plugin tagged v0.1.0; tarball in GH Releases" (L312). Unlike `scripts/gen-test-corpus.sh` (a Phase 3 deliverable for a specific scale-test), these are obvious plugin scaffolding. A v0.1 implementer would not be left wondering whether to create them. By the strict logic that surfaced F-PASS13-I2 / F-PASS14-O1 / F-PASS15-I1, however, this IS the same defect-class. OBSERVATION rather than IMPORTANT acknowledges the lower production-grade risk.

**Fix options:**

1. Add §Scope deliverable bullets: "`plugin.json` — Claude Code plugin manifest" and "`hooks.json.template` — hooks.json variant template referencing all 13 hooks via `${CLAUDE_PLUGIN_ROOT}`."
2. OR accept this gap as legitimate plugin-infrastructure implicit-in-tarball.
3. OR add an umbrella deliverable for plugin scaffolding.

---

## Forbidden-Pattern Sweep

| Forbidden pattern | Result |
|---|---|
| `eval ` (code samples) | No active code samples with `eval` |
| `.claude/templates/` (hardcoded) | L534 mentions only in a prohibition — correct |
| `Co-Authored-By: Claude` | L536 mentions only in a prohibition — correct |
| Robot emoji | Not found |
| "TODO for architect" / "Pending architect review" / "Placeholder for architect" | L756 only in Self-Audit prohibition — correct |
| "MVP" / "for now" / "good enough" / "we can fix later" | Only as legitimate v0.9 milestone label or in Self-Audit prohibition — correct |

**No forbidden-pattern violations.**

---

## Novelty Assessment

**Novelty: MODERATE.**

- F-PASS16-I1 and F-PASS16-I2 demonstrate prior-pass regressions — the v0.4.8 sibling-sweep was incomplete despite explicit "at all callsites" claim. This pattern (claimed-resolved finding silently reopening across 5+ passes) is itself a process-gap signal.
- F-PASS16-I3 is genuinely novel — the v0.4.10 fix is internally inconsistent with the very cascade it claims to extend.
- F-PASS16-S1 (frontmatter ↔ body Git-Bash drift) is genuinely novel — no prior pass cross-checked the `cross_platform` enumerated-string field.
- F-PASS16-O1 is a 4th instance of the gate-vs-scope defect class.

**Fresh-Context Compounding Value strongly demonstrated:** Pass 16 surfaces THREE prior-pass-claimed-resolved regressions (F-PASS10-O2 / F-PASS12-O1 / F-PASS13-O1 all silently re-opened) and the v0.4.10 fix's internal counting error. None of Passes 13–15 caught either issue because they trusted the v0.4.8 "at all callsites" claim and didn't re-grep.

---

## Streak Decision

**Streak: stays at 0/3 (FAIL).** 3 IMPORTANT findings exceed the "0 CRITICAL + 0 IMPORTANT → advance" gate.

| Pass | Verdict | Streak after |
|---|---|---|
| Pass 12 | PASS | 1/3 |
| Pass 13 | FAIL (2 IMPORTANT) | 0/3 (RESET) |
| Pass 14 | FAIL (1 IMPORTANT) | 0/3 |
| Pass 15 | FAIL (1 IMPORTANT) | 0/3 |
| **Pass 16** | **FAIL (3 IMPORTANT)** | **0/3** |

---

## Recommended Next Action

**Dispatch fix-burst for v0.4.11.**

1. **F-PASS16-I1 + F-PASS16-I2 (paired, IMPORTANT, blocking):** Full grep sibling-sweep of citation shorthand.
   - L280: `plan §A.4` → `phased-build-plan.md §A.4`
   - L523: `Plugin plan §3.15` → `plugin-plan.md §3.15`
   - Verify with `grep -nE '(^|[^.])plan §[A-Z0-9]|Plugin plan §|Phased plan §' product-brief.md` returning zero non-Changelog-historical matches.
   - Add a v0.4.11 changelog entry citing F-PASS16-I1/I2 and acknowledging the v0.4.8 sibling-sweep was incomplete.

2. **F-PASS16-I3 (IMPORTANT, blocking, [process-gap]):** Replace L57's "**STRUCTURAL FIX (4th in cascade):**" with semantic label "**STRUCTURAL FIX (Changelog audit-trail discipline):**" — eliminates count-drift class permanently.

3. **F-PASS16-S1 (SUGGESTION, bundle):** Update frontmatter L42 to include "Git Bash" alongside "WSL2".

4. **F-PASS16-O1 (OBSERVATION, optional bundle):** Optionally add `plugin.json` and `hooks.json.template` to §Scope Additional v0.x deliverables, closing the 4th gate-vs-scope artifact-mismatch instance.

After v0.4.11, dispatch Pass 17 with fresh context. Streak resumes from 0/3.

---

## Structured Summary

```yaml
target_file: /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
target_version: 0.4.10
target_lines: 763
pass_number: 16
adversary_protocol: BC-5.39.001 3-CLEAN
finding_counts:
  critical: 0
  important: 3
  suggestion: 1
  observation: 1
  process_gap: 1
  total_blocking: 3
verdict: FAIL
streak_before: 0/3
streak_after: 0/3 (no change — blocker count > 0)
critical_finding_ids: []
important_finding_ids: [F-PASS16-I1, F-PASS16-I2, F-PASS16-I3]
suggestion_finding_ids: [F-PASS16-S1]
observation_finding_ids: [F-PASS16-O1]
process_gap_finding_ids: [F-PASS16-I3]
paper_fix_pattern_observed: false
pass_15_fixes_verified: 3
structural_fixes_still_holding: 6
prior_pass_fixes_still_holding: 15
prior_pass_fixes_regressed: 3  # F-PASS10-O2 + F-PASS12-O1 + F-PASS13-O1 at L280 + L523
new_findings_classification:
  - F-PASS16-I1: stale citation shorthand at L280 (`plan §A.4` should be `phased-build-plan.md §A.4`); regresses 3 prior-pass fixes
  - F-PASS16-I2: stale citation shorthand at L523 (`Plugin plan §3.15` should be `plugin-plan.md §3.15`); paired with I1
  - F-PASS16-I3: v0.4.10 changelog mis-counts structural fix as "4th in cascade"; actual is 6th by fix-count or 5th by version-count; process-gap
  - F-PASS16-S1: frontmatter `cross_platform` omits "Git Bash" though body cites 4x
  - F-PASS16-O1: plugin.json + hooks.json.template required by gates L297/L300/L366 but not in §Scope; 4th instance of gate-vs-scope defect class
recommended_next_action: |
  Dispatch v0.4.11 fix-burst. Bundle F-PASS16-I1+I2 as a single sibling-sweep fix
  with grep-verification of the fix; replace I3's count label with a semantic label
  ("Changelog audit-trail discipline") to eliminate count-drift class. Optional:
  S1 frontmatter Git-Bash addition; O1 plugin-infrastructure §Scope addition.
files_relevant_to_review:
  - /Users/jmagady/Dev/brain-factory/.factory/specs/product-brief.md
  - /Users/jmagady/Dev/brain-factory/.factory/cycles/v0.1-phase-1a-brief/adversary-pass-15.md
  - /Users/jmagady/Dev/brain-factory/.factory/planning/stage-3-locks.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-phased-build-plan.md
  - /Users/jmagady/Dev/brain-factory/docs/planning/llm-second-brain-plugin-plan.md
  - /Users/jmagady/Dev/brain-factory/CLAUDE.md
tool_profile_note: |
  Pass 16 adversary profile is read-only (Read/Grep/Glob). Report persisted by
  orchestrator via state-manager dispatch (this commit).
```
