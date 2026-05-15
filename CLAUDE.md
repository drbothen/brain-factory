# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

> **Toolchain:** Bash (`set -euo pipefail`) for hooks, Claude Code skills (`SKILL.md` frontmatter + procedure), Claude Code agents (`AGENT.md`). Tests via `bats-core`. Lint via `shellcheck` + `shfmt`. No Rust, no JS test framework, no compiled binaries in v0.x — pure bash + markdown for tests and hooks. **Node 20+ is required at the operator's machine** for narrow utilities only: Defuddle CLI (clean web extraction, ~70-90% token savings on `/brain:ingest-url`) and `scripts/run-skill.mjs` (headless skill runner powering scheduled GitHub Actions). WASM hooks via factory-dispatcher = v1.0 (post-MVP). This is the **brain-factory plugin source repo**, not a brain vault. Brain content (sources, wiki, briefs) lives in a separate per-user repo.

---

## Project Identity

`brain-factory` is a Claude Code plugin that turns Obsidian-style vaults into LLM-maintained second brains. It is the **second factory** in a planned family alongside `vsdd-factory` (Verified Spec-Driven Development) and a planned shared `factory-dispatcher` (the hook runtime).

This repo contains:
- Plugin source (will live under `plugins/brain-factory/` once Phase 1 starts)
- Planning artifacts (`docs/planning/`)
- Tests (`plugins/brain-factory/tests/` — bats suites)
- CI workflows (`.github/workflows/`)

This repo does NOT contain:
- A user's brain vault (sources, wiki, briefs). That's a separate per-user repo.
- The shared dispatcher source. That's `factory-dispatcher`, a separate repo.

**Current state: pre-v0.1, GREENFIELD MODE.** Planning is complete; the VSDD greenfield pipeline is being kicked off to drive the build. The phased build plan ([`docs/planning/llm-second-brain-phased-build-plan.md`](docs/planning/llm-second-brain-phased-build-plan.md)) is the design source of truth that feeds Phase 1 spec crystallization.

---

## Source-of-Truth Precedence

When two artifacts disagree, the **LATER, MORE-SPECIFIC artifact wins**. Apply this rule when adversary, consistency-validator, or spec-reviewer surfaces a conflict between two project documents:

1. **Story spec** (under `.factory/stories/`) supersedes the BC it traces to, when the conflict is about implementation scope. The BC supersedes when the conflict is about contract semantics.
2. **ADR** (under `.factory/specs/architecture/adr/` or numbered `ADR-NNN-*.md`) supersedes earlier ADRs that address the same decision; superseded ADRs are marked with explicit `Supersedes: ADR-NNN` and `Superseded by: ADR-MMM` frontmatter back-refs.
3. **PRD supplements** (`interface-definitions`, `error-taxonomy`, `nfr-catalog`, `test-vectors`) supersede the PRD prose for the same surface area.
4. **VP files** (`.factory/specs/verification-properties/`) supersede the prose verification narrative in PRD/architecture for the property they cover.
5. **Recent `.factory/STATE.md` decision rows (D-NNN)** supersede earlier-recorded but conflicting narrative in SESSION-HANDOFF.md.
6. **Recent adversary pass reports** supersede earlier pass reports for the same finding ID (cascade closure rationale tracks the chain).
7. **For code-vs-spec conflicts**: the SPEC wins (Standing Rule for VSDD). Code is brought into alignment via fix-burst or follow-up story, not the other way around. Only the human can authorize spec amendment to match code.
8. **Planning artifacts under `docs/planning/`** are immutable design source-of-truth for the build. They feed Phase 1 spec crystallization; once the .factory/ specs are written, the .factory/ specs are the operational source of truth, and planning artifacts become historical context. Planning artifacts may only be amended by explicit human direction.

If two artifacts are at the same precedence level and disagree, surface to the orchestrator. The orchestrator routes to the artifact's owner-specialist (e.g., BC vs BC → product-owner; ADR vs ADR → architect) for adjudication.

---

## Pipeline Authority

The orchestrator (`vsdd-factory:orchestrator` agent) coordinates all phases. Specialist agents do the writing. **The orchestrator does NOT write files itself** — it delegates via the `Agent` tool with `subagent_type` set to the specialist (see Agent Routing Table in the Companion Principle section below). The single permitted exception is direct human-mandated edits to this CLAUDE.md or other project-root meta-docs (e.g., this paragraph itself).

Phase sequence for brain-factory (greenfield mode):

- **Phase 0: N/A** (no existing implementation to ingest — this is greenfield, not brownfield). Planning artifacts in `docs/planning/` serve as the equivalent context input.
- **Phase 1a/b/c/d: Spec Crystallization (UPCOMING — first cycle starting)** — L2 domain spec / PRD with BCs / architecture with ADRs / adversarial spec review.
- **Phase 2: Story Decomposition** — epics, stories, dependency graph, wave schedule, holdout scenarios.
- **Phase 3: TDD Implementation** — per-story TDD via bash + bats, with adversarial 3-CLEAN cascades.
- **Phase 4: Holdout Evaluation** (gated on per-wave readiness).
- **Phase 5: Adversarial Refinement** (post-implementation cascade).
- **Phase 6: Formal Hardening** — shellcheck + shfmt + bats coverage + (where applicable) property-based bash test patterns. (Kani/cargo-fuzz/cargo-mutants are not applicable — this is bash, not Rust.)
- **Phase 7: Convergence** — 7-dimensional convergence assessment.

Per-story Phase 3 sub-workflow: stubs → failing bats tests → TDD green → LOCAL adversary 3-CLEAN → demo-recorder per-AC → push → pr-manager 9-step PR cycle → squash-merge → state-manager post-merge burst. BC-5.39.001 3-CLEAN protocol applies to every cascade.

---

## CANONICAL PRINCIPLE — Production-Grade Default

This principle binds every AI agent operating on this project. It overrides any default behavior in agent prompts, skills, or templates that conflicts with it. Mirrors the user's persistent directive: **"No pragmatic convergence. Fix all issues before build."**

### Statement

**Default behavior is enterprise/production-grade correctness. Speed lives in feature *ordering*, not feature *completeness*.**

### Six rules

1. **No MVP-driven deferrals.** Phrases like "for now," "good enough," "we can fix later," "minimum viable," and "ship fast and iterate" are RATIONALIZATIONS, not engineering decisions. Treat them as defect-pattern smells. If a thing is worth doing in v1, it is worth doing correctly in v1.

2. **Feature order is the only acceptable speed lever.** It is acceptable to defer an entire feature (e.g., a future story or wave) to a later cycle. It is NOT acceptable to ship the current story partially or with shortcuts that need later cleanup. Each shipped feature must be production-grade on the cycle it ships.

