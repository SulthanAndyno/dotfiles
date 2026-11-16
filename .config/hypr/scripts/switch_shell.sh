#!/usr/bin/env bash
# ==========================================================
# SHELL TOGGLE (WAYBAR+SWAYNC <---> NOCTALIA)
# ==========================================================

if pgrep -x "noctalia" >/dev/null 2>&1; then
    killall noctalia 2>/dev/null
    waybar &
    swaync &
    notify-send "Desktop Shell" "Switched to Waybar + SwayNC" -a "Hyprland"
else
    if command -v noctalia >/dev/null 2>&1; then
        killall waybar swaync 2>/dev/null
        noctalia &
        notify-send "Desktop Shell" "Switched to Noctalia Shell" -a "Hyprland"
    else
        notify-send "Noctalia Not Installed" "Install it first: sudo pacman -S noctalia" -u critical -a "Hyprland"
    fi
fi
