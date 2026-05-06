#!/usr/bin/env bash
# tanyel-apply-accent — regenerate wallpapers and update theme files for a chosen accent color
# Usage: tanyel-apply-accent <hex_color>   e.g. tanyel-apply-accent "#D4A843"

set -euo pipefail

ACCENT="${1:-#2B9EA8}"

# Validate hex color (#RRGGBB)
if [[ ! "$ACCENT" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "Invalid color. Use #RRGGBB format." >&2
  exit 1
fi

# Parse RGB components for ImageMagick rgba()
R=$((16#${ACCENT:1:2}))
G=$((16#${ACCENT:3:2}))
B=$((16#${ACCENT:5:2}))
RGBA45="rgba($R,$G,$B,0.45)"
RGBA30="rgba($R,$G,$B,0.30)"
RGBA20="rgba($R,$G,$B,0.20)"
RGBA18="rgba($R,$G,$B,0.18)"

# Default teal that gets replaced everywhere it appears
DEFAULT_ACCENT="#2B9EA8"

WP_DIR="$HOME/.local/share/wallpapers/tanyel"
THEME_DIR="$HOME/.local/share/themes/TanyelOS"

mkdir -p "$WP_DIR"

# ── Regenerate wallpapers with new accent color ─────────────────
if command -v convert &>/dev/null; then
  echo "→ Regenerating wallpapers with accent $ACCENT…"

  # Aurora — primary accent nebula on dark blue base
  convert -size 1920x1080 gradient:'#1B2035-#141822' \
    \( -size 1920x1080 xc:none -fill "$RGBA45" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
    \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.30)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
    "$WP_DIR/aurora.jpg"

  # Dusk — accent-tinted dusk gradient
  convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
    \( -size 1920x1080 xc:none -fill "$RGBA30" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
    "$WP_DIR/dusk.jpg"

  # Grid — accent-colored grid lines on dark
  convert -size 1920x1080 xc:'#141822' \
    \( -size 1920x1080 radial-gradient:"${RGBA20}-transparent" \) -compose over -composite \
    "$WP_DIR/grid.jpg"

  # Topo — accent contour rings
  convert -size 1920x1080 xc:'#1E2530' \
    \( -size 1920x1080 radial-gradient:"${RGBA20}-transparent" \) -compose over -composite \
    "$WP_DIR/topo.jpg"

  # Solid — solid color complement (slate with subtle accent vignette)
  convert -size 1920x1080 xc:'#253040' \
    \( -size 1920x1080 radial-gradient:"${RGBA18}-transparent" \) -compose over -composite \
    "$WP_DIR/solid.jpg"

  echo "  ✓ Wallpapers regenerated"
else
  echo "  ! ImageMagick missing — wallpapers unchanged"
fi

# ── Patch theme CSS files (replace default teal with new accent) ─
patch_css() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  # Replace exact accent color (case-insensitive)
  sed -i "s/${DEFAULT_ACCENT}/${ACCENT}/gi" "$file"
}

if [[ -d "$THEME_DIR" ]]; then
  echo "→ Patching theme CSS…"
  patch_css "$THEME_DIR/gtk-4.0/gtk.css"
  patch_css "$THEME_DIR/gtk-3.0/gtk.css"
  patch_css "$THEME_DIR/gnome-shell/gnome-shell.css"
  patch_css "$HOME/.config/gtk-4.0/gtk.css"
  patch_css "$HOME/.config/gtk-3.0/gtk.css"
  echo "  ✓ Theme CSS updated"
fi

# ── Update extension settings ──────────────────────────────────
echo "→ Updating Dash to Panel dot color…"
for n in 1 2 3 4; do
  gsettings set org.gnome.shell.extensions.dash-to-panel "dot-color-$n" "$ACCENT" 2>/dev/null || true
done

# ── Refresh background to current wallpaper ────────────────────
CURRENT_WP=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'" | sed 's|file://||')
if [[ -n "$CURRENT_WP" && -f "$CURRENT_WP" ]]; then
  # Force refresh by toggling
  gsettings set org.gnome.desktop.background picture-uri "" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-uri "file://$CURRENT_WP" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$CURRENT_WP" 2>/dev/null || true
fi

# Save chosen accent to a known location for the Tweaks app to read on startup
mkdir -p "$HOME/.config/tanyelos"
echo "$ACCENT" > "$HOME/.config/tanyelos/accent"

echo "✓ Accent $ACCENT applied. Log out and back in for full effect on running apps."
