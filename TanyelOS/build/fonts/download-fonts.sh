#!/bin/bash
# Download and package TanyelOS fonts as a .deb
# Run from repo root inside Ubuntu VM: bash build/fonts/download-fonts.sh

set -e

PKG="tanyelos-fonts"
VERSION="1.0"
ARCH="all"
DEB="${PKG}_${VERSION}_${ARCH}.deb"
BUILD_DIR="build/fonts/deb-root"
FONT_DIR="$BUILD_DIR/usr/share/fonts/tanyelos"

echo "Downloading fonts..."

mkdir -p "$FONT_DIR"
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/etc/fonts/conf.d"

# ── Geist ────────────────────────────────────────────────────────────────────
echo "Downloading Geist..."
GEIST_URL="https://github.com/vercel/geist-font/releases/latest/download/Geist.zip"
curl -L "$GEIST_URL" -o /tmp/Geist.zip
unzip -q /tmp/Geist.zip -d /tmp/geist-extracted
find /tmp/geist-extracted -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
rm -rf /tmp/Geist.zip /tmp/geist-extracted

# ── JetBrains Mono ───────────────────────────────────────────────────────────
echo "Downloading JetBrains Mono..."
JBM_URL="https://github.com/JetBrains/JetBrainsMono/releases/latest/download/JetBrainsMono-2.304.zip"
curl -L "$JBM_URL" -o /tmp/JetBrainsMono.zip
unzip -q /tmp/JetBrainsMono.zip -d /tmp/jbm-extracted
find /tmp/jbm-extracted -name "*.ttf" -path "*/fonts/ttf/*" -exec cp {} "$FONT_DIR/" \;
rm -rf /tmp/JetBrainsMono.zip /tmp/jbm-extracted

# ── Inter (fallback) ─────────────────────────────────────────────────────────
echo "Downloading Inter..."
INTER_URL="https://github.com/rsms/inter/releases/latest/download/Inter-4.0.zip"
curl -L "$INTER_URL" -o /tmp/Inter.zip
unzip -q /tmp/Inter.zip -d /tmp/inter-extracted
find /tmp/inter-extracted -name "*.ttf" -path "*InterVariable*" -exec cp {} "$FONT_DIR/" \;
rm -rf /tmp/Inter.zip /tmp/inter-extracted

# ── Control file ─────────────────────────────────────────────────────────────
cat > "$BUILD_DIR/DEBIAN/control" << EOF
Package: $PKG
Version: $VERSION
Architecture: $ARCH
Maintainer: TanyelOS
Description: TanyelOS Fonts
 Includes Geist, JetBrains Mono, and Inter for TanyelOS.
EOF

# postinst: refresh font cache
cat > "$BUILD_DIR/DEBIAN/postinst" << 'EOF'
#!/bin/bash
fc-cache -f /usr/share/fonts/tanyelos || true
EOF
chmod 755 "$BUILD_DIR/DEBIAN/postinst"

# ── Build deb ────────────────────────────────────────────────────────────────
dpkg-deb --build "$BUILD_DIR" "build/fonts/$DEB"
rm -rf "$BUILD_DIR"

echo "Built: build/fonts/$DEB"
