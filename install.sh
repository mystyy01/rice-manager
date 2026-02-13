#!/usr/bin/env bash
set -euo pipefail

REPO_RAW_BASE="https://raw.githubusercontent.com/mystyy01/rice-manager/main"
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
  --import-mono-glass   Import local mono-glass rice if available
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
  if ask_yes_no "Import local mono-glass rice if found?" "y"; then
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
  SRC="$HOME/.local/share/rices/mono-glass"
  DST="$RICE_ROOT/mono-glass"
  if [[ -d "$SRC" ]]; then
    echo "Importing mono-glass from $SRC"
    rm -rf "$DST"
    if command -v rsync >/dev/null 2>&1; then
      mkdir -p "$DST"
      rsync -a --delete "$SRC/" "$DST/"
    else
      mkdir -p "$DST"
      cp -a "$SRC/." "$DST/"
    fi
    echo "Imported mono-glass -> $DST"
  else
    echo "Skipped mono-glass import (not found at $SRC)."
  fi
fi

echo "Done. Try: rice list"
