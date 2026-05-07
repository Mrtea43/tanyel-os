#!/usr/bin/env bash
# tanyel-apply-accent — apply an accent color across TanyelOS
# Usage: tanyel-apply-accent <hex_color> [--no-wallpaper]
#
# Strategy:
#   1. Native libadwaita accent setting (instant for system menus)
#   2. Yaru icon-theme variant matching accent (so Nautilus selection follows)
#   3. Patch BOTH TanyelOS-Light and TanyelOS-Dark theme CSS
#   4. Wallpaper regen runs ASYNC (current variant first, others after)
#      — unless --no-wallpaper is passed (Tweaks does this for snappy UI)

set -euo pipefail

ACCENT="${1:-#2B9EA8}"
SKIP_WALLPAPER="false"
[[ "${2:-}" == "--no-wallpaper" ]] && SKIP_WALLPAPER="true"

if [[ ! "$ACCENT" =~ ^#[0-9A-Fa-f]{6}$ ]]; then
  echo "Invalid color. Use #RRGGBB format." >&2
  exit 1
fi

R=$((16#${ACCENT:1:2}))
G=$((16#${ACCENT:3:2}))
B=$((16#${ACCENT:5:2}))
RGBA55="rgba($R,$G,$B,0.55)"
RGBA45="rgba($R,$G,$B,0.45)"
RGBA35="rgba($R,$G,$B,0.35)"
RGBA28="rgba($R,$G,$B,0.28)"
RGBA22="rgba($R,$G,$B,0.22)"

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

echo "→ Setting libadwaita accent → $NATIVE_ACCENT"
gsettings set org.gnome.desktop.interface accent-color "$NATIVE_ACCENT" 2>/dev/null || \
  echo "  (libadwaita accent-color not supported on this GNOME — skipping)"

# ── 2. Yaru icon-theme variant (changes Nautilus selection color) ─
declare -A YARU_VARIANTS=(
  ["#2B9EA8"]="Yaru-prussiangreen-dark"  # teal
  ["#D4A843"]="Yaru-yellow-dark"          # amber
  ["#E05C4A"]="Yaru-red-dark"             # rose
  ["#8B6FC2"]="Yaru-purple-dark"          # violet
  ["#5DB348"]="Yaru-sage-dark"            # lime
)
YARU_VARIANT="${YARU_VARIANTS[$ACCENT]:-Yaru-prussiangreen-dark}"
echo "→ Setting Yaru icon-theme → $YARU_VARIANT"
gsettings set org.gnome.desktop.interface icon-theme "$YARU_VARIANT" 2>/dev/null || true

# ── 3. Update extension settings (instant) ─────────────────────
echo "→ Updating dock indicator color…"
for n in 1 2 3 4; do
  gsettings set org.gnome.shell.extensions.dash-to-panel "dot-color-$n" "$ACCENT" 2>/dev/null || true
done
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-running-dots-color "$ACCENT" 2>/dev/null || true

# ── 4. Patch theme CSS in BOTH variants ────────────────────────
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

# ── 5. Save preference ─────────────────────────────────────────
mkdir -p "$HOME/.config/tanyelos"
echo "$ACCENT" > "$HOME/.config/tanyelos/accent"

# ── 6. Wallpaper regeneration (async) ──────────────────────────
if [[ "$SKIP_WALLPAPER" == "true" ]]; then
  echo "✓ Accent $ACCENT applied (wallpaper regen skipped — pick a wallpaper in Tweaks to refresh)"
  exit 0
fi

if ! command -v convert &>/dev/null; then
  echo "✓ Accent $ACCENT applied (ImageMagick missing — wallpaper not regenerated)"
  exit 0
fi

CURRENT_URI=$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null | tr -d "'" | sed 's|file://||')
CURRENT_NAME=""
if [[ "$CURRENT_URI" =~ /tanyel/([^/.]+)\.jpg ]]; then
  CURRENT_NAME="${BASH_REMATCH[1]}"
fi
[[ -z "$CURRENT_NAME" ]] && CURRENT_NAME="aurora-dark"

# Run the entire wallpaper regen in the background — instant return to Tweaks.
(
  case "$CURRENT_NAME" in
    aurora-dark)
      convert -size 1920x1080 gradient:'#1B2035-#0E1220' \
        \( -size 1920x1080 xc:none -fill "$RGBA55" -draw "circle 480,360 1100,360" -blur 0x200 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.35)' -draw "circle 1500,750 2100,750" -blur 0x220 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill "$RGBA22" -draw "circle 1200,180 1700,180" -blur 0x160 \) -compose over -composite \
        "$WP_DIR/aurora-dark.jpg" 2>/dev/null
      ;;
    aurora-light)
      convert -size 1920x1080 gradient:'#F0EDE6-#E0DBD0' \
        \( -size 1920x1080 xc:none -fill "$RGBA45" -draw "circle 480,400 1100,400" -blur 0x220 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.28)' -draw "circle 1500,750 2100,750" -blur 0x220 \) -compose over -composite \
        \( -size 1920x1080 xc:none -fill "$RGBA22" -draw "circle 1200,180 1700,180" -blur 0x160 \) -compose over -composite \
        "$WP_DIR/aurora-light.jpg" 2>/dev/null
      ;;
    dusk-dark)
      convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
        \( -size 1920x1080 xc:none -fill "$RGBA45" -draw "circle 1200,540 1900,540" -blur 0x220 \) -compose over -composite \
        "$WP_DIR/dusk-dark.jpg" 2>/dev/null
      ;;
    dusk-light)
      convert -size 1920x1080 gradient:'#F0D9C4-#E8B89A' \
        \( -size 1920x1080 xc:none -fill "$RGBA35" -draw "circle 1200,540 1900,540" -blur 0x220 \) -compose over -composite \
        "$WP_DIR/dusk-light.jpg" 2>/dev/null
      ;;
    grid-dark|grid-light)
      VARIANT="${CURRENT_NAME#grid-}"
      BASE='#141822'; FILL="$RGBA28"
      [[ "$VARIANT" == "light" ]] && { BASE='#F0EDE6'; FILL="$RGBA22"; }
      GRID_DRAW=""
      for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
      for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
      convert -size 1920x1080 xc:"$BASE" \
        -stroke "$ACCENT" -strokewidth 1.4 -fill none -draw "$GRID_DRAW" \
        \( -size 1920x1080 xc:none -fill "$FILL" -draw "circle 960,540 1500,540" -blur 0x220 \) -compose over -composite \
        "$WP_DIR/grid-${VARIANT}.jpg" 2>/dev/null
      ;;
    topo-dark|topo-light)
      VARIANT="${CURRENT_NAME#topo-}"
      BASE='#1E2530'; [[ "$VARIANT" == "light" ]] && BASE='#EAE4D8'
      TOPO_DRAW="fill none "
      for r in $(seq 80 70 1400); do TOPO_DRAW+="circle 960,540 $((960+r)),540 "; done
      convert -size 1920x1080 xc:"$BASE" \
        -stroke "$ACCENT" -strokewidth 1.4 -fill none -draw "$TOPO_DRAW" \
        "$WP_DIR/topo-${VARIANT}.jpg" 2>/dev/null
      ;;
    solid-dark|solid-light)
      VARIANT="${CURRENT_NAME#solid-}"
      BASE='#253040'; FILL="$RGBA28"
      [[ "$VARIANT" == "light" ]] && { BASE='#E8E4DD'; FILL="$RGBA28"; }
      convert -size 1920x1080 xc:"$BASE" \
        \( -size 1920x1080 xc:none -fill "$FILL" -draw "circle 960,540 1900,540" -blur 0x250 \) -compose over -composite \
        "$WP_DIR/solid-${VARIANT}.jpg" 2>/dev/null
      ;;
  esac

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
    /usr/local/bin/tanyel-regen-wallpapers "$ACCENT" "$CURRENT_NAME" >/dev/null 2>&1 || true
  fi
) >/dev/null 2>&1 &

echo "✓ Accent $ACCENT applied. Wallpaper regenerating in background."
