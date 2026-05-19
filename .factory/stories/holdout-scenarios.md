---
artifact_type: holdout-scenarios
version: "v0.1.3"
created: 2026-05-19
last_updated: 2026-05-19
authored_by: vsdd-factory:product-owner
inputs:
  - product-brief.md@v0.4.20
  - prd/index.md@v0.1.12
  - behavioral-contracts/BC-INDEX.md@v0.1.14
  - architecture/ARCH-INDEX.md@v0.1.23
  - verification-properties/VP-INDEX.md@v0.1.7
  - stories/epics.md@v0.1.1
  - stories/dependency-graph.md@v0.1.0
  - stories/wave-schedule.md@v0.1.1
total_scenarios: 17
must_pass_count: 10
nice_to_pass_count: 7
phase: phase-2-story-decomposition-step-e
visibility: holdout-evaluator-only
access_control: restricted
---

# brain-factory Holdout Scenarios

**17 scenarios — 10 must-pass / 7 nice-to-pass. Phase 4 evaluator-only artifact.**

---

## §Discipline Statement

**READ THIS FIRST. These disciplines govern every evaluation decision.**

This artifact is restricted to the `vsdd-factory:holdout-evaluator` agent in Phase 4.
It must not be read by Phase 3 implementer agents, adversary agents, or any specialist
other than the holdout-evaluator. The information asymmetry is load-bearing: implementers
produced BCs, architecture, and stories WITHOUT seeing these scenarios; the evaluator
independently probes emergent behavior from those artifacts.

**Six holdout-scenario disciplines:**

1. **Scenarios are hidden from the implementer.** Phase 3 implementer and adversary agents
   have not seen this file. They implemented from BCs and stories alone. The holdout
   evaluator tests whether the resulting implementation exhibits the user-observable
   behaviors described here — behaviors the implementer had no direct specification for.

2. **Scenarios are USER-JOURNEY shaped, not BC-shaped.** Each scenario describes a
   multi-step workflow an operator performs. The evaluation question is: does the system
   behave correctly at the system boundary (observable files, frontmatter, exit codes,
   JSONL log entries, hook verdicts), not whether a single BC's precondition fires?

3. **Scenarios test EMERGENT BEHAVIOR.** They probe interactions between multiple stories.
   No single BC contemplates the full workflow in any scenario. If a scenario fails and
   no BC directly covers the failure, that is exactly the kind of gap holdout evaluation
   is designed to find. File the finding against the responsible subsystem.

4. **Scenarios must be testable.** Every expected outcome is stated in terms of file
   existence, frontmatter field values, JSONL log entries, hook exit codes, or process
   exit codes. Evaluators must not accept "the output looked reasonable" as a pass signal.
   Each acceptance signal is verifiable by reading files + grepping logs + checking codes.

5. **Must-pass vs nice-to-pass scoring.** MUST-PASS scenarios cover critical-defense paths
   (security, data integrity) and critical-capability paths (zero-to-brain, full publishing
   pipeline). A MUST-PASS scenario with evaluator satisfaction < 0.6 BLOCKS convergence.
   NICE-TO-PASS scenarios cover emergent-behavior probes and edge cases; they contribute
   to the mean satisfaction score (target ≥ 0.85) but do not individually block.

6. **Coverage intent, not enumeration.** These 17 scenarios collectively exercise the
   critical user-visible surface across all 9 epics. They are NOT one-per-BC. Each
   scenario is a meaningful integration test that produces a binary (pass/fail) result
   on the most important behavioral surface of the implementation.

---

## §Scope

The brain-factory v0.1 user-visible surface evaluated by these scenarios:

**Operator-invokable skills (26 skills via `/brain:` prefix):**
`/brain:init`, `/brain:health`, `/brain:upgrade-brain`,
`/brain:ingest-url`, `/brain:ingest-source`,
`/brain:quarantine-check`,
`/brain:lint-wiki`, `/brain:rename-page`,
`/brain:connect`, `/brain:process-inbox`, `/brain:synthesize`,
`/brain:brief`, `/brain:write`, `/brain:publish-content`, `/brain:monthly-perf`,
`/brain:adversary-review`,
`/brain:policy-add`, `/brain:policy-registry-validate`,
`/brain:install-actions`,
plus 7 additional specialist skills defined in the plugin manifest.

**Hook enforcement chain (13 bash hooks):**
`quarantine-fetch.sh` (PreToolUse/WebFetch),
`validate-source-immutability.sh` (PreToolUse/Write),
`validate-wikilink-integrity.sh` (PostToolUse/Write),
`validate-index-log-coherence.sh` (PostToolUse/Write),
`validate-frontmatter-schema.sh` (PostToolUse/Write),
`validate-page-type-policy.sh` (PostToolUse/Write),
`validate-source-id-citation.sh` (PostToolUse/Write),
`validate-publish-state.sh` (PostToolUse/Write),
`enforce-kebab-case.sh` (PreToolUse/Write),
`block-ai-attribution.sh` (PreToolUse/Bash),
`validate-voice-avoid-list.sh` (PostToolUse/Write),
`flush-state-and-commit.sh` (Stop),
`brain-health-check.sh` (SessionStart).

**Test infrastructure:**
8 category bats suites (`meta-lint.bats`, `skills.bats`, `templates.bats`,
`quarantine.bats`, `adversary.bats`, `policies.bats`, `upgrade.bats`,
`integration.bats`) plus one per-hook bats suite per hook script.

**Automation runtime:**
`bin/lobster-run` Lobster YAML executor, 19 GitHub Action templates
(6 v0.1 core + 9 v0.5 core + 4 community-optional).

**Governance:**
`.brain/policies.yaml` registry with 10 baseline policies.
`scripts/event-catalog.json` structured event catalog.

---

## §Scenarios

---

### HS-001 — Cold-Start Brain Initialization End-to-End

**Category:** must-pass

**Wave dependency:** Evaluable after W2 (STORY-001 + STORY-002 + STORY-003 complete).

**Operator setup:**
1. Create a new empty directory (e.g., `~/test-brain-001`).
2. Run `git init -b main` in that directory.
3. Confirm `Node 20+`, `jq`, and `yq` are available in PATH.

