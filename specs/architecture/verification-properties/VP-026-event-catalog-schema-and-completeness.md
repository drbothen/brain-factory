---
document_type: verification-property
id: VP-026
title: "Event catalog: JSON schema validity and emit-site completeness"
level: L3
version: "1.4"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-18T00:00:00
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

bats (meta-lint.bats + per-hook .bats files) — catalog cross-reference and separation enforcement:

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
    '{"tool_name":"Write","tool_input":{"path":"wiki/concepts/ok.md"}}'
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}'
    '{"tool_name":"WebFetch","tool_input":{"url":"https://example.com"}}'
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
    local payload='{"tool_name":"Write","tool_input":{"path":"wiki/concepts/test.md"}}'
    local stderr_output; stderr_output="$(echo "$payload" | "$hook_script" 2>&1 >/dev/null || true)"
    local line_count; line_count="$(echo "$stderr_output" | grep -c '{' || echo 0)"
    assert [ "$line_count" -ge 1 ] \
      "hook $hook_name: stderr has no JSONL events (NFR-011 violation)"
  done < <(find "${PLUGIN_ROOT}/hooks" -name "*.sh" ! -path "*/lib/*")
}

@test "all hooks: no verdict content appears on stderr (separation enforced)" {
  while IFS= read -r hook_script; do
    local hook_name; hook_name="$(basename "$hook_script" .sh)"
    local payload='{"tool_name":"Write","tool_input":{"path":"wiki/concepts/test.md"}}'
    local stderr_output; stderr_output="$(echo "$payload" | "$hook_script" 2>&1 >/dev/null || true)"
    # Verdict envelope fields must not appear in stderr
    if echo "$stderr_output" | grep -qE '"continue"|"decision"|"hookSpecificOutput"'; then
      fail "hook $hook_name: verdict envelope JSON found on stderr (should be on stdout only)"
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
- A hook emits a debug JSONL line on stderr that also writes verdict envelope keys (`"continue"`, `"decision"`, `"hookSpecificOutput"`) — the verdict-in-stderr test catches this separation violation
- `event-catalog.json` exists but is malformed JSON (unclosed bracket) — the `jq empty`
  test on the catalog file itself catches this before any downstream test depends on it
- A hook produces zero JSONL lines on stderr when the allow path is taken (hook omits the
  structured emit call) — the minimum-one-JSONL-line test catches this NFR-011 violation

## Status

proposed — pending Phase 3 implementation of hook-event-emit.sh, event-catalog.json,
and meta-lint.bats extension to cover event catalog cross-reference

## Changelog

### v1.4 (2026-05-25)

**CASCADE (ADR-002/ADR-003 v2.0 — hook protocol update):** §Verification Mechanism updated all stale stdin fixtures: `"tool"` → `"tool_name"`, `"input":{...}` → `"tool_input":{...}`, `"output":{}` removed (5 fixture strings across 3 bats tests). Verdict-in-stderr grep updated from `'"verdict"'` to `'"continue"|"decision"|"hookSpecificOutput"'` (new envelope field names). §Counterexamples updated to cite new envelope field names. [audit-trail]

### v1.3 (2026-05-18)

**STRUCTURAL FIX (F-PHASE2-STEP-B-CLOSEOUT-O1-CASCADE — §Verification Mechanism updated to per-hook .bats convention):** Mechanism changed from `bats (meta-lint.bats + hooks.bats)` to `bats (meta-lint.bats + per-hook .bats files)`. The stdout/stderr separation tests for individual hooks now live in per-hook files rather than a consolidated `tests/hooks.bats`. Cascades from SS-18 v1.5 per-hook .bats reversal (F-PHASE2-STEP-B-CLOSEOUT-O1). [audit-trail]

### v1.2 (2026-05-16)

**STRUCTURAL FIX (F-PASS15-C1 — version-bump for Pass 14 Changelog amendments):** Pass 14 architect burst (07466a4) amended this file's Changelog section without bumping its version, in violation of the F-PASS13-C2 incremental scope discipline. This v1.2 burst applies the missing version bump. No new body modifications past v1.1 — only this version-bump-and-Changelog-entry closure. [audit-trail]

**STRUCTURAL FIX (F-PASS15-I1 — F-PASS10-C1/I1 bullet cell-count and H1-directionality correction):** The v1.1 Changelog claimed "all three derived cells aligned" for VP-026. ARCH-INDEX v0.1.12 records only two cells with drift for VP-026: the Document Map Purpose cell and the VP-INDEX Summary Title cell. Corrected: two of three derived cells (ARCH-INDEX Document Map Purpose, ARCH-INDEX VP-INDEX Summary Title) aligned TO the canonical VP-026 H1 during the Pass 10 27-VP sweep; the VP-INDEX Title cell was already aligned (per VP-INDEX v0.1.5 — VP-026 does not appear in the "already aligned" inventory explicitly, but ARCH-INDEX v0.1.12 records drift only for Document Map Purpose and VP-INDEX Summary Title, not VP-INDEX Title). [audit-trail]

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS3-S1:** VP-026 counterexample wording corrected from present-tense to past-tense per the event_type naming convention (SS-17, ADR-009). ARCH-INDEX v0.1.4 entry records: "VP-026 counterexample wording corrected from present-tense to past-tense per the event_type naming convention (SS-17, ADR-009)." [audit-trail]
- **F-PASS10-C1/I1 (27-VP H1 canonical-baseline sweep):** Two of three derived cells (ARCH-INDEX Document Map Purpose, ARCH-INDEX VP-INDEX Summary Title) aligned TO the canonical VP-026 H1 during the Pass 10 27-VP sweep; the VP-INDEX Title cell was already aligned. ARCH-INDEX v0.1.12 entry records drift resolved for VP-026 Document Map Purpose and VP-INDEX Summary Title cells. [audit-trail]
