#!/usr/bin/env bash
# ==========================================================
# SCREENSHOT SNIPPING TOOL (SUPER + SHIFT + S)
# ==========================================================

SAVE_DIR="/home/Shuu/Pictures/Screenshots"
mkdir -p "$SAVE_DIR"

# Area Snipping Tool with Slurp & Grim
GEOMETRY=$(slurp -d -c "e06c75" -b "1e1e2ecc" -s "00000000" 2>/dev/null)
if [ -z "$GEOMETRY" ]; then
    # User canceled selection (e.g. Esc)
    exit 0
fi

TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILE="$SAVE_DIR/Screenshot_${TIMESTAMP}.png"

grim -g "$GEOMETRY" "$FILE"
wl-copy < "$FILE"

notify-send -u low -i "$FILE" -a "Screenshot" "Screenshot Tersimpan! 📸" "Disimpan ke Pictures/Screenshots\n& otomatis disalin ke clipboard."
