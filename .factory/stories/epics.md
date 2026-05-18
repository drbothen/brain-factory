---
artifact_type: epics
version: "0.1.0"
created: 2026-05-18
authored_by: vsdd-factory:story-writer
inputs:
  - product-brief.md@v0.4.19
  - prd/index.md@v0.1.10
  - behavioral-contracts/BC-INDEX.md@v0.1.9
  - architecture/ARCH-INDEX.md@v0.1.22
  - verification-properties/VP-INDEX.md@v0.1.6
  - docs/planning/llm-second-brain-phased-build-plan.md (immutable)
total_epics: 9
total_bcs_covered: 95
phase: phase-2-story-decomposition-step-a
phase_2_status: STEP-A-IN-PROGRESS
---

# brain-factory Epics

**95 BCs assigned across 9 epics. Every BC in exactly one epic. Coverage matrix verified.**

Epics are ordered by recommended build sequence, aligned with the phased build plan's
phase boundaries (§4–§8). Build order: plugin foundation → hook enforcement → content
capture → content production → knowledge synthesis → publishing → operational tooling
→ scale and observability → plugin packaging and governance.

---

## Coverage Verification Footer

| Epic | BCs | Running Total |
|------|-----|---------------|
| EPIC-01: Plugin Foundation and Scaffold | 13 | 13 |
| EPIC-02: Hook Enforcement Chain | 20 | 33 |
| EPIC-03: Content Capture (URL + Source Ingest) | 11 | 44 |
| EPIC-04: Wiki Layer and Content Production | 10 | 54 |
| EPIC-05: Knowledge Synthesis | 3 | 57 |
| EPIC-06: Content Brief, Writing, and Publishing | 10 | 67 |
| EPIC-07: Lobster Runtime and GitHub Action Templates | 8 | 75 |
| EPIC-08: Scale-Aware Architecture and Observability | 10 | 85 |
| EPIC-09: Plugin Packaging and Governance | 10 | 95 |
| **TOTAL** | **95** | **95** |

Sum = 95. Every BC in exactly one epic. Coverage: **PASS**.

---

## Epic: Plugin Foundation and Scaffold

- **Goal:** A developer can install brain-factory as a local plugin and run `/brain:init`
  to scaffold a complete, working brain vault in under 5 minutes, with all required
  directory structure, CLAUDE.md wiring, and plugin manifest artifacts in place. This
  epic delivers the "zero to first brain" user journey.
- **BCs:** BC-2.01.001, BC-2.01.002, BC-2.01.003, BC-2.01.004, BC-2.01.005,
  BC-2.01.006, BC-2.14.001, BC-2.14.002, BC-2.14.003, BC-2.14.004, BC-2.14.005,
  BC-2.06.003, BC-2.06.004
- **Subsystems touched:** SS-01 (Brain Initialization and Scaffold), SS-14 (Plugin
  Lifecycle and Upgrade), SS-06 (Source Layer and Immutability — scaffold-time pieces)
- **Phased-plan anchor:** Build-plan Phase 1 (§5 Plugin scaffold with bash hooks) — the
  plugin structure, init skill, plugin.json, hooks.json.template, and upgrade lifecycle
  all land here before hook scripts are wired.
- **Estimated stories:** 5
- **Rationale:** The plugin scaffold and the init skill are the foundation every other
  epic builds on. An operator cannot ingest a URL, fire hooks, or produce content until
  `/brain:init` has run and `plugin.json` is valid. BC-2.14.001–005 (plugin manifest,
  lifecycle, read-only engine) and BC-2.01.001–006 (scaffold, SLA, error on non-git-repo,
  embedding_status template, health check) form one coherent unit of user value: "I
  installed the plugin and have a working brain." BC-2.06.003 (manifest.json records
  `last_ingest` timestamps) and BC-2.06.004 (7 default topic categories scaffolded by
  `/brain:init`) are included here because they are scaffold-time responsibilities
  belonging to the init skill and init-produced manifest structure, not to the ingest
  pipeline runtime.

---

## Epic: Hook Enforcement Chain

- **Goal:** Every write to the brain vault passes through a verified hook enforcement
  chain that blocks prompt injection, prevents source overwrite, enforces wikilink
  integrity, validates frontmatter schemas, enforces page-type policy, validates
  source-ID citations, blocks invalid publish-state transitions, enforces kebab-case
  filenames, blocks AI attribution tokens, and emits structured JSONL events. Each hook
  exits 0/1/2 per the canonical contract and completes under 100ms p99.
