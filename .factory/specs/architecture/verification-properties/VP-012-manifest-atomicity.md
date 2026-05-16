---
document_type: verification-property
id: VP-012
title: "Manifest write atomicity"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.03.002, BC-2.06.003]
created: 2026-05-15
status: proposed
---

# VP-012: Manifest write atomicity

## Property Statement

A manifest.json write that is interrupted between the mktemp write and the mv step leaves the original manifest.json unchanged. The manifest is never in a partial-write state visible to concurrent readers or subsequent hook invocations. After a successful write, manifest.json is valid JSON.

## Verification Mechanism

bats (integration.bats) — inject failure mid-write:

```bash
@test "manifest-write.sh: interrupted write leaves original intact" {
  local vault="${TEMP_BRAIN}"
  local manifest="${vault}/.brain/manifest.json"
  
  # Establish baseline manifest
  echo '{"version":"1","sources":{},"last_updated":"2026-01-01"}' > "$manifest"
  local original; original="$(cat "$manifest")"
  
  # Simulate interrupted write by overriding mv with a failing version
  mv() { return 1; }
  export -f mv
  
  # Attempt to write new content
  run bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh" \
    "$manifest" '{"version":"1","sources":{"sources/ai/test.md":{}},"last_updated":"2026-01-15"}'
  assert_failure
  
  # Original manifest unchanged
  local after; after="$(cat "$manifest")"
  assert_equal "$original" "$after"
  
  # No temp file leaked
  assert_equal "0" "$(ls "${manifest}."* 2>/dev/null | wc -l)"
  
  unset -f mv
}

@test "manifest-write.sh: successful write produces valid JSON" {
  run bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/manifest-write.sh" \
    "${TEMP_BRAIN}/.brain/manifest.json" \
    '{"version":"1","sources":{},"last_updated":"2026-01-15"}'
  assert_success
  run jq -e '.' "${TEMP_BRAIN}/.brain/manifest.json"
  assert_success "manifest.json is not valid JSON after write"
}
```

## Assumed Prerequisites

- `manifest-write.sh` helper exists in `hooks/lib/` (ADR-016)
- Temp directory available for test vault

## Counterexamples

- `manifest.json` is written directly (without tmp-file + mv pattern) — if the process is killed mid-write, the file is partially written (invalid JSON)
- The temp file from a failed write is not cleaned up (file leak — would confuse subsequent manifest reads)
- A successful write produces JSON with an extraneous trailing newline that makes it unparseable by `jq` (malformed output)

## Status

proposed — pending Phase 3 implementation of manifest-write.sh