**Trigger sequence:**
1. Run `/brain:init` (no arguments) in the new directory.
2. Wait for completion.
3. Inspect the resulting file tree.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | All required directories exist: `.brain/`, `sources/`, `sources/ai/`, `sources/health/`, `sources/psychology/`, `sources/productivity/`, `sources/business/`, `sources/books/`, `sources/podcasts/`, `wiki/`, `wiki/concepts/`, `wiki/people/`, `wiki/frameworks/`, `wiki/syntheses/`, `wiki/observations/`, `wiki/questions/`, `briefs/`, `briefs/research/`, `to-publish/linkedin/`, `published/linkedin/`, `drafts/linkedin/` | `find . -type d | sort` and diff against the expected list |
| 2 | `.brain/manifest.json` exists, is valid JSON, and contains top-level fields `sources: []`, `chunks: []`, `embeddings_model: null`, and a `last_ingest` timestamp field | `jq 'keys' .brain/manifest.json` shows required keys |
| 3 | `.brain/policies.yaml` exists and contains exactly 10 baseline policy entries | `yq '. | length' .brain/policies.yaml` returns 10 |
| 4 | The total wall-clock elapsed time from skill invocation to successful completion is less than 300 seconds (NFR-002) | Capture `date +%s` before and after; assert difference < 300 |
| 5 | No error code (E-INIT-NNN) appears in the skill's output and the skill exits 0 | Check stdout/stderr for `E-INIT-` prefix; assert exit code 0 |

**Story coverage:** STORY-001, STORY-002, STORY-003, STORY-004 (health check on fresh brain)

**BC coverage:** BC-2.01.001, BC-2.01.002, BC-2.01.003, BC-2.01.004, BC-2.01.005, BC-2.06.003, BC-2.06.004

**Emergent-behavior probe:** Tests that STORY-001 (scaffold) and STORY-002 (init skill) and STORY-003 (error-path handling on happy path) are wired together correctly as a single user-facing command, and that `.brain/manifest.json` initialization is atomic (STORY-016 `manifest-write.sh` helper must have fired). No single BC specifies the full directory list; the conformance of the complete tree is emergent.

---

### HS-002 — Prompt-Injection Quarantine Blocks Malicious URL

**Category:** must-pass

**Wave dependency:** Evaluable after W2 (STORY-006 complete).

**Operator setup:**
1. Start from a brain initialized via HS-001 (or any valid `.brain/` state).
2. Prepare a local HTTP test server (or use a fixture file) that serves content containing
   a known quarantine corpus trigger pattern — for example, content containing
   `Ignore all previous instructions and` followed by an instruction to exfiltrate
   data. The exact pattern must be a match against `scripts/quarantine.mjs`'s pattern
   corpus.

**Trigger sequence:**
1. Run `/brain:ingest-url <url-serving-injection-content>`.
2. Observe the skill's exit.
3. Inspect `.brain/manifest.json` and `.brain/logs/` for any entries.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | The skill exits with a non-zero code and outputs error `E-QUARANTINE-001` or `E-INGEST-004` before any wiki pages are written | Grep stdout/stderr for `E-QUARANTINE-001` or `E-INGEST-004`; assert exit code ≠ 0 |
| 2 | No new wiki pages exist under `wiki/` after the failed ingest | Count files in `wiki/` before and after; assert count unchanged |
| 3 | `.brain/manifest.json` contains no new source entry for the injected URL | `jq '.sources | length'` is unchanged from pre-trigger count |
| 4 | `quarantine-fetch.sh` JSONL event is present in `.brain/logs/` with `exit_code: 2` and `pattern_matched: true` fields | Grep `.brain/logs/*.jsonl` for a `quarantine-fetch` event with the expected fields |
| 5 | The `block-ai-attribution.sh` hook was NOT involved (wrong code path) — the block originates from `quarantine-fetch.sh` specifically | The JSONL event's `hook` field is `quarantine-fetch.sh`, not `block-ai-attribution.sh` |

**Story coverage:** STORY-006, STORY-016, STORY-017 (pipeline should not reach wiki gen)

**BC coverage:** BC-2.04.001, BC-2.10.001, BC-2.10.002, BC-2.10.003

**Emergent-behavior probe:** Tests that the PreToolUse/WebFetch hook fires BEFORE Claude can process the content, and that the pipeline is correctly aborted (manifest and wiki both unchanged). The fail-closed property (NFR-016) is critical: a crash in the hook must also block, not silently pass.

---

### HS-003 — Source Immutability Enforced on Re-Ingest Attempt

**Category:** must-pass

**Wave dependency:** Evaluable after W3 (STORY-007 complete).

**Operator setup:**
1. Start from a brain with at least one successfully ingested source (e.g., run
   `/brain:ingest-source sources/ai/test-article.md` where the file exists and
   the initial ingest succeeded).
2. Note the sha256 checksum of the source file as it was at ingest time.
3. Modify the source file's content (append a line).

**Trigger sequence:**
1. Attempt `/brain:ingest-source sources/ai/test-article.md` a second time (same path,
   modified content).
2. Observe the hook verdict and exit code.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | The skill exits with a non-zero code before writing any new wiki pages | Assert exit code ≠ 0; count wiki pages unchanged |
| 2 | Error `E-SOURCE-001` appears in stdout/stderr | Grep for `E-SOURCE-001` |
| 3 | `.brain/manifest.json` still contains the original source record with the original sha256 — not the modified sha256 | `jq '.sources[] | select(.path=="sources/ai/test-article.md") | .sha256'` returns the original hash |
| 4 | `validate-source-immutability.sh` JSONL event exists in logs with `exit_code: 2` | Grep JSONL logs for the hook event |
| 5 | No wiki page from the second ingest attempt was written — the PostToolUse hook prevented it | List wiki pages; assert no new pages after the second attempt |

**Story coverage:** STORY-007, STORY-016, STORY-019

**BC coverage:** BC-2.04.002, BC-2.03.001, BC-2.03.002

**Emergent-behavior probe:** The immutability check requires the hook to read `manifest.json` and compare sha256 hashes across the entire pipeline. This exercises the STORY-016 atomic manifest-write helper and STORY-007's hook in concert. Tests that a partially-completed ingest (manifest found, hash compared, mismatch) is correctly blocked before any wiki writes occur — the ordering of hook firing relative to wiki generation is emergent.

---

### HS-004 — Wikilink Integrity Gate Catches Broken Link Before Commit

**Category:** must-pass

**Wave dependency:** Evaluable after W3 (STORY-008 complete).

