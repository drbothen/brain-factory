#!/usr/bin/env bash
set -euo pipefail

# validate-ingest-path.sh — STUB (STORY-019 implementation pending)
#
# Intended contract (to be implemented in STORY-019 impl step):
#   $1 — candidate path (absolute or relative) to validate
#   BRAIN_ROOT (env, optional) — override vault root; default: git rev-parse --show-toplevel
#
# Final behavior:
#   1. Resolve candidate path with `readlink -f` (handles .. traversal and symlinks).
#      NOTE: use readlink -f, NOT realpath — realpath is not available on macOS without
#      GNU coreutils. readlink -f is portable on macOS 12.3+ and all Linux distributions.
#   2. Hard-block system directories (/etc /usr /var /sys /proc) ALWAYS —
#      not configurable via policy.
#   3. Determine vault root via `git rev-parse --show-toplevel` (unless BRAIN_ROOT is set).
#   4. If resolved path is not prefixed by vault root, check allowlist from
#      .brain/policies.yaml (key: allowed_external_paths).
#   5. On rejection: emit JSON error to stdout + exit 2 with E-INGEST-009.
#   6. On acceptance: print resolved path to stdout + exit 0.
#
# Exit codes:
#   0 — path accepted; resolved absolute path printed to stdout
#   2 — path rejected; JSON error envelope printed to stdout
#   3 — STUB sentinel (not yet implemented; bats tests MUST fail on this)

echo '{"level":"error","code":"E-STUB","message":"E-STUB: validate-ingest-path not implemented"}' >&2
exit 3
