#!/usr/bin/env python3
"""Generate TanyelOS wallpapers as PNG files.

Usage (run from repo root inside Ubuntu VM):
    pip install Pillow numpy
    python3 build/scripts/generate-wallpapers.py

Outputs:
    build/wallpapers/{aurora,dusk,grid,topo,solid}-{dark,light}.png
    Each wallpaper is 3840x2160 (4K UHD).
"""

import json
import math
import os
import sys

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("Install dependencies: pip install Pillow numpy")
    sys.exit(1)

W, H = 3840, 2160

# ── Color helpers ────────────────────────────────────────────────────────────

def oklch_to_rgb(L, C, h_deg):
    h = math.radians(h_deg)
    a = C * math.cos(h)
    b = C * math.sin(h)
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    lc = l_ ** 3; mc = m_ ** 3; sc = s_ ** 3
    r =  4.0767416621 * lc - 3.3077115913 * mc + 0.2309699292 * sc
    g = -1.2684380046 * lc + 2.6097574011 * mc - 0.3413193965 * sc
    bv = -0.0041960863 * lc - 0.7034186147 * mc + 1.7076147010 * sc
    def lin(c):
        c = max(0, min(1, c))
        return 12.92 * c if c <= 0.0031308 else 1.055 * (c ** (1/2.4)) - 0.055
    return (int(lin(r)*255), int(lin(g)*255), int(lin(bv)*255))

def hex_to_rgb(h):
    h = h.lstrip('#')
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def lerp_color(c1, c2, t):
    return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))

def blend(base, overlay, alpha):
    return tuple(int(base[i] * (1 - alpha) + overlay[i] * alpha) for i in range(3))

# ── Wallpaper generators ─────────────────────────────────────────────────────

def make_aurora_dark(h, c):
    img = np.zeros((H, W, 3), dtype=np.uint8)
    base1 = oklch_to_rgb(0.20, 0.04, 250)
    base2 = oklch_to_rgb(0.15, 0.03, 260)
    glow1 = oklch_to_rgb(0.55, 0.16, h)
    glow2 = oklch_to_rgb(0.50, 0.18, h + 60)
    glow3 = oklch_to_rgb(0.40, 0.14, h - 40)

    xs = np.linspace(0, 1, W)
    ys = np.linspace(0, 1, H)
    xg, yg = np.meshgrid(xs, ys)

    # Base gradient
    t_base = yg
    for ch in range(3):
        img[:, :, ch] = (base1[ch] * (1 - t_base) + base2[ch] * t_base).astype(np.uint8)

    # Aurora glow 1 — ellipse at 20% 30%
    dx1 = (xg - 0.20) / 0.40
    dy1 = (yg - 0.30) / 0.30
    r1 = np.clip(1 - np.sqrt(dx1**2 + dy1**2), 0, 1) ** 1.5 * 0.55
    for ch in range(3):
        img[:, :, ch] = np.clip(img[:, :, ch] + r1 * glow1[ch], 0, 255).astype(np.uint8)

    # Aurora glow 2 — ellipse at 80% 70%
    dx2 = (xg - 0.80) / 0.35
    dy2 = (yg - 0.70) / 0.25
    r2 = np.clip(1 - np.sqrt(dx2**2 + dy2**2), 0, 1) ** 1.5 * 0.45
    for ch in range(3):
        img[:, :, ch] = np.clip(img[:, :, ch] + r2 * glow2[ch], 0, 255).astype(np.uint8)

    # Aurora glow 3 — ellipse at 50% 100%
    dx3 = (xg - 0.50) / 0.30
    dy3 = (yg - 1.00) / 0.20
    r3 = np.clip(1 - np.sqrt(dx3**2 + dy3**2), 0, 1) ** 1.5 * 0.35
    for ch in range(3):
        img[:, :, ch] = np.clip(img[:, :, ch] + r3 * glow3[ch], 0, 255).astype(np.uint8)

    return Image.fromarray(img)

