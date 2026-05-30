# AC-015: Lint Clean (shellcheck + shfmt)

AC: AC-015
BC: CLAUDE.md §Conventions — shellcheck clean + shfmt-normalized
Test: Direct tool invocation (not a bats test — shellcheck/shfmt are run directly)

## shellcheck

Command:
  `shellcheck plugins/brain-factory/hooks/*.sh plugins/brain-factory/hooks/lib/*.sh`

Result: zero output, exit code 0.
Confirmed by: `raw-output/shellcheck-run.txt` containing only the "clean" annotation.

## shfmt

Command:
  `shfmt -d -i 2 plugins/brain-factory/hooks/*.sh plugins/brain-factory/hooks/lib/*.sh`

Result: zero output (no diff), exit code 0.
Confirmed by: `raw-output/shellcheck-run.txt` containing only the "clean" annotation.

## meta-lint enforcement of these constraints

Additionally, meta-lint.bats tests 9-10 run shellcheck and shfmt against the
`hook-event-emit.sh` helper specifically as part of the CI gate:

```
ok 9 BC_2_04_017: hook-event-emit.sh passes shellcheck
ok 10 BC_2_04_017: hook-event-emit.sh passes shfmt
```

This means shellcheck/shfmt conformance for the emit helper is enforced both:
1. Directly by AC-015 tool invocations
2. Structurally by meta-lint test 9-10 (will fail in CI if regressed)

## raw-output/shellcheck-run.txt content

```
shellcheck: 0 warnings (clean)
shfmt: 0 diffs (clean)
```
