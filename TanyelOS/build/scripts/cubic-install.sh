#!/bin/bash
# TanyelOS — Cubic chroot install script
#
# Run this INSIDE the Cubic chroot terminal after opening the Ubuntu 24.04 ISO.
# Before running, copy the build/ folder into the Cubic project directory
# so it's accessible inside the chroot.
#
# Usage (inside Cubic chroot):
#   bash /build/scripts/cubic-install.sh

set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== TanyelOS Install Script ==="
echo ""

# ── 1. Install required packages ─────────────────────────────────────────────
echo "[1/7] Installing dependencies..."
apt-get update -qq
apt-get install -y --no-install-recommends \
    python3 \
    python3-gi \
    gir1.2-gtk-4.0 \
    gir1.2-adw-1 \
    libadwaita-1-0 \
    gnome-tweaks \
    gnome-shell-extensions \
    gnome-shell-extension-prefs \
    dconf-cli \
    fonts-open-sans

# ── 2. Install TanyelOS fonts ─────────────────────────────────────────────────
echo "[2/7] Installing fonts..."
mkdir -p /usr/share/fonts/tanyelos
cp -r /build/fonts/tanyelos-fonts/* /usr/share/fonts/tanyelos/ 2>/dev/null || \
  echo "  Fonts deb not found — copy TTF files manually to /usr/share/fonts/tanyelos/"
fc-cache -f /usr/share/fonts/tanyelos

# ── 3. Install wallpapers ─────────────────────────────────────────────────────
echo "[3/7] Installing wallpapers..."
mkdir -p /usr/share/backgrounds/tanyelos
cp /build/wallpapers/*.png /usr/share/backgrounds/tanyelos/
chmod 644 /usr/share/backgrounds/tanyelos/*.png

# ── 4. Install GTK themes ─────────────────────────────────────────────────────
echo "[4/7] Installing themes..."
for theme_dir in /build/themes/tanyelos-*/; do
    theme_name=$(basename "$theme_dir")
    cp -r "$theme_dir" "/usr/share/themes/$theme_name/"
    chmod -R 644 "/usr/share/themes/$theme_name/"
    find "/usr/share/themes/$theme_name/" -type d -exec chmod 755 {} +
done
echo "  Installed $(ls /usr/share/themes/ | grep tanyelos | wc -l) theme variants"

# ── 5. Install TanyelOS Tweaks app ────────────────────────────────────────────
echo "[5/7] Installing TanyelOS Tweaks app..."
mkdir -p /usr/share/tanyelos-tweaks
cp /build/tweaks-app/tanyelos-tweaks.py /usr/share/tanyelos-tweaks/

cat > /usr/bin/tanyelos-tweaks << 'EOF'
#!/bin/bash
exec python3 /usr/share/tanyelos-tweaks/tanyelos-tweaks.py "$@"
EOF
chmod +x /usr/bin/tanyelos-tweaks

cp /build/tweaks-app/tanyelos-tweaks.desktop /usr/share/applications/
chmod 644 /usr/share/applications/tanyelos-tweaks.desktop

# App icon
mkdir -p /usr/share/icons/hicolor/scalable/apps
cat > /usr/share/icons/hicolor/scalable/apps/tanyelos-tweaks.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">
  <rect x="4" y="4" width="40" height="40" rx="10" fill="#3d9eb5"/>
  <rect x="12" y="12" width="10" height="10" rx="3" fill="white" opacity="0.9"/>
  <rect x="26" y="12" width="10" height="10" rx="3" fill="white" opacity="0.5"/>
  <rect x="12" y="26" width="10" height="10" rx="3" fill="white" opacity="0.5"/>
  <rect x="26" y="26" width="10" height="10" rx="3" fill="white" opacity="0.9"/>
</svg>
EOF
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true

# ── 6. Set dconf defaults ─────────────────────────────────────────────────────
echo "[6/7] Applying dconf defaults..."
mkdir -p /etc/dconf/profile
mkdir -p /etc/dconf/db/tanyelos.d

cp /build/dconf/tanyelos /etc/dconf/profile/user
cp /build/dconf/tanyelos.d/* /etc/dconf/db/tanyelos.d/

dconf update

# ── 7. Set GDM background ─────────────────────────────────────────────────────
echo "[7/7] Configuring GDM login screen..."
GDM_CSS="/usr/share/gnome-shell/gnome-shell-theme.gresource"
if [ -f "$GDM_CSS" ]; then
    # Write a GDM override that sets the background
    cat > /usr/share/gnome-shell/gdm3.css.override << 'EOF'
#lockDialogGroup {
  background: url(file:///usr/share/backgrounds/tanyelos/aurora-dark.png);
  background-size: cover;
  background-position: center;
}
EOF
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=== TanyelOS install complete! ==="
echo ""
echo "Theme variants installed:"
ls /usr/share/themes/ | grep tanyelos | sed 's/^/  /'
echo ""
echo "Next steps in Cubic:"
echo "  1. Set ISO name to: TanyelOS 24.04"
echo "  2. Set ISO filename to: tanyelos-24.04"
echo "  3. Click Generate"