- **BCs:** BC-2.04.001, BC-2.04.002, BC-2.04.003, BC-2.04.004, BC-2.04.005,
  BC-2.04.006, BC-2.04.007, BC-2.04.008, BC-2.04.009, BC-2.04.010, BC-2.04.011,
  BC-2.04.012, BC-2.04.013, BC-2.04.014, BC-2.04.015, BC-2.04.016, BC-2.04.017,
  BC-2.17.001, BC-2.17.002, BC-2.17.003, BC-2.17.004, BC-2.10.001, BC-2.10.002,
  BC-2.10.003
- **Subsystems touched:** SS-04 (Hook Enforcement Chain), SS-17 (Structured Event
  Catalog), SS-10 (Prompt-Injection Quarantine)
- **Phased-plan anchor:** Build-plan Phase 1 (§5.5 Drop in the bash hooks — production
  enforcement layer). Specifically: all 13 bash hook scripts, hooks.json.template
  wiring, the structured event catalog, and the quarantine corpus patterns (the quarantine
  script is a hook co-requisite: it is invoked by quarantine-fetch.sh and must exist
  before any WebFetch hook can enforce).
- **Estimated stories:** 9
- **Rationale:** SS-04, SS-17, and SS-10 are tightly coupled at the implementation level:
  every SS-04 hook (BC-2.04.001–017) must emit structured JSONL events (BC-2.17.001–004),
  and the quarantine hook (BC-2.04.001) invokes the quarantine corpus (BC-2.10.001–003).
  Splitting these three subsystems across separate epics would create an artificial
  dependency wall: you cannot fully implement and bats-test quarantine-fetch.sh without
  the event catalog, and you cannot implement the event catalog without knowing which
  hooks will emit events. These 24 BCs form one logical delivery chunk: the complete
  hook enforcement layer. SS-10's BC-2.10.001 (quarantine-check skill) is grouped here
  because the quarantine-check skill is a thin wrapper over the same corpus and pattern-
  matching logic already required for quarantine-fetch.sh. Grouping avoids implementing
  the corpus twice. SS-04 BCs are P0-dominant (15 of 17 are P0); SS-17 BCs are all P0;
  SS-10 BCs are all P0 — this is the highest-priority buildable unit after the scaffold.

---

## Epic: Content Capture (URL + Source Ingest)

- **Goal:** An operator can ingest an external URL via Defuddle into 5–15 cross-referenced
  wiki pages with token-budget logging, manifest delta writes, and sub-linear latency as
  the wiki grows. An operator can also ingest a local file into the sources layer with
  proper manifest tracking, out-of-vault rejection, and partial-failure fan-out. Source
  immutability (no overwrite after creation, sha256-based hash) is enforced both at the
  ingest layer and by the hook chain.
- **BCs:** BC-2.02.001, BC-2.02.002, BC-2.02.003, BC-2.02.004, BC-2.02.005,
  BC-2.02.006, BC-2.02.007, BC-2.03.001, BC-2.03.002, BC-2.03.003, BC-2.03.004
- **Subsystems touched:** SS-02 (URL Ingest Pipeline), SS-03 (Source Ingest Pipeline)
- **Phased-plan anchor:** Build-plan Phase 1 (§5 — validated via `§5.10 local dev test`:
  `/brain:ingest-url` must produce 5+ wiki pages with cross-references). This is the
  second-priority capability after hooks because the Phase 1 exit gate (§5.11) requires
  successful end-to-end ingest as a gate criterion.
- **Estimated stories:** 4
- **Rationale:** SS-02 and SS-03 are naturally grouped: both are ingest skills that write
  to `sources/{topic}/` and update `manifest.json`. They share the manifest-delta
  architecture (ADR-010), the source-immutability constraint (ADR-015), and the
  partial-failure fan-out requirement (BC-2.03.004). The URL pipeline adds Defuddle
  integration and wiki-page generation on top of the source write; the local-file pipeline
  is the simpler variant of the same flow. Grouping them allows one implementation sequence:
  implement the shared manifest-write helper (hooks/lib/manifest-write.sh) once, then
  build both pipelines against it. BC-2.06.001 (source immutability post-creation) and
  BC-2.06.002 (manifest chunks array) are in EPIC-01 and EPIC-08 respectively, as they
  are scaffold-time and scale-time responsibilities; the ingest-time enforcement of
  immutability is delegated to the hook chain (EPIC-02).

