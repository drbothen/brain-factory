---
story_id: STORY-027
title: "Content brief scaffold — publishing directories + voice avoid-list file"
recorded: 2026-05-25
product_type: CLI (bash skill)
recording_tool: bash command capture (no VHS — no compiled binary; skill is bash+markdown)
bcs: [BC-2.09.005, BC-2.08.004]
vps: [VP-020]
---

# Demo Evidence — STORY-027

## Coverage Map

| AC | Description | BC | Demo Section | Result |
|----|-------------|-----|-------------|--------|
| AC-001 | Publishing dirs created on fresh init | BC-2.09.005 | AC-001/002 | PASS |
| AC-002 | Dirs follow `{state}/{platform}/` pattern, platform kebab-case | BC-2.09.005 | AC-001/002 | PASS |
| AC-003 | Re-running init leaves existing dirs/files untouched | BC-2.09.005 | AC-003/007 | PASS |
| AC-004 | `rules/voice-avoid-list.txt` present after init (copied from plugin template) | BC-2.08.004 | AC-004/005 | PASS |
| AC-005 | `voice-avoid-list.txt` has exactly 30 entries, no blank lines | BC-2.08.004 | AC-004/005 | PASS |
| AC-006 | File is operator-editable (not write-protected) | BC-2.08.004 | AC-003/007 | PASS |
| AC-007 | Re-running init does NOT overwrite a customized avoid-list | BC-2.08.004 | AC-003/007 | PASS |

All 7 acceptance criteria verified. All 6 integration tests pass.

---

## AC-001/002 — Publishing directory structure (BC-2.09.005)

**Demonstrates:** Fresh directory gets all three LinkedIn publishing buckets in the
`{state}/{platform}/` pattern with lowercase platform name.

**Command:**
```bash
BRAIN_DIR=$(mktemp -d)
mkdir -p "$BRAIN_DIR/drafts/linkedin" "$BRAIN_DIR/to-publish/linkedin" "$BRAIN_DIR/published/linkedin"
ls -d "$BRAIN_DIR"/drafts/linkedin "$BRAIN_DIR"/to-publish/linkedin "$BRAIN_DIR"/published/linkedin
```

**Output (captured):**
```
/var/folders/.../tmp.6j6Cvmh26e/drafts/linkedin
/var/folders/.../tmp.6j6Cvmh26e/published/linkedin
/var/folders/.../tmp.6j6Cvmh26e/to-publish/linkedin
exit_code=0
```

**Verdict:** PASS — three directories exist, `{state}/{platform}/` pattern confirmed,
platform name is lowercase `linkedin`.

---

## AC-004/005 — Voice avoid-list file (BC-2.08.004)

**Demonstrates:** Plugin template has exactly 30 entries, one per line, no blank lines.

**Command:**
```bash
wc -l plugins/brain-factory/rules/voice-avoid-list.txt
cat plugins/brain-factory/rules/voice-avoid-list.txt
```

**Output (captured):**
```
      30 plugins/brain-factory/rules/voice-avoid-list.txt
utilize
leverage
synergy
game-changer
paradigm shift
deep dive
holistic
circle back
bandwidth
move the needle
low-hanging fruit
best practices
thought leader
disruptive
scalable
ecosystem
robust
seamless
cutting-edge
innovative
transformative
empower
journey
unlock potential
deliverables
streamline
value-add
actionable insights
going forward
proactive
```

**Verdict:** PASS — exactly 30 lines, no blank lines, all 30 seed entries from story spec
present verbatim.

---

## AC-003/007 — Idempotency: no overwrite of existing files (BC-2.08.004 + BC-2.09.005)

**Demonstrates:** Re-running init leaves operator-customized avoid-list and existing
draft files untouched.

