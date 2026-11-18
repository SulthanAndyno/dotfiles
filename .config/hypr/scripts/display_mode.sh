#!/usr/bin/env bash
# ==========================================================
# MULTI-MONITOR & SCREEN DUPLICATE MANAGER (Hyprland Lua)
# Supports: Duplicate (Mirror), Extend, External Only, Laptop Only
# ==========================================================

INTERNAL="eDP-1"
MONITORS_JSON=$(hyprctl monitors all -j 2>/dev/null || echo "[]")
EXTERNAL=$(echo "$MONITORS_JSON" | jq -r --arg int "$INTERNAL" '.[] | select(.name != $int) | .name' | head -n 1)
LAPTOP_HZ=$(echo "$MONITORS_JSON" | jq -r --arg int "$INTERNAL" '.[] | select(.name == $int) | (.refreshRate // 144) | floor')
[ -z "$LAPTOP_HZ" ] || [ "$LAPTOP_HZ" -lt 50 ] && LAPTOP_HZ=144

sync_quickshell() {
    if command -v qs >/dev/null 2>&1; then
        (sleep 0.35 && qs -c ii ipc call hyprlandData syncMonitors >/dev/null 2>&1) &
    fi
}

require_external() {
    if [ -z "$EXTERNAL" ]; then
        notify-send -u low -i video-display -a "Display Mode" "🖥️ No External Display" "Plug in an HDMI or USB-C monitor/projector first."
        exit 0
    fi
}

apply_duplicate() {
    require_external
    local ext_mode="preferred"
    if echo "$MONITORS_JSON" | jq -r --arg ext "$EXTERNAL" '.[] | select(.name == $ext) | .availableModes[]' | grep -q "^1920x1080@60"; then
        ext_mode="1920x1080@60"
    fi
    hyprctl eval "hl.monitor({ output = \"${INTERNAL}\", mode = \"1920x1080@${LAPTOP_HZ}\", position = \"0x0\", scale = 1, disabled = false })" >/dev/null 2>&1
    hyprctl eval "hl.monitor({ output = \"${EXTERNAL}\", mode = \"${ext_mode}\", position = \"0x0\", scale = 1, mirror = \"${INTERNAL}\", disabled = false })" >/dev/null 2>&1
    sync_quickshell
    notify-send -u low -i video-display -a "Display Mode" "🪞 Duplicate Screen Active" "Mirroring ${INTERNAL} to ${EXTERNAL}."
}

apply_extend() {
    require_external
    hyprctl eval "hl.monitor({ output = \"${INTERNAL}\", mode = \"1920x1080@${LAPTOP_HZ}\", position = \"0x0\", scale = 1, disabled = false })" >/dev/null 2>&1
    hyprctl eval "hl.monitor({ output = \"${EXTERNAL}\", mode = \"preferred\", position = \"auto\", scale = 1, disabled = false })" >/dev/null 2>&1
    sync_quickshell
    notify-send -u low -i video-display -a "Display Mode" "🖥️ Extend Display Active" "${INTERNAL} + ${EXTERNAL} in dual-monitor mode."
}

apply_external_only() {
    require_external
    hyprctl eval "hl.monitor({ output = \"${EXTERNAL}\", mode = \"preferred\", position = \"0x0\", scale = 1, disabled = false })" >/dev/null 2>&1
    hyprctl eval "hl.monitor({ output = \"${INTERNAL}\", disabled = true })" >/dev/null 2>&1
    sync_quickshell
    notify-send -u low -i video-display -a "Display Mode" "📺 Second Screen Only" "Using ${EXTERNAL} only (${INTERNAL} off)."
}

apply_laptop_only() {
    hyprctl eval "hl.monitor({ output = \"${INTERNAL}\", mode = \"1920x1080@${LAPTOP_HZ}\", position = \"0x0\", scale = 1, disabled = false })" >/dev/null 2>&1
    if [ -n "$EXTERNAL" ]; then
        hyprctl eval "hl.monitor({ output = \"${EXTERNAL}\", disabled = true })" >/dev/null 2>&1
    fi
    sync_quickshell
    notify-send -u low -i video-display -a "Display Mode" "💻 Laptop Screen Only" "Using ${INTERNAL} only."
}

case "${1:-}" in
    --duplicate|duplicate)
        apply_duplicate
        exit 0
        ;;
    --extend|extend)
        apply_extend
        exit 0
        ;;
    --external|external)
        apply_external_only
        exit 0
        ;;
    --laptop|laptop)
        apply_laptop_only
        exit 0
        ;;
    --toggle|toggle)
        require_external
        MIRROR_OF=$(echo "$MONITORS_JSON" | jq -r --arg ext "$EXTERNAL" '.[] | select(.name == $ext) | .mirrorOf // "none"')
        if [ "$MIRROR_OF" != "none" ] && [ -n "$MIRROR_OF" ]; then
            apply_extend
        else
            apply_duplicate
        fi
        exit 0
        ;;
esac

CHOSEN=$(printf "🪞 Duplicate (Mirror Screen)\n🖥️ Extend (Dual Monitor)\n📺 Second Screen Only (External)\n💻 Laptop Screen Only (eDP-1)" | fuzzel --dmenu -p "🖥️ Display Mode: " -l 4 -w 42)

case "$CHOSEN" in
    *Duplicate*)
        apply_duplicate
        ;;
    *Extend*)
        apply_extend
        ;;
    *Second\ Screen*)
        apply_external_only
        ;;
    *Laptop\ Screen*)
        apply_laptop_only
        ;;
esac
