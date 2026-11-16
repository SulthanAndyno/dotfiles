#!/usr/bin/env bash
# ==========================================================
# POWER PROFILE SELECTOR MENU (Fuzzel GUI Selector)
# Allows switching between Power Saver, Balanced, Performance
# ==========================================================

MONITOR="eDP-1"

CHOSEN=$(printf "🍃 Power Saver (60Hz • Hemat Baterai)\n🌊 Balanced (144Hz • Seimbang)\n🔥 Performance (144Hz • Performa Tinggi)" | fuzzel --dmenu -p "⚡ Mode Daya: " -l 3 -w 36)

case "$CHOSEN" in
    *Power\ Saver*)
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set power-saver 2>/dev/null
        command -v asusctl >/dev/null 2>&1 && asusctl profile set Quiet 2>/dev/null
        hyprctl keyword monitor "${MONITOR},1920x1080@60,0x0,1"
        notify-send -u low -i battery -a "Power Mode" "🍃 Power Saver Aktif" "Layar dialihkan ke 60Hz. Baterai lebih awet dan laptop adem."
        ;;
    *Balanced*)
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set balanced 2>/dev/null
        command -v asusctl >/dev/null 2>&1 && asusctl profile set Balanced 2>/dev/null
        hyprctl keyword monitor "${MONITOR},1920x1080@144,0x0,1"
        notify-send -u low -i battery-charging -a "Power Mode" "🌊 Balanced Mode Aktif" "Layar dialihkan ke 144Hz. Performa seimbang."
        ;;
    *Performance*)
        command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set performance 2>/dev/null
        command -v asusctl >/dev/null 2>&1 && asusctl profile set Performance 2>/dev/null
        hyprctl keyword monitor "${MONITOR},1920x1080@144,0x0,1"
        notify-send -u low -i local_fire_department -a "Power Mode" "🔥 Performance Mode Aktif" "Layar 144Hz. Performa maksimal ASUS TUF!"
        ;;
esac