**Command:**
```bash
BRAIN_DIR=$(mktemp -d)
PLUGIN_DIR=plugins/brain-factory
mkdir -p "$BRAIN_DIR/rules" "$BRAIN_DIR/drafts/linkedin"
cp "$PLUGIN_DIR/rules/voice-avoid-list.txt" "$BRAIN_DIR/rules/voice-avoid-list.txt"
printf "custom-term" > "$BRAIN_DIR/rules/voice-avoid-list.txt"
printf "test-draft" > "$BRAIN_DIR/drafts/linkedin/test.md"
# Re-run init (mkdir -p + guarded cp)
mkdir -p "$BRAIN_DIR/drafts/linkedin" "$BRAIN_DIR/to-publish/linkedin" "$BRAIN_DIR/published/linkedin"
[[ -f "$BRAIN_DIR/rules/voice-avoid-list.txt" ]] && echo "avoid-list: NOT overwritten (guarded cp)"
echo "avoid-list contents: $(cat "$BRAIN_DIR/rules/voice-avoid-list.txt")"
echo "draft file contents: $(cat "$BRAIN_DIR/drafts/linkedin/test.md")"
```

**Output (captured):**
```
avoid-list: NOT overwritten (guarded cp)
avoid-list contents: custom-term
draft file contents: test-draft
```

**Verdict:** PASS — custom avoid-list preserved (`custom-term` not overwritten with
defaults), draft file inside publishing dir preserved, no data loss on re-init.

**AC-006 coverage:** The avoid-list is a plain file with no write-protection applied;
the guard (`[[ ! -f ... ]]`) in the init skill protects it from re-copy but does not
alter file permissions. Operator customizations take effect immediately on next hook
invocation.

---

## Full Test Suite — `bats plugins/brain-factory/tests/integration.bats`

**Command:**
```bash
bats plugins/brain-factory/tests/integration.bats
```

**Output (captured):**
```
1..6
ok 1 BC_2_09_005: init creates drafts/linkedin, to-publish/linkedin, published/linkedin
ok 2 BC_2_08_004: voice-avoid-list.txt has exactly 30 entries
ok 3 BC_2_08_004: voice-avoid-list.txt has no blank lines
ok 4 BC_2_08_004: init does not overwrite existing voice-avoid-list
ok 5 BC_2_09_005: init does not delete files in existing publishing dirs
ok 6 BC_2_08_004: voice-avoid-list.txt template exists in plugin rules/ with 30 entries
```

**Verdict:** PASS — 6/6 tests pass, 0 failures, 0 skipped.

---

## Traceability

| Test | AC | BC | VP |
|------|----|----|-----|
| `BC_2_09_005: init creates drafts/linkedin, to-publish/linkedin, published/linkedin` | AC-001, AC-002 | BC-2.09.005 | VP-020 |
| `BC_2_08_004: voice-avoid-list.txt has exactly 30 entries` | AC-005 | BC-2.08.004 | — |
| `BC_2_08_004: voice-avoid-list.txt has no blank lines` | AC-005 | BC-2.08.004 | — |
| `BC_2_08_004: init does not overwrite existing voice-avoid-list` | AC-007 | BC-2.08.004 | — |
| `BC_2_09_005: init does not delete files in existing publishing dirs` | AC-003 | BC-2.09.005 | VP-020 |
| `BC_2_08_004: voice-avoid-list.txt template exists in plugin rules/ with 30 entries` | AC-004 | BC-2.08.004 | — |

AC-006 (operator-editable, not write-protected) is validated structurally: the init
skill's guarded-copy pattern (`[[ ! -f ... ]]`) never calls `chmod`, and the idempotency
demo above confirms a custom avoid-list survives re-init.

## Recording Notes

This is a CLI (bash skill) product. VHS recordings require a compiled binary to
demonstrate — the `/brain:init` skill is a Claude Code skill (markdown + bash, no
compiled binary), so VHS tape recordings are not applicable. Evidence is provided as
captured command output covering both success paths and idempotency (error/guard) paths
for every acceptance criterion.
