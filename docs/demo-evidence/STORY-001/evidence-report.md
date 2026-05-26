# Demo Evidence Report — STORY-001

**Story:** Plugin scaffold — directory structure, manifest, and hook registry  
**Date:** 2026-05-25  
**Product type:** CLI / bash plugin (shell command evidence)  
**Verdict:** ALL ACs PASS

---

## AC-001 — plugin.json exists, valid JSON, all required fields, semver version

**Commands:**
```bash
jq -e '.' plugins/brain-factory/.claude-plugin/plugin.json
jq -r '.version' plugins/brain-factory/.claude-plugin/plugin.json
jq -e '.name and .displayName and .version and .description and .author and .license and .keywords and .skills and .agents and .hooks' \
    plugins/brain-factory/.claude-plugin/plugin.json
```

**Output:**
```
{
  "name": "brain-factory",
  "displayName": "Brain Factory",
  "version": "0.1.0",
  "description": "LLM-maintained second brain plugin for Claude Code",
  "author": { "name": "Josh Magady" },
  "license": "MIT",
  "keywords": ["second-brain", "obsidian", "knowledge-management", "rag", "agents"],
  "skills": "./skills/",
  "agents": ["./agents/"],
  "hooks": "hooks/hooks.json"
}

0.1.0

true
```

**Verdict: PASS** — plugin.json is valid JSON, version is semver `0.1.0`, all required fields present.

---

## AC-002 — 26 skill dirs and 14 agent dirs

**Commands:**
```bash
find plugins/brain-factory/skills -mindepth 1 -maxdepth 1 -type d | wc -l
find plugins/brain-factory/agents -mindepth 1 -maxdepth 1 -type d | wc -l
```

**Output:**
```
26
14
```

**Verdict: PASS** — Exactly 26 skill directories and 14 agent directories found.

---

## AC-003 — hooks.json with 13 entries, all using ${CLAUDE_PLUGIN_ROOT}

**Commands:**
```bash
jq '[.. | strings | select(endswith(".sh"))] | length' plugins/brain-factory/hooks/hooks.json
grep -c 'CLAUDE_PLUGIN_ROOT' plugins/brain-factory/hooks/hooks.json
jq '.hooks | keys' plugins/brain-factory/hooks/hooks.json
```

**Output:**
```
13

13

[
  "PostToolUse",
  "PreToolUse",
  "SessionStart",
  "Stop"
]
```

**Verdict: PASS** — hooks.json contains exactly 13 hook script entries, all 13 use `${CLAUDE_PLUGIN_ROOT}`, and uses the 4 expected event-type keys.

---

## AC-004 — All hook paths reference existing .sh files

**Command:**
```bash
for cmd in $(jq -r '[.. | strings | select(endswith(".sh"))] | .[]' plugins/brain-factory/hooks/hooks.json); do
  rel="${cmd#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  echo -n "$rel: "
  test -f "plugins/brain-factory/$rel" && echo "EXISTS" || echo "MISSING"
done
```

**Output:**
```
hooks/brain-health-check.sh: EXISTS
hooks/quarantine-fetch.sh: EXISTS
hooks/enforce-kebab-case.sh: EXISTS
hooks/block-ai-attribution.sh: EXISTS
hooks/validate-source-immutability.sh: EXISTS
hooks/validate-wikilink-integrity.sh: EXISTS
hooks/validate-index-log-coherence.sh: EXISTS
hooks/validate-frontmatter-schema.sh: EXISTS
hooks/validate-page-type-policy.sh: EXISTS
hooks/validate-voice-avoid-list.sh: EXISTS
hooks/validate-source-id-citation.sh: EXISTS
hooks/validate-publish-state.sh: EXISTS
hooks/flush-state-and-commit.sh: EXISTS
```

**Verdict: PASS** — All 13 hook script paths resolve to existing `.sh` files. No MISSING entries.

---

## AC-005 — Directory structure complete

**Command:**
```bash
for dir in .claude-plugin skills agents hooks hooks/lib workflows templates \
    templates/github-action-templates rules bin tests tests/fixtures; do
  echo -n "plugins/brain-factory/$dir/: "
  test -d "plugins/brain-factory/$dir" && echo "EXISTS" || echo "MISSING"
done
```

