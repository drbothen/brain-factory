---
document_type: verification-property
id: VP-023
title: "GitHub Action templates: v0.1 core set YAML validity and trigger configuration"
level: L3
version: "1.0"
producer: "vsdd-factory:architect"
phase: phase-1c
traces_to: ../VP-INDEX.md
timestamp: 2026-05-15T00:00:00
verifies_bcs: [BC-2.13.001]
created: 2026-05-15
status: proposed
---

# VP-023: GitHub Action templates: v0.1 core set YAML validity and trigger configuration

## Property Statement

The 6 v0.1 core GitHub Action template files (BC-2.13.001) must each satisfy:

1. **YAML validity:** `yamllint` passes with no errors on each template file.
2. **GH Actions schema:** Each template contains the mandatory top-level keys `name`,
   `on`, `jobs`. The `jobs` map contains at least one job with a `runs-on` key and a
   `steps` list.
3. **Trigger configuration:** Each template's `on:` block matches its intended trigger
   type (documented in ADR-013 per-template inventory):
   - `daily-brief.yml` — `schedule:` with a cron expression
   - `weekly-refresh.yml` — `schedule:` with a cron expression
   - `ingest-rss.yml` — `schedule:` with a cron expression
   - `health-check.yml` — `schedule:` with a cron expression
   - `lint-wiki.yml` — `schedule:` with a cron expression (or `push:` / `pull_request:`)
   - `scale-test.yml` — `workflow_dispatch:` (manual trigger)
4. **`runs-on` value:** All 6 templates use `ubuntu-latest` as the runner target.
5. **No hardcoded paths or tokens:** No template contains a hardcoded vault path or
   a literal API token value. Dynamic paths use `${{ github.workspace }}` or
   equivalent. Tokens use `${{ secrets.LINKEDIN_ACCESS_TOKEN }}` or similar secret refs.

This VP covers BC-2.13.001's ship gate: "the templates are valid GH Actions YAML and
run green on push in the CI matrix." The "run green" portion is validated separately
by the CI matrix integration test (the smoke-brain fixture in GH Actions).

## Verification Mechanism

bats (meta-lint.bats + CI matrix) — template structural assertions:

```bash
# --- meta-lint.bats: template YAML validity ---

CORE_TEMPLATES=(
  "daily-brief.yml"
  "weekly-refresh.yml"
  "ingest-rss.yml"
  "health-check.yml"
  "lint-wiki.yml"
  "scale-test.yml"
)

@test "GH Action templates: all 6 v0.1 core templates exist in plugin" {
  for template in "${CORE_TEMPLATES[@]}"; do
    local path="${PLUGIN_ROOT}/templates/github-action-templates/${template}"
    assert [ -f "$path" ] "Missing v0.1 core template: $template"
  done
}

@test "GH Action templates: all 6 core templates pass yamllint" {
  for template in "${CORE_TEMPLATES[@]}"; do
    local path="${PLUGIN_ROOT}/templates/github-action-templates/${template}"
    run yamllint -d relaxed "$path"
    assert_success "yamllint failed on $template: $output"
  done
}

@test "GH Action templates: all core templates have mandatory top-level keys" {
  for template in "${CORE_TEMPLATES[@]}"; do
    local path="${PLUGIN_ROOT}/templates/github-action-templates/${template}"
    for key in name on jobs; do
      run yq eval "has(\"$key\")" "$path"
      assert_output "true" "$template missing top-level key: $key"
    done
  done
}

@test "GH Action templates: all core templates use ubuntu-latest runner" {
  for template in "${CORE_TEMPLATES[@]}"; do
    local path="${PLUGIN_ROOT}/templates/github-action-templates/${template}"
    run yq eval '.jobs[].runs-on' "$path"
    # All runs-on values must be ubuntu-latest
    while IFS= read -r runner; do
      assert [ "$runner" = "ubuntu-latest" ] \
        "$template job uses non-standard runner: $runner"
    done <<< "$output"
  done
}

@test "GH Action templates: scale-test.yml uses workflow_dispatch trigger" {
  local path="${PLUGIN_ROOT}/templates/github-action-templates/scale-test.yml"
  run yq eval 'has("on.workflow_dispatch")' "$path"
  assert_output "true" "scale-test.yml missing workflow_dispatch trigger"
}

@test "GH Action templates: no hardcoded API tokens or vault paths in templates" {
  for template in "${CORE_TEMPLATES[@]}"; do
    local path="${PLUGIN_ROOT}/templates/github-action-templates/${template}"
    # Secrets must use ${{ secrets.* }} syntax, not literal values
    run grep -n 'ACCESS_TOKEN\s*=\s*[^$]' "$path"
    assert_output "" "$template contains a potential hardcoded token"
    # Paths must not reference a specific user's home directory
    run grep -n '/Users/' "$path"
    assert_output "" "$template hardcodes a macOS home path"
    run grep -n '/home/' "$path"
    assert_output "" "$template hardcodes a Linux home path"
  done
}

@test "GH Action templates: scheduled templates use cron on: trigger" {
  local scheduled_templates=("daily-brief.yml" "weekly-refresh.yml" "ingest-rss.yml"
    "health-check.yml" "lint-wiki.yml")
  for template in "${scheduled_templates[@]}"; do
    local path="${PLUGIN_ROOT}/templates/github-action-templates/${template}"
    run yq eval '.on | has("schedule")' "$path"
    assert_output "true" "$template missing schedule trigger"
  done
}
```

## Assumed Prerequisites

- `yamllint` in PATH (CI installs via pip or package manager in GH Actions matrix)
- `yq` in PATH for structured YAML assertions
- The 6 core template files exist at `${PLUGIN_ROOT}/templates/github-action-templates/`
  before Phase 3 implementation (they are hand-authored per ADR-013 — no generation)

## Counterexamples

- A template uses `on: push` instead of `on: schedule:` — the trigger-type assertion
  catches the mismatch for scheduled templates
- `scale-test.yml` uses `on: schedule:` instead of `on: workflow_dispatch:` — this
  would trigger the scale test on every cron tick, which is expensive and unintended;
  the workflow_dispatch assertion catches this
- A template references `${{ env.LINKEDIN_ACCESS_TOKEN }}` (env var, not secret) — this
  is a security misconfiguration; the hardcoded-token pattern grep catches anything that
  looks like a token value not in `secrets.*` context (note: the grep pattern focuses
  on literal values, not all secret references)

## Status

proposed — pending Phase 3 implementation of GH Action templates and meta-lint.bats
extension to cover template YAML