3. **Tech debt register (`.factory/tech-debt-register.md`) is for HUMAN-DIRECTED deferrals ONLY.** AI agents must NOT add entries to it as a default catchment for issues found during review. If an agent discovers a defect, the default action is to FIX it in-scope. Adding to the register requires ALL of:
   - Explicit human direction to defer, AND
   - A concrete future dependency that makes the deferral necessary (e.g., "this depends on the WASM dispatcher landing in factory-dispatcher v1.0"), AND
   - Attachment to the specific future story or wave where it will be resolved (so it cannot get lost).

4. **AI-built defects are the AI's responsibility to fix.** Every artifact in `.factory/` and most code in `plugins/brain-factory/` was written by AI (with human approval). When an AI agent finds an issue in another AI agent's output, the default is to fix it in the current scope — even if that means expanding scope. Surfacing the issue as a question, an "advisory," a "TODO for architect," or a "pending architect review" is the WRONG default. The correct default is to fix.

5. **`Suggest` is acceptable. `Default to cheap path` is not.** Agents may propose cheaper alternatives to the human, but the agent's DEFAULT action must be the correct path. "I noticed this would be faster if we skipped X — would you like to?" is fine. Skipping X without surfacing the option is not.

6. **"Pending architect review" / "TODO for architect" / "Placeholder for architect" in spec artifacts is forbidden when the question is answerable in current scope.** If the question requires architect adjudication only because the answer needs cross-component reasoning that hasn't happened yet, that's legitimate. If the question is mechanical (path migration, version pin selection, conventional lint configuration, hook-script `set -euo pipefail` placement), the AI handling the spec must answer it now.

### What this means in practice

| Anti-pattern | Production-grade replacement |
|--------------|------------------------------|
| "MVP: ship without bats coverage on edge case X" | Write the edge-case bats test. Cover it now. |
| "For now we'll hardcode this template path; refactor later" | Read the path from `${CLAUDE_PLUGIN_ROOT}/templates/...` now. Document the resolution rule. |
| "We can add error handling in v2" | Add error handling now. Define the exit-code taxonomy in scope. |
| "Architect TODO: confirm hook exit-code 1 vs 2 semantics" | Pick the production-grade default (0 ok / 1 advisory / 2 block per phased plan §A.4) and write the rationale inline. |
| "Pending architect review: should we support all 18 GitHub Action templates in v0.1?" | Read the phased build plan, decide based on phase boundaries, document the decision. |
| "Phase 3 deferred: add this to tech-debt-register" | First ask: did the human direct this deferral? If no, fix it now. |
| "Good enough for v0.1" | "Production-grade for v0.1." If you can't say production-grade, you're not done. |
| Implementer claims "MVP scope" / "test-path-only" / "deferred to follow-up" | Adversary independently verifies the claim under fresh-context analysis. Implementer self-disclosure of risk severity is NOT authoritative. |
| Hook script swallows a `jq` parse error and returns `{}` where partial-failure data should propagate | Thread proper plumbing through; surface-and-defer-via-error is a SOUL.md #4 violation. |
| Skill `SKILL.md` claiming "this requires capability X" with no `allowed-tools` gating | Either set `allowed-tools` to enforce the gate or remove the docs. |
| Adding a parameter to a hook's JSON input contract to close a finding correctly | DO IT. "Wiring not redesign" means don't *replace* the protocol; it does NOT mean don't *add* proper plumbing where it was missing. |
| File a P4 TD for cosmetic cleanup of 2 byte-identical hook helpers (~45 min total) | Fix the 2 cosmetic cleanups in-scope. P4 TDs that could have been a single inline edit are a defer-pattern smell. |

### Self-Audit Checklist (every agent, before declaring work done)

Run this checklist as the last act of every task. If any answer is "yes" or "I'm not sure," stop and remediate before declaring done.

- [ ] Did I rationalize any decision with "MVP," "for now," "good enough," or "we can fix later"?
- [ ] Did I add a new tech-debt-register entry without **all three** of: explicit human direction, concrete future dependency, and a specific future story/wave anchor?
- [ ] Did I leave any "pending architect review," "TODO for architect," or "Placeholder for architect" in a spec artifact for a question I could have answered in scope?
- [ ] Did I find a bug or gap in another AI's output and surface it as a question/advisory instead of fixing it in scope?
- [ ] Did I default to the cheapest mechanism instead of the correct mechanism?
- [ ] If I added an ADVISORY-severity finding to a report, did I evaluate whether it should be a BLOCKER under the production-grade lens? (Most "advisories" become blockers.)
- [ ] Did I paper-fix a finding by renaming, doc-commenting, or asserting-only when the real fix is structural?
- [ ] Did I sibling-sweep all callsites when I changed a hook signature, exit-code semantic, or canonical identifier?
- [ ] Did I modify a planning artifact in `docs/planning/` without explicit human direction? (NEVER allowed without explicit ask.)

### Boundaries — what the principle does NOT mean

- **It does not mean "do everything before shipping anything."** Phasing waves (Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase 4) is correct. Within a phase, every shipped story must be production-grade. The phased build plan in `docs/planning/llm-second-brain-phased-build-plan.md` defines exit gates per phase.
- **It does not mean "no asks of the human."** Genuine human decisions — risk acceptance, business priorities, scope vs deadline tradeoffs, versioning policy, marketplace publishing decisions, family-relationship policy with `factory-dispatcher` — should be surfaced. The principle forbids deferring WORK that the AI can do; it does not forbid surfacing DECISIONS that only the human can make.
- **It does not mean "infinite scope expansion."** If you find an issue, fix it. If the fix requires expanding into a new domain that requires new specs or new architecture decisions, surface it cleanly and request scope expansion. The principle requires fixing, not infinite recursion.
- **It does not override security or correctness.** If a "production-grade fix" requires a security review, run the security review.

### Companion Principle — Correct Agent Routing

"Fix in scope" works ONLY when paired with correct agent routing. Otherwise it degrades into "every agent does everything," which destroys specialization and produces worse work than the defer-pattern it replaces.

#### Rules

