# Plan: Migrate vsdd-factory to a Vendored Dispatcher

**Status:** ready to execute
**Owner:** vsdd-factory maintainer
**Date:** 2026-05-14
**Audience for this document:** a future Claude Code session (or human operator) with zero prior context. Self-sufficient — every command, file content, gate, and checkpoint required to execute the migration is embedded below. No sibling planning documents are required.
**Estimated duration:** 2–3 working weeks for the engineering work; 1–2 weeks of soak time before promoting v1.0.0 final.

---

## 0. How to read this plan

This is an **execution plan**, not an architecture proposal. The "why" is in §4. The "what to do" is in §6–§14, phase by phase. Each phase has explicit entry criteria, work steps with literal commands, verification gates, and exit criteria. Do not advance a phase until its exit gate passes.

**If you are executing this plan from zero context:**

1. Read §1–§5 to understand goal, current state, target state, motivation, and risks.
2. Read §6 (prerequisites) and verify all preconditions hold.
3. Execute §8–§14 in order. Do not skip phases.
4. Use §15 (rollback) if any gate fails.
5. Use §17 (per-phase checkpoints) as the canonical verification commands.

**Cycle naming convention (vsdd-factory's own discipline):** this work runs as a named cycle `v1.0-dispatcher-extraction-pass-1` in `.factory/cycles/`, with its own decision-log (D-NNN entries seeded in §16), burst-log, lessons.md, and INDEX.md. State-manager handles bookkeeping per existing TD-VSDD-053 single-commit-per-burst discipline.

---

## 1. Goal & non-goals

### Goal

Extract the four engine crates and five sink crates currently in `vsdd-factory/crates/` into a separate shared repo named `factory-dispatcher`. Convert vsdd-factory's release pipeline to download and vendor the compiled binaries (and depend on the published crates) instead of building them locally. Preserve every operator-facing behavior. Pass all 534 bats tests after migration.

### Non-goals

- **Not changing hook behavior.** Every WASM hook plugin behaves identically pre- and post-migration.
- **Not changing the host ABI.** Whatever ABI hook-sdk currently exposes becomes the v1.0.0 stable contract. ABI design changes are explicitly out of scope.
- **Not changing observability semantics.** Sinks emit the same events, same fields, same routing as before.
- **Not extracting VSDD-specific resolvers.** Only the resolver *framework* (trait + registry) moves; the VSDD-specific resolver implementations (BC-INDEX, ARCH-INDEX, etc.) stay in vsdd-factory.
- **Not collapsing the bash→WASM hook migration (E-10).** That work continues on its own track; this migration is orthogonal.
- **Not changing the marketplace name.** Operators continue to install via `/plugin install vsdd-factory@claude-mp`.
- **Not changing the dispatcher binary's on-disk location.** Operators continue to find it at `~/.claude/plugins/cache/claude-mp/vsdd-factory/<version>/hooks/dispatcher/bin/<platform>/factory-dispatcher`. Only the build path changes (vendored, not in-tree).

---

## 2. Current state (pre-migration)

```
vsdd-factory/                               # current repo
├── crates/
│   ├── factory-dispatcher/                 # ← MOVE OUT
│   ├── hook-sdk/                           # ← MOVE OUT
│   ├── hook-sdk-macros/                    # ← MOVE OUT
│   ├── vsdd-context-resolvers/             # ← SPLIT (framework moves; impls stay)
│   ├── sink-file/                          # ← MOVE OUT
│   ├── sink-otel-grpc/                     # ← MOVE OUT
│   ├── sink-datadog/                       # ← MOVE OUT
│   ├── sink-honeycomb/                     # ← MOVE OUT
│   ├── sink-http/                          # ← MOVE OUT
│   ├── hook-plugins/                       # ← STAYS (52 VSDD-specific WASM plugins)
│   └── ...
├── plugins/vsdd-factory/
│   ├── hooks/dispatcher/bin/<platform>/    # ← becomes vendored, not built
│   ├── hook-plugins/*.wasm                 # ← stays; rebuilt against published hook-sdk
│   ├── hooks-registry.toml                 # ← stays; possibly schema-bumped
│   └── hooks/*.sh                          # ← stays (bash legacy + fallback; E-10 in flight)
├── Cargo.toml                              # ← workspace surgery; remove 9 members, add crates.io deps
├── Cargo.lock                              # ← regenerated
└── .github/workflows/release.yml           # ← swap "cargo build dispatcher" for "vendor-dispatcher.mjs"
```

**Concretely, the crates leaving the workspace:**

1. `factory-dispatcher` — the dispatcher binary
2. `hook-sdk` — public library; crates.io publish target
3. `hook-sdk-macros` — proc macros; crates.io publish target
4. `vsdd-context-resolvers` — split: framework half moves as `context-resolvers-core`; VSDD impls stay (renamed appropriately, see §11.3)
5. `sink-file`
6. `sink-otel-grpc`
7. `sink-datadog`
8. `sink-honeycomb`
9. `sink-http`

**Versioning baseline as of plan authoring:**

- vsdd-factory plugin: `v1.0.0-rc.18` (or whatever is current at execution time — see §6 step 5)
- 52 WASM hook plugins compiled against the in-tree hook-sdk
- 534 bats tests across 17 suites
- Marketplace: `drbothen/claude-mp`
- Active F5 convergence cycle: `v1.0-feature-engine-discipline-pass-1` (PR #124 open draft as of last commit)

---

## 3. Target state (post-migration)

```
factory-dispatcher/                         # NEW shared repo
├── crates/
│   ├── factory-dispatcher/                 # the binary
│   ├── hook-sdk/                           # crates.io: hook-sdk@1.0.0
│   ├── hook-sdk-macros/                    # crates.io: hook-sdk-macros@1.0.0
│   ├── context-resolvers-core/             # crates.io: context-resolvers-core@1.0.0
│   ├── sink-file/                          # crates.io: sink-file@1.0.0
│   ├── sink-otel-grpc/                     # crates.io: sink-otel-grpc@1.0.0
│   ├── sink-datadog/                       # crates.io: sink-datadog@1.0.0
│   ├── sink-honeycomb/                     # crates.io: sink-honeycomb@1.0.0
│   └── sink-http/                          # crates.io: sink-http@1.0.0
├── docs/{authoring-hooks,host-abi,semver-commitment,consumer-integration,observability-sinks}.md
├── examples/{echo-hook,consumer-factory-template}/
├── .github/workflows/{ci,release}.yml
└── README.md
                                            # Tagged v1.0.0 → 5 platform binaries on GH Releases

vsdd-factory/                               # SAME repo, post-surgery
├── crates/
│   ├── hook-plugins/                       # 52 VSDD WASM plugins (depend on hook-sdk from crates.io)
│   ├── vsdd-context-resolvers/             # VSDD-specific resolver impls (depend on context-resolvers-core)
│   └── ... (any other VSDD-specific crates)
├── plugins/vsdd-factory/
│   ├── hooks/dispatcher/bin/<platform>/    # VENDORED binaries from factory-dispatcher GH Releases
│   ├── hook-plugins/*.wasm                 # built locally from crates/hook-plugins/
│   ├── hooks-registry.toml                 # unchanged
│   └── hooks/*.sh                          # unchanged
├── vendor-dispatcher.yaml                  # NEW: pins factory-dispatcher version + per-platform SHA256
├── scripts/vendor-dispatcher.mjs           # NEW: download + SHA-verify + lay out binaries
├── Cargo.toml                              # SHRINKEN workspace (9 members removed)
└── .github/workflows/release.yml           # MODIFIED: calls vendor-dispatcher.mjs
```

**Operator-facing changes:** zero. Install command, binary location, behavior, observability all identical.

**Developer-facing changes:**

- Dispatcher source lives elsewhere; bugs in the dispatcher are filed on the `factory-dispatcher` repo
- ABI / SDK changes go through the shared repo's release process
- `cargo test --workspace` in vsdd-factory no longer builds the dispatcher (faster CI)
- A bumped dispatcher pin in vsdd-factory is a 2-line change to `vendor-dispatcher.yaml` followed by a re-release

---

## 4. Why this migration

Three reasons; in order of weight:

1. **Multiple factories need the dispatcher.** The `brain-factory` plugin (planned) needs the same hook runtime. Future factories (research, ops, sales-process) will too. Each forking the dispatcher = N implementations diverging = no shared improvements. Extracting once unlocks every future factory.
2. **Cleaner stability story.** The dispatcher + SDK + sinks have implicit semver guarantees today (hook plugins compiled against a given hook-sdk version expect a compatible dispatcher). Making this explicit via separate versioning + published crates.io artifacts + documented host-ABI surface = fewer "why did this WASM plugin stop loading?" surprises.
3. **Faster vsdd-factory CI.** vsdd-factory's `cargo test --workspace` currently rebuilds the dispatcher binary on every PR. After migration, only the WASM plugins build. CI minute savings: estimated 30–50% per run.

The marginal cost is one repo + one release pipeline + one stability commitment. The marginal gain is every future factory and every future operator who debugs less.

---

## 5. Risks & mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| Behavioral drift between in-tree dispatcher and v1.0.0 vendored binary | HIGH | Phase 5 parity gate: byte-compare or behavior-test the two dispatchers on the same input corpus before promoting. |
| WASM plugins compiled against published hook-sdk fail to load | HIGH | Phase 4 gate: rebuild all 52 plugins + load-test in dispatcher before merging. |
| Cargo workspace surgery breaks the F5 cycle in flight (PR #124) | MEDIUM | Phase 1: pause F5 (mark PR #124 do-not-merge during migration); resume on new base after Phase 6. |
| Operator install breaks (binary path changed, manifest mismatch) | MEDIUM | Phase 5 smoke test: fresh install in clean home dir; verify dispatcher resolves at expected path. |
| Self-referential discipline: vsdd-factory's own hooks block its `.factory/` commits during migration | MEDIUM | Operator-level cache holds the OLD dispatcher; develop-branch source changes don't affect it. Migration commits proceed normally. |
| SHA mismatch between vendor-dispatcher.yaml pin and downloaded binary | LOW | scripts/vendor-dispatcher.mjs fails closed; CI verifies on every build. |
| crates.io publish failure mid-release | LOW | Publish order: macros → sdk → resolvers-core → sinks. Each is independent crate-publish; failure of one doesn't corrupt the others. |
| Operator on stale dispatcher version after upgrade (cache not refreshed) | LOW | Plugin tarball carries the dispatcher; install always overwrites cache. Document in release notes. |
| 534 bats tests fail because they depended on local cargo build artifacts | LOW | Phase 4 fixes any test that walks `target/`; replace with operator-cache paths. |
| Shared repo gets the wrong stewardship model and stalls | MEDIUM | §6 prerequisite: human locks stewardship before Phase 2. |

---

## 6. Prerequisites (must all hold before Phase 1)

Run these checks first. If any fails, resolve before continuing.

```bash
# 1. vsdd-factory main branch is clean and CI is green.
cd /path/to/vsdd-factory
git checkout main
git pull --ff-only
git status --porcelain | wc -l   # must be 0
gh run list --branch main --workflow ci.yml --limit 1 --json conclusion --jq '.[0].conclusion'  # must be "success"

# 2. develop branch is in known state.
git checkout develop
git pull --ff-only
gh run list --branch develop --workflow ci.yml --limit 1 --json conclusion --jq '.[0].conclusion'  # must be "success"

# 3. No open release branch.
git branch --list 'release/*' --all | grep -v 'HEAD ->' | wc -l   # must be 0; if not, finish current release first

# 4. F5 cycle PR (currently #124) is in known state.
gh pr view 124 --json state,isDraft --jq '"\(.state) \(.isDraft)"'   # observe; if MERGEABLE+draft, decide hold-or-merge with human

# 5. Latest vsdd-factory version is captured.
gh release view --json tagName --jq '.tagName' > .baseline-version.txt
cat .baseline-version.txt
```

Human decisions required before Phase 1 (lock these in writing, see §16 for the D-NNN seed entries that will record them):

- [ ] **Shared repo name.** Default: `factory-dispatcher`. Alternatives: `claude-factory-runtime`, `hookforge`, `claude-hook-platform`. Pick one. (Below assumes `factory-dispatcher`.)
- [ ] **Shared repo owner / stewardship.** Same GitHub account as vsdd-factory in bootstrap phase; separable governance later. Confirm.
- [ ] **Sink subset for v1.0.0.** All five (file, otel-grpc, datadog, honeycomb, http), or subset? Default: all five.
- [ ] **F5 cycle disposition.** Pause for migration (recommended) or wait for F5 to converge first.
- [ ] **Target dispatcher v1.0.0 date.** Pick a target. Default: 2 weeks after Phase 2 begins.
- [ ] **Operator communication channel.** How are operators told about the migration? CHANGELOG entry, GitHub Discussion, or both?

---

## 7. Cycle structure (vsdd-factory's own bookkeeping)

This migration runs as cycle `v1.0-dispatcher-extraction-pass-1` in vsdd-factory's `.factory/cycles/` discipline. Bookkeeping artifacts created at cycle init (state-manager dispatch):

```
.factory/cycles/v1.0-dispatcher-extraction-pass-1/
├── cycle-manifest.md           # scope, target, success criteria, links to this plan
├── decision-log.md             # D-NNN entries (see §16 seed)
├── burst-log.md                # per-burst structural record per D-444(c)
├── lessons.md                  # L-DE1-NNN cumulative
├── INDEX.md                    # adversarial reviews table (likely empty — migration not adversarial)
└── retrospective.md            # written at Phase 7
```

The migration deliberately runs **concurrent** with the F5 cycle (`v1.0-feature-engine-discipline-pass-1`), not nested. STATE.md Concurrent Cycles tail shows both per D-433(e)+D-439(c) length=4 convention.

**Commit discipline:** every phase produces 1–N atomic commits per TD-VSDD-053 single-commit-per-burst. State-manager handles `.factory/` bookkeeping commits per existing convention (see vsdd-factory CLAUDE.md). This plan describes the engineering bursts; state-manager dispatches happen per existing protocol.

**Convergence criteria** (different from F5 convergence — this is structural, not adversarial):

| Dimension | Criterion |
|---|---|
| Build | `cargo build --workspace --all-targets` clean in both repos |
| Tests | All 534 bats tests pass in vsdd-factory; all `cargo test --workspace` pass in factory-dispatcher |
| Parity | Vendored dispatcher passes byte-equivalent or behavior-equivalent gate on shared input corpus (§12) |
| Operator | Fresh `/plugin install` produces working dispatcher at expected path |
| ABI | All 52 WASM plugins load successfully under the vendored dispatcher |
| Docs | CHANGELOG, README, FACTORY.md, hooks-reference.md updated; consumer-integration.md exists in shared repo |

Cycle closes when all six are GREEN.

---

## 8. Phase 1 — Decision lock & baseline

**Purpose:** lock the human decisions, capture an immutable baseline, pause the F5 cycle if applicable.

**Entry criteria:** §6 prerequisites all pass.

### 8.1 Lock decisions

Human signs off (or plan executor surfaces) on every checkbox in §6. Record verbatim in the cycle's decision-log:

```
.factory/cycles/v1.0-dispatcher-extraction-pass-1/decision-log.md

D-DE1-001 [2026-MM-DD] Lock shared repo name: `factory-dispatcher`. Owner: <github-user>. License: MIT.
D-DE1-002 [2026-MM-DD] Lock host ABI version 1.0.0. Whatever hook-sdk currently exposes becomes the stable v1 surface. Breaking changes require v2.
D-DE1-003 [2026-MM-DD] Sink subset for v1.0.0: all five (file, otel-grpc, datadog, honeycomb, http).
D-DE1-004 [2026-MM-DD] F5 cycle disposition: pause. PR #124 marked do-not-merge until cycle close.
D-DE1-005 [2026-MM-DD] Target factory-dispatcher v1.0.0 release date: <date>.
D-DE1-006 [2026-MM-DD] Operator communication: CHANGELOG entry + GitHub Discussion at promotion.
D-DE1-007 [2026-MM-DD] Crate split — vsdd-context-resolvers separates into context-resolvers-core (generic, moves) and vsdd-context-resolvers (impls, stays).
```

### 8.2 Baseline tag

```bash
cd /path/to/vsdd-factory
git checkout main
git pull --ff-only
git tag -a baseline/pre-dispatcher-extraction -m "Baseline before dispatcher extraction. Last commit prior to v1.0-dispatcher-extraction-pass-1 cycle."
git push origin baseline/pre-dispatcher-extraction
```

### 8.3 Capture current artifacts

```bash
# Build the current dispatcher (the canonical "old" binary).
cd /path/to/vsdd-factory
cargo build --release -p factory-dispatcher
mkdir -p .baseline-artifacts/
cp target/release/factory-dispatcher .baseline-artifacts/factory-dispatcher-baseline

# Capture SHA for later parity check.
sha256sum .baseline-artifacts/factory-dispatcher-baseline > .baseline-artifacts/dispatcher-baseline.sha256

# Capture the current public API surface of each crate moving out.
for CRATE in factory-dispatcher hook-sdk hook-sdk-macros vsdd-context-resolvers sink-file sink-otel-grpc sink-datadog sink-honeycomb sink-http; do
  cargo +nightly rustdoc -p "$CRATE" -- --output-format json -Z unstable-options 2>/dev/null || true
  cp -r "target/doc/$CRATE.json" ".baseline-artifacts/${CRATE}-api.json" 2>/dev/null || \
    cargo doc -p "$CRATE" --no-deps && cp -r "target/doc/$CRATE" ".baseline-artifacts/${CRATE}-doc"
done

# Capture current bats test results as a green baseline.
cd plugins/vsdd-factory/tests && ./run-all.sh 2>&1 | tee ../../../.baseline-artifacts/bats-baseline.log
grep -E '^(ok|not ok|# tests)' ../../../.baseline-artifacts/bats-baseline.log | tail -5

# Add to git (state-manager handles the actual commit per single-commit-per-burst).
git add .baseline-artifacts/
```

### 8.4 Pause F5 cycle

If F5 is in flight:

```bash
# Comment on PR #124 marking it on-hold.
gh pr comment 124 --body "🛑 On hold during v1.0-dispatcher-extraction-pass-1 cycle. Will resume after extraction promotes."

# Update STATE.md frontmatter to note concurrent cycle. (state-manager dispatch — single commit per TD-VSDD-053.)
# Per D-433(e)+D-439(c) Concurrent Cycles tail LENGTH=4 convention.
```

### 8.5 Open cycle in vsdd-factory

state-manager dispatch creates:
- `.factory/cycles/v1.0-dispatcher-extraction-pass-1/cycle-manifest.md` (scope, target, links to this plan)
- `.factory/cycles/v1.0-dispatcher-extraction-pass-1/decision-log.md` (D-DE1-001..007 from §8.1)
- `.factory/cycles/v1.0-dispatcher-extraction-pass-1/burst-log.md` (empty header)
- `.factory/cycles/v1.0-dispatcher-extraction-pass-1/lessons.md` (empty header)
- `.factory/cycles/v1.0-dispatcher-extraction-pass-1/INDEX.md` (empty)

Single atomic commit on `factory-artifacts` branch (per existing vsdd-factory convention).

### 8.6 Exit gate

- [ ] All decisions in §8.1 logged with D-DE1-NNN identifiers.
- [ ] `baseline/pre-dispatcher-extraction` tag exists at origin.
- [ ] `.baseline-artifacts/` directory present with baseline binary, SHA, API surfaces, bats results.
- [ ] F5 PR #124 marked on-hold (if applicable).
- [ ] Cycle directory exists with manifest and seed decision-log.

---

## 9. Phase 2 — Stand up `factory-dispatcher` repo

**Purpose:** create the shared repo, lift the nine crates with git history preserved, get CI green, tag a v1.0.0-rc.1.

**Entry criteria:** Phase 1 exit gate passed.

### 9.1 Create the repo

```bash
# Create empty repo on GitHub (use locked owner from D-DE1-001).
OWNER=<locked-owner>
gh repo create "$OWNER/factory-dispatcher" --public --description "Generic hook dispatcher and WASM SDK for Claude Code factory plugins. Used by vsdd-factory, brain-factory, and other plugin ecosystems."

# Clone locally.
cd ~/Dev
git clone "git@github.com:$OWNER/factory-dispatcher.git"
cd factory-dispatcher
```

### 9.2 Lift the nine crates with history preserved

Use `git subtree split` from vsdd-factory to preserve per-crate git history. Each split produces a branch containing only that crate's history; we then fetch those into the new repo.

```bash
# Setup: in vsdd-factory, produce subtree splits for each crate.
cd /path/to/vsdd-factory
git checkout main

for CRATE in factory-dispatcher hook-sdk hook-sdk-macros vsdd-context-resolvers sink-file sink-otel-grpc sink-datadog sink-honeycomb sink-http; do
  git subtree split --prefix="crates/$CRATE" -b "split/$CRATE"
done

# Note: vsdd-context-resolvers is a SPLIT (framework moves, impls stay).
# The subtree split brings the whole crate's history; the actual split happens in §11.3.
# For now, lift everything and re-divide later.

# Add vsdd-factory as a remote inside the new factory-dispatcher repo.
cd ~/Dev/factory-dispatcher
git remote add vsdd /path/to/vsdd-factory  # local path or git@github URL
git fetch vsdd

# Create the workspace skeleton.
mkdir -p crates docs examples .github/workflows

# For each crate, merge its split branch as a subdirectory.
for CRATE in factory-dispatcher hook-sdk hook-sdk-macros vsdd-context-resolvers sink-file sink-otel-grpc sink-datadog sink-honeycomb sink-http; do
  git merge --allow-unrelated-histories -s ours --no-commit "vsdd/split/$CRATE" || true
  git read-tree --prefix="crates/$CRATE/" -u "vsdd/split/$CRATE"
  git commit -m "feat($CRATE): lift from vsdd-factory @ baseline/pre-dispatcher-extraction"
done

# Rename vsdd-context-resolvers → context-resolvers-core. The VSDD-specific impls
# inside will be removed in §9.3 (only the trait + registry remains here).
git mv crates/vsdd-context-resolvers crates/context-resolvers-core
git commit -m "rename: vsdd-context-resolvers → context-resolvers-core (generic framework only)"
```

### 9.3 Strip VSDD specifics from `context-resolvers-core`

This crate currently contains both the generic resolver framework AND VSDD-specific resolver implementations. The split:

- **Keep in factory-dispatcher/context-resolvers-core/:** the `ContextResolver` trait, the `ResolverRegistry`, the WASM loading lifecycle, the host-ABI bindings.
- **Move back to vsdd-factory:** the VSDD-specific resolver impls (BC-INDEX-resolver, ARCH-INDEX-resolver, Linear-resolver, GitHub-PR-resolver, etc.).

Practically:

```bash
cd ~/Dev/factory-dispatcher/crates/context-resolvers-core
# Inventory what's in the crate.
ls src/

# Audit each file: is it generic (stays) or VSDD-specific (gets removed here, kept in vsdd-factory)?
# This is a judgment call; the test is "would another factory want to use this verbatim?"
# Trait + registry + ABI = generic. Specific resolver implementations = not generic.

# Remove VSDD-specific files (these get re-added to vsdd-factory's crates/vsdd-context-resolvers in §11.3).
git rm src/bc_index_resolver.rs src/arch_index_resolver.rs src/linear_resolver.rs src/github_pr_resolver.rs
# Update mod.rs / lib.rs to remove their declarations.

# Verify the remaining crate compiles standalone.
cargo build -p context-resolvers-core
cargo test -p context-resolvers-core

git commit -m "refactor(context-resolvers-core): remove VSDD-specific resolvers; keep generic framework only"
```

### 9.4 Workspace Cargo.toml

Write `factory-dispatcher/Cargo.toml`:

```toml
[workspace]
resolver = "2"
members = [
  "crates/factory-dispatcher",
  "crates/hook-sdk",
  "crates/hook-sdk-macros",
  "crates/context-resolvers-core",
  "crates/sink-file",
  "crates/sink-otel-grpc",
  "crates/sink-datadog",
  "crates/sink-honeycomb",
  "crates/sink-http",
]

[workspace.package]
version = "1.0.0-rc.1"
edition = "2021"
license = "MIT"
repository = "https://github.com/<owner>/factory-dispatcher"
homepage = "https://github.com/<owner>/factory-dispatcher"

[workspace.dependencies]
# pinned versions of shared deps (wasmtime, tokio, serde, etc.) — copy from vsdd-factory's current
# workspace Cargo.toml to preserve the working dependency tree.
```

Each crate's `Cargo.toml` updates `version = "1.0.0-rc.1"` and uses workspace-inherited package metadata.

### 9.5 Inter-crate dependencies

Update internal `path = "../crate-x"` references to workspace dependencies:

```toml
# In factory-dispatcher/crates/factory-dispatcher/Cargo.toml:
[dependencies]
hook-sdk = { path = "../hook-sdk", version = "1.0.0-rc.1" }
context-resolvers-core = { path = "../context-resolvers-core", version = "1.0.0-rc.1" }
sink-file = { path = "../sink-file", version = "1.0.0-rc.1" }
# ... etc
```

Important: include both `path` AND `version` so the crate publishes cleanly to crates.io later. Without `version`, `cargo publish` fails.

### 9.6 Validate the build

```bash
cd ~/Dev/factory-dispatcher
cargo build --workspace --all-targets
cargo test --workspace --all-targets
cargo fmt --check --all
cargo clippy --workspace --all-targets -- -D warnings
```

If anything fails, fix in place. Common failure modes:

- Missing `version =` in workspace member Cargo.toml → add.
- Internal references to `vsdd_*` types that came along with the move → either inline them (if generic) or remove (if VSDD-specific; they belong back in vsdd-factory).
- Test fixtures that reference VSDD paths → move to vsdd-factory or rewrite as generic.

### 9.7 Add CI workflow

`.github/workflows/ci.yml`:

```yaml
name: CI
on:
  pull_request:
  push: { branches: [main] }
jobs:
  test:
    strategy:
      matrix:
        runner: [ubuntu-latest, macos-14, windows-latest]
    runs-on: ${{ matrix.runner }}
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: rustfmt, clippy }
      - run: cargo build --workspace --all-targets
      - run: cargo test --workspace --all-targets
  fmt:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: rustfmt }
      - run: cargo fmt --check --all
  clippy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with: { components: clippy }
      - run: cargo clippy --workspace --all-targets -- -D warnings
```

### 9.8 Add release workflow

`.github/workflows/release.yml`:

```yaml
name: Release
on:
  push:
    tags: ['v*']
permissions:
  contents: write
jobs:
  binaries:
    strategy:
      fail-fast: false
      matrix:
        target:
          - { runner: macos-14,      triple: aarch64-apple-darwin,      artifact: factory-dispatcher-${{ github.ref_name }}-darwin-arm64 }
          - { runner: macos-13,      triple: x86_64-apple-darwin,       artifact: factory-dispatcher-${{ github.ref_name }}-darwin-x86_64 }
          - { runner: ubuntu-latest, triple: x86_64-unknown-linux-gnu,  artifact: factory-dispatcher-${{ github.ref_name }}-linux-x86_64-gnu }
          - { runner: ubuntu-latest, triple: x86_64-unknown-linux-musl, artifact: factory-dispatcher-${{ github.ref_name }}-linux-x86_64-musl }
          - { runner: windows-latest,triple: x86_64-pc-windows-msvc,    artifact: factory-dispatcher-${{ github.ref_name }}-windows-x86_64.exe }
    runs-on: ${{ matrix.target.runner }}
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - if: matrix.target.triple == 'x86_64-unknown-linux-musl'
        run: sudo apt-get update && sudo apt-get install -y musl-tools
      - run: rustup target add ${{ matrix.target.triple }}
      - run: cargo build --release --target ${{ matrix.target.triple }} -p factory-dispatcher
      - shell: bash
        run: |
          BIN="target/${{ matrix.target.triple }}/release/factory-dispatcher"
          [[ "${{ matrix.target.triple }}" == *windows* ]] && BIN="${BIN}.exe"
          cp "$BIN" "${{ matrix.target.artifact }}"
          sha256sum "${{ matrix.target.artifact }}" > "${{ matrix.target.artifact }}.sha256"
      - uses: actions/upload-artifact@v4
        with:
          name: ${{ matrix.target.artifact }}
          path: |
            ${{ matrix.target.artifact }}
            ${{ matrix.target.artifact }}.sha256

  publish-release:
    needs: binaries
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/download-artifact@v4
        with: { path: artifacts }
      - run: |
          cd artifacts
          cat */*.sha256 > ../SHA256SUMS
          ls -R
      - run: gh release create ${{ github.ref_name }} --generate-notes artifacts/*/factory-dispatcher-* SHA256SUMS
        env: { GH_TOKEN: ${{ secrets.GITHUB_TOKEN }} }

  crates-io-publish:
    needs: publish-release
    if: ${{ !contains(github.ref_name, 'rc') }}   # only publish to crates.io on full releases, not RCs
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - run: |
          # Publish in dependency order.
          cargo publish -p hook-sdk-macros
          sleep 30   # crates.io indexing
          cargo publish -p hook-sdk
          sleep 30
          cargo publish -p context-resolvers-core
          sleep 30
          for s in sink-file sink-otel-grpc sink-datadog sink-honeycomb sink-http; do
            cargo publish -p "$s"
            sleep 30
          done
        env: { CARGO_REGISTRY_TOKEN: ${{ secrets.CARGO_REGISTRY_TOKEN }} }
```

### 9.9 Add docs

Minimum docs for v1.0.0-rc.1:

- `README.md` — what this is, install, basic usage, link to consumer-integration.md
- `docs/consumer-integration.md` — how a factory vendors the dispatcher (vendor-dispatcher.yaml schema, vendor-dispatcher.mjs reference impl)
- `docs/authoring-hooks.md` — how to write a WASM hook plugin (compile target, ABI version, host functions available)
- `docs/host-abi.md` — versioned ABI surface
- `docs/semver-commitment.md` — stability guarantees: host ABI v1.x stable; SDK breaking changes require v2 SDK and v2 dispatcher

Lift content from vsdd-factory's existing equivalent docs (`docs/guide/authoring-hooks.md`, `docs/guide/observability-sinks.md`, `docs/guide/semver-commitment.md`). Genericize: remove VSDD-specific examples; replace with the new `examples/echo-hook/`.

### 9.10 Add example hook

`examples/echo-hook/` — minimal WASM hook plugin:

```toml
# examples/echo-hook/Cargo.toml
[package]
name = "echo-hook"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib"]

[dependencies]
hook-sdk = { path = "../../crates/hook-sdk", version = "1.0.0-rc.1" }
```

```rust
// examples/echo-hook/src/lib.rs
use hook_sdk::*;

#[hook]
pub fn on_pre_tool_use(payload: HookPayload) -> HookVerdict {
    eprintln!("echo-hook: tool={} matcher={:?}", payload.tool_name, payload.matcher);
    HookVerdict::Ok
}
```

Build and verify:

```bash
cd ~/Dev/factory-dispatcher
rustup target add wasm32-wasip1
cargo build --target wasm32-wasip1 --release -p echo-hook
ls target/wasm32-wasip1/release/echo_hook.wasm  # must exist
```

### 9.11 Tag v1.0.0-rc.1

```bash
cd ~/Dev/factory-dispatcher
git add .
git commit -m "feat: factory-dispatcher v1.0.0-rc.1 — initial release candidate"
git push origin main
git tag -a v1.0.0-rc.1 -m "v1.0.0-rc.1 — extracted from vsdd-factory baseline/pre-dispatcher-extraction"
git push origin v1.0.0-rc.1
```

The release workflow fires, produces 5 platform binaries on GH Releases, skips crates.io publish (RC gate).

### 9.12 Exit gate

- [ ] `factory-dispatcher` repo exists at locked owner.
- [ ] All 9 crates lifted with preserved git history (verify via `git log --follow crates/<crate>/Cargo.toml`).
- [ ] `cargo build --workspace --all-targets` clean.
- [ ] `cargo test --workspace --all-targets` clean.
- [ ] `cargo fmt --check` and `cargo clippy -- -D warnings` clean.
- [ ] v1.0.0-rc.1 tag exists; release workflow ran green; 5 platform binaries on GH Releases with SHA256SUMS.
- [ ] `examples/echo-hook` compiles to WASM successfully.

---

## 10. Phase 3 — Wire vendoring into vsdd-factory

**Purpose:** add the consumer-side vendoring config and scripts. Don't yet remove anything from vsdd-factory's workspace — that's Phase 4.

**Entry criteria:** Phase 2 exit gate passed.

### 10.1 Create migration branch

```bash
cd /path/to/vsdd-factory
git checkout develop
git pull --ff-only
git checkout -b feature/dispatcher-extraction-vendoring
```

### 10.2 Compute SHA256 of each platform binary

```bash
mkdir -p /tmp/dispatcher-shas
cd /tmp/dispatcher-shas
gh release download v1.0.0-rc.1 -R <owner>/factory-dispatcher
for FILE in factory-dispatcher-v1.0.0-rc.1-*; do
  echo "${FILE}: $(sha256sum "$FILE" | awk '{print $1}')"
done > shas.txt
cat shas.txt
```

Use these SHAs in §10.3.

### 10.3 Add `vendor-dispatcher.yaml`

At vsdd-factory repo root:

```yaml
# vendor-dispatcher.yaml — pins the shared factory-dispatcher version this plugin ships.
# Updated deliberately; verified by SHA256 at vendor time.
dispatcher:
  repo: <owner>/factory-dispatcher
  version: v1.0.0-rc.1
  artifacts:
    darwin-arm64:
      url: https://github.com/<owner>/factory-dispatcher/releases/download/v1.0.0-rc.1/factory-dispatcher-v1.0.0-rc.1-darwin-arm64
      sha256: <paste from §10.2>
    darwin-x86_64:
      url: https://github.com/<owner>/factory-dispatcher/releases/download/v1.0.0-rc.1/factory-dispatcher-v1.0.0-rc.1-darwin-x86_64
      sha256: <paste>
    linux-x86_64-gnu:
      url: https://github.com/<owner>/factory-dispatcher/releases/download/v1.0.0-rc.1/factory-dispatcher-v1.0.0-rc.1-linux-x86_64-gnu
      sha256: <paste>
    linux-x86_64-musl:
      url: https://github.com/<owner>/factory-dispatcher/releases/download/v1.0.0-rc.1/factory-dispatcher-v1.0.0-rc.1-linux-x86_64-musl
      sha256: <paste>
    windows-x86_64:
      url: https://github.com/<owner>/factory-dispatcher/releases/download/v1.0.0-rc.1/factory-dispatcher-v1.0.0-rc.1-windows-x86_64.exe
      sha256: <paste>
```

### 10.4 Add `scripts/vendor-dispatcher.mjs`

Create `scripts/vendor-dispatcher.mjs`:

```javascript
#!/usr/bin/env node
// scripts/vendor-dispatcher.mjs
// Reads vendor-dispatcher.yaml, downloads each platform binary, verifies SHA256,
// places at plugins/vsdd-factory/hooks/dispatcher/bin/<platform>/factory-dispatcher[.exe].
// Idempotent. Fails closed on any SHA mismatch or download failure.

import fs from "node:fs";
import path from "node:path";
import { execSync } from "node:child_process";
import yaml from "js-yaml";
import crypto from "node:crypto";

const REPO_ROOT = path.resolve(import.meta.dirname, "..");
const CONFIG_PATH = path.join(REPO_ROOT, "vendor-dispatcher.yaml");
const BIN_BASE = path.join(REPO_ROOT, "plugins/vsdd-factory/hooks/dispatcher/bin");

const config = yaml.load(fs.readFileSync(CONFIG_PATH, "utf8"));
const { artifacts, version } = config.dispatcher;

console.log(`Vendoring factory-dispatcher ${version}`);

for (const [platform, spec] of Object.entries(artifacts)) {
  const isWindows = platform === "windows-x86_64";
  const targetDir = path.join(BIN_BASE, platform);
  const binName = isWindows ? "factory-dispatcher.exe" : "factory-dispatcher";
  const targetPath = path.join(targetDir, binName);

  fs.mkdirSync(targetDir, { recursive: true });

  // Skip if already present with correct SHA (idempotent).
  if (fs.existsSync(targetPath)) {
    const existingSha = crypto.createHash("sha256").update(fs.readFileSync(targetPath)).digest("hex");
    if (existingSha === spec.sha256) {
      console.log(`  ✓ ${platform}: already vendored, SHA matches`);
      continue;
    }
    console.log(`  ! ${platform}: SHA mismatch; re-downloading`);
  }

  console.log(`  → ${platform}: downloading ${spec.url}`);
  execSync(`curl -fsSL -o "${targetPath}" "${spec.url}"`, { stdio: "inherit" });

  const downloadedSha = crypto.createHash("sha256").update(fs.readFileSync(targetPath)).digest("hex");
  if (downloadedSha !== spec.sha256) {
    fs.rmSync(targetPath);
    throw new Error(`SHA256 mismatch for ${platform}\n  expected: ${spec.sha256}\n  got:      ${downloadedSha}`);
  }

  if (!isWindows) fs.chmodSync(targetPath, 0o755);
  console.log(`  ✓ ${platform}: SHA verified`);

  // Write provenance marker next to the binary.
  fs.writeFileSync(
    path.join(targetDir, "dispatcher-version.txt"),
    `${version}\nsource: ${spec.url}\nsha256: ${spec.sha256}\nvendored: ${new Date().toISOString()}\n`
  );
}

console.log(`Vendored ${Object.keys(artifacts).length} platform binaries.`);
```

### 10.5 Add npm script invocation (so dev + CI have one entry point)

If vsdd-factory doesn't already have a `package.json` at root, add a minimal one:

```json
{
  "name": "vsdd-factory-tooling",
  "private": true,
  "type": "module",
  "scripts": {
    "vendor-dispatcher": "node scripts/vendor-dispatcher.mjs"
  },
  "dependencies": {
    "js-yaml": "^4.1.0"
  }
}
```

If a package.json exists, add the script + dep.

### 10.6 Verify vendoring works (without yet modifying release workflow)

```bash
cd /path/to/vsdd-factory
npm install
npm run vendor-dispatcher

# Verify binaries landed.
find plugins/vsdd-factory/hooks/dispatcher/bin -name 'factory-dispatcher*' -type f
# Should list 5 entries.

# Spot-check one binary runs.
plugins/vsdd-factory/hooks/dispatcher/bin/$(uname | tr '[:upper:]' '[:lower:]')-$(uname -m | sed 's/x86_64/x86_64/')/factory-dispatcher --version
# Output should match v1.0.0-rc.1.

# Run the bats suite — current dispatcher (built locally) is still the one wired into hooks.json,
# so this should still pass.
cd plugins/vsdd-factory/tests && ./run-all.sh
```

If bats suite passes, the vendored binaries are coexisting with the built ones harmlessly.

### 10.7 Commit Phase 3 work

state-manager dispatches one commit (or one per logical sub-burst per TD-VSDD-053):

```bash
git add vendor-dispatcher.yaml scripts/vendor-dispatcher.mjs package.json package-lock.json
git add plugins/vsdd-factory/hooks/dispatcher/bin/   # the vendored binaries
git commit -m "feat(vendor): add factory-dispatcher vendoring infrastructure

Pins factory-dispatcher v1.0.0-rc.1 via vendor-dispatcher.yaml. Adds
scripts/vendor-dispatcher.mjs to download + SHA-verify + lay out binaries.
Does not yet remove the in-tree dispatcher build; that's Phase 4.

Refs: cycle v1.0-dispatcher-extraction-pass-1, D-DE1-004"

# Push to remote.
git push -u origin feature/dispatcher-extraction-vendoring
```

### 10.8 Exit gate

- [ ] `vendor-dispatcher.yaml` exists with valid SHA pins for all 5 platforms.
- [ ] `scripts/vendor-dispatcher.mjs` exists and is executable.
- [ ] `npm run vendor-dispatcher` succeeds; 5 binaries land at expected paths; provenance markers present.
- [ ] Vendored binary `--version` output matches `v1.0.0-rc.1`.
- [ ] Full bats suite still passes (vendored binaries coexist with built dispatcher harmlessly).
- [ ] Single atomic commit on feature branch.

---

## 11. Phase 4 — Workspace surgery

**Purpose:** remove the nine extracted crates from vsdd-factory's Cargo workspace; switch dependencies to vendored binary + crates.io (or git for RC) for the SDK; re-build all 52 WASM plugins against the new SDK.

**Entry criteria:** Phase 3 exit gate passed.

### 11.1 Remove crates from workspace

Edit `Cargo.toml` (root):

```toml
[workspace]
members = [
  # KEEP: VSDD-specific crates only.
  "crates/hook-plugins",                  # 52 WASM plugins (or individual sub-crates)
  "crates/vsdd-context-resolvers",        # VSDD-specific resolver impls (see §11.3)
  # ... any other VSDD-specific crates that stay

  # REMOVED (now consumed via vendored binary + crates.io):
  # "crates/factory-dispatcher",
  # "crates/hook-sdk",
  # "crates/hook-sdk-macros",
  # "crates/sink-file",
  # "crates/sink-otel-grpc",
  # "crates/sink-datadog",
  # "crates/sink-honeycomb",
  # "crates/sink-http",
]

[workspace.dependencies]
# Replace path deps with crates.io versions.
# During RC phase (v1.0.0-rc.X), depend via git on the tag because the crate isn't on crates.io yet.
hook-sdk = { git = "https://github.com/<owner>/factory-dispatcher", tag = "v1.0.0-rc.1" }
hook-sdk-macros = { git = "https://github.com/<owner>/factory-dispatcher", tag = "v1.0.0-rc.1" }
context-resolvers-core = { git = "https://github.com/<owner>/factory-dispatcher", tag = "v1.0.0-rc.1" }
# Sinks: only declare if used by remaining vsdd-factory crates (likely not — sinks are consumed by the dispatcher binary directly).
```

### 11.2 Remove the crate source directories

```bash
cd /path/to/vsdd-factory
git rm -r crates/factory-dispatcher
git rm -r crates/hook-sdk
git rm -r crates/hook-sdk-macros
git rm -r crates/sink-file
git rm -r crates/sink-otel-grpc
git rm -r crates/sink-datadog
git rm -r crates/sink-honeycomb
git rm -r crates/sink-http
# Note: crates/vsdd-context-resolvers stays in tree but its source CHANGES — see §11.3.
```

### 11.3 Re-establish `vsdd-context-resolvers` as VSDD-specific impls

The split (per D-DE1-007): the generic framework lives in factory-dispatcher's `context-resolvers-core`; the VSDD-specific resolver impls return here.

```bash
cd /path/to/vsdd-factory/crates/vsdd-context-resolvers

# This crate now:
# - Depends on context-resolvers-core (the trait + registry) from the shared repo.
# - Provides VSDD-specific resolver implementations (BC-INDEX, ARCH-INDEX, Linear, GitHub-PR, etc.).
# The actual files were preserved through git history; re-check `src/` contents and update Cargo.toml:
```

Update `crates/vsdd-context-resolvers/Cargo.toml`:

```toml
[package]
name = "vsdd-context-resolvers"
version = "1.0.0-rc.18"
edition = "2021"

[lib]
crate-type = ["cdylib"]   # if shipping as WASM resolvers

[dependencies]
context-resolvers-core = { workspace = true }
hook-sdk = { workspace = true }
serde = { version = "1", features = ["derive"] }
# ...
```

Update `crates/vsdd-context-resolvers/src/lib.rs` to import the trait from `context-resolvers-core` instead of the local module that previously held it.

### 11.4 Update each WASM hook plugin's dependencies

For every crate under `crates/hook-plugins/` (52 of them):

```toml
# Example: crates/hook-plugins/protect-vp/Cargo.toml
[dependencies]
# OLD: hook-sdk = { path = "../../hook-sdk" }
# NEW:
hook-sdk = { workspace = true }
hook-sdk-macros = { workspace = true }
```

Script this rather than hand-editing:

```bash
cd /path/to/vsdd-factory
find crates/hook-plugins -name Cargo.toml -exec sed -i.bak \
  -e 's|hook-sdk = { path = "[^"]*hook-sdk[^"]*" }|hook-sdk = { workspace = true }|g' \
  -e 's|hook-sdk-macros = { path = "[^"]*hook-sdk-macros[^"]*" }|hook-sdk-macros = { workspace = true }|g' \
  {} \;
find crates/hook-plugins -name 'Cargo.toml.bak' -delete
```

### 11.5 Rebuild + retest

```bash
cargo clean   # blow away stale build artifacts referencing the moved crates
cargo build --workspace --all-targets   # should now build only VSDD-specific crates + 52 plugins
cargo test --workspace --all-targets
cargo fmt --check --all
cargo clippy --workspace --all-targets -- -D warnings
```

Rebuild WASM plugins:

```bash
rustup target add wasm32-wasip1
for CRATE in crates/hook-plugins/*/; do
  NAME=$(basename "$CRATE")
  cargo build --target wasm32-wasip1 --release -p "$NAME"
  cp "target/wasm32-wasip1/release/${NAME}.wasm" "plugins/vsdd-factory/hook-plugins/${NAME}.wasm"
done

# Sanity check: 52 plugins built.
ls plugins/vsdd-factory/hook-plugins/*.wasm | wc -l
```

### 11.6 Update release workflow

Edit `.github/workflows/release.yml`. Remove the in-tree dispatcher cross-compile job; add a vendoring step.

OLD (likely something like):

```yaml
- run: cargo build --release --target ${{ matrix.target.triple }} -p factory-dispatcher
- run: cp target/${{ matrix.target.triple }}/release/factory-dispatcher* plugins/vsdd-factory/hooks/dispatcher/bin/${{ matrix.target.platform }}/
```

NEW:

```yaml
- uses: actions/setup-node@v4
  with: { node-version: 20 }
- run: npm ci
- run: npm run vendor-dispatcher
- name: Verify vendored binaries
  run: |
    for PLATFORM in darwin-arm64 darwin-x86_64 linux-x86_64-gnu linux-x86_64-musl windows-x86_64; do
      BIN_NAME="factory-dispatcher"
      [[ "$PLATFORM" == "windows-x86_64" ]] && BIN_NAME="factory-dispatcher.exe"
      test -f "plugins/vsdd-factory/hooks/dispatcher/bin/$PLATFORM/$BIN_NAME"
    done
```

Also: remove the matrix-build job entirely if it only built the dispatcher.

### 11.7 Run full validation

```bash
cd /path/to/vsdd-factory

# Cargo workspace clean.
cargo build --workspace --all-targets
cargo test --workspace --all-targets
cargo fmt --check --all
cargo clippy --workspace --all-targets -- -D warnings

# Full bats suite.
cd plugins/vsdd-factory/tests
./run-all.sh

# Capture the result count vs baseline.
grep -c '^ok' last-run.log
grep -c '^not ok' last-run.log
diff -u ../../../.baseline-artifacts/bats-baseline.log last-run.log | head -50
```

Expected: 534 ok, 0 not ok. Any regression must be diagnosed before exit.

### 11.8 Commit Phase 4 work

This phase has multiple logical bursts per TD-VSDD-053. State-manager dispatches each as a single commit:

- Burst 1: workspace removal + Cargo.toml updates
- Burst 2: vsdd-context-resolvers re-establishment
- Burst 3: WASM plugin Cargo.toml mass update
- Burst 4: rebuilt WASM artifacts
- Burst 5: release workflow modification

Each commit follows conventional format:

```
git commit -m "refactor(workspace): remove extracted crates; depend on factory-dispatcher v1.0.0-rc.1

Removes 8 crates (factory-dispatcher, hook-sdk, hook-sdk-macros, sink-{file,otel-grpc,
datadog,honeycomb,http}) from workspace; workspace deps now reference the shared
factory-dispatcher repo via git tag during the RC phase.

Refs: cycle v1.0-dispatcher-extraction-pass-1, D-DE1-001..007"
```

### 11.9 Exit gate

- [ ] Cargo.toml workspace members reduced to VSDD-specific crates only.
- [ ] 8 crate source directories removed (factory-dispatcher, hook-sdk, hook-sdk-macros, 5 sinks).
- [ ] `crates/vsdd-context-resolvers` rewritten to depend on context-resolvers-core from shared repo.
- [ ] All 52 WASM hook plugins compile against the shared `hook-sdk`.
- [ ] 52 `.wasm` files in `plugins/vsdd-factory/hook-plugins/`.
- [ ] `cargo build --workspace`, `cargo test --workspace`, `cargo fmt --check`, `cargo clippy -- -D warnings` all clean.
- [ ] Full bats suite: 534 ok, 0 not ok.
- [ ] Release workflow no longer attempts in-tree dispatcher build.

---

## 12. Phase 5 — Validate parity

**Purpose:** prove the vendored v1.0.0-rc.1 dispatcher behaves identically to the baseline in-tree dispatcher. This is the critical gate before operator promotion.

**Entry criteria:** Phase 4 exit gate passed.

### 12.1 Behavioral parity test corpus

Construct a corpus of hook-event payloads spanning every event type and every plugin. Run both dispatchers (baseline and vendored) against the corpus; verdicts must match.

```bash
cd /path/to/vsdd-factory
mkdir -p .factory/parity-test

# Generate corpus from real telemetry: pull historical hook events from the last 7 days of
# .factory/logs/dispatcher-internal-*.jsonl. Each event becomes one test case.
for DAY in $(seq 0 6); do
  DATE=$(date -d "$DAY days ago" +%Y-%m-%d 2>/dev/null || date -v "-${DAY}d" +%Y-%m-%d)
  LOG=".factory/logs/dispatcher-internal-${DATE}.jsonl"
  [[ -f "$LOG" ]] || continue
  jq -c '. | select(.event == "hook_dispatch")' "$LOG" >> .factory/parity-test/corpus.jsonl
done
wc -l .factory/parity-test/corpus.jsonl   # expect 100s to 1000s of events

# Baseline binary.
BASELINE=".baseline-artifacts/factory-dispatcher-baseline"

# Vendored binary (per platform; pick the current platform).
case "$(uname)" in
  Darwin) PLATFORM=darwin-$(uname -m | sed 's/arm64/arm64/;s/x86_64/x86_64/') ;;
  Linux)  PLATFORM=linux-x86_64-gnu ;;
esac
VENDORED="plugins/vsdd-factory/hooks/dispatcher/bin/${PLATFORM}/factory-dispatcher"

# Drive both dispatchers through the corpus in headless mode.
node scripts/parity-driver.mjs --baseline "$BASELINE" --vendored "$VENDORED" --corpus .factory/parity-test/corpus.jsonl > .factory/parity-test/results.json
jq '.diff_count' .factory/parity-test/results.json   # MUST be 0
```

`scripts/parity-driver.mjs` (sketch — write this script in Phase 4 prep):

```javascript
// For each event in corpus.jsonl:
//   1. Invoke baseline dispatcher with the event payload on stdin.
//   2. Invoke vendored dispatcher with the same payload.
//   3. Compare verdict (status, message, exit_code).
//   4. Diff any mismatches.
// Output: { total, matches, diff_count, diffs: [{trace, baseline, vendored}] }
```

### 12.2 WASM plugin load test

```bash
# Verify every plugin in hooks-registry.toml loads under the vendored dispatcher.
VENDORED="plugins/vsdd-factory/hooks/dispatcher/bin/${PLATFORM}/factory-dispatcher"
"$VENDORED" --validate-registry plugins/vsdd-factory/hooks-registry.toml
# Exit 0 = all plugins load + ABI-compatible.
```

### 12.3 Operator smoke test (fresh install)

Simulate an end-user install in a clean home directory. This catches binary-path issues, missing permissions, marketplace tarball corruption.

```bash
# Create isolated test env.
TEST_HOME=$(mktemp -d)
HOME="$TEST_HOME" claude /plugin marketplace add drbothen/claude-mp
HOME="$TEST_HOME" claude /plugin install vsdd-factory@claude-mp  # installs the current marketplace version

# After install, override the cache with the local in-development tarball.
# (In practice: build the tarball from the current branch, place at cache path, run hook.)
mkdir -p plugin-tarball
# ... build tarball steps per existing vsdd-factory release procedure
cp -r plugin-tarball/* "$TEST_HOME/.claude/plugins/cache/claude-mp/vsdd-factory/v1.0.0-rc.X/"

# Verify dispatcher resolves.
DISPATCHER="$TEST_HOME/.claude/plugins/cache/claude-mp/vsdd-factory/v1.0.0-rc.X/hooks/dispatcher/bin/${PLATFORM}/factory-dispatcher"
test -x "$DISPATCHER"
"$DISPATCHER" --version
"$DISPATCHER" --validate-registry "$TEST_HOME/.claude/plugins/cache/claude-mp/vsdd-factory/v1.0.0-rc.X/hooks-registry.toml"

# Fire a synthetic hook event end-to-end.
echo '{"event":"PreToolUse","tool_name":"Write","tool_input":{"file_path":"/tmp/test.txt","content":"hello"}}' | "$DISPATCHER"

# Clean up.
rm -rf "$TEST_HOME"
```

### 12.4 F5 cycle resume dry-run

Before promotion, verify the F5 convergence cycle (paused in Phase 1) still functions on the vendored base.

```bash
# Switch to develop, merge the migration branch as a draft PR (do NOT merge yet).
cd /path/to/vsdd-factory
git checkout develop
gh pr create --base develop --head feature/dispatcher-extraction-vendoring --draft --title "feat(workspace): migrate to vendored factory-dispatcher v1.0.0-rc.1" --body-file .factory/cycles/v1.0-dispatcher-extraction-pass-1/pr-body.md

# Run the cycle's adversary cascade against this PR (per existing F5 protocol).
# This catches anything the bats suite missed.
```

### 12.5 Soak period (recommended: 5–7 days)

Run the migration branch in real use for a soak period before promoting:

- The vsdd-factory team uses the migration branch for normal `.factory/` work.
- F5 cycle resumes against this branch (not merged to main yet).
- Any hook-chain anomaly (false-positive block, false-negative pass, observability sink dropping events) is investigated.

If the soak surfaces a defect: fix in scope, re-run §12.1–§12.4. If the defect requires a dispatcher change: factory-dispatcher releases v1.0.0-rc.2; update vendor-dispatcher.yaml; restart soak.

### 12.6 Exit gate

- [ ] Parity test diff_count = 0 across full corpus.
- [ ] All 52 WASM plugins load under vendored dispatcher (--validate-registry passes).
- [ ] Operator fresh-install smoke test passes (dispatcher present, executable, ABI-compatible).
- [ ] F5 cycle dry-run on migration branch passes (no new findings introduced by migration itself).
- [ ] Soak period (5–7 days) clean of unexpected hook-chain behavior.
- [ ] All findings during soak triaged and resolved.

---

## 13. Phase 6 — Release & promote

**Purpose:** tag factory-dispatcher v1.0.0 final, update vsdd-factory's pin, cut the vsdd-factory release that operators install.

**Entry criteria:** Phase 5 exit gate passed.

### 13.1 Promote factory-dispatcher to v1.0.0 final

```bash
cd ~/Dev/factory-dispatcher
git checkout main
git pull --ff-only

# Tag v1.0.0 from the same commit as v1.0.0-rc.1 (if no fixes were needed during soak)
# OR from the latest commit (if rc.2 / rc.3 were cut during soak).
git tag -a v1.0.0 -m "v1.0.0 — first stable release. Host ABI v1.x is stable per semver-commitment.md."
git push origin v1.0.0
```

The release workflow fires:
- 5 platform binaries on GH Releases.
- crates.io publish (the gate `if: !contains(github.ref_name, 'rc')` allows it).
- `hook-sdk@1.0.0`, `hook-sdk-macros@1.0.0`, `context-resolvers-core@1.0.0`, sinks @ 1.0.0 — all on crates.io.

### 13.2 Update vsdd-factory pin

```bash
cd /path/to/vsdd-factory
git checkout feature/dispatcher-extraction-vendoring

# Compute new SHAs from v1.0.0 release artifacts.
mkdir -p /tmp/v1-shas && cd /tmp/v1-shas
gh release download v1.0.0 -R <owner>/factory-dispatcher
for FILE in factory-dispatcher-v1.0.0-*; do
  echo "${FILE}: $(sha256sum "$FILE" | awk '{print $1}')"
done
```

Edit `vendor-dispatcher.yaml`:

```yaml
dispatcher:
  repo: <owner>/factory-dispatcher
  version: v1.0.0     # ← updated
  artifacts:
    darwin-arm64:
      url: https://github.com/<owner>/factory-dispatcher/releases/download/v1.0.0/factory-dispatcher-v1.0.0-darwin-arm64
      sha256: <new SHA>
    # ... etc for all 5 platforms
```

Edit root `Cargo.toml` — switch SDK deps from git tag to crates.io versions:

```toml
[workspace.dependencies]
hook-sdk = "1.0"
hook-sdk-macros = "1.0"
context-resolvers-core = "1.0"
```

Re-vendor + re-build + re-test:

```bash
npm run vendor-dispatcher
cargo clean
cargo build --workspace --all-targets
cargo test --workspace --all-targets
# Rebuild all 52 WASM plugins.
for CRATE in crates/hook-plugins/*/; do
  NAME=$(basename "$CRATE")
  cargo build --target wasm32-wasip1 --release -p "$NAME"
  cp "target/wasm32-wasip1/release/${NAME}.wasm" "plugins/vsdd-factory/hook-plugins/${NAME}.wasm"
done
cd plugins/vsdd-factory/tests && ./run-all.sh   # 534 ok expected
```

### 13.3 Merge to develop

```bash
cd /path/to/vsdd-factory
git checkout feature/dispatcher-extraction-vendoring
git commit -am "chore(vendor): bump factory-dispatcher pin to v1.0.0 final; switch SDK deps from git to crates.io"
git push

# Merge the PR (already open as draft from §12.4). Mark ready for review; merge per vsdd-factory's
# normal develop-merge process (squash).
gh pr ready <PR-number>
# Reviews per vsdd-factory's existing PR cycle (pr-manager 9-step protocol).
gh pr merge <PR-number> --squash
```

### 13.4 Cut release branch + main merge

Per vsdd-factory's RELEASING.md (canonical):

```bash
cd /path/to/vsdd-factory
git checkout develop
git pull --ff-only

# Determine new version. If current is v1.0.0-rc.18, the vendored migration is significant
# enough to warrant rc.19 (or even drop the rc and release v1.0.0 if other stability signals are good).
# This is a human decision; default to rc.19.
NEW_VERSION="v1.0.0-rc.19"

# Cut release branch per TD #69.
git checkout -b "release/${NEW_VERSION}"
# Update plugins/vsdd-factory/.claude-plugin/plugin.json version field.
jq --arg v "${NEW_VERSION#v}" '.version = $v' plugins/vsdd-factory/.claude-plugin/plugin.json > /tmp/pj && mv /tmp/pj plugins/vsdd-factory/.claude-plugin/plugin.json

# Update CHANGELOG.md per §19.

git commit -am "release: ${NEW_VERSION}"
git push -u origin "release/${NEW_VERSION}"

# Open release PR targeting main (per TD #69 guardrail).
gh pr create --base main --head "release/${NEW_VERSION}" --title "release: ${NEW_VERSION}" --body "First vsdd-factory release on vendored factory-dispatcher. See CHANGELOG."

# Merge with --merge (NOT --squash) per CLAUDE.md release rule.
gh pr merge <PR-number> --merge

# Tag at main's new tip.
git checkout main
git pull --ff-only
git tag -a "${NEW_VERSION}" -m "${NEW_VERSION} — first release on vendored factory-dispatcher v1.0.0"
git push origin "${NEW_VERSION}"
```

### 13.5 Marketplace publish

vsdd-factory's existing release pipeline publishes the tarball to `drbothen/claude-mp`. The pipeline auto-fires on tag push. Verify:

```bash
gh run watch  # watch the release.yml workflow
# After success:
gh release view "${NEW_VERSION}" -R drbothen/vsdd-factory
```

Operators receive the new version on `/plugin update vsdd-factory@claude-mp`.

### 13.6 Resume F5 cycle

```bash
gh pr comment 124 --body "✅ Dispatcher extraction promoted in vsdd-factory ${NEW_VERSION}. F5 cycle resumes on new base."
# Rebase PR #124 onto new main.
git checkout <pr-124-branch>
git rebase main
git push --force-with-lease   # requires human approval per vsdd-factory git rules
```

### 13.7 Exit gate

- [ ] `factory-dispatcher` v1.0.0 tagged; binaries on GH Releases; crates published to crates.io.
- [ ] `vsdd-factory` `vendor-dispatcher.yaml` pins v1.0.0 final with verified SHAs.
- [ ] `vsdd-factory` Cargo workspace deps reference crates.io (not git).
- [ ] vsdd-factory release branch `release/v1.0.0-rc.19` (or chosen version) created + merged to main.
- [ ] vsdd-factory tag pushed; release workflow ran green.
- [ ] Marketplace tarball published; operator install path verified.
- [ ] F5 cycle PR #124 rebased onto new main; cycle resumed.

---

## 14. Phase 7 — Cleanup & docs

**Purpose:** remove transitional artifacts, update documentation, write retrospective.

**Entry criteria:** Phase 6 exit gate passed; first 48h post-promotion produced no incident reports.

### 14.1 Remove transitional artifacts

```bash
cd /path/to/vsdd-factory

# Remove the baseline artifacts (they served their purpose in Phase 1/5).
git rm -r .baseline-artifacts/
git rm .factory/parity-test/   # corpus + driver served Phase 5; archive in cycle dir instead

# Move parity-test artifacts into the cycle's retrospective folder.
mkdir -p .factory/cycles/v1.0-dispatcher-extraction-pass-1/parity-evidence/
# (Recover from git history if already rm'd, or copy before rm.)

git commit -m "chore(cleanup): remove transitional baseline artifacts; archive parity evidence to cycle dir

Refs: cycle v1.0-dispatcher-extraction-pass-1 retrospective"
```

### 14.2 Documentation updates

The following docs in vsdd-factory need updates:

| File | Update |
|---|---|
| `README.md` | "Build the dispatcher" section → "Vendor the dispatcher". Add link to factory-dispatcher repo. |
| `CLAUDE.md` | Architectural authority sections referencing `crates/factory-dispatcher` paths → reference shared repo. |
| `plugins/vsdd-factory/docs/FACTORY.md` | Hook layer description updated. |
| `docs/guide/authoring-hooks.md` | Point at shared repo's authoring-hooks.md. |
| `docs/guide/hooks-reference.md` | Update binary-source description (vendored, not built). |
| `docs/guide/observability.md` | Sinks now come from shared repo. |
| `docs/guide/observability-sinks.md` | Point at shared repo's observability-sinks.md. |
| `docs/guide/migrating-from-0.79.md` | Add note about the dispatcher source-of-truth move. |
| `docs/guide/semver-commitment.md` | Reference the shared repo's host-ABI stability. |
| `docs/guide/configuration.md` | `vendor-dispatcher.yaml` schema documented. |
| `CONTRIBUTING.md` | "How to modify dispatcher source" → "File issue on factory-dispatcher repo". |

state-manager dispatches per existing single-commit-per-burst discipline.

### 14.3 Update agent routing table

In vsdd-factory's `CLAUDE.md`, the agent routing table currently includes work that touched the dispatcher source. Update:

- Old: "Dispatcher source bug → architect + implementer (in vsdd-factory)"
- New: "Dispatcher source bug → file issue on `factory-dispatcher` repo; vsdd-factory side, bump pin after fix releases"

### 14.4 Retrospective

Write `.factory/cycles/v1.0-dispatcher-extraction-pass-1/retrospective.md`:

```markdown
# Cycle Retrospective — v1.0-dispatcher-extraction-pass-1

## What worked
- Subtree split preserved per-crate history.
- Phase 5 parity test caught <N> behavioral diffs that the bats suite missed.
- Soak period prevented <list>.

## What didn't
- <issues encountered>
- <time overruns>

## Lessons (codified in lessons.md as L-DE1-NNN)
- ...

## Numbers
- Total cycle duration: <X> days
- Phase 1: <X> days
- Phase 2: <X> days
- Phase 3-4: <X> days
- Phase 5 soak: <X> days
- Phase 6-7: <X> days
- Bats tests at exit: 534 ok / 0 not ok (same as baseline)
- WASM plugins migrated: 52
- Parity diff_count: 0
- Operator install regressions reported: <N> (target: 0)

## Follow-up TDs
- TD-DE1-001: <any deferred work, with attached future story>
```

### 14.5 Close the cycle

state-manager dispatches the cycle-close commit, advancing STATE.md:

- Frontmatter: `current_cycle` updated to next.
- Concurrent Cycles tail per D-433(e)+D-439(c).
- Decisions Log appended with closure row.

### 14.6 Exit gate

- [ ] All documentation in §14.2 updated.
- [ ] Agent routing table reflects new dispatcher source location.
- [ ] Retrospective written; lessons codified in cycle's lessons.md.
- [ ] STATE.md updated; cycle closed; next cycle current.
- [ ] No operator-reported regressions in 7 days post-promotion.

---

## 15. Rollback procedures

Rollback is phase-specific. The earlier the failure, the cheaper the rollback.

### Rollback from Phase 1 (decision lock)

Trivial. No code changed. Just abandon the cycle:

```bash
# Discard the cycle's manifest commits if they were made.
git revert <commits>
# Or: leave them in place; mark cycle as abandoned in retrospective.
```

### Rollback from Phase 2 (shared repo created, no consumer changes)

Trivial. Delete or archive the shared repo:

```bash
gh repo delete <owner>/factory-dispatcher --yes
# Or: archive (preserves history but prevents activity):
gh repo edit <owner>/factory-dispatcher --archived
```

vsdd-factory untouched. No operator impact.

### Rollback from Phase 3 (vendoring config added)

Revert the migration branch; do not merge. Operators unaffected because nothing was released.

```bash
cd /path/to/vsdd-factory
git checkout develop
git branch -D feature/dispatcher-extraction-vendoring
# (Or push :feature/dispatcher-extraction-vendoring to delete remote branch.)
```

### Rollback from Phase 4 (workspace surgery; not yet merged)

Same as Phase 3 rollback. Branch is unmerged; abandoning it returns to baseline.

### Rollback from Phase 5 (parity gate failed)

Two paths:

**Path A — Defect in vendored dispatcher.** Fix in shared repo, release v1.0.0-rc.2, bump pin, retry §12.

**Path B — Defect in migration approach.** Revert migration branch; investigate; re-plan.

Either way, vsdd-factory's main branch is unaffected.

### Rollback from Phase 6 (post-merge, post-tag)

Highest cost. The migration is operator-visible.

```bash
# Cut a hotfix release reverting to the prior dispatcher source.
cd /path/to/vsdd-factory

# Branch off the tag immediately before migration.
git checkout v1.0.0-rc.18   # the baseline tag from §8.2
git checkout -b release/v1.0.0-rc.20-hotfix-revert-vendor

# Bump version, update plugin.json + CHANGELOG.
# Tag, release, marketplace publish.
# Operators receive the revert on next `/plugin update`.
```

**During the rollback window**: keep the factory-dispatcher repo alive (don't delete). It's not the source of the problem; the integration is. Next attempt re-uses the existing v1.0.0 release.

### Rollback decision tree

```
Phase failure
  ├─ Pre-merge (Phase 1-4): revert local branch; minimal cost
  ├─ Pre-tag (Phase 5):     fix in scope OR revert branch; no operator impact
  └─ Post-tag (Phase 6+):   cut hotfix release reverting to pre-vendor baseline
                              + RCA + re-plan + retry
```

---

## 16. Decision log seed (D-NNN entries this cycle creates)

Pre-fill `.factory/cycles/v1.0-dispatcher-extraction-pass-1/decision-log.md` with these entries. State-manager finalizes dates and IDs during dispatch.

```
| ID         | Date       | Decision |
|------------|------------|----------|
| D-DE1-001  | <Phase 1>  | Shared repo name: `factory-dispatcher`. Owner: <user>. License: MIT. |
| D-DE1-002  | <Phase 1>  | Host ABI v1.0.0 frozen at extraction baseline. Breaking changes require v2. |
| D-DE1-003  | <Phase 1>  | Sink subset for v1.0.0: all five (file, otel-grpc, datadog, honeycomb, http). |
| D-DE1-004  | <Phase 1>  | F5 cycle paused for migration duration. PR #124 marked do-not-merge. |
| D-DE1-005  | <Phase 1>  | Target factory-dispatcher v1.0.0 final release: <date>. |
| D-DE1-006  | <Phase 1>  | Operator comm: CHANGELOG entry + GitHub Discussion at promotion. |
| D-DE1-007  | <Phase 1>  | vsdd-context-resolvers split: framework → context-resolvers-core (shared); impls stay. |
| D-DE1-008  | <Phase 2>  | git subtree split chosen for history preservation over `git filter-repo`. |
| D-DE1-009  | <Phase 2>  | factory-dispatcher CI gates: build, test, fmt, clippy across 3 OS runners. |
| D-DE1-010  | <Phase 2>  | crates.io publish only on full releases, not RCs. |
| D-DE1-011  | <Phase 2>  | RC consumers depend on shared repo via `git = ...` + tag; full release uses crates.io. |
| D-DE1-012  | <Phase 3>  | vendor-dispatcher.yaml format: top-level `dispatcher:` key with `version`, `repo`, `artifacts.<platform>.{url,sha256}`. |
| D-DE1-013  | <Phase 3>  | SHA256 verification fails closed (no fallback). vendor-dispatcher.mjs is idempotent. |
| D-DE1-014  | <Phase 4>  | Bash hooks (`plugins/vsdd-factory/hooks/*.sh`) stay in place as fallback; E-10 migration continues independently. |
| D-DE1-015  | <Phase 5>  | Parity verification: behavioral equivalence on real-telemetry corpus. Byte-equivalence not required (would constrain future dispatcher build flags). |
| D-DE1-016  | <Phase 5>  | Soak period: 5–7 days minimum on migration branch before promotion. |
| D-DE1-017  | <Phase 6>  | First vendored vsdd-factory release: v1.0.0-rc.19 (continues rc sequence from rc.18 baseline). |
| D-DE1-018  | <Phase 7>  | Future dispatcher version bumps in vsdd-factory: 2-line vendor-dispatcher.yaml change + version pin in Cargo.toml + re-release. |
```

---

## 17. Per-phase checkpoint commands (canonical verification)

Run these verbatim at each phase's exit gate. All must succeed.

### Phase 1
```bash
git tag -l 'baseline/pre-dispatcher-extraction'
ls .baseline-artifacts/factory-dispatcher-baseline
test -f .baseline-artifacts/bats-baseline.log
grep -c '^ok' .baseline-artifacts/bats-baseline.log   # 534
test -d .factory/cycles/v1.0-dispatcher-extraction-pass-1
test -f .factory/cycles/v1.0-dispatcher-extraction-pass-1/decision-log.md
```

### Phase 2 (in factory-dispatcher repo)
```bash
cargo build --workspace --all-targets
cargo test --workspace --all-targets
cargo fmt --check --all
cargo clippy --workspace --all-targets -- -D warnings
rustup target add wasm32-wasip1
cargo build --target wasm32-wasip1 --release -p echo-hook
test -f target/wasm32-wasip1/release/echo_hook.wasm
gh release view v1.0.0-rc.1 --json assets --jq '.assets | length'   # 5 (+ SHA256SUMS = 6)
```

### Phase 3 (in vsdd-factory)
```bash
test -f vendor-dispatcher.yaml
test -x scripts/vendor-dispatcher.mjs
npm run vendor-dispatcher
find plugins/vsdd-factory/hooks/dispatcher/bin -name 'factory-dispatcher*' -type f | wc -l   # 5
# Spot-check binary runs.
PLATFORM=$(uname | tr A-Z a-z)-$(uname -m | sed 's/aarch64/arm64/')
plugins/vsdd-factory/hooks/dispatcher/bin/${PLATFORM}/factory-dispatcher --version
cd plugins/vsdd-factory/tests && ./run-all.sh
```

### Phase 4
```bash
cargo build --workspace --all-targets
cargo test --workspace --all-targets
cargo fmt --check --all
cargo clippy --workspace --all-targets -- -D warnings
# Verify removed crates are gone.
for C in factory-dispatcher hook-sdk hook-sdk-macros sink-file sink-otel-grpc sink-datadog sink-honeycomb sink-http; do
  test ! -d "crates/$C" || (echo "ERROR: crates/$C still present"; exit 1)
done
# Verify 52 WASM plugins built.
ls plugins/vsdd-factory/hook-plugins/*.wasm | wc -l   # 52
cd plugins/vsdd-factory/tests && ./run-all.sh   # 534 ok
```

### Phase 5
```bash
node scripts/parity-driver.mjs --baseline .baseline-artifacts/factory-dispatcher-baseline \
  --vendored plugins/vsdd-factory/hooks/dispatcher/bin/${PLATFORM}/factory-dispatcher \
  --corpus .factory/parity-test/corpus.jsonl
jq '.diff_count' .factory/parity-test/results.json   # 0
plugins/vsdd-factory/hooks/dispatcher/bin/${PLATFORM}/factory-dispatcher --validate-registry plugins/vsdd-factory/hooks-registry.toml
# Operator smoke test (manual; verify in clean home dir).
```

### Phase 6
```bash
gh release view v1.0.0 -R <owner>/factory-dispatcher
cargo search hook-sdk --limit 1 | grep '"1.0.0"'
git -C /path/to/vsdd-factory tag -l | grep "v1.0.0-rc.19"   # or chosen version
gh release view v1.0.0-rc.19 -R drbothen/vsdd-factory   # marketplace tarball
```

### Phase 7
```bash
# All doc updates landed.
grep -r 'crates/factory-dispatcher' README.md CLAUDE.md plugins/vsdd-factory/docs/ 2>/dev/null && echo "ERROR: stale path refs" || echo "OK"
# Cycle closed in STATE.md.
grep -q 'v1.0-dispatcher-extraction-pass-1' .factory/STATE.md
grep -q 'CLOSED' .factory/cycles/v1.0-dispatcher-extraction-pass-1/cycle-manifest.md
```

---

## 18. Test strategy

Three layers of test coverage, in order of catch-rate.

### 18.1 Unit + workspace tests (existing)

`cargo test --workspace --all-targets` in both repos. Must pass at every phase boundary.

In factory-dispatcher: tests the dispatcher logic, SDK API surface, sink emitters, resolver framework.
In vsdd-factory: tests the WASM hook plugin business logic (each hook's verdict for canonical inputs).

### 18.2 Bats integration suite (existing)

`plugins/vsdd-factory/tests/run-all.sh` — 534 tests across 17 suites. Tests the operator-level integration: hooks.json wiring, dispatcher invocation, hook plugin loading, observability emission.

**Must pass with same 534/534 count after migration.** Any regression is a P0 blocker.

### 18.3 Parity tests (new for this migration)

Built in Phase 4 prep, executed in Phase 5.

**Purpose:** prove that the vendored dispatcher produces identical verdicts to the baseline dispatcher on a real-world input corpus.

**Corpus source:** real telemetry from `.factory/logs/dispatcher-internal-*.jsonl` (7 days). Each `hook_dispatch` event becomes one test case.

**Test:** drive both dispatchers (baseline binary + vendored binary) through the corpus; compare verdicts; diff_count must be 0.

**Script:** `scripts/parity-driver.mjs` (sketched in §12.1). Output: JSON report with diffs.

**Why corpus from telemetry, not synthetic:** synthetic corpora miss real-world payload variations. The dispatcher has been running in production for vsdd-factory's own discipline cycle for weeks — that's the most realistic corpus available.

### 18.4 Operator smoke test (new for this migration)

`§12.3` — fresh install in clean home directory; verify dispatcher resolves at expected path; verify it loads the registry; fire a synthetic event end-to-end.

### 18.5 Soak (continuous, 5–7 days)

Real-use validation. vsdd-factory team runs normal `.factory/` work against the migration branch. Anomalies in hook chain (false positives, false negatives, dropped observability events) get filed and triaged.

---

## 19. Communication plan

### 19.1 CHANGELOG entry (vsdd-factory)

```markdown
## [1.0.0-rc.19] — <date>

### Changed
- **BREAKING (internal): dispatcher source moved to shared `factory-dispatcher` repo.**
  - Operators: no action required. Binary path, install command, behavior unchanged.
  - Plugin authors / contributors: dispatcher source bugs are now filed on the
    `factory-dispatcher` repo (https://github.com/<owner>/factory-dispatcher).
  - vsdd-factory now consumes `hook-sdk` from crates.io and vendors the dispatcher
    binary at release time. See `vendor-dispatcher.yaml` and `docs/guide/configuration.md`.
- Cargo workspace shrunk: 9 crates removed (factory-dispatcher, hook-sdk, hook-sdk-macros,
  sink-{file,otel-grpc,datadog,honeycomb,http}). vsdd-context-resolvers split — generic
  framework moved to context-resolvers-core in shared repo; VSDD-specific resolver impls remain.
- CI duration reduced ~30–50% per PR (no longer rebuilding the dispatcher).

### Internal
- Cycle `v1.0-dispatcher-extraction-pass-1` closed. D-DE1-001..018 codified.
- 52 WASM hook plugins recompiled against published hook-sdk@1.0.0. Behavior unchanged.
- All 534 bats tests pass on the migrated workspace.
- Parity test diff_count = 0 between baseline and vendored dispatcher.

### Migration notes for plugin authors
- If you maintain a hook plugin: depend on `hook-sdk = "1"` from crates.io.
- If you maintain a context resolver: depend on `context-resolvers-core = "1"` from crates.io
  for the framework; keep VSDD-specific impls in vsdd-factory.
- Host ABI v1.x is stable. Breaking changes require v2 SDK and v2 dispatcher.

### Links
- Shared repo: https://github.com/<owner>/factory-dispatcher
- Semver commitment: https://github.com/<owner>/factory-dispatcher/blob/main/docs/semver-commitment.md
- Consumer integration: https://github.com/<owner>/factory-dispatcher/blob/main/docs/consumer-integration.md
```

### 19.2 GitHub Discussion (vsdd-factory)

Post a discussion at promotion (Phase 6) summarizing for operators:

- TL;DR: nothing changes for you.
- What moved and why.
- How to debug if anything looks wrong post-upgrade.
- Where to file dispatcher-related issues (the shared repo) vs vsdd-factory issues (this repo).

### 19.3 factory-dispatcher release notes

Generated by `gh release create --generate-notes`. Augment with:

- "First stable release. Extracted from vsdd-factory v1.0.0-rc.18 baseline. Host ABI v1.x stable per semver-commitment.md."
- Link to docs/consumer-integration.md for new consumers.

---

## 20. Open questions to lock before Phase 1

These are listed in §6 prerequisites; replicated here for visibility:

1. **Shared repo name** (default: `factory-dispatcher`).
2. **Shared repo owner / stewardship** (default: same as vsdd-factory).
3. **Sink subset for v1.0.0** (default: all five).
4. **F5 cycle disposition** (default: pause).
5. **Target factory-dispatcher v1.0.0 date** (default: 2 weeks after Phase 2 begins).
6. **Operator communication channel** (default: CHANGELOG + GitHub Discussion at promotion).
7. **vsdd-factory version number for first vendored release** (default: v1.0.0-rc.19 — continues sequence).
8. **Parity gate stringency** (default: behavioral equivalence on telemetry corpus; not byte-equivalence).
9. **Soak duration** (default: 5–7 days; longer if PR #124 reveals dispatcher-sensitive findings).

---

## 21. Starter prompt for the next Claude session

When ready to execute this plan in a fresh session:

> Read `/Users/jmagady/Dev/scrap/vsdd-dispatcher-extraction-plan.md` end to end. The file is self-sufficient — every command, file content, gate, checkpoint, and rollback procedure is embedded. Execute §6 (prerequisites) first. If all pass and the human has locked the §20 open questions, execute §8 → §14 in order. Do not skip phases. Use §17 (per-phase checkpoint commands) as the canonical verification at each exit gate. If any gate fails, halt and consult §15 (rollback). Before promoting (Phase 6), surface the §16 decision-log entries to me to confirm final dates and version numbers.

---

## 22. Change log

- **2026-05-14, v1.** Initial migration plan. Standalone — embeds all commands, file contents, gates, and rollback procedures required to extract `factory-dispatcher`, `hook-sdk`, `hook-sdk-macros`, `context-resolvers-core`, and 5 sink crates from vsdd-factory into a shared repo, then migrate vsdd-factory's release pipeline to consume them via vendored binaries (binaries from GH Releases) and published crates (from crates.io). Preserves all 534 bats tests, 52 WASM hook plugins, and operator-facing behavior. Covers 7 phases: decision lock → shared-repo standup → consumer-side vendoring → workspace surgery → parity validation → release & promote → cleanup & docs. Includes per-phase rollback procedures and a 7-day soak gate before promotion.