**Operator setup:**
1. Start from a brain with at least 3 wiki pages (slugs `concept-a`, `concept-b`, `concept-c`
   under `wiki/concepts/`).
2. Confirm `/brain:lint-wiki` currently exits 0 (clean state).

**Trigger sequence:**
1. Directly edit `wiki/concepts/concept-a.md` to add a wikilink `[[nonexistent-concept]]`
   referencing a slug that does not exist in the wiki index.
2. Run `/brain:lint-wiki`.
3. Also attempt to save a new wiki page via any skill that triggers a PostToolUse/Write
   hook (e.g., a skill that writes to `wiki/concepts/concept-d.md` with a reference to
   `[[also-nonexistent]]`).

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | `/brain:lint-wiki` exits with a non-zero code and outputs a finding referencing `[[nonexistent-concept]]` | Assert exit ≠ 0; grep output for `nonexistent-concept` and `E-WIKI-001` |
| 2 | The broken-link finding appears in the structured output with `file`, `slug`, and `error_code` fields | Parse lint output JSON; confirm required fields present |
| 3 | The PostToolUse/Write hook (`validate-wikilink-integrity.sh`) fires on the new wiki page write and returns exit 2, preventing the write from being accepted by Claude Code | The hook JSONL event shows `exit_code: 2` and names `also-nonexistent` as the broken slug |
| 4 | `wiki/index.md` does NOT contain an entry for `nonexistent-concept` or `also-nonexistent` | Grep `wiki/index.md` for both slugs; assert absent |
| 5 | After the operator fixes the broken link (changes `[[nonexistent-concept]]` to `[[concept-b]]`), `/brain:lint-wiki` exits 0 | Re-run lint after fix; assert exit 0 |

**Story coverage:** STORY-008, STORY-020, STORY-021

**BC coverage:** BC-2.04.003, BC-2.04.006, BC-2.05.001, BC-2.05.002, BC-2.05.005

**Emergent-behavior probe:** Tests that both the explicit lint skill AND the PostToolUse hook fire consistently for the same violation class. A subtle emergent failure mode: the lint skill reads `wiki/index.md` using O(n) index-first resolution (BC-2.05.005), while the hook reads the same index. If the index was stale or the hook used a different resolution strategy, they would give inconsistent verdicts. This scenario detects that inconsistency.

---

### HS-005 — AI Attribution Blocked on Bash Command Containing Forbidden Token

**Category:** must-pass

**Wave dependency:** Evaluable after W3 (STORY-012 complete).

**Operator setup:**
1. Start from any initialized brain.
2. Have a commit-ready state (at least one staged file).

**Trigger sequence:**
1. Attempt to run a bash command that includes the string `Co-Authored-By: Claude` in its
   body — for example, a `git commit -m` command with that string in the message.
2. Observe whether `block-ai-attribution.sh` fires.
3. Also attempt to run a bash command containing a robot emoji (U+1F916) in its arguments.
4. Also attempt a command containing `Generated with Claude Code` in its arguments.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | The first bash command is blocked (exit 2) and error `E-ATTR-001` appears in output | Assert exit 2; grep for `E-ATTR-001` |
| 2 | The git commit does NOT appear in `git log` (the commit was prevented entirely) | `git log --oneline -1` shows a pre-existing commit, not the attempted one |
| 3 | The robot-emoji command is also blocked with `E-ATTR-001` | Assert exit 2 on the emoji command |
| 4 | The `Generated with Claude Code` command is also blocked with `E-ATTR-001` | Assert exit 2 |
| 5 | A bash command with no AI attribution tokens (e.g., a plain `git commit -m "feat: add page"`) is NOT blocked (exit 0 from the hook) | Run a clean commit and assert it proceeds without hook intervention |

**Story coverage:** STORY-012

**BC coverage:** BC-2.04.012

**Emergent-behavior probe:** Tests that the PreToolUse/Bash hook correctly scans the ENTIRE command string (not just the commit message flag value) and that the hook correctly distinguishes forbidden tokens from benign commands. The three-token check (Co-Authored-By, robot emoji, Generated with Claude Code) must all fire independently. The false-positive check (acceptance signal 5) is equally important: an overly aggressive hook that blocks all commits would be a production blocker.

---

### HS-006 — Multi-Page Wiki Output From Single URL Ingest

**Category:** must-pass

**Wave dependency:** Evaluable after W4 (STORY-017 complete; wiki page generation pipeline).

**Operator setup:**
1. Start from a clean initialized brain (HS-001 satisfied).
2. Choose a publicly accessible URL for a substantive article (e.g., a long-form
   technical blog post or Wikipedia article with multiple sub-concepts). The article
   must be extractable by Defuddle and must contain at least 5 distinct concepts.

**Trigger sequence:**
1. Run `/brain:ingest-url <url>`.
2. Wait for completion.
3. Inspect the wiki directory, manifest, and token log.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | At least 5 new wiki pages are created under `wiki/{type}/` with valid kebab-case filenames | `find wiki/ -name "*.md" -newer .brain/manifest.json.pre-ingest | wc -l` ≥ 5 |
| 2 | Each new wiki page has valid YAML frontmatter including `embedding_status: pending`, a non-empty `source_id` field referencing the ingested source slug, and a `type` matching a valid category | `yq '.embedding_status, .source_id, .type' wiki/{type}/{slug}.md` passes for each page |
| 3 | `.brain/manifest.json` has a new source entry with `url`, `sha256`, `ingested_at`, and `wiki_pages` fields; `wiki_pages` lists ≥ 5 slugs | `jq '.sources[-1] | {url, sha256, ingested_at, wiki_pages}' .brain/manifest.json` |
| 4 | `.brain/logs/ingest-tokens.jsonl` has a new line with fields `ts`, `source_slug`, `input_tokens`, `output_tokens`; `input_tokens` > 0 | `tail -1 .brain/logs/ingest-tokens.jsonl | jq '. | keys'` contains required fields |
| 5 | All new wiki pages pass `/brain:lint-wiki` (no broken wikilinks, valid frontmatter, valid type directories) | Run `/brain:lint-wiki` after ingest; assert exit 0 |

**Story coverage:** STORY-016, STORY-017, STORY-009, STORY-010, STORY-008, STORY-036

**BC coverage:** BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.005, BC-2.04.004, BC-2.04.007, BC-2.16.001

