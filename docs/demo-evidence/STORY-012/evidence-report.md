# Demo Evidence Report — STORY-012

**Story:** STORY-012 — enforce-kebab-case.sh + block-ai-attribution.sh
**Date:** 2026-05-27
**Branch:** feature/STORY-012
**Test results:** 43/43 bats tests pass (26 enforce-kebab-case + 17 block-ai-attribution)

---

## Per-AC Evidence

| AC | Tape File | Demonstrates | Status |
|----|-----------|-------------|--------|
| AC-001 | AC-016-lint-clean.tape | Hook contract: shebang, set -euo, no eval, explicit exits (verified via shellcheck + shfmt) | RECORDED |
| AC-002 | AC-002-kebab-valid-allow.tape | `wiki/concepts/ai-agents.md` → exit 0, `{"verdict":"allow",...}` | RECORDED |
| AC-003 | AC-003-kebab-invalid-block.tape | `wiki/concepts/AI Agents.md` → exit 2, E-NAMING-001, suggestion `ai-agents.md` | RECORDED |
| AC-004 | AC-003-kebab-invalid-block.tape | `wiki/concepts/ai_agents.md` → exit 2, E-NAMING-001, suggestion `ai-agents.md` (covered in same tape via underscore fixture) | RECORDED |
| AC-005 | AC-005-exempt-claude-md.tape | `CLAUDE.md` → exit 0 (exempt) | RECORDED |
| AC-006 | AC-005-exempt-claude-md.tape | All 7 exception-list files tested in bats suite (AC-SUITE-bats-all-green.tape shows full run) | RECORDED |
| AC-007 | AC-003-kebab-invalid-block.tape | Suggestion derivation: lowercase + s/ /-/g + s/_/-/g shown in output | RECORDED |
| AC-008 | AC-003-kebab-invalid-block.tape | JSONL stderr with `naming.kebab_case.rejected` and `naming.kebab_case.accepted` | RECORDED |
| AC-009 | AC-016-lint-clean.tape | Hook contract: shebang, set -euo, no eval, explicit exits (verified via shellcheck + shfmt) | RECORDED |
| AC-010 | AC-010-attribution-clean-allow.tape | `git commit -m "feat: add feature"` → exit 0, allow verdict | RECORDED |
| AC-011 | AC-011-attribution-coauthored-block.tape | Command with `Co-Authored-By: Claude Opus` → exit 2, E-ATTR-001 | RECORDED |
| AC-012 | AC-011-attribution-coauthored-block.tape | Robot emoji → exit 2, E-ATTR-001 (covered in bats parameterized test, visible in AC-SUITE tape) | RECORDED |
| AC-013 | AC-011-attribution-coauthored-block.tape | `Generated with Claude Code` → exit 2, E-ATTR-001 (covered in bats parameterized test, visible in AC-SUITE tape) | RECORDED |
| AC-014 | AC-SUITE-bats-all-green.tape | Single-pass scan for all 3 patterns shown in bats test run | RECORDED |
| AC-015 | AC-011-attribution-coauthored-block.tape | JSONL stderr with `attribution.token.blocked` and `attribution.token.cleared` | RECORDED |
| AC-016 | AC-016-lint-clean.tape | shellcheck exits 0; shfmt -d produces no diff on both scripts | RECORDED |

---

## Test Run Summary

```
enforce-kebab-case.bats: 26 tests, 0 failures
block-ai-attribution.bats: 17 tests, 0 failures
Total: 43/43 PASS
shellcheck: 0 warnings
shfmt -d: no diff
```

---

## Tape Files

| File | Description |
|------|-------------|
| `AC-002-kebab-valid-allow.tape` | VHS tape: valid kebab path → exit 0 |
| `AC-003-kebab-invalid-block.tape` | VHS tape: invalid filename (space + underscore) → exit 2 + suggestion |
| `AC-005-exempt-claude-md.tape` | VHS tape: CLAUDE.md exempt → exit 0 |
| `AC-010-attribution-clean-allow.tape` | VHS tape: clean commit → exit 0 |
| `AC-011-attribution-coauthored-block.tape` | VHS tape: attribution token → exit 2 + E-ATTR-001 |
| `AC-016-lint-clean.tape` | VHS tape: shellcheck + shfmt clean |
| `AC-SUITE-bats-all-green.tape` | VHS tape: full 43/43 bats run |

## Demo Scripts

| File | Description |
|------|-------------|
| `scripts/demo-ac002.sh` | Shell script driving AC-002 demo |
| `scripts/demo-ac003.sh` | Shell script driving AC-003 demo |
| `scripts/demo-ac005.sh` | Shell script driving AC-005 demo |
| `scripts/demo-ac010.sh` | Shell script driving AC-010 demo |
| `scripts/demo-ac011.sh` | Shell script driving AC-011 demo |
| `scripts/demo-ac016.sh` | Shell script driving AC-016 demo |

---

## Gate Status

- All 16 ACs have at least 1 recording (tape or bats suite tape)
- 7 dedicated tape files + 6 demo scripts
- Gate: PASS
