#!/usr/bin/env bash
# ==========================================================
# BRIGHTNESS OSD - Brightnessctl
# ==========================================================

case "$1" in
    up)
        brightnessctl set 5%+
        ;;
    down)
        brightnessctl set 5%-
        ;;
esac

bri=$(brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 0, length($4)-1)}')
notify-send -h string:x-canonical-private-synchronous:brightness -h int:value:"$bri" "Brightness: ${bri}%" -t 1200 -i display-brightness
