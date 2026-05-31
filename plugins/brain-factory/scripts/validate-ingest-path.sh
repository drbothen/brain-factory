#!/usr/bin/env bash
set -euo pipefail

# validate-ingest-path.sh — Path validation gate for /brain:ingest-source
#
# Usage: validate-ingest-path.sh <candidate-path>
#        BRAIN_ROOT  (env, optional) — override vault root;
#                    default: git rev-parse --show-toplevel
#
# Validation order:
#   1. Resolve candidate with readlink -f (NOT realpath — NOT available on macOS
#      without GNU coreutils; readlink -f is portable on macOS 12.3+ and Linux).
#      For nonexistent paths, walk up to find the first existing ancestor,
#      resolve that, and reconstruct the full path. This ensures macOS
#      /var→/private/var symlinks are handled consistently.
#   2. Vault check: if resolved path is inside resolved vault root → proceed.
#   3. System-directory hard block (for paths NOT in vault):
#      /etc /usr /var/log /var/run /var/spool /var/db /var/caches /sys /proc
#      (and macOS /private/* equivalents). NOT configurable via allowlist.
#      NOTE: /var/folders is macOS user-writable temp space (NOT a system dir).
#   4. Allowlist check: .brain/policies.yaml allowed_external_paths.
#      If resolved path is prefixed by any allowed path → proceed.
#   5. Otherwise reject with E-INGEST-009.
#   6. File existence check: missing file → E-INGEST-011; exit 2.
#   7. File type check: image → E-INGEST-010; PDF without pdftotext → E-INGEST-010.
#   8. Duplicate guard: slug in .brain/manifest.json → E-INGEST-001; exit 2.
#   9. Accept: print resolved path to stdout; exit 0.
#
# Exit codes:
#   0 — path accepted; resolved absolute path printed to stdout
#   2 — path rejected; JSON error envelope printed to stdout

CANDIDATE="${1:?Usage: validate-ingest-path.sh <candidate-path>}"

# ---------------------------------------------------------------------------
# _resolve_path <path>
#
# Resolves a path with readlink -f. For nonexistent paths (readlink -f exits 1
# on macOS), walks up the directory tree to find the nearest existing ancestor,
# resolves that with readlink -f, then appends the remaining path components.
# This correctly handles macOS /var → /private/var symlinks for temp paths.
# ---------------------------------------------------------------------------
_resolve_path() {
  local path="$1"
  # Fast path: readlink -f succeeds (path exists)
  local resolved
  resolved="$(readlink -f "$path" 2>/dev/null || true)"
  if [ -n "$resolved" ]; then
    printf '%s' "$resolved"
    return 0
  fi
  # Slow path: walk up to first existing ancestor, then rebuild
  local remaining="" current="$path"
  while [ -n "$current" ] && [ "$current" != "/" ]; do
    if [ -e "$current" ]; then
      local ancestor_resolved
      ancestor_resolved="$(readlink -f "$current" 2>/dev/null || printf '%s' "$current")"
      printf '%s%s' "${ancestor_resolved%/}" "$remaining"
      return 0
    fi
    remaining="/$(basename "$current")${remaining}"
    current="$(dirname "$current")"
  done
  # Root or completely unresolvable: return as-is
  printf '%s' "$path"
}

# ---------------------------------------------------------------------------
# Step 1: Resolve candidate path.
# ---------------------------------------------------------------------------
RESOLVED="$(_resolve_path "$CANDIDATE")"

# ---------------------------------------------------------------------------
# Step 2: Determine and resolve vault root.
# ---------------------------------------------------------------------------
if [ -n "${BRAIN_ROOT:-}" ]; then
  RAW_VAULT_ROOT="$BRAIN_ROOT"
else
  RAW_VAULT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
fi

if [ -z "$RAW_VAULT_ROOT" ]; then
  printf '{"level":"error","code":"E-INGEST-009","message":"Cannot determine vault root: not a git repository and BRAIN_ROOT is unset."}\n'
  exit 2
fi

VAULT_ROOT="$(readlink -f "$RAW_VAULT_ROOT" 2>/dev/null || printf '%s' "$RAW_VAULT_ROOT")"
VAULT_ROOT="${VAULT_ROOT%/}"

# ---------------------------------------------------------------------------
# Helper: _path_has_prefix <path> <prefix>
# Returns 0 if path equals prefix or starts with prefix/ (no partial dir match).
# ---------------------------------------------------------------------------
_path_has_prefix() {
  local path="$1" prefix="${2%/}"
  case "$path" in
  "${prefix}/"* | "${prefix}") return 0 ;;
  esac
  return 1
}

# ---------------------------------------------------------------------------
# Step 2 continued: Check if resolved path is inside the resolved vault root.
# ---------------------------------------------------------------------------
INSIDE_VAULT=0
if _path_has_prefix "$RESOLVED" "$VAULT_ROOT"; then
  INSIDE_VAULT=1
fi

