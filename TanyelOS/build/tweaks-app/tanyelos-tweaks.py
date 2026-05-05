#!/usr/bin/env python3
"""TanyelOS Tweaks — native GTK4/libadwaita app for live theme switching.

Mirrors the tweaks panel from the TanyelOS web design.
Lets the user switch: Theme (light/dark), Accent color, Font, Wallpaper.

Install dependencies (Ubuntu 24.04):
    sudo apt install python3-gi gir1.2-gtk-4.0 gir1.2-adw-1

Run:
    python3 tanyelos-tweaks.py
"""

import gi
import subprocess
import os

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")
from gi.repository import Gtk, Adw, Gio, GLib, Gdk

APP_ID = "io.tanyelos.Tweaks"
VERSION = "1.0"

ACCENTS = [
    {"name": "Teal",   "key": "teal",   "hex": "#3d9eb5"},
    {"name": "Amber",  "key": "amber",  "hex": "#c99a2e"},
    {"name": "Rose",   "key": "rose",   "hex": "#c96040"},
    {"name": "Violet", "key": "violet", "hex": "#8b60c9"},
    {"name": "Lime",   "key": "lime",   "hex": "#5da64c"},
]

FONTS = [
    {"name": "Geist",        "family": "Geist"},
    {"name": "Inter",        "family": "Inter"},
    {"name": "IBM Plex Sans","family": "IBM Plex Sans"},
    {"name": "Manrope",      "family": "Manrope"},
]

WALLPAPERS = [
    {"name": "Aurora", "key": "aurora"},
    {"name": "Dusk",   "key": "dusk"},
    {"name": "Grid",   "key": "grid"},
    {"name": "Topo",   "key": "topo"},
    {"name": "Solid",  "key": "solid"},
]

WALLPAPER_DIR = "/usr/share/backgrounds/tanyelos"


def gsettings_set(schema, key, value):
    try:
        subprocess.run(["gsettings", "set", schema, key, value],
                       check=True, capture_output=True)
    except subprocess.CalledProcessError as e:
        print(f"gsettings error: {e.stderr.decode()}")


def get_current_dark_mode():
    try:
        result = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "color-scheme"],
            capture_output=True, text=True)
        return "dark" in result.stdout
    except Exception:
        return True


def get_current_accent():
    try:
        result = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "gtk-theme"],
            capture_output=True, text=True)
        theme = result.stdout.strip().strip("'")
        for a in ACCENTS:
            if a["key"] in theme.lower():
                return a["key"]
    except Exception:
        pass
    return "teal"


def get_current_font():
    try:
        result = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.interface", "font-name"],
            capture_output=True, text=True)
        font_str = result.stdout.strip().strip("'")
        family = " ".join(font_str.split()[:-1]) if font_str else "Geist"
        for f in FONTS:
            if f["family"].lower() in family.lower():
                return f["family"]
    except Exception:
        pass
    return "Geist"


def get_current_wallpaper():
    try:
        result = subprocess.run(
            ["gsettings", "get", "org.gnome.desktop.background", "picture-uri"],
            capture_output=True, text=True)
        uri = result.stdout.strip().strip("'")
        for wp in WALLPAPERS:
            if wp["key"] in uri:
                return wp["key"]
    except Exception:
        pass
    return "aurora"


class TanyelOSTweaks(Adw.Application):
    def __init__(self):
        super().__init__(application_id=APP_ID,
                         flags=Gio.ApplicationFlags.FLAGS_NONE)
        self.connect("activate", self.on_activate)

    def on_activate(self, app):
        self.win = TweaksWindow(application=app)
        self.win.present()


