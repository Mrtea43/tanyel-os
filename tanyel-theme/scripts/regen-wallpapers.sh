#!/usr/bin/env bash
# tanyel-regen-wallpapers — regenerate wallpapers in light + dark variants
# Usage: tanyel-regen-wallpapers <hex_color> [skip_name]
# Outputs: $HOME/.local/share/wallpapers/tanyel/{aurora,dusk,grid,topo,solid}-{light,dark}.jpg

set -euo pipefail

ACCENT="${1:-#2B9EA8}"
SKIP="${2:-}"

R=$((16#${ACCENT:1:2}))
G=$((16#${ACCENT:3:2}))
B=$((16#${ACCENT:5:2}))

# Dark variant uses heavier accent saturation
DARK_RGBA45="rgba($R,$G,$B,0.45)"
DARK_RGBA30="rgba($R,$G,$B,0.30)"
DARK_RGBA20="rgba($R,$G,$B,0.20)"
DARK_RGBA18="rgba($R,$G,$B,0.18)"

# Light variant uses lower alpha so accent doesn't wash out the cream base
LIGHT_RGBA22="rgba($R,$G,$B,0.22)"
LIGHT_RGBA15="rgba($R,$G,$B,0.15)"
LIGHT_RGBA12="rgba($R,$G,$B,0.12)"
LIGHT_RGBA10="rgba($R,$G,$B,0.10)"

WP_DIR="$HOME/.local/share/wallpapers/tanyel"
mkdir -p "$WP_DIR"

command -v convert &>/dev/null || exit 0

# ── DARK variants ───────────────────────────────────────────────────
[[ "$SKIP" != "aurora-dark" && "$SKIP" != "aurora" ]] && convert -size 1920x1080 gradient:'#1B2035-#141822' \
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA45" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.30)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
  "$WP_DIR/aurora-dark.jpg" 2>/dev/null || true

[[ "$SKIP" != "dusk-dark" && "$SKIP" != "dusk" ]] && convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA30" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
  "$WP_DIR/dusk-dark.jpg" 2>/dev/null || true

if [[ "$SKIP" != "grid-dark" && "$SKIP" != "grid" ]]; then
  GRID_DRAW=""
  for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
  for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
  convert -size 1920x1080 xc:'#141822' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$GRID_DRAW" \
    \( -size 1920x1080 xc:none -fill "$DARK_RGBA20" -draw "circle 960,540 1500,540" -blur 0x200 \) -compose over -composite \
    "$WP_DIR/grid-dark.jpg" 2>/dev/null || true
fi

if [[ "$SKIP" != "topo-dark" && "$SKIP" != "topo" ]]; then
  TOPO_DRAW="fill none "
  for r in $(seq 80 70 1400); do TOPO_DRAW+="circle 960,540 $((960+r)),540 "; done
  convert -size 1920x1080 xc:'#1E2530' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$TOPO_DRAW" \
    "$WP_DIR/topo-dark.jpg" 2>/dev/null || true
fi

[[ "$SKIP" != "solid-dark" && "$SKIP" != "solid" ]] && convert -size 1920x1080 xc:'#253040' \
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA18" -draw "circle 960,540 1800,540" -blur 0x250 \) -compose over -composite \
  "$WP_DIR/solid-dark.jpg" 2>/dev/null || true

# ── LIGHT variants ──────────────────────────────────────────────────
[[ "$SKIP" != "aurora-light" && "$SKIP" != "aurora" ]] && convert -size 1920x1080 gradient:'#F5F2EC-#EDEAE4' \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA22" -draw "circle 480,360 900,360" -blur 0x180 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.12)' -draw "circle 1500,750 1900,750" -blur 0x180 \) -compose over -composite \
  "$WP_DIR/aurora-light.jpg" 2>/dev/null || true

[[ "$SKIP" != "dusk-light" && "$SKIP" != "dusk" ]] && convert -size 1920x1080 gradient:'#F0D9C4-#E8B89A' \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA15" -draw "circle 1200,540 1800,540" -blur 0x200 \) -compose over -composite \
  "$WP_DIR/dusk-light.jpg" 2>/dev/null || true

if [[ "$SKIP" != "grid-light" && "$SKIP" != "grid" ]]; then
  GRID_DRAW=""
  for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
  for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
  convert -size 1920x1080 xc:'#F5F2EC' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$GRID_DRAW" \
    \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA10" -draw "circle 960,540 1500,540" -blur 0x200 \) -compose over -composite \
    "$WP_DIR/grid-light.jpg" 2>/dev/null || true
fi

if [[ "$SKIP" != "topo-light" && "$SKIP" != "topo" ]]; then
  TOPO_DRAW="fill none "
  for r in $(seq 80 70 1400); do TOPO_DRAW+="circle 960,540 $((960+r)),540 "; done
  convert -size 1920x1080 xc:'#EDEAE4' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$TOPO_DRAW" \
    "$WP_DIR/topo-light.jpg" 2>/dev/null || true
fi

[[ "$SKIP" != "solid-light" && "$SKIP" != "solid" ]] && convert -size 1920x1080 xc:'#E8E4DD' \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA12" -draw "circle 960,540 1800,540" -blur 0x250 \) -compose over -composite \
  "$WP_DIR/solid-light.jpg" 2>/dev/null || true
