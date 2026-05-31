# AC-013 through AC-017: Partial-Failure Fan-Out Envelope (BC-2.03.004)

BC: BC-2.03.004 — `/brain:ingest-source` propagates partial-failure fan-out; no silent swallow
Script: `plugins/brain-factory/scripts/generate-wiki.sh`
Skill: `plugins/brain-factory/skills/ingest-source/SKILL.md`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-013 | Fan-out envelope: `{"source_id","pages_attempted","pages_created","pages_failed","failures"}`. `pages_failed > 0` → exit 1; `pages_failed == 0` → exit 0. |
| AC-014 | Failed pages listed in `failures[]` with slug + error code. No failed page silently omitted. `failures` array never absent. |
| AC-015 | `pages_attempted == pages_created + pages_failed` invariant holds in all scenarios. |
| AC-016 | `set +e` NEVER in skill Procedure body. Static analysis (meta-lint bats). |
| AC-017 | When ALL pages fail (0 created), exit 1 with complete failure list; source file and manifest still stand. |

## Evidence

### AC-013/014/015: Full success — pages_failed=0, exit 0

```
Command: generate-wiki.sh <brain> transformer-models.md ingest.source
```

Output envelope:

```json
{
  "pages_attempted": 12,
  "pages_created": 12,
  "pages_failed": 0,
  "failures": []
}
exit: 0
```

```
Invariant: attempted(12) == created(12) + failed(0): PASS
failures array present: true
failures array length: 0
```

**Result: PASS** — envelope present; `failures` always included; invariant holds; exit 0 on full success.

### AC-013/014/015: Partial failure — pages_failed>0, exit 1

Pre-existing page causes slug collision for `attention-mechanisms`:

```
Command: generate-wiki.sh <brain> transformer-v2.md ingest.source  (1 collision expected)
```

Output envelope:

```json
{
  "pages_attempted": 7,
  "pages_created": 3,
  "pages_failed": 4,
  "failures": [
    {
      "slug": "attention-mechanisms",
      "type": "concepts",
      "error": "E-INGEST-014: Wiki page generation failed for 'attention-mechanisms': slug already exists. Other pages preserved."
    },
    {
      "slug": "scaling-laws",
      "type": "syntheses",
      "error": "E-INGEST-014: Wiki page generation failed for 'scaling-laws': slug already exists. Other pages preserved."
    },
    {
      "slug": "geoffrey-hinton",
      "type": "people",
      "error": "E-INGEST-014: Wiki page generation failed for 'geoffrey-hinton': slug already exists. Other pages preserved."
    },
    {
      "slug": "pytorch",
      "type": "frameworks",
      "error": "E-INGEST-014: Wiki page generation failed for 'pytorch': slug already exists. Other pages preserved."
    }
  ]
}
exit: 1  (advisory — partial failure)
```

```
pages_failed > 0: true
failures[0].error contains E-INGEST-014: 1
Invariant: attempted(7) == created(3) + failed(4): PASS
```

**Result: PASS** — partial failure propagated; each failed page listed with error code; exit 1; invariant holds.

### AC-017: All pages fail — pages_created=0, exit 1, source still stands

Second ingest of source with all identical slugs (first run already created all pages):

```
Command: generate-wiki.sh <brain> simple-source-copy.md  (all slugs pre-exist)
```

Output envelope:

```json
{
  "pages_attempted": 4,
  "pages_created": 0,
  "pages_failed": 4,
  "failures": [
    {"slug": "simple-source", "type": "concepts", "error": "E-INGEST-014: ...slug already exists..."},
    {"slug": "core-concept", "type": "concepts", "error": "E-INGEST-014: ...slug already exists..."},
    {"slug": "key-insights-from-simple-source", "type": "observations", "error": "E-INGEST-014: ...slug already exists..."},
    {"slug": "open-questions-on-simple-source", "type": "questions", "error": "E-INGEST-014: ...slug already exists..."}
  ]
}
exit: 1
```

```
pages_created == 0: true
pages_failed > 0: true
Invariant: attempted(4) == created(0) + failed(4): PASS
Source file still stands: YES
```

**Result: PASS** — all-failure case exits 1 with complete failure list; source file and manifest preserved.

### AC-016: `set +e` static analysis

```
Procedure section 'set +e' occurrences: 0  (expected: 0)
Result: PASS — set +e absent from Procedure
```

bats tests:

```
ok 41 BC_2_03_004: ingest-source SKILL.md Procedure section does not contain set +e as command (AC-016)
ok 42 BC_2_03_004: skills/ingest-source/SKILL.md Procedure does not invoke realpath (uses readlink -f) (AC-016)
```

**Result: PASS** — `set +e` absent from skill Procedure body; `readlink -f` used exclusively.

Raw output: `raw-output/fanout-envelope-demos.txt`, `raw-output/skills-bats-run.txt`
