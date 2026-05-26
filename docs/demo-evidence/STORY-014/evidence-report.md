---
document_type: demo-evidence-report
product: "brain-factory"
pipeline_run: "2026-05-26T01:30:00Z"
demo_type: "cli"
recording_tool: "vhs"
status: complete
---

# Demo Evidence Report

## Product: brain-factory
## Pipeline Run: 2026-05-26T01:30:00Z
## Story: STORY-014 — hook-event-emit.sh + Event Catalog

---

## Per-AC Demo Recordings

| AC | Story | Description | GIF | WEBM | Size (webm) | Status |
|----|-------|-------------|-----|------|-------------|--------|
| AC-001 | STORY-014 | emit_event and emit_verdict functions exist after sourcing hook-event-emit.sh | [gif](AC-001-emit-functions-exist.gif) | [webm](AC-001-emit-functions-exist.webm) | 28 KB | recorded |
| AC-002 | STORY-014 | emit_event writes JSONL to stderr with required fields (ts, event_type, hook_name, trace) | [gif](AC-002-emit-event-jsonl-stderr.gif) | [webm](AC-002-emit-event-jsonl-stderr.webm) | 62 KB | recorded |
| AC-004 | STORY-014 | Stream separation — emit_event stdout empty; emit_verdict stderr empty | [gif](AC-004-stream-separation.gif) | [webm](AC-004-stream-separation.webm) | 34 KB | recorded |
| AC-005 | STORY-014 | Credential fields (api_token, api_key) are masked as [REDACTED] | [gif](AC-005-credential-masking.gif) | [webm](AC-005-credential-masking.webm) | 36 KB | recorded |
| AC-006+007 | STORY-014 | event-catalog.json exists, valid JSON array, entries have required fields | [gif](AC-006-007-catalog-valid.gif) | [webm](AC-006-007-catalog-valid.webm) | 103 KB | recorded |
| AC-008 | STORY-014 | All event_type values follow domain.verb naming convention | [gif](AC-008-event-type-naming.gif) | [webm](AC-008-event-type-naming.webm) | 72 KB | recorded |
| AC-009+010 | STORY-014 | Catalog has 28 entries; all event_type values are unique | [gif](AC-009-010-count-uniqueness.gif) | [webm](AC-009-010-count-uniqueness.webm) | 31 KB | recorded |
| AC-013 | STORY-014 | All 28 example payloads parse as valid JSON | [gif](AC-013-example-payloads-valid.gif) | [webm](AC-013-example-payloads-valid.webm) | 60 KB | recorded |
| AC-014 | STORY-014 | shellcheck exits 0; shfmt -d produces no diff on hook-event-emit.sh | [gif](AC-014-shellcheck-shfmt.gif) | [webm](AC-014-shellcheck-shfmt.webm) | 30 KB | recorded |
| FULL | STORY-014 | Full bats test suite — 20/20 tests pass (hook-event-emit.bats + meta-lint.bats) | [gif](AC-full-test-suite.gif) | [webm](AC-full-test-suite.webm) | 680 KB | recorded |

---

## AC Coverage Summary

| AC | Covered By | Tape Source |
|----|-----------|-------------|
| AC-001: Functions exported | AC-001-emit-functions-exist | [tape](AC-001-emit-functions-exist.tape) |
| AC-002: JSONL on stderr with required fields | AC-002-emit-event-jsonl-stderr | [tape](AC-002-emit-event-jsonl-stderr.tape) |
| AC-003: ISO 8601 ts field | Covered by bats full suite (test 4) | [tape](AC-full-test-suite.tape) |
| AC-004: Stream separation | AC-004-stream-separation | [tape](AC-004-stream-separation.tape) |
| AC-005: Credential masking | AC-005-credential-masking | [tape](AC-005-credential-masking.tape) |
| AC-006: event-catalog.json exists and is valid JSON array | AC-006-007-catalog-valid | [tape](AC-006-007-catalog-valid.tape) |
| AC-007: All entries have required fields | AC-006-007-catalog-valid | [tape](AC-006-007-catalog-valid.tape) |
| AC-008: domain.verb naming convention | AC-008-event-type-naming | [tape](AC-008-event-type-naming.tape) |
| AC-009: 28 catalog entries | AC-009-010-count-uniqueness | [tape](AC-009-010-count-uniqueness.tape) |
| AC-010: All event_type values unique | AC-009-010-count-uniqueness | [tape](AC-009-010-count-uniqueness.tape) |
| AC-011: severity in {info,warn,error} | Covered by bats full suite (test 17) | [tape](AC-full-test-suite.tape) |
| AC-012: fields is a JSON array | Covered by bats full suite (test 12) | [tape](AC-full-test-suite.tape) |
| AC-013: example payloads are valid JSON | AC-013-example-payloads-valid | [tape](AC-013-example-payloads-valid.tape) |
| AC-014: shellcheck + shfmt clean | AC-014-shellcheck-shfmt | [tape](AC-014-shellcheck-shfmt.tape) |

---

## Full Bats Test Suite Results

All 20 bats tests pass across both suites:

