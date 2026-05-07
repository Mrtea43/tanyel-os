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

# Dark variant — strong accent (it's competing with a dark bg).
DARK_RGBA55="rgba($R,$G,$B,0.55)"
DARK_RGBA45="rgba($R,$G,$B,0.45)"
DARK_RGBA35="rgba($R,$G,$B,0.35)"
DARK_RGBA28="rgba($R,$G,$B,0.28)"
DARK_RGBA22="rgba($R,$G,$B,0.22)"

# Light variant — bumped from old (22/15/12/10) to (45/35/28/22) so the
# accent is actually visible on the cream base.
LIGHT_RGBA45="rgba($R,$G,$B,0.45)"
LIGHT_RGBA35="rgba($R,$G,$B,0.35)"
LIGHT_RGBA28="rgba($R,$G,$B,0.28)"
LIGHT_RGBA22="rgba($R,$G,$B,0.22)"

WP_DIR="$HOME/.local/share/wallpapers/tanyel"
mkdir -p "$WP_DIR"

command -v convert &>/dev/null || exit 0

# ── DARK variants ───────────────────────────────────────────────────
# Aurora-dark: 3 visible accent stops along a curve — matches design's
# "northern lights over slate" look.
[[ "$SKIP" != "aurora-dark" && "$SKIP" != "aurora" ]] && convert -size 1920x1080 gradient:'#1B2035-#0E1220' \
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA55" -draw "circle 480,360 1100,360" -blur 0x200 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.35)' -draw "circle 1500,750 2100,750" -blur 0x220 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA22" -draw "circle 1200,180 1700,180" -blur 0x160 \) -compose over -composite \
  "$WP_DIR/aurora-dark.jpg" 2>/dev/null || true

[[ "$SKIP" != "dusk-dark" && "$SKIP" != "dusk" ]] && convert -size 1920x1080 gradient:'#6B3620-#1E1428' \
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA45" -draw "circle 1200,540 1900,540" -blur 0x220 \) -compose over -composite \
  "$WP_DIR/dusk-dark.jpg" 2>/dev/null || true

if [[ "$SKIP" != "grid-dark" && "$SKIP" != "grid" ]]; then
  GRID_DRAW=""
  for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
  for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
  convert -size 1920x1080 xc:'#141822' \
    -stroke "$ACCENT" -strokewidth 1 -fill none \
    -draw "$GRID_DRAW" \
    \( -size 1920x1080 xc:none -fill "$DARK_RGBA28" -draw "circle 960,540 1500,540" -blur 0x220 \) -compose over -composite \
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
  \( -size 1920x1080 xc:none -fill "$DARK_RGBA28" -draw "circle 960,540 1900,540" -blur 0x250 \) -compose over -composite \
  "$WP_DIR/solid-dark.jpg" 2>/dev/null || true

# ── LIGHT variants ──────────────────────────────────────────────────
# Aurora-light: deeper cream gradient + bigger accent blobs so the wallpaper
# is visibly tinted, not invisible.
[[ "$SKIP" != "aurora-light" && "$SKIP" != "aurora" ]] && convert -size 1920x1080 gradient:'#F0EDE6-#E0DBD0' \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA45" -draw "circle 480,400 1100,400" -blur 0x220 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill 'rgba(91,143,255,0.28)' -draw "circle 1500,750 2100,750" -blur 0x220 \) -compose over -composite \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA22" -draw "circle 1200,180 1700,180" -blur 0x160 \) -compose over -composite \
  "$WP_DIR/aurora-light.jpg" 2>/dev/null || true

[[ "$SKIP" != "dusk-light" && "$SKIP" != "dusk" ]] && convert -size 1920x1080 gradient:'#F0D9C4-#E8B89A' \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA35" -draw "circle 1200,540 1900,540" -blur 0x220 \) -compose over -composite \
  "$WP_DIR/dusk-light.jpg" 2>/dev/null || true

if [[ "$SKIP" != "grid-light" && "$SKIP" != "grid" ]]; then
  GRID_DRAW=""
  for x in $(seq 0 60 1920); do GRID_DRAW+="line $x,0 $x,1080 "; done
  for y in $(seq 0 60 1080); do GRID_DRAW+="line 0,$y 1920,$y "; done
  convert -size 1920x1080 xc:'#F0EDE6' \
    -stroke "$ACCENT" -strokewidth 1.4 -fill none \
    -draw "$GRID_DRAW" \
    \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA22" -draw "circle 960,540 1500,540" -blur 0x220 \) -compose over -composite \
    "$WP_DIR/grid-light.jpg" 2>/dev/null || true
fi

if [[ "$SKIP" != "topo-light" && "$SKIP" != "topo" ]]; then
  TOPO_DRAW="fill none "
  for r in $(seq 80 70 1400); do TOPO_DRAW+="circle 960,540 $((960+r)),540 "; done
  convert -size 1920x1080 xc:'#EAE4D8' \
    -stroke "$ACCENT" -strokewidth 1.4 -fill none \
    -draw "$TOPO_DRAW" \
    "$WP_DIR/topo-light.jpg" 2>/dev/null || true
fi

[[ "$SKIP" != "solid-light" && "$SKIP" != "solid" ]] && convert -size 1920x1080 xc:'#E8E4DD' \
  \( -size 1920x1080 xc:none -fill "$LIGHT_RGBA28" -draw "circle 960,540 1900,540" -blur 0x250 \) -compose over -composite \
  "$WP_DIR/solid-light.jpg" 2>/dev/null || true
