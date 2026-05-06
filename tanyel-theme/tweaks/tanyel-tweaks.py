#!/usr/bin/env python3
"""TanyelOS Tweaks — apply theme, accent color, font, and wallpaper settings."""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
from gi.repository import Gtk, Gio, Adw, GLib

import os
import subprocess

WALLPAPER_DIR = os.path.expanduser('~/.local/share/wallpapers/tanyel')

WALLPAPERS = [
    ('aurora', 'Aurora', 'Dark blue with teal nebula'),
    ('dusk',   'Dusk',   'Warm orange to deep purple'),
    ('grid',   'Grid',   'Clean lines on dark base'),
    ('topo',   'Topo',   'Topographic contour rings'),
    ('solid',  'Solid',  'Plain dark slate'),
]

ACCENTS = [
    ('teal',   '#2B9EA8', 'Teal'),
    ('amber',  '#D4A843', 'Amber'),
    ('rose',   '#E05C4A', 'Rose'),
    ('violet', '#8B6FC2', 'Violet'),
    ('lime',   '#5DB348', 'Lime'),
]

FONTS = ['Geist', 'Inter', 'Cantarell', 'Ubuntu', 'JetBrains Mono', 'Roboto']


class TweaksWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_title('TanyelOS Tweaks')
        self.set_default_size(440, 640)

        self.iface = Gio.Settings.new('org.gnome.desktop.interface')
        self.bg = Gio.Settings.new('org.gnome.desktop.background')

        toolbar_view = Adw.ToolbarView()
        header = Adw.HeaderBar()
        toolbar_view.add_top_bar(header)

        scrolled = Gtk.ScrolledWindow()
        scrolled.set_vexpand(True)

        clamp = Adw.Clamp()
        clamp.set_maximum_size(400)
        clamp.set_margin_top(24)
        clamp.set_margin_bottom(24)
        clamp.set_margin_start(16)
        clamp.set_margin_end(16)

        page = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=24)

        page.append(self._build_appearance_section())
        page.append(self._build_desktop_section())
        page.append(self._build_about_section())

        clamp.set_child(page)
        scrolled.set_child(clamp)
        toolbar_view.set_content(scrolled)
        self.set_content(toolbar_view)

    def _build_appearance_section(self):
        group = Adw.PreferencesGroup()
        group.set_title('Appearance')

        # Theme row (dark/light toggle)
        theme_row = Adw.ActionRow()
        theme_row.set_title('Theme')
        theme_row.set_subtitle('Switch between light and dark mode')

        theme_box = Gtk.Box(spacing=0, css_classes=['linked'])
        theme_box.set_valign(Gtk.Align.CENTER)
        light_btn = Gtk.ToggleButton(label='Light')
        dark_btn  = Gtk.ToggleButton(label='Dark')
        dark_btn.set_group(light_btn)

        current_scheme = self.iface.get_string('color-scheme')
        if 'dark' in current_scheme:
            dark_btn.set_active(True)
        else:
            light_btn.set_active(True)

        light_btn.connect('toggled', lambda b: b.get_active() and self.iface.set_string('color-scheme', 'default'))
        dark_btn.connect('toggled',  lambda b: b.get_active() and self.iface.set_string('color-scheme', 'prefer-dark'))

        theme_box.append(light_btn)
        theme_box.append(dark_btn)
        theme_row.add_suffix(theme_box)
        group.add(theme_row)

        # Accent color row
        accent_row = Adw.ActionRow()
        accent_row.set_title('Accent color')
        accent_row.set_subtitle('Highlight color for buttons and selections')

        accent_dropdown = Gtk.DropDown.new_from_strings([a[2] for a in ACCENTS])
        accent_dropdown.set_valign(Gtk.Align.CENTER)
        # Restore saved accent
        saved_accent = self._read_saved_accent()
        for i, a in enumerate(ACCENTS):
            if a[1].lower() == saved_accent.lower():
                accent_dropdown.set_selected(i)
                break
        accent_dropdown.connect('notify::selected', self._on_accent_changed)
        accent_row.add_suffix(accent_dropdown)
        group.add(accent_row)

        # Font row
        font_row = Adw.ActionRow()
        font_row.set_title('Interface font')
        font_row.set_subtitle('Used for menus, labels, and apps')

        font_dropdown = Gtk.DropDown.new_from_strings(FONTS)
        font_dropdown.set_valign(Gtk.Align.CENTER)
        current_font = self.iface.get_string('font-name').rsplit(' ', 1)[0]
        if current_font in FONTS:
            font_dropdown.set_selected(FONTS.index(current_font))
        font_dropdown.connect('notify::selected', self._on_font_changed)
        font_row.add_suffix(font_dropdown)
        group.add(font_row)

        return group

    def _build_desktop_section(self):
        group = Adw.PreferencesGroup()
        group.set_title('Desktop')

        wp_row = Adw.ActionRow()
        wp_row.set_title('Wallpaper')
        wp_row.set_subtitle('Background image')

        wp_dropdown = Gtk.DropDown.new_from_strings([w[1] for w in WALLPAPERS])
        wp_dropdown.set_valign(Gtk.Align.CENTER)
        wp_dropdown.connect('notify::selected', self._on_wallpaper_changed)
        wp_row.add_suffix(wp_dropdown)
        group.add(wp_row)

        # Show current wallpaper preview info
        info_row = Adw.ActionRow()
        info_row.set_title('Storage location')
        info_row.set_subtitle(WALLPAPER_DIR)
        group.add(info_row)

        return group

    def _build_about_section(self):
        group = Adw.PreferencesGroup()

        about_row = Adw.ActionRow()
        about_row.set_title('TanyelOS Tweaks')
        about_row.set_subtitle('Version 1.0 · github.com/Mrtea43/tanyel-os')
        group.add(about_row)

        return group

    def _on_accent_changed(self, dropdown, _):
        accent = ACCENTS[dropdown.get_selected()]
        # Run the apply-accent script that regenerates wallpapers + patches CSS
        try:
            result = subprocess.run(
                ['/usr/local/bin/tanyel-apply-accent', accent[1]],
                capture_output=True, text=True, timeout=30
            )
            if result.returncode == 0:
                self._toast(f'Accent → {accent[2]}: wallpapers regenerated, theme updated')
            else:
                self._toast(f'Accent change error: {result.stderr.strip()[:100]}')
        except FileNotFoundError:
            self._toast('tanyel-apply-accent not found — run install.sh')
        except subprocess.TimeoutExpired:
            self._toast('Accent change timed out')

    def _on_font_changed(self, dropdown, _):
        font = FONTS[dropdown.get_selected()]
        self.iface.set_string('font-name', f'{font} 11')
        if font == 'JetBrains Mono':
            self.iface.set_string('monospace-font-name', f'{font} 11')

    def _on_wallpaper_changed(self, dropdown, _):
        wp_id = WALLPAPERS[dropdown.get_selected()][0]
        wp_path = os.path.join(WALLPAPER_DIR, f'{wp_id}.jpg')
        if os.path.exists(wp_path):
            uri = f'file://{wp_path}'
            self.bg.set_string('picture-uri', uri)
            self.bg.set_string('picture-uri-dark', uri)
            self.bg.set_string('picture-options', 'zoom')
        else:
            self._toast(f'Wallpaper not found: {wp_path}')

    def _read_saved_accent(self):
        try:
            with open(os.path.expanduser('~/.config/tanyelos/accent')) as f:
                return f.read().strip()
        except (FileNotFoundError, OSError):
            return '#2B9EA8'

    def _toast(self, msg):
        # Simple stderr log; could wire up Adw.Toast for proper UI feedback
        print(f'[Tweaks] {msg}')


class TweaksApp(Adw.Application):
    def __init__(self):
        super().__init__(application_id='com.tanyelos.Tweaks',
                         flags=Gio.ApplicationFlags.DEFAULT_FLAGS)
        self.connect('activate', self._on_activate)

    def _on_activate(self, app):
        win = self.props.active_window
        if not win:
            win = TweaksWindow(application=app)
        win.present()


if __name__ == '__main__':
    app = TweaksApp()
    app.run(None)
