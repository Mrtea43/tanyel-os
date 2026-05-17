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

# ── 0. Prerequisites ──────────────────────────────────────────
step "0/6  Prerequisites"
info "Installing required packages…"
sudo apt-get update -qq 2>/dev/null || true
sudo apt-get install -y --no-install-recommends \
  curl unzip dconf-cli libglib2.0-bin gettext \
  gnome-shell-extensions gnome-tweaks \
  fonts-jetbrains-mono imagemagick 2>&1 | tail -3 || warn "Some packages could not be installed"
ok "Prerequisites ready"

# ── 1. Fonts ──────────────────────────────────────────────────
step "1/6  Fonts"

FONT_DIR="$HOME/.local/share/fonts/TanyelOS"
mkdir -p "$FONT_DIR"

install_font_zip() {
  local name="$1" url="$2" pattern="$3"
  fc-list | grep -qi "$name" && { ok "$name already installed"; return 0; }
  info "Downloading $name…"
  local tmp; tmp=$(mktemp -d)
  if ! curl -fsSL "$url" -o "$tmp/font.zip" 2>/dev/null; then
    warn "Could not download $name — skipping"
    rm -rf "$tmp"
    return 1
  fi
  unzip -q "$tmp/font.zip" -d "$tmp/out" 2>/dev/null || { warn "$name: zip extraction failed"; rm -rf "$tmp"; return 1; }
  find "$tmp/out" -type f \( -name "$pattern" -o -name "${pattern/.ttf/.otf}" \) -exec cp {} "$FONT_DIR/" \; 2>/dev/null || true
  rm -rf "$tmp"
  ok "$name installed"
  return 0
}

# Try Geist; if it fails, install Inter from apt as fallback
if ! install_font_zip "Geist" \
  "https://github.com/vercel/geist-font/releases/latest/download/Geist.zip" \
  "*.ttf"; then
  info "Falling back to Inter via apt…"
  sudo apt-get install -y --no-install-recommends fonts-inter 2>/dev/null \
    && ok "Inter installed (Geist substitute)" \
    || warn "Inter unavailable too — system default font will be used"
fi

# JetBrains Mono is already installed via apt in step 0
ok "JetBrains Mono already installed (apt)"

fc-cache -f "$FONT_DIR" 2>/dev/null || true
ok "Font cache updated"

# ── 2. GNOME extensions ───────────────────────────────────────
step "2/6  GNOME extensions"

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"
mkdir -p "$EXT_DIR"

install_extension() {
  local uuid="$1" name="$2"
  local ext_dir="$EXT_DIR/$uuid"
  local sys_ext_dir="/usr/share/gnome-shell/extensions/$uuid"
  local local_zip="$SCRIPT_DIR/extensions/${uuid}.zip"

  if [[ -d "$ext_dir" && -n "$(ls -A "$ext_dir" 2>/dev/null)" ]]; then
    ok "$name already installed (user)"
    return 0
  fi

  if [[ -d "$sys_ext_dir" && -n "$(ls -A "$sys_ext_dir" 2>/dev/null)" ]]; then
    ok "$name already installed (system, via apt)"
    return 0
  fi

  # Try local bundled zip first (most reliable)
  if [[ -f "$local_zip" ]]; then
    info "Installing $name from bundled zip…"
    mkdir -p "$ext_dir"
    unzip -qo "$local_zip" -d "$ext_dir" 2>/dev/null && {
      # Compile schemas if present
      if [[ -d "$ext_dir/schemas" ]]; then
        glib-compile-schemas "$ext_dir/schemas/" 2>/dev/null || true
      fi
      ok "$name installed (bundled)"
      return 0
    }
    warn "$name: bundled zip extraction failed"
  fi

  # Fallback: GNOME extensions API
  info "Fetching $name for GNOME $GNOME_VER from extensions.gnome.org…"
  local download_url
  download_url=$(curl -fsSL \
    "https://extensions.gnome.org/extension-info/?uuid=${uuid}&shell_version=${GNOME_VER}" \
    2>/dev/null | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('download_url',''))" \
    2>/dev/null) || download_url=""

  if [[ -z "$download_url" ]]; then
    warn "$name: install manually → https://extensions.gnome.org/?q=$(echo "$name" | tr ' ' '+')"
    return 0
  fi

  curl -fsSL "https://extensions.gnome.org${download_url}" -o "/tmp/${uuid}.zip" 2>/dev/null || {
    warn "$name: download failed"
    return 0
  }

  mkdir -p "$ext_dir"
  unzip -qo "/tmp/${uuid}.zip" -d "$ext_dir" 2>/dev/null || {
    warn "$name: extraction failed"
    rm -rf "$ext_dir"
    return 0
  }
  if [[ -d "$ext_dir/schemas" ]]; then
    glib-compile-schemas "$ext_dir/schemas/" 2>/dev/null || true
  fi
  rm -f "/tmp/${uuid}.zip"
  ok "$name installed"
}

