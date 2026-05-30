---
artifact_type: cicd-setup
version: v1.0
project: brain-factory
created: "2026-05-25"
status: active
---

# CI/CD Setup — brain-factory

## Workflow Location

`.github/workflows/ci.yml`

## Trigger Configuration

| Event | Branches |
|-------|----------|
| `push` | `main`, `develop` |
| `pull_request` (target) | `main`, `develop` |

Concurrency group `${{ github.workflow }}-${{ github.ref }}` with `cancel-in-progress: true` ensures stale runs are cancelled when a new push arrives on the same branch.

## Jobs

### `lint` (ubuntu-22.04, timeout 10 min)

Runs shellcheck and shfmt against all hook scripts under `plugins/brain-factory/hooks/*.sh`. Both steps gracefully no-op when no hook scripts exist yet (Wave 1 bootstrap state), using `find` with a null-guard rather than a glob that would fail on an empty directory.

### `test` (ubuntu-22.04, timeout 15 min)

Installs jq, yq, and bats-core, then runs:
1. All `*.bats` files under `plugins/brain-factory/tests/` (full test suite)
2. `plugins/brain-factory/tests/meta-lint.bats` (factory self-audit)

Both steps gracefully no-op when the test directory or meta-lint file does not yet exist.

## Pinned Tool Versions

| Tool | Version | Source |
|------|---------|--------|
| shellcheck | 0.10.0 | GitHub releases (koalaman/shellcheck) |
| shfmt | 3.8.0 | GitHub releases (mvdan/sh) |
| jq | apt-get (ubuntu-22.04 default) | Ubuntu 22.04 package |
| yq | 4.43.1 | GitHub releases (mikefarah/yq) |
| bats-core | 1.11.0 | GitHub releases (bats-core/bats-core) |
| actions/checkout | SHA b4ffde65f46336ab88eb53be808477a3936bae11 (v4.1.1) | GitHub Actions marketplace |

All GitHub-hosted binaries are downloaded by version tag. The `actions/checkout` action is pinned to its full commit SHA (supply chain security — CLAUDE.md requirement).

## Branch Protection Recommendations

Apply these settings to the `develop` branch once the CI workflow is live and producing status checks:

```
Required status checks (strict):
  - CI / lint
  - CI / test

Require PR before merging: yes
Required approving reviews: 0 (single-dev project; CI is the gate)
Enforce admins: false
Restrictions: null
```

Apply with:

```bash
gh api repos/drbothen/brain-factory/branches/develop/protection -X PUT \
  --input - <<EOF
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["CI / lint", "CI / test"]
  },
  "required_pull_request_reviews": {
    "required_approving_review_count": 0
  },
  "enforce_admins": false,
  "restrictions": null
}
EOF
```

The `main` branch protection can mirror the same settings once `develop` → `main` merge cadence is established post-v0.1.

## Wave 1 Bootstrap Notes

The workflow is written to tolerate the pre-Wave-1 state where no hook scripts and no bats test files exist yet. Each step uses a `find`-based null-guard:

```bash
HOOKS=$(find plugins/brain-factory/hooks -name '*.sh' 2>/dev/null || true)
if [ -z "$HOOKS" ]; then
  echo "No hook scripts found — skipping"
  exit 0
fi
```

Once Wave 1 stories (`STORY-001` through the first hook deliverables) land in `develop`, the lint and test steps will engage automatically with no workflow changes needed.

## Upgrade Path

When the project migrates to WASM dispatcher (v1.0, Phase 4), add a `cargo` lint job to this workflow targeting the dispatcher plugin crates. The bash lint and bats test jobs remain for hook regression coverage even after the migration.
