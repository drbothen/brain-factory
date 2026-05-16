---
document_type: adr
id: ADR-015
title: "Source immutability: sha256 algorithm, storage location, verification cadence"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
timestamp: 2026-05-15T00:00:00
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-015: Source immutability hash algorithm

## Context

BC-2.06.001 requires that `sources/{topic}/{slug}.md` is immutable after creation. The primary enforcement mechanism is path-existence checking in manifest.json (ADR-008). A secondary audit mechanism (sha256 hash) provides tamper-evidence: if a source file is modified outside the hook chain (e.g., by a direct `git checkout` or an editor), the hash mismatch is detectable.

Two decisions are required:
1. Which hash algorithm to use (sha256 vs alternatives)
2. Where to store the hash and when to verify it

## Decision

### Hash algorithm: sha256

sha256 is chosen because:
- Available on all target platforms without additional installation (`shasum -a 256` on macOS; `sha256sum` on Linux)
- Collision-resistant for the tamper-evidence use case (not cryptographic signing — tamper-evidence for source files)
- Output format is consistent (64 hex characters) across platforms
- `sha256sum` / `shasum -a 256` are POSIX-standard tools; no npm, no Python required

Portability shim: `hooks/lib/sha256.sh` provides `compute_sha256 <path>` which selects the correct command:
```bash
compute_sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}
```

### Storage location: manifest.json sha256 field

Each source entry in manifest.json carries a `sha256` field (string). This field is populated when the source is first ingested:
```json
{
  "sources/ai/some-article.md": {
    "sha256": "abcdef1234...",
    ...
  }
}
```

The sha256 is computed over the source file's content at ingest time. It is NOT recomputed on every hook invocation (expensive); it is stored once and used for:
1. **Dispatcher-parity verification** (ADR-007): when v1.0 WASM hooks are validated, source file content is verified to be identical between bash and WASM runs
2. **Out-of-band tamper detection**: `/brain:health` scans source files for sha256 mismatches as part of its six-dimensional convergence check

### Verification cadence

- **At ingest time:** sha256 computed and stored in manifest.json. This is the "record" step.
- **At health-check time:** `/brain:health` verifies sha256 matches for sources in the last N days (configurable; default: 30). This is the "audit" step. Full-corpus sha256 verification is NOT done on every hook invocation (too expensive at 10K sources).
- **On explicit request:** `/brain:quarantine-check <path>` recomputes and verifies sha256 for a specific source file.

### Enforcement distinction

Block enforcement (BC-2.06.001, BC-2.04.002) is based on path-existence in manifest.json, NOT on sha256 comparison:
- A new write to an existing source path → BLOCKED (path exists in manifest.json → E-SOURCE-001)
- A new write to a new source path → ALLOWED (path absent from manifest.json → ingest proceeds)

The sha256 hash is an audit trail and a tamper-evidence record, not the enforcement mechanism. This distinction is deliberate: sha256 comparison would require reading the existing file on every PostToolUse hook invocation, adding latency. Path-existence check is O(1) via jq key lookup.

## Consequences

**Positive:**
- sha256 provides a cryptographically strong tamper-evidence record for the dispatcher-parity verification in v1.0
- Platform portability is handled by a single shim function in the shared lib
- Separating enforcement (path-existence) from audit (sha256) keeps hook latency low

**Negative:**
- Out-of-band edits (e.g., manual git operations) can modify source files without triggering the hook; the sha256 mismatch is only detected at health-check time, not immediately
- The sha256 field in manifest.json grows the manifest by ~70 bytes per source; at 10K sources this is ~700KB overhead — acceptable

**Neutral:**
- sha3, blake2, and other algorithms were considered; sha256 wins on availability (standard POSIX tooling) without a meaningful security tradeoff for tamper-evidence use cases

## References

- BC-2.06.001 (sources immutable after creation)
- BC-2.04.002 (validate-source-immutability.sh blocks overwrite)
- BC-2.01.006 (brain:health reports six-dimensional convergence state)
- ADR-007 (dispatcher-parity verification in v1.0)
- ADR-008 (wiki layer — source immutability enforcement flow)
- ADR-010 (manifest.json structure — sha256 field)
