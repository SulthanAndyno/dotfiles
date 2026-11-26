#!/usr/bin/env bash
# ==========================================================
# SMART WINDOW SWITCHER (Alt + Tab)
# Lists mapped Hyprland windows across all workspaces sorted by MRU
# ==========================================================
set -u

pkill -x fuzzel >/dev/null 2>&1 && exit 0

WINDOWS_RAW=$(hyprctl clients -j 2>/dev/null | jq -r '
  [ .[] | select(.mapped == true and .workspace.id >= 1) ]
  | sort_by(if .focusHistoryID == 0 then 999999 else .focusHistoryID end)
  | .[]
  | "[WS \(.workspace.id)]  \(.class)  —  \(.title[0:48])  (\(.address))"
')

[ -z "$WINDOWS_RAW" ] && exit 0

LINE_COUNT=$(printf "%s\n" "$WINDOWS_RAW" | wc -l)
[ "$LINE_COUNT" -gt 10 ] && LINE_COUNT=10

SELECTED=$(printf "%s\n" "$WINDOWS_RAW" | fuzzel --dmenu --match-mode fzf -p "🪟 Switch: " -l "$LINE_COUNT" -w 62)
[ -z "$SELECTED" ] && exit 0

ADDR=$(printf "%s" "$SELECTED" | sed -n 's/.*(\(0x[0-9a-fA-F]*\))$/\1/p')
[ -n "$ADDR" ] && hyprctl dispatch focuswindow "address:${ADDR}" >/dev/null 2>&1
