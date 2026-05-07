#!/usr/bin/env python3
"""TanyelOS Tweaks — compact floating panel for theme, accent, font, and wallpaper."""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gio, Adw, Gdk, GLib

import os
import subprocess

WALLPAPER_DIR = os.path.expanduser('~/.local/share/wallpapers/tanyel')

WALLPAPERS = ['aurora', 'dusk', 'grid', 'topo', 'solid']

ACCENTS = [
    ('teal',   '#2B9EA8'),
    ('amber',  '#D4A843'),
    ('rose',   '#E05C4A'),
    ('violet', '#8B6FC2'),
    ('lime',   '#5DB348'),
]

FONTS = ['Geist', 'Inter', 'IBM Plex Sans', 'JetBrains Mono', 'Cantarell', 'Ubuntu']

PANEL_CSS = """
.t-tweaks-panel {
  background: alpha(@theme_bg_color, 0.96);
  border-radius: 14px;
  border: 0.5px solid alpha(@borders, 0.8);
  box-shadow:
    0 1px 2px rgba(0,0,0,0.06),
    0 8px 24px rgba(0,0,0,0.16);
  padding: 0;
}

.t-tweaks-titlebar {
  padding: 12px 14px 6px 16px;
  font-weight: 600;
  font-size: 14px;
}

.t-tweaks-section-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: alpha(@theme_fg_color, 0.55);
  margin: 12px 16px 8px 16px;
}

.t-tweaks-row {
  padding: 6px 16px;
}

.t-tweaks-row label.title {
  font-size: 13px;
  font-weight: 500;
}

.t-close {
  min-width: 24px;
  min-height: 24px;
  padding: 2px;
  border-radius: 999px;
  background: transparent;
  border: none;
}
.t-close:hover {
  background: alpha(@theme_fg_color, 0.08);
}

button.t-seg {
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 500;
  min-height: 24px;
}
button.t-seg:checked {
  background: @theme_bg_color;
  color: @theme_fg_color;
  font-weight: 600;
}
"""


