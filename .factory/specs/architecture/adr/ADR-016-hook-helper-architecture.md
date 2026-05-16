---
document_type: adr
id: ADR-016
title: "Hook helper architecture: hook-event-emit.sh, api-retry.sh, manifest-write.sh"
status: accepted
level: L3
version: "1.1"
producer: "vsdd-factory:architect"
timestamp: 2026-05-16T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-016: Hook helper architecture

## Context

Thirteen hook scripts share common logic: emitting structured events to stderr, generating trace UUIDs, writing JSON verdicts to stdout, handling API retries, and writing manifest entries atomically. Without shared helpers, this logic is duplicated across 13 scripts — a violation of the DRY principle and a maintenance burden.

Three helpers are needed:
1. `hook-event-emit.sh` — structured event emission to stderr + JSON verdict to stdout
2. `api-retry.sh` — exponential backoff for external API calls
3. `manifest-write.sh` — atomic manifest.json write (tmp-file + mv pattern)

## Decision

### hooks/lib/ directory

All shared helpers live in `plugins/brain-factory/hooks/lib/`. Individual hook scripts source them:
```bash
# At top of each hook script, after set -euo pipefail:
# shellcheck source=hooks/lib/hook-event-emit.sh
source "${CLAUDE_PLUGIN_ROOT}/hooks/lib/hook-event-emit.sh"
```

### hook-event-emit.sh

This is the most important helper. It provides:

**1. Trace UUID generation:**
```bash
generate_trace() {
  # Uses uuidgen on macOS; falls back to /proc/sys/kernel/random/uuid on Linux
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  elif [[ -f /proc/sys/kernel/random/uuid ]]; then
    cat /proc/sys/kernel/random/uuid
  else
    # Fallback: generate from /dev/urandom
    od -x /dev/urandom | head -1 | awk '{OFS="-"; print $2$3,$4,$5,$6,$7$8$9}'
  fi
}
```

**2. Structured event emission to stderr (JSONL):**
```bash
emit_event() {
  local event_type="$1"
  local severity="$2"
  local hook_name="$3"
  local trace="$4"
  shift 4
  # Additional k=v pairs as remaining args
  local ts; ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf '{"ts":"%s","event_type":"%s","severity":"%s","hook_name":"%s","trace":"%s"' \
    "$ts" "$event_type" "$severity" "$hook_name" "$trace" >&2
  # Append additional fields from remaining args
  while [[ $# -gt 0 ]]; do
    printf ',"%s":"%s"' "$1" "$2" >&2
    shift 2
  done
  printf '}\n' >&2
}
```

**3. JSON verdict emission to stdout:**
```bash
emit_verdict() {
  local verdict="$1"   # allow|advise|block
  local code="$2"      # E-SCOPE-NNN or empty for allow
  local message="$3"   # human-readable or empty for allow
  local trace="$4"     # uuid
  if [[ "$verdict" == "allow" ]]; then
    printf '{"verdict":"allow","trace":"%s"}\n' "$trace"
    return 0
  fi
  if [[ -z "$code" || -z "$message" ]]; then
    # Malformed verdict — emit internal error and block
    printf '{"verdict":"block","code":"E-HOOK-001","message":"emit_verdict called with missing code or message","trace":"%s"}\n' "$trace"
    exit 2
  fi
  printf '{"verdict":"%s","code":"%s","message":"%s","trace":"%s"}\n' \
    "$verdict" "$code" "$message" "$trace"
}
```

The hook script's main body calls `TRACE=$(generate_trace)` once at startup, then uses `$TRACE` in all `emit_event` and `emit_verdict` calls.

### api-retry.sh

Used by skills and GH Action scripts that call external APIs (LinkedIn, RSS feeds):
```bash
api_retry() {
  local max_attempts=3
  local delay=60
  local cmd=("$@")
  local attempt=1
  while [[ $attempt -le $max_attempts ]]; do
    if output="$("${cmd[@]}" 2>&1)"; then
      printf '%s' "$output"
      return 0
    fi
    local http_code; http_code="$(printf '%s' "$output" | grep -oP 'HTTP/\S+ \K\d+' | tail -1)"
    if [[ "$http_code" == "429" ]]; then
      local retry_after; retry_after="$(printf '%s' "$output" | grep -i 'retry-after:' | awk '{print $2}' | tr -d '\r')"
      [[ -n "$retry_after" ]] || retry_after=$((delay))
      sleep "$retry_after"
    else
      sleep "$delay"
      delay=$((delay * 2))
    fi
    attempt=$((attempt + 1))
  done
  # 3 attempts exhausted — exit 1 per BC-2.13.003
  return 1
}
```
BC-2.13.003 (rate-limit handling: 3 retries, 60s base, exponential 60/120/240s, exit 1 after
3 failures) is satisfied by this helper.

