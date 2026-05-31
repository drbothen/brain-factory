# AC-003 and AC-004: PDF and Image File Type Handling (BC-2.03.001)

BC: BC-2.03.001 — edge case EC-002 (binary file handling)
Script: `plugins/brain-factory/scripts/validate-ingest-path.sh`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-003 | PDF files: if `pdftotext` available → extract text and proceed (exit 0); if unavailable → E-INGEST-010 exit 2 with advisory. |
| AC-004 | Image files (`.png`, `.jpg`, `.gif`, `.webp`, `.svg`) → E-INGEST-010 exit 2: "Image files cannot be ingested in v0.1. Convert to text or markdown first." |

## Evidence

### AC-003: PDF with pdftotext available — exit 0

```
Command: BRAIN_ROOT=<vault> PATH=<mock_bin>:PATH validate-ingest-path.sh <vault>/sources/ai/report.pdf
stdout: /private/<vault>/sources/ai/report.pdf
exit: 0
```

**Result: PASS** — pdftotext found on PATH; script accepts the PDF and returns resolved path.

### AC-003: PDF without pdftotext — E-INGEST-010 exit 2

```
Command: BRAIN_ROOT=<vault> PATH=<no_pdftotext> validate-ingest-path.sh report.pdf
stdout: {"level":"error","code":"E-INGEST-010","message":"PDF extraction requires poppler-utils (pdftotext). Install via your OS package manager or convert manually."}
exit: 2
```

**Result: PASS** — pdftotext absent; E-INGEST-010 emitted, exit 2, no file read.

### AC-004: Image file (.png) — E-INGEST-010 exit 2

```
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh diagram.png
stdout: {"level":"error","code":"E-INGEST-010","message":"Image files cannot be ingested in v0.1. Convert to text or markdown first."}
exit: 2
```

**Result: PASS** — image extension detected; E-INGEST-010 emitted, exit 2, no file read.

### bats coverage

```
ok 30 BC_2_03_001: PDF file with pdftotext on PATH exits 0 (AC-003)
ok 31 BC_2_03_001: PDF file without pdftotext emits E-INGEST-010 exit 2 (AC-003)
ok 32 BC_2_03_001: .png image file emits E-INGEST-010 exit 2 (AC-004)
ok 33 BC_2_03_001: .jpg image file emits E-INGEST-010 exit 2 (AC-004)
```

Raw output: `raw-output/validate-ingest-path-demos.txt` (DEMO 8, DEMO 9, DEMO 10), `raw-output/skills-bats-run.txt`
