#!/usr/bin/env python3
"""Lightweight image picker and sibling shuffler for Quickshell PhotoWidget."""

import os
import random
import sys

IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".avif", ".bmp"}


def pick_random(target: str) -> int:
    directory = target if os.path.isdir(target) else os.path.dirname(target)
    if not directory or not os.path.isdir(directory):
        directory = os.path.expanduser("~/Pictures/Wallpapers")
    if not os.path.isdir(directory):
        return 1

    candidates = [
        os.path.join(directory, name)
        for name in sorted(os.listdir(directory))
        if os.path.splitext(name)[1].lower() in IMAGE_EXTS
        and os.path.isfile(os.path.join(directory, name))
    ]
    if not candidates:
        return 1

    others = [p for p in candidates if os.path.abspath(p) != os.path.abspath(target)]
    chosen = random.choice(others if others else candidates)
    print(chosen)
    return 0


def pick_dialog(start_target: str) -> int:
    import gi

    gi.require_version("Gtk", "3.0")
    from gi.repository import Gtk

    dialog = Gtk.FileChooserDialog(
        title="Choose Photo Frame Image",
        action=Gtk.FileChooserAction.OPEN,
    )
    dialog.add_buttons(
        Gtk.STOCK_CANCEL,
        Gtk.ResponseType.CANCEL,
        Gtk.STOCK_OPEN,
        Gtk.ResponseType.OK,
    )

    image_filter = Gtk.FileFilter()
    image_filter.set_name("Images")
    for ext in sorted(IMAGE_EXTS):
        image_filter.add_pattern(f"*{ext}")
        image_filter.add_pattern(f"*{ext.upper()}")
    dialog.add_filter(image_filter)

    start_dir = start_target if os.path.isdir(start_target) else os.path.dirname(start_target)
    if not start_dir or not os.path.isdir(start_dir):
        start_dir = os.path.expanduser("~/Pictures")
    if os.path.isdir(start_dir):
        dialog.set_current_folder(start_dir)

    response = dialog.run()
    selected = dialog.get_filename() if response == Gtk.ResponseType.OK else None
    dialog.destroy()

    if selected:
        print(selected)
        return 0
    return 1


def main() -> int:
    args = sys.argv[1:]
    if args and args[0] == "--random":
        return pick_random(args[1] if len(args) > 1 else "")
    start = args[1] if (args and args[0] == "--pick" and len(args) > 1) else (args[0] if args else "")
    return pick_dialog(start)


if __name__ == "__main__":
    sys.exit(main())
