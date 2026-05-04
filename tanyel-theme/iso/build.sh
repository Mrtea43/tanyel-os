#!/usr/bin/env bash
# TanyelOS ISO Builder — live-build with minimal package list
# Builds a complete bootable ISO from scratch (~25-35 min)

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'
ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${CYAN}  →${RESET}  $*"; }
fail() { echo -e "${RED}  ✗${RESET}  $*"; exit 1; }
step() { echo -e "\n${BOLD}── $* ──${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUT_ISO="$SCRIPT_DIR/tanyelos-1.0-amd64.iso"

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash build.sh"

for cmd in lb debootstrap; do
  command -v "$cmd" &>/dev/null || fail "Missing: $cmd"
done
ok "Tools present"

# ── Clean ─────────────────────────────────────────────────────
step "Preparing build directory"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
ok "Build directory ready"

# ── Configure ─────────────────────────────────────────────────
step "Configuring live-build"

lb config \
  --mode ubuntu \
  --distribution noble \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootloader grub-efi \
  --debian-installer none \
  --iso-application "TanyelOS" \
  --iso-publisher "TanyelOS" \
  --iso-volume "TanyelOS 1.0" \
  --memtest none \
  --win32-loader false \
  --apt-indices false \
  --apt-recommends false \
  --mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
  --mirror-chroot "http://archive.ubuntu.com/ubuntu/" \
  --mirror-binary "http://archive.ubuntu.com/ubuntu/" \
  --archive-areas "main restricted universe multiverse"

ok "live-build configured"

# ── Copy TanyelOS config ───────────────────────────────────────
step "Copying TanyelOS config"
cp -r "$SCRIPT_DIR/config/"* "$BUILD_DIR/config/"
ok "Config files copied"

# ── Build ─────────────────────────────────────────────────────
step "Building ISO (~25 min)"
lb build 2>&1

# ── Output ────────────────────────────────────────────────────
step "Finalising"

ISO=$(find "$BUILD_DIR" -name "*.iso" | head -1)
[[ -z "$ISO" ]] && fail "ISO not found — build failed"

cp "$ISO" "$OUT_ISO"
SIZE=$(du -sh "$OUT_ISO" | cut -f1)
ok "ISO ready: $OUT_ISO ($SIZE)"

sha256sum "$OUT_ISO" > "$OUT_ISO.sha256"
ok "SHA256: $(cut -d' ' -f1 "$OUT_ISO.sha256")"

echo -e "\n${BOLD}${GREEN}  TanyelOS 1.0 ISO ready.${RESET}\n"
