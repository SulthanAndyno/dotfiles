#!/usr/bin/env bash
# ==========================================================
# DYNAMIC POWER & REFRESH RATE MANAGER (ASUS TUF FA506NC)
# Automatically switches between 144Hz (AC) and 60Hz (Battery)
# ==========================================================

MONITOR="eDP-1"
AC_SYS="/sys/class/power_supply/ACAD/online"
LAST_STATE=""

apply_power_state() {
    local current_state="0"
    if [ -f "$AC_SYS" ]; then
        current_state=$(cat "$AC_SYS" 2>/dev/null || echo "0")
    else
        if grep -q "1" /sys/class/power_supply/AC*/online 2>/dev/null; then
            current_state="1"
        else
            current_state="0"
        fi
    fi

    if [ "$current_state" = "$LAST_STATE" ]; then
        return
    fi

    LAST_STATE="$current_state"

    if [ "$current_state" = "1" ]; then
        # PLUGGED IN -> Performance Mode (144Hz)
        hyprctl keyword monitor "${MONITOR},1920x1080@144,0x0,1"
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set performance 2>/dev/null
        command -v asusctl >/dev/null 2>&1 && asusctl profile set Performance 2>/dev/null
        notify-send -u low -i battery-charging -a "Power Manager" "⚡ Mode Performa (144Hz)" "Charger terhubung. Mode Performa Maksimal & Layar 144Hz aktif."
    else
        # ON BATTERY -> Balanced Mode (60Hz)
        hyprctl keyword monitor "${MONITOR},1920x1080@60,0x0,1"
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set balanced 2>/dev/null
        command -v asusctl >/dev/null 2>&1 && asusctl profile set Balanced 2>/dev/null
        notify-send -u low -i battery -a "Power Manager" "🔋 Mode Baterai (60Hz • Balanced)" "Charger dicabut. Layar dialihkan ke 60Hz agar hemat baterai tapi tetap responsif."
    fi
}

case "$1" in
    --144|144)
        hyprctl keyword monitor "${MONITOR},1920x1080@144,0x0,1"
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set performance 2>/dev/null
        notify-send -u low -i video-display -a "Display" "Mode Manual (144Hz)" "Layar diset ke 144Hz."
        exit 0
        ;;
    --60|60)
        hyprctl keyword monitor "${MONITOR},1920x1080@60,0x0,1"
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set power-saver 2>/dev/null
        notify-send -u low -i video-display -a "Display" "Mode Manual (60Hz)" "Layar diset ke 60Hz."
        exit 0
        ;;
    --toggle|toggle)
        CURRENT_RATE=$(hyprctl monitors -j | jq -r '.[0].refreshRate // 144' | cut -d '.' -f 1)
        if [ "$CURRENT_RATE" -gt 100 ]; then
            hyprctl keyword monitor "${MONITOR},1920x1080@60,0x0,1"
            command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set power-saver 2>/dev/null
            notify-send -u low -i video-display -a "Display" "Layar: 60Hz" "Mode hemat baterai aktif."
        else
            hyprctl keyword monitor "${MONITOR},1920x1080@144,0x0,1"
            command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set balanced 2>/dev/null
            notify-send -u low -i video-display -a "Display" "Layar: 144Hz" "Mode mulus aktif."
        fi
        exit 0
        ;;
esac

apply_power_state

if command -v udevadm >/dev/null 2>&1; then
    udevadm monitor --udev --subsystem-match=power_supply 2>/dev/null | while read -r _; do
        apply_power_state
    done
else
    while true; do
        apply_power_state
        sleep 4
    done
fi
