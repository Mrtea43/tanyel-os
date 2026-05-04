#!/usr/bin/env bash
# TanyelOS Theme Installer
# Transforms a fresh Ubuntu 24.04 LTS install into TanyelOS
# Usage: curl -fsSL https://... | bash   or   bash install.sh
#
# What this does:
#   1. Installs required fonts (Geist, JetBrains Mono)
#   2. Installs GNOME extensions (Dash to Panel, ArcMenu, Blur my Shell, etc.)
#   3. Copies GTK4/GTK3 theme files
#   4. Copies GNOME Shell theme
#   5. Installs Plymouth boot theme
#   6. Patches GDM login screen
#   7. Applies dconf settings (layout, colors, taskbar position)
#   8. Optionally sets wallpaper

set -euo pipefail

# ── Colors for output ─────────────────────────────────────────
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${CYAN}  →${RESET}  $*"; }
warn() { echo -e "${YELLOW}  !${RESET}  $*"; }
fail() { echo -e "${RED}  ✗${RESET}  $*"; exit 1; }
step() { echo -e "\n${BOLD}$*${RESET}"; }

# ── Check environment ─────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ $EUID -eq 0 ]]; then
  fail "Do not run as root. The script will sudo when needed."
fi

if ! command -v gnome-shell &>/dev/null; then
  fail "GNOME Shell not found. This installer requires Ubuntu with GNOME."
fi

GNOME_VER=$(gnome-shell --version | grep -oP '\d+' | head -1)
info "Detected GNOME Shell $GNOME_VER"

# ── Step 1: Install fonts ─────────────────────────────────────
step "1/7  Installing fonts"

FONT_DIR="$HOME/.local/share/fonts/TanyelOS"
mkdir -p "$FONT_DIR"

# Geist (Vercel's typeface — open source, OFL license)
if fc-list | grep -qi "Geist"; then
  ok "Geist already installed"
else
  info "Downloading Geist…"
  GEIST_TMP=$(mktemp -d)
  curl -fsSL "https://github.com/vercel/geist-font/releases/latest/download/Geist.zip" \
    -o "$GEIST_TMP/Geist.zip" || warn "Could not download Geist — skipping"
  if [[ -f "$GEIST_TMP/Geist.zip" ]]; then
    unzip -q "$GEIST_TMP/Geist.zip" -d "$GEIST_TMP/geist"
    find "$GEIST_TMP/geist" -name "*.ttf" -o -name "*.otf" | xargs -I{} cp {} "$FONT_DIR/"
    rm -rf "$GEIST_TMP"
    ok "Geist installed"
  fi
fi

# JetBrains Mono
if fc-list | grep -qi "JetBrains Mono"; then
  ok "JetBrains Mono already installed"
else
  info "Downloading JetBrains Mono…"
  JBM_TMP=$(mktemp -d)
  curl -fsSL "https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono-2.304.zip" \
    -o "$JBM_TMP/JBM.zip" || warn "Could not download JetBrains Mono — skipping"
  if [[ -f "$JBM_TMP/JBM.zip" ]]; then
    unzip -q "$JBM_TMP/JBM.zip" -d "$JBM_TMP/jbm"
    find "$JBM_TMP/jbm" -name "*.ttf" | grep -v "NL" | xargs -I{} cp {} "$FONT_DIR/"
    rm -rf "$JBM_TMP"
    ok "JetBrains Mono installed"
  fi
fi

fc-cache -f "$FONT_DIR" 2>/dev/null
ok "Font cache updated"

# ── Step 2: Install GNOME extensions ─────────────────────────
step "2/7  Installing GNOME extensions"

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"

install_extension() {
  local uuid="$1"
  local name="$2"
  if [[ -d "$EXT_DIR/$uuid" ]]; then
    ok "$name already installed"
    return
  fi
  info "Installing $name…"
  # Try gnome-extensions CLI first (available in GNOME 3.36+)
  if command -v gnome-extensions &>/dev/null; then
    # Get extension ID from extensions.gnome.org
    local ext_id
    ext_id=$(curl -s "https://extensions.gnome.org/extension-query/?search=$uuid" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['extensions'][0]['pk'])" 2>/dev/null || echo "")
    if [[ -n "$ext_id" ]]; then
      curl -fsSL "https://extensions.gnome.org/extension-data/${uuid}.v${GNOME_VER}.shell-extension.zip" \
        -o "/tmp/${uuid}.zip" 2>/dev/null || true
    fi
  fi
  # Fallback: manual download
  if [[ ! -f "/tmp/${uuid}.zip" ]]; then
    warn "Could not auto-install $name — install manually from https://extensions.gnome.org"
    warn "  Search for: $name"
    return
  fi
  mkdir -p "$EXT_DIR/$uuid"
  unzip -q "/tmp/${uuid}.zip" -d "$EXT_DIR/$uuid"
  rm -f "/tmp/${uuid}.zip"
  ok "$name installed"
}

# Required extensions
install_extension "dash-to-panel@jderose9.github.com"    "Dash to Panel"
install_extension "arcmenu@arcmenu.com"                   "ArcMenu"
install_extension "blur-my-shell@aunetx"                  "Blur my Shell"
install_extension "user-theme@gnome-shell-extensions.gcampax.github.com" "User Themes"
install_extension "just-perfection-desktop@just-perfection" "Just Perfection"

echo ""
warn "If any extensions failed to download, install them from:"
warn "  https://extensions.gnome.org"
warn "Then re-run this script to apply settings."

