---
document_type: verification-property
id: VP-026
title: "Event catalog: JSON schema validity and emit-site completeness"
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-16T00:00:00
verifies_bcs: [BC-2.17.003, BC-2.17.004]
created: 2026-05-15
status: proposed
---

# VP-026: Event catalog: JSON schema validity and emit-site completeness

## Property Statement

**stdout/stderr separation (BC-2.17.003):** For every hook script, stdout contains
exactly one JSON verdict object and stderr contains zero or more JSONL event lines.
`jq empty <stdout>` succeeds on every code path including error paths and early-exit
paths triggered by `set -euo pipefail`. No JSONL events appear on stdout; no verdict
content appears on stderr. This is a load-bearing architectural constraint for
dispatcher-readiness in v1.0 (KD-003).

**Catalog completeness (BC-2.17.004):** The structured event catalog at
`scripts/event-catalog.json` is a closed registry. Every `emit_event` call site in
every hook script must use an `event_type` value that is registered in `event-catalog.json`.
No `event_type` that is not in the catalog may appear in any hook's stderr JSONL output.
The meta-lint suite verifies this at CI time by cross-referencing all emit sites against
the catalog.

## Verification Mechanism

bats (meta-lint.bats + hooks.bats) — catalog cross-reference and separation enforcement:

```bash
# --- BC-2.17.004: catalog completeness cross-reference ---

@test "event catalog: event-catalog.json is valid JSON (BC-2.17.004)" {
  local catalog="${PLUGIN_ROOT}/scripts/event-catalog.json"
  assert [ -f "$catalog" ] "event-catalog.json not found"
  run jq empty "$catalog"
  assert_success "event-catalog.json is not valid JSON"
}

@test "event catalog: every emit_event call site uses a registered event_type" {
  local catalog="${PLUGIN_ROOT}/scripts/event-catalog.json"
  local registered_types; registered_types="$(jq -r '.[].event_type' "$catalog")"

  # Extract all event_type values from emit_event calls in hook scripts
  while IFS= read -r hook_script; do
    local emit_sites; emit_sites="$(grep -oP 'emit_event\s+"\K[^"]+(?=")' "$hook_script" || true)"
    while IFS= read -r event_type; do
      [[ -z "$event_type" ]] && continue
      if ! grep -qxF "$event_type" <<< "$registered_types"; then
        fail "Unregistered event_type '$event_type' in $hook_script not found in event-catalog.json"
      fi
    done <<< "$emit_sites"
  done < <(find "${PLUGIN_ROOT}/hooks" -name "*.sh" ! -path "*/lib/*")
}

@test "event catalog: catalog has at least one entry per hook type (lifecycle coverage)" {
  local catalog="${PLUGIN_ROOT}/scripts/event-catalog.json"
  # Expected hook lifecycle event types that must be in the catalog
  local required_types=(
    "hook.allow"
    "hook.block"
    "hook.advise"
    "hook.error"
  )
  for event_type in "${required_types[@]}"; do
    run jq --arg t "$event_type" 'map(select(.event_type == $t)) | length' "$catalog"
    assert [ "$output" -ge 1 ] "event-catalog.json missing required event_type: $event_type"
  done
}

# --- BC-2.17.003: stdout/stderr separation for all hooks ---

@test "all hooks: stdout is valid single JSON on allow code path" {
  local representative_payloads=(
    '{"tool":"Write","input":{"path":"wiki/concepts/ok.md"},"output":{}}'
    '{"tool":"Bash","input":{"command":"git status"}}'
    '{"tool":"WebFetch","input":{"url":"https://example.com"}}'
  )
  while IFS= read -r hook_script; do
    local hook_name; hook_name="$(basename "$hook_script" .sh)"
    local payload="${representative_payloads[0]}"  # Use Write payload as default
    run bash -c "echo '$payload' | '$hook_script' 2>/dev/null"
    run jq empty <<< "$output"
    assert_success "hook $hook_name: stdout is not valid JSON on allow path"
  done < <(find "${PLUGIN_ROOT}/hooks" -name "*.sh" ! -path "*/lib/*")
}

@test "all hooks: stderr contains at least 1 JSONL line per invocation (BC-2.17.003 EC-003 / NFR-011)" {
  while IFS= read -r hook_script; do
    local hook_name; hook_name="$(basename "$hook_script" .sh)"
    local payload='{"tool":"Write","input":{"path":"wiki/concepts/test.md"},"output":{}}'
    local stderr_output; stderr_output="$(echo "$payload" | "$hook_script" 2>&1 >/dev/null || true)"
    local line_count; line_count="$(echo "$stderr_output" | grep -c '{' || echo 0)"
    assert [ "$line_count" -ge 1 ] \
      "hook $hook_name: stderr has no JSONL events (NFR-011 violation)"
  done < <(find "${PLUGIN_ROOT}/hooks" -name "*.sh" ! -path "*/lib/*")
}

@test "all hooks: no verdict content appears on stderr (separation enforced)" {
  while IFS= read -r hook_script; do
    local hook_name; hook_name="$(basename "$hook_script" .sh)"
    local payload='{"tool":"Write","input":{"path":"wiki/concepts/test.md"},"output":{}}'
    local stderr_output; stderr_output="$(echo "$payload" | "$hook_script" 2>&1 >/dev/null || true)"
    # Verdict fields must not appear in stderr
    if echo "$stderr_output" | grep -q '"verdict"'; then
      fail "hook $hook_name: verdict JSON found on stderr (should be on stdout only)"
    fi
  done < <(find "${PLUGIN_ROOT}/hooks" -name "*.sh" ! -path "*/lib/*")
}
```

