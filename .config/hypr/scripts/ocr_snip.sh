#!/usr/bin/env bash
# ==========================================================
# INSTANT OCR SNIPPING TOOL (SUPER + SHIFT + T)
# Captures screen region -> Tesseract OCR -> Clipboard
# ==========================================================
set -u

TMP_IMG=$(mktemp /tmp/ocr_snip_XXXXXX.png)
trap 'rm -f "$TMP_IMG"' EXIT

# Exit cleanly if slurp is already open or user presses Esc
pgrep -x slurp >/dev/null 2>&1 && exit 0

GEOMETRY=$(slurp -d -c "89b4fa" -b "1e1e2ecc" -s "00000000" 2>/dev/null)
[ -z "$GEOMETRY" ] && exit 0

if ! grim -g "$GEOMETRY" "$TMP_IMG" 2>/dev/null; then
    notify-send -u normal -i dialog-error -a "Instant OCR" "OCR Failed" "Could not capture screen region."
    exit 1
fi

TEXT=$(tesseract "$TMP_IMG" stdout -l eng --psm 6 2>/dev/null | sed -e 's/[[:space:]]*$//' | awk 'NF{p=1} p')

if [ -z "$TEXT" ]; then
    notify-send -u low -i edit-find -a "Instant OCR" "No Text Detected" "Try selecting a clearer or larger text area."
    exit 0
fi

printf "%s" "$TEXT" | wl-copy

PREVIEW=$(printf "%s" "$TEXT" | tr '\n' ' ' | cut -c1-120)
[ "${#TEXT}" -gt 120 ] && PREVIEW="${PREVIEW}..."

notify-send -u low -i edit-copy -a "Instant OCR" "Text Copied to Clipboard" "$PREVIEW"
