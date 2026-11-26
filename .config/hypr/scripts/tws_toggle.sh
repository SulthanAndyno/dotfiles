#!/usr/bin/env bash
# ==========================================================
# ONE-TAP REDMI BUDS BLUETOOTH TOGGLE (SUPER + SHIFT + B)
# Connects/disconnects paired Redmi Buds TWS with battery HUD
# ==========================================================
set -u

FALLBACK_MAC="78:99:87:E8:79:4E"

bluetoothctl power on >/dev/null 2>&1 || true

DEVICE_LINE=$(bluetoothctl devices 2>/dev/null | grep -i -E "Redmi Buds|Xiaomi|Earbuds" | head -n 1 || true)
MAC=$(printf "%s" "$DEVICE_LINE" | awk '{print $2}')
NAME=$(printf "%s" "$DEVICE_LINE" | cut -d' ' -f3-)

if [ -z "$MAC" ]; then
    MAC="$FALLBACK_MAC"
    NAME="Redmi Buds 6 Lite"
fi

INFO=$(bluetoothctl info "$MAC" 2>/dev/null || true)
if [ -z "$INFO" ]; then
    notify-send -u normal -i bluetooth-disabled -a "TWS Quick Toggle" "Device Not Paired" "Pair ${NAME} first via Bluetooth settings."
    exit 1
fi

get_battery_pct() {
    bluetoothctl info "$MAC" 2>/dev/null | sed -n 's/.*Battery Percentage:.*(\([0-9]*\)).*/\1/p' | head -n 1
}

if printf "%s\n" "$INFO" | grep -q "Connected: yes"; then
    if bluetoothctl disconnect "$MAC" >/dev/null 2>&1; then
        notify-send -u low -i audio-headphones -a "TWS Quick Toggle" "${NAME} Disconnected" "Bluetooth audio disconnected cleanly."
    else
        notify-send -u normal -i dialog-error -a "TWS Quick Toggle" "Disconnect Failed" "Could not disconnect ${NAME}."
    fi
else
    notify-send -u low -i bluetooth-active -a "TWS Quick Toggle" "Connecting ${NAME}..." "Make sure earbuds are out of the case."
    if timeout 10 bluetoothctl connect "$MAC" >/dev/null 2>&1; then
        sleep 0.8
        BAT=$(get_battery_pct)
        if [ -n "$BAT" ]; then
            notify-send -u low -i audio-headphones -a "TWS Quick Toggle" "${NAME} Connected" "Battery: ${BAT}%"
        else
            notify-send -u low -i audio-headphones -a "TWS Quick Toggle" "${NAME} Connected" "Audio routed to ${NAME}."
        fi
    else
        notify-send -u normal -i bluetooth-disabled -a "TWS Quick Toggle" "Connection Failed" "Ensure ${NAME} is awake & not connected to another phone."
        exit 1
    fi
fi
