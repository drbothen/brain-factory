---
document_type: verification-property
id: VP-002
title: "PostToolUse hook trigger on wiki writes"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.04.003, BC-2.04.004, BC-2.04.005, BC-2.04.006, BC-2.04.007, BC-2.04.009, BC-2.04.010]
created: 2026-05-15
status: proposed
---

# VP-002: PostToolUse hook trigger on wiki writes

## Property Statement

Every Write or Edit tool call that writes to the `wiki/` directory triggers all 7 registered PostToolUse hooks (in the order registered in hooks.json): validate-source-immutability, validate-wikilink-integrity, validate-index-log-coherence, validate-frontmatter-schema, validate-page-type-policy, validate-voice-avoid-list, validate-source-id-citation, validate-publish-state. No hook is skippable by a skill.

## Verification Mechanism

bats (integration.bats) using `local-dev-test.sh` end-to-end pattern:

1. Install plugin in temp vault (with `claude --plugin-dir ./plugins/brain-factory`)
2. Write a wiki file via the Write tool (via a test-skill that deliberately writes)
3. Capture hook stderr logs from `.brain/logs/hooks-YYYY-MM-DD.jsonl`
4. Assert all 8 hook `emit_event` calls appear in the JSONL output for that write operation

```bash
@test "PostToolUse: wiki write triggers all 8 hooks" {
  # Write a test wiki file via the test harness
  write_wiki_file "${TEMP_BRAIN}/wiki/concepts/test-concept.md" "${VALID_WIKI_FIXTURE}"
  # Count distinct hook_name values in the log for this write
  local hooks_fired
  hooks_fired=$(jq -r '.hook_name' "${TEMP_BRAIN}/.brain/logs/hooks-$(date +%Y-%m-%d).jsonl" \
    | sort -u | wc -l)
  assert_equal "$hooks_fired" "8"
}
```

The property also verifies the negative: a write to `sources/` triggers only validate-source-immutability and enforce-kebab-case (not all 8 PostToolUse wiki hooks). The hook routing is matcher-based; the test verifies the matcher works correctly.

## Assumed Prerequisites

- Plugin installed in temp vault
- hooks.json registered in Claude Code
- `.brain/logs/` writable and JSONL-capturing

## Counterexamples

- A PostToolUse hook fires on a wiki write but one of the 8 hooks is silently skipped (missing from JSONL log)
- A skill can write to `wiki/` without triggering the wikilink-integrity hook (bypass scenario — would violate KD-001)

## Changelog

### v1.1 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** Both occurrences of `hooks.json.template` updated to `hooks.json` (filename rename per ADR-003 v2.0): §Property Statement and §Assumed Prerequisites. [audit-trail]

## Status

proposed — pending Phase 3 end-to-end test harness
