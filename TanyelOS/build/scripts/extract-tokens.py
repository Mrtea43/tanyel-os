#!/usr/bin/env python3
"""Extract TanyelOS design tokens from TanyelOS.html and convert oklch to hex.

Usage (run from repo root inside Ubuntu VM):
    pip install colour-science
    python3 build/scripts/extract-tokens.py

Outputs:
    build/tokens/tokens-light.json
    build/tokens/tokens-dark.json
    build/tokens/accents.json
"""

import json
import math
import os

# ── oklch → hex conversion (no external dep version) ───────────────────────

def oklch_to_oklab(L, C, h_deg):
    h = math.radians(h_deg)
    a = C * math.cos(h)
    b = C * math.sin(h)
    return L, a, b

def oklab_to_linear_srgb(L, a, b):
    l_ = L + 0.3963377774 * a + 0.2158037573 * b
    m_ = L - 0.1055613458 * a - 0.0638541728 * b
    s_ = L - 0.0894841775 * a - 1.2914855480 * b
    l = l_ ** 3
    m = m_ ** 3
    s = s_ ** 3
    r =  4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s
    g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s
    b2 = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
    return r, g, b2

def linear_to_srgb(c):
    if c <= 0.0031308:
        return 12.92 * c
    return 1.055 * (c ** (1 / 2.4)) - 0.055

def oklch_to_hex(L, C, h):
    """Convert oklch(L C h) to #rrggbb. L in [0,1], C in [0,0.4], h in degrees."""
    lab = oklch_to_oklab(L, C, h)
    r, g, b = oklab_to_linear_srgb(*lab)
    r = max(0, min(1, linear_to_srgb(r)))
    g = max(0, min(1, linear_to_srgb(g)))
    b = max(0, min(1, linear_to_srgb(b)))
    return "#{:02x}{:02x}{:02x}".format(int(r * 255), int(g * 255), int(b * 255))

def oklch_alpha_to_rgba(L, C, h, a):
    hex_color = oklch_to_hex(L, C, h)
    r = int(hex_color[1:3], 16)
    g = int(hex_color[3:5], 16)
    b = int(hex_color[5:7], 16)
    return "rgba({},{},{},{})".format(r, g, b, a)

# ── Token definitions (from design-reference/TanyelOS.html) ─────────────────

ACCENT_CONFIGS = {
    "teal":   {"h": 195, "c": 0.13},
    "amber":  {"h": 60,  "c": 0.15},
    "rose":   {"h": 20,  "c": 0.16},
    "violet": {"h": 290, "c": 0.13},
    "lime":   {"h": 130, "c": 0.15},
}

def build_tokens_for_accent(accent_name, h, c, dark=False):
    tokens = {}

    if dark:
        tokens["bg_0"]       = oklch_to_hex(0.18, 0.008, 250)
        tokens["bg_1"]       = oklch_to_hex(0.22, 0.010, 250)
        tokens["bg_2"]       = oklch_to_hex(0.15, 0.008, 250)
        tokens["fg_0"]       = oklch_to_hex(0.96, 0.005, 80)
        tokens["fg_1"]       = oklch_to_hex(0.78, 0.008, 80)
        tokens["fg_2"]       = oklch_to_hex(0.58, 0.010, 80)
        tokens["line"]       = oklch_to_hex(0.30, 0.012, 250)
        tokens["line_soft"]  = oklch_to_hex(0.26, 0.010, 250)
        tokens["accent_soft"] = oklch_to_hex(0.30, c * 0.6, h)
    else:
        tokens["bg_0"]       = oklch_to_hex(0.96, 0.005, 80)
        tokens["bg_1"]       = oklch_to_hex(0.99, 0.003, 80)
        tokens["bg_2"]       = oklch_to_hex(0.94, 0.006, 80)
        tokens["fg_0"]       = oklch_to_hex(0.20, 0.010, 80)
        tokens["fg_1"]       = oklch_to_hex(0.40, 0.010, 80)
        tokens["fg_2"]       = oklch_to_hex(0.60, 0.010, 80)
        tokens["line"]       = oklch_to_hex(0.85, 0.005, 80)
        tokens["line_soft"]  = oklch_to_hex(0.90, 0.004, 80)
        tokens["accent_soft"] = oklch_to_hex(0.92, c * 0.4, h)

    tokens["accent"]      = oklch_to_hex(0.60, c, h)
    tokens["accent_name"] = accent_name
    tokens["accent_h"]    = h
    tokens["accent_c"]    = c
    tokens["dark"]        = dark

    # Window controls
    tokens["ctrl_close"] = oklch_to_hex(0.65, 0.18, 25)
    tokens["ctrl_min"]   = oklch_to_hex(0.78, 0.14, 80)
    tokens["ctrl_max"]   = oklch_to_hex(0.70, 0.16, 145)

    return tokens


def main():
    os.makedirs("build/tokens", exist_ok=True)

    all_light = {}
    all_dark = {}
    accents = {}

    for name, cfg in ACCENT_CONFIGS.items():
        h, c = cfg["h"], cfg["c"]
        all_light[name] = build_tokens_for_accent(name, h, c, dark=False)
        all_dark[name]  = build_tokens_for_accent(name, h, c, dark=True)
        accents[name] = {
            "h": h, "c": c,
            "hex": oklch_to_hex(0.60, c, h),
            "soft_dark":  oklch_to_hex(0.30, c * 0.6, h),
            "soft_light": oklch_to_hex(0.92, c * 0.4, h),
        }

    with open("build/tokens/tokens-light.json", "w") as f:
        json.dump(all_light, f, indent=2)
    with open("build/tokens/tokens-dark.json", "w") as f:
        json.dump(all_dark, f, indent=2)
    with open("build/tokens/accents.json", "w") as f:
        json.dump(accents, f, indent=2)

    print("Tokens written:")
    print("  build/tokens/tokens-light.json")
    print("  build/tokens/tokens-dark.json")
    print("  build/tokens/accents.json")
    print()
    for name, cfg in ACCENT_CONFIGS.items():
        hex_val = oklch_to_hex(0.60, cfg["c"], cfg["h"])
        print(f"  {name:8s}  {hex_val}")


if __name__ == "__main__":
    main()