1. **Agents own their domain.** A consistency-validator does NOT silently rewrite spec content. An implementer does NOT silently rewrite the spec. Each specialist agent has a defined scope (see Agent Routing Table below); work outside that scope is routed to the correct specialist via the orchestrator.
2. **The orchestrator owns routing.** When a specialist agent discovers a defect outside its own domain, it surfaces the finding to the orchestrator with the proposed routing. The orchestrator then dispatches the correct specialist. This is NOT a defer-pattern — it is correct-agent-pattern. The fix still happens in scope of the same work cycle.
3. **Surface vs defer — the critical distinction:**
   - **Surface (production-grade):** Agent A finds issue → routes to orchestrator → orchestrator dispatches specialist B → specialist B fixes in scope. **No human round-trip required for the routing.**
   - **Defer (forbidden):** Agent A finds issue → adds to tech-debt-register / advisory / "TODO for X" → original work declared done → issue persists. **Requires human to discover and re-prioritize.**
4. **When in doubt about routing, ask the orchestrator** — not the human. The orchestrator has the routing table loaded; let it route.
5. **The orchestrator NEVER does specialist work itself.** It coordinates, dispatches, and validates gates. If the orchestrator is tempted to write a file directly (other than this CLAUDE.md per direct human mandate), that is a routing failure — find the correct specialist and dispatch.

#### Agent Routing Table

Use this table to determine which specialist handles which kind of work. Authoritative reference; supersedes any conflicting routing in upstream skills until the upstream vsdd-factory canonicalization lands. Mirrors the routing table loaded by `.claude/agents/orchestrator.md`.

| If the work is... | Route to agent ID |
|-------------------|-------------------|
| Product brief, PRD, behavioral contracts (BCs), holdout scenarios | `vsdd-factory:product-owner` |
| Market analysis, L2 domain spec, ubiquitous language | `vsdd-factory:business-analyst` |
| Architecture, ADRs, DTU assessment, gene transfusion, dependency manifest | `vsdd-factory:architect` |
| UX spec, design system, wireframes, interaction design | `vsdd-factory:ux-designer` |
| Story decomposition, dependency graph, wave schedule | `vsdd-factory:story-writer` |
| Cross-document consistency (IDs, anchors, counts, naming) | `vsdd-factory:consistency-validator` |
| Adversarial fresh-context review (specs or implementation) | `vsdd-factory:adversary` |
| Constructive spec/story review (different-model cognitive diversity) | `vsdd-factory:spec-reviewer` |
| PR diff code review (different-model cognitive diversity) | `vsdd-factory:code-reviewer` |
| Deep codebase scanning, semantic analysis, brownfield ingest | `vsdd-factory:codebase-analyzer` |
| Brownfield extraction validation (catch hallucinated dependencies) | `vsdd-factory:validate-extraction` |
| TDD test stubs and failing tests | `vsdd-factory:test-writer` |
| TDD implementation (one failing test → minimum code → micro-commit) | `vsdd-factory:implementer` |
| E2E browser tests (Playwright/Cypress) | `vsdd-factory:e2e-tester` |
| Demo recordings (VHS terminal or Playwright browser) | `vsdd-factory:demo-recorder` |
| PR lifecycle (create, review dispatch, finding triage, merge) | `vsdd-factory:pr-manager` |
| Final fresh-eyes PR diff review before merge | `vsdd-factory:pr-reviewer` |
| Formal proofs, fuzzing, mutation testing, security scan | `vsdd-factory:formal-verifier` |
| Security review / triage (CWE/CVE, OWASP) | `vsdd-factory:security-reviewer` |
| Holdout scenario evaluation against implementation (strict info asymmetry) | `vsdd-factory:holdout-evaluator` |
| DTU clone validation against real third-party services | `vsdd-factory:dtu-validator` |
| Repo setup, worktrees, CI/CD, release, plugin tarball packaging | `vsdd-factory:devops-engineer` |
| Toolchain preflight, env setup, dependency installation (bats, shellcheck, shfmt) | `vsdd-factory:dx-engineer` |
| `.factory/STATE.md` updates, `.factory/` commits, cycle bookkeeping | `vsdd-factory:state-manager` |
| Spec governance, versioning, traceability audit | `vsdd-factory:spec-steward` |
| Documentation generation from code/specs (current behavior only) | `vsdd-factory:technical-writer` |
| External research (Perplexity, Context7, Tavily MCP access) | `vsdd-factory:research-agent` |
| GitHub CLI operations on behalf of agents without shell access | `vsdd-factory:github-ops` |
| Performance benchmarks, regression detection | `vsdd-factory:performance-engineer` |
| Data schemas, migrations, pure-core / effectful-I/O boundary | `vsdd-factory:data-engineer` |
| WCAG AA/AAA accessibility audit | `vsdd-factory:accessibility-auditor` |
| Visual regression, mockup fidelity comparison | `vsdd-factory:visual-reviewer` |
| Post-pipeline analysis, lessons capture, improvement proposals | `vsdd-factory:session-reviewer` |

#### Routing examples (brain-factory canonical patterns)

- **Cross-document consistency defect found by consistency-validator** during a phase gate: correct routing is `product-owner` (owner of BC/PRD content) OR `architect` (owner of ADR content), NOT consistency-validator-fixes-it. The orchestrator dispatches.
- **Adversarial finding: hook script swallows `jq` parse failure** in a fix-burst: correct routing is `implementer` (the hook script is code, not spec). The fix-burst dispatch happens via orchestrator-drives-cascade pattern because pr-manager lacks Agent tool access — that's a tooling routing constraint, not a defer-pattern.
- **TDD red-gate violation found by test-writer** where a Red Gate bats test does not align with the BC: route to `product-owner` (if the BC is the problem) or to the human (if the spec is genuinely contradictory). DO NOT have the test-writer modify the BC silently.
- **Security finding found by security-reviewer**: triage classification is security-reviewer's job. The FIX is implementer's job (with security-reviewer re-running to confirm). Use the `fix-pr-delivery` skill.
- **BC ↔ hook event-catalog drift discovered during implementation**: the implementer must amend the BC's structured event catalog in the SAME atomic commit. The implementer is editing the .factory/ artifact in-scope — this is correct-agent because the contract surface and the emission site are both implementer-owned at fix-burst time. Post-merge, state-manager + adversary verify.
- **Out-of-scope finding (legitimate scope-boundary defer)**: still route to orchestrator. Orchestrator records the deferral with explicit future-story attachment per Canonical Principle Rule 3. The deferral target must be a real story ID, not "Phase X" or "later."
- **Finding that planning artifact under `docs/planning/` should change**: NEVER auto-fix. Route to the human; planning artifacts are immutable without explicit direction. The correct mid-pipeline response is to amend the `.factory/` spec that the planning artifact fed into.

#### When the routing is unclear

If a defect doesn't obviously map to a specialist:

1. **Ask the orchestrator first.** The orchestrator has the routing table loaded; let it route.
2. **If the orchestrator is uncertain, the orchestrator asks the human.** This is the legitimate use of human time — routing-table extensions, not domain-fixes-by-wrong-agent.
3. **Default fallback for unmapped work: research → architect.** Most truly novel work that doesn't fit a specialist needs external research first (`vsdd-factory:research-agent`), then architectural decision (`vsdd-factory:architect`).

#### Anti-patterns this principle blocks

- ❌ Adversary rewrites failing tests "to make them pass" (wrong: route to test-writer or implementer).
- ❌ State-manager writes spec content like BC bodies or ADR rationale (wrong: route to product-owner or architect; state-manager handles index rows, frontmatter syncs, decision logs, and cross-document version bumps).
- ❌ Consistency-validator silently edits brief frontmatter (wrong: route to product-owner).
- ❌ Implementer adds a new BC to fix a TDD red-gate (wrong: route to product-owner; implementer cannot author specs).
- ❌ Orchestrator writes the artifact itself when a specialist's output is unsatisfactory (wrong: re-dispatch the specialist with better instructions, or escalate to human).
- ❌ Any agent edits `.factory/STATE.md` directly (wrong: state-manager owns STATE.md).
- ❌ Any agent edits `docs/planning/*.md` (wrong: human-only, this is immutable design source-of-truth).
- ❌ Filing a P4 "opportunistic cleanup" TD when the fix is ~45 minutes of in-scope work (wrong: fix in-scope per Canonical Principle Rule 3 + Rule 4).

#### Conflict with upstream

If a vsdd-factory agent prompt or skill defines a different routing than the table above, this table wins for brain-factory. The upstream canonicalization issue (filed against `drbothen/vsdd-factory`) tracks bringing upstream into alignment.

### Operational Discipline TDs (brain-factory-specific layering)

These project-specific operational rules layer onto the canonical principle. Recorded in `.factory/SESSION-HANDOFF.md` and enforced by the factory-dispatcher hook chain:

- **TD-VSDD-053 — Single-commit-per-burst.** Each logical burst → ONE commit in `.factory/`. Multi-commit chains (HEAD and HEAD^ both containing "backfill" / "Stage 1" / "Stage 2") trigger `MULTI_COMMIT_CHAIN_NOT_ALLOWED`. Recovery procedure documented in "Factory Hook Diagnostics" below.
- **TD-VSDD-059 — Paper-fix detection.** State-manager and adversary must verify every claimed closure has a load-bearing test or assertion, not just a doc-comment or rename. Implementer self-disclosure of risk severity is NOT authoritative — adversary independently verifies.
- **TD-VSDD-060 — Sibling-site sweep on value changes.** When changing a hook input/output contract, exit-code semantic, or canonical identifier, grep for ALL callsites in the plugin (and tests) before committing.
- **TD-VSDD-091 — Anti-volatile-pin.** Narrative spec content must cite hook script names, skill names, and behavioral anchors, NOT `script.sh:NNN` line numbers (which decay on subsequent diffs). Justified citations (Red Gate test tables, AC source-of-truth tables, pass-report changelogs) excepted.
- **BC-5.39.001 — 3-CLEAN convergence protocol.** Adversarial cascades require three consecutive clean passes for convergence; any finding resets the streak to 0/3. Applies to both LOCAL and PR-LEVEL cascades.
- **TD-FACTORY-HOOK-BYPASS-001 P0** — Use Edit/Write tools ONLY for `.factory/` mutations. NEVER use Python/sed/echo bypass. Enforced by POL-3.
- **POL-14 — Auto-promotion at merge.** When a story's PR merges, BCs in `behavioral_contracts` frontmatter auto-promote `draft → active`. State-manager runs this transition.
- **brain-factory-001 — Planning artifacts are immutable.** Files under `docs/planning/` are design source-of-truth, written once during planning, only amended by explicit human direction. Mid-pipeline changes go to `.factory/` specs, not back-propagated to planning artifacts.
- **brain-factory-002 — Filenames are kebab-case lowercase no spaces.** Wiki filenames are IMMUTABLE after creation (per phased plan §A.4) — once skills/hooks exist, renames go through the dedicated `rename-page` skill, not direct `mv`.

## Conventions (Code-Level)

brain-factory-specific coding patterns enforced by CI and/or adversarial review. These are non-negotiable under the production-grade default — violations are bugs, not style preferences.

### Highlights

- **Bash hook contract.** Every hook script under `plugins/brain-factory/hooks/` must:
  - Start with `#!/usr/bin/env bash` and `set -euo pipefail`.
  - Accept JSON on stdin per the hook input protocol (phased plan §A.4).
  - Emit JSON on stdout per the hook output protocol.
  - Exit with `0` (success/no-op), `1` (advisory — log but continue), or `2` (block — abort the operation).
  - Never call `exit` without an explicit code. Never bare-`exit` on a trap.
  - Never use `eval`. Quote all expansions (`"$var"` not `$var`).

- **Skill contract.** Every `SKILL.md` under `plugins/brain-factory/skills/<name>/` must include:
  - YAML frontmatter with: `name`, `description`, `argument-hint`, `allowed-tools`.
  - Sections in order: Iron Law, Red Flags, Announce-at-Start, Procedure (numbered), Quality Bar, Output.
  - No template-path hardcoding to `.claude/templates/...` — always use `${CLAUDE_PLUGIN_ROOT}/templates/...`.

- **Agent contract.** Every `AGENT.md` (specialist agent) under `plugins/brain-factory/agents/<name>/` must declare its scope, tool profile (allowed/denied tools), and routing reference into the Agent Routing Table above.

- **Template path discipline.** ALL template references use `${CLAUDE_PLUGIN_ROOT}/templates/...`. Never hardcode `.claude/templates/...` — that path is the development/test convention, not the runtime convention.

- **Filename discipline.** Filenames are kebab-case, lowercase, no spaces. Wiki filenames are IMMUTABLE after creation — renames go through the rename-page skill (forthcoming).

