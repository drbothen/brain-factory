---
document_type: behavioral-contract
level: L3
version: "1.3"
status: draft
producer: "vsdd-factory:product-owner"
traces_to: ../BC-INDEX.md
timestamp: 2026-05-16T00:00:00
phase: phase-1b
origin: greenfield
subsystem: "SS-17"
capability: "CAP-017"
lifecycle_status: active
introduced: v0.1.0
modified: []
---

# Behavioral Contract BC-2.17.004: No hook emits tokens, API keys, or credential values to any output stream

## Description

Security constraint: hook scripts must never echo tokens, API keys, credential values, or any sensitive data to stdout, stderr, or any log file. The redact helper (forthcoming) provides a safe pattern for handling fields that may carry sensitive data. Any hook that processes credential-adjacent data must use the redact helper before emitting.

## Preconditions

1. Hook is executing and processes data that may contain credentials (e.g., `.brain/policies.yaml` which stores API keys).

## Postconditions

1. No value from a credential-carrying field (e.g., `linkedin_api_key`, `readwise_token`) appears in any hook output (stdout, stderr, or `.brain/logs/hooks-*.jsonl`).
2. Credential fields are replaced with `[REDACTED]` in any log output.

## Invariants

1. The redact helper is used at every callsite that processes credential-adjacent data.
2. The adversary independently verifies no credential leakage (TD-VSDD-059 paper-fix detection applies).

## Edge Cases

| ID | Description | Expected Behavior |
|----|-------------|-------------------|
| EC-001 | Hook reads policies.yaml which contains API key | The API key field value is never emitted to any stream. Only the field name may be logged (e.g., `"field": "linkedin_api_key", "value": "[REDACTED]"`). |

## Canonical Test Vectors

| Input | Expected Output | Category |
|-------|----------------|----------|
| Hook that reads policies.yaml with API key present | No API key value in stdout, stderr, or logs | security |

## Verification Properties

| VP-NNN | Property | Proof Method |
|--------|----------|-------------|
| VP-026 | No credential values in hook stdout | bats tests/hook-event-emit.bats (grep for known-test-key pattern) |
| VP-026 | No credential values in hook stderr | bats tests/hook-event-emit.bats |

## Traceability

| Field | Value |
|-------|-------|
| Capability Anchor Justification | CAP-017 ("Structured Event Catalog") per brief CLAUDE.md §Conventions ("No secrets in stdout/logs. Hook scripts must never echo tokens, API keys, or credential values."). |
| Architecture Module | SS-17: Structured Event Catalog |
| Stories | STORY-015 |
| Source Brief Section | product-brief.md CLAUDE.md §Conventions |

## Changelog

### v1.3 (2026-05-19)

**BACKFILL (F-PHASE2-ADV-PASS1-C04):** Bidirectional traceability backfilled: Stories field now cites STORY-015 per STORY-INDEX v0.3.2 reverse map. No semantic change to BC contract.

### v1.2 (2026-05-19)

**SWEEP FIX (F-PHASE2-DECOMP-GATE-I01-CASCADE):** BC body Verification Properties table swept to per-hook .bats convention per UD-006 + SS-18 v1.5. `bats hooks.bats` → `bats tests/hook-event-emit.bats` (credential redaction; 2 rows). No semantic change; only test-path strings updated.

### v1.1 (2026-05-16)

Initial content release.