### manifest-write.sh

Provides atomic manifest.json write:
```bash
atomic_manifest_write() {
  local manifest_path="$1"
  local new_content="$2"
  local tmp; tmp="$(mktemp "${manifest_path}.XXXXXX")"
  printf '%s\n' "$new_content" > "$tmp"
  mv "$tmp" "$manifest_path"
}
```
NFR-018 (manifest atomicity) is satisfied by this helper.

### Hook stdin parsing

Each hook script parses stdin into local variables at startup:
```bash
INPUT="$(cat)"
TOOL="$(printf '%s' "$INPUT" | jq -r '.tool')"
INPUT_PATH="$(printf '%s' "$INPUT" | jq -r '.input.path // empty')"
```
Hooks that don't need a specific field simply don't parse it. jq parse failure → the hook exits 2 (fail-closed per NFR-016): `TOOL="$(printf '%s' "$INPUT" | jq -r '.tool')" || { emit_verdict block "E-HOOK-002" "malformed stdin" "$TRACE"; exit 2; }`.

## Consequences

**Positive:**
- Shared helpers eliminate logic duplication across 13 hook scripts
- emit_verdict prevents malformed verdicts (missing code/message) from reaching Claude Code
- api-retry.sh centralizes rate-limit handling — not duplicated in 19 GH Action templates
- manifest-write.sh makes atomic writes a one-liner for any script that touches manifest.json

**Negative:**
- shellcheck must be configured to understand `source "${CLAUDE_PLUGIN_ROOT}/..."` — this requires `# shellcheck source=...` annotations in each hook script
- The uuidgen fallback chain adds ~5 lines of platform detection to hook-event-emit.sh

**Neutral:**
- The helpers are part of the plugin tarball (included in hooks/lib/)
- meta-lint validates that each hook sources hook-event-emit.sh (BC-2.18.002 extension)

## api-retry.sh Delivery for GitHub Actions

ADR-013 states that all 19 GH Action templates invoke `api-retry.sh` for rate-limit
handling (BC-2.13.003). GH Actions runners do NOT have access to `${CLAUDE_PLUGIN_ROOT}`
paths at runtime because the plugin is installed in the user's local Claude Code session,
not in the Actions runner environment.

**Resolution:** `api-retry.sh` is delivered to GH Actions via a second canonical location:
`scripts/lib/api-retry.sh` (separate from `hooks/lib/api-retry.sh`). The GH Action
templates reference it via a repo-relative path (the operator's brain vault contains
a copy of `scripts/lib/api-retry.sh` installed by `/brain:install-actions`).

The `hooks/lib/api-retry.sh` version is used exclusively by hook scripts running in the
Claude Code session. The `scripts/lib/api-retry.sh` version is used exclusively by GH
Action templates. Both versions implement identical logic (same bash function body) and
are kept in sync by meta-lint (BC-2.18.003: structural equivalence check between the
two copies). This is a deliberate dual-copy pattern, not DRY violation — the deployment
contexts have incompatible `${CLAUDE_PLUGIN_ROOT}` resolution environments.

Rationale for not using a shared symlink or install-time substitution: GH Action YAML
files that reference scripts must use paths relative to `$GITHUB_WORKSPACE`, which maps
to the brain vault root. The hook context resolves `${CLAUDE_PLUGIN_ROOT}` at session
start; the GH Actions context has no equivalent resolver.

## References

- BC-2.04.015 (hook p99 < 100ms — emit_event must be fast)
- BC-2.04.016 (every hook reads JSON stdin, writes JSON stdout, exits 0/1/2)
- BC-2.04.017 (hook structured event emission via event catalog)
- BC-2.13.003 (rate-limit handling)
- NFR-016 (fail-closed guarantee — malformed stdin → exit 2)
- NFR-018 (manifest atomicity)
- ADR-002 (hook chain contract)
- ADR-014 (error taxonomy enforcement — emit_verdict with E-SCOPE-NNN codes)

## Changelog

### v1.1 (2026-05-16)

Content edits past initial creation detected (timestamp 2026-05-16T00:00:00 > created 2026-05-15). Changelog back-filled per F-PASS13-C2 architecture artifact Changelog discipline.

- **F-PASS3-I1:** `api-retry.sh` retry policy explicitly documented in §api-retry.sh: 3 retries maximum, 60-second base backoff interval, exit 1 advisory on retry exhaustion. Aligns with BC-2.13.003. [audit-trail]
- **F-1c-CV-06:** §api-retry.sh Delivery for GitHub Actions section added — clarifies the dual-copy delivery pattern: `hooks/lib/api-retry.sh` (Claude Code session context) and `scripts/lib/api-retry.sh` (GH Actions runner context). Rationale for deliberate dual-copy (not DRY violation) documented. [audit-trail]
