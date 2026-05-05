# TanyelOS

A beautiful Linux desktop based on Ubuntu 24.04. Same rock-solid foundation — completely different look and feel.

Dark theme, teal accents, frosted glass taskbar at the bottom, custom boot animation, and a Start button. All of it applied in one command on top of a fresh Ubuntu install.

---

## What you get

- **Bottom taskbar** with a Start button and open window list
- **Dark theme** with teal accent color across all apps
- **Custom boot animation** — TanyelOS logo with a progress bar
- **Frosted glass menus** and context menus
- **JetBrains Mono** for the terminal
- **5 wallpapers** — Aurora, Dusk, Grid, Topo, Solid
- **5 accent colors** — Teal, Amber, Rose, Violet, Lime

---

## Requirements

| | Minimum | Recommended |
|---|---|---|
| CPU | 2-core 64-bit | 4-core 64-bit |
| RAM | 2 GB | 8 GB |
| Storage | 20 GB | 40 GB SSD |
| Display | 1024×768 | 1920×1080 |

---

## Install

TanyelOS runs on top of Ubuntu 24.04. You need Ubuntu installed first.

**Step 1 — Get Ubuntu 24.04**

Download the ISO from [ubuntu.com](https://ubuntu.com/download/desktop) and install it. If you want to try it in a VM first, see the VirtualBox section below.

**Step 2 — Open a terminal and run:**

```bash
sudo apt install -y git && git clone https://github.com/Mrtea43/tanyel-os.git && cd tanyel-os/tanyel-theme && bash install.sh
```

**Step 3 — Log out and back in**

TanyelOS will be active when you log back in.

---

## Running in VirtualBox (Windows / Mac)

1. Download [VirtualBox](https://www.virtualbox.org) — free
2. Create a new VM: **Linux → Ubuntu 64-bit**
3. Set **4 GB RAM**, **2 CPUs**, **25 GB disk**
4. Go to **Settings → Storage** and attach the Ubuntu ISO
5. Go to **Settings → Display** and set **128 MB VRAM**
6. Boot the VM and install Ubuntu
7. After install, open the terminal and run the command above

---

## After install

If the shell theme doesn't apply automatically:

1. Open **GNOME Tweaks** → Appearance → Shell → select **TanyelOS**
2. Open **Extensions** app and make sure these are enabled:
   - Dash to Panel
   - ArcMenu
   - User Themes
   - Blur my Shell
   - Just Perfection

To change accent color or wallpaper, go to **Settings → Appearance**.

---

## Uninstall

```bash
cd tanyel-os/tanyel-theme && bash uninstall.sh
```

This removes all TanyelOS files and restores Ubuntu's default theme.

---

## License

MIT — free to use, share, and modify.