**Output:**
```
plugins/brain-factory/.claude-plugin/: EXISTS
plugins/brain-factory/skills/: EXISTS
plugins/brain-factory/agents/: EXISTS
plugins/brain-factory/hooks/: EXISTS
plugins/brain-factory/hooks/lib/: EXISTS
plugins/brain-factory/workflows/: EXISTS
plugins/brain-factory/templates/: EXISTS
plugins/brain-factory/templates/github-action-templates/: EXISTS
plugins/brain-factory/rules/: EXISTS
plugins/brain-factory/bin/: EXISTS
plugins/brain-factory/tests/: EXISTS
plugins/brain-factory/tests/fixtures/: EXISTS
```

**Verdict: PASS** — All 12 required directories exist. No MISSING entries.

---

## AC-006 — All bats tests pass

**Command:**
```bash
bats plugins/brain-factory/tests/upgrade.bats
```

**Output:**
```
1..32
ok 1 BC_2_14_004: plugin.json exists and is valid JSON
ok 2 BC_2_14_004: plugin.json has required top-level fields
ok 3 BC_2_14_004: plugin.json version matches semver pattern
ok 4 BC_2_14_004: plugin.json name is brain-factory
ok 5 BC_2_14_004: 26 skill directories exist under skills/
ok 6 BC_2_14_004: 14 agent directories exist under agents/
ok 7 BC_2_14_005: hooks.json exists and is valid JSON
ok 8 BC_2_14_005: hooks.json has exactly 13 hook script entries
ok 9 BC_2_14_005: all 13 hook paths use ${CLAUDE_PLUGIN_ROOT}
ok 10 BC_2_14_003: no hardcoded absolute paths in hooks.json
ok 11 BC_2_14_005: all hook paths in hooks.json reference existing .sh files
ok 12 BC_2_14_005: hooks.json has correct event type keys
ok 13 BC_2_14_005: quarantine-fetch is PreToolUse with WebFetch matcher
ok 14 BC_2_14_005: enforce-kebab-case is PreToolUse with Write|Edit matcher
ok 15 BC_2_14_005: block-ai-attribution is PreToolUse with Bash matcher
ok 16 BC_2_14_005: 8 PostToolUse validation hooks with Write|Edit matcher
ok 17 BC_2_14_005: flush-state-and-commit is Stop event
ok 18 BC_2_14_005: brain-health-check is SessionStart event
ok 19 BC_2_14_005: all hook entries have timeout field
ok 20 BC_2_14_003: required directory .claude-plugin/ exists
ok 21 BC_2_14_003: required directory skills/ exists
ok 22 BC_2_14_003: required directory agents/ exists
ok 23 BC_2_14_003: required directory hooks/ exists
ok 24 BC_2_14_003: required directory hooks/lib/ exists
ok 25 BC_2_14_003: required directory workflows/ exists
ok 26 BC_2_14_003: required directory templates/ exists
ok 27 BC_2_14_003: required directory templates/github-action-templates/ exists
ok 28 BC_2_14_003: required directory rules/ exists
ok 29 BC_2_14_003: required directory bin/ exists
ok 30 BC_2_14_003: required directory tests/ exists
ok 31 BC_2_14_003: required directory tests/fixtures/ exists
ok 32 BC_2_14_003: no hardcoded absolute paths in hooks/ skills/ agents/ or .claude-plugin/
```

**Verdict: PASS** — 32/32 bats tests pass. Zero failures, zero skips.

---

## AC-007 — No hardcoded absolute paths

**Command:**
```bash
grep -rE '/(Users|home)/[^ ]+' \
    plugins/brain-factory/hooks/ \
    plugins/brain-factory/skills/ \
    plugins/brain-factory/agents/ \
    plugins/brain-factory/.claude-plugin/ || echo "No hardcoded paths found"
```

**Output:**
```
No hardcoded paths found
```

**Verdict: PASS** — No hardcoded `/Users/...` or `/home/...` paths anywhere in hooks, skills, agents, or the plugin manifest.

---

## Summary

| AC | Description | Verdict |
|----|-------------|---------|
| AC-001 | plugin.json valid JSON, all required fields, semver version | PASS |
| AC-002 | 26 skill dirs and 14 agent dirs | PASS |
| AC-003 | hooks.json with 13 entries, all using `${CLAUDE_PLUGIN_ROOT}` | PASS |
| AC-004 | All hook paths reference existing .sh files | PASS |
| AC-005 | Directory structure complete (12 required dirs) | PASS |
| AC-006 | All 32 bats tests pass | PASS |
| AC-007 | No hardcoded absolute paths | PASS |

**Overall: 7/7 ACs PASS — STORY-001 evidence complete.**
