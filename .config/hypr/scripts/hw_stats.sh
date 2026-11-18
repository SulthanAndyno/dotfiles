#!/usr/bin/env bash
# ==========================================================
# ASUS TUF HARDWARE TELEMETRY & FAN SPEED MONITOR
# Dynamically resolves hwmon paths (asus & k10temp) across reboots
# ==========================================================

find_hwmon() {
    local target="$1"
    for dir in /sys/class/hwmon/hwmon*; do
        if [ "$(cat "$dir/name" 2>/dev/null)" = "$target" ]; then
            echo "$dir"
            return 0
        fi
    done
}

K10_DIR=$(find_hwmon "k10temp")
ASUS_DIR=$(find_hwmon "asus")

# 1. CPU Temperature & Fan
CPU_TEMP=$(awk '{printf "%.0f", $1/1000}' "${K10_DIR}/temp1_input" 2>/dev/null || echo "N/A")
CPU_FAN=$(cat "${ASUS_DIR}/fan1_input" 2>/dev/null || echo "0")

# 2. GPU Temperature & Fan (RTX 3050)
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | cut -d "." -f 1 || echo "N/A")
GPU_FAN=$(cat "${ASUS_DIR}/fan2_input" 2>/dev/null || echo "0")

# 3. Active Refresh Rate
RATE=$(hyprctl monitors -j | jq -r '.[0].refreshRate // 144' | cut -d '.' -f 1)

# 4. Display Notification
notify-send -u low -i preferences-system-performance -a "ASUS TUF Hardware" \
    "🌡️ ASUS TUF Temp & Fan Status" \
    " CPU: ${CPU_TEMP}°C  •  🌀 ${CPU_FAN} RPM\n󰢮 GPU: ${GPU_TEMP}°C  •  🌀 ${GPU_FAN} RPM\n⚡ Refresh Rate: ${RATE}Hz"
