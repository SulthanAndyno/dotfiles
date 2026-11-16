#!/usr/bin/env bash
# ==========================================================
# ASUS TUF HARDWARE TELEMETRY & FAN SPEED MONITOR
# Reads directly from kernel hwmon (asus-nb-wmi & k10temp)
# ==========================================================

# 1. CPU Temperature & Fan
CPU_TEMP=$(awk '{printf "%.0f", $1/1000}' /sys/class/hwmon/hwmon6/temp1_input 2>/dev/null || echo "N/A")
CPU_FAN=$(cat /sys/class/hwmon/hwmon10/fan1_input 2>/dev/null || echo "0")

# 2. GPU Temperature & Fan (RTX 3050)
GPU_TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits 2>/dev/null | cut -d "." -f 1 || echo "N/A")
GPU_FAN=$(cat /sys/class/hwmon/hwmon10/fan2_input 2>/dev/null || echo "0")

# 3. Active Refresh Rate
RATE=$(hyprctl monitors -j | jq -r '.[0].refreshRate // 144' | cut -d '.' -f 1)

# 4. Display Notification
notify-send -u low -i preferences-system-performance -a "ASUS TUF Hardware" \
    "🌡️ Status Suhu & Kipas ASUS TUF" \
    " CPU: ${CPU_TEMP}°C  •  🌀 ${CPU_FAN} RPM\n󰢮 GPU: ${GPU_TEMP}°C  •  🌀 ${GPU_FAN} RPM\n⚡ Refresh Rate: ${RATE}Hz"
