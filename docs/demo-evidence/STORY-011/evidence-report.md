---
story_id: STORY-011
recorded: 2026-05-27
status: complete
---

# Demo Evidence Report — STORY-011

## Coverage

6 per-AC recordings + 2 full-suite bats recordings.

## Per-AC Recordings

| AC | File | Demonstrates |
|----|------|-------------|
| AC-002 | `AC-002-resolved-source-ids-exit-0.gif` | `source_ids: [ai/valid-source]` with matching manifest entry → exit 0, `{"verdict":"allow"}` |
| AC-003 | `AC-003-unresolved-source-id-exit-2.gif` | `source_ids: [ai/nonexistent]` with no manifest entry → exit 2, `"code":"E-WIKI-007"` with slug in message |
| AC-006 | `AC-006-missing-manifest-exit-2.gif` | `.brain/manifest.json` absent → exit 2, `"code":"E-WIKI-008"` (fail-closed) |
| AC-009 | `AC-009-new-draft-exit-0.gif` | New file write with `status: draft` → exit 0 (creation allowed, no prior state) |
| AC-011 | `AC-011-draft-to-published-exit-2.gif` | Transition `draft → published` (skipping `ready`) → exit 2, `"code":"E-PUBLISH-001"` |
| AC-015 | `AC-015-lint-clean.gif` | `shellcheck` + `shfmt -d -i 2` clean on both scripts |

## Full Suite Recordings

| Recording | Tests | Pass |
|-----------|-------|------|
| `FULL-001-bats-source-id-citation.gif` | 22 | 22/22 |
| `FULL-002-bats-publish-state.gif` | 26 | 26/26 |

## Coverage Assessment

All ACs with hook-executable behavior (AC-002, AC-003, AC-004, AC-005, AC-006, AC-007 for citation; AC-009, AC-010, AC-011, AC-012, AC-013, AC-014 for publish state) are covered by bats tests. The per-AC GIF recordings demonstrate the 6 most representative behaviors; the full suite recordings confirm all 48 tests pass.

ACs AC-001 and AC-008 (script structural contract: shebang, set -euo pipefail, jq, no eval, exit codes) are covered by AC-015 lint-clean recording and meta-lint assertions.

Gate: at least 1 recording per AC — satisfied (AC-002, AC-003, AC-006, AC-009, AC-011, AC-015 each cover at least one AC; full suite recordings cover remaining ACs through bats).
