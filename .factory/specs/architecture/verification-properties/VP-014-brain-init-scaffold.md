---
document_type: verification-property
id: VP-014
title: "Brain initialization scaffolds complete folder structure"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-16T00:00:00
verifies_bcs: [BC-2.01.001, BC-2.01.002, BC-2.01.003, BC-2.01.004]
created: 2026-05-15
status: proposed
---

# VP-014: Brain initialization scaffolds complete folder structure

## Property Statement

After a successful `/brain:init` run against a fresh git-initialized directory, the
complete postcondition structure from BC-2.01.001 exists on disk: all 7 source topic
subdirectories, all 6 wiki type subdirectories, all 6 briefs subdirectories, `inbox/`,
`.brain/logs/`, `.brain/manifest.json`, `.brain/STATE.md`, `.brain/policies.yaml`,
`wiki/index.md`, `wiki/log.md`, `CLAUDE.md`, `rules/voice-avoid-list.txt`, and 6 core
GH Action template files in `.github/workflows/`. The total directory and file count
after a successful init is at least 25 distinct entries.

Completion wall-clock time must be under 5 minutes (BC-2.01.002). Error paths must emit
E-INIT-001 through E-INIT-006 with exit 2 for each failure mode (BC-2.01.003). Every
wiki page template written during init must include `embedding_status: pending` in
frontmatter (BC-2.01.004).

No engine plugin files are modified during init. Template resolution always uses
`${CLAUDE_PLUGIN_ROOT}/templates/...` — never hardcoded paths.

## Verification Mechanism

bats (integration.bats) — end-to-end init assertion on a temp brain.

**Invocation pattern:** The public `/brain:init` interface is zero-argument (SS-01 §Architectural Decisions). The bats harness does NOT pass `--target` or `--yes` flags. Instead it `cd`s into the temp brain directory before invoking the skill's run script, which uses the current working directory as the target. This matches the real operator invocation pattern.

```bash
@test "/brain:init: all postcondition directories exist in fresh brain" {
  local brain_dir; brain_dir="$(mktemp -d)"
  git -C "$brain_dir" init -b main >/dev/null 2>&1

  # Invoke init skill via cd into brain dir — zero-argument public CLI (SS-01 §Architectural Decisions)
  (cd "$brain_dir" && CLAUDE_PLUGIN_ROOT="${BATS_TEST_DIRNAME}/../../.." \
    bash "${CLAUDE_PLUGIN_ROOT}/skills/init/run.sh")

  assert_success

  # Directory structure assertions (BC-2.01.001)
  for dir in \
    sources/ai sources/health sources/psychology sources/productivity \
    sources/business sources/books sources/podcasts \
    wiki/concepts wiki/people wiki/frameworks wiki/syntheses \
    wiki/observations wiki/questions \
    inbox \
    briefs/daily briefs/weekly briefs/monthly briefs/content \
    briefs/decisions briefs/research \
    .brain/logs .github/workflows rules; do
    assert [ -d "$brain_dir/$dir" ] "Missing directory: $dir"
  done

  # File assertions
  for file in \
    .brain/manifest.json .brain/STATE.md .brain/policies.yaml \
    wiki/index.md wiki/log.md CLAUDE.md rules/voice-avoid-list.txt; do
    assert [ -f "$brain_dir/$file" ] "Missing file: $file"
  done

  # GH Action templates (6 core templates — BC-2.01.001 postcondition 1)
  local gh_count; gh_count="$(find "$brain_dir/.github/workflows" -name "*.yml" | wc -l | tr -d ' ')"
  assert [ "$gh_count" -ge 6 ] "Expected >= 6 GH Action templates, got $gh_count"
}

@test "/brain:init: embedding_status: pending in all init wiki templates (BC-2.01.004)" {
  local brain_dir; brain_dir="$(mktemp -d)"
  git -C "$brain_dir" init -b main >/dev/null 2>&1
  (cd "$brain_dir" && CLAUDE_PLUGIN_ROOT="${BATS_TEST_DIRNAME}/../../.." \
    bash "${CLAUDE_PLUGIN_ROOT}/skills/init/run.sh")

  # Every wiki page template written during init must have embedding_status: pending
  while IFS= read -r page; do
    local status; status="$(yq eval '.embedding_status // ""' "$page")"
    assert [ "$status" = "pending" ] "Wiki page $page missing embedding_status: pending"
  done < <(find "$brain_dir/wiki" -name "*.md" ! -name "index.md" ! -name "log.md")
}

@test "/brain:init: rejects non-git directory with E-INIT-001 (BC-2.01.003)" {
  local brain_dir; brain_dir="$(mktemp -d)"
  # No git init — should get E-INIT-001
  run bash -c "cd '$brain_dir' && CLAUDE_PLUGIN_ROOT='${BATS_TEST_DIRNAME}/../../..' \
    bash '${BATS_TEST_DIRNAME}/../../../skills/init/run.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-INIT-001"'
}

@test "/brain:init: rejects existing .brain/ with E-INIT-002 — hard-fail, not idempotent (BC-2.01.003)" {
  # Decision: already-initialized brain → E-INIT-002 hard-fail (SS-01 §Architectural Decisions).
  # The correct recovery is /brain:upgrade-brain, not re-running /brain:init.
  local brain_dir; brain_dir="$(mktemp -d)"
  git -C "$brain_dir" init -b main >/dev/null 2>&1
  mkdir -p "$brain_dir/.brain"
  run bash -c "cd '$brain_dir' && CLAUDE_PLUGIN_ROOT='${BATS_TEST_DIRNAME}/../../..' \
    bash '${BATS_TEST_DIRNAME}/../../../skills/init/run.sh'"
  assert_failure 2
  assert_output --partial '"code":"E-INIT-002"'
}

@test "/brain:init: completes under 5 minutes (BC-2.01.002)" {
  local brain_dir; brain_dir="$(mktemp -d)"
  git -C "$brain_dir" init -b main >/dev/null 2>&1
  local start; start="$(date +%s)"
  (cd "$brain_dir" && CLAUDE_PLUGIN_ROOT="${BATS_TEST_DIRNAME}/../../.." \
    bash "${CLAUDE_PLUGIN_ROOT}/skills/init/run.sh")
  local elapsed; elapsed="$(($(date +%s) - start))"
  assert [ "$elapsed" -lt 300 ] "/brain:init took ${elapsed}s, exceeds 5-minute SLA"
}
```

## Assumed Prerequisites

- `yq` in PATH (for frontmatter assertions)
- `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin installation directory in the test environment
- Tests run in a temp directory that is cleaned up after each test case
- The init skill's run script is idempotent with respect to re-running on a fresh temp dir

## Counterexamples

- `/brain:init` writes templates using a hardcoded path like `.claude/templates/` instead of
  `${CLAUDE_PLUGIN_ROOT}/templates/...` — this breaks cross-installation portability and
  violates the template-path discipline (brain-factory-002-equivalent for templates)
- One of the 7 source topic directories is omitted from the scaffold — the bats
  directory-assertion loop catches any missing entry
- `embedding_status` is absent from a wiki page template — the per-page yq assertion catches this
- `/brain:init` modifies files under `${CLAUDE_PLUGIN_ROOT}/` — any such write would be detected
  by a post-run integrity check comparing file mtimes against the plugin installation timestamp

## Status

proposed — pending Phase 3 implementation of init skill and integration.bats
