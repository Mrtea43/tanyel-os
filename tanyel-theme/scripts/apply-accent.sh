#!/usr/bin/env bash
# tanyel-apply-accent — apply an accent color across TanyelOS
# Usage: tanyel-apply-accent <hex_color>
#
# Strategy:
#   1. Native libadwaita accent setting (instant for system menus)
#   2. Patch BOTH TanyelOS-Light and TanyelOS-Dark theme CSS
#   3. Regenerate current wallpaper variant fast
#   4. Background-regenerate the rest

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
RGBA22="rgba($R,$G,$B,0.22)"
RGBA20="rgba($R,$G,$B,0.20)"
RGBA18="rgba($R,$G,$B,0.18)"
RGBA15="rgba($R,$G,$B,0.15)"
RGBA12="rgba($R,$G,$B,0.12)"
RGBA10="rgba($R,$G,$B,0.10)"

DEFAULT_ACCENT="#2B9EA8"
WP_DIR="$HOME/.local/share/wallpapers/tanyel"

mkdir -p "$WP_DIR"

# ── 1. Native libadwaita accent (instant) ──────────────────────
declare -A ACCENT_NAMES=(
  ["#2B9EA8"]="teal"
  ["#D4A843"]="yellow"
  ["#E05C4A"]="red"
  ["#8B6FC2"]="purple"
  ["#5DB348"]="green"
)
NATIVE_ACCENT="${ACCENT_NAMES[$ACCENT]:-blue}"

echo "→ Setting native libadwaita accent → $NATIVE_ACCENT"
gsettings set org.gnome.desktop.interface accent-color "$NATIVE_ACCENT" 2>/dev/null || \
  echo "  (libadwaita accent-color not supported on this GNOME — skipping)"

# ── 2. Update extension settings (instant) ─────────────────────
echo "→ Updating Dash to Panel dot color…"
for n in 1 2 3 4; do
  gsettings set org.gnome.shell.extensions.dash-to-panel "dot-color-$n" "$ACCENT" 2>/dev/null || true
done

# ── 3. Patch theme CSS in BOTH variants (next launch) ──────────
patch_css() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  sudo sed -i "s/${DEFAULT_ACCENT}/${ACCENT}/gi" "$file" 2>/dev/null || \
    sed -i "s/${DEFAULT_ACCENT}/${ACCENT}/gi" "$file" 2>/dev/null || true
}

echo "→ Patching theme CSS (Light + Dark)…"
for theme in TanyelOS-Light TanyelOS-Dark TanyelOS; do
  for sub in gtk-4.0 gtk-3.0 gnome-shell; do
    patch_css "/usr/share/themes/${theme}/${sub}/gtk.css"
    patch_css "/usr/share/themes/${theme}/${sub}/gnome-shell.css"
    patch_css "$HOME/.local/share/themes/${theme}/${sub}/gtk.css"
    patch_css "$HOME/.local/share/themes/${theme}/${sub}/gnome-shell.css"
  done
done
patch_css "$HOME/.config/gtk-4.0/gtk.css"
patch_css "$HOME/.config/gtk-3.0/gtk.css"

# ── 4. Save preference ─────────────────────────────────────────
mkdir -p "$HOME/.config/tanyelos"
echo "$ACCENT" > "$HOME/.config/tanyelos/accent"

