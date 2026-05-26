# STORY-016 Demo Evidence Report

## Summary

- **Story:** STORY-016 — Defuddle fetch wrapper, duplicate guard, and atomic manifest-write helper
- **BCs:** BC-2.02.001, BC-2.02.004, BC-2.02.006
- **VPs:** VP-012, VP-015
- **Tests:** 54/54 pass (`bats plugins/brain-factory/tests/ingest-url.bats`)
- **Lint:** shellcheck clean, shfmt-normalized (no diff)
- **Date:** 2026-05-26

## AC Evidence

### AC-001: defuddle-fetch.mjs exists and outputs cleaned markdown

**Traces to:** BC-2.02.001 precondition 2; invariant 1

**Test coverage (test-output.txt lines 2–7, 55):**
- `ok 1 BC_2_02_001: defuddle-fetch.mjs outputs cleaned markdown on exit 0 (happy path)`
- `ok 2 BC_2_02_001: defuddle-fetch.mjs contains Defuddle import and Node version check`
- `ok 3 BC_2_02_001: defuddle-fetch.mjs produces markdown to stdout for valid URL`
- `ok 4 BC_2_02_001: defuddle-fetch.mjs rejects file:// URL with E-INGEST-012`
- `ok 5 BC_2_02_001: defuddle-fetch.mjs rejects ftp:// URL with E-INGEST-012`
- `ok 6 BC_2_02_001: defuddle-fetch.mjs rejects data: URL with E-INGEST-012`
- `ok 54 BC_2_02_001: happy-path fixture URL produces source file with expected slug`

**Result:** PASS (7 tests)

---

### AC-002: Node 22+ absent emits E-INGEST-005 and exits 2

**Traces to:** BC-2.02.001 edge case EC-006

**Test coverage (test-output.txt lines 8–10):**
- `ok 7 BC_2_02_001_EC006: Node absent emits E-INGEST-005 and exits 2`
- `ok 8 BC_2_02_001_EC006: E-INGEST-005 message mentions Node 22+`
- `ok 9 BC_2_02_001_EC006: defuddle-fetch.mjs does not emit E-INGEST-005 on sufficient Node version`

**Result:** PASS (3 tests)

---

### AC-003: Non-200 HTTP response emits E-INGEST-002; no source file written

**Traces to:** BC-2.02.001 edge case EC-002

**Test coverage (test-output.txt lines 11–13):**
- `ok 10 BC_2_02_001_EC002: non-200 HTTP response emits E-INGEST-002 and exits 2`
- `ok 11 BC_2_02_001_EC002: E-INGEST-002 message mentions HTTP status and URL`
- `ok 12 BC_2_02_001_EC002: no source file written on non-200 response`

**Result:** PASS (3 tests)

---

### AC-004: Empty Defuddle output emits E-INGEST-003; no source file written

**Traces to:** BC-2.02.001 edge case EC-003

**Test coverage (test-output.txt lines 14–16):**
- `ok 13 BC_2_02_001_EC003: empty Defuddle output emits E-INGEST-003 and exits 2`
- `ok 14 BC_2_02_001_EC003: E-INGEST-003 message mentions page may not be extractable`
- `ok 15 BC_2_02_001_EC003: no source file written when Defuddle returns empty`

**Result:** PASS (3 tests)

---

### AC-005: Successful ingest creates sources/{topic}/{slug}.md with correct frontmatter

**Traces to:** BC-2.02.001 postcondition 1

**Test coverage (test-output.txt lines 17–23):**
- `ok 16 BC_2_02_001: successful ingest creates source file at sources/{topic}/{slug}.md`
- `ok 17 BC_2_02_001: source file has title frontmatter field`
- `ok 18 BC_2_02_001: source file has url frontmatter field matching ingested URL`
- `ok 19 BC_2_02_001: source file has ingested_at frontmatter in ISO 8601 format`
- `ok 20 BC_2_02_001: source file has source_id frontmatter matching the slug`
- `ok 21 BC_2_02_001: source file has topic frontmatter field`
- `ok 22 BC_2_02_001: source file has embedding_status: pending frontmatter field`

