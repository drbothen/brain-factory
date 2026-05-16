---
document_type: verification-property
id: VP-005
title: "Frontmatter schema conformance"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.04.004, BC-2.04.005, BC-2.05.006]
created: 2026-05-15
status: proposed
---

# VP-005: Frontmatter schema conformance

## Property Statement

For any markdown file written to `wiki/`, `briefs/`, or `sources/`: if the file's YAML frontmatter (between `---` fences at the top) is missing any mandatory field, the PostToolUse `validate-frontmatter-schema.sh` hook produces exit 2, verdict `block`, code `E-SCHEMA-001`. The mandatory field set for wiki pages includes at minimum: `title`, `type`, `created`, `embedding_status`.

## Verification Mechanism

bats (hooks.bats) with fixture payloads:

```bash
@test "validate-frontmatter-schema.sh: missing embedding_status → E-SCHEMA-001" {
  # Wiki page content without embedding_status
  local content='---\ntitle: "Test Concept"\ntype: concept\ncreated: 2026-01-01\n---\n# Test'
  local payload="{\"tool\":\"Write\",\"input\":{\"path\":\"wiki/concepts/test.md\",\"content\":\"$content\"},\"output\":{}}"
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-frontmatter-schema.sh"
  assert_failure 2
  assert_output --partial '"code":"E-SCHEMA-001"'
}

@test "validate-frontmatter-schema.sh: complete frontmatter → allow" {
  local content='---\ntitle: "Test"\ntype: concept\ncreated: 2026-01-01\nembedding_status: pending\n---\n# Test'
  local payload="{\"tool\":\"Write\",\"input\":{\"path\":\"wiki/concepts/test.md\",\"content\":\"$content\"},\"output\":{}}"
  echo "$payload" | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-frontmatter-schema.sh"
  assert_success
}

@test "validate-frontmatter-schema.sh: file not in wiki/ → no-op allow" {
  # Files outside wiki/ are not subject to wiki frontmatter schema
  echo '{"tool":"Write","input":{"path":"scripts/gen.sh","content":"#!/bin/bash"},"output":{}}' \
    | "${CLAUDE_PLUGIN_ROOT}/hooks/validate-frontmatter-schema.sh"
  assert_success
}
```

## Assumed Prerequisites

- `yq` or equivalent YAML parser available (installed by `make setup`)

## Counterexamples

- A wiki page missing `embedding_status` is allowed to be written (violates BC-2.04.004, BC-2.05.006)
- The hook blocks a file in `scripts/` that has no YAML frontmatter (false positive — scope too broad)
- The hook allows a file with malformed YAML frontmatter (fence present but unparseable YAML)

## Status

proposed — pending Phase 3 implementation
