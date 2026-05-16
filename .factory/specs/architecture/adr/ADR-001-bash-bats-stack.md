---
document_type: adr
id: ADR-001
title: "Bash + bats + markdown stack for v0.x (no Rust, no Node test framework)"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-001: Bash + bats + markdown stack for v0.x

## Context

brain-factory packages an LLM-maintained second-brain methodology as a Claude Code plugin. The implementation choices for v0.x concern the toolchain for hook scripts, test suites, and utilities. Two competing forces apply:

1. **Speed to first useful plugin.** Every week spent waiting for shared infrastructure (Rust WASM toolchain, factory-dispatcher extraction) is a week not validating the methodology with real ingest and writing sessions.
2. **Production-grade correctness.** v0.x is not a prototype — it is the production enforcement layer for a single-author dogfood phase leading to 3–5 pilot users.

The phased-build-plan.md documents this trade explicitly: "bash hooks ran in production for months before the WASM port shipped" (vsdd-factory precedent). The plan establishes that bash hooks deliver ~80% of enforcement value with ~10% of platform complexity.

## Decision

v0.x uses:
- **Hook scripts:** bash (`#!/usr/bin/env bash` + `set -euo pipefail`), no Rust, no compiled binaries
- **Test suites:** bats-core, no JavaScript test framework (no remark, no markdownlint-cli2, no ajv)
- **Node 20+ utilities:** Defuddle CLI (`scripts/defuddle-fetch.mjs`), headless skill runner (`scripts/run-skill.mjs`), quarantine corpus (`scripts/quarantine.mjs`) — narrow, opt-in utilities not in the test path
- **Lint:** shellcheck (`-S style -e SC1090` baseline) + shfmt (`-i 2`)
- **Markdown validation:** enforced by hooks using `yq eval` (frontmatter), `awk` (section parsing), `jq` (JSON payloads), `sha256sum` (immutability) — not by bats directly

This is a locked decision per SL-1 (user-selected "Embrace Node 20+ as required") and the phased-build-plan.md Phase 1 architecture. WASM hooks via factory-dispatcher are a v1.0 concern (ADR-007).

## Consequences

**Positive:**
- Time to first plugin install: ~4 weeks (vs 12+ weeks blocked on Rust/dispatcher extraction)
- No Rust toolchain dependency for contributors in v0.x
- Portable to macOS + Linux (Git Bash + WSL2 partial per NFR-014)
- bats inner loop is < 1 second per targeted test — fast TDD cycle

**Negative:**
- Hook chain ceiling: ~10–15 hooks before per-event bash startup introduces measurable overhead. Brain-factory v0.x ships 13 hooks — within budget; v1.0 migration is the capacity release valve.
- Non-deterministic on Windows-native (no bash in PATH without Git Bash / WSL2)
- shellcheck and shfmt must be installed in CI and on dev machines (`make setup`)

**Neutral:**
- Node 20+ utilities are narrow-scope (fetch + quarantine + headless runner). They do not touch the hook test path.

## Alternatives Considered

1. **Rust + WASM hooks from day one.** Rejected: blocks development on upstream factory-dispatcher extraction (vsdd-dispatcher-extraction-plan.md dependency). Adds Rust toolchain to every contributor's environment. No methodology validation possible during extraction wait.
2. **Python hooks.** Rejected: Python version management (pyenv, venv) adds operational overhead inconsistent with the plugin's portability goals. Bash is universally available on macOS + Linux.
3. **Node-only stack (hooks in JS).** Rejected: requires npm in every hook execution context. Bash is faster for the I/O-light validation logic that hooks perform.

## References

- phased-build-plan.md §5.5 ("not placeholders — production enforcement layer for v0.x")
- phased-build-plan.md §1 (table: "bash hooks ran in production for months")
- SL-1 (Node 20+ as required toolchain — Stage 3 user lock)
- NFR-014 (cross-platform support target)
- NFR-021 (shellcheck compliance), NFR-022 (shfmt compliance)
- ADR-007 (factory-dispatcher v1.0 migration)
