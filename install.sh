#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/mystyy01/rice-manager/main"
REPO_ARCHIVE_URL="https://github.com/mystyy01/rice-manager/archive/refs/heads/main.tar.gz"
DEFAULT_BIN_DIR="$HOME/.local/bin"
DEFAULT_RICE_ROOT="$HOME/.local/share/rices"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  cat <<USAGE
rice-manager installer

Usage:
  curl -fsSL $REPO_RAW_BASE/install.sh | bash

Flags:
  --yes                 Non-interactive (uses defaults)
  --bin-dir <path>      Install directory for the rice executable (default: $DEFAULT_BIN_DIR)
  --rice-root <path>    Rice storage root for optional imports (default: $DEFAULT_RICE_ROOT)
  --import-mono-glass   Import mono-glass rice from the GitHub repo
USAGE
  exit 0
fi

ASSUME_YES=0
IMPORT_MONO_GLASS=0
BIN_DIR="$DEFAULT_BIN_DIR"
RICE_ROOT="$DEFAULT_RICE_ROOT"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --yes)
      ASSUME_YES=1
      ;;
    --import-mono-glass)
      IMPORT_MONO_GLASS=1
      ;;
    --bin-dir)
      shift
      BIN_DIR="${1:-}"
      [[ -n "$BIN_DIR" ]] || { echo "Missing value for --bin-dir" >&2; exit 1; }
      ;;
    --rice-root)
      shift
      RICE_ROOT="${1:-}"
      [[ -n "$RICE_ROOT" ]] || { echo "Missing value for --rice-root" >&2; exit 1; }
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
  shift
done

ask() {
  local prompt="$1"
  local default="$2"
  local out
  read -r -p "$prompt [$default]: " out || true
  if [[ -z "$out" ]]; then
    echo "$default"
  else
    echo "$out"
  fi
}

ask_yes_no() {
  local prompt="$1"
  local default="$2"
  local out
  read -r -p "$prompt [$default]: " out || true
  out="${out:-$default}"
  case "${out,,}" in
    y|yes) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "$ASSUME_YES" -eq 0 ]]; then
  BIN_DIR="$(ask 'Install rice binary into directory' "$BIN_DIR")"
  RICE_ROOT="$(ask 'Rice storage root' "$RICE_ROOT")"
  if ask_yes_no "Install bundled mono-glass rice from GitHub?" "y"; then
    IMPORT_MONO_GLASS=1
  fi
fi

mkdir -p "$BIN_DIR"
mkdir -p "$RICE_ROOT"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

RICE_URL="$REPO_RAW_BASE/bin/rice"
echo "Downloading rice from: $RICE_URL"
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$RICE_URL" -o "$TMPDIR/rice"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$TMPDIR/rice" "$RICE_URL"
else
  echo "Need curl or wget to install." >&2
  exit 1
fi

install -m 0755 "$TMPDIR/rice" "$BIN_DIR/rice"

echo "Installed: $BIN_DIR/rice"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    ;;
  *)
    echo "Note: $BIN_DIR is not currently in PATH."
    echo "Add this to your shell config (e.g. ~/.zshrc):"
    echo "  export PATH=\"$BIN_DIR:\$PATH\""
    ;;
esac

if [[ "$IMPORT_MONO_GLASS" -eq 1 ]]; then
  DST="$RICE_ROOT/mono-glass"

  if command -v tar >/dev/null 2>&1; then
    echo "Downloading bundled mono-glass from: $REPO_ARCHIVE_URL"
    if command -v curl >/dev/null 2>&1; then
      curl -fsSL "$REPO_ARCHIVE_URL" -o "$TMPDIR/repo.tar.gz"
    elif command -v wget >/dev/null 2>&1; then
      wget -qO "$TMPDIR/repo.tar.gz" "$REPO_ARCHIVE_URL"
    else
      echo "Need curl or wget to install mono-glass." >&2
      exit 1
    fi

    tar -xzf "$TMPDIR/repo.tar.gz" -C "$TMPDIR"
    SRC_ARCHIVE_DIR="$(find "$TMPDIR" -maxdepth 6 -type d -path '*/rices/mono-glass' | head -n 1)"
    if [[ -n "$SRC_ARCHIVE_DIR" && -d "$SRC_ARCHIVE_DIR" ]]; then
      rm -rf "$DST"
      mkdir -p "$DST"
      if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$SRC_ARCHIVE_DIR/" "$DST/"
      else
        cp -a "$SRC_ARCHIVE_DIR/." "$DST/"
      fi
      echo "Installed mono-glass -> $DST"
    else
      echo "mono-glass not found in downloaded archive." >&2
      echo "Please open an issue at: https://github.com/mystyy01/rice-manager/issues" >&2
      exit 1
    fi
  else
    echo "Need tar to unpack mono-glass preset." >&2
    exit 1
  fi
fi

echo "Done. Try: rice list"
