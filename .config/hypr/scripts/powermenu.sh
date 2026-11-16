#!/usr/bin/env bash
# ==========================================================
# POWER MENU - Fuzzel Minimalist Session Launcher
# ==========================================================

chosen=$(printf "󰌾  Lock\n󰤄  Suspend\n󰍃  Logout\n󰜉  Reboot\n󰐥  Power Off" | fuzzel -d -w 18 -l 5 -p "Power ❯ ")

case "$chosen" in
    *"Lock")
        swaylock -f -c 1e1e2e
        ;;
    *"Suspend")
        systemctl suspend
        ;;
    *"Logout")
        hyprctl dispatch exit
        ;;
    *"Reboot")
        systemctl reboot
        ;;
    *"Power Off")
        systemctl poweroff
        ;;
esac