class TweaksWindow(Adw.ApplicationWindow):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.set_title("TanyelOS Tweaks")
        self.set_default_size(380, 560)
        self.set_resizable(False)

        self._dark = get_current_dark_mode()
        self._accent = get_current_accent()
        self._font = get_current_font()
        self._wallpaper = get_current_wallpaper()

        self._build_ui()

    def _build_ui(self):
        # Toolbar + scroll
        toolbar_view = Adw.ToolbarView()
        self.set_content(toolbar_view)

        header = Adw.HeaderBar()
        header.set_show_end_title_buttons(True)
        toolbar_view.add_top_bar(header)

        scroll = Gtk.ScrolledWindow()
        scroll.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scroll.set_vexpand(True)
        toolbar_view.set_content(scroll)

        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
        box.set_margin_top(8)
        box.set_margin_bottom(16)
        box.set_margin_start(16)
        box.set_margin_end(16)
        scroll.set_child(box)

        # ── Theme section ──
        box.append(self._section_label("Appearance"))

        theme_group = Adw.PreferencesGroup()
        box.append(theme_group)

        theme_row = Adw.ActionRow()
        theme_row.set_title("Dark Mode")
        theme_row.set_subtitle("Switch between light and dark theme")
        self._theme_switch = Gtk.Switch()
        self._theme_switch.set_active(self._dark)
        self._theme_switch.set_valign(Gtk.Align.CENTER)
        self._theme_switch.connect("state-set", self._on_theme_toggled)
        theme_row.add_suffix(self._theme_switch)
        theme_row.set_activatable_widget(self._theme_switch)
        theme_group.add(theme_row)

        # ── Accent section ──
        box.append(self._section_label("Accent Color"))

        accent_group = Adw.PreferencesGroup()
        box.append(accent_group)

        accent_row = Adw.ActionRow()
        accent_row.set_title("Color")
        accent_row.set_subtitle("Applied to buttons, highlights, and indicators")
        accent_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        accent_box.set_valign(Gtk.Align.CENTER)

        self._accent_buttons = {}
        for a in ACCENTS:
            btn = Gtk.Button()
            btn.set_size_request(28, 28)
            btn.set_tooltip_text(a["name"])
            btn.add_css_class("circular")
            self._set_button_color(btn, a["hex"])
            if a["key"] == self._accent:
                btn.add_css_class("accent-selected")
            btn.connect("clicked", self._on_accent_clicked, a["key"])
            self._accent_buttons[a["key"]] = btn
            accent_box.append(btn)

        accent_row.add_suffix(accent_box)
        accent_group.add(accent_row)

        # ── Font section ──
        box.append(self._section_label("Font"))

        font_group = Adw.PreferencesGroup()
        box.append(font_group)

        font_row = Adw.ComboRow()
        font_row.set_title("Interface Font")
        font_row.set_subtitle("Applied to all system UI text")
        font_model = Gtk.StringList()
        selected_idx = 0
        for i, f in enumerate(FONTS):
            font_model.append(f["name"])
            if f["family"] == self._font:
                selected_idx = i
        font_row.set_model(font_model)
        font_row.set_selected(selected_idx)
        font_row.connect("notify::selected", self._on_font_changed)
        font_group.add(font_row)
        self._font_row = font_row

        # ── Wallpaper section ──
        box.append(self._section_label("Wallpaper"))

        wp_group = Adw.PreferencesGroup()
        box.append(wp_group)

        wp_row = Adw.ActionRow()
        wp_row.set_title("Style")
        wp_row.set_subtitle("Choose your desktop background")
        wp_flow = Gtk.FlowBox()
        wp_flow.set_max_children_per_line(5)
        wp_flow.set_selection_mode(Gtk.SelectionMode.SINGLE)
        wp_flow.set_valign(Gtk.Align.CENTER)
        wp_flow.set_homogeneous(True)

        self._wp_buttons = {}
        for wp in WALLPAPERS:
            wp_btn = self._make_wallpaper_button(wp)
            wp_flow.append(wp_btn)
            self._wp_buttons[wp["key"]] = wp_btn

        wp_flow.connect("child-activated", self._on_wallpaper_activated)
        wp_row.add_suffix(wp_flow)
        wp_group.add(wp_row)

        # ── About section ──
        box.append(self._section_label(""))
        about_group = Adw.PreferencesGroup()
        box.append(about_group)

        about_row = Adw.ActionRow()
        about_row.set_title("TanyelOS Tweaks")
        about_row.set_subtitle(f"Version {VERSION}")
        about_group.add(about_row)

    def _section_label(self, text):
        lbl = Gtk.Label(label=text)
        lbl.set_halign(Gtk.Align.START)
        lbl.set_margin_top(16)
        lbl.set_margin_bottom(4)
        lbl.add_css_class("heading")
        return lbl

    def _set_button_color(self, btn, hex_color):
        css = f"""
        button {{
            background-color: {hex_color};
            border: 2px solid transparent;
            min-width: 28px;
            min-height: 28px;
        }}
        button.accent-selected {{
            border-color: alpha(currentColor, 0.8);
            box-shadow: 0 0 0 2px {hex_color};
        }}
        """
        provider = Gtk.CssProvider()
        provider.load_from_string(css)
        btn.get_style_context().add_provider(provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION)

    def _make_wallpaper_button(self, wp):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        box.set_margin_top(4)
        box.set_margin_bottom(4)
        box.set_margin_start(4)
        box.set_margin_end(4)

        preview = Gtk.DrawingArea()
        preview.set_size_request(48, 32)
        preview.set_draw_func(self._draw_wallpaper_preview, wp["key"])

        label = Gtk.Label(label=wp["name"])
        label.set_css_classes(["caption"])

        box.append(preview)
        box.append(label)
        return box

    def _draw_wallpaper_preview(self, area, cr, width, height, wp_key):
        # Draw a simple color preview for each wallpaper style
        previews = {
            "aurora": [(0.07, 0.08, 0.14), (0.15, 0.40, 0.50)],
            "dusk":   [(0.55, 0.28, 0.15), (0.20, 0.12, 0.30)],
            "grid":   [(0.10, 0.12, 0.18), (0.22, 0.55, 0.65)],
            "topo":   [(0.16, 0.18, 0.22), (0.24, 0.50, 0.58)],
            "solid":  [(0.22, 0.60, 0.72), (0.22, 0.60, 0.72)],
        }
        colors = previews.get(wp_key, [(0.2, 0.2, 0.2), (0.4, 0.4, 0.4)])
        import math as _m
        pattern = cairo_linear(cr, 0, 0, width, height, colors[0], colors[1])
        cr.set_source(pattern)
        cr.rectangle(0, 0, width, height)
        cr.fill()

        if wp_key == self._wallpaper:
            cr.set_source_rgba(1, 1, 1, 0.9)
            cr.set_line_width(2)
            cr.rectangle(1, 1, width - 2, height - 2)
            cr.stroke()

    def _on_theme_toggled(self, switch, state):
        self._dark = state
        self._apply_theme()
        return False

    def _on_accent_clicked(self, btn, key):
        for k, b in self._accent_buttons.items():
            b.remove_css_class("accent-selected")
        btn.add_css_class("accent-selected")
        self._accent = key
        self._apply_theme()

    def _on_font_changed(self, row, _):
        idx = row.get_selected()
        self._font = FONTS[idx]["family"]
        gsettings_set("org.gnome.desktop.interface", "font-name", f"{self._font} 11")
        gsettings_set("org.gnome.desktop.interface", "document-font-name", f"{self._font} 11")

    def _on_wallpaper_activated(self, flow, child):
        idx = child.get_index()
        wp = WALLPAPERS[idx]
        self._wallpaper = wp["key"]
        self._apply_wallpaper()

    def _apply_theme(self):
        variant = "dark" if self._dark else "light"
        theme_name = f"tanyelos-{self._accent}-{variant}"
        color_scheme = "prefer-dark" if self._dark else "prefer-light"

        gsettings_set("org.gnome.desktop.interface", "gtk-theme", theme_name)
        gsettings_set("org.gnome.desktop.interface", "color-scheme", color_scheme)
        gsettings_set("org.gnome.shell.extensions.user-theme", "name", theme_name)
        self._apply_wallpaper()

    def _apply_wallpaper(self):
        variant = "dark" if self._dark else "light"
        wp_name = f"{self._wallpaper}-{variant}.png"
        uri = f"file://{WALLPAPER_DIR}/{wp_name}"

        gsettings_set("org.gnome.desktop.background", "picture-uri", uri)
        gsettings_set("org.gnome.desktop.background", "picture-uri-dark", uri)
        gsettings_set("org.gnome.desktop.background", "picture-options", "zoom")


def cairo_linear(cr, x0, y0, x1, y1, c1, c2):
    try:
        import cairo
        pat = cairo.LinearGradient(x0, y0, x1, y1)
        pat.add_color_stop_rgb(0, *c1)
        pat.add_color_stop_rgb(1, *c2)
        return pat
    except ImportError:
        cr.set_source_rgb(*c1)
        return None


def main():
    app = TanyelOSTweaks()
    app.run(None)


if __name__ == "__main__":
    main()