---

## Epic: Wiki Layer and Content Production

- **Goal:** The wiki layer enforces the six-type page structure, maintains wikilink
  integrity through index-first lookup, and provides a `/brain:rename-page` skill that
  atomically renames a page and propagates all backlinks. The `embedding_status` field
  is mandatory in all wiki page frontmatter. The meta-lint bats suite validates the
  factory's own artifacts (SKILL.md, AGENT.md, hook scripts) structurally.
- **BCs:** BC-2.05.001, BC-2.05.002, BC-2.05.003, BC-2.05.004, BC-2.05.005,
  BC-2.05.006, BC-2.18.001, BC-2.18.002, BC-2.18.003, BC-2.18.004, BC-2.18.005
- **Subsystems touched:** SS-05 (Wiki Layer and Wikilink Integrity), SS-18 (Meta-Lint
  and Self-Audit)
- **Phased-plan anchor:** Build-plan Phase 1 (§5 — wiki layer is required by ingest;
  `/brain:lint-wiki` and `/brain:rename-page` are in the Phase 1 skill set per §5.4
  skill migration list). Meta-lint (SS-18) also lands in Phase 1: the bats test runner
  and `meta-lint.bats` are part of the CI workflow (§5.9) that must run green on push.
- **Estimated stories:** 4
- **Rationale:** SS-05 and SS-18 are grouped because meta-lint's job is to validate the
  artifacts produced by skills and hooks — and both skills and hooks are substantially
  complete by this point in the build. SS-18's five BCs (BC-2.18.001–005) cannot be
  satisfied until SKILL.md files and hook scripts exist (they validate those artifacts);
  grouping with SS-05 places meta-lint in the correct wave after EPIC-01 and EPIC-02
  produce the artifacts to be linted. SS-05's wiki-lint and rename-page capabilities
  are complementary to meta-lint's structural validation: both are about keeping the
  artifact layer coherent. The BC-2.06.001 (source immutability) is in EPIC-01 because
  it is a scaffold invariant; the wiki-side immutability enforcement (validate-source-
  immutability.sh) is in EPIC-02. SS-05 and SS-18 together = "the quality enforcement
  layer for the brain's content and the factory's own artifacts."

---

## Epic: Knowledge Synthesis

- **Goal:** After ingesting content, an operator can run `/brain:connect [days]` to
  surface cross-domain connections across recent ingests, `/brain:synthesize` to build
  a weekly thesis from the connection layer, and `/brain:process-inbox` to classify and
  route inbox notes to the correct wiki type. This closes the "learning loop" — ingested
  content becomes synthesized insight.
- **BCs:** BC-2.11.001, BC-2.11.002, BC-2.11.003
- **Subsystems touched:** SS-11 (Knowledge Synthesis and Connection)
- **Phased-plan anchor:** Build-plan Phase 0 (§4.3/§4.5) — the `connect.md`,
  `synthesize.md`, and `process-inbox.md` skill bodies are part of the Phase 0 manual
  vault; they migrate to the plugin in Phase 1 (§5.4). Build-plan Phase 3 (§7 dogfood)
  is where they get real usage validation. These are P1 BCs; they are built after the
  P0 foundation is stable.
- **Estimated stories:** 2
- **Rationale:** BC-2.11.001–003 are the three synthesis capabilities. They are all P1
  priority, depend on the wiki layer (EPIC-03 ingest produces the pages they synthesize
  across), and have no inter-dependencies with each other that would require further
  splitting. Three BCs → one epic is correct granularity; attempting to split further
  would produce micro-epics with no independent user value. The `process-inbox` skill
  (BC-2.11.003) is included here (not in EPIC-03) because its user value is synthesis/
  routing, not raw ingestion — it classifies existing inbox notes into the wiki type
  taxonomy, which is a synthesis operation.

---

## Epic: Content Brief, Writing, and Publishing

- **Goal:** An operator can generate a content brief in ONE THING / PROOF /
  TRANSFORMATION format, produce a full piece in the author's voice, generate companion
  posts and hero image prompts, pass the voice avoid-list check on brief drafts, and
  publish to LinkedIn via the Posts API with state-machine-enforced transitions
  (draft → ready → published). Performance analytics via `/brain:monthly-perf` complete
  the content lifecycle.
