#!/usr/bin/env bash
# TanyelOS Installer — transforms Ubuntu 24.04 into TanyelOS
# Run from the tanyel-theme/ directory: bash install.sh

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'
GREEN='\033[0;32m'; CYAN='\033[0;36m'; YELLOW='\033[1;33m'; RED='\033[0;31m'
ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${CYAN}  →${RESET}  $*"; }
warn() { echo -e "${YELLOW}  !${RESET}  $*"; }
fail() { echo -e "${RED}  ✗${RESET}  $*"; exit 1; }
step() { echo -e "\n${BOLD}── $* ──${RESET}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

[[ $EUID -eq 0 ]] && fail "Do not run as root. The script will sudo when needed."
command -v gnome-shell &>/dev/null || fail "GNOME Shell not found. Requires Ubuntu with GNOME."

GNOME_VER=$(gnome-shell --version | grep -oP '\d+' | head -1)
info "GNOME Shell $GNOME_VER detected"

# ── 1. Fonts ──────────────────────────────────────────────────
step "1/6  Fonts"

FONT_DIR="$HOME/.local/share/fonts/TanyelOS"
mkdir -p "$FONT_DIR"

install_font_zip() {
  local name="$1" url="$2" pattern="$3"
  fc-list | grep -qi "$name" && { ok "$name already installed"; return; }
  info "Downloading $name…"
  local tmp; tmp=$(mktemp -d)
  curl -fsSL "$url" -o "$tmp/font.zip" 2>/dev/null || { warn "Could not download $name — skipping"; rm -rf "$tmp"; return; }
  unzip -q "$tmp/font.zip" -d "$tmp/out"
  find "$tmp/out" -name "$pattern" | xargs -I{} cp {} "$FONT_DIR/"
  rm -rf "$tmp"
  ok "$name installed"
}

install_font_zip "Geist" \
  "https://github.com/vercel/geist-font/releases/latest/download/Geist.zip" \
  "*.ttf"

install_font_zip "JetBrains Mono" \
  "https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono-2.304.zip" \
  "*.ttf"

fc-cache -f "$FONT_DIR" 2>/dev/null
ok "Font cache updated"

# ── 2. GNOME extensions ───────────────────────────────────────
step "2/6  GNOME extensions"

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"

install_extension() {
  local uuid="$1" name="$2"
  local ext_dir="$EXT_DIR/$uuid"

  if [[ -d "$ext_dir" ]]; then
    ok "$name already installed"
    return 0
  fi

  info "Fetching $name for GNOME $GNOME_VER…"

  local download_url
  download_url=$(curl -fsSL \
    "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${GNOME_VER}" \
    2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('download_url',''))" \
    2>/dev/null) || download_url=""

  if [[ -z "$download_url" ]]; then
    warn "$name: no compatible version for GNOME $GNOME_VER — install manually"
    warn "  → https://extensions.gnome.org/?q=$(echo "$name" | tr ' ' '+')"
    return 0
  fi

  curl -fsSL "https://extensions.gnome.org${download_url}" -o "/tmp/${uuid}.zip" 2>/dev/null || {
    warn "$name: download failed"
    return 0
  }

  mkdir -p "$ext_dir"
  unzip -q "/tmp/${uuid}.zip" -d "$ext_dir" 2>/dev/null || {
    warn "$name: extraction failed"
    rm -rf "$ext_dir"
    return 0
  }
  rm -f "/tmp/${uuid}.zip"
  ok "$name installed"
}

install_extension "dash-to-panel@jderose9.github.com"                        "Dash to Panel"
install_extension "arcmenu@arcmenu.com"                                       "ArcMenu"
install_extension "blur-my-shell@aunetx"                                      "Blur my Shell"
install_extension "user-theme@gnome-shell-extensions.gcampax.github.com"     "User Themes"
install_extension "just-perfection-desktop@just-perfection"                   "Just Perfection"

# ── 3. GTK theme ──────────────────────────────────────────────
step "3/6  GTK theme"

THEME_DIR="$HOME/.local/share/themes/TanyelOS"
mkdir -p "$THEME_DIR/gtk-4.0" "$THEME_DIR/gtk-3.0" "$THEME_DIR/gnome-shell"

cp "$SCRIPT_DIR/gtk-4.0/gtk.css" "$THEME_DIR/gtk-4.0/gtk.css"
cp "$SCRIPT_DIR/gtk-3.0/gtk.css" "$THEME_DIR/gtk-3.0/gtk.css"

mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0"
cp "$SCRIPT_DIR/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
cp "$SCRIPT_DIR/gtk-3.0/gtk.css" "$HOME/.config/gtk-3.0/gtk.css"

cat > "$THEME_DIR/index.theme" <<'EOF'
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

ok "GTK theme installed"

# ── 4. GNOME Shell theme ──────────────────────────────────────
step "4/6  GNOME Shell theme"

cp "$SCRIPT_DIR/gnome-shell/gnome-shell.css" "$THEME_DIR/gnome-shell/gnome-shell.css"
ok "GNOME Shell theme installed"

# ── 5. Plymouth boot theme ────────────────────────────────────
step "5/6  Plymouth boot theme"

sudo install -dm755 /usr/share/plymouth/themes/tanyel
sudo cp "$SCRIPT_DIR/plymouth/tanyel.script"   /usr/share/plymouth/themes/tanyel/
sudo cp "$SCRIPT_DIR/plymouth/tanyel.plymouth" /usr/share/plymouth/themes/tanyel/

sudo update-alternatives --install \
  /usr/share/plymouth/themes/default.plymouth \
  default.plymouth \
  /usr/share/plymouth/themes/tanyel/tanyel.plymouth \
  200 2>/dev/null || true

sudo update-initramfs -u 2>/dev/null || warn "Could not update initramfs — reboot may not show boot animation"
ok "Plymouth boot theme installed"

# ── 6. Apply GNOME settings ───────────────────────────────────
step "6/6  Applying GNOME settings"

# Generate Aurora wallpaper using ImageMagick
info "Generating Aurora wallpaper…"
sudo apt-get install -y imagemagick 2>/dev/null || true

WP_DIR="$HOME/.local/share/wallpapers/tanyel"
mkdir -p "$WP_DIR"

if command -v convert &>/dev/null; then
  convert -size 1920x1080 \
    gradient:'#1B2035-#141822' \
    \( -size 1920x1080 xc:none \
       -fill 'rgba(43,158,168,0.45)' \
       -draw "circle 480,360 900,360" \
       -blur 0x180 \) \
    -compose over -composite \
    \( -size 1920x1080 xc:none \
       -fill 'rgba(91,143,255,0.30)' \
       -draw "circle 1500,750 1900,750" \
       -blur 0x180 \) \
    -compose over -composite \
    "$WP_DIR/aurora.jpg" 2>/dev/null
  ok "Aurora wallpaper generated"
else
  warn "ImageMagick missing — wallpaper not generated"
fi

# Apply dconf system defaults
dconf load / < "$SCRIPT_DIR/tanyel-gnome.dconf"

# Force key settings via gsettings (takes effect immediately)
gsettings set org.gnome.desktop.interface gtk-theme 'TanyelOS' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11' 2>/dev/null || true
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true

if [[ -f "$WP_DIR/aurora.jpg" ]]; then
  gsettings set org.gnome.desktop.background picture-uri "file://$WP_DIR/aurora.jpg" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WP_DIR/aurora.jpg" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null || true
fi

# Enable all extensions
for uuid in \
  "dash-to-panel@jderose9.github.com" \
  "arcmenu@arcmenu.com" \
  "blur-my-shell@aunetx" \
  "user-theme@gnome-shell-extensions.gcampax.github.com" \
  "just-perfection-desktop@just-perfection"
do
  gnome-extensions enable "$uuid" 2>/dev/null || true
done

ok "Settings applied"

# ── 7. Neofetch branding ──────────────────────────────────────
step "7/7  Neofetch branding"

sudo apt-get install -y --no-install-recommends neofetch 2>/dev/null || true

NEOF_DIR="$HOME/.config/neofetch"
mkdir -p "$NEOF_DIR"

cat > "$NEOF_DIR/config.conf" <<'NEOF'
print_info() {
    info title
    info underline
    info "OS"         distro
    info "Host"       model
    info "Kernel"     kernel
    info "Shell"      shell
    info "Theme"      theme
    info "Uptime"     uptime
    prin ""
}

# Custom ASCII art (the TOS logo)
ascii_distro="auto"
image_backend="ascii"

ascii_colors=(6 6 6 6 6 6)
bold="on"
underline_enabled="on"
separator=":"

distro_shorthand="off"
os_arch="off"
kernel_shorthand="on"
shell_path="off"
shell_version="off"
uptime_shorthand="tiny"
theme_bold="off"
NEOF

# Custom ASCII art for neofetch
cat > "$NEOF_DIR/ascii" <<'ASCII'
   ████████
  ██      ██
  ██  ██  ██
  ██  ████ ██
  ██      ██
   ████████
  TanyelOS
ASCII

# Override distro name shown by neofetch
sudo tee /etc/os-release-tanyel > /dev/null <<'EOF'
NAME="TanyelOS"
VERSION="1.0"
ID=tanyelos
ID_LIKE=ubuntu
PRETTY_NAME="TanyelOS 1.0"
VERSION_ID="1.0"
EOF

ok "Neofetch configured"

# ── Done ──────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}  TanyelOS installed.${RESET}"
echo ""
echo -e "  ${BOLD}Next:${RESET} Log out and back in — TanyelOS will be active."
echo -e "  If the shell theme isn't applied, open ${CYAN}Tweaks${RESET} →"
echo -e "  Appearance → Shell → select ${CYAN}TanyelOS${RESET}"
echo ""
