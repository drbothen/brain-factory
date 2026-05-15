# brain-factory

**An LLM-maintained second brain as a Claude Code plugin.** Capture articles, books, podcasts, fleeting thoughts. The LLM compiles them into a wiki organized by type (concepts, people, frameworks, syntheses). Daily briefs surface connections; weekly synthesis builds a thesis; quarterly mirror reflects belief evolution.

> Status: pre-v0.1. Planning artifacts in [`docs/planning/`](docs/planning/). Implementation kicks off following the phased build plan.

## What this is

`brain-factory` is the engine. The brain — your sources, wiki, briefs, published work — lives in a separate repo (your private vault). Install brain-factory into Claude Code; point it at your vault; the plugin's skills, hooks, and agents do the rest.

```
~/.claude/plugins/.../brain-factory/<version>/    ← the plugin (engine, this repo)
<you>/my-brain/                                   ← the data (your private vault)
├── sources/         immutable raw material, by topic
├── wiki/            LLM-owned knowledge graph, organized by type
├── briefs/          daily, weekly, monthly, content briefs
├── published/       archive with performance data
├── .brain/          plugin runtime state
└── CLAUDE.md        your operating manual
```

## Install (after v0.1.0 ships)

```
/plugin marketplace add drbothen/claude-mp
/plugin install brain-factory@claude-mp
```

Then in a fresh directory:

```bash
mkdir my-brain && cd my-brain && git init -b main
claude
> /brain:init
```

## How it relates to vsdd-factory

`brain-factory` is the second consumer of the shared `factory-dispatcher` hook runtime (the first is `vsdd-factory`, the VSDD software-development factory). Both factories live on the [`drbothen/claude-mp`](https://github.com/drbothen/claude-mp) marketplace.

| Plugin | Domain | Repo |
|---|---|---|
| `vsdd-factory` | Software engineering via Verified Spec-Driven Development | [drbothen/vsdd-factory](https://github.com/drbothen/vsdd-factory) |
| `brain-factory` | LLM-maintained personal knowledge management | this repo |
| `factory-dispatcher` | Shared WASM hook runtime + SDK + observability sinks | (to be extracted from vsdd-factory) |

## Planning artifacts

Four planning documents drive the build. Each is independently executable from zero context.

| Document | Purpose |
|---|---|
| [`docs/planning/llm-second-brain-plan.md`](docs/planning/llm-second-brain-plan.md) | The methodology — what a brain does, how layers work, the daily/weekly/monthly rituals, voice rules. |
| [`docs/planning/llm-second-brain-plugin-plan.md`](docs/planning/llm-second-brain-plugin-plan.md) | The plugin packaging — engine/target split, hook-enforced discipline, declarative governance, adversarial review, ~25 skills, 10 specialist agents, 18 GitHub Action templates. |
| [`docs/planning/llm-second-brain-phased-build-plan.md`](docs/planning/llm-second-brain-phased-build-plan.md) | **The recommended build path** — start with bash hooks, ship v0.x in ~5 weeks, migrate to WASM via shared dispatcher only when ready (v1.0). |
| [`docs/planning/vsdd-dispatcher-extraction-plan.md`](docs/planning/vsdd-dispatcher-extraction-plan.md) | The upstream prerequisite for v1.0 — how vsdd-factory migrates to a vendored dispatcher, freeing the hook runtime for brain-factory and future factories to share. |

**Start here:** the [phased build plan](docs/planning/llm-second-brain-phased-build-plan.md). It's self-sufficient for Phases 0–3 (manual brain → plugin scaffold → marketplace publish → dogfood).

## License

MIT (forthcoming — pending license file).