- **BCs:** BC-2.08.001, BC-2.08.002, BC-2.08.003, BC-2.08.004, BC-2.09.001,
  BC-2.09.002, BC-2.09.003, BC-2.09.004, BC-2.09.005, BC-2.09.006
- **Subsystems touched:** SS-08 (Content Brief and Writing), SS-09 (Publishing Pipeline)
- **Phased-plan anchor:** Build-plan Phase 3 (§7 dogfood + pilot users) — the brief →
  write → publish pipeline is the primary value proposition validated by dogfood. Phase
  1 (§5.4) migrates the `brief.md` and `write.md` skill bodies; Phase 3 (§7.5 quality
  bar) requires "at least one piece of content has shipped from a brain → brief → write
  → publish pipeline."
- **Estimated stories:** 5
- **Rationale:** SS-08 and SS-09 form the complete content production pipeline. SS-08
  (brief + write + companion posts + voice avoid-list) leads into SS-09 (publish state
  machine + LinkedIn API + scheduling + performance analytics). The voice avoid-list
  (BC-2.08.004 in SS-08 and BC-2.04.008 in SS-04) spans two subsystems: the hook
  (SS-04) enforces it at write-time, and SS-08's skill body applies it at brief-
  generation time. BC-2.04.008 is correctly in EPIC-02 (the hook) while BC-2.08.004
  (the skill-level enforcement rule) is here. The two are complementary: the hook is
  the backstop; the skill is the proactive application. Separating brief/write from
  publishing would create an artificial dependency: you cannot validate the state machine
  (BC-2.09.004) without the brief → draft → ready → published flow, and you cannot
  validate the publishing API without published content. Grouping delivers the complete
  user journey: "I want to publish a piece from my brain."

---

## Epic: Lobster Runtime and GitHub Action Templates

- **Goal:** The Lobster bash workflow orchestrator (`bin/lobster-run`) reads workflow
  YAML files and executes skill steps in declared dependency order, supporting headless
  execution and the canonical exit-code contract. Six workflow YAML files ship in
  `plugins/brain-factory/workflows/`. Fifteen author-committed GitHub Action templates
  ship in the tarball (v0.1 core set of 6 plus v0.5 additions of 9) with rate-limit
  retry handling, plus 4 community-optional templates with documented no-author-support
  status.
- **BCs:** BC-2.12.001, BC-2.12.002, BC-2.12.003, BC-2.12.004, BC-2.13.001,
  BC-2.13.002, BC-2.13.003, BC-2.13.004
- **Subsystems touched:** SS-12 (Lobster Runtime), SS-13 (GitHub Action Templates)
- **Phased-plan anchor:** Build-plan Phase 1 (§5.2/§5.9 — `bin/lobster-run` is in the
  plugin folder structure; CI workflow uses `run-all.sh` which is lobster-adjacent;
  GH Action templates are in the Phase 1 plugin structure) and Phase 2 (§6 marketplace
  publish — GH Actions are part of the tarball). The v0.1 core 6-template set
  (BC-2.13.001) is a Phase 1 deliverable; the v0.5 9-template additions (BC-2.13.002)
  are Phase 3.
- **Estimated stories:** 4
- **Rationale:** SS-12 and SS-13 are grouped because the GitHub Action templates
  orchestrate brain operations via the Lobster runtime — the templates call `lobster-run`
  (or the skills directly). Lobster is the batch-execution layer the GH Action templates
  depend on. Building them together in one epic ensures the GH Action templates can be
  tested end-to-end against the runtime they invoke. Rate-limit handling (BC-2.13.003)
  is included here because it belongs to the GH Action template implementation; the
  underlying `scripts/lib/api-retry.sh` helper is implemented once for the publishing
  pipeline (EPIC-06) and reused here. BC-2.13.004 (community-optional templates) is
  P2 and is the only P2 BC in the project; it is grouped here because its delivery is
  a simple tarball-packaging step that follows the P0/P1 template work.

---

## Epic: Scale-Aware Architecture and Observability

- **Goal:** Token instrumentation records JSONL per ingest invocation. The health check
  warns when trailing-average token spend exceeds 2x baseline. The system sustains 100
  sources/day over a 5-day test run without data loss, peak resident memory stays under
  2GB, per-ingest token cost stays within 3x baseline at 10K-source corpus, and the
  reproducible synthetic test corpus generator (`scripts/gen-test-corpus.sh`) supports
  scale validation. Source-layer immutability hash algorithm (sha256, content-addressed)
  and the `manifest.json` chunks-array schema for future embedding support are also
  included.
