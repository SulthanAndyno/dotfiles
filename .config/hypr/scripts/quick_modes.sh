#!/usr/bin/env bash
# ==========================================================
# PRESENTATION (DND), NIGHT LIGHT & CAFFEINE QUICK TOGGLES
# Syncs directly with Quickshell native services via IPC
# Usage:
#   quick_modes.sh --dnd         Toggle Do Not Disturb
#   quick_modes.sh --nightlight  Toggle Night Light (Hyprsunset)
#   quick_modes.sh --caffeine    Toggle Keep Awake (Idle Inhibitor)
#   quick_modes.sh               Interactive Fuzzel selector
# ==========================================================
set -u

ipc_call() {
    qs -c ii ipc call "$@" 2>/dev/null | tr -d '"' | tr -d '[:space:]'
}

toggle_dnd() {
    local cur
    cur=$(ipc_call notifications statusSilent)
    if [ "$cur" = "OFF" ] || [ -z "$cur" ]; then
        notify-send -u low -t 1800 -i notifications-disabled -a "Presentation Mode" "Do Not Disturb ON" "Pop-up notifications silenced."
        sleep 0.12
        ipc_call notifications toggleSilent >/dev/null
    else
        ipc_call notifications toggleSilent >/dev/null
        notify-send -u low -t 2000 -i notifications -a "Presentation Mode" "Notifications Active" "Do Not Disturb turned off."
    fi
}

toggle_nightlight() {
    local state
    state=$(ipc_call nightlight toggle)
    if [ "$state" = "ON" ]; then
        notify-send -u low -t 2000 -i weather-clear-night -a "Night Light" "Eye-Care Warmth ON" "Screen warmth filter enabled."
    else
        notify-send -u low -t 2000 -i weather-clear -a "Night Light" "Night Light OFF" "Standard 6500K color temperature active."
    fi
}

toggle_caffeine() {
    local state
    state=$(ipc_call idle toggle)
    if [ "$state" = "ON" ]; then
        notify-send -u low -t 2000 -i preferences-desktop-screensaver -a "Caffeine" "Keep Awake ON" "Auto-lock and sleep inhibited."
    else
        notify-send -u low -t 2000 -i system-lock-screen -a "Caffeine" "Keep Awake OFF" "Normal idle auto-lock resumed."
    fi
}

case "${1:-}" in
    --dnd|dnd)
        toggle_dnd
        ;;
    --nightlight|nightlight)
        toggle_nightlight
        ;;
    --caffeine|caffeine)
        toggle_caffeine
        ;;
    *)
        DND_ST=$(ipc_call notifications statusSilent)
        NL_ST=$(ipc_call nightlight status)
        CAF_ST=$(ipc_call idle status)

        CHOSEN=$(printf "🔕 Presentation DND  [%s]\n🌙 Night Light Eye-Care  [%s]\n☕ Caffeine Keep Awake  [%s]" \
            "${DND_ST:-?}" "${NL_ST:-?}" "${CAF_ST:-?}" | fuzzel --dmenu -p "🎛️ Quick Modes: " -l 3 -w 42)

        case "$CHOSEN" in
            *Presentation*) toggle_dnd ;;
            *Night\ Light*) toggle_nightlight ;;
            *Caffeine*)     toggle_caffeine ;;
        esac
        ;;
esac