**Emergent-behavior probe:** Tests the complete ingest pipeline: Defuddle fetch (STORY-016) → wiki generation (STORY-017) → hook enforcement chain (STORY-009/010 frontmatter + type validation) → manifest write (STORY-016) → token logging (STORY-036). A subtle emergent point: wiki pages must pass lint IMMEDIATELY after ingest, meaning the hooks that fire during page writes must produce pages that are consistent with the lint-wiki check. If the wiki generator produces pages that the hooks accept but lint-wiki later rejects, that is a cross-story consistency failure.

---

### HS-007 — Full Content Production Pipeline: Ingest to Published

**Category:** must-pass

**Wave dependency:** Evaluable after W9 (STORY-028 + STORY-029 + STORY-030 complete; full publishing chain).

**Operator setup:**
1. Start from a brain with at least 5 URLs already ingested across 2 distinct topics
   (e.g., 3 URLs on topic "mental models", 2 URLs on topic "learning science").
2. Configure `policies.yaml` with a valid LinkedIn API credential entry
   (or a test-mode credential that the LinkedIn API mock accepts).

**Trigger sequence:**
1. Run `/brain:connect 7` (discover top-7 cross-domain connections from ingested content).
2. Run `/brain:synthesize` (generate weekly thesis from connection layer output).
3. Run `/brain:brief <topic>` where `<topic>` is "mental models" (or any topic with ≥ 3
   ingested sources). This produces `briefs/<topic>-<date>.md`.
4. Run `/brain:adversary-review briefs/<topic>-<date>.md` and continue until the streak
   counter in `.brain/STATE.md` reaches `3/3 CONVERGED`.
5. Run `/brain:write --brief briefs/<topic>-<date>.md`. This produces a draft in
   `drafts/linkedin/<slug>.md`.
6. Run `/brain:publish-content drafts/linkedin/<slug>.md` to move to ready state.
7. Run `/brain:publish-content to-publish/linkedin/<slug>.md --finalize --url
   https://www.linkedin.com/posts/test-article-001` to complete the publish flow.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | `briefs/<topic>-<date>.md` exists and contains the three required sections: `ONE THING`, `PROOF`, and `TRANSFORMATION` | Grep brief file for section headings; assert all three present |
| 2 | After step 4, `.brain/STATE.md` contains `adversary_streak: 3` and `adversary_status: CONVERGED` | `grep 'adversary_streak\|adversary_status' .brain/STATE.md` returns expected values |
| 3 | `drafts/linkedin/<slug>.md` exists with `status: draft` frontmatter; after step 6, the file is moved to `to-publish/linkedin/<slug>.md` with `status: ready` | Check file existence and frontmatter at each state |
| 4 | After step 7, `published/linkedin/<slug>.md` exists with `status: published`, `published_at` as an ISO8601 timestamp, and `linkedin_post_id` field present | `yq '.status, .published_at, .linkedin_post_id' published/linkedin/<slug>.md` |
| 5 | `validate-publish-state.sh` JSONL log shows three valid state transitions: draft→ready, ready→published; no invalid transitions logged | Grep JSONL logs for `validate-publish-state` events; assert no `E-PUBLISH-001` errors |

**Story coverage:** STORY-024, STORY-025, STORY-027, STORY-028, STORY-029, STORY-030, STORY-040, STORY-041

**BC coverage:** BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.09.001, BC-2.09.002, BC-2.09.004, BC-2.07.001, BC-2.07.002, BC-2.07.003, BC-2.07.004, BC-2.11.001, BC-2.11.002

**Emergent-behavior probe:** This is the end-to-end critical-capability scenario. Each step's output feeds the next step's input. The emergent question: does the complete pipeline maintain consistent file state across all state transitions, including the adversarial review streak counter correctly resetting on findings and incrementing on clean passes? The state machine (draft→ready→published) must be enforced by the hook, not by the skill alone.

---

### HS-008 — `/brain:health` Six-Dimensional Report After Substantial Use

**Category:** must-pass

**Wave dependency:** Evaluable after W6 (STORY-037 complete; token budget alert in health).

**Operator setup:**
1. Start from a brain that has been used substantially: ≥ 10 URLs ingested across
   ≥ 2 sessions, ≥ 3 briefs produced, at least one publish completed.
2. Confirm `.brain/logs/ingest-tokens.jsonl` has at least 10 entries (one per ingest).

**Trigger sequence:**
1. Run `/brain:health`.
2. Inspect the JSON output.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | The output is valid JSON with exactly 6 top-level dimension keys corresponding to the six health dimensions (content depth, connection density, synthesis currency, publishing cadence, schema compliance, token budget) | `jq 'keys | length'` returns 6; each key matches the expected dimension names |
| 2 | Each dimension has a `status` field with one of: `GREEN`, `YELLOW`, or `RED` | `jq '.[] | .status' health_output.json` returns only valid values for all 6 dimensions |
| 3 | The `token_budget` dimension includes a `trailing_30d_average_tokens` field computed from `.brain/logs/ingest-tokens.jsonl` | Assert field present and numeric; verify it matches manual aggregation of last 30 days of log entries |
| 4 | The health skill exits 0 when all dimensions are GREEN, and exits 1 (advisory) when any dimension is YELLOW or RED | Manipulate a known-good brain to force a YELLOW condition (e.g., no synthesis in 7 days) and verify exit 1 |
| 5 | `brain-health-check.sh` (SessionStart hook) fires on the next session open and emits a summary banner matching the `/brain:health` output structure | Simulate SessionStart; grep JSONL logs for `brain-health-check` event; assert `status` field present |

**Story coverage:** STORY-004, STORY-036, STORY-037, STORY-013

**BC coverage:** BC-2.01.006, BC-2.16.001, BC-2.16.002, BC-2.04.013, BC-2.04.014

**Emergent-behavior probe:** Tests that the six health dimensions are all computable from available data (wiki/, manifest.json, logs/) and that the 30-day trailing average is correctly aggregated from the JSONL log written by STORY-036's instrumentation. The SessionStart hook (STORY-013) re-runs the same computation; consistency between the skill output and the hook banner is emergent.

---

### HS-009 — Partial-Failure Fan-Out on Multi-Resource Ingest

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W5 (STORY-019 complete; partial-failure fan-out).