## Assumed Prerequisites

- `scripts/event-catalog.json` exists in the plugin installation by Phase 3
- `emit_event` is the canonical function name used by all hooks (from hook-event-emit.sh)
- All 13 hook scripts are present in `${PLUGIN_ROOT}/hooks/` excluding the `lib/` subdirectory
- `jq` in PATH
- The `grep -oP` (Perl regex) syntax is available in the test environment (bash + grep with PCRE)

## Counterexamples

- A hook uses a literal `event_type` string like `"hook.started"` that is not registered in
  `event-catalog.json` — the emit-site cross-reference loop catches this (SS-17 requires
  past-tense event_type values; `hook.started` is past-tense but must still appear in the
  catalog — an unregistered past-tense value is equally a violation)
- A hook emits a debug JSONL line on stderr that also writes the `"verdict"` key (e.g., a
  developer logs the verdict for debugging) — the verdict-in-stderr test catches this separation
  violation
- `event-catalog.json` exists but is malformed JSON (unclosed bracket) — the `jq empty`
  test on the catalog file itself catches this before any downstream test depends on it
- A hook produces zero JSONL lines on stderr when the allow path is taken (hook omits the
  structured emit call) — the minimum-one-JSONL-line test catches this NFR-011 violation

## Status

proposed — pending Phase 3 implementation of hook-event-emit.sh, event-catalog.json,
and meta-lint.bats extension to cover event catalog cross-reference

## Changelog

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS3-S1:** VP-026 counterexample wording corrected from present-tense to past-tense per the event_type naming convention (SS-17, ADR-009). ARCH-INDEX v0.1.4 entry records: "VP-026 counterexample wording corrected from present-tense to past-tense per the event_type naming convention (SS-17, ADR-009)." [audit-trail]
- **F-PASS10-C1/I1 (27-VP H1 canonical-baseline sweep):** VP-026 H1 title and all three derived cells (VP-INDEX Title, ARCH-INDEX Document Map Purpose, ARCH-INDEX VP-INDEX Summary Title) aligned during the Pass 10 27-VP sweep. ARCH-INDEX v0.1.12 entry records drift resolved for VP-026 Document Map Purpose and VP-INDEX Summary Title cells. [audit-trail]
