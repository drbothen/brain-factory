# AC-006, AC-007, AC-008: Six workflow YAML files (BC-2.12.003)

**Traces to:** BC-2.12.003 postconditions 1, 2, 3; invariants 1, 2
**Status:** PASS (all three ACs)

## AC-006: Exactly 6 workflow files exist

```
$ ls plugins/brain-factory/workflows/

brief-to-publish.yaml
daily-ritual.yaml
ingest-source.yaml
ingest-url.yaml
scale-test.yaml
weekly-refresh.yaml

$ find workflows -maxdepth 1 -name '*.yaml' | wc -l
6
```

PASS — exactly 6 `.yaml` files present; no more, no fewer (AC-006 upper and lower bound).

## AC-007: All 6 parse with yq + required schema fields

All 6 files pass `yq eval '.' <file>` with exit 0. Schema fields verified:

| File | name | description | steps count | steps[0].id | args type | depends_on type |
|------|------|-------------|-------------|-------------|-----------|-----------------|
| brief-to-publish.yaml | brief-to-publish | End-to-end pipeline... | 3 | draft-brief | !!seq | !!seq |
| daily-ritual.yaml | daily-ritual | Daily brain maintenance... | 3 | health-check | !!seq | !!seq |
| ingest-source.yaml | ingest-source | Ingest a local file... | 2 | ingest | !!seq | !!seq |
| ingest-url.yaml | ingest-url | Ingest a URL into the brain... | 2 | fetch-url | !!seq | !!seq |
| scale-test.yaml | scale-test | Scale validation corpus... | 3 | generate-corpus | !!seq | !!seq |
| weekly-refresh.yaml | weekly-refresh | Weekly brain synthesis... | 4 | synthesize | !!seq | !!seq |

All `name` and `description` fields: non-empty strings.
All `steps`: non-empty arrays (2–4 steps each).
All step `args` and `depends_on`: `!!seq` (array type).

PASS — AC-007.

## AC-008: .yaml extension, no .lobster files

```
$ ls workflows/*.lobster 2>/dev/null
(no output — no matches found)
```

PASS — zero `.lobster` files exist in `workflows/`. Extension is `.yaml` throughout.

## Bats tests

```
ok 119 BC_2_12_003: all 6 workflow files exist in plugins/brain-factory/workflows/ (AC-006)
ok 120 BC_2_12_003: all 6 workflow files parse with yq and contain required schema fields (AC-007)
ok 121 BC_2_12_003: no .lobster files in workflows/ — extension is .yaml not .lobster (AC-008)
```

## Raw output

`raw-output/ac-006-007-008-workflow-files.txt`