# ── 5. Regenerate current wallpaper variant fast ───────────────
if command -v convert &>/dev/null; then
  CURRENT_URI=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'" | sed 's|file://||')
  CURRENT_NAME=""
  if [[ "$CURRENT_URI" =~ /tanyel/([^/.]+)\.jpg ]]; then
    CURRENT_NAME="${BASH_REMATCH[1]}"   # e.g. "aurora-dark"
  fi
  [[ -z "$CURRENT_NAME" ]] && CURRENT_NAME="aurora-dark"

  echo "→ Regenerating current wallpaper: $CURRENT_NAME…"

  case "$CURRENT_NAME" in
    aurora-dark)
      convert -size 1920x1080 gradient:'#1B2035-#141822' \
        \( -size 1920x1080 xc:none -fill "$RGBA45" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.30)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
        "$WP_DIR/aurora-dark.jpg" 2>/dev/null && echo "  ✓"
      ;;
    aurora-light)
      convert -size 1920x1080 gradient:'#F5F2EC-#EDEAE4' \
        \( -size 1920x1080 xc:none -fill "$RGBA22" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.12)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
        "$WP_DIR/aurora-light.jpg" 2>/dev/null && echo "  ✓"
      ;;
    dusk-dark)
      convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
        \( -size 1920x1080 xc:none -fill "$RGBA30" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
        "$WP_DIR/dusk-dark.jpg" 2>/dev/null && echo "  ✓"
      ;;
    dusk-light)
      convert -size 1920x1080 gradient:'#F0D9C4-#E8B89A' \
        \( -size 1920x1080 xc:none -fill "$RGBA15" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
        "$WP_DIR/dusk-light.jpg" 2>/dev/null && echo "  ✓"
      ;;
    grid-dark|grid-light)
      VARIANT="${CURRENT_NAME#grid-}"
      BASE='#141822'; FILL="$RGBA20"
      [[ "$VARIANT" == "light" ]] && { BASE='#F5F2EC'; FILL="$RGBA10"; }
      GRID_DRAW=""
      for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
      for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
      convert -size 1920x1080 xc:"$BASE" \
        -stroke "$ACCENT" -strokewidth 1 -fill none -draw "$GRID_DRAW" \
        \( -size 1920x1080 xc:none -fill "$FILL" -draw "circle 960,540 1500,540" -blur 0x200 \) -compose over -composite \
        "$WP_DIR/grid-${VARIANT}.jpg" 2>/dev/null && echo "  ✓"
      ;;
    topo-dark|topo-light)
      VARIANT="${CURRENT_NAME#topo-}"
      BASE='#1E2530'; [[ "$VARIANT" == "light" ]] && BASE='#EDEAE4'
      TOPO_DRAW="fill none "
      for r in $(seq 80 70 1400); do TOPO_DRAW+="circle 960,540 $((960+r)),540 "; done
      convert -size 1920x1080 xc:"$BASE" \
        -stroke "$ACCENT" -strokewidth 1 -fill none -draw "$TOPO_DRAW" \
        "$WP_DIR/topo-${VARIANT}.jpg" 2>/dev/null && echo "  ✓"
      ;;
    solid-dark|solid-light)
      VARIANT="${CURRENT_NAME#solid-}"
      BASE='#253040'; FILL="$RGBA18"
      [[ "$VARIANT" == "light" ]] && { BASE='#E8E4DD'; FILL="$RGBA12"; }
      convert -size 1920x1080 xc:"$BASE" \
        \( -size 1920x1080 xc:none -fill "$FILL" -draw "circle 960,540 1800,540" -blur 0x250 \) -compose over -composite \
        "$WP_DIR/solid-${VARIANT}.jpg" 2>/dev/null && echo "  ✓"
      ;;
  esac

  # Refresh background
  if [[ -f "$WP_DIR/$CURRENT_NAME.jpg" ]]; then
    NEW_URI="file://$WP_DIR/$CURRENT_NAME.jpg"
    gsettings set org.gnome.desktop.background picture-uri "" 2>/dev/null || true
    gsettings set org.gnome.desktop.background picture-uri "$NEW_URI" 2>/dev/null || true
    if [[ "$CURRENT_NAME" == *-dark ]]; then
      gsettings set org.gnome.desktop.background picture-uri-dark "$NEW_URI" 2>/dev/null || true
    fi
  fi

  # Background-regenerate the rest
  if [[ -x /usr/local/bin/tanyel-regen-wallpapers ]]; then
    nohup /usr/local/bin/tanyel-regen-wallpapers "$ACCENT" "$CURRENT_NAME" >/dev/null 2>&1 &
  fi
fi

echo "✓ Accent $ACCENT applied. System menus update instantly; restart apps to fully refresh."