- `plugins/brain-factory/tests/hook-event-emit.bats` — 10 tests
- `plugins/brain-factory/tests/meta-lint.bats` — 10 tests

```
1..20
ok 1 BC_2_04_017: hook-event-emit.sh exports emit_event function
ok 2 BC_2_04_017: hook-event-emit.sh exports emit_verdict function
ok 3 BC_2_04_017: emit_event writes JSONL to stderr with ts, event_type, hook_name, trace
ok 4 BC_2_04_017: emit_event ts field is ISO 8601 format
ok 5 VP_017: emit_event produces no stdout output
ok 6 VP_017: emit_verdict produces no stderr output
ok 7 VP_017: emit_verdict writes JSON to stdout
ok 8 BC_2_04_017: emit_event masks credential values
ok 9 BC_2_04_017: emit_event includes extra key-value fields
ok 10 BC_2_04_017_EC001: missing helper emits fallback JSONL and exits 2
ok 11 BC_2_17_002: event-catalog.json exists and is valid JSON array
ok 12 BC_2_17_002: all catalog entries have event_type, hook_name, severity, fields, example
ok 13 BC_2_17_002: all event_type values match domain.verb pattern
ok 14 BC_2_17_001: catalog has at least 27 event entries
ok 15 BC_2_17_001: all event_type values are unique
ok 16 BC_2_17_002: all example payloads are valid JSON
ok 17 BC_2_17_002: severity values are info, warn, or error
ok 18 VP_008: all emit_event call sites have matching catalog entries
ok 19 BC_2_04_017: hook-event-emit.sh passes shellcheck
ok 20 BC_2_04_017: hook-event-emit.sh passes shfmt
```

---

## Toolchain

| Tool | Version | Status |
|------|---------|--------|
| VHS | 0.10.0 | installed |
| bats | 1.x | installed |
| shellcheck | 0.x | installed |
| shfmt | 3.x | installed |
| jq | 1.x | installed |

---

## Demo Helper Scripts

Demo scripts are in `scripts/` and are sourced by the tape files. They use standard shell
constructs that avoid VHS parser limitations (no curly braces in Type arguments).

| Script | AC |
|--------|-----|
| [scripts/demo-ac-001.sh](scripts/demo-ac-001.sh) | AC-001 |
| [scripts/demo-ac-002.sh](scripts/demo-ac-002.sh) | AC-002 |
| [scripts/demo-ac-004.sh](scripts/demo-ac-004.sh) | AC-004 |
| [scripts/demo-ac-005.sh](scripts/demo-ac-005.sh) | AC-005 |
| [scripts/demo-ac-006-007.sh](scripts/demo-ac-006-007.sh) | AC-006+007 |
| [scripts/demo-ac-008.sh](scripts/demo-ac-008.sh) | AC-008 |
| [scripts/demo-ac-009-010.sh](scripts/demo-ac-009-010.sh) | AC-009+010 |
| [scripts/demo-ac-013.sh](scripts/demo-ac-013.sh) | AC-013 |
| [scripts/demo-ac-014.sh](scripts/demo-ac-014.sh) | AC-014 |

---

## PR Embedding Snippet

```markdown
## Demo Evidence — STORY-014

| AC | Recording |
|----|-----------|
| AC-001: Functions exported | ![AC-001](docs/demo-evidence/STORY-014/AC-001-emit-functions-exist.gif) |
| AC-002: JSONL on stderr | ![AC-002](docs/demo-evidence/STORY-014/AC-002-emit-event-jsonl-stderr.gif) |
| AC-004: Stream separation | ![AC-004](docs/demo-evidence/STORY-014/AC-004-stream-separation.gif) |
| AC-005: Credential masking | ![AC-005](docs/demo-evidence/STORY-014/AC-005-credential-masking.gif) |
| AC-006+007: Catalog valid | ![AC-006-007](docs/demo-evidence/STORY-014/AC-006-007-catalog-valid.gif) |
| AC-008: Naming convention | ![AC-008](docs/demo-evidence/STORY-014/AC-008-event-type-naming.gif) |
| AC-009+010: Count+Unique | ![AC-009-010](docs/demo-evidence/STORY-014/AC-009-010-count-uniqueness.gif) |
| AC-013: Example payloads | ![AC-013](docs/demo-evidence/STORY-014/AC-013-example-payloads-valid.gif) |
| AC-014: lint clean | ![AC-014](docs/demo-evidence/STORY-014/AC-014-shellcheck-shfmt.gif) |
| Full test suite (20/20) | ![FULL](docs/demo-evidence/STORY-014/AC-full-test-suite.gif) |
```

---

## Notes

- WebM is the primary format (best compression, GitHub supports playback)
- GIF fallback for inline embedding in PR descriptions and READMEs
- All demos run from worktree root `/Users/jmagady/Dev/brain-factory/.worktrees/STORY-014`
- Helper scripts in `scripts/` avoid VHS parser limitations with curly braces and commas in jq expressions
- AC-003 (ISO 8601 ts), AC-011 (severity enum), AC-012 (fields array) are covered by the full bats suite recording