**Result:** PASS (7 tests)

---

### AC-006: quarantine-fetch.sh hook fires before Defuddle fetch

**Traces to:** BC-2.02.001 precondition 5; edge case EC-005

**Evidence:** The skill body in `plugins/brain-factory/skills/ingest-url/SKILL.md` invokes the
quarantine hook as a PreToolUse guard before any WebFetch call. The hook chain fires via the
Claude Code hooks mechanism, not directly invokable in a pure bats test without a live Claude Code
session. Structural evidence: the SKILL.md Procedure step for quarantine precedes the Defuddle fetch
step, and E-INGEST-004 is defined in the error taxonomy. Bats coverage for hook-event-emit.sh
(the event emission substrate used by quarantine-fetch.sh) is in `tests/hook-event-emit.bats`.

**Result:** STRUCTURAL PASS — quarantine hook wired in skill body; event substrate tested separately

---

### AC-007: Duplicate URL detected in manifest.json before any Defuddle fetch; exits 2 with E-INGEST-001

**Traces to:** BC-2.02.006 postconditions 1–3; invariant 1

**Test coverage (test-output.txt lines 24–27):**
- `ok 23 BC_2_02_006: duplicate URL in manifest exits 2 with E-INGEST-001`
- `ok 24 BC_2_02_006: E-INGEST-001 message names the existing slug`
- `ok 25 BC_2_02_006: ingest-url with fixture duplicate URL exits 2 (fixture test)`
- `ok 26 BC_2_02_006: defuddle-fetch.mjs is NOT called for a duplicate URL`

**Result:** PASS (4 tests)

---

### AC-008: Defuddle is NEVER called for a duplicate URL

**Traces to:** BC-2.02.006 invariant 1

**Test coverage (test-output.txt line 27):**
- `ok 26 BC_2_02_006: defuddle-fetch.mjs is NOT called for a duplicate URL`

Mock-based assertion: the bats test replaces `defuddle-fetch.mjs` with a mock that records
invocation count; asserts count = 0 when the URL is already in manifest.json.

**Result:** PASS (1 test — dedicated invocation-count assertion)

---

### AC-009: URL with different query string is treated as a new URL

**Traces to:** BC-2.02.006 edge case EC-001

**Test coverage (test-output.txt lines 28–29):**
- `ok 27 BC_2_02_006_EC001: URL with different query string is treated as new URL`
- `ok 28 BC_2_02_006_EC001: ingest proceeds for URL with additional query string`

**Result:** PASS (2 tests)

---

### AC-010: manifest-write.sh exists, appends entry atomically via .tmp+mv

**Traces to:** BC-2.02.004 postcondition 3; invariant 2

**Test coverage (test-output.txt lines 30–34, 51):**
- `ok 29 BC_2_02_004: manifest-write.sh sources successfully (library exists)`
- `ok 30 BC_2_02_004: manifest_write function returns 0 on valid entry and writable manifest`
- `ok 31 BC_2_02_004: manifest_write appends entry to manifest.json sources array`
- `ok 32 BC_2_02_004: manifest_write does NOT leave .tmp file behind after success (atomic)`
- `ok 33 BC_2_02_004: manifest_write fails with E-INGEST-008 when BRAIN_DIR is unset`
- `ok 50 VP_012: manifest_write uses atomic .tmp+mv pattern (no partial writes)`

**Result:** PASS (6 tests)

---

### AC-011: manifest.json new entry has all required fields; existing entries unchanged

**Traces to:** BC-2.02.004 postconditions 1–2; BC-2.02.001 postcondition 2

**Test coverage (test-output.txt lines 35–42):**
- `ok 34 BC_2_02_004: manifest entry has source_id field after ingest`
- `ok 35 BC_2_02_004: manifest entry has url field matching ingested URL`
- `ok 36 BC_2_02_004: manifest entry has topic field`
- `ok 37 BC_2_02_004: manifest entry has ingested_at field in ISO 8601 format`
- `ok 38 BC_2_02_004: manifest entry has last_ingest field in ISO 8601 format`
- `ok 39 BC_2_02_004: manifest entry has chunks array (empty on first ingest)`
- `ok 40 BC_2_02_004: manifest entry has embeddings_model field (null on first ingest)`
- `ok 41 BC_2_02_004: second ingest does not modify first entry (existing entries unchanged)`