**Operator setup:**
1. Start from a clean initialized brain.
2. Prepare a local source file (e.g., `sources/ai/mixed-quality.md`) that contains
   5 sections: 3 sections with well-formed markdown and clear concepts, 1 section with
   content that will trigger the `< 5 extractable concepts` warning (minimal substance),
   and 1 section with a valid wikilink reference to an existing concept.

**Trigger sequence:**
1. Run `/brain:ingest-source sources/ai/mixed-quality.md`.
2. Observe exit code and output.
3. Check wiki pages created and the JSONL log.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | The skill exits with code 1 (degraded/advisory), not 0 (full success) or 2 (block) | Assert exit code == 1 |
| 2 | At least 3 wiki pages are created (for the valid sections) and logged in manifest | Count new wiki pages ≥ 3 |
| 3 | The JSONL log contains per-item results: successful items have `status: ok`; the weak-content item has `status: degraded` with code `E-INGEST-006` | `grep E-INGEST-006 .brain/logs/*.jsonl` returns one line for the weak section |
| 4 | `.brain/manifest.json` records the source with `partial_ingest: true` and lists only the successfully created wiki pages | `jq '.sources[-1].partial_ingest' .brain/manifest.json` returns `true` |
| 5 | Running `/brain:lint-wiki` after the partial ingest exits 0 (no broken links from the partial ingest) | Assert lint exits 0 |

**Story coverage:** STORY-019, STORY-017, STORY-008, STORY-036

**BC coverage:** BC-2.03.002, BC-2.03.003, BC-2.02.003, BC-2.02.005, BC-2.16.001

**Emergent-behavior probe:** Tests BC-2.03.002 (partial-failure fan-out) across the full ingest pipeline. A naive implementation might either fail the entire ingest (too conservative) or silently proceed with all items (too permissive). The correct behavior — partial success with explicit per-item result logging — requires the STORY-019 fan-out logic and STORY-036 JSONL instrumentation to be wired together. Also confirms lint-wiki is not confused by a partially-ingested source.

---

### HS-010 — Idempotent Upgrade: `/brain:upgrade-brain` Run Twice

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W6 (STORY-005 complete; upgrade skill).

**Operator setup:**
1. Start from a brain initialized with brain-factory v0.1.
2. Simulate an upgrade scenario by incrementing the plugin version field in `plugin.json`
   to `v0.2` (or use the actual v0.2 artifact if available during Phase 4).

**Trigger sequence:**
1. Run `/brain:upgrade-brain` (first invocation — performs migration from v0.1 to v0.2).
2. Confirm the brain is in the upgraded state.
3. Run `/brain:upgrade-brain` a second time immediately (idempotency test).
4. Inspect the brain state after both runs.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | First invocation exits 0 and updates `.brain/manifest.json` schema version field | `jq '.schema_version' .brain/manifest.json` returns the new version string after first run |
| 2 | Second invocation exits 0 (no-op) with a message indicating "already at target version" | Assert exit 0 and grep output for "already at target" or equivalent |
| 3 | No data loss: source count and wiki page count are identical before first run and after second run | Compare counts before/after both runs |
| 4 | `.brain/manifest.json` is not duplicated, corrupted, or partially written | `jq '.' .brain/manifest.json` parses cleanly after second run |
| 5 | The JSONL log records both invocations: first as `migration_applied`, second as `migration_skipped` | Grep logs for both event types |

**Story coverage:** STORY-005

**BC coverage:** BC-2.14.001, BC-2.14.002

**Emergent-behavior probe:** NFR-024 requires idempotency; this scenario operationalizes that requirement. The interesting emergent behavior: if the first upgrade modifies `manifest.json` structure and the second run parses the already-upgraded manifest expecting the OLD structure, it will fail. The migration code must be schema-version-aware, not just mechanically re-apply the same transformation.

---

### HS-011 — Out-of-Vault Path Traversal Rejected

**Category:** must-pass

**Wave dependency:** Evaluable after W5 (STORY-019 complete; path validation in local ingest).

**Operator setup:**
1. Start from any initialized brain.
2. No special setup required.

**Trigger sequence:**
1. Run `/brain:ingest-source ../../../etc/passwd` (path traversal attempt).
2. Also attempt `/brain:ingest-source /tmp/outside-vault.md` (absolute path outside vault).
3. Also attempt `/brain:ingest-source sources/../../../etc/passwd` (normalized traversal).

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | All three commands exit with code 2 (block) and output `E-INGEST-009` | Assert exit 2 and grep for `E-INGEST-009` on each attempt |
| 2 | No file outside the brain vault directory is read or modified by the skill | Verify `/etc/passwd` mtime is unchanged; verify no `/tmp/*.md` was accessed |
| 3 | `.brain/manifest.json` is unchanged after all three attempts | sha256 of manifest before == sha256 after |
| 4 | No JSONL log entry with `status: ok` exists for any of these paths | Grep JSONL logs for the attempted paths; assert no `status: ok` entries |
| 5 | A valid within-vault path (`sources/ai/valid.md`) succeeds after the failed attempts (hook does not corrupt state) | Run `/brain:ingest-source sources/ai/valid.md` and assert exit 0 |

**Story coverage:** STORY-019

**BC coverage:** BC-2.03.001, BC-2.03.004

**Emergent-behavior probe:** Security-critical path validation (NFR-013 complementary to quarantine). Tests that path canonicalization and vault-boundary checking are applied correctly to ALL forms of path traversal attempts — not just the simplest `..` form. Also tests that a failed path-traversal attempt does not corrupt the hook/skill state for subsequent valid requests.

---

### HS-012 — Voice Avoid-List Advisory Does Not Block Commit

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W3 (STORY-010 complete; voice advisory hook).

**Operator setup:**
1. Start from any initialized brain.
2. Confirm the voice avoid-list exists at `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt`
   and contains at least 5 forbidden words/phrases (one per line). Note three of them for use in the test.

**Trigger sequence:**
1. Write a new brief draft file to `drafts/linkedin/test-voice-draft.md` that deliberately
   uses 5 words from the voice avoid-list in the body text.
