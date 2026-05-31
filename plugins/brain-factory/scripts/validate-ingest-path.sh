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
#      /etc /usr /var (ALL of /var/*) /sys /proc
#      (and macOS /private/* equivalents). NOT configurable via allowlist.
#      NOTE: /var/folders is macOS user-writable temp space; it is safe
#      because in-vault paths (step 2) bypass this block entirely.
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
# _lexical_normalize_path <absolute-path>
#
# Lexically collapse a /-separated absolute path by dropping empty segments
# and `.` segments and popping on `..` segments. Does NOT touch the filesystem.
# This is used after the slow-path ancestor-walk to eliminate any remaining `..`
# segments that were appended verbatim (because the intermediate component did
# not exist at resolution time and therefore could not be dereferenced via
# readlink -f on macOS).
#
# Guarded against popping above root: excess `..` segments at the root level
# are silently ignored (POSIX: "/.." == "/").
#
# Input must be an absolute path (starts with /). Behaviour is undefined for
# relative paths — callers must not pass relative paths here.
# ---------------------------------------------------------------------------
_lexical_normalize_path() {
  local path="$1"
  local -a parts=()
  local part
  # Split on /; read -ra requires bash (guaranteed by #!/usr/bin/env bash above)
  local IFS='/'
  # shellcheck disable=SC2162
  read -ra segs <<<"$path"
  for part in "${segs[@]}"; do
    case "$part" in
    '' | '.') continue ;;
    '..')
      if [ "${#parts[@]}" -gt 0 ]; then
        unset 'parts[-1]'
      fi
      ;;
    *) parts+=("$part") ;;
    esac
  done
  # Reconstruct: always starts with /
  if [ "${#parts[@]}" -eq 0 ]; then
    printf '/'
    return 0
  fi
  local result="/${parts[0]}"
  local i
  for ((i = 1; i < ${#parts[@]}; i++)); do
    result="${result}/${parts[$i]}"
  done
  printf '%s' "$result"
}

# ---------------------------------------------------------------------------
# _resolve_path <path>
#
# Resolves a path with readlink -f. For nonexistent paths (readlink -f exits 1
# on macOS), walks up the directory tree to find the nearest existing ancestor,
# resolves that with readlink -f, then appends the remaining path components.
# This correctly handles macOS /var → /private/var symlinks for temp paths.
#
# SECURITY: After slow-path reconstruction the raw string may contain literal
# `..` segments (e.g. vault/nonexistent/../../../../etc/passwd). We MUST call
# _lexical_normalize_path on the reconstructed result to collapse those `..`
# segments before any prefix or system-directory comparisons are made.
# Without this normalization, a path that lexically starts with the vault root
# but lexically escapes it via `..` would incorrectly set INSIDE_VAULT=1.
# (BC-2.03.003 invariant 1)
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
      local raw_result="${ancestor_resolved%/}${remaining}"
      # SECURITY: canonicalize to collapse any .. segments before returning.
      # The remaining component may contain literal ../ escapes (e.g. from a
      # path like vault/nonexistent/../../../../etc/passwd). Lexically normalize
      # so that all prefix and system-dir checks operate on the true canonical path.
      _lexical_normalize_path "$raw_result"
      return 0
    fi
    remaining="/$(basename "$current")${remaining}"
    current="$(dirname "$current")"
  done
  # Root or completely unresolvable: normalize as-is (handles edge case of / input)
  _lexical_normalize_path "$path"
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
# ALL of /var/* is blocked for out-of-vault paths (BC-2.03.003 invariant 2).
# In-vault paths (INSIDE_VAULT=1) never reach this check — that is the safe
# path for /var/folders mktemp vaults on macOS.
# ---------------------------------------------------------------------------
_is_system_dir() {
  local path="$1"
  # BC-2.03.003 invariant 2: deny-by-default for all /var/* when outside vault.
  # /var/folders is macOS user-writable temp space (NOT blocked) — but that guard
  # only applies when the path is INSIDE the vault (checked before this function).
  # For out-of-vault paths, ALL of /var/* is hard-blocked.
  case "$path" in
  /etc/* | /etc) return 0 ;;
  /usr/* | /usr) return 0 ;;
  /var/* | /var) return 0 ;;
  /sys/* | /sys) return 0 ;;
  /proc/* | /proc) return 0 ;;
  /private/etc/* | /private/etc) return 0 ;;
  /private/usr/* | /private/usr) return 0 ;;
  /private/var/* | /private/var) return 0 ;;
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