- **BCs:** BC-2.16.001, BC-2.16.002, BC-2.16.003, BC-2.16.004, BC-2.16.005,
  BC-2.16.006, BC-2.06.001, BC-2.06.002
- **Subsystems touched:** SS-16 (Scale-Aware Architecture), SS-06 (Source Layer and
  Immutability — scale-time and schema pieces)
- **Phased-plan anchor:** Build-plan Phase 3 (§7 dogfood — "targets 10x Karpathy scale
  (~10K sources / ~40M words / ~10K wiki pages) as v0.9 tested SLA, not aspiration;
  seven architectural disciplines locked from v0.1"). The synthetic test corpus
  (BC-2.16.006) and sustained-throughput test (BC-2.16.003) are validated during
  dogfood. The token instrumentation (BC-2.16.001) is wired during Phase 1 ingest
  (it is required by BC-2.02.003, which is in EPIC-03), but the alerting, budget
  enforcement, and scale test infrastructure are Phase 3 concerns.
- **Estimated stories:** 4
- **Rationale:** SS-16 and the two remaining SS-06 BCs form the "does this hold at
  scale?" epic. BC-2.06.001 (source immutability after creation — the behavioral
  invariant) and BC-2.06.002 (manifest chunks array schema — the v0.5 embedding
  preparation) are in this epic rather than EPIC-01 or EPIC-03 for the following reasons:
  BC-2.06.001 is an immutability invariant validated by the ADR-015 sha256 algorithm
  (ADR-015 is a scale/architecture decision); its bats test exercises the same hash
  machinery as the scale corpus generator. BC-2.06.002 is a schema forward-compatibility
  concern (the chunks array is populated at v0.5+ per the BC itself), not a scaffold or
  ingest concern — it belongs with scale-related schema work. Grouping both with SS-16
  avoids splitting the immutability hash story across EPIC-01 (init), EPIC-03 (ingest),
  and EPIC-08 (scale). The BC-2.06.003 (last_ingest timestamps) and BC-2.06.004
  (default topic categories) are in EPIC-01 because they are init-time responsibilities.

---

## Epic: Plugin Packaging and Governance

- **Goal:** The adversarial review skill dispatches all four wclaude validation agents,
  runs multi-pass writescore revision, uses a different model family from the producer,
  and returns a structured pass/fail verdict. The governance policies layer is initialized
  by `/brain:init`, supports adding new policies with schema validation, and provides
  policy-registry validation. These capabilities complete the plugin's quality and
  governance surface and are required for the adversarial review gate in the Phase 1
  exit criteria.
- **BCs:** BC-2.07.001, BC-2.07.002, BC-2.07.003, BC-2.07.004, BC-2.15.001,
  BC-2.15.002, BC-2.15.003
- **Subsystems touched:** SS-07 (Adversarial Review and Writescore), SS-15 (Governance
  and Policies)
- **Phased-plan anchor:** Build-plan Phase 1 (§5.11 exit gate — `/brain:ingest-url`
  must produce "adversary-review PASS"; Phase 2 (§6 marketplace publish — governance
  policies are part of the operator onboarding surface). SS-07 is required by the Phase
  1 exit gate criterion. SS-15 is required by the Phase 2 operator trust surface.
- **Estimated stories:** 4
- **Rationale:** SS-07 (adversarial review) and SS-15 (governance policies) are grouped
  as the "quality and governance" epic that completes the plugin's capability surface.
  Both are non-content capabilities — they govern how content is produced and how the
  plugin itself is governed. SS-07 is P0-dominant (BC-2.07.001, 002, 004 are P0; 003
  is P1) and must land before the Phase 1 exit gate, which requires adversary-review
  PASS on a fresh ingest. SS-15 is all P1 and rounds out the operator-facing governance
  surface that makes the plugin trustworthy for pilot users (Phase 3). Separating them
  into two separate epics would create two small epics (4 + 3 = 7 BCs) with no
  independent delivery value — neither SS-07 alone nor SS-15 alone constitutes a
  shippable user-facing capability. Together they form the "the plugin governs itself
  and produces reviewed content" epic, which is a coherent value statement for operator
  confidence.