2. Observe whether the PostToolUse/Write hook (`validate-voice-avoid-list.sh`) fires.
3. Observe whether the write is blocked or advisory.
4. Attempt to run a downstream operation on the file (e.g., `/brain:adversary-review`).

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | The file IS written (not blocked) — the hook exits 1 (advisory), not 2 (block) | Assert the file exists at `drafts/linkedin/test-voice-draft.md` after the write attempt |
| 2 | Error code `E-VOICE-001` appears in Claude Code's output as a cosmetic advisory | Grep Claude output for `E-VOICE-001` |
| 3 | The JSONL log records the hook firing with `exit_code: 1` and `matches` listing the 5 forbidden words | `grep E-VOICE-001 .brain/logs/*.jsonl | jq '.matches | length'` returns 5 |
| 4 | Subsequent operations on the file (e.g., adversary review) proceed without being blocked by the advisory | Assert downstream operations exit 0 when the file is otherwise valid |
| 5 | A brief with ZERO voice avoid-list matches triggers no advisory (hook exits 0, no E-VOICE-001 in output) | Write a clean draft; assert no advisory fires |

**Story coverage:** STORY-010

**BC coverage:** BC-2.04.008

**Emergent-behavior probe:** Tests the advisory-vs-block distinction (exit 1 vs exit 2) which is foundational to the hook contract. An implementation that accidentally exits 2 (block) would make brain-factory unusable for any operator who has idiomatic phrases in their writing style. Tests that the hook communicates the issue without preventing the operator from proceeding.

---

### HS-013 — Lobster Headless Workflow Executes Without stdin Blocking

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W5 (STORY-033 complete; lobster headless execution).

**Operator setup:**
1. Start from a brain with all 6 workflow YAML files in place (produced by STORY-033).
2. Have a CI-like environment: no interactive terminal (simulate by piping `/dev/null`
   to stdin).

**Trigger sequence:**
1. Run `bin/lobster-run --workflow workflows/ingest-and-lint.yaml < /dev/null`.
2. Run each of the 6 available workflow YAML files in headless mode.
3. Observe exit codes and output.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | All 6 workflow runs complete without blocking on stdin (no "waiting for input" hang) | Assert all 6 complete within 30 seconds with non-blocking termination |
| 2 | Each workflow exits with one of the documented codes: 0 (success), 1 (skill advisory), 2 (skill blocked), 3 (cycle detected), 4 (skill not found) | Assert exit codes are in {0,1,2,3,4} |
| 3 | A workflow YAML with a circular dependency (`A depends_on B`, `B depends_on A`) is detected and exits 3 with `E-LOBSTER-001` | Create a cycle-test.yaml fixture; assert exit 3 and `E-LOBSTER-001` |
| 4 | The topological sort executes skills in dependency order (skill B runs before skill C when C depends_on B) | Log timestamps of skill invocations in JSONL; assert B's `ts` < C's `ts` |
| 5 | A workflow referencing a non-existent skill name exits 4 with `E-LOBSTER-002` | Test with a workflow referencing `brain:nonexistent-skill`; assert exit 4 |

**Story coverage:** STORY-032, STORY-033

**BC coverage:** BC-2.12.001, BC-2.12.002, BC-2.12.003, BC-2.12.004

**Emergent-behavior probe:** Tests that `bin/lobster-run` is genuinely headless (BC-2.12.003 invariant) — a skill that prompts for interactive input would hang indefinitely in CI. Also tests that the topological sort ordering is preserved under real execution, not just in the topo-sort unit test. If the dependency graph is correct but the execution scheduler doesn't honor the order, that's an emergent failure.

---

### HS-014 — Adversarial Review Streak Counter Tracks 3-CLEAN Convergence

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W6 (STORY-040 + STORY-041 complete; streak counter).

**Operator setup:**
1. Start from a brain with a draft brief at `briefs/test-brief-streak.md`.
2. Configure policies.yaml to use a different model for the adversary than the producer
   (required by BC-2.07.001 and E-ADVERSARY-001).

**Trigger sequence:**
1. Run `/brain:adversary-review briefs/test-brief-streak.md` — expect at least one finding
   (the brief has deliberately introduced a weak claim that the adversary should catch).
2. Observe `.brain/STATE.md` streak counter after pass 1.
3. Fix the finding in the brief.
4. Run `/brain:adversary-review briefs/test-brief-streak.md` again — expect a clean pass.
5. Run a third time (clean pass).
6. Run a fourth time (clean pass — this completes 3 consecutive clean passes).
7. Observe `.brain/STATE.md` for CONVERGED status.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | After pass 1 (finding), `.brain/STATE.md` contains `adversary_streak: 0` (finding resets streak) | Grep STATE.md for `adversary_streak`; assert 0 |
| 2 | After pass 2 (first clean), streak is `1` | Assert `adversary_streak: 1` |
| 3 | After pass 3 (second clean), streak is `2` | Assert `adversary_streak: 2` |
| 4 | After pass 4 (third clean), STATE.md shows `adversary_streak: 3` AND `adversary_status: CONVERGED` | Assert both fields |
| 5 | The verdict JSON from each pass has the correct schema: `{pass: N, verdict: PASS|FAIL, findings: [...], score: N.NN}` | Parse each verdict file; assert schema conforms to BC-2.07.004 specification |

**Story coverage:** STORY-040, STORY-041

**BC coverage:** BC-2.07.001, BC-2.07.002, BC-2.07.003, BC-2.07.004

**Emergent-behavior probe:** Tests that the streak counter in STATE.md is correctly maintained across multiple skill invocations (not in-memory state). A naive implementation that uses in-memory counters would pass the unit tests but fail this scenario (streak lost between sessions). Also tests the reset-on-finding invariant: if the streak counter fails to reset after a finding, it can falsely claim convergence.

---

### HS-015 — Policy Registry Duplicate Detection and Validation

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W8 (STORY-042 + STORY-043 complete; policy operations).

**Operator setup:**
1. Start from an initialized brain with `.brain/policies.yaml` containing the 10 baseline
   policies (produced by STORY-042).
2. Confirm `/brain:policy-registry-validate` exits 0 on the baseline state.

**Trigger sequence:**
1. Add a new valid policy via `/brain:policy-add`:
   ```
   id: test-policy-001
   name: Test Policy
   description: A policy for holdout testing.
   enforcement: advisory
   severity: low
   ```
