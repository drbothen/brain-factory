# AC-012 through AC-015: 50K-Token Chunk Warning (BC-2.02.005)

BC: BC-2.02.005 — advisory warning when source exceeds 50K-token threshold
Script: `plugins/brain-factory/scripts/check-token-threshold.sh`
Test file: `plugins/brain-factory/tests/skills.bats`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-012 | Advisory emitted with exact wording when word-estimate exceeds threshold |
| AC-013 | Warning is advisory only — exit 0 regardless; ingest proceeds |
| AC-014 | Content at or below threshold (== 50000 included) triggers no warning |
| AC-015 | Absent `max_ingest_tokens_per_chunk` in policies.yaml → default 50000 used |

## Evidence

### AC-012 + AC-013: Advisory emitted on overage, exit 0 (advisory only)

Source: ~50000-word body (estimated 65000 tokens = 50000 * 1.3, exceeds threshold)

Stdout:
```
{"estimated_tokens":65000,"threshold":50000,"exceeds":true}
{"level":"warn","code":"E-INGEST-013","message":"Source content estimated at 65000 tokens, exceeding the 50000-token chunk threshold. Full content ingested in v0.1. Automatic chunking available at v0.5+. Consider splitting large sources manually."}
```

Stderr (structured event):
```
{"ts":"2026-05-30T18:43:13Z","event_type":"ingest.url.token_threshold_exceeded","hook_name":"check-token-threshold.sh","trace":"698715f0-395a-4e3d-aadf-439b4f48082c","estimated_tokens":"65000","threshold":"50000","source_file":"<path>"}
```

Exit: 0 — confirms AC-013: advisory only, does not block ingest.

Advisory message matches AC-012 exact wording:
"Source content estimated at <N> tokens, exceeding the <threshold>-token chunk threshold.
Full content ingested in v0.1. Automatic chunking available at v0.5+. Consider splitting
large sources manually."

### AC-014: Below-threshold content triggers no warning

Source: 8-word body (estimated 0 tokens, well below 50000)

Stdout: `{"estimated_tokens":0,"threshold":50000,"exceeds":false}`
No E-INGEST-013 warning in output.
Exit: 0

The implementation uses a strictly-greater-than comparison: `[ "$ESTIMATED_TOKENS" -gt "$THRESHOLD" ]`
which means threshold == 50000 does NOT trigger the warning (exclusive boundary per AC-014).

### AC-015: Default 50000 when policies.yaml key absent

Bats coverage (direct bats assertions, not manual demos):
```
ok 9 BC_2_02_005: check-token-threshold.sh uses default 50000 when key absent from policies.yaml (AC-015)
ok 10 BC_2_02_005: check-token-threshold.sh uses default 50000 when policies.yaml absent entirely (AC-015)
```

Test 9: policies.yaml exists but `max_ingest_tokens_per_chunk` key is absent.
Test 10: no policies.yaml file at all.
Both assert that threshold defaults to 50000 and the script exits 0.

## Token heuristic implementation

Word count × 1.3 tokens/word via `awk`:
```bash
BODY_WORDS="$(awk '... skip frontmatter ...' "$SOURCE_FILE" | wc -w | tr -d ' ')"
ESTIMATED_TOKENS="$(awk -v words="$BODY_WORDS" 'BEGIN { printf "%d", words * 1.3 }')"
```

Frontmatter is stripped before counting (awk skips content between `---` fences),
ensuring the YAML header does not inflate the token estimate.

## Lint evidence

```
ok 16 BC_2_02_005: scripts/check-token-threshold.sh passes shellcheck (structural Red Gate)
ok 19 BC_2_02_005: scripts/check-token-threshold.sh passes shfmt normalization (structural Red Gate)
```
