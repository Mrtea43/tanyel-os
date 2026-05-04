# TanyelOS — Custom Linux Distribution Plan

## Vision
A real bootable Linux OS where the TanyelOS design is the native desktop environment —
not a browser app, but an actual Wayland compositor, native apps, Plymouth boot screen,
and distributable ISO.

---

## Technology Stack (Recommended)

| Layer | Technology | Why |
|---|---|---|
| **Base distro** | Ubuntu 24.04 LTS minimal | Stable, large package ecosystem, good hardware support |
| **Display server** | Wayland | Modern, secure, no X11 legacy baggage |
| **Compositor** | wlroots (C) or Smithay (Rust) | Powers Sway, Hyprland — battle-tested primitives |
| **Shell / taskbar** | gtk4-layer-shell + GTK4 | Renders over the compositor; CSS-themeable |
| **Window decorations** | Custom CSD via libdecor | Matches TanyelOS rounded chrome, traffic-light buttons |
| **App framework** | GTK4 + libadwaita (custom theme) | Native feel, CSS overrideable to match TanyelOS design tokens |
| **Terminal** | Custom VTE-based (GTK4) | Matches TanyelOS terminal styling |
| **File manager** | Custom GTK4 app | Matches TanyelOS Files UI |
| **Boot animation** | Plymouth | TanyelOS logo + progress bar animation |
| **Login screen** | SDDM + custom QML theme | Matches TanyelOS dark/light style |
| **ISO builder** | `live-build` or `cubic` | Standard Ubuntu ISO customization |
| **Theming** | Custom GTK4 CSS + icon set | Design tokens from TanyelOS.html carried over |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    TanyelOS ISO (bootable)                   │
├─────────────────────────────────────────────────────────────┤
│  Plymouth boot  →  SDDM login  →  tanyel-session (systemd)  │
├─────────────────────────────────────────────────────────────┤
│                    tanyel-compositor                         │
│           (wlroots Wayland compositor in C/Rust)             │
│   • window management (drag, resize, min/max/close)          │
│   • workspaces                                               │
│   • wallpaper rendering                                      │
├────────────────┬────────────────┬───────────────────────────┤
│  tanyel-shell  │  tanyel-files  │  tanyel-terminal          │
│  (taskbar,     │  (file mgr,    │  (VTE-based,              │
│   start menu,  │   GTK4)        │   JetBrains Mono)         │
│   top bar,     ├────────────────┤                           │
│   notifs)      │  tanyel-about  │  tanyel-settings          │
│                │  tanyel-resume │  tanyel-contact           │
└────────────────┴────────────────┴───────────────────────────┘
│                  Ubuntu 24.04 LTS base                       │
│         (kernel, systemd, apt, hardware drivers)             │
└─────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
tanyel-os/
├── compositor/          # tanyel-compositor (wlroots/Smithay)
│   ├── src/
│   │   ├── main.c / main.rs
│   │   ├── output.c        # display/monitor handling
│   │   ├── seat.c          # keyboard/mouse/touch input
│   │   ├── xdg_shell.c     # window protocol
│   │   └── config.c        # theme tokens
│   └── meson.build
├── shell/               # taskbar, top bar, start menu, context menu
│   ├── src/
│   │   ├── taskbar.c
│   │   ├── start-menu.c
│   │   ├── top-bar.c
│   │   └── notifications.c
│   └── meson.build
├── apps/
│   ├── files/           # file manager
│   ├── terminal/        # terminal emulator
│   ├── settings/        # settings app
│   ├── about/           # about/portfolio app
│   ├── resume/          # resume viewer
│   └── contact/         # contact form app
├── theme/
│   ├── gtk4/            # GTK4 CSS theme (design tokens from TanyelOS.html)
│   ├── icons/           # custom icon set
│   ├── cursors/         # custom cursor theme
│   └── plymouth/        # boot animation
├── sddm-theme/          # login screen
├── iso/
│   ├── config/          # live-build configuration
│   ├── hooks/           # post-install scripts
│   └── package-lists/   # what goes in the ISO
├── sessions/
│   └── tanyel.desktop   # session descriptor for display managers
└── docs/
    └── build.md         # how to build the ISO
```

---

## Design Token Mapping (HTML → GTK4 CSS)

The TanyelOS.html design tokens map directly to GTK4 CSS variables:

```css
/* TanyelOS.html */
--bg-0: oklch(96% 0.005 80);
--accent: oklch(60% 0.13 195);
--radius: 10px;
--font: 'Geist', 'Inter', system-ui;