def make_aurora_light(h, c):
    img = np.zeros((H, W, 3), dtype=np.uint8)
    base1 = oklch_to_rgb(0.94, 0.02, h)
    base2 = oklch_to_rgb(0.88, 0.03, h + 30)
    glow1 = oklch_to_rgb(0.85, 0.10, h)
    glow2 = oklch_to_rgb(0.80, 0.10, h + 60)

    xs = np.linspace(0, 1, W)
    ys = np.linspace(0, 1, H)
    xg, yg = np.meshgrid(xs, ys)

    t_base = yg
    for ch in range(3):
        img[:, :, ch] = (base1[ch] * (1 - t_base) + base2[ch] * t_base).astype(np.uint8)

    dx1 = (xg - 0.20) / 0.40
    dy1 = (yg - 0.30) / 0.30
    r1 = np.clip(1 - np.sqrt(dx1**2 + dy1**2), 0, 1) ** 1.5 * 0.70
    for ch in range(3):
        img[:, :, ch] = np.clip(img[:, :, ch] + r1 * (glow1[ch] - img[:, :, ch]) * 0.6, 0, 255).astype(np.uint8)

    dx2 = (xg - 0.80) / 0.35
    dy2 = (yg - 0.70) / 0.25
    r2 = np.clip(1 - np.sqrt(dx2**2 + dy2**2), 0, 1) ** 1.5 * 0.50
    for ch in range(3):
        img[:, :, ch] = np.clip(img[:, :, ch] + r2 * (glow2[ch] - img[:, :, ch]) * 0.5, 0, 255).astype(np.uint8)

    return Image.fromarray(img)

def make_dusk_dark():
    img = np.zeros((H, W, 3), dtype=np.uint8)
    c1 = oklch_to_rgb(0.45, 0.12, 30)
    c2 = oklch_to_rgb(0.35, 0.10, 350)
    c3 = oklch_to_rgb(0.25, 0.06, 280)
    ys = np.linspace(0, 1, H)
    for y_idx in range(H):
        t = ys[y_idx]
        if t < 0.6:
            color = lerp_color(c1, c2, t / 0.6)
        else:
            color = lerp_color(c2, c3, (t - 0.6) / 0.4)
        img[y_idx, :] = color
    return Image.fromarray(img)

def make_dusk_light():
    img = np.zeros((H, W, 3), dtype=np.uint8)
    c1 = oklch_to_rgb(0.85, 0.08, 60)
    c2 = oklch_to_rgb(0.75, 0.07, 20)
    c3 = oklch_to_rgb(0.65, 0.05, 300)
    ys = np.linspace(0, 1, H)
    for y_idx in range(H):
        t = ys[y_idx]
        if t < 0.5:
            color = lerp_color(c1, c2, t / 0.5)
        else:
            color = lerp_color(c2, c3, (t - 0.5) / 0.5)
        img[y_idx, :] = color
    return Image.fromarray(img)

def make_grid_dark(h, c):
    base1 = oklch_to_rgb(0.40, 0.06, h)
    base2 = oklch_to_rgb(0.20, 0.02, 250)
    line_color = oklch_to_rgb(0.50, 0.04, h)
    img = np.zeros((H, W, 3), dtype=np.uint8)
    xs = np.linspace(0, 1, W)
    ys = np.linspace(0, 1, H)
    xg, yg = np.meshgrid(xs, ys)

    # Radial base
    dx = (xg - 0.5) / 0.35
    dy = (yg - 0.3) / 0.30
    r = np.clip(1 - np.sqrt(dx**2 + dy**2), 0, 1)
    for ch in range(3):
        img[:, :, ch] = (base2[ch] + r * (base1[ch] - base2[ch])).astype(np.uint8)

    # Grid lines every 40px
    grid_px = 40
    x_line = ((np.arange(W) % grid_px) == 0)
    y_line = ((np.arange(H) % grid_px) == 0)
    alpha = 0.18
    img[np.ix_(np.ones(H, dtype=bool), x_line)] = np.clip(
        img[np.ix_(np.ones(H, dtype=bool), x_line)] * (1 - alpha) +
        np.array(line_color) * alpha, 0, 255).astype(np.uint8)
    img[np.ix_(y_line, np.ones(W, dtype=bool))] = np.clip(
        img[np.ix_(y_line, np.ones(W, dtype=bool))] * (1 - alpha) +
        np.array(line_color) * alpha, 0, 255).astype(np.uint8)

    return Image.fromarray(img)