# ---------------------------------------------------------------------------
# Step 3: Hard-block system directories for paths NOT inside the vault.
# Blocks traditional Unix system directories and their macOS /private/* mirrors.
# /var/folders is macOS user-writable temp space and is NOT blocked here.
# BC-2.03.003 invariant 2.
# ---------------------------------------------------------------------------
_is_system_dir() {
  local path="$1"
  case "$path" in
  /etc/* | /etc) return 0 ;;
  /usr/* | /usr) return 0 ;;
  /var/log/* | /var/log) return 0 ;;
  /var/run/* | /var/run) return 0 ;;
  /var/spool/* | /var/spool) return 0 ;;
  /var/db/* | /var/db) return 0 ;;
  /var/caches/* | /var/caches) return 0 ;;
  /var/tmp/* | /var/tmp) return 0 ;;
  /var/root/* | /var/root) return 0 ;;
  /var/mail/* | /var/mail) return 0 ;;
  /sys/* | /sys) return 0 ;;
  /proc/* | /proc) return 0 ;;
  /private/etc/* | /private/etc) return 0 ;;
  /private/usr/* | /private/usr) return 0 ;;
  /private/var/log/* | /private/var/log) return 0 ;;
  /private/var/run/* | /private/var/run) return 0 ;;
  /private/var/spool/* | /private/var/spool) return 0 ;;
  /private/var/db/* | /private/var/db) return 0 ;;
  /private/var/caches/* | /private/var/caches) return 0 ;;
  /private/var/tmp/* | /private/var/tmp) return 0 ;;
  /private/var/root/* | /private/var/root) return 0 ;;
  /private/var/mail/* | /private/var/mail) return 0 ;;
  /private/sys/* | /private/sys) return 0 ;;
  /private/proc/* | /private/proc) return 0 ;;
  esac
  return 1
}

if [ "$INSIDE_VAULT" -eq 0 ] && _is_system_dir "$RESOLVED"; then
  printf '{"level":"error","code":"E-INGEST-009","message":"Path '\''%s'\'' is outside the brain vault. Only vault-relative paths are allowed."}\n' \
    "$RESOLVED"
  exit 2
fi

# ---------------------------------------------------------------------------
# Step 4: Check allowed_external_paths in .brain/policies.yaml.
# Only checked when path is NOT inside vault.
# ---------------------------------------------------------------------------
ALLOWED_EXTERNAL=0
if [ "$INSIDE_VAULT" -eq 0 ]; then
  POLICIES_FILE="${VAULT_ROOT}/.brain/policies.yaml"
  if [ -f "$POLICIES_FILE" ] && command -v yq >/dev/null 2>&1; then
    ALLOWED_PATHS="$(yq eval '.allowed_external_paths[]' "$POLICIES_FILE" 2>/dev/null || true)"
    while IFS= read -r allowed; do
      [ -z "$allowed" ] && continue
      ALLOWED_RESOLVED="$(readlink -f "$allowed" 2>/dev/null || printf '%s' "${allowed%/}")"
      if _path_has_prefix "$RESOLVED" "$ALLOWED_RESOLVED"; then
        ALLOWED_EXTERNAL=1
        break
      fi
    done <<<"$ALLOWED_PATHS"
  fi
fi

# ---------------------------------------------------------------------------
# Step 5: Reject if not inside vault and not in allowlist.
# ---------------------------------------------------------------------------
if [ "$INSIDE_VAULT" -eq 0 ] && [ "$ALLOWED_EXTERNAL" -eq 0 ]; then
  printf '{"level":"error","code":"E-INGEST-009","message":"Path '\''%s'\'' is outside the brain vault. Only vault-relative paths are allowed."}\n' \
    "$RESOLVED"
  exit 2
fi

# ---------------------------------------------------------------------------
# Step 6: File existence check.
# ---------------------------------------------------------------------------
if [ ! -f "$RESOLVED" ]; then
  printf '{"level":"error","code":"E-INGEST-011","message":"File not found: %s"}\n' \
    "$RESOLVED"
  exit 2
fi

# ---------------------------------------------------------------------------
# Step 7: File type checks.
# Extract lowercase extension from resolved path basename.
# ---------------------------------------------------------------------------
LOWER_NAME="$(printf '%s' "$(basename "$RESOLVED")" | tr '[:upper:]' '[:lower:]')"
EXT="${LOWER_NAME##*.}"
if [ "$EXT" = "$LOWER_NAME" ]; then
  EXT=""
fi

case "$EXT" in
png | jpg | jpeg | gif | webp | svg)
  printf '{"level":"error","code":"E-INGEST-010","message":"Image files cannot be ingested in v0.1. Convert to text or markdown first."}\n'
  exit 2
  ;;
pdf)
  if ! command -v pdftotext >/dev/null 2>&1; then
    printf '{"level":"error","code":"E-INGEST-010","message":"PDF extraction requires poppler-utils (pdftotext). Install via your OS package manager or convert manually."}\n'
    exit 2
  fi
  ;;
esac

# ---------------------------------------------------------------------------
# Step 8: Duplicate guard — slug already in manifest.
# Slug derived from basename without extension, lowercased, kebab-case.
# ---------------------------------------------------------------------------
SLUG_RAW="$(basename "$RESOLVED")"
SLUG_RAW="${SLUG_RAW%.*}"
SLUG="$(printf '%s' "$SLUG_RAW" |
  tr '[:upper:]' '[:lower:]' |
  tr -cs '[:alnum:]-' '-' |
  sed 's/^-*//;s/-*$//')"

MANIFEST="${VAULT_ROOT}/.brain/manifest.json"
if [ -f "$MANIFEST" ]; then
  EXISTING="$(jq -r --arg slug "$SLUG" \
    '.sources | to_entries[] | select(.value.source_id == $slug) | .value.source_id' \
    "$MANIFEST" 2>/dev/null | head -1 || true)"
  if [ -n "$EXISTING" ]; then
    printf '{"level":"error","code":"E-INGEST-001","message":"Source already ingested as %s. Sources are immutable."}\n' \
      "$SLUG"
    exit 2
  fi
fi

# ---------------------------------------------------------------------------
# Step 9: Accept — print resolved path; exit 0.
# ---------------------------------------------------------------------------
printf '%s\n' "$RESOLVED"
exit 0