2. Attempt to add the same policy ID again (`/brain:policy-add` with `id: test-policy-001`).
3. Attempt to add a policy with missing required fields (omit `description`).
4. Run `/brain:policy-registry-validate` on the resulting registry.

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | First `/brain:policy-add` exits 0 and the policy count increases from 10 to 11 | `yq '. | length' .brain/policies.yaml` returns 11 after first add |
| 2 | Second `/brain:policy-add` with duplicate ID exits 2 and outputs `E-POLICY-001` | Assert exit 2; grep for `E-POLICY-001` |
| 3 | After the duplicate-ID rejection, policy count remains 11 (not 12) | `yq '. | length' .brain/policies.yaml` still returns 11 |
| 4 | `/brain:policy-add` with missing `description` exits 2 with `E-POLICY-003` referencing the missing field | Assert exit 2; grep for `E-POLICY-003` and `description` |
| 5 | `/brain:policy-registry-validate` exits 0 on the 11-policy registry (all 11 are valid) | Assert exit 0 |

**Story coverage:** STORY-042, STORY-043

**BC coverage:** BC-2.15.001, BC-2.15.002, BC-2.15.003

**Emergent-behavior probe:** Tests that the `id` uniqueness invariant is enforced at write time (not just at validation time). An implementation that adds the duplicate and relies on `policy-registry-validate` to catch it later would fail acceptance signal 3. Also tests that partial-YAML (missing fields) is caught with the specific field named in the error, not a generic "invalid YAML" message.

---

### HS-016 — GH Action Templates Install and Structural Validity

**Category:** nice-to-pass

**Wave dependency:** Evaluable after W6 (STORY-034 complete; v0.1 templates + install-actions skill).

**Operator setup:**
1. Start from an initialized brain.
2. Have a `.github/workflows/` directory (or allow the skill to create it).

**Trigger sequence:**
1. Run `/brain:install-actions` to install the v0.1 core GH Action templates.
2. Inspect the installed YAML files.
3. Attempt to validate each template with `yq` (YAML syntax check) and a GitHub Actions
   schema check (e.g., via `actionlint` if available, or schema validation).

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | Exactly 6 workflow YAML files are installed under `.github/workflows/` | `ls .github/workflows/*.yml | wc -l` returns 6 |
| 2 | Each of the 6 files is valid YAML (no parse errors) | `for f in .github/workflows/*.yml; do yq '.' "$f" > /dev/null && echo PASS; done` — all 6 PASS |
| 3 | Each template has a `name:` field and at least one `on:` trigger | `yq '.name, .on | keys' .github/workflows/*.yml` returns non-empty values for each |
| 4 | Running `/brain:install-actions` a second time is idempotent (no duplicate files, no error) | Assert file count remains 6 and exit code is 0 on second run |
| 5 | The `scale-test.yml` template (used by HS for STORY-039 scale gate) is present in the installed set | `ls .github/workflows/scale-test.yml` exists |

**Story coverage:** STORY-034

**BC coverage:** BC-2.13.001

**Emergent-behavior probe:** Tests the idempotency of the install-actions skill (not specified in a single BC — emergent from the system design) and that all 6 templates are structurally valid enough to be parsed by downstream tools. The `scale-test.yml` acceptance signal connects this scenario to HS for STORY-039 (scale gate), testing that the templates installed here form a coherent test infrastructure for Phase 4 scale validation.

---

### HS-017 — Scale Gate: 1K-Page Ingest Latency Stays Sub-Linear

**Category:** must-pass

**Wave dependency:** Evaluable after W7 (STORY-018 + STORY-038 complete; sub-linear gate + corpus generator).

**Operator setup:**
1. Run `scripts/gen-test-corpus.sh --sources 100 --seed 42` to generate a 100-source
   baseline corpus.
2. Use the generated corpus to pre-load 100 sources via `/brain:ingest-source` for each.
3. Record the total time for 100-source ingest as T(100).
4. Run `scripts/gen-test-corpus.sh --sources 1000 --seed 42` for a 1000-source corpus.

**Trigger sequence:**
1. Ingest the 1000-source corpus.
2. Record total wall-clock time as T(1K).
3. Compute the scaling ratio T(1K) / T(100).

**Expected outcomes:**

| # | Acceptance Signal | How to Verify |
|---|------------------|---------------|
| 1 | T(1K) completes without OOM error and without any partial-manifest corruption | Assert process exits 0; `jq '.' .brain/manifest.json` parses cleanly after ingest |
| 2 | `scripts/gen-test-corpus.sh --sources 1000 --seed 42` produces the same corpus on two runs (deterministic output — same sha256 per file) | Run twice; assert sha256 of all generated files matches between runs (BC-2.16.006) |
| 3 | T(1K) / T(100) ≤ 20 (sub-linear scaling ratio: NFR-004, BC-2.02.007) | Compute ratio; assert ≤ 20 |
| 4 | `.brain/logs/ingest-tokens.jsonl` contains exactly 1000 entries after the 1000-source ingest | `wc -l .brain/logs/ingest-tokens.jsonl` returns 1000 |
| 5 | `/brain:lint-wiki` completes on the resulting wiki (expected 5K-10K pages) within 600 seconds (NFR-003) | Time lint run; assert < 600s |

**Story coverage:** STORY-018, STORY-038, STORY-036, STORY-020

**BC coverage:** BC-2.02.007, BC-2.16.006, BC-2.16.001, BC-2.05.001, BC-2.05.005

**Emergent-behavior probe:** Tests the sub-linear scaling invariant (BC-2.02.007, NFR-004) in the real ingest pipeline, not just via the bats scale assertion. The bats test asserts the property under a synthetic fixture; this holdout scenario exercises it under the actual pipeline implementation with real corpus data. A regression in the O(n) wikilink resolution (BC-2.05.005) would cause lint to scale quadratically and fail acceptance signal 5.

---

## §Story Coverage Verification