def make_grid_light(h, c):
    base = oklch_to_rgb(0.92, 0.02, h)
    line_color = oklch_to_rgb(0.50, 0.04, h)
    img = np.full((H, W, 3), base, dtype=np.uint8)
    grid_px = 40
    x_line = ((np.arange(W) % grid_px) == 0)
    y_line = ((np.arange(H) % grid_px) == 0)
    alpha = 0.12
    img[np.ix_(np.ones(H, dtype=bool), x_line)] = np.clip(
        img[np.ix_(np.ones(H, dtype=bool), x_line)] * (1 - alpha) +
        np.array(line_color) * alpha, 0, 255).astype(np.uint8)
    img[np.ix_(y_line, np.ones(W, dtype=bool))] = np.clip(
        img[np.ix_(y_line, np.ones(W, dtype=bool))] * (1 - alpha) +
        np.array(line_color) * alpha, 0, 255).astype(np.uint8)
    return Image.fromarray(img)

def make_topo_dark(h, c):
    base = oklch_to_rgb(0.28, 0.02, 220)
    ring_color = oklch_to_rgb(0.50, 0.04, h)
    img = np.full((H, W, 3), base, dtype=np.uint8)
    xs = np.linspace(0, 1, W)
    ys = np.linspace(0, 1, H)
    xg, yg = np.meshgrid(xs, ys)

    for cx, cy, ring_r, alpha in [(0.30, 0.40, 0.18, 0.18), (0.70, 0.70, 0.22, 0.14)]:
        dist = np.sqrt((xg - cx)**2 + (yg - cy)**2)
        scale_x = W / H
        dist = np.sqrt(((xg - cx) * scale_x)**2 + (yg - cy)**2)
        rings = (dist % ring_r)
        is_ring = (rings < (ring_r * 0.04)) | (rings > ring_r * 0.96)
        for ch in range(3):
            img[:, :, ch] = np.where(is_ring,
                np.clip(img[:, :, ch] * (1 - alpha) + ring_color[ch] * alpha, 0, 255),
                img[:, :, ch]).astype(np.uint8)
    return Image.fromarray(img)

def make_topo_light(h, c):
    base = oklch_to_rgb(0.92, 0.01, 220)
    ring_color = oklch_to_rgb(0.50, 0.04, h)
    img = np.full((H, W, 3), base, dtype=np.uint8)
    xs = np.linspace(0, 1, W)
    ys = np.linspace(0, 1, H)
    xg, yg = np.meshgrid(xs, ys)
    for cx, cy, ring_r, alpha in [(0.30, 0.40, 0.18, 0.10), (0.70, 0.70, 0.22, 0.08)]:
        scale_x = W / H
        dist = np.sqrt(((xg - cx) * scale_x)**2 + (yg - cy)**2)
        rings = dist % ring_r
        is_ring = (rings < ring_r * 0.04) | (rings > ring_r * 0.96)
        for ch in range(3):
            img[:, :, ch] = np.where(is_ring,
                np.clip(img[:, :, ch] * (1 - alpha) + ring_color[ch] * alpha, 0, 255),
                img[:, :, ch]).astype(np.uint8)
    return Image.fromarray(img)

def make_solid_dark(h, c):
    color = oklch_to_rgb(0.35, 0.04, h)
    img = np.full((H, W, 3), color, dtype=np.uint8)
    return Image.fromarray(img)

def make_solid_light(h, c):
    color = oklch_to_rgb(0.88, 0.04, h)
    img = np.full((H, W, 3), color, dtype=np.uint8)
    return Image.fromarray(img)

# ── Main ─────────────────────────────────────────────────────────────────────

def main():
    os.makedirs("build/wallpapers", exist_ok=True)

    with open("build/tokens/accents.json") as f:
        accents = json.load(f)

    # Default accent is teal for the wallpapers
    default = accents["teal"]
    h, c = default["h"], default["c"]

    jobs = [
        ("aurora-dark",  lambda: make_aurora_dark(h, c)),
        ("aurora-light", lambda: make_aurora_light(h, c)),
        ("dusk-dark",    make_dusk_dark),
        ("dusk-light",   make_dusk_light),
        ("grid-dark",    lambda: make_grid_dark(h, c)),
        ("grid-light",   lambda: make_grid_light(h, c)),
        ("topo-dark",    lambda: make_topo_dark(h, c)),
        ("topo-light",   lambda: make_topo_light(h, c)),
        ("solid-dark",   lambda: make_solid_dark(h, c)),
        ("solid-light",  lambda: make_solid_light(h, c)),
    ]

    for name, fn in jobs:
        path = f"build/wallpapers/{name}.png"
        print(f"Generating {path}...", end=" ", flush=True)
        img = fn()
        img.save(path, "PNG", optimize=False)
        print("done")

    print(f"\nAll wallpapers saved to build/wallpapers/")

if __name__ == "__main__":
    main()
