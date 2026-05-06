#!/usr/bin/env bash
# tanyel-regen-wallpapers — regenerate the 4 non-current wallpapers in background
# Runs after apply-accent has already done the visible one.
# Usage: tanyel-regen-wallpapers <hex_color> <skip_name>

set -euo pipefail

ACCENT="${1:-#2B9EA8}"
SKIP="${2:-aurora}"

R=$((16#${ACCENT:1:2}))
G=$((16#${ACCENT:3:2}))
B=$((16#${ACCENT:5:2}))
RGBA45="rgba($R,$G,$B,0.45)"
RGBA30="rgba($R,$G,$B,0.30)"
RGBA20="rgba($R,$G,$B,0.20)"
RGBA18="rgba($R,$G,$B,0.18)"

WP_DIR="$HOME/.local/share/wallpapers/tanyel"
mkdir -p "$WP_DIR"

command -v convert &>/dev/null || exit 0

[[ "$SKIP" != "aurora" ]] && convert -size 1920x1080 gradient:'#1B2035-#141822' \
  \( -size 1920x1080 xc:none -fill "$RGBA45" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.30)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
  "$WP_DIR/aurora.jpg" 2>/dev/null || true

[[ "$SKIP" != "dusk" ]] && convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
  \( -size 1920x1080 xc:none -fill "$RGBA30" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
  "$WP_DIR/dusk.jpg" 2>/dev/null || true

if [[ "$SKIP" != "grid" ]]; then
  GRID_DRAW=""
  for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
  for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
  convert -size 1920x1080 xc:'#141822' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$GRID_DRAW" \
    \( -size 1920x1080 xc:none -fill "$RGBA20" -draw "circle 960,540 1500,540" -blur 0x200 \) -compose over -composite \
    "$WP_DIR/grid.jpg" 2>/dev/null || true
fi

if [[ "$SKIP" != "topo" ]]; then
  TOPO_DRAW="fill none "
  for r in $(seq 80 70 1400); do
    TOPO_DRAW+="circle 960,540 $((960+r)),540 "
  done
  convert -size 1920x1080 xc:'#1E2530' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$TOPO_DRAW" \
    "$WP_DIR/topo.jpg" 2>/dev/null || true
fi

[[ "$SKIP" != "solid" ]] && convert -size 1920x1080 xc:'#253040' \
  \( -size 1920x1080 xc:none -fill "$RGBA18" -draw "circle 960,540 1800,540" -blur 0x250 \) -compose over -composite \
  "$WP_DIR/solid.jpg" 2>/dev/null || true
