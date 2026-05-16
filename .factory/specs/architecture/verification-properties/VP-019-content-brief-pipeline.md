---
document_type: verification-property
id: VP-019
title: "Content brief pipeline: ONE THING / PROOF / TRANSFORMATION structure enforcement"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.08.001, BC-2.08.002]
created: 2026-05-15
status: proposed
---

# VP-019: Content brief pipeline: ONE THING / PROOF / TRANSFORMATION structure enforcement

## Property Statement

**Brief generation (BC-2.08.001):** `/brain:brief <topic>` generates a content brief
at `briefs/content/{slug}-brief.md` containing all three mandatory sections: ONE THING
(the single thesis), PROOF (evidence points citing real wiki page slugs from the brain),
and TRANSFORMATION (what the reader's view changes to). The brief frontmatter includes
`topic`, `created`, `status: draft`, and `source_wiki_pages: [...]`. PROOF points must
cite actual wiki page slugs — hallucinated citations (slugs not present in `wiki/`) fail
the verification.

When the brain has no wiki pages relevant to the topic, the skill emits advisory exit 1
(not exit 2 — the lack of content is not a hard error, it is guidance to the operator).

**Write skill takes brief as input (BC-2.08.002):** `/brain:write` accepts the brief
file as input, produces a full draft in `drafts/{platform}/`, and the draft frontmatter
references the source brief slug. The draft must contain at least 80% of the key points
enumerated in the brief's PROOF section.

## Verification Mechanism

bats (skills.bats) — end-to-end brief generation with a seeded brain:

```bash
@test "brain:brief: generates brief with all 3 mandatory sections (BC-2.08.001)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-brief-test"
  setup_fixture_brain_with_ai_pages "$brain_dir"  # seeds wiki/concepts/ai-agents.md etc.

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/brief/run.sh" "AI agents" --yes

  assert_success

  # Brief file created
  local brief_file; brief_file="$(find "$brain_dir/briefs/content" -name "*ai-agents*brief*.md" | head -1)"
  assert [ -n "$brief_file" ] "No brief file created in briefs/content/"

  # All three mandatory sections present
  run grep -c "## ONE THING\|## PROOF\|## TRANSFORMATION" "$brief_file"
  assert_output "3"

  # Frontmatter fields present
  run yq eval '.topic' "$brief_file"
  refute_output ""  # topic must be set

  run yq eval '.status' "$brief_file"
  assert_output "draft"

  run yq eval '.source_wiki_pages | length' "$brief_file"
  assert [ "$output" -ge 1 ] "source_wiki_pages must reference at least 1 wiki page"
}

@test "brain:brief: PROOF citations resolve to real wiki slugs (BC-2.08.001 Invariant 2)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-brief-citation-test"
  setup_fixture_brain_with_ai_pages "$brain_dir"

  BRAIN_ROOT="$brain_dir" CLAUDE_PLUGIN_ROOT="${PLUGIN_ROOT}" \
    bash "${PLUGIN_ROOT}/skills/brief/run.sh" "AI agents" --yes

  local brief_file; brief_file="$(find "$brain_dir/briefs/content" -name "*brief*.md" | head -1)"

  # Extract all wikilink slugs from the PROOF section
  local proof_section; proof_section="$(awk '/## PROOF/,/## TRANSFORMATION/' "$brief_file")"
  local cited_slugs; cited_slugs="$(echo "$proof_section" | grep -oP '\[\[\K[^\]]+(?=\]\])')"

  while IFS= read -r slug; do
    [[ -z "$slug" ]] && continue
    # Each cited slug must resolve to an actual wiki file
    local resolved; resolved="$(find "$brain_dir/wiki" -name "${slug}.md" | head -1)"
    assert [ -n "$resolved" ] "PROOF cites non-existent wiki slug: $slug"
  done <<< "$cited_slugs"
}

@test "brain:brief: no relevant wiki pages → advisory exit 1 (BC-2.08.001 EC-001)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-empty-brief-test"
  setup_fixture_brain "$brain_dir"  # empty brain with no wiki pages

  run bash "${PLUGIN_ROOT}/skills/brief/run.sh" "quantum computing" --yes
  assert_failure 1  # Advisory exit, not hard fail
  assert_output --partial 'No wiki content found'
}

@test "brain:write: draft references source brief and includes key points (BC-2.08.002)" {
  local brain_dir; brain_dir="${BATS_TEST_TMPDIR}/brain-write-test"
  setup_fixture_brain_with_ai_pages "$brain_dir"

  # Generate brief first
  BRAIN_ROOT="$brain_dir" bash "${PLUGIN_ROOT}/skills/brief/run.sh" "AI agents" --yes
  local brief_file; brief_file="$(find "$brain_dir/briefs/content" -name "*brief*.md" | head -1)"

  # Run write skill with the brief
  BRAIN_ROOT="$brain_dir" bash "${PLUGIN_ROOT}/skills/write/run.sh" --brief "$brief_file" --yes
  assert_success

  # Draft file created in drafts/
  local draft_file; draft_file="$(find "$brain_dir/drafts" -name "*.md" | head -1)"
  assert [ -n "$draft_file" ] "No draft file created in drafts/"

  # Draft frontmatter references source brief
  run yq eval '.source_brief' "$draft_file"
  refute_output ""
  assert_output --partial "briefs/content/"
}
```

## Assumed Prerequisites

- `setup_fixture_brain_with_ai_pages` seeds the brain with 5+ wiki pages about AI agents
  (at slugs like `ai-agents.md`, `cognitive-architectures.md`, etc.)
- `setup_fixture_brain` creates an initialized brain with no wiki pages
- The wiki pages seeded by the fixture must be resolvable via `[[slug]]` wikilinks
- `yq` and `awk` in PATH

## Counterexamples

- The brief contains the section headings "ONE THING", "PROOF", "TRANSFORMATION" but one of
  them has empty body — the bats test checks for heading presence; a supplementary test should
  assert that each section body is non-empty (at least 1 non-blank line)
- PROOF section cites slugs using wikilink format `[[slug]]` but the slug doesn't match any
  `wiki/{type}/{slug}.md` file — the slug resolution loop catches hallucinated citations
- `/brain:write` accepts a brief path but ignores the `source_wiki_pages` field and generates
  content independently — the draft references check verifies the brief is actually consumed

## Status

proposed — pending Phase 3 implementation of brief skill, write skill, and skills.bats
