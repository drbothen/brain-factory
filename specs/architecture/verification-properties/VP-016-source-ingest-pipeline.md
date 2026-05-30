---
document_type: verification-property
id: VP-016
title: "Source ingest pipeline: local file ingest and out-of-vault path rejection"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.03.001, BC-2.03.003, BC-2.03.004]
created: 2026-05-15
status: proposed
---

# VP-016: Source ingest pipeline: local file ingest and out-of-vault path rejection

## Property Statement

For a valid local file path within the brain vault, `/brain:ingest-source <path>`
executes the complete local ingest pipeline: reads the file directly (no Defuddle
fetch), writes `sources/{topic}/{slug}.md` with mandatory source frontmatter, updates
`.brain/manifest.json` with the manifest delta, triggers 5–15 wiki pages, and writes
the JSONL token record (BC-2.03.001).

Out-of-vault paths (paths resolving outside the brain root, including system directories
such as `/etc/`, `/usr/`, `/proc/`) are blocked with E-INGEST-009 and exit 2
(BC-2.03.003). The restriction applies even when the path technically resolves to a
readable file.

Partial failure fan-out: if wiki page generation fails for individual pages (e.g.,
a hook blocks one page), the per-page errors are propagated individually; the source
file write and manifest update are not rolled back (BC-2.03.004). The skill exits 1
on partial failure (some pages failed) with a structured partial-failure report.

## Verification Mechanism

bats (skills.bats + integration.bats):

```bash
@test "ingest-source: valid local file ingested to sources/ and wiki pages created" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-source-test"
  setup_fixture_brain "$brain_dir"

  # Create a test fixture file within the brain vault
  local fixture_file="$brain_dir/inbox/my-article.md"
  cat > "$fixture_file" <<'EOF'
# Test Article

This is a test article about AI agents and cognitive architectures.
It has enough content to produce at least 5 wiki pages.
...
EOF

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/ingest-source/run.sh" "$fixture_file" --topic ai --yes

  assert_success
  # Source file created with mandatory frontmatter
  run find "$brain_dir/sources/ai" -name "*.md" | wc -l
  assert_output "1"
  # Manifest updated
  run jq '.sources | length' "$brain_dir/.brain/manifest.json"
  assert_output "1"
  # Wiki pages created
  local wiki_count; wiki_count="$(find "$brain_dir/wiki" -name "*.md" \
    ! -name "index.md" ! -name "log.md" | wc -l | tr -d ' ')"
  assert [ "$wiki_count" -ge 5 ] "Expected >= 5 wiki pages, got $wiki_count"
}

@test "ingest-source: out-of-vault path blocked with E-INGEST-009 (BC-2.03.003)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-vault-test"
  setup_fixture_brain "$brain_dir"

  # System path outside vault
  run bash "${PLUGIN_ROOT}/skills/ingest-source/run.sh" /etc/hostname --topic ai --yes
  assert_failure 2
  assert_output --partial '"code":"E-INGEST-009"'

  # Path traversal attack (resolved path is outside vault)
  run bash "${PLUGIN_ROOT}/skills/ingest-source/run.sh" \
    "$brain_dir/../../etc/passwd" --topic ai --yes
  assert_failure 2
  assert_output --partial '"code":"E-INGEST-009"'
}

@test "ingest-source: partial failure fan-out — source committed, failed pages reported individually (BC-2.03.004)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-partial-test"
  setup_fixture_brain "$brain_dir"

  # Configure the hook to block writes to wiki/people/ for this test
  local fixture_file="$brain_dir/inbox/partial-test.md"
  printf '# Test\nContent for partial failure test.\n' > "$fixture_file"

  BRAIN_ROOT="$brain_dir" \
    BATS_HOOK_OVERRIDE_BLOCK_WIKI_TYPE="people" \
    bash "${PLUGIN_ROOT}/skills/ingest-source/run.sh" "$fixture_file" --topic ai --yes
  # Partial failure: exit 1, NOT exit 2
  assert_failure 1
  # Source file must still be committed
  local src_count; src_count="$(find "$brain_dir/sources" -name "*.md" | wc -l | tr -d ' ')"
  assert [ "$src_count" -ge 1 ] "Source file not written despite partial failure"
  # Partial failure report must enumerate failed pages
  assert_output --partial '"status":"partial"'
}
```

## Assumed Prerequisites

- `setup_fixture_brain` helper creates a minimal initialized brain at the given path
- `BATS_HOOK_OVERRIDE_BLOCK_WIKI_TYPE` is a test-environment env var that configures the
  wiki validation hook to block writes to a specific wiki type (for partial-failure simulation)
- `jq` and `yq` in PATH
- Tests run with `BRAIN_ROOT` and `CLAUDE_PLUGIN_ROOT` set explicitly

## Counterexamples

- Path resolution uses string prefix matching (`startsWith("$brain_dir")`) instead of
  `realpath` — symlink traversal can escape the vault; must use `realpath` before comparison
- On partial page-generation failure, the skill rolls back the source file — this violates
  BC-2.03.004 (partial-failure fan-out must not roll back the committed source)
- Out-of-vault check applies only to absolute paths but not relative paths with `../` traversal —
  the bats path-traversal test catches this gap

## Status

proposed — pending Phase 3 implementation of ingest-source skill and skills.bats
