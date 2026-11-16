#!/usr/bin/env bash
# ==========================================================
# WALLPAPER DAEMON & LOADER - AWWW
# ==========================================================

WALLPAPER="/home/Shuu/Pictures/Wallpapers/Anju Inami.png"
if [ ! -f "$WALLPAPER" ]; then
    WALLPAPER="/home/Shuu/.local/share/backgrounds/2026-08-16-23-33-59-Anju Inami.png"
fi

# Clean up stale socket if daemon is dead
if ! pgrep -x "awww-daemon" >/dev/null; then
    rm -f "/run/user/$(id -u)/${WAYLAND_DISPLAY:-wayland-1}-awww-daemon.sock" 2>/dev/null
    awww-daemon &
    for i in {1..20}; do
        if awww query >/dev/null 2>&1; then
            break
        fi
        sleep 0.1
    done
fi

if [ -f "$WALLPAPER" ]; then
    awww img "$WALLPAPER" --transition-type wipe --transition-angle 30 --transition-step 90 2>/dev/null || awww img "$WALLPAPER" 2>/dev/null || true
fi
