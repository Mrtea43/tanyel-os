#!/usr/bin/env bash
# TanyelOS Theme Uninstaller — restores Ubuntu defaults
# Run from the tanyel-theme/ directory: bash uninstall.sh

set -euo pipefail

RESET='\033[0m'; BOLD='\033[1m'
GREEN='\033[0;32m'; CYAN='\033[0;36m'
ok()   { echo -e "${GREEN}  ✓${RESET}  $*"; }
info() { echo -e "${CYAN}  →${RESET}  $*"; }
step() { echo -e "\n${BOLD}── $* ──${RESET}"; }

[[ $EUID -eq 0 ]] && { echo "Do not run as root."; exit 1; }

echo -e "${BOLD}TanyelOS Uninstaller${RESET}"
echo "This will remove the TanyelOS theme and restore Ubuntu defaults."
read -rp "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }

# ── 1. GTK theme variants ─────────────────────────────────────
step "Removing GTK theme variants"
sudo rm -rf /usr/share/themes/TanyelOS-Light /usr/share/themes/TanyelOS-Dark /usr/share/themes/TanyelOS
rm -rf "$HOME/.local/share/themes/TanyelOS-Light" "$HOME/.local/share/themes/TanyelOS-Dark" "$HOME/.local/share/themes/TanyelOS"
rm -f  "$HOME/.config/gtk-4.0/gtk.css"
rm -f  "$HOME/.config/gtk-3.0/gtk.css"
ok "GTK theme variants removed"

# ── 2. Wallpapers ─────────────────────────────────────────────
step "Removing wallpapers"
rm -rf "$HOME/.local/share/wallpapers/tanyel"
ok "Wallpapers removed"

# ── 3. Fonts ──────────────────────────────────────────────────
step "Removing TanyelOS fonts"
rm -rf "$HOME/.local/share/fonts/TanyelOS"
fc-cache -f 2>/dev/null || true
ok "Custom fonts removed (system fonts kept)"

# ── 4. GNOME extensions ───────────────────────────────────────
step "Removing GNOME extensions"
for uuid in \
  "dash-to-dock@micxgx.gmail.com" \
  "dash-to-panel@jderose9.github.com" \
  "arcmenu@arcmenu.com" \
  "blur-my-shell@aunetx" \
  "just-perfection-desktop@just-perfection"
do
  gnome-extensions disable "$uuid" 2>/dev/null || true
  rm -rf "$HOME/.local/share/gnome-shell/extensions/$uuid"
done
ok "Extensions disabled and removed"

# ── 5. Plymouth boot theme ────────────────────────────────────
step "Removing Plymouth boot theme"
sudo update-alternatives --remove default.plymouth /usr/share/plymouth/themes/tanyel/tanyel.plymouth 2>/dev/null || true
sudo rm -rf /usr/share/plymouth/themes/tanyel
sudo update-initramfs -u 2>/dev/null || true
ok "Plymouth theme removed"

# ── 6. GDM ────────────────────────────────────────────────────
step "Removing GDM config"
sudo rm -f /etc/gdm3/greeter.dconf-defaults
sudo rm -f /usr/share/gnome-shell/theme/tanyel-gdm.css
ok "GDM config removed"

# ── 7. Tweaks app + dock launchers ────────────────────────────
step "Removing Tweaks app + dock launchers"
sudo rm -f /usr/local/bin/tanyel-tweaks
sudo rm -f /usr/local/bin/tanyel-apply-accent
sudo rm -f /usr/local/bin/tanyel-regen-wallpapers
sudo rm -f /usr/share/applications/com.tanyelos.Tweaks.desktop
sudo rm -f /usr/share/applications/tanyelos-about.desktop
sudo rm -f /usr/share/applications/tanyelos-projects.desktop
sudo rm -f /usr/share/applications/tanyelos-resume.desktop
sudo rm -f /usr/share/applications/tanyelos-contact.desktop
sudo rm -f /usr/share/icons/hicolor/scalable/apps/tanyelos-about.svg
sudo rm -f /usr/share/icons/hicolor/scalable/apps/tanyelos-projects.svg
sudo rm -f /usr/share/icons/hicolor/scalable/apps/tanyelos-resume.svg
sudo rm -f /usr/share/icons/hicolor/scalable/apps/tanyelos-contact.svg
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
ok "Tweaks app + dock launchers + icons removed"

# ── 8. Neofetch config ────────────────────────────────────────
step "Removing neofetch config"
rm -rf "$HOME/.config/neofetch"
sudo rm -f /etc/os-release-tanyel
ok "Neofetch config removed"

# ── 9. Saved preferences ──────────────────────────────────────
step "Removing saved preferences"
rm -rf "$HOME/.config/tanyelos"
ok "Saved preferences removed"

# ── 10. Restore GNOME defaults ────────────────────────────────
step "Resetting GNOME settings"
dconf reset -f /org/gnome/desktop/interface/   2>/dev/null || true
dconf reset -f /org/gnome/desktop/wm/preferences/ 2>/dev/null || true
dconf reset -f /org/gnome/desktop/background/  2>/dev/null || true
dconf reset    /org/gnome/shell/extensions/user-theme/name 2>/dev/null || true
ok "GNOME settings reset to default"

echo ""
echo -e "${BOLD}${GREEN}TanyelOS removed.${RESET}"
echo ""
echo "  Log out and back in to fully restore Ubuntu's default appearance."
echo "  To remove the cloned repo:  rm -rf ~/tanyel-os"
echo ""