| Story | Scenarios Exercising | At Least One? |
|-------|---------------------|--------------|
| STORY-001 | HS-001 | YES |
| STORY-002 | HS-001 | YES |
| STORY-003 | HS-001 | YES |
| STORY-004 | HS-001, HS-008 | YES |
| STORY-005 | HS-010 | YES |
| STORY-006 | HS-002 | YES |
| STORY-007 | HS-003 | YES |
| STORY-008 | HS-004, HS-006, HS-009 | YES |
| STORY-009 | HS-006 | YES |
| STORY-010 | HS-006, HS-012 | YES |
| STORY-011 | HS-007 (publish state machine) | YES |
| STORY-012 | HS-005 | YES |
| STORY-013 | HS-008 | YES |
| STORY-014 | HS-002, HS-006 (event catalog + emit) | YES |
| STORY-015 | HS-002, HS-003 (hook meta-lint: all hooks must conform) | YES |
| STORY-016 | HS-002, HS-003, HS-006 | YES |
| STORY-017 | HS-006, HS-009 | YES |
| STORY-018 | HS-017 | YES |
| STORY-019 | HS-003, HS-009, HS-011 | YES |
| STORY-020 | HS-004, HS-006, HS-017 | YES |
| STORY-021 | HS-004 (rename exercised by lint follow-up) | YES |
| STORY-022 | HS-005 (meta-lint covers all SKILL.md including block-ai-attribution) | YES |
| STORY-023 | HS-002, HS-003 (per-hook completeness gate validates all hooks in scenarios) | YES |
| STORY-024 | HS-007 | YES |
| STORY-025 | HS-007 | YES |
| STORY-026 | HS-007 (inbox → connect flow) | YES |
| STORY-027 | HS-007 | YES |
| STORY-028 | HS-007 | YES |
| STORY-029 | HS-007 | YES |
| STORY-030 | HS-007 | YES |
| STORY-031 | HS-008 (monthly-perf shares token log with health) | YES |
| STORY-032 | HS-013 | YES |
| STORY-033 | HS-013 | YES |
| STORY-034 | HS-016 | YES |
| STORY-035 | HS-017 (api-retry used in scale-test workflow) | YES |
| STORY-036 | HS-006, HS-008, HS-017 | YES |
| STORY-037 | HS-008 | YES |
| STORY-038 | HS-017 | YES |
| STORY-039 | HS-017 (scale gate scenario exercises same assertions) | YES |
| STORY-040 | HS-007, HS-014 | YES |
| STORY-041 | HS-007, HS-014 | YES |
| STORY-042 | HS-015 | YES |
| STORY-043 | HS-015 | YES |

**Coverage: 43/43 stories — 100%.**

---

## §BC Coverage Verification

Scenarios exercise the following BCs (partial list — primary BCs per scenario):

BC-2.01.001, BC-2.01.002, BC-2.01.003, BC-2.01.004, BC-2.01.005, BC-2.01.006 (HS-001, HS-008)
BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.005, BC-2.02.006, BC-2.02.007 (HS-006, HS-009, HS-017)
BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004 (HS-003, HS-009, HS-011)
BC-2.04.001, BC-2.04.002, BC-2.04.003, BC-2.04.004, BC-2.04.006, BC-2.04.007, BC-2.04.008, BC-2.04.009, BC-2.04.010, BC-2.04.011, BC-2.04.012, BC-2.04.013, BC-2.04.014, BC-2.04.015, BC-2.04.016, BC-2.04.017 (HS-002..006, HS-008)
BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005, BC-2.05.006 (HS-004, HS-006, HS-017)
BC-2.06.001, BC-2.06.002, BC-2.06.003, BC-2.06.004 (HS-001, HS-008)
BC-2.07.001, BC-2.07.002, BC-2.07.003, BC-2.07.004 (HS-007, HS-014)
BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.08.004 (HS-007)
BC-2.09.001, BC-2.09.002, BC-2.09.003, BC-2.09.004, BC-2.09.005, BC-2.09.006 (HS-007, HS-008)
BC-2.10.001, BC-2.10.002, BC-2.10.003 (HS-002)
BC-2.11.001, BC-2.11.002, BC-2.11.003 (HS-007)
BC-2.12.001, BC-2.12.002, BC-2.12.003, BC-2.12.004 (HS-013)
BC-2.13.001, BC-2.13.002, BC-2.13.003, BC-2.13.004 (HS-016, HS-017)
BC-2.14.001, BC-2.14.002, BC-2.14.003, BC-2.14.004, BC-2.14.005 (HS-001, HS-010)
BC-2.15.001, BC-2.15.002, BC-2.15.003 (HS-015)
BC-2.16.001, BC-2.16.002, BC-2.16.003, BC-2.16.004, BC-2.16.005, BC-2.16.006 (HS-008, HS-017)
BC-2.17.001, BC-2.17.002, BC-2.17.003, BC-2.17.004 (HS-002, HS-003 — event catalog validation)
BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.004, BC-2.18.005 (HS-005, HS-002 — meta-lint fires on hook coverage)

**Estimated BC coverage: 87/95 BCs (91.6%).** The 8 BCs not directly named in a scenario
acceptance signal are covered transitively (hooks that fire in the background of scenarios
that exercise the hook chain). BC-2.04.005 (embedding_status pending write), BC-2.02.004
(duplicate guard), BC-2.09.005 (publishing directories), and similar infrastructure BCs
are exercised in HS-001, HS-006, HS-007 as side effects of the primary acceptance signals.

---

## §Changelog

### v0.1.3 — 2026-05-19

**INPUT REFRESH (F-PHASE2-DECOMP-GATE-RETRY-INFO-01):** Stale input version references updated: `stories/wave-schedule.md@v0.1.0` → `@v0.1.1` (wave-schedule bumped in Phase 2 Step F story-writer burst); `behavioral-contracts/BC-INDEX.md@v0.1.13` → `@v0.1.14` (BC-INDEX bump in this PO burst for BC-2.04.015 v1.3 + BC-2.04.016 v1.3). No scenario content changed. [audit-trail]

### v0.1.2 — 2026-05-19

**PATH FIX (F-PHASE2-DECOMP-GATE-I03):** HS-012 Operator Setup step 2 voice avoid-list path corrected from `${CLAUDE_PLUGIN_ROOT}/voice-avoid-list.yaml` to `${CLAUDE_PLUGIN_ROOT}/rules/voice-avoid-list.txt` to align with STORY-027 AC-004, BC-2.04.008 Precondition §2, and BC-2.08.004 canonical paths. Also clarified "contains at least 5 forbidden words/phrases (one per line)". No scenario semantics changed.

### v0.1.1 — 2026-05-19

Micro-fix F-PHASE2-STEP-E-O1: frontmatter count drift corrected — total_scenarios 15→17,
must_pass_count 8→10, nice_to_pass_count unchanged at 7. Body content unchanged. Discipline
statement and body summary line updated to match. Version bumped from v0.1.0.

### v0.1.0 — 2026-05-19

Initial holdout scenarios for brain-factory v0.1. 15 scenarios (8 must-pass, 7 nice-to-pass).
All 43 stories covered. Estimated 91.6% BC coverage. Produced in Phase 2 Step E by
vsdd-factory:product-owner.
