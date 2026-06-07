#!/usr/bin/env bash
# Chuma installer — downloads prebuilt binary, no Rust required
set -euo pipefail

BINARY="chuma"
# Public release repo (release.yml in chatelo/Model-Plug pushes the
# built artifacts here via `repository: chumaAI/chuma-code`). Users
# `curl` install.sh from this same repo, so the resolution stays
# self-consistent — `latest` and the per-version asset URL both come
# from the same place.
REPO="${CHUMA_REPO:-chumaAI/chuma-code}"
VERSION="${CHUMA_VERSION:-latest}"

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════╗"
echo "║   Chuma ⚡  Installer        ║"
echo "╚══════════════════════════════════╝"
echo -e "${RESET}"

# ── helpers ────────────────────────────────────────────────────────────────
need() {
  if ! command -v "$1" &>/dev/null; then
    echo -e "${RED}✗ Required tool not found: $1${RESET}"
    exit 1
  fi
}

need curl
need tar

# ── detect OS ──────────────────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  OS_TAG="linux"  ;;
  Darwin) OS_TAG="macos"  ;;
  *)
    echo -e "${RED}✗ Unsupported OS: $OS${RESET}"
    echo "  Windows users: see https://github.com/$REPO#windows"
    exit 1
    ;;
esac

case "$ARCH" in
  x86_64)          ARCH_TAG="x86_64"  ;;
  arm64|aarch64)   ARCH_TAG="aarch64" ;;
  *)
    echo -e "${RED}✗ Unsupported architecture: $ARCH${RESET}"
    exit 1
    ;;
esac

# ── resolve version ────────────────────────────────────────────────────────
if [ "$VERSION" = "latest" ]; then
  echo -e "${CYAN}▶ Fetching latest release...${RESET}"
  VERSION="$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')"
  if [ -z "$VERSION" ]; then
    echo -e "${RED}✗ Could not fetch latest version. Check your internet connection.${RESET}"
    exit 1
  fi
fi

echo -e "${CYAN}▶ Installing ${BINARY} ${VERSION} (${OS_TAG}/${ARCH_TAG})${RESET}"

# ── download ───────────────────────────────────────────────────────────────
# Asset shape produced by .github/workflows/release.yml:
#   chuma-<os>-<arch>-v<VERSION>.tar.gz   (Linux / macOS)
#   chuma-windows-<arch>-v<VERSION>.zip   (Windows; not handled here)
# Keep this in lockstep with that matrix.
TARBALL="${BINARY}-${OS_TAG}-${ARCH_TAG}-${VERSION}.tar.gz"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${TARBALL}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${GREEN}▶ Downloading ${URL}${RESET}"
if ! curl -fsSL --progress-bar "$URL" -o "${TMP_DIR}/${TARBALL}"; then
  echo -e "${RED}✗ Download failed.${RESET}"
  echo "  URL: $URL"
  echo "  Check that release ${VERSION} has a ${TARBALL} asset."
  exit 1
fi

echo -e "${GREEN}▶ Extracting...${RESET}"
tar -xzf "${TMP_DIR}/${TARBALL}" -C "${TMP_DIR}"
chmod +x "${TMP_DIR}/${BINARY}"

# ── install location ───────────────────────────────────────────────────────
# Prefer ~/.local/bin (no sudo); fall back to /usr/local/bin with sudo
if [ -n "${CHUMA_INSTALL_DIR:-}" ]; then
  INSTALL_DIR="$CHUMA_INSTALL_DIR"
elif [ -w "/usr/local/bin" ]; then
  INSTALL_DIR="/usr/local/bin"
else
  INSTALL_DIR="${HOME}/.local/bin"
fi

mkdir -p "$INSTALL_DIR"
DEST="${INSTALL_DIR}/${BINARY}"

if [ -e "$DEST" ] && [ ! -w "$DEST" ]; then
  echo -e "${YELLOW}▶ Existing install needs sudo to overwrite${RESET}"
  sudo mv "${TMP_DIR}/${BINARY}" "$DEST"
else
  mv "${TMP_DIR}/${BINARY}" "$DEST"
fi

# ── PATH check ─────────────────────────────────────────────────────────────
if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
  echo ""
  echo -e "${YELLOW}⚠  ${INSTALL_DIR} is not in your PATH.${RESET}"
  echo "   Add this line to your shell config (~/.bashrc, ~/.zshrc, etc.):"
  echo ""
  echo -e "   ${BOLD}export PATH=\"${INSTALL_DIR}:\$PATH\"${RESET}"
  echo ""
  echo "   Then reload: source ~/.bashrc  (or open a new terminal)"
fi

# ── done ───────────────────────────────────────────────────────────────────
INSTALLED_VERSION="$("$DEST" --version 2>/dev/null || echo "unknown")"
echo ""
echo -e "${GREEN}${BOLD}✓ Chuma installed!${RESET}"
echo -e "  Location : $DEST"
echo -e "  Version  : $INSTALLED_VERSION"
echo ""
echo "Quick start:"
echo "  chuma config set anthropic YOUR_API_KEY"
echo "  chuma run \"hello world\""
echo "  chuma status"