/* GTK4 theme (gtk.css) */
@define-color window_bg_color oklch(96% 0.005 80);
@define-color accent_color oklch(60% 0.13 195);
/* border-radius: 10px on .window */
```

---

## Development Phases

### Phase 1 — Foundation (4–6 weeks)
- [ ] Set up Ubuntu 24.04 minimal build VM
- [ ] Build a minimal wlroots compositor that opens windows
- [ ] Create `tanyel.session` and `tanyel.desktop` session files
- [ ] Boot into compositor from TTY (no display manager yet)
- [ ] Window open/close/move/resize working

### Phase 2 — Shell (6–8 weeks)
- [ ] Top bar (clock, app name, logo mark)
- [ ] Taskbar (running apps, start button, clock)
- [ ] Start menu (GTK4 popover with search + app grid)
- [ ] Right-click context menu (GTK4 menu)
- [ ] Desktop icon grid (draggable, selectable, double-click to open)
- [ ] Wallpaper rendering (Aurora, Dusk, Grid, Topo, Solid)

### Phase 3 — Window Chrome (3–4 weeks)
- [ ] Custom CSD (client-side decorations): rounded corners, traffic-light buttons
- [ ] Focus/unfocus styles (opacity, shadow)
- [ ] Maximize fills screen (minus taskbar/topbar)
- [ ] Minimize to taskbar

### Phase 4 — Core Apps (8–10 weeks)
- [ ] Terminal (VTE widget, tsh shell commands, JetBrains Mono, neofetch)
- [ ] File Manager (sidebar, grid view, breadcrumbs, double-click to navigate)
- [ ] Text/Markdown viewer
- [ ] Image viewer
- [ ] About app (avatar, markdown bio)
- [ ] Resume viewer (styled PDF-like layout)
- [ ] Contact app (form + links)
- [ ] Settings app (theme, accent, font, wallpaper)

### Phase 5 — System Integration (3–4 weeks)
- [ ] Plymouth boot theme (TanyelOS logo + progress bar)
- [ ] SDDM login theme (dark bg, logo, password field)
- [ ] systemd user session
- [ ] GTK4 theme applied system-wide
- [ ] Icon theme
- [ ] Font installation (Geist, JetBrains Mono)
- [ ] D-Bus notifications

### Phase 6 — ISO (2–3 weeks)
- [ ] `live-build` config for Ubuntu base
- [ ] Package list (minimal Ubuntu + Wayland + custom packages)
- [ ] Post-install hooks (set TanyelOS as default session)
- [ ] Bootable ISO build pipeline
- [ ] Test in QEMU/VirtualBox

---

## Key Dependencies

```bash
# Compositor
libwlroots-dev    # Wayland compositor primitives
libxkbcommon-dev  # keyboard handling
libdrm-dev        # display/GPU

# Shell + apps
libgtk-4-dev          # UI toolkit
libadwaita-1-dev      # GNOME HIG components (customizable)
gtk4-layer-shell-dev  # taskbar/notifications over Wayland
libvte-2.91-gtk4-dev  # terminal widget

# ISO
live-build        # Ubuntu ISO builder
debootstrap       # base system bootstrap
```

---

## Estimated Timeline

| Phase | Work |
|---|---|
| Phase 1 (Compositor foundation) | 4–6 weeks |
| Phase 2 (Shell) | 6–8 weeks |
| Phase 3 (Window chrome) | 3–4 weeks |
| Phase 4 (Apps) | 8–10 weeks |
| Phase 5 (System integration) | 3–4 weeks |
| Phase 6 (ISO) | 2–3 weeks |
| **Total** | **~6–9 months solo** |

---

## Simpler Shortcut Path (1–2 months to something bootable)

If you want something real and bootable faster:

1. Use **Sway** (existing wlroots compositor) instead of writing one
2. Style **waybar** with CSS matching TanyelOS taskbar
3. Use **fuzzel** for the start menu launcher (CSS-themeable)
4. Build apps in **GTK4 + Python** (faster than C/Rust)
5. Plymouth + SDDM themes for boot/login
6. Package as Ubuntu ISO with Cubic

This trades "fully custom compositor" for "working TanyelOS distro in 2 months."

---

## Language Recommendation

| Component | Language |
|---|---|
| Compositor | **Rust** (Smithay) — memory-safe, modern; or **C** (wlroots) — more examples |
| Shell + apps | **Python + GTK4** (fastest iteration) or **Rust + gtk4-rs** (type-safe) |
| Build system | **Meson** (standard for GTK ecosystem) |
| ISO scripting | **Bash** |
