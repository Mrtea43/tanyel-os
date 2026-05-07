#!/usr/bin/env python3
"""TanyelOS Tweaks — compact floating panel for theme, accent, font, and wallpaper."""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gio, Adw, Gdk

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

# Local CSS — scoped to the Tweaks window only via .t-tweaks-* classes.
PANEL_CSS = b"""
.t-tweaks-titlebar {
  padding: 12px 14px 6px 16px;
  font-weight: 600;
}
.t-tweaks-section-label {
  font-size: 10px;
  font-weight: 600;
  margin: 12px 16px 6px 16px;
  opacity: 0.55;
}
.t-tweaks-row {
  padding: 6px 16px;
}
.t-tweaks-row > label.title {
  font-size: 13px;
  font-weight: 500;
}
button.t-seg {
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 500;
  min-height: 24px;
}
"""


def _safe(fn):
    """Wrap a callback so an exception never crashes the app/session."""
    def wrapper(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except Exception as e:
            print(f'[tanyel-tweaks] {fn.__name__} error: {e}')
    return wrapper


class TweaksWindow(Adw.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        self.set_title('Tweaks')
        self.set_default_size(320, 380)
        self.set_resizable(False)

        self.iface = Gio.Settings.new('org.gnome.desktop.interface')
        self.bg = Gio.Settings.new('org.gnome.desktop.background')
        # user-theme schema may not exist if extension is disabled
        try:
            schemas = Gio.SettingsSchemaSource.get_default()
            if schemas and schemas.lookup('org.gnome.shell.extensions.user-theme', True):
                self.user_theme = Gio.Settings.new('org.gnome.shell.extensions.user-theme')
            else:
                self.user_theme = None
        except Exception:
            self.user_theme = None

        self._load_local_css()

        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        self.set_content(outer)

        # Custom titlebar
        header = Adw.HeaderBar()
        header.set_title_widget(Gtk.Label(label='Tweaks'))
        outer.append(header)

        # APPEARANCE
        outer.append(self._section_label('APPEARANCE'))
        outer.append(self._row('Theme', self._build_theme_toggle()))
        outer.append(self._row('Accent', self._build_accent_segments()))
        outer.append(self._row('Font', self._build_font_dropdown()))

        # DESKTOP
        outer.append(self._section_label('DESKTOP'))
        outer.append(self._row('Wallpaper', self._build_wallpaper_dropdown()))

        outer.append(Gtk.Box(height_request=12))

    def _load_local_css(self):
        provider = Gtk.CssProvider()
        try:
            provider.load_from_data(PANEL_CSS)
            display = Gdk.Display.get_default()
            if display is not None:
                Gtk.StyleContext.add_provider_for_display(
                    display,
                    provider,
                    Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
                )
        except Exception as e:
            print(f'[tanyel-tweaks] CSS load failed: {e}')

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

    # ── Theme toggle ─────────────────────────────────────────────
    def _build_theme_toggle(self):
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0,
                      css_classes=['linked'])
        box.set_valign(Gtk.Align.CENTER)
        light_btn = Gtk.ToggleButton(label='light')
        dark_btn = Gtk.ToggleButton(label='dark')
        light_btn.add_css_class('t-seg')
        dark_btn.add_css_class('t-seg')
        dark_btn.set_group(light_btn)

        if 'dark' in (self.iface.get_string('color-scheme') or ''):
            dark_btn.set_active(True)
        else:
            light_btn.set_active(True)

        light_btn.connect('toggled', _safe(lambda b: b.get_active() and self._set_theme('light')))
        dark_btn.connect('toggled', _safe(lambda b: b.get_active() and self._set_theme('dark')))

        box.append(light_btn)
        box.append(dark_btn)
        return box

    @_safe
    def _set_theme(self, mode):
        variant = 'TanyelOS-Dark' if mode == 'dark' else 'TanyelOS-Light'
        scheme = 'prefer-dark' if mode == 'dark' else 'default'
        self.iface.set_string('color-scheme', scheme)
        self.iface.set_string('gtk-theme', variant)
        if self.user_theme is not None:
            self.user_theme.set_string('name', variant)
        self._update_wallpaper_for_theme()

    @_safe
    def _update_wallpaper_for_theme(self):
        current = self.bg.get_string('picture-uri') or ''
        for name in WALLPAPERS:
            if name in current:
                self._set_wallpaper(name)
                return
        self._set_wallpaper('aurora')

    # ── Accent ───────────────────────────────────────────────────
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
            btn.connect('toggled', _safe(self._on_accent_toggled), hex_)
            box.append(btn)
        return box

    def _on_accent_toggled(self, btn, hex_):
        if not btn.get_active():
            return
        # --no-wallpaper makes accent change feel instant: CSS + libadwaita
        # + Yaru icon-theme update in <100ms; user can pick a wallpaper
        # in the dropdown below if they want it tinted too.
        try:
            subprocess.Popen(
                ['/usr/local/bin/tanyel-apply-accent', hex_, '--no-wallpaper'],
                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        except FileNotFoundError:
            print('[tanyel-tweaks] tanyel-apply-accent not installed')

    # ── Font ─────────────────────────────────────────────────────
    def _build_font_dropdown(self):
        dd = Gtk.DropDown.new_from_strings(FONTS)
        dd.set_valign(Gtk.Align.CENTER)
        current = (self.iface.get_string('font-name') or '').rsplit(' ', 1)[0]
        if current in FONTS:
            dd.set_selected(FONTS.index(current))
        dd.connect('notify::selected', _safe(self._on_font_changed))
        return dd

    def _on_font_changed(self, dd, _):
        font = FONTS[dd.get_selected()]
        self.iface.set_string('font-name', f'{font} 11')
        if 'Mono' in font:
            self.iface.set_string('monospace-font-name', f'{font} 11')

    # ── Wallpaper ────────────────────────────────────────────────
    def _build_wallpaper_dropdown(self):
        dd = Gtk.DropDown.new_from_strings(WALLPAPERS)
        dd.set_valign(Gtk.Align.CENTER)
        current = self.bg.get_string('picture-uri') or ''
        for i, name in enumerate(WALLPAPERS):
            if name in current:
                dd.set_selected(i)
                break
        dd.connect('notify::selected', _safe(self._on_wallpaper_changed))
        return dd

    def _on_wallpaper_changed(self, dd, _):
        self._set_wallpaper(WALLPAPERS[dd.get_selected()])

    @_safe
    def _set_wallpaper(self, name):
        light_path = os.path.join(WALLPAPER_DIR, f'{name}-light.jpg')
        dark_path = os.path.join(WALLPAPER_DIR, f'{name}-dark.jpg')
        if os.path.exists(light_path):
            self.bg.set_string('picture-uri', f'file://{light_path}')
        elif os.path.exists(dark_path):
            self.bg.set_string('picture-uri', f'file://{dark_path}')
        if os.path.exists(dark_path):
            self.bg.set_string('picture-uri-dark', f'file://{dark_path}')
        self.bg.set_string('picture-options', 'zoom')

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