# ── Step 3: Install GTK theme ─────────────────────────────────
step "3/7  Installing GTK theme"

THEME_DEST_USER="$HOME/.local/share/themes/TanyelOS"
THEME_DEST_SYS="/usr/share/themes/TanyelOS"

install -dm755 "$THEME_DEST_USER"
install -dm755 "$THEME_DEST_USER/gtk-4.0"
install -dm755 "$THEME_DEST_USER/gtk-3.0"

cp "$SCRIPT_DIR/gtk-4.0/gtk.css" "$THEME_DEST_USER/gtk-4.0/gtk.css"
cp "$SCRIPT_DIR/gtk-3.0/gtk.css" "$THEME_DEST_USER/gtk-3.0/gtk.css"

# gtk.css in ~/.config/gtk-4.0 applies to all GTK4 apps
mkdir -p "$HOME/.config/gtk-4.0"
cp "$SCRIPT_DIR/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"

mkdir -p "$HOME/.config/gtk-3.0"
cp "$SCRIPT_DIR/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"

ok "GTK4 + GTK3 theme installed to ~/.local/share/themes/TanyelOS"

# ── Step 4: Install GNOME Shell theme ─────────────────────────
step "4/7  Installing GNOME Shell theme"

SHELL_THEME_DEST="$THEME_DEST_USER/gnome-shell"
mkdir -p "$SHELL_THEME_DEST"
cp "$SCRIPT_DIR/gnome-shell/gnome-shell.css" "$SHELL_THEME_DEST/gnome-shell.css"

ok "GNOME Shell theme installed"

# ── Step 5: Install Plymouth boot theme ───────────────────────
step "5/7  Installing Plymouth boot theme"

PLYMOUTH_DEST="/usr/share/plymouth/themes/tanyel"

if [[ -d "$PLYMOUTH_DEST" ]]; then
  ok "Plymouth theme already exists — overwriting"
fi

sudo install -dm755 "$PLYMOUTH_DEST"
sudo cp "$SCRIPT_DIR/plymouth/tanyel.script"  "$PLYMOUTH_DEST/tanyel.script"
sudo cp "$SCRIPT_DIR/plymouth/tanyel.plymouth" "$PLYMOUTH_DEST/tanyel.plymouth"

# Set as default Plymouth theme
sudo update-alternatives --install \
  /usr/share/plymouth/themes/default.plymouth \
  default.plymouth \
  "$PLYMOUTH_DEST/tanyel.plymouth" 200 || true

sudo update-plymouth-boot-screen 2>/dev/null \
  || sudo update-initramfs -u 2>/dev/null \
  || warn "Could not update initramfs — boot theme may not apply until next update"

ok "Plymouth boot theme installed"

# ── Step 6: Patch GDM login screen ────────────────────────────
step "6/7  Patching GDM login screen"

GDM_GRESOURCE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
GDM_CSS_DEST="/usr/share/gnome-shell/theme/tanyel-gdm.css"

if [[ ! -f "$GDM_GRESOURCE" ]]; then
  warn "GDM gresource not found — skipping login screen theme"
else
  sudo cp "$SCRIPT_DIR/gdm/tanyel-gdm.css" "$GDM_CSS_DEST"

  # Create override config
  GDM_CONF="/etc/gdm3/greeter.dconf-defaults"
  sudo tee "$GDM_CONF" > /dev/null <<'EOF'
[org/gnome/login-screen]
logo='/usr/share/pixmaps/tanyelos-logo.png'
disable-user-list=false
banner-message-enable=false

[org/gnome/desktop/interface]
gtk-theme='TanyelOS'
icon-theme='TanyelOS'
font-name='Geist 10'
color-scheme='prefer-dark'
EOF

  ok "GDM greeter config written"
  warn "Full GDM theme requires patching gnome-shell-theme.gresource."
  warn "See: https://github.com/thiggy01/change-gdm-background for a helper."
fi

# ── Step 7: Apply dconf settings ──────────────────────────────
step "7/7  Applying GNOME settings"

if command -v dconf &>/dev/null; then
  dconf load / < "$SCRIPT_DIR/tanyel-gnome.dconf"
  ok "dconf settings applied"
else
  warn "dconf not found — applying via gsettings"
  gsettings set org.gnome.desktop.interface gtk-theme 'TanyelOS'
  gsettings set org.gnome.desktop.interface icon-theme 'TanyelOS'
  gsettings set org.gnome.desktop.interface font-name 'Geist 10'
  gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 10'
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:'
  gsettings set org.gnome.desktop.wm.preferences theme 'TanyelOS'
  gsettings set org.gnome.shell.extensions.user-theme name 'TanyelOS'
fi

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}  TanyelOS theme installed.${RESET}"
echo ""
echo -e "  Next steps:"
echo -e "    1. ${CYAN}Log out and back in${RESET} (or run ${CYAN}Alt+F2 → r${RESET} to restart GNOME Shell)"
echo -e "    2. Open ${CYAN}Extensions${RESET} app and enable:"
echo -e "         • Dash to Panel"
echo -e "         • ArcMenu"
echo -e "         • Blur my Shell"
echo -e "         • User Themes"
echo -e "         • Just Perfection"
echo -e "    3. Open ${CYAN}Tweaks${RESET} app → Appearance → Shell → TanyelOS"
echo -e "    4. Reboot to see the Plymouth boot animation"
echo ""
echo -e "  To uninstall: bash ${CYAN}$SCRIPT_DIR/uninstall.sh${RESET}"
echo ""
