#!/usr/bin/env bash
# TanyelOS Theme Uninstaller — restores Ubuntu defaults

set -euo pipefail

ok() { echo "  ✓  $*"; }

echo "Removing TanyelOS theme…"

# GTK theme
rm -rf "$HOME/.local/share/themes/TanyelOS"
rm -f  "$HOME/.config/gtk-4.0/gtk.css"
rm -f  "$HOME/.config/gtk-3.0/gtk.css"
ok "GTK theme removed"

# Plymouth
sudo rm -rf /usr/share/plymouth/themes/tanyel
sudo update-initramfs -u 2>/dev/null || true
ok "Plymouth theme removed"

# GDM
sudo rm -f /etc/gdm3/greeter.dconf-defaults
sudo rm -f /usr/share/gnome-shell/theme/tanyel-gdm.css
ok "GDM config removed"

# Restore GNOME defaults
dconf reset -f /org/gnome/desktop/interface/
dconf reset -f /org/gnome/desktop/wm/preferences/
dconf reset    /org/gnome/shell/extensions/user-theme/name
ok "GNOME settings reset"

echo ""
echo "  Done. Log out and back in to apply."
