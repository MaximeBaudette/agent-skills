#!/usr/bin/env bash
# setup.sh — Install the tectonic LaTeX compiler binary
#
# Tectonic is a self-contained LaTeX engine that auto-downloads
# only the packages it needs on first compile.
#
# Usage: bash setup.sh

set -euo pipefail

BIN_DIR="$HOME/bin"
TECTONIC_BIN="$BIN_DIR/tectonic"

if command -v tectonic &>/dev/null; then
  echo "✓ tectonic already in PATH: $(command -v tectonic)"
  tectonic --version
  exit 0
fi

if [[ -x "$TECTONIC_BIN" ]]; then
  echo "✓ tectonic already installed at $TECTONIC_BIN"
  "$TECTONIC_BIN" --version
  exit 0
fi

echo "→ Installing tectonic to $TECTONIC_BIN"
mkdir -p "$BIN_DIR"

# Direct binary download from GitHub releases
{
  ARCH=$(uname -m)
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  
  # Get latest release tag (format: tectonic@X.Y.Z)
  LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/tectonic-typesetting/tectonic/releases/latest" \
    | python3 -c "import json,sys; print(json.load(sys.stdin)['tag_name'])")
  VERSION="${LATEST_TAG#tectonic@}"

  if [[ "$ARCH" == "x86_64" && "$OS" == "linux" ]]; then
    TARBALL="tectonic-${VERSION}-x86_64-unknown-linux-musl.tar.gz"
  elif [[ "$ARCH" == "aarch64" && "$OS" == "linux" ]]; then
    TARBALL="tectonic-${VERSION}-aarch64-unknown-linux-musl.tar.gz"
  elif [[ "$ARCH" == "x86_64" && "$OS" == "darwin" ]]; then
    TARBALL="tectonic-${VERSION}-x86_64-apple-darwin.tar.gz"
  elif [[ "$ARCH" == "arm64" && "$OS" == "darwin" ]]; then
    TARBALL="tectonic-${VERSION}-aarch64-apple-darwin.tar.gz"
  else
    echo "ERROR: Unsupported platform: $OS/$ARCH" >&2
    exit 1
  fi

  RELEASE_URL="https://github.com/tectonic-typesetting/tectonic/releases/download/tectonic%40${VERSION}/${TARBALL}"

  TMP=$(mktemp -d)
  trap "rm -rf $TMP" EXIT
  curl -fsSL "$RELEASE_URL" -o "$TMP/tectonic.tar.gz"
  tar -xzf "$TMP/tectonic.tar.gz" -C "$TMP"
  cp "$TMP/tectonic" "$TECTONIC_BIN"
  chmod +x "$TECTONIC_BIN"
}

echo "✓ tectonic installed at $TECTONIC_BIN"
"$TECTONIC_BIN" --version

echo ""
echo "Make sure $BIN_DIR is in your PATH."
echo "Add to ~/.bashrc or ~/.profile if needed:"
echo '  export PATH="$HOME/bin:$PATH"'
