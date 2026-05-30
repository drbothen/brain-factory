---
artifact_type: story
story_id: STORY-044
epic_id: EPIC-02
title: "BC-2.04.016 v1.6 PC2 verdict-text harmonization to ADR-002 v2.0 continue/decision format"
status: draft
created: 2026-05-30
tdd_mode: strict
phase: 3
points: 2
priority: P1
subsystems: [SS-04]
behavioral_contracts: [BC-2.04.016]
vps: []
dependencies: []
blocks: []
inputs:
  - behavioral-contracts/ss-04/BC-2.04.016.md
  - specs/architecture/adr/ADR-002-hook-output-format.md
input-hash: ""
# Origin: D-PASS8-CS-03 — Wave 4 Gate 3 adversary finding M01 (also tracked as decision D-PASS8-CS-03).
# Canonical Principle Rule 3 anchor: explicit filing authorized as follow-up story at Wave 4 Gate 3
# (Wave 4 Gate 3 fix burst 2026-05-30). Concrete dependency: product-owner sweep of BC-2.04.016 PC2
# prose against ADR-002 v2.0 format. Wave 5 or next PO maintenance sweep is the earliest anchor.
---

# STORY-044: BC-2.04.016 v1.6 PC2 verdict-text harmonization to ADR-002 v2.0 format

## Goal

Harmonize BC-2.04.016 Postcondition 2 prose with ADR-002 v2.0 hook output format. The current PC2 text references the deprecated `{"verdict":"allow|advise|block",...}` schema. All hook implementations use ADR-002 v2.0 `{"continue":true/false,"decision":"allow|advise|block",...}` format, but BC-2.04.016 v1.5 PC2 still cites the old `verdict` key.

## Background

- BC-2.04.016 is the universal hook I/O contract BC (every hook reads JSON from stdin, writes JSON verdict to stdout, exits 0/1/2).
- ADR-002 v2.0 updated the stdout schema from `{"verdict":"..."}` to `{"continue":...,"decision":...,"hookSpecificOutput":...}`.
- Wave 4 STORY-015 delivery closed the implementation gap (all 13 hooks emit ADR-002 v2.0 format, tested in hook-contracts.bats), but the BC-2.04.016 PC2 prose was not swept.
- Wave 4 Gate 3 adversary finding M01 (also D-PASS8-CS-03) identified this as a spec-vs-spec consistency defect. Deferred as out-of-STORY-015-scope with explicit story anchor per Canonical Principle Rule 3.

## Acceptance Criteria

- AC-001: BC-2.04.016 v1.6 Postcondition 2 prose uses `{"continue":true/false,"decision":"allow|advise|block",...}` format aligned with ADR-002 v2.0. The deprecated `verdict` key is removed.
- AC-002: BC-2.04.016 v1.6 Canonical Test Vectors table updated to reflect ADR-002 v2.0 stdout examples (not `verdict`-keyed).
- AC-003: Sibling-sweep of all BC files that reference `{"verdict":...}` in Postconditions or Test Vectors to confirm no other BCs carry the deprecated format (or document any that do as separate follow-up stories).
- AC-004: BC-INDEX v0.1.NNN updated with BC-2.04.016 v1.6 version entry and POL-14 note.

## Owner

product-owner

## Traceability

- Origin: D-PASS8-CS-03 (Wave 4 Gate 3 adversary finding M01 / STORY-015 Pass 8 cross-story deferral)
- Deferred from: STORY-015 delivery (out-of-scope per correct-agent-routing principle — BC spec content is product-owner domain)
- Target wave: Wave 5 PO maintenance sweep or Wave 5 gate

## Changelog

### v0.1 (2026-05-30)

STORY-044 filed as follow-up story stub per Wave 4 Gate 3 fix burst (closes D-PASS8-CS-03 deferral with explicit story anchor per Canonical Principle Rule 3).
