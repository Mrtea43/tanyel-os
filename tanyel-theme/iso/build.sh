#!/usr/bin/env bash
# TanyelOS ISO Builder — remaster approach
# Downloads official Ubuntu ISO, injects TanyelOS theme, repacks.
# Much faster than live-build (~20 min vs 60+ min).

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'
ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${CYAN}  →${RESET}  $*"; }
fail() { echo -e "${RED}  ✗${RESET}  $*"; exit 1; }
step() { echo -e "\n${BOLD}── $* ──${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="$SCRIPT_DIR/work"
OUT_ISO="$SCRIPT_DIR/tanyelos-1.0-amd64.iso"

UBUNTU_ISO_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.2-desktop-amd64.iso"
UBUNTU_ISO="$SCRIPT_DIR/ubuntu-base.iso"

[[ $EUID -ne 0 ]] && fail "Run as root: sudo bash build.sh"

for cmd in xorriso unsquashfs mksquashfs curl; do
  command -v "$cmd" &>/dev/null || fail "Missing: $cmd"
done
ok "All tools present"

# ── Step 1: Download Ubuntu base ISO ─────────────────────────
step "Downloading Ubuntu 24.04 base ISO (~5 GB)"
if [[ ! -f "$UBUNTU_ISO" ]]; then
  info "Downloading from $UBUNTU_ISO_URL"
  curl -L --progress-bar "$UBUNTU_ISO_URL" -o "$UBUNTU_ISO"
  ok "Downloaded"
else
  ok "Already downloaded — skipping"
fi

# ── Step 2: Extract ISO ───────────────────────────────────────
step "Extracting ISO"
rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR/iso" "$WORK_DIR/mnt" "$WORK_DIR/newfs"

info "Mounting ISO"
mount -o loop,ro "$UBUNTU_ISO" "$WORK_DIR/mnt"
info "Copying ISO contents"
cp -a "$WORK_DIR/mnt/." "$WORK_DIR/iso/"
umount "$WORK_DIR/mnt"
chmod -R u+w "$WORK_DIR/iso"
ok "ISO extracted"

# ── Step 3: Extract squashfs filesystem ───────────────────────
step "Extracting filesystem"

# Debug: show ISO structure so we can find squashfs
echo "  ISO contents:"
find "$WORK_DIR/iso" -maxdepth 3 | sed 's/^/    /'

# Ubuntu 24.04 stores squashfs under casper/ with various names
SQUASH_FILE=$(find "$WORK_DIR/iso" \( \
  -name "*.squashfs" -o \
  -name "*.sqfs" -o \
  -name "minimal.squashfs" -o \
  -name "filesystem.squashfs" \
\) | grep -v "README" | sort | tail -1)

[[ -z "$SQUASH_FILE" ]] && fail "Could not find squashfs filesystem in ISO. Check structure above."

info "Using squashfs: $SQUASH_FILE"
unsquashfs -d "$WORK_DIR/newfs" "$SQUASH_FILE"
ok "Filesystem extracted"

# ── Step 4: Apply TanyelOS theme ─────────────────────────────
step "Applying TanyelOS theme"

FS="$WORK_DIR/newfs"

# Mount /proc /sys /dev for chroot
mount --bind /proc "$FS/proc"
mount --bind /sys  "$FS/sys"
mount --bind /dev  "$FS/dev"
mount --bind /dev/pts "$FS/dev/pts"

# Copy theme files into filesystem
info "Copying theme files"

# GTK themes
install -dm755 "$FS/usr/share/themes/TanyelOS/gtk-4.0"
install -dm755 "$FS/usr/share/themes/TanyelOS/gtk-3.0"
cp "$SCRIPT_DIR/config/includes.chroot/usr/share/themes/TanyelOS/gtk-4.0/gtk.css" \
   "$FS/usr/share/themes/TanyelOS/gtk-4.0/gtk.css"
cp "$SCRIPT_DIR/config/includes.chroot/usr/share/themes/TanyelOS/gtk-3.0/gtk.css" \
   "$FS/usr/share/themes/TanyelOS/gtk-3.0/gtk.css"

# GTK user config (applies to live user)
install -dm755 "$FS/etc/skel/.config/gtk-4.0"
install -dm755 "$FS/etc/skel/.config/gtk-3.0"
cp "$SCRIPT_DIR/config/includes.chroot/etc/skel/.config/gtk-4.0/gtk.css" \
   "$FS/etc/skel/.config/gtk-4.0/gtk.css"
cp "$SCRIPT_DIR/config/includes.chroot/etc/skel/.config/gtk-3.0/gtk.css" \
   "$FS/etc/skel/.config/gtk-3.0/gtk.css"

# GNOME Shell theme
install -dm755 "$FS/usr/share/gnome-shell/theme"
cp "$SCRIPT_DIR/config/includes.chroot/usr/share/gnome-shell/theme/tanyel-gnome-shell.css" \
   "$FS/usr/share/gnome-shell/theme/"

# Plymouth boot theme
install -dm755 "$FS/usr/share/plymouth/themes/tanyel"
cp "$SCRIPT_DIR/config/includes.chroot/usr/share/plymouth/themes/tanyel/"* \
   "$FS/usr/share/plymouth/themes/tanyel/"

# dconf system database
install -dm755 "$FS/etc/dconf/db/tanyel.d"
install -dm755 "$FS/etc/dconf/profile"
cp "$SCRIPT_DIR/config/includes.chroot/etc/dconf/db/tanyel.d/00-tanyelos" \
   "$FS/etc/dconf/db/tanyel.d/00-tanyelos"
cp "$SCRIPT_DIR/config/includes.chroot/etc/dconf/profile/user" \
   "$FS/etc/dconf/profile/user"

# Theme index
cat > "$FS/usr/share/themes/TanyelOS/index.theme" <<'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=TanyelOS
Comment=TanyelOS desktop theme
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=TanyelOS
MetacityTheme=TanyelOS
IconTheme=Yaru-teal-dark
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:
EOF

ok "Theme files copied"

# Run inside chroot
info "Running chroot setup"
chroot "$FS" /bin/bash <<'CHROOT'
set -e

# Install GNOME extensions
EXT_DIR="/usr/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"

install_ext() {
  local uuid="$1" url="$2"
  [[ -d "$EXT_DIR/$uuid" ]] && return
  echo "    installing $uuid"
  curl -fsSL "$url" -o "/tmp/ext.zip" 2>/dev/null && \
    mkdir -p "$EXT_DIR/$uuid" && \
    unzip -q "/tmp/ext.zip" -d "$EXT_DIR/$uuid" && \
    rm -f "/tmp/ext.zip" || echo "    skipped $uuid"
}

install_ext "dash-to-panel@jderose9.github.com" \
  "https://extensions.gnome.org/extension-data/dash-to-paneljderose9.github.com.v64.shell-extension.zip"
install_ext "arcmenu@arcmenu.com" \
  "https://extensions.gnome.org/extension-data/arcmenuarcmenu.com.v60.shell-extension.zip"
install_ext "blur-my-shell@aunetx" \
  "https://extensions.gnome.org/extension-data/blur-my-shellaunetx.v66.shell-extension.zip"
install_ext "user-theme@gnome-shell-extensions.gcampax.github.com" \
  "https://extensions.gnome.org/extension-data/user-themegnome-shell-extensions.gcampax.github.com.v54.shell-extension.zip"
install_ext "just-perfection-desktop@just-perfection" \
  "https://extensions.gnome.org/extension-data/just-perfection-desktopjust-perfection.v28.shell-extension.zip"

# Install JetBrains Mono font
curl -fsSL "https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono-2.304.zip" \
  -o /tmp/jbm.zip 2>/dev/null && \
  unzip -q /tmp/jbm.zip -d /tmp/jbm && \
  mkdir -p /usr/share/fonts/truetype/jetbrains-mono && \
  find /tmp/jbm -name "*.ttf" | grep -v NL | xargs -I{} cp {} /usr/share/fonts/truetype/jetbrains-mono/ && \
  rm -rf /tmp/jbm /tmp/jbm.zip || echo "Font install skipped"

# Compile dconf
dconf update 2>/dev/null || true

# Set Plymouth theme
update-alternatives --install \
  /usr/share/plymouth/themes/default.plymouth \
  default.plymouth \
  /usr/share/plymouth/themes/tanyel/tanyel.plymouth \
  200 2>/dev/null || true

# Set live session hostname
echo "tanyelos" > /etc/hostname
sed -i 's/ubuntu/tanyelos/g' /etc/hosts 2>/dev/null || true

# Font cache
fc-cache -f 2>/dev/null || true

echo "Chroot setup complete"
CHROOT

# Unmount
umount "$FS/dev/pts" "$FS/dev" "$FS/sys" "$FS/proc" 2>/dev/null || true
ok "Theme applied"

# ── Step 5: Repack squashfs ───────────────────────────────────
step "Repacking filesystem (takes ~5 min)"
rm -f "$SQUASH_FILE"
mksquashfs "$WORK_DIR/newfs" "$SQUASH_FILE" -comp xz -noappend -quiet
ok "Filesystem repacked: $(du -sh "$SQUASH_FILE" | cut -f1)"

# Update filesystem size
printf $(du -sx --block-size=1 "$WORK_DIR/newfs" | cut -f1) > \
  "$(dirname "$SQUASH_FILE")/filesystem.size" 2>/dev/null || true

# ── Step 6: Rebuild ISO ───────────────────────────────────────
step "Building final ISO"

# Get original ISO label
ISO_LABEL=$(xorriso -indev "$UBUNTU_ISO" -report_system_area as_mkisofs 2>/dev/null | grep -o 'LABEL=[^ ]*' | head -1 | cut -d= -f2 || echo "TanyelOS")

xorriso -as mkisofs \
  -r -V "TanyelOS 1.0" \
  -o "$OUT_ISO" \
  -J -joliet-long \
  -b boot/grub/i386-pc/eltorito.img \
  -c boot/grub/i386-pc/boot.cat \
  -no-emul-boot -boot-load-size 4 -boot-info-table \
  --grub2-boot-info \
  --grub2-mbr "$WORK_DIR/iso/boot/grub/i386-pc/boot_hybrid.img" \
  -eltorito-alt-boot \
  -e --interval:appended_partition_2:all:: \
  -no-emul-boot -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b \
  "$WORK_DIR/iso/boot/grub/efi.img" \
  -iso_mbr_part_type a2a0d0ebe5b9334487c068b6b72699c7 \
  "$WORK_DIR/iso" 2>/dev/null || \
xorriso -as mkisofs \
  -r -V "TanyelOS 1.0" \
  -o "$OUT_ISO" \
  -J -joliet-long \
  "$WORK_DIR/iso"

SIZE=$(du -sh "$OUT_ISO" | cut -f1)
ok "ISO built: $OUT_ISO ($SIZE)"

sha256sum "$OUT_ISO" > "$OUT_ISO.sha256"
ok "SHA256: $(cut -d' ' -f1 "$OUT_ISO.sha256")"

echo ""
echo -e "${BOLD}${GREEN}  TanyelOS 1.0 ISO ready.${RESET}"
echo ""
