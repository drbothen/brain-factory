# brain-factory — Plugin Repo Operating Manual

> Read this file first when working in this repo. This is the brain-factory **plugin source repo**, not a brain vault. Brain content (sources, wiki, briefs) lives in a separate user repo.

## Project identity

**brain-factory** is a Claude Code plugin that turns Obsidian-style vaults into LLM-maintained second brains. It is the second factory in a planned family alongside `vsdd-factory` (Verified Spec-Driven Development) and a planned shared `factory-dispatcher` (the hook runtime).

This repo contains:
- Plugin source (will live under `plugins/brain-factory/` once implementation starts)
- Planning artifacts (`docs/planning/`)
- Tests (`plugins/brain-factory/tests/` — bats suites)
- CI workflows (`.github/workflows/`)

This repo does NOT contain:
- A user's brain vault (sources, wiki, briefs). That's a separate per-user repo.
- The shared dispatcher source. That's `factory-dispatcher`, a separate repo.

## Current state

**Pre-v0.1.** Planning complete; implementation pending Phase 0 of the phased build plan ([`docs/planning/llm-second-brain-phased-build-plan.md`](docs/planning/llm-second-brain-phased-build-plan.md)).

Next step: execute Phase 0 (manual brain in a test vault) to validate the methodology before plugin scaffolding begins.

## Build path

Follow [`docs/planning/llm-second-brain-phased-build-plan.md`](docs/planning/llm-second-brain-phased-build-plan.md):

| Phase | Goal | Duration |
|---|---|---|
| 0 | Manual brain (validate methodology) | 1 week |
| 1 | Plugin scaffold with bash hooks | 3 weeks |
| 2 | Marketplace publish + first install | 1 week |
| 3 | Author dogfood + pilot users | 8–12 weeks |
| 4 | Dispatcher migration to WASM | Gated on upstream |

Each phase has explicit exit gates. Do not advance until prior gate passes.

## Authority — source of truth

When two artifacts disagree, the LATER, MORE-SPECIFIC artifact wins:

1. The planning docs in `docs/planning/` — these are the design source of truth.
2. Once implementation starts, `plugins/brain-factory/skills/*/SKILL.md` and `plugins/brain-factory/hooks/*.sh` become authoritative for behavior.
3. `CHANGELOG.md` (forthcoming) records the path from v0.1.0 onward.

If code and a plan disagree: the PLAN wins. Bring code into alignment via fix in scope or follow-up issue. Only the human can authorize plan amendment to match code.

## Conventions (code-level, when implementation begins)

- **Bash hooks** under `plugins/brain-factory/hooks/`: `set -euo pipefail`, JSON-in / JSON-out protocol, exit 0/1/2 for ok/advisory/block. See [phased plan §A.4](docs/planning/llm-second-brain-phased-build-plan.md) for full hook spec.
- **Skills** under `plugins/brain-factory/skills/<name>/SKILL.md`: frontmatter (name, description, argument-hint, allowed-tools), Iron Law, Red Flags, Announce-at-Start, Procedure (numbered), Quality Bar, Output.
- **Templates** referenced via `${CLAUDE_PLUGIN_ROOT}/templates/...`. NEVER hardcoded `.claude/templates/` paths.
- **Filenames** kebab-case, lowercase, no spaces. Wiki filenames are IMMUTABLE after creation — renames go through the rename-page skill.
- **Commits** conventional format (`feat:`, `fix:`, `chore:`, `docs:`). NO AI attribution — never include `Co-Authored-By: Claude` or robot emoji. NEVER force-push to `main`. NEVER use `--no-verify`.

## Hard rules

- NEVER modify any planning artifact under `docs/planning/` without explicit instruction. These are versioned design documents; changes go through a separate revision process.
- NEVER create folders outside the structure defined in the phased build plan §A.2.
- ALWAYS check Phase exit gates before advancing the build.
- CHALLENGE assumptions before agreeing. Cite a planning artifact section when disagreeing.

## What I want from you (Claude)

- When asked to "start building" or "execute," begin with [`docs/planning/llm-second-brain-phased-build-plan.md`](docs/planning/llm-second-brain-phased-build-plan.md) §4 (Phase 0). Do not skip Phase 0.
- When asked to "ship" or "release," check the Phase exit gates first.
- Surface decisions to the human; do not make naming, marketplace, or stewardship choices unilaterally.
- When in doubt about an architectural decision, cite the relevant planning section and ask.

## Family relationship

| Repo | Role |
|---|---|
| [`drbothen/vsdd-factory`](https://github.com/drbothen/vsdd-factory) | Sister plugin — VSDD methodology for software engineering. Same family branding (`<domain>-factory`). |
| [`drbothen/claude-mp`](https://github.com/drbothen/claude-mp) | The marketplace. Hosts both vsdd-factory and brain-factory tarballs. |
| `factory-dispatcher` (planned) | Shared hook runtime to be extracted from vsdd-factory. v1.0 of brain-factory depends on it. |

## License

MIT (LICENSE file forthcoming).
