#!/usr/bin/env bash
# ==========================================================
# POWER PROFILE SELECTOR MENU (Fuzzel GUI Selector)
# 4 Modes: Power Saver, Balanced Eco (60Hz), Balanced Smooth (144Hz), Performance
# ==========================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUTO_SCRIPT="${SCRIPT_DIR}/power_profile_auto.sh"

CHOSEN=$(printf "🍃 Power Saver (60Hz • Ultra Efficiency)\n🔋 Balanced Eco (60Hz • Battery Friendly)\n🌊 Balanced Smooth (144Hz • Cool & Fluid)\n🔥 Performance (144Hz • Max Power)" | fuzzel --dmenu -p "⚡ Power Mode: " -l 4 -w 46)

case "$CHOSEN" in
    *Power\ Saver*)
        "$AUTO_SCRIPT" --apply 60 power-saver Quiet
        notify-send -u low -i battery -a "Power Mode" "🍃 Power Saver (60Hz)" "Maximum battery savings with 60Hz display and quiet cooling."
        ;;
    *Balanced\ Eco*)
        "$AUTO_SCRIPT" --apply 60 balanced Balanced
        notify-send -u low -i battery -a "Power Mode" "🔋 Balanced Eco (60Hz)" "60Hz display for battery life while keeping CPU responsive."
        ;;
    *Balanced\ Smooth*)
        "$AUTO_SCRIPT" --apply 144 balanced Balanced
        notify-send -u low -i battery-charging -a "Power Mode" "🌊 Balanced Smooth (144Hz)" "Fluid 144Hz display with balanced performance and quiet fans."
        ;;
    *Performance*)
        "$AUTO_SCRIPT" --apply 144 performance Performance
        notify-send -u low -i local_fire_department -a "Power Mode" "🔥 Performance (144Hz)" "Full ASUS TUF performance and 144Hz display enabled."
        ;;
esac
