#!/usr/bin/env bash
# tanyel-apply-accent — apply an accent color across TanyelOS
# Usage: tanyel-apply-accent <hex_color>   e.g. tanyel-apply-accent "#D4A843"
#
# Strategy: do INSTANT changes first (libadwaita native accent, gsettings),
# only regenerate the current wallpaper (not all 5), patch CSS for next launch.

set -euo pipefail

ACCENT="${1:-#2B9EA8}"

if [[ ! "$ACCENT" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "Invalid color. Use #RRGGBB format." >&2
  exit 1
fi

R=$((16#${ACCENT:1:2}))
G=$((16#${ACCENT:3:2}))
B=$((16#${ACCENT:5:2}))
RGBA45="rgba($R,$G,$B,0.45)"
RGBA30="rgba($R,$G,$B,0.30)"
RGBA20="rgba($R,$G,$B,0.20)"
RGBA18="rgba($R,$G,$B,0.18)"

DEFAULT_ACCENT="#2B9EA8"
WP_DIR="$HOME/.local/share/wallpapers/tanyel"
THEME_DIR="$HOME/.local/share/themes/TanyelOS"

mkdir -p "$WP_DIR"

# ── 1. Map hex to GNOME 46 native accent name (INSTANT for libadwaita apps) ─
# Available: blue, teal, green, yellow, orange, red, pink, purple, slate
declare -A ACCENT_NAMES=(
  ["#2B9EA8"]="teal"
  ["#D4A843"]="yellow"
  ["#E05C4A"]="red"
  ["#8B6FC2"]="purple"
  ["#5DB348"]="green"
)
NATIVE_ACCENT="${ACCENT_NAMES[$ACCENT]:-blue}"

echo "→ Setting native libadwaita accent → $NATIVE_ACCENT (instant)"
gsettings set org.gnome.desktop.interface accent-color "$NATIVE_ACCENT" 2>/dev/null || \
  echo "  (org.gnome.desktop.interface accent-color not supported on this GNOME — will skip)"

# ── 2. Update extension settings (INSTANT) ──────────────────────
echo "→ Updating Dash to Panel dot color (instant)…"
for n in 1 2 3 4; do
  gsettings set org.gnome.shell.extensions.dash-to-panel "dot-color-$n" "$ACCENT" 2>/dev/null || true
done

# ── 3. Patch theme CSS (takes effect when apps restart) ──────────
patch_css() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sed -i "s/${DEFAULT_ACCENT}/${ACCENT}/gi" "$file"
}

if [[ -d "$THEME_DIR" ]]; then
  echo "→ Patching theme CSS (next app launch)…"
  patch_css "$THEME_DIR/gtk-4.0/gtk.css"
  patch_css "$THEME_DIR/gtk-3.0/gtk.css"
  patch_css "$THEME_DIR/gnome-shell/gnome-shell.css"
  patch_css "$HOME/.config/gtk-4.0/gtk.css"
  patch_css "$HOME/.config/gtk-3.0/gtk.css"
fi

# ── 4. Save preference ─────────────────────────────────────────
mkdir -p "$HOME/.config/tanyelos"
echo "$ACCENT" > "$HOME/.config/tanyelos/accent"

# ── 5. Regenerate ONLY the current wallpaper (fast) ────────────
if command -v convert &>/dev/null; then
  CURRENT_URI=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'" | sed 's|file://||')
  CURRENT_NAME=""
  if [[ -n "$CURRENT_URI" && "$CURRENT_URI" =~ /tanyel/([^/.]+)\.jpg ]]; then
    CURRENT_NAME="${BASH_REMATCH[1]}"
  fi

  # If no TanyelOS wallpaper currently set, default to aurora
  [[ -z "$CURRENT_NAME" ]] && CURRENT_NAME="aurora"

  echo "→ Regenerating current wallpaper: $CURRENT_NAME (1 of 5)…"

  case "$CURRENT_NAME" in
    aurora)
      convert -size 1920x1080 gradient:'#1B2035-#141822' \
        \( -size 1920x1080 xc:none -fill "$RGBA45" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.30)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
        "$WP_DIR/aurora.jpg" 2>/dev/null && echo "  ✓ Aurora regenerated"
      ;;
    dusk)
      convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
        \( -size 1920x1080 xc:none -fill "$RGBA30" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
        "$WP_DIR/dusk.jpg" 2>/dev/null && echo "  ✓ Dusk regenerated"
      ;;
    grid)
      GRID_DRAW=""
      for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
      for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
      convert -size 1920x1080 xc:'#141822' \
        -stroke "$ACCENT" -strokewidth 1 -fill none \
        -draw "$GRID_DRAW" \
        \( -size 1920x1080 xc:none -fill "$RGBA20" -draw "circle 960,540 1500,540" -blur 0x200 \) -compose over -composite \
        "$WP_DIR/grid.jpg" 2>/dev/null && echo "  ✓ Grid regenerated"
      ;;
    topo)
      TOPO_DRAW="fill none "
      for r in $(seq 80 70 1400); do
        TOPO_DRAW+="circle 960,540 $((960+r)),540 "
      done
      convert -size 1920x1080 xc:'#1E2530' \
        -stroke "$ACCENT" -strokewidth 1 -fill none \
        -draw "$TOPO_DRAW" \
        "$WP_DIR/topo.jpg" 2>/dev/null && echo "  ✓ Topo regenerated"
      ;;
    solid)
      convert -size 1920x1080 xc:'#253040' \
        \( -size 1920x1080 xc:none -fill "$RGBA18" -draw "circle 960,540 1800,540" -blur 0x250 \) -compose over -composite \
        "$WP_DIR/solid.jpg" 2>/dev/null && echo "  ✓ Solid regenerated"
      ;;
  esac

  # Refresh background (force GNOME to re-read the file)
  if [[ -f "$WP_DIR/$CURRENT_NAME.jpg" ]]; then
    NEW_URI="file://$WP_DIR/$CURRENT_NAME.jpg"
    gsettings set org.gnome.desktop.background picture-uri "" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri "$NEW_URI" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri-dark "$NEW_URI" 2>/dev/null || true
  fi

  # Background-regenerate the other 4 wallpapers so future picks are instant
  if [[ -x /usr/local/bin/tanyel-regen-wallpapers ]]; then
    nohup /usr/local/bin/tanyel-regen-wallpapers "$ACCENT" "$CURRENT_NAME" >/dev/null 2>&1 &
  fi
fi

echo "✓ Accent $ACCENT applied. System menus update instantly; restart apps to fully refresh."
