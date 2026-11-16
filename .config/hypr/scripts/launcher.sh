#!/usr/bin/env bash
# ==========================================================
# SMART LAUNCHER WRAPPER (DUX / NOCTALIA / FUZZEL)
# ==========================================================

if pgrep -x "dms" >/dev/null 2>&1; then
    dms ipc call spotlight toggle 2>/dev/null && exit 0
fi

if pgrep -x "noctalia" >/dev/null 2>&1; then
    noctalia msg panel-toggle launcher 2>/dev/null && exit 0
fi

fuzzel
