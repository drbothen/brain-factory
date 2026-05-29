---
overall_health: YELLOW
last_health_check: ""
dimensions:
  capture: YELLOW
  sources: GREEN
  wiki: YELLOW
  synthesis: YELLOW
  output: YELLOW
  reflection: GREEN
---

# Brain STATE

Six-dimensional convergence tracking for this brain vault.
Run `/brain:health` to refresh all dimensions and update this file.

## Dimension 1: Capture

Tracks the `inbox/` directory. GREEN when inbox is present and has ≤50 items;
YELLOW when inbox is backlogged (>50 items — run `/brain:inbox-review` to clear);
RED when inbox directory is missing (run `/brain:init` to repair).

| Metric | Value |
|--------|-------|
| Inbox items | 0 |
| Status | (not yet checked) |

## Dimension 2: Sources

Tracks `manifest.json` (source index) and 30-day trailing token cost. GREEN when
sources are indexed and token budget is within baseline; YELLOW when token cost
exceeds 2× baseline or no sources are indexed yet; RED when manifest is missing
or corrupt, or when token cost exceeds 4× baseline.

| Metric | Value |
|--------|-------|
| Sources indexed | 0 |
| 30-day avg tokens | (not yet checked) |
| Status | (not yet checked) |

## Dimension 3: Wiki

Tracks real wiki pages under `wiki/` (excludes `index.md`, `log.md`, `_template*`).
GREEN when ≥1 wiki page exists; YELLOW when no wiki pages exist yet (ingest your
first source to populate).

| Metric | Value |
|--------|-------|
| Wiki pages | 0 |
| Status | (not yet checked) |

## Dimension 4: Synthesis

Tracks weekly briefs under `briefs/weekly/`. GREEN when ≥1 weekly brief exists;
YELLOW when none exist yet (run `/brain:weekly-synthesis` to generate).

| Metric | Value |
|--------|-------|
| Weekly briefs | 0 |
| Status | (not yet checked) |

## Dimension 5: Output

Tracks content briefs under `briefs/content/`. GREEN when ≥1 content brief exists;
YELLOW when none exist yet (run `/brain:draft-content-brief` to generate).

| Metric | Value |
|--------|-------|
| Content briefs | 0 |
| Status | (not yet checked) |

## Dimension 6: Reflection

Tracks `.brain/STATE.md` itself. GREEN when STATE.md exists and is non-empty;
YELLOW when STATE.md is empty (re-run `/brain:init` or restore from backup).

| Metric | Value |
|--------|-------|
| STATE.md | present |
| Status | (not yet checked) |

---
_Initialized by /brain:init_
