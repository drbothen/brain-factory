---
document_type: adr
id: ADR-014
title: "Error taxonomy enforcement at hook layer"
status: accepted
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../ARCH-INDEX.md
supersedes: null
superseded_by: null
created: 2026-05-15
---

# ADR-014: Error taxonomy enforcement at hook layer

## Context

The error taxonomy (prd-supplements/error-taxonomy.md) defines 21 error scopes with E-SCOPE-NNN codes. Each hook script is responsible for emitting the correct error code in its verdict JSON. Without architectural enforcement, hooks can emit undefined codes or omit codes entirely, making error handling by skills and operators inconsistent.

## Decision

### Error code selection is deterministic (pure core)

Given a specific error condition in a hook, the correct E-SCOPE-NNN code is determined by the error taxonomy. This selection is a pure function: condition → code. It is not ambiguous.

Each hook script includes an inline comment block that lists the error codes it may emit and the conditions that trigger each:
```bash
# Error codes emitted by this hook:
# E-WIKI-001: wikilink [[slug]] not found in wiki/index.md
# E-WIKI-002: wikilink syntax malformed (missing closing brackets)
```

This comment block is validated by meta-lint (BC-2.18.002 extension): the `validate-error-taxonomy.sh` meta-lint check (a sub-case of the hook script validation surface) verifies that each code cited in the inline comment block exists in the canonical error taxonomy.

### Verdict JSON code field enforcement

Hook verdict JSON must include `code` and `message` when `verdict` is `advise` or `block`. The shared verdict-emit helper (in `hooks/lib/hook-event-emit.sh`, see ADR-016) enforces this: calling `emit_verdict block "E-SCOPE-NNN" "message"` is the only way to produce a block verdict. Calling `emit_verdict block "" ""` or omitting the code field causes the helper to exit 2 with an internal error — a crash-to-block that surfaces the implementation defect.

### 21 scope coverage

The 21 scopes (ADVERSARY, ATTR, FLUSH, HEALTH, HOOK, INGEST, INIT, LOBSTER, NAMING, PERF, POLICY, PUBLISH, QUARANTINE, RATE, RENAME, SCHEMA, SOURCE, UPGRADE, VOICE, WIKI, WRITE) are assigned to hooks as follows:
- QUARANTINE → quarantine-fetch.sh
- SOURCE → validate-source-immutability.sh
- WIKI → validate-wikilink-integrity.sh
- SCHEMA → validate-frontmatter-schema.sh, validate-page-type-policy.sh
- NAMING → enforce-kebab-case.sh
- ATTR → block-ai-attribution.sh
- VOICE → validate-voice-avoid-list.sh
- WRITE → validate-source-id-citation.sh, validate-index-log-coherence.sh
- PUBLISH → validate-publish-state.sh
- FLUSH → flush-state-and-commit.sh
- HEALTH → brain-health-check.sh
- HOOK → internal hook infrastructure errors (malformed stdin, helper crash)
- INGEST, INIT, LOBSTER, PERF, POLICY, RATE, RENAME, UPGRADE → emitted by skills (not hooks), documented in error-taxonomy.md

Hooks that do not emit error codes in the absence of errors simply exit 0 with `{"verdict": "allow", "trace": "..."}` — no code or message required.

## Consequences

**Positive:**
- Error codes are consistent across all hooks — operators and skills can pattern-match on `E-SCOPE-NNN` codes
- Inline comment blocks make each hook's error surface explicit and reviewable in PRs
- Verdict-emit helper prevents malformed verdicts from reaching Claude Code

**Negative:**
- The meta-lint validation of inline comment blocks requires parsing bash comments — this is a grep-based check, not a semantic analysis
- New error codes must be added to error-taxonomy.md before they can appear in a hook's comment block; this is a coordination requirement between product-owner and implementer

**Neutral:**
- Scopes not emitted by hooks (INGEST, INIT, LOBSTER, etc.) are still in the taxonomy — they're emitted by skills or by lobster-run

## References

- prd-supplements/error-taxonomy.md (21 scopes, full taxonomy)
- interface-definitions.md §2 (verdict JSON schema — code and message fields)
- ADR-002 (hook chain contract — verdict JSON)
- ADR-016 (hook-event-emit.sh including verdict emit helper)
- BC-2.04.016 (every hook reads JSON stdin, writes JSON stdout, exits 0/1/2 only)
