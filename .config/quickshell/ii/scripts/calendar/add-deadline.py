#!/usr/bin/env python3
"""Lightweight GTK3 dialog to add a deadline title + date for CalendarWidget."""

import json
import re
import sys

import gi

gi.require_version("Gtk", "3.0")
from gi.repository import Gtk


def main() -> int:
    initial_date = sys.argv[1] if len(sys.argv) > 1 and re.match(r"^\d{4}-\d{2}-\d{2}$", sys.argv[1]) else ""

    dialog = Gtk.Dialog(title="Add Deadline Countdown")
    dialog.set_default_size(340, -1)
    dialog.set_resizable(False)
    dialog.add_buttons(
        Gtk.STOCK_CANCEL,
        Gtk.ResponseType.CANCEL,
        Gtk.STOCK_ADD,
        Gtk.ResponseType.OK,
    )
    dialog.set_default_response(Gtk.ResponseType.OK)

    box = dialog.get_content_area()
    box.set_spacing(10)
    box.set_margin_top(14)
    box.set_margin_bottom(10)
    box.set_margin_start(14)
    box.set_margin_end(14)

    title_lbl = Gtk.Label(label="Event / Deadline Title:")
    title_lbl.set_xalign(0)
    title_entry = Gtk.Entry()
    title_entry.set_placeholder_text("e.g. TP Modul 11, Kuis Jarkom")
    title_entry.set_activates_default(True)

    date_lbl = Gtk.Label(label="Target Date (YYYY-MM-DD):")
    date_lbl.set_xalign(0)

    cal = Gtk.Calendar()
    if initial_date:
        y, m, d = map(int, initial_date.split("-"))
        cal.select_month(m - 1, y)
        cal.select_day(d)

    date_entry = Gtk.Entry()
    if initial_date:
        date_entry.set_text(initial_date)
    else:
        y, m, d = cal.get_date()
        date_entry.set_text(f"{y:04d}-{m + 1:02d}-{d:02d}")
    date_entry.set_activates_default(True)

    def on_day_selected(_widget):
        y, m, d = cal.get_date()
        date_entry.set_text(f"{y:04d}-{m + 1:02d}-{d:02d}")

    cal.connect("day-selected", on_day_selected)

    box.pack_start(title_lbl, False, False, 0)
    box.pack_start(title_entry, False, False, 0)
    box.pack_start(date_lbl, False, False, 0)
    box.pack_start(date_entry, False, False, 0)
    box.pack_start(cal, False, False, 0)
    dialog.show_all()

    response = dialog.run()
    title_val = title_entry.get_text().strip()
    date_val = date_entry.get_text().strip()
    dialog.destroy()

    if response == Gtk.ResponseType.OK and title_val and re.match(r"^\d{4}-\d{2}-\d{2}$", date_val):
        print(json.dumps({"title": title_val, "date": date_val}))
        return 0
    return 1


if __name__ == "__main__":
    sys.exit(main())
