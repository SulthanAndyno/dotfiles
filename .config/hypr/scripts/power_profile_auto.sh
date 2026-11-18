#!/usr/bin/env bash
# ==========================================================
# DYNAMIC POWER & REFRESH RATE MANAGER (ASUS TUF FA506NC)
# Automatically switches between 144Hz (AC) and 60Hz (Battery)
# ==========================================================

MONITOR="eDP-1"
AC_SYS="/sys/class/power_supply/ACAD/online"
LAST_STATE=""

# Apply Hyprland Lua monitor mode, system power profiles, and notify Quickshell.
set_display_and_power() {
    local hz="$1"
    local pp_mode="$2"
    local asus_mode="$3"

    hyprctl eval "hl.monitor({ output = \"${MONITOR}\", mode = \"1920x1080@${hz}\", position = \"0x0\", scale = 1 })" >/dev/null 2>&1
    command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set "$pp_mode" 2>/dev/null
    command -v asusctl >/dev/null 2>&1 && asusctl profile set "$asus_mode" 2>/dev/null

    if command -v qs >/dev/null 2>&1; then
        (sleep 0.3 && qs -c ii ipc call hyprlandData syncMonitors >/dev/null 2>&1) &
    fi
}

apply_power_state() {
    local current_state="0"
    if [ -f "$AC_SYS" ]; then
        current_state=$(cat "$AC_SYS" 2>/dev/null || echo "0")
    elif grep -q "1" /sys/class/power_supply/AC*/online 2>/dev/null; then
        current_state="1"
    fi

    if [ "$current_state" = "$LAST_STATE" ]; then
        return
    fi

    LAST_STATE="$current_state"

    if [ "$current_state" = "1" ]; then
        set_display_and_power 144 performance Performance
        notify-send -u low -i battery-charging -a "Power Manager" "⚡ Performance Mode (144Hz)" "AC connected. Full performance and 144Hz display active."
    else
        set_display_and_power 60 balanced Balanced
        notify-send -u low -i battery -a "Power Manager" "🔋 Balanced Eco (60Hz)" "AC unplugged. Switched to 60Hz and balanced power for battery life."
    fi
}

case "${1:-}" in
    --apply)
        set_display_and_power "${2:-144}" "${3:-balanced}" "${4:-Balanced}"
        exit 0
        ;;
    --144|144)
        set_display_and_power 144 performance Performance
        notify-send -u low -i video-display -a "Display" "Manual Mode (144Hz)" "Display set to 144Hz."
        exit 0
        ;;
    --60|60)
        set_display_and_power 60 power-saver Quiet
        notify-send -u low -i video-display -a "Display" "Manual Mode (60Hz)" "Display set to 60Hz."
        exit 0
        ;;
    --toggle|toggle)
        CURRENT_RATE=$(hyprctl monitors -j | jq -r '.[0].refreshRate // 144' | cut -d '.' -f 1)
        if [ "$CURRENT_RATE" -gt 100 ]; then
            set_display_and_power 60 power-saver Quiet
            notify-send -u low -i video-display -a "Display" "Display: 60Hz" "Battery saving refresh rate active."
        else
            set_display_and_power 144 balanced Balanced
            notify-send -u low -i video-display -a "Display" "Display: 144Hz" "Smooth refresh rate active."
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
