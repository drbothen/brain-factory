# AC-013 and AC-014: No Credential Leakage (BC-2.17.004)

BC: BC-2.17.004 — No hook emits tokens, API keys, or credential values to any output stream
Test files:
- Static: `plugins/brain-factory/tests/meta-lint.bats` (AC-013)
- Dynamic: `plugins/brain-factory/tests/hook-contracts.bats` Section 5 (AC-014)

## AC-013: No credential variable refs in emit_event/emit_verdict calls (meta-lint static scan)

Test name: `BC_2_17_004_AC013: no credential variable refs in emit_event or emit_verdict calls in any hook`
(test 15 in meta-lint.bats run)

The assertion extracts lines containing `emit_event` or `emit_verdict` (excluding
comment lines), then greps for variable patterns ending in `_TOKEN`, `_KEY`,
`_SECRET`, or `_PASSWORD` (case-insensitive suffix), in both `$VAR` and `${VAR}` forms.

Load-bearing assertion code:

```bash
local emit_lines
emit_lines="$(grep -nE 'emit_event|emit_verdict' "$sh_file" | grep -v '^\s*#' || true)"

local cred_hits
cred_hits="$(echo "$emit_lines" \
  | grep -iE '\$\{?[A-Za-z_][A-Za-z0-9_]*(_(TOKEN|KEY|SECRET|PASSWORD))\}?' \
  || true)"
```

This catches patterns like `$ANTHROPIC_API_KEY`, `$GITHUB_TOKEN`,
`${LINKEDIN_ACCESS_TOKEN}`, `$MY_SECRET`, etc., when they appear on emit call lines.
It does NOT flag non-emit lines (hooks can read these variables into local variables;
the constraint is that they must not pass them directly into emit calls).

Result: `ok 15 BC_2_17_004_AC013: no credential variable refs in emit_event or emit_verdict calls in any hook`

## AC-014: Sentinel injection — credential values absent from stdout and stderr

Test coverage in Section 5 (tests 58-71 in hook-contracts.bats run):

All 13 hooks are covered. The approach:
1. Build a credential-adjacent fixture by injecting synthetic sentinel values into
   the `tool_input.content` field (or `tool_input.command` for block-ai-attribution)
2. Run the hook with the injected fixture
3. Assert stdout does NOT contain `CRED_SENTINEL_KEY`
4. Assert stderr does NOT contain `CRED_SENTINEL_KEY`

Sentinel values used (fake, no real credentials):
- `CRED_SENTINEL_KEY = "sk-test-ABCDEF1234567890abcdef1234567890"`
- `CRED_SENTINEL_TOKEN = "ghp_FAKE_TOKEN_xyzXYZ999aaa"`

Load-bearing assertion code:

```bash
if echo "$stdout_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
  echo "FAIL: sentinel found in stdout of ${hook_name}" >&2
  return 1
fi
if echo "$stderr_out" | grep -qF "${CRED_SENTINEL_KEY}"; then
  echo "FAIL: sentinel found in stderr of ${hook_name}" >&2
  return 1
fi
```

Test 71 additionally exercises the `hook-event-emit.sh` helper directly, verifying
that the emit layer masks values matching credential key patterns to `[REDACTED]`:

```bash
@test "BC_2_17_004: emit_event credential masking — key matching *_key is redacted in stderr JSONL" {
  # ... sources the helper, calls emit_event with api_token=<sentinel> ...
  echo "$stderr_out" | grep -qF "[REDACTED]"
}
```

## Cross-cutting negative assertions (meta-lint tests 18-21)

These four meta-lint tests enforce the broader cross-cutting negative assertions
from CLAUDE.md §Meta-Lint Contract Surface 4. They are structurally enforced
for the `plugins/brain-factory/` source tree (not `.factory/` pipeline history,
which legitimately documents these patterns for audit purposes).

Test 18: `BC_2_17_004: no plugin source file contains Co-Authored-By: Claude`
Test 19: `BC_2_17_004: no plugin source file contains robot emoji`
Test 20: `BC_2_04_016: no plugin source file contains --no-verify`
Test 21: `BC_2_04_016: no plugin source file contains hardcoded .claude/templates/ path`

Load-bearing logic for test 18:

```bash
hits="$(git -C "$repo_root" ls-files -- "${plugin_dir}" 2>/dev/null \
  | grep -v 'block-ai-attribution' \
  | grep -v 'event-catalog.json' \
  | grep -v 'bash-ai-attribution' \
  | grep -v 'meta-lint.bats' \
  | xargs grep -lF 'Co-Authored-By: Claude' 2>/dev/null || true)"
if [ -n "$hits" ]; then
  ...
  return 1
fi
```

The git-tracked-files approach (`git ls-files`) prevents false positives from
untracked scratch files; the exemptions for `block-ai-attribution` and
`meta-lint.bats` are correct per the CLAUDE.md Meta-Lint Contract rationale
(the hook's domain logic is to detect this string; meta-lint is self-referential).

## bats TAP output (tests 58-71 from hook-contracts-run.txt and tests 15, 18-21 from meta-lint-run.txt)

hook-contracts.bats:
```
ok 58 BC_2_17_004: block-ai-attribution does not leak credential sentinel to stdout or stderr
ok 59 BC_2_17_004: validate-frontmatter-schema does not leak credential sentinel to stdout or stderr
ok 60 BC_2_17_004: validate-voice-avoid-list does not leak credential sentinel to stdout or stderr
ok 61 BC_2_17_004: validate-wikilink-integrity does not leak credential sentinel to stdout or stderr
ok 62 BC_2_17_004: brain-health-check does not leak credential sentinel to stdout or stderr
ok 63 BC_2_17_004: enforce-kebab-case does not leak credential sentinel to stdout or stderr
ok 64 BC_2_17_004: flush-state-and-commit does not leak credential sentinel to stdout or stderr
ok 65 BC_2_17_004: quarantine-fetch does not leak credential sentinel to stdout or stderr
ok 66 BC_2_17_004: validate-index-log-coherence does not leak credential sentinel to stdout or stderr
ok 67 BC_2_17_004: validate-page-type-policy does not leak credential sentinel to stdout or stderr
ok 68 BC_2_17_004: validate-publish-state does not leak credential sentinel to stdout or stderr
ok 69 BC_2_17_004: validate-source-id-citation does not leak credential sentinel to stdout or stderr
ok 70 BC_2_17_004: validate-source-immutability does not leak credential sentinel to stdout or stderr
ok 71 BC_2_17_004: emit_event credential masking — key matching *_key is redacted in stderr JSONL
```

meta-lint.bats:
```
ok 15 BC_2_17_004_AC013: no credential variable refs in emit_event or emit_verdict calls in any hook
ok 18 BC_2_17_004: no plugin source file contains Co-Authored-By: Claude
ok 19 BC_2_17_004: no plugin source file contains robot emoji
ok 20 BC_2_04_016: no plugin source file contains --no-verify
ok 21 BC_2_04_016: no plugin source file contains hardcoded .claude/templates/ path
```