install_extension "dash-to-dock@micxgx.gmail.com"                            "Dash to Dock"
install_extension "arcmenu@arcmenu.com"                                      "ArcMenu"
install_extension "blur-my-shell@aunetx"                                     "Blur my Shell"
install_extension "user-theme@gnome-shell-extensions.gcampax.github.com"    "User Themes"
install_extension "just-perfection-desktop@just-perfection"                  "Just Perfection"
install_extension "window-list@gnome-shell-extensions.gcampax.github.com"   "Window List"

# Fork Window List to user scope so we ship our own stylesheets. User
# extensions in ~/.local/share/gnome-shell/extensions/ take precedence over
# system ones at /usr/share/gnome-shell/extensions/, so this doesn't touch
# system files (apt upgrades won't clobber it either).
fork_window_list() {
  local uuid="window-list@gnome-shell-extensions.gcampax.github.com"
  local sys="/usr/share/gnome-shell/extensions/$uuid"
  local usr="$HOME/.local/share/gnome-shell/extensions/$uuid"
  local src="$SCRIPT_DIR/extensions/window-list"

  if [[ ! -d "$sys" ]]; then
    warn "Window List not installed system-wide; skipping fork"
    return
  fi
  if [[ ! -f "$src/stylesheet-dark.css" ]]; then
    warn "TanyelOS Window List stylesheets not found at $src; skipping fork"
    return
  fi

  mkdir -p "$usr"
  cp -rf "$sys"/* "$usr/"
  cp -f "$src/stylesheet-dark.css"  "$usr/stylesheet-dark.css"
  cp -f "$src/stylesheet-light.css" "$usr/stylesheet-light.css"
  ok "Window List forked + restyled at $usr"
}
fork_window_list

# ── 3. Build TanyelOS-Light + TanyelOS-Dark theme variants ───────
step "3/6  Building light and dark theme variants"

# Sentinel-token sed expressions for each variant
DARK_GTK_SED='
s|/\*BG0\*/[^/]*/\*ENDBG0\*/|#252935|g
s|/\*BG1\*/[^/]*/\*ENDBG1\*/|#2C3141|g
s|/\*BG2\*/[^/]*/\*ENDBG2\*/|#1B1F2A|g
s|/\*FG0\*/[^/]*/\*ENDFG0\*/|#F5F3EF|g
s|/\*FG1\*/[^/]*/\*ENDFG1\*/|#C7C2BB|g
s|/\*FG2\*/[^/]*/\*ENDFG2\*/|#948E88|g
s|/\*LINE\*/[^/]*/\*ENDLINE\*/|#3A3F52|g
s|/\*LINESOFT\*/[^/]*/\*ENDLINESOFT\*/|#323749|g
s|/\*ACCENTSOFT\*/[^/]*/\*ENDACCENTSOFT\*/|#1A3B42|g
'
LIGHT_GTK_SED='
s|/\*BG0\*/[^/]*/\*ENDBG0\*/|#FDFCFB|g
s|/\*BG1\*/[^/]*/\*ENDBG1\*/|#F5F2EC|g
s|/\*BG2\*/[^/]*/\*ENDBG2\*/|#EDEAE4|g
s|/\*FG0\*/[^/]*/\*ENDFG0\*/|#312E29|g
s|/\*FG1\*/[^/]*/\*ENDFG1\*/|#635E57|g
s|/\*FG2\*/[^/]*/\*ENDFG2\*/|#9B9590|g
s|/\*LINE\*/[^/]*/\*ENDLINE\*/|#D8D4CF|g
s|/\*LINESOFT\*/[^/]*/\*ENDLINESOFT\*/|#E5E1DC|g
s|/\*ACCENTSOFT\*/[^/]*/\*ENDACCENTSOFT\*/|#DCF0F2|g
'

build_gtk_variant() {
  local variant="$1" src="$2" dest="$3"
  local sed_script
  if [[ "$variant" == "DARK" ]]; then sed_script="$DARK_GTK_SED"; else sed_script="$LIGHT_GTK_SED"; fi
  sed "$sed_script" "$src" | sudo tee "$dest" > /dev/null
}

# Shell CSS color flip for light variant (two-pass to avoid conflicts)
build_shell_variant() {
  local variant="$1" src="$2" dest="$3"
  if [[ "$variant" == "DARK" ]]; then
    sudo cp "$src" "$dest"
    return
  fi
  # Light variant: invert dark colors → light, and light states → dark equivalents
  sed \
    -e 's/rgba(27, *31, *42,/__P1__/g' \
    -e 's/rgba(37, *41, *53,/__P2__/g' \
    -e 's/rgba(58, *63, *82,/__P3__/g' \
    -e 's/rgba(44, *49, *65,/__P4__/g' \
    -e 's/rgba(245, *243, *239,/__P5__/g' \
    -e 's/rgba(253, *252, *251,/__P6__/g' \
    -e 's/rgba(216, *212, *207,/__P7__/g' \
    -e 's/color: *#F5F3EF/__C1__/g' \
    -e 's/color: *#FFFFFF/__C2__/g' \
    -e 's/color: *#C7C2BB/__C3__/g' \
    -e 's/color: *#312E29/__C4__/g' \
    -e 's/color: *#635E57/__C5__/g' \
    -e 's/border: *0\.5px solid *#3A3F52/__B1__/g' \
    "$src" | \
  sed \
    -e 's|__P1__|rgba(253, 252, 251,|g' \
    -e 's|__P2__|rgba(245, 243, 239,|g' \
    -e 's|__P3__|rgba(216, 212, 207,|g' \
    -e 's|__P4__|rgba(237, 234, 229,|g' \
    -e 's|__P5__|rgba(49, 46, 41,|g' \
    -e 's|__P6__|rgba(253, 252, 251,|g' \
    -e 's|__P7__|rgba(216, 212, 207,|g' \
    -e 's|__C1__|color: #312E29|g' \
    -e 's|__C2__|color: #312E29|g' \
    -e 's|__C3__|color: #635E57|g' \
    -e 's|__C4__|color: #312E29|g' \
    -e 's|__C5__|color: #635E57|g' \
    -e 's|__B1__|border: 0.5px solid #D8D4CF|g' \
    | sudo tee "$dest" > /dev/null
}

for variant in DARK LIGHT; do
  variant_name="$([ "$variant" = "DARK" ] && echo "Dark" || echo "Light")"
  theme_dir="/usr/share/themes/TanyelOS-${variant_name}"
  info "Building TanyelOS-${variant_name}…"

  sudo mkdir -p "${theme_dir}/gtk-3.0" "${theme_dir}/gtk-4.0" "${theme_dir}/gnome-shell"

  build_gtk_variant "${variant}" "$SCRIPT_DIR/gtk-4.0/gtk.css" "${theme_dir}/gtk-4.0/gtk.css"
  build_gtk_variant "${variant}" "$SCRIPT_DIR/gtk-3.0/gtk.css" "${theme_dir}/gtk-3.0/gtk.css"
  build_shell_variant "${variant}" "$SCRIPT_DIR/gnome-shell/gnome-shell.css" "${theme_dir}/gnome-shell/gnome-shell.css"

  sudo tee "${theme_dir}/index.theme" > /dev/null <<EOF
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=TanyelOS-${variant_name}
Comment=TanyelOS desktop theme — ${variant_name}
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=TanyelOS-${variant_name}
MetacityTheme=TanyelOS-${variant_name}
IconTheme=Yaru-teal-dark
CursorTheme=Adwaita
ButtonLayout=close,minimize,maximize:
EOF
  ok "  TanyelOS-${variant_name} installed to ${theme_dir}"
done

# Also install user-level gtk.css (per-user override) — use Dark variant by default
mkdir -p "$HOME/.config/gtk-4.0" "$HOME/.config/gtk-3.0"
sudo cp "/usr/share/themes/TanyelOS-Dark/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || \
  build_gtk_variant "DARK" "$SCRIPT_DIR/gtk-4.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
sudo chown "$USER:$USER" "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null || true

# ── 5. Plymouth boot theme ────────────────────────────────────
step "5/6  Plymouth boot theme"

sudo install -dm755 /usr/share/plymouth/themes/tanyel
sudo cp "$SCRIPT_DIR/plymouth/tanyel.script"   /usr/share/plymouth/themes/tanyel/
sudo cp "$SCRIPT_DIR/plymouth/tanyel.plymouth" /usr/share/plymouth/themes/tanyel/

# Generate logo.png for Plymouth (96x96 rounded teal square with white T)
if command -v convert &>/dev/null; then
  info "Generating Plymouth logo…"
  TMPLOGO=$(mktemp -d)
  # Rounded teal square (96x96)
  convert -size 96x96 xc:none \
    -fill '#2B9EA8' -draw "roundrectangle 0,0 95,95 22,22" \
    "$TMPLOGO/logo-bg.png" 2>/dev/null
  # White "T" overlay
  convert "$TMPLOGO/logo-bg.png" \
    -fill white -font DejaVu-Sans-Bold -pointsize 60 \
    -gravity center -annotate +0+0 'T' \
    "$TMPLOGO/logo.png" 2>/dev/null
  if [[ -f "$TMPLOGO/logo.png" ]]; then
    sudo cp "$TMPLOGO/logo.png" /usr/share/plymouth/themes/tanyel/logo.png
  fi
  rm -rf "$TMPLOGO"
fi

sudo update-alternatives --install \
  /usr/share/plymouth/themes/default.plymouth \
  default.plymouth \
  /usr/share/plymouth/themes/tanyel/tanyel.plymouth \
  200 2>/dev/null || true

sudo update-alternatives --set default.plymouth \
  /usr/share/plymouth/themes/tanyel/tanyel.plymouth 2>/dev/null || true

# Ensure GRUB has 'quiet splash' so Plymouth shows on boot
GRUB_FILE="/etc/default/grub"
if [[ -f "$GRUB_FILE" ]] && ! grep -q 'splash' "$GRUB_FILE"; then
  info "Enabling Plymouth splash in GRUB…"
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' "$GRUB_FILE"
  sudo update-grub 2>/dev/null || warn "update-grub failed"
fi

# Set Plymouth theme via plymouth-set-default-theme (most reliable method)
if command -v plymouth-set-default-theme &>/dev/null; then
  sudo plymouth-set-default-theme -R tanyel 2>/dev/null || \
    sudo update-initramfs -u 2>/dev/null || \
    warn "Could not regenerate initramfs"
else
  sudo update-initramfs -u 2>/dev/null || warn "Could not update initramfs"
fi

ok "Plymouth boot theme installed"

# ── 6. Apply GNOME settings ───────────────────────────────────
step "6/6  Applying GNOME settings"

WP_DIR="$HOME/.local/share/wallpapers/tanyel"

# Install accent-applier scripts (instant change + background wallpaper regen)
info "Installing accent applier…"
sudo install -m 755 "$SCRIPT_DIR/scripts/apply-accent.sh"      /usr/local/bin/tanyel-apply-accent
sudo install -m 755 "$SCRIPT_DIR/scripts/regen-wallpapers.sh"  /usr/local/bin/tanyel-regen-wallpapers
ok "tanyel-apply-accent + tanyel-regen-wallpapers installed"

# Pre-generate all 5 wallpapers at install time (synchronous)
info "Pre-generating all 5 wallpapers…"
/usr/local/bin/tanyel-regen-wallpapers "#2B9EA8" "" 2>&1 | sed 's/^/  /' || warn "Wallpaper generation failed"
# Apply accent + set initial wallpaper
/usr/local/bin/tanyel-apply-accent "#2B9EA8" 2>&1 | sed 's/^/  /' || true

# Install Tweaks app (custom GTK4 settings panel)
info "Installing TanyelOS Tweaks app…"
sudo apt-get install -y --no-install-recommends \
  python3-gi gir1.2-gtk-4.0 gir1.2-adw-1 2>&1 | tail -2 || warn "GTK4 Python bindings missing — Tweaks app may not run"

sudo install -m 755 "$SCRIPT_DIR/tweaks/tanyel-tweaks.py" /usr/local/bin/tanyel-tweaks
sudo install -m 644 "$SCRIPT_DIR/tweaks/com.tanyelos.Tweaks.desktop" /usr/share/applications/com.tanyelos.Tweaks.desktop

# Install custom desktop launchers (About / Projects / resume.pdf / Contact) for the dock
info "Installing dock launchers…"
for launcher in "$SCRIPT_DIR"/tweaks/desktop-files/*.desktop; do
  [[ -f "$launcher" ]] && sudo install -m 644 "$launcher" "/usr/share/applications/$(basename "$launcher")"
done

# Install custom SVG icons for the launchers (matches design's flat colored glyphs)
if compgen -G "$SCRIPT_DIR/tweaks/icons/*.svg" > /dev/null; then
  info "Installing custom dock icons…"
  sudo install -dm755 /usr/share/icons/hicolor/scalable/apps
  sudo install -m 644 "$SCRIPT_DIR"/tweaks/icons/*.svg /usr/share/icons/hicolor/scalable/apps/
  sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
fi

# Create placeholder folders/files referenced by launchers
mkdir -p "$HOME/Projects" "$HOME/Documents"
[[ ! -f "$HOME/Documents/resume.pdf" ]] && touch "$HOME/Documents/resume.pdf"

update-desktop-database ~/.local/share/applications 2>/dev/null || true
update-desktop-database /usr/share/applications 2>/dev/null || true
ok "Tweaks app + dock launchers + icons installed"

# Apply dconf system defaults
dconf load / < "$SCRIPT_DIR/tanyel-gnome.dconf"

# Force key settings via gsettings (takes effect immediately)
gsettings set org.gnome.desktop.interface gtk-theme 'TanyelOS-Dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11' 2>/dev/null || true
gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:' 2>/dev/null || true
gsettings set org.gnome.shell.extensions.user-theme name 'TanyelOS-Dark' 2>/dev/null || true

# Set wallpaper to dark variants by default; light variants used when color-scheme=default
if [[ -f "$WP_DIR/aurora-dark.jpg" ]]; then
  gsettings set org.gnome.desktop.background picture-uri "file://$WP_DIR/aurora-light.jpg" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WP_DIR/aurora-dark.jpg" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null || true
fi

# Enable all extensions
for uuid in \
  "dash-to-dock@micxgx.gmail.com" \
  "arcmenu@arcmenu.com" \
  "blur-my-shell@aunetx" \
  "user-theme@gnome-shell-extensions.gcampax.github.com" \
  "just-perfection-desktop@just-perfection" \
  "window-list@gnome-shell-extensions.gcampax.github.com"
do
  gnome-extensions enable "$uuid" 2>/dev/null || true
done

# Disable extensions that conflict with TanyelOS layout (Ubuntu's stock
# dock + dash-to-panel, in case a previous TanyelOS install enabled it).
for uuid in \
  "ubuntu-dock@ubuntu.com" \
  "ding@rastersoft.com" \
  "tiling-assistant@ubuntu.com" \
  "dash-to-panel@jderose9.github.com"
do
  gnome-extensions disable "$uuid" 2>/dev/null || true
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
