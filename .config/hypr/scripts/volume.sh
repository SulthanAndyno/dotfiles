#!/usr/bin/env bash
# ==========================================================
# VOLUME OSD - PipeWire / WirePlumber
# ==========================================================

case "$1" in
    up)
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+
        ;;
    down)
        wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        ;;
    mute)
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        ;;
esac

vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2 * 100)}')
is_muted=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -i "MUTED" || true)

if [ -n "$is_muted" ]; then
    notify-send -h string:x-canonical-private-synchronous:volume -h int:value:0 "Volume: Muted" -t 1200 -i audio-volume-muted
else
    notify-send -h string:x-canonical-private-synchronous:volume -h int:value:"$vol" "Volume: ${vol}%" -t 1200 -i audio-volume-high
fi
