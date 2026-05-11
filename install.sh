#!/usr/bin/env bash
# ChumaClaw installer — downloads prebuilt binary, no Rust required
set -euo pipefail

BINARY="chuma"
REPO="chumaAI/chuma-code"
VERSION="${CHUMA_VERSION:-latest}"

BOLD="\033[1m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

echo -e "${CYAN}${BOLD}"
echo "╔══════════════════════════════════╗"
echo "║   ChumaClaw ⚡  Installer        ║"
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

echo -e "${GREEN}✔ Found version: ${VERSION}${RESET}"

# ── check if already installed ─────────────────────────────────────────────
if command -v "$BINARY" &>/dev/null; then
  CURRENT_VERSION="$("$BINARY" --version 2>/dev/null | awk '{print $2}')"
  REMOTE_VERSION="${VERSION#v}"
  if [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ]; then
    echo ""
    echo -e "${GREEN}${BOLD}✓ ChumaClaw ${VERSION} is already installed and up to date.${RESET}"
    echo -e "  ${DIM:-\033[2m}Location: $(command -v "$BINARY")${RESET}"
    echo ""
    exit 0
  else
    echo -e "${YELLOW}▶ Upgrading ${CURRENT_VERSION} → ${REMOTE_VERSION}${RESET}"
  fi
fi

# ── download ───────────────────────────────────────────────────────────────
ASSET="${BINARY}-${OS_TAG}-${ARCH_TAG}-${VERSION}"
URL="https://github.com/${REPO}/releases/download/${VERSION}/${ASSET}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo -e "${CYAN}▶ Downloading ${BINARY}-${OS_TAG}-${ARCH_TAG}...${RESET}"
if ! curl -fsSL --progress-bar "$URL" -o "${TMP_DIR}/${BINARY}"; then
  echo -e "${RED}✗ Download failed.${RESET}"
  echo "  URL: $URL"
  echo "  Check that release ${VERSION} has a ${ASSET} asset."
  exit 1
fi

chmod +x "${TMP_DIR}/${BINARY}"

# ── install location ───────────────────────────────────────────────────────
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
PURPLE="\033[35m"
DIM="\033[2m"

echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║       ✓  ChumaClaw installed successfully!           ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}Version ${RESET}   ${BOLD}${INSTALLED_VERSION}${RESET}"
echo -e "  ${DIM}Location${RESET}   ${CYAN}${DEST}${RESET}"
echo ""
echo -e "${PURPLE}${BOLD}  ──────────────────  Quick Start  ──────────────────${RESET}"
echo ""
echo -e "  ${YELLOW}#${RESET} Set your API key"
echo -e "  ${BOLD}chuma config set anthropic YOUR_API_KEY${RESET}"
echo ""
echo -e "  ${YELLOW}#${RESET} Run a prompt"
echo -e "  ${BOLD}chuma run \"explain recursion in one paragraph\"${RESET}"
echo ""
echo -e "  ${YELLOW}#${RESET} Launch an agent"
echo -e "  ${BOLD}chuma agent \"write and test a Python web scraper\"${RESET}"
echo ""
echo -e "  ${YELLOW}#${RESET} Free local models — no API key needed"
echo -e "  ${BOLD}chuma chat --provider ollama --model gemma4:31b-cloud${RESET}"
echo ""
echo -e "  ${DIM}Docs & releases → https://github.com/chumaAI/chuma-code${RESET}"
echo ""