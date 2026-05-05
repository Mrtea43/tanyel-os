# TanyelOS

A custom Ubuntu 24.04 LTS distribution with a polished design system — dark/light themes, 5 accent colors, custom fonts, and a native Tweaks app.

## What's included

| Component | Description |
|-----------|-------------|
| GTK4 + GNOME Shell themes | 10 variants (5 accents × dark/light) |
| TanyelOS Tweaks app | Native GTK4 app to switch theme, accent, font, wallpaper |
| Wallpapers | 5 styles × 2 variants (Aurora, Dusk, Grid, Topo, Solid) |
| Fonts | Geist, JetBrains Mono, Inter |
| dconf defaults | Pre-configured GNOME settings |

## Building the ISO

### Requirements
- Ubuntu 24.04 VM (VirtualBox or VMware recommended)
- Ubuntu 24.04 desktop ISO (download from ubuntu.com)
- ~20GB free disk space in the VM
- Internet access (for downloading fonts)

### Step 1 — Generate design assets (inside Ubuntu VM)

```bash
git clone https://github.com/YOUR_USERNAME/TanyelOS
cd TanyelOS

# Install Python deps
pip3 install numpy Pillow

# Extract color tokens from TanyelOS design
python3 build/scripts/extract-tokens.py

# Generate wallpapers (takes ~2 min)
python3 build/scripts/generate-wallpapers.py

# Generate GTK themes
python3 build/scripts/build-theme.py

# Download and package fonts
bash build/fonts/download-fonts.sh

# Build TanyelOS Tweaks .deb
bash build/tweaks-app/build-deb.sh
```

### Step 2 — Install Cubic

```bash
sudo apt install cubic
```

Open Cubic and select your Ubuntu 24.04 ISO.

### Step 3 — Copy build assets into Cubic project

In Cubic, before entering the chroot, copy the `build/` directory into the Cubic project directory so it's accessible inside the chroot.

### Step 4 — Run install script inside Cubic chroot

In Cubic's terminal tab:

```bash
bash /build/scripts/cubic-install.sh
```

### Step 5 — Generate ISO

In Cubic:
1. Set **ISO name**: `TanyelOS 24.04`
2. Set **filename**: `tanyelos-24.04`
3. Click **Generate**

The final ISO will be in your Cubic project directory.

### Step 6 — Test in VM

Boot `tanyelos-24.04.iso` in VirtualBox (live mode, no install needed):
1. GNOME loads with Aurora wallpaper + dark theme
2. Open **TanyelOS Tweaks** from the app grid
3. Switch accent colors, theme, font, wallpaper — all apply live

## Distributing the ISO

GitHub can't store ISO files. Use one of:
- **GitHub Releases** — `gh release create v1.0 tanyelos-24.04.iso`
- **Google Drive** — upload and share the link

## Design reference

The original TanyelOS web design (React simulation) is in `design-reference/`. It was used as the source of truth for the design system.

## Accent colors

| Name   | Hue | Hex     |
|--------|-----|---------|
| Teal   | 195 | #3d9eb5 |
| Amber  |  60 | #c99a2e |
| Rose   |  20 | #c96040 |
| Violet | 290 | #8b60c9 |
| Lime   | 130 | #5da64c |