class TweaksWindow(Gtk.Window):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title('Tweaks')
        self.set_decorated(False)
        self.set_default_size(300, 360)
        self.set_resizable(False)
        self.add_css_class('t-tweaks-panel')

        self.iface = Gio.Settings.new('org.gnome.desktop.interface')
        self.bg = Gio.Settings.new('org.gnome.desktop.background')

        self._load_css()

        # Outer container
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_child(outer)

        # Custom titlebar
        titlebar = Gtk.WindowHandle()
        title_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        title_box.add_css_class('t-tweaks-titlebar')
        title_label = Gtk.Label(label='Tweaks', xalign=0, hexpand=True)
        title_label.add_css_class('title')
        close_btn = Gtk.Button(icon_name='window-close-symbolic')
        close_btn.add_css_class('t-close')
        close_btn.connect('clicked', lambda _: self.close())
        title_box.append(title_label)
        title_box.append(close_btn)
        titlebar.set_child(title_box)
        outer.append(titlebar)

        # APPEARANCE section
        outer.append(self._section_label('APPEARANCE'))
        outer.append(self._row('Theme', self._build_theme_toggle()))
        outer.append(self._row('Accent', self._build_accent_segments()))
        outer.append(self._row('Font', self._build_font_dropdown()))

        # DESKTOP section
        outer.append(self._section_label('DESKTOP'))
        outer.append(self._row('Wallpaper', self._build_wallpaper_dropdown()))

        # bottom padding
        spacer = Gtk.Box()
        spacer.set_size_request(0, 12)
        outer.append(spacer)

    def _load_css(self):
        provider = Gtk.CssProvider()
        provider.load_from_data(PANEL_CSS.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

    def _section_label(self, text):
        lbl = Gtk.Label(label=text, xalign=0)
        lbl.add_css_class('t-tweaks-section-label')
        return lbl

    def _row(self, title, control):
        row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        row.add_css_class('t-tweaks-row')
        title_lbl = Gtk.Label(label=title, xalign=0, hexpand=True)
        title_lbl.add_css_class('title')
        row.append(title_lbl)
        row.append(control)
        return row

    # ── Theme toggle (Light/Dark segmented) ──────────────────────
    def _build_theme_toggle(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0,
                      css_classes=['linked'])
        box.set_valign(Gtk.Align.CENTER)
        light_btn = Gtk.ToggleButton(label='light')
        dark_btn = Gtk.ToggleButton(label='dark')
        light_btn.add_css_class('t-seg')
        dark_btn.add_css_class('t-seg')
        dark_btn.set_group(light_btn)

        current = self.iface.get_string('color-scheme')
        if 'dark' in current:
            dark_btn.set_active(True)
        else:
            light_btn.set_active(True)

        light_btn.connect('toggled', lambda b: b.get_active() and self._set_theme('light'))
        dark_btn.connect('toggled', lambda b: b.get_active() and self._set_theme('dark'))

        box.append(light_btn)
        box.append(dark_btn)
        return box

    def _set_theme(self, mode):
        if mode == 'dark':
            self.iface.set_string('color-scheme', 'prefer-dark')
            self.iface.set_string('gtk-theme', 'TanyelOS-Dark')
            try:
                Gio.Settings.new('org.gnome.shell.extensions.user-theme') \
                    .set_string('name', 'TanyelOS-Dark')
            except Exception:
                pass
        else:
            self.iface.set_string('color-scheme', 'default')
            self.iface.set_string('gtk-theme', 'TanyelOS-Light')
            try:
                Gio.Settings.new('org.gnome.shell.extensions.user-theme') \
                    .set_string('name', 'TanyelOS-Light')
            except Exception:
                pass
        # Re-apply current wallpaper variant
        self._update_wallpaper_for_theme()

    def _update_wallpaper_for_theme(self):
        # Find current wallpaper base name (strip -dark/-light)
        current = self.bg.get_string('picture-uri') or ''
        for name in WALLPAPERS:
            if name in current:
                self._set_wallpaper(name)
                return
        self._set_wallpaper('aurora')

    # ── Accent segmented buttons ──────────────────────────────────
    def _build_accent_segments(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0,
                      css_classes=['linked'])
        box.set_valign(Gtk.Align.CENTER)

        saved = self._read_saved_accent()
        first_btn = None
        for i, (name, hex_) in enumerate(ACCENTS):
            btn = Gtk.ToggleButton(label=name)
            btn.add_css_class('t-seg')
            if i == 0:
                first_btn = btn
            else:
                btn.set_group(first_btn)
            if hex_.lower() == saved.lower():
                btn.set_active(True)
            btn.connect('toggled', self._on_accent_toggled, hex_, name)
            box.append(btn)
        return box

    def _on_accent_toggled(self, btn, hex_, name):
        if not btn.get_active():
            return
        try:
            subprocess.Popen(
                ['/usr/local/bin/tanyel-apply-accent', hex_],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL
            )
            # Toggle theme to force GTK CSS reload in running apps
            current_theme = self.iface.get_string('gtk-theme')
            GLib.timeout_add(100, lambda: self.iface.set_string('gtk-theme', 'Adwaita') or False)
            GLib.timeout_add(250, lambda: self.iface.set_string('gtk-theme', current_theme) or False)
        except FileNotFoundError:
            pass

    # ── Font dropdown ────────────────────────────────────────────
    def _build_font_dropdown(self):
        dd = Gtk.DropDown.new_from_strings(FONTS)
        dd.set_valign(Gtk.Align.CENTER)
        current = self.iface.get_string('font-name').rsplit(' ', 1)[0]
        if current in FONTS:
            dd.set_selected(FONTS.index(current))
        dd.connect('notify::selected', self._on_font_changed)
        return dd

    def _on_font_changed(self, dd, _):
        font = FONTS[dd.get_selected()]
        self.iface.set_string('font-name', f'{font} 11')
        if 'Mono' in font:
            self.iface.set_string('monospace-font-name', f'{font} 11')

    # ── Wallpaper dropdown ───────────────────────────────────────
    def _build_wallpaper_dropdown(self):
        dd = Gtk.DropDown.new_from_strings(WALLPAPERS)
        dd.set_valign(Gtk.Align.CENTER)
        # Restore current
        current = self.bg.get_string('picture-uri') or ''
        for i, name in enumerate(WALLPAPERS):
            if name in current:
                dd.set_selected(i)
                break
        dd.connect('notify::selected', self._on_wallpaper_changed)
        return dd

    def _on_wallpaper_changed(self, dd, _):
        self._set_wallpaper(WALLPAPERS[dd.get_selected()])

    def _set_wallpaper(self, name):
        light_path = os.path.join(WALLPAPER_DIR, f'{name}-light.jpg')
        dark_path = os.path.join(WALLPAPER_DIR, f'{name}-dark.jpg')
        # Picture URI for light/dark color schemes
        if os.path.exists(light_path):
            self.bg.set_string('picture-uri', f'file://{light_path}')
        elif os.path.exists(dark_path):
            self.bg.set_string('picture-uri', f'file://{dark_path}')
        if os.path.exists(dark_path):
            self.bg.set_string('picture-uri-dark', f'file://{dark_path}')
        self.bg.set_string('picture-options', 'zoom')

    # ── Helpers ──────────────────────────────────────────────────
    def _read_saved_accent(self):
        try:
            with open(os.path.expanduser('~/.config/tanyelos/accent')) as f:
                return f.read().strip()
        except (FileNotFoundError, OSError):
            return '#2B9EA8'


class TweaksApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.tanyelos.Tweaks',
                         flags=Gio.ApplicationFlags.DEFAULT_FLAGS)
        self.connect('activate', self._on_activate)

    def _on_activate(self, app):
        win = self.props.active_window
        if not win:
            win = TweaksWindow(app)
        win.present()


if __name__ == '__main__':
    app = TweaksApp()
    app.run(None)
