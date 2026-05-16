---
document_type: prd-supplement
supplement_type: nfr-catalog
version: "0.1.0"
status: draft
producer: "vsdd-factory:product-owner"
timestamp: 2026-05-15T00:00:00
phase: phase-1b
traces_to: prd/index.md
created: 2026-05-15
---

# brain-factory NFR Catalog

NFRs are cross-cutting concerns that apply across subsystems. Each NFR has a numerical target and a validation method.

| NFR-ID | Category | Requirement | Numerical Target | Validation Method |
|--------|----------|-------------|-----------------|-------------------|
| NFR-001 | Performance | Hook p99 latency | < 100ms per hook invocation on canonical payload | bats hooks.bats latency assertion on GitHub Actions ubuntu-latest |
| NFR-002 | Performance | Init SLA | < 300 seconds wall-clock | `assert_under_5_minutes` in local-dev-test.sh |
| NFR-003 | Performance | `/brain:lint-wiki` on 10K-page wiki | < 600 seconds wall-clock | bats integration.bats scale test |
| NFR-004 | Performance | Ingest latency sub-linear growth | T(10K) / T(1K) ≤ 20 | bats integration.bats scale measurement |
| NFR-005 | Performance | Peak resident memory per operation | < 2GB on GitHub Actions ubuntu-latest | `/usr/bin/time -v` measurement in scale test |
| NFR-006 | Scale | Sources per day sustained | 100 sources/day over 5-day test without data loss | v0.9 scale test via gen-test-corpus.sh |
| NFR-007 | Scale | Token cost at 10K corpus | Average ≤ 150K input tokens per ingest | `.brain/logs/ingest-tokens.jsonl` aggregation in scale test |
| NFR-008 | Scale | Wiki size supported | ≥ 10,000 pages without structural change | v0.9 scale test |
| NFR-009 | Determinism | Hook output reproducibility | Same stdin payload → same stdout JSON + exit code (except `ts` and `trace` fields) | bats property test (parameterized re-run) |
| NFR-010 | Observability | Token cost visibility | 30-day trailing average computable from `.brain/logs/ingest-tokens.jsonl` at any time | `/brain:health` token alert; `/brain:monthly-perf` report |
| NFR-011 | Observability | Hook event completeness | Every hook invocation produces ≥ 1 JSONL event on stderr | bats hooks.bats stderr capture assertion |
| NFR-012 | Security | No credential leakage | 0 credential values (API keys, tokens) in any hook stdout/stderr/log | bats hooks.bats grep assertion on known-test-key pattern |
| NFR-013 | Security | Quarantine coverage | 100% of WebFetch calls pass through quarantine-fetch.sh | hooks.json.template registration + bats integration |
| NFR-014 | Portability | Cross-platform support | Hooks run on macOS + Linux strong; Git Bash + WSL2 partial (Windows-native = v1.0) | v0.9 ship gate: ≥ 1 operator on each of {macOS, Linux, Windows-via-Git-Bash-or-WSL2} |
| NFR-015 | Portability | Node 20+ compatibility | All Node scripts (`defuddle-fetch.mjs`, `run-skill.mjs`, `quarantine.mjs`) run on Node 20.x LTS | CI matrix: node-version: ['20'] |
| NFR-016 | Reliability | Hook fail-closed guarantee | If hook crashes or gets malformed stdin, it exits 2 (never exits 0 on error) | bats hooks.bats (inject error conditions; assert exit 2) |
| NFR-017 | Reliability | Source immutability | 0 overwrite-of-existing-source-record incidents in normal operation | `validate-source-immutability.sh` blocking + bats hooks.bats |
| NFR-018 | Reliability | Manifest atomicity | manifest.json write is atomic (tmp-file + mv pattern) | bats integration.bats (inject write failure mid-op; assert no partial manifest) |
| NFR-019 | Testability | bats suite count | Exactly 9 bats suites in plugins/brain-factory/tests/ | meta-lint.bats count assertion |
| NFR-020 | Testability | Hook coverage | Every hook has ≥ 3 test cases (positive + negative + edge) in hooks.bats | meta-lint.bats test-case count assertion |
| NFR-021 | Testability | shellcheck compliance | 0 shellcheck warnings in any hook script (-S style -e SC1090 baseline) | CI shellcheck run; pre-push gate |
| NFR-022 | Testability | shfmt compliance | 0 shfmt diff output (2-space indent normalization) | CI shfmt -d run; pre-push gate |
| NFR-023 | Maintainability | Filename immutability | 0 wiki filename renames via direct `mv` (must use /brain:rename-page) | `enforce-kebab-case.sh` + brain-factory-002 convention |
| NFR-024 | Maintainability | Plugin upgrade safety | `/brain:upgrade-brain` migration is idempotent | bats upgrade.bats (run twice; assert same outcome) |
| NFR-025 | Maintainability | Event catalog completeness | 0 hook-event:emit sites without a catalog row | meta-lint.bats cross-reference check |

---

## Self-Audit Checklist

- [x] All NFRs have numerical targets (no qualitative "should be fast" descriptions) — verified.
- [x] All validation methods are specific and testable — verified.
- [x] Three-file gate run before commit (see error-taxonomy.md for command).
