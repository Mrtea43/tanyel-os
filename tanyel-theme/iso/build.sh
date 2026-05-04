#!/usr/bin/env bash
# TanyelOS ISO Builder
# Produces: tanyelos-1.0-amd64.iso  (~2.5 GB)
#
# Requirements (run on Ubuntu 22.04 or 24.04):
#   sudo apt install live-build debootstrap squashfs-tools xorriso isolinux
#
# Usage:
#   bash build.sh            # full build (~30-60 min)
#   bash build.sh --clean    # wipe previous build first

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'
ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${CYAN}  →${RESET}  $*"; }
fail() { echo -e "${RED}  ✗${RESET}  $*"; exit 1; }
step() { echo -e "\n${BOLD}── $* ──${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"
OUT_ISO="$SCRIPT_DIR/tanyelos-1.0-amd64.iso"

# ── Preflight ─────────────────────────────────────────────────
step "Preflight checks"

[[ $EUID -ne 0 ]] && fail "This script must run as root (sudo bash build.sh)"

for cmd in lb debootstrap mksquashfs xorriso; do
  command -v "$cmd" &>/dev/null || fail "Missing: $cmd  →  sudo apt install live-build debootstrap squashfs-tools xorriso"
done
ok "All tools present"

# ── Clean ─────────────────────────────────────────────────────
if [[ "${1:-}" == "--clean" ]] || [[ ! -d "$BUILD_DIR" ]]; then
  step "Cleaning previous build"
  rm -rf "$BUILD_DIR"
  ok "Build directory cleared"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# ── Configure live-build ──────────────────────────────────────
step "Configuring live-build"

lb config \
  --mode ubuntu \
  --distribution noble \
  --architectures amd64 \
  --binary-images iso-hybrid \
  --bootloader grub-efi \
  --debian-installer live \
  --debian-installer-gui true \
  --iso-application "TanyelOS" \
  --iso-publisher "TanyelOS Project" \
  --iso-volume "TanyelOS 1.0" \
  --memtest none \
  --win32-loader false \
  --apt-indices false \
  --apt-recommends true \
  --debootstrap-options "--variant=minbase" \
  --mirror-bootstrap "http://archive.ubuntu.com/ubuntu/" \
  --mirror-chroot "http://archive.ubuntu.com/ubuntu/" \
  --mirror-binary "http://archive.ubuntu.com/ubuntu/" \
  --archive-areas "main restricted universe multiverse"

ok "live-build configured for Ubuntu 24.04 (Noble)"

# ── Copy config ───────────────────────────────────────────────
step "Copying TanyelOS config"

cp -r "$SCRIPT_DIR/config/"* "$BUILD_DIR/config/"
ok "Config files copied"

# ── Build ─────────────────────────────────────────────────────
step "Building ISO  (this takes 30–60 minutes)"
info "Logs: $BUILD_DIR/build.log"

lb build 2>&1 | tee "$BUILD_DIR/build.log"

# ── Rename output ─────────────────────────────────────────────
step "Finalising"

if [[ -f "$BUILD_DIR/live-image-amd64.hybrid.iso" ]]; then
  cp "$BUILD_DIR/live-image-amd64.hybrid.iso" "$OUT_ISO"
  SIZE=$(du -sh "$OUT_ISO" | cut -f1)
  ok "ISO built: $OUT_ISO  ($SIZE)"
else
  fail "ISO not found — check $BUILD_DIR/build.log"
fi

# ── Checksum ──────────────────────────────────────────────────
sha256sum "$OUT_ISO" > "$OUT_ISO.sha256"
ok "SHA256: $(cat "$OUT_ISO.sha256" | cut -d' ' -f1)"

echo ""
echo -e "${BOLD}${GREEN}  TanyelOS 1.0 ISO ready.${RESET}"
echo ""
echo -e "  Test in QEMU:  ${CYAN}qemu-system-x86_64 -m 4G -cdrom $OUT_ISO -boot d${RESET}"
echo -e "  Flash to USB:  ${CYAN}sudo dd if=$OUT_ISO of=/dev/sdX bs=4M status=progress${RESET}"
echo -e "  Or use:        ${CYAN}https://etcher.balena.io${RESET}"
echo ""