- **No AI attribution in commits.** Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`). NEVER include `Co-Authored-By: Claude`, robot emoji, or "Generated with Claude Code" trailers. The user has explicitly directed this for brain-factory.

- **No `--no-verify`. No force-push to `main`.** lefthook pre-commit/pre-push hooks are non-negotiable. Bypassing them is TD-FACTORY-HOOK-BYPASS-001 P0.

- **bats is for HOOK testing, not markdown content testing.** Every hook script has a bats suite under `plugins/brain-factory/tests/<hook-name>.bats` covering positive case + negative case + edge case (per phased plan §5.7). Bats feeds the hook a JSON payload on stdin (sometimes embedding a markdown fixture from `plugins/brain-factory/tests/fixtures/`) and asserts on the hook's stdout JSON + exit code. Red Gate bats tests fail before the hook is implemented; green after.

- **Markdown content validation lives IN HOOKS, not in test files.** Frontmatter schemas, wikilink resolution, wiki/index.md drift, source-immutability hashing, and structural conformance are validated by hooks using `yq eval` (frontmatter), `awk` (section parsing), `jq` (JSON payloads), and `sha256sum` (immutability). The hook is the validator; bats tests the hook. Examples from phased plan §A: `validate-frontmatter-schema.sh`, `wikilink-check`, `validate-source-immutability`.

- **Skill outputs are validated by PostToolUse hooks, not by skill-specific test files.** When a skill `Write`s or `Edit`s a wiki/source/brief, the matching PostToolUse hook (matcher pattern from phased plan §5.5) fires automatically — parsing the just-written markdown and emitting an advisory (exit 1) or block (exit 2). Skills are exercised end-to-end via `plugins/brain-factory/tests/run-all.sh` and the §5.10 local-dev test script (temp brain → real skill invocation → hook verdicts → assertions on resulting filesystem).

- **Meta-lint: tests for the factory itself.** A dedicated bats suite at `plugins/brain-factory/tests/meta-lint.bats` validates that the factory's own artifacts conform to their templates. Distinct from hook bats (which tests hook BEHAVIOR) — meta-lint tests artifact STRUCTURE. Specifically asserts (see "Meta-Lint Contract" section below for the full list):
  - Every `SKILL.md` has frontmatter with required fields, the canonical 6-section structure (Iron Law / Red Flags / Announce-at-Start / Procedure / Quality Bar / Output), a non-empty Iron Law, a Red Flags list with ≥1 entry, and a numbered Procedure.
  - Every `hooks/*.sh` starts with `#!/usr/bin/env bash`, has `set -euo pipefail` within the first 10 lines, never bare-`exit`s, never uses `eval`, and has a corresponding bats test file.
  - Every `AGENT.md` declares its scope, tool-profile, and links to the Agent Routing Table.
  - No tracked file contains `Co-Authored-By: Claude`, `--no-verify`, or hardcoded `.claude/templates/...` paths.
  - All `${CLAUDE_PLUGIN_ROOT}/...` references resolve to real paths in the plugin tree.

  An artifact failing meta-lint is a P1 finding in adversarial review — the factory cannot enforce its own contracts on user output if it doesn't enforce them on its own source.

- **No JS/Node test framework.** No `remark`, no `markdownlint-cli2`, no `ajv` schema validators. v0.x is intentionally pure bash + jq + yq + awk for portability and dependency minimalism. The phased plan documents this as a deliberate choice — Phase 4 (WASM dispatcher migration) is when richer tooling becomes available, not v0.x.

- **shellcheck clean + shfmt-normalized.** No `SC2XXX` warnings. Indent with 2 spaces (shfmt `-i 2`).

- **Structured event emission.** Every `hook-event:emit` site must appear as a row in the structured event catalog BC (forthcoming, Phase 1d output). New emission sites added without a corresponding catalog row are a P1 finding in adversarial review.

- **No secrets in stdout/logs.** Hook scripts must never echo tokens, API keys, or credential values. Use the redact helper (forthcoming) for any field that could carry sensitive data.

### Forbidden patterns

| Pattern | Reason |
|---------|--------|
| `eval "$..."` in a hook script | Shell injection surface; use parameter expansion + `--` separators |
| `exit` without explicit numeric code | Hook contract requires `exit 0`/`1`/`2` semantics |
| `.claude/templates/...` hardcoded in skill or hook | Use `${CLAUDE_PLUGIN_ROOT}/templates/...` |
| `cat $file` (unquoted) anywhere in a hook | Word-splitting + glob expansion bug; always `cat "$file"` |
| `Co-Authored-By: Claude` or robot emoji in any commit message | User has explicitly forbidden AI attribution |
| `git push --force` to `main` without `--force-with-lease` AND human approval | Project git-safety protocol |
| `git commit --no-verify` | TD-FACTORY-HOOK-BYPASS-001 P0 violation |
| `mv` on a wiki filename after creation | Use the rename-page skill (preserves backlink integrity); wiki filenames are immutable per phased plan §A.4 |
| Direct edits to `docs/planning/*.md` without explicit human ask | Planning artifacts are immutable design source-of-truth |
| `hook-event:emit` site without a catalog row in the structured-event BC | Catalog drift — P1 adversarial finding |

### Error handling

- Hook scripts: structured error envelope on exit ≠ 0 — JSON `{"level": "error|warn", "code": "E-HOOK-NNN", "message": "...", "trace": "..."}` on stdout, exit code per contract.
- Skill failures: skill returns a structured failure block with `quality-bar` violation enumeration; orchestrator routes to the right specialist.
- Partial-failure fan-out (e.g., batch wiki page generation): propagate per-item results; do not swallow and return empty.
- No `set +e` to silence errors. If a step legitimately tolerates failure, capture the exit code into a variable and branch on it explicitly.

### Logging

- Hooks emit structured events via `hook-event:emit` (forthcoming helper). Format: JSONL on stderr with `ts`, `event_type`, `plugin`, `trace`, plus event-specific fields.
- All `event_type` values must be registered in the structured event catalog BC before the PR merges.
- No `echo "..."` for user-facing output from hooks — hooks emit JSON on stdout, structured events on stderr. Skills emit prose to the user via Claude Code.

### Concurrency

- Hooks should be idempotent and side-effect-aware. Hook A and Hook B may run in either order; design for both.
- Long-running operations (e.g., wiki rebuild) must be cancellable: trap SIGINT/SIGTERM and exit cleanly.
- File-system mutations under the brain vault must use the `lock` helper (forthcoming) when there's any chance of concurrent access from parallel skills.

### Conflict resolution

If this principle conflicts with a vsdd-factory agent prompt, skill, or rule, this principle wins for brain-factory. Upstream changes to canonicalize these principles across all VSDD-managed projects are tracked in the `drbothen/vsdd-factory` GitHub issue tracker.

### When in Doubt

If you are an AI agent and you are uncertain whether the production-grade default applies in a specific case, the answer is YES. The principle is the default. Ask only if you have a concrete reason to suspect this case is an exception.

If you are a human reviewing this file and you want to change the principle, edit this file and commit. The principle becomes whatever this file says.

---

## Build & Test

> Note: pre-v0.1. Build commands below are TARGET conventions to be established during Phase 1d / Phase 2 toolchain bootstrap. The phased build plan §A.4 defines the canonical hook contract that these commands will enforce.

Four test surfaces, four commands:

```bash
# 1. HOOK TESTS (bats) — TDD inner loop for hook scripts
bats plugins/brain-factory/tests/<hook-name>.bats

# 2. META-LINT (bats) — structural validation of the factory's own artifacts
bats plugins/brain-factory/tests/meta-lint.bats

# 3. BASH LINT — hook quality
shellcheck plugins/brain-factory/hooks/*.sh
shfmt -d -i 2 plugins/brain-factory/hooks/*.sh        # diff mode
shfmt -w -i 2 plugins/brain-factory/hooks/*.sh        # write mode

# 4. END-TO-END — skill behavior on a real (temp) brain
plugins/brain-factory/tests/run-all.sh                # runs all bats suites (hooks + meta-lint)
bash plugins/brain-factory/tests/local-dev-test.sh    # §5.10: temp brain → real skill → hook verdicts

# Pre-push gate
plugins/brain-factory/tests/run-all.sh && \
  shellcheck plugins/brain-factory/hooks/*.sh && \
  shfmt -d -i 2 plugins/brain-factory/hooks/*.sh

# Setup (idempotent — Phase 1 deliverable)
make setup    # install bats, shellcheck, shfmt, jq, yq
```

### TDD Inner Loop Discipline

The TDD inner loop applies to **hook scripts** (where there's bash logic to test). Skills are exercised end-to-end via the local-dev test, not in a tight inner loop.

| Question | Command | Time |
|---|---|---|
| Did my hook fix make its target bats test pass? | `bats plugins/brain-factory/tests/<file>.bats -f "<test name>"` | < 1s |
| Did my hook fix break anything in this suite? | `bats plugins/brain-factory/tests/<file>.bats` | < 5s |
| See ALL failing hook tests at once | `bats plugins/brain-factory/tests/ --no-tempdir-cleanup` | 5-30s |
| Did my skill change produce the right wiki output? | `bash plugins/brain-factory/tests/local-dev-test.sh` (or a scoped variant) | seconds-to-minutes depending on scope |
| Lint clean | `shellcheck plugins/brain-factory/hooks/*.sh && shfmt -d -i 2 plugins/brain-factory/hooks/*.sh` | < 2s |
| Final pre-push gate | run-all.sh + shellcheck + shfmt | < 1 min |

When iterating a hook fix-burst, run the **single bats test** that targets your fix — not the whole `run-all.sh`. Reserve the full run for end-of-burst before pushing.

## Meta-Lint Contract

The factory ships rules to its users (skills' Iron Laws, Red Flags, hook exit-code semantics). It must enforce the same rules on its own source. **Meta-lint is how the factory tests itself.**

Lives at `plugins/brain-factory/tests/meta-lint.bats`. Runs in CI (mandatory, blocking) and as part of the pre-push gate.

### Surfaces and enforced assertions

**Surface 1 — Skills (`plugins/brain-factory/skills/<name>/SKILL.md`):**

| Assertion | Rationale |
|---|---|
| Frontmatter present (YAML between `---` fences at top) | Without frontmatter, Claude Code can't load the skill |
| Frontmatter has non-empty `name`, `description`, `argument-hint`, `allowed-tools` | Required by Claude Code skill loader |
| `name` frontmatter value matches the directory name | Prevents drift between filesystem and skill identity |
| `allowed-tools` is a YAML list (sequence), not a string | Schema correctness |
| Body has section headings in order: `Iron Law`, `Red Flags`, `Announce-at-Start`, `Procedure`, `Quality Bar`, `Output` | Phased plan §A.4 canonical skill shape |
| `Iron Law` section body is non-empty and ≤ 200 chars (single sentence enforced) | Iron Laws lose force when they sprawl |
| `Red Flags` section has ≥ 1 bullet (regex `^\s*[-*]` or `^\s*\(\d+\)`) | Empty Red Flags = unenforced |
| `Procedure` section is a numbered list (regex `^\d+\.` on ≥ 1 line) | Procedure must be steppable; prose isn't |
| No occurrence of `.claude/templates/` in body | Use `${CLAUDE_PLUGIN_ROOT}/templates/` |
| Filename and directory are kebab-case lowercase, no spaces | Project-wide filename rule |

**Surface 2 — Hooks (`plugins/brain-factory/hooks/*.sh`):**

| Assertion | Rationale |
|---|---|
| First line is `#!/usr/bin/env bash` | Portability, explicit interpreter |
| `set -euo pipefail` appears within first 10 lines | Hook contract from phased plan §A.4 |
| No bare `exit` (every `exit` is followed by `0`, `1`, or `2`) | Hook contract requires explicit verdict |
| No `eval` anywhere in the script | Shell injection avoidance |
| Has a corresponding `plugins/brain-factory/tests/<hook-name>.bats` file | BC coverage gate — every hook is bats-tested |
| `shellcheck` exits 0 on this file | Aggregate quality gate |
| `shfmt -d -i 2` produces no diff on this file | Formatting normalization |

**Surface 3 — Agents (`plugins/brain-factory/agents/<name>/AGENT.md`):**

| Assertion | Rationale |
|---|---|
| Frontmatter present with `name`, `scope`, `tool-profile` | Required agent metadata |
| Body references the Agent Routing Table (substring match on the CLAUDE.md anchor) | Prevents orphan agents that aren't routable |
| Allowed/denied tools explicitly enumerated | Prevents tool-profile drift |
| Filename and directory are kebab-case lowercase | Project-wide filename rule |

**Surface 4 — Cross-cutting (tracked repo files):**

| Assertion | Rationale |
|---|---|
| No tracked file contains the string `Co-Authored-By: Claude` | User has explicitly forbidden AI attribution |
| No tracked file contains the string `🤖` (robot emoji) | Same |
| No `--no-verify` in any committed script (test files excepted only if explicitly justified) | TD-FACTORY-HOOK-BYPASS-001 P0 |
| Every `${CLAUDE_PLUGIN_ROOT}/...` reference resolves to a path that exists under `plugins/brain-factory/` | Catches typos in template paths before runtime failure |
| Every internal markdown link `[...](path)` resolves | Documentation integrity |

### When meta-lint fires

- **Pre-commit (via lefthook):** runs the subset that's cheap (frontmatter shape, line-1 shebang, grep for forbidden strings).
- **Pre-push (via lefthook):** runs the full suite.
- **CI (mandatory, blocking):** runs the full suite plus shellcheck and shfmt diff.
- **Adversarial review:** the adversary independently verifies meta-lint passed; the agent that ran it is not authoritative.

### When meta-lint changes

Meta-lint rules are themselves a contract. Adding, removing, or weakening a rule requires:

1. A BC update (product-owner) explaining why the rule changed.
2. A sweep of all existing factory artifacts to verify they still pass under the new rule (or filing follow-up stories with explicit story IDs to bring them into conformance).
3. A test-writer dispatch to update `meta-lint.bats` itself.

Meta-lint rules MUST NOT be weakened to make a failing artifact pass. That's a paper-fix (TD-VSDD-059). If an artifact fails meta-lint, the artifact is wrong, not the rule.

## Formal Verification

Brain-factory v0.x is bash + markdown. Formal verification in the Kani/cargo-mutants sense is **not applicable**. The equivalent rigor comes from a layered stack:

- **bats Red Gate tests for every BC whose surface is a hook.** Each such BC has at least one failing bats test BEFORE the hook is implemented; the test goes green when the hook lands. BCs whose surface is a skill or a markdown convention are validated by hooks (which themselves have bats coverage), not by skill-level bats tests.
- **PostToolUse hook coverage for every wiki/source/brief mutation.** Markdown content shape, frontmatter schema, wikilink integrity, and source immutability are enforced at the moment of Write/Edit by hooks fired from `hooks` settings in the plugin manifest.
- **End-to-end local-dev test (phased plan §5.10).** A scripted temp-brain that exercises real skill invocations and asserts on the resulting filesystem + hook verdicts. This is the closest analog to integration testing for skill behavior.
- **shellcheck strict mode** — `-S style -e SC1090` baseline, escalating to `-S warning` as the codebase matures.
- **shfmt -d** — diff-mode formatting check in CI; rejects non-normalized scripts.
- **Adversarial 3-CLEAN cascades** — BC-5.39.001 protocol on every PR and every spec phase gate. The adversary reads written markdown artifacts with fresh context and checks they actually do what the BCs say.
- **Holdout scenario evaluation** — Phase 4 evaluation against scenarios hidden from the implementer; scenarios are exercised against a real (temp) brain.

Once Phase 4 (dispatcher migration to WASM) lands, the WASM hook plugins will be eligible for property-based testing via Rust's `proptest` and potentially Kani if the dispatcher exposes pure-core functions. That's a v1.0+ concern.

## Git Workflow

### Branch model
- **Default branch:** `main` (release branch, infrequent commits in v0.x; will become tag-gated post-v0.1)
- **Active development:** initially direct on `main` (pre-v0.1, no collaborators); once v0.1 ships → `develop` (PRs target `develop`)
- **Feature branches:** `feature/<story-id>` once Phase 2 stories exist
- **Maintenance branches:** `maintenance/<scope>`
- **Worktree pattern:** per-story worktrees in `.worktrees/<story-id>/` for parallel work (Phase 3+)
- **Factory artifacts branch:** `factory-artifacts` (orphan branch mounted at `.factory/` via worktree). Local-only by default — orchestrator does NOT push factory-artifacts to remote without explicit user authorization.

### Commit conventions
- **Conventional Commits** enforced by lefthook (config forthcoming in Phase 1d):
  - `pre-commit`: shellcheck + shfmt + markdownlint
  - `pre-push`: full bats suite + lint
  - `pre-tag`: changelog completeness + version bump check
- **Factory hook chain** (`.factory/` commits): single-commit-per-burst per TD-VSDD-053; MULTI_COMMIT_CHAIN_NOT_ALLOWED detector blocks two consecutive commits with "backfill" / "Stage 1" / "Stage 2" in their subjects. See "Factory Hook Diagnostics" section below for the full recovery procedure.

### Non-negotiable git rules
- **NEVER skip hooks** (`--no-verify`, `--no-gpg-sign`). If a hook fails, investigate and fix the underlying issue. Bypassing is a TD-FACTORY-HOOK-BYPASS-001 P0 violation.
- **NEVER add AI attribution to commits** — no `Co-Authored-By: Claude`, no robot emojis, no "Generated with Claude Code" trailers. The user has explicitly directed this for brain-factory.
- **NEVER force-push to `main`.** Force-push to `develop` (once it exists) requires explicit human approval. Force-push to feature/maintenance branches is acceptable when the work is local-only (no collaborators); `--force-with-lease` preferred over raw `--force`.
- **NEVER use destructive operations as a first-line response.** `git reset --hard`, `git clean -f`, `git checkout --` should be the last option after exhausting safer alternatives (`git stash`, `git reset --soft`, worktree-based isolation).
- **NEVER modify `docs/planning/*.md` without explicit human direction.** These are versioned design documents.

### Operational tips
- **Heredoc workaround:** large commit-message heredocs are sometimes blocked by hook payload limits. When `git commit -m "$(cat <<'EOF' ... EOF)"` fails, write the message to `/tmp/<file>` and use `git commit -F /tmp/<file>`. The Factory Hook Diagnostics section enumerates the specific hook validators that may trigger this.
- **Soft reset for recovery, never `--hard`.** Per the multi-commit-chain recovery procedure: `git -C .factory reset --soft HEAD~N` preserves the working tree state; re-author as a single combined commit.
- **`git stash` for in-progress work** when context-switching between worktrees — preserves uncommitted changes without losing them to a reset.

## Factory Hook Diagnostics

When `Agent` tool dispatches fail with errors like:

```
PreToolUse:Agent hook error: [...factory-dispatcher]: factory-dispatcher trace=<UUID> event=PreToolUse tool=Agent host_abi=1 matched_tiers=N plugins_run=N total_ms=N block_intent=true exit_code=2
```

— the factory-dispatcher hook chain blocked the dispatch. The error message itself carries NO human-readable reason — only the trace UUID. To diagnose, follow this procedure.

### Step 1 — Locate the dispatcher log

Internal logs live at:

```
.factory/logs/dispatcher-internal-YYYY-MM-DD.jsonl
```

(One file per day, JSONL format, one event per line.)

### Step 2 — Find the block reason

Search the day's log for the trace UUID:

```bash
grep '<TRACE-UUID>' .factory/logs/dispatcher-internal-$(date +%Y-%m-%d).jsonl
```

Look for `plugin.log` entries with `level: warn` — those carry the human-readable block reason as an embedded multi-line `message` field. Example payload:

```
"FAIL: MULTI_COMMIT_CHAIN_NOT_ALLOWED — HEAD and HEAD^ both contain 'backfill'.
 The single-commit protocol (TD-VSDD-053) does not use backfill commits.
 ...
 Recover with: git -C .factory reset --soft HEAD~2 then re-author as a single commit"
```

The `plugin_name` field on the same record (e.g., `validate-wave-gate-prerequisite`, `validate-pr-merge-prerequisites`, `regression-gate`) tells you which guard fired.

### Step 3 — Common blockers and recovery procedures

| Blocker | Detection | Recovery |
|---------|-----------|----------|
| **Multi-commit chain (TD-VSDD-053)** | HEAD and HEAD^ both have `backfill` / `Stage 1` / `Stage 2` in their commit messages | `git -C .factory reset --soft HEAD~N` (preserves working tree); re-author as one combined commit; force-push with `--force-with-lease` (requires explicit user approval) |
| **SHA drift** | STATE.md or SESSION-HANDOFF.md cite a develop SHA that doesn't match `git rev-parse origin/develop` (or `origin/main` pre-v0.1) | Update narrative via state-manager dispatch; STATE.md and SESSION-HANDOFF cited SHAs must match current `git -C . log -1 --format=%H <branch>` |
| **In-progress narrative** | STATE.md decision log has an open phase without closure | Add closure row via state-manager; bump version |
| **factory-artifacts dirty** | `git -C .factory status --porcelain` is non-empty | Commit/discard pending changes via state-manager |

### Step 4 — Re-run the validator before re-dispatching

```bash
bash .factory/hooks/verify-sha-currency.sh
```

Expected: exit 0 with `PASS` lines and no `FAIL` lines. If it still fails, repeat Step 2 with the new dispatch's trace.

### Step 5 — Going-forward discipline (orchestrator)

To avoid the multi-commit-chain block:

- **Bundle backfills.** When state-manager performs multi-document backfills (e.g., adversary pass-N report + fix-pass-N closure report), stage all files THEN commit ONCE. Never two state-manager dispatches in a row both producing "backfill" commits.
- **Single-commit-per-burst.** Each logical burst (one adversary cascade step, one fix-pass cycle, one phase transition) → one commit in `.factory/`. Multiple consecutive commits with the same theme word (`backfill`, `Stage`) trigger the chain detector.
- **Soft-reset for recovery, never `--hard`.** The working tree state is what we want to preserve.
- **Force-push always needs user approval.** Per project git-safety protocol; orchestrator must request it from the human.

### Hook source locations (read-only reference)

- Dispatcher binary: `~/.claude/plugins/cache/claude-mp/vsdd-factory/<version>/hooks/dispatcher/bin/<platform>/factory-dispatcher`
- Hook registry config: `~/.claude/plugins/cache/claude-mp/vsdd-factory/<version>/hooks-registry.toml`
- Hook plugins (WASM): `~/.claude/plugins/cache/claude-mp/vsdd-factory/<version>/hook-plugins/*.wasm`
- Project-side validator scripts: `.factory/hooks/*.sh` (forthcoming, Phase 1d)

## Family Relationship

| Repo | Role |
|---|---|
| [`drbothen/vsdd-factory`](https://github.com/drbothen/vsdd-factory) | Sister plugin — VSDD methodology for software engineering. Same family branding (`<domain>-factory`). Drives this repo's pipeline. |
| [`drbothen/claude-mp`](https://github.com/drbothen/claude-mp) | The marketplace. Hosts both vsdd-factory and brain-factory tarballs. |
| `factory-dispatcher` (planned) | Shared hook runtime to be extracted from vsdd-factory. v1.0 of brain-factory depends on it. |

## Project References

| Path | Description |
|------|-------------|
| `docs/planning/llm-second-brain-phased-build-plan.md` | **THE recommended build path** — start with bash hooks, ship v0.x in ~5 weeks, migrate to WASM via shared dispatcher only when ready (v1.0). Source-of-truth for Phase 1 specs. |
| `docs/planning/llm-second-brain-plan.md` | The methodology — what a brain does, how layers work, the daily/weekly/monthly rituals, voice rules. |
| `docs/planning/llm-second-brain-plugin-plan.md` | The plugin packaging — engine/target split, hook-enforced discipline, declarative governance, adversarial review, ~25 skills, 10 specialist agents, 18 GitHub Action templates. |
| `docs/planning/vsdd-dispatcher-extraction-plan.md` | The upstream prerequisite for v1.0 — how vsdd-factory migrates to a vendored dispatcher, freeing the hook runtime for brain-factory and future factories to share. |
| `.factory/STATE.md` | Live pipeline state (current phase, decisions log, session resume checkpoint) — created by state-manager during Phase 1a |
| `.factory/SESSION-HANDOFF.md` | Resume-ready handoff for new sessions — created during Phase 1a |
| `.factory/specs/architecture/` | Architecture docs + ADRs + ARCH-INDEX.md (forthcoming — Phase 1c output) |
| `.factory/specs/behavioral-contracts/` | BC files + BC-INDEX.md (forthcoming — Phase 1b output) |
| `.factory/specs/verification-properties/` | VP files + VP-INDEX.md (forthcoming — Phase 1c/d output) |
| `.factory/specs/domain-spec/` | L2 domain spec (entities, invariants, capabilities, edge cases) (forthcoming — Phase 1a output) |
| `.factory/stories/` | Per-story implementation specs + STORY-INDEX.md (forthcoming — Phase 2 output) |
| `.factory/research/` | Cited research artifacts |
| `.factory/policies.yaml` | Project governance policy registry (10 baseline + project-specific) |
| `plugins/brain-factory/hooks/` | Bash hook scripts (forthcoming — Phase 1+ output) |
| `plugins/brain-factory/skills/<name>/SKILL.md` | Plugin skill definitions (forthcoming) |
| `plugins/brain-factory/agents/<name>/AGENT.md` | Plugin specialist agent definitions (forthcoming) |
| `plugins/brain-factory/templates/` | Templates referenced via `${CLAUDE_PLUGIN_ROOT}/templates/...` |
| `plugins/brain-factory/tests/` | bats test suites — per-hook tests + `meta-lint.bats` (factory-self-audit) + `run-all.sh` orchestrator + `local-dev-test.sh` end-to-end |
| `plugins/brain-factory/tests/meta-lint.bats` | Structural validation of SKILL.md / AGENT.md / hooks against their contracts (Iron Law present, frontmatter shape, exit-code semantics, etc.) — see "Meta-Lint Contract" section above |
| `plugins/brain-factory/tests/fixtures/` | Markdown + JSON fixtures fed to hook bats tests as stdin payloads |
| `lefthook.yml` | Pre-commit/push/tag git hook config (forthcoming — Phase 1d) |
| `Makefile` | Task runner (forthcoming — Phase 1d) |
| `README.md` | Public-facing project overview |
| `LICENSE` | MIT |
