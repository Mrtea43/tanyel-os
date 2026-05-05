#!/bin/bash
# Build tanyelos-tweaks .deb package
# Run from repo root inside Ubuntu VM: bash build/tweaks-app/build-deb.sh

set -e

PKG="tanyelos-tweaks"
VERSION="1.0"
ARCH="all"
DEB="${PKG}_${VERSION}_${ARCH}.deb"
BUILD_DIR="build/tweaks-app/deb-root"

echo "Building $DEB..."

# Create package directory structure
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"
mkdir -p "$BUILD_DIR/usr/share/tanyelos-tweaks"
mkdir -p "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps"

# Copy app
cp build/tweaks-app/tanyelos-tweaks.py "$BUILD_DIR/usr/share/tanyelos-tweaks/"

# Create launcher wrapper
cat > "$BUILD_DIR/usr/bin/tanyelos-tweaks" << 'EOF'
#!/bin/bash
exec python3 /usr/share/tanyelos-tweaks/tanyelos-tweaks.py "$@"
EOF
chmod +x "$BUILD_DIR/usr/bin/tanyelos-tweaks"

# Copy .desktop file
cp build/tweaks-app/tanyelos-tweaks.desktop "$BUILD_DIR/usr/share/applications/"

# Create SVG icon (simple TanyelOS logo)
cat > "$BUILD_DIR/usr/share/icons/hicolor/scalable/apps/tanyelos-tweaks.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48" height="48">
  <rect x="4" y="4" width="40" height="40" rx="10" fill="#3d9eb5"/>
  <rect x="12" y="12" width="10" height="10" rx="3" fill="white" opacity="0.9"/>
  <rect x="26" y="12" width="10" height="10" rx="3" fill="white" opacity="0.5"/>
  <rect x="12" y="26" width="10" height="10" rx="3" fill="white" opacity="0.5"/>
  <rect x="26" y="26" width="10" height="10" rx="3" fill="white" opacity="0.9"/>
</svg>
EOF

# Control file
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PKG
Version: $VERSION
Architecture: $ARCH
Maintainer: TanyelOS
Depends: python3, python3-gi, gir1.2-gtk-4.0, gir1.2-adw-1
Description: TanyelOS Tweaks
 Customize your TanyelOS desktop: theme (light/dark), accent color,
 font, and wallpaper. Requires TanyelOS themes and wallpapers.
EOF

# postinst: update icon cache
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
set -e
gtk-update-icon-cache -f -t /usr/share/icons/hicolor || true
update-desktop-database /usr/share/applications || true
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# Build the .deb
dpkg-deb --build "$BUILD_DIR" "build/tweaks-app/$DEB"
rm -rf "$BUILD_DIR"

echo "Built: build/tweaks-app/$DEB"