**Result:** PASS (8 tests)

---

### AC-012: Duplicate guard reads manifest.json only; no sources/ directory scan

**Traces to:** BC-2.02.004 postcondition 1; invariant 1

**Test coverage (test-output.txt lines 43–44):**
- `ok 42 BC_2_02_004: duplicate guard reads manifest.json only — not sources/ dir`
- `ok 43 BC_2_02_004: manifest-only read — 10 orphan sources do not affect duplicate detection`

Test creates 10 source files NOT in manifest; asserts ingest does not read those files and correctly
treats the target URL as new.

**Result:** PASS (2 tests)

---

### AC-013: Manifest write failure → source file rolled back; E-INGEST-008 emitted

**Traces to:** BC-2.02.004 edge case EC-002

**Test coverage (test-output.txt lines 45–48):**
- `ok 44 BC_2_02_004_EC002: manifest write failure emits E-INGEST-008`
- `ok 45 BC_2_02_004_EC002: source file is deleted when manifest write fails (rollback)`
- `ok 46 BC_2_02_004_EC002: manifest.json is NOT corrupted when write fails`
- `ok 47 BC_2_02_004_EC002: _ingest_pipeline rollback deletes source file on manifest write failure`

**Result:** PASS (4 tests)

---

### AC-014: manifest-write.sh is shellcheck-clean; shfmt -d -i 2 produces no diff

**Traces to:** CLAUDE.md §Conventions

**Lint evidence (lint-output.txt):**
- `shellcheck plugins/brain-factory/hooks/lib/manifest-write.sh` → exit 0, no findings
- `shfmt -d -i 2 plugins/brain-factory/hooks/lib/manifest-write.sh` → exit 0, no diff

**Bats coverage (test-output.txt lines 49–50):**
- `ok 48 BC_2_02_004: manifest-write.sh passes shellcheck`
- `ok 49 BC_2_02_004: manifest-write.sh passes shfmt normalization`

**Result:** PASS (2 bats tests + direct lint clean)

---

## VP Evidence

| VP | Property | Tests | Result |
|----|----------|-------|--------|
| VP-012 | Manifest write is atomic (.tmp + mv; no partial writes) | `ok 50`, `ok 51` (test-output.txt lines 51–52) | PASS |
| VP-012 | manifest.json is valid JSON and contains written entry after manifest_write | `ok 51` (test-output.txt line 52) | PASS |
| VP-015 | manifest-write.sh sources hook-event-emit.sh | `ok 52` (test-output.txt line 53) | PASS |
| VP-015 | manifest_write emits ingest.url.manifest_updated or ingest.source.manifest_updated structured event | `ok 53` (test-output.txt line 54) | PASS |

---

## Coverage Summary

| AC | Tests | Path Type | Result |
|----|-------|-----------|--------|
| AC-001 | ok 1–6, ok 54 | success + protocol-rejection | PASS |
| AC-002 | ok 7–9 | error (Node absent) | PASS |
| AC-003 | ok 10–12 | error (non-200 HTTP) | PASS |
| AC-004 | ok 13–15 | error (empty output) | PASS |
| AC-005 | ok 16–22 | success (frontmatter fields) | PASS |
| AC-006 | structural | quarantine hook wiring | PASS |
| AC-007 | ok 23–26 | error (duplicate URL) | PASS |
| AC-008 | ok 26 | error (no Defuddle call) | PASS |
| AC-009 | ok 27–28 | edge-case (query string) | PASS |
| AC-010 | ok 29–32, ok 50 | success + atomic write | PASS |
| AC-011 | ok 34–41 | success (all fields; existing unchanged) | PASS |
| AC-012 | ok 42–43 | edge-case (no sources/ scan) | PASS |
| AC-013 | ok 44–47 | error (rollback on write failure) | PASS |
| AC-014 | ok 48–49 + lint | lint clean | PASS |

**Total: 54/54 tests pass. 0 failures. Lint clean.**
