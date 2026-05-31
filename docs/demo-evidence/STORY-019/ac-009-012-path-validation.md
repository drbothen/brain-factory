# AC-009 through AC-012: Out-of-Vault Path Rejection (BC-2.03.003)

BC: BC-2.03.003 — `/brain:ingest-source` rejects paths outside the brain vault root
Script: `plugins/brain-factory/scripts/validate-ingest-path.sh`

## AC Contract Summary

| AC | Contract |
|----|----------|
| AC-009 | Resolve path with `readlink -f` (NOT `realpath`); if resolved path not prefixed by vault root → E-INGEST-009 exit 2; no file read. |
| AC-010 | System directories (`/etc/`, `/usr/`, `/var/`, `/sys/`, `/proc/`) are ALWAYS blocked regardless of allowlist. Hard block, not configurable. |
| AC-011 | Symlink inside vault resolving outside vault → rejected (resolved path check, not raw path). |
| AC-012 | `allowed_external_paths` in `.brain/policies.yaml` permits outside-vault non-system paths; system dirs still blocked even if listed. |

## Evidence

### AC-009: Valid in-vault path — exit 0, resolved path printed

```
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh <vault>/sources/ai/my-research.md
stdout: /private/var/folders/…/tmp.xxx/sources/ai/my-research.md
exit: 0
```

**Result: PASS** — in-vault path accepted; resolved absolute path printed to stdout.

### AC-009/AC-010: System directory hard block (/etc/passwd) — E-INGEST-009 exit 2

```
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh /etc/passwd
stdout: {"level":"error","code":"E-INGEST-009","message":"Path '/private/etc/passwd' is outside the brain vault. Only vault-relative paths are allowed."}
exit: 2
```

Note: macOS resolves `/etc` to `/private/etc` via symlink — `readlink -f` follows this correctly.

**Result: PASS** — system directory blocked before file existence check; E-INGEST-009 exit 2.

### AC-009: dot-dot traversal outside vault — E-INGEST-009 exit 2

```
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh <vault>/../<sibling>/outside.txt
stdout: {"level":"error","code":"E-INGEST-009","message":"Path '/private/var/.../T/tmp.sibling/outside.txt' is outside the brain vault. Only vault-relative paths are allowed."}
exit: 2
```

**Result: PASS** — `..` traversal resolved by `readlink -f` (or `_lexical_normalize_path` for nonexistent intermediates) before vault comparison; E-INGEST-009 exit 2.

### AC-011: Symlink inside vault resolving outside vault — E-INGEST-009 exit 2

```
Symlink: <vault>/sources/outside-link.md → <outside>/secret.md
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh <vault>/sources/outside-link.md
stdout: {"level":"error","code":"E-INGEST-009","message":"Path '/private/var/.../tmp.xxx/secret.md' is outside the brain vault. Only vault-relative paths are allowed."}
exit: 2
```

**Result: PASS** — `readlink -f` follows symlink; resolved path is outside vault; E-INGEST-009 exit 2.

### AC-010/AC-012: System directory hard-blocked even when in allowlist

```
policies.yaml: allowed_external_paths: [/etc/]
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh /etc/passwd  (with /etc/ allowlisted)
stdout: {"level":"error","code":"E-INGEST-009","message":"Path '/private/etc/passwd' is outside the brain vault. Only vault-relative paths are allowed."}
exit: 2
```

**Result: PASS** — system-dir check (step 3) runs BEFORE allowlist check (step 4); /etc/ in allowlist does not override the hard block.

Additional system-dir hard blocks verified in bats:

```
ok 25 BC_2_03_003: /usr/ hard-blocked regardless of allowlist (AC-010)
ok 26 BC_2_03_003: /var/ hard-blocked regardless of allowlist (AC-010)
ok 27 BC_2_03_003: out-of-vault /var/<non-enumerated> hard-blocked even when allowlisted (F3 regression)
```

### AC-012: Allowlisted outside-vault non-system path — exit 0

```
policies.yaml: allowed_external_paths: [/tmp/bats-allowed-86MbxS/]
Command: BRAIN_ROOT=<vault> validate-ingest-path.sh /tmp/bats-allowed-86MbxS/research-notes.md
stdout: /private/tmp/bats-allowed-86MbxS/research-notes.md
exit: 0
```

**Result: PASS** — non-system path explicitly allowlisted; accepted; resolved path returned.

### BLOCKER-1: nonexistent-intermediate `..` escape (BC-2.03.003 invariant 1)

The slow-path resolution in `_resolve_path` canonicalizes `..` segments after ancestor walk,
preventing vault-escape via `vault/nonexistent/../../../../etc/passwd`:

```
ok 43 BC_2_03_003: nonexistent-intermediate dotdot escaping to system file yields E-INGEST-009 exit 2 (BLOCKER-1)
ok 44 BC_2_03_003: nonexistent-intermediate dotdot escaping to sibling outside vault yields E-INGEST-009 exit 2 (BLOCKER-1)
```

### readlink -f (not realpath) verified

```
ok 40 BC_2_03_003: scripts/validate-ingest-path.sh does not invoke realpath as a command (uses readlink -f)
```

### Full bats coverage

```
ok 20 BC_2_03_003: valid markdown file inside vault exits 0 with resolved path (AC-001/AC-009)
ok 21 BC_2_03_003: /etc/passwd rejected with E-INGEST-009 exit 2 (AC-009/AC-010)
ok 22 BC_2_03_003: dot-dot traversal resolving outside vault rejected E-INGEST-009 exit 2 (AC-009)
ok 23 BC_2_03_003: symlink inside vault pointing outside vault rejected E-INGEST-009 exit 2 (AC-011)
ok 24 BC_2_03_003: /etc/ hard-blocked even when in policies.yaml allowed_external_paths (AC-010/AC-012)
ok 25 BC_2_03_003: /usr/ hard-blocked regardless of allowlist (AC-010)
ok 26 BC_2_03_003: /var/ hard-blocked regardless of allowlist (AC-010)
ok 27 BC_2_03_003: out-of-vault /var/<non-enumerated> hard-blocked even when allowlisted (F3 regression)
ok 28 BC_2_03_003: allowlisted outside-vault path is accepted; exit 0 (AC-012)
ok 35 BC_2_03_003: scripts/validate-ingest-path.sh exists (structural)
ok 36 BC_2_03_003: scripts/validate-ingest-path.sh first line is #!/usr/bin/env bash
ok 37 BC_2_03_003: scripts/validate-ingest-path.sh has set -euo pipefail within first 10 lines
ok 38 BC_2_03_003: scripts/validate-ingest-path.sh passes shellcheck (structural Red Gate)
ok 39 BC_2_03_003: scripts/validate-ingest-path.sh passes shfmt normalization (structural Red Gate)
ok 40 BC_2_03_003: scripts/validate-ingest-path.sh does not invoke realpath as a command (uses readlink -f)
ok 43 BC_2_03_003: nonexistent-intermediate dotdot escaping to system file yields E-INGEST-009 exit 2 (BLOCKER-1)
ok 44 BC_2_03_003: nonexistent-intermediate dotdot escaping to sibling outside vault yields E-INGEST-009 exit 2 (BLOCKER-1)
```

Raw output: `raw-output/validate-ingest-path-demos.txt` (DEMO 1-6), `raw-output/skills-bats-run.txt`
