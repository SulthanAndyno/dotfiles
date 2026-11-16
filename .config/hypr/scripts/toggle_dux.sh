#!/usr/bin/env bash
# ==========================================================
# DUX SHELL (QUICKSHELL + GO) TOGGLE & MANAGER
# ==========================================================

if pgrep -x "dms" >/dev/null 2>&1; then
    dms kill 2>/dev/null || killall dms 2>/dev/null
    waybar &
    swaync &
    notify-send "Desktop Shell" "Switched to Waybar + SwayNC" -a "Hyprland"
else
    if command -v dms >/dev/null 2>&1; then
        killall waybar swaync 2>/dev/null
        dms run &
        notify-send "Dux Shell Activated" "Quickshell Dynamic Island is running!" -a "Hyprland"
    else
        notify-send "Dux Shell Not Installed" "Run: sudo pacman -S dux-shell in terminal" -u critical -a "Hyprland"
    fi
fi
