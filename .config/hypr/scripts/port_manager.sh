#!/usr/bin/env bash
# ==========================================================
# LOCALHOST PORT MANAGER & KILLER (Fuzzel GUI + CLI Helper)
# Usage:
#   port_manager.sh           -> Interactive Fuzzel menu (Super+Shift+K)
#   port_manager.sh --list    -> Print active ports table in terminal
#   port_manager.sh --kill N  -> Kill process listening on port N
# ==========================================================

collect_ports() {
    ss -tlnp 2>/dev/null | awk '
    NR > 1 {
        local_addr = $4
        port = local_addr
        sub(/^.*:/, "", port)
        proc = "system/other"
        pid = "-"
        if (match($0, /users:\(\("[^"]+",pid=[0-9]+/)) {
            s = substr($0, RSTART, RLENGTH)
            proc = s
            sub(/^users:\(\("/, "", proc)
            sub(/",pid=.*$/, "", proc)
            pid = s
            sub(/^.*pid=/, "", pid)
        }
        if (port ~ /^[0-9]+$/) {
            pnum = port + 0
            if (pnum >= 32768 && proc == "agy") next
            key = port ":" pid
            if (!seen[key]++) {
                printf "%-6s %-16s %-8s %s\n", ":" port, proc, pid, local_addr
            }
        }
    }' | sort -t: -k2,2n
}

kill_by_pid_and_port() {
    local pid="$1"
    local port="$2"
    local proc="$3"

    if [ -z "$pid" ] || [ "$pid" = "-" ]; then
        notify-send -u normal -i dialog-error -a "Port Manager" "Cannot Kill :${port}" "Process requires root privileges (PID hidden)."
        echo "Cannot kill port :${port} (owned by root/system or no PID found)." >&2
        return 1
    fi

    if kill -15 "$pid" 2>/dev/null; then
        sleep 0.3
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
        notify-send -u low -i process-stop -a "Port Manager" "💀 Killed Port :${port}" "Stopped ${proc} (PID ${pid})."
        echo "Stopped ${proc} (PID ${pid}) on port :${port}."
        return 0
    else
        notify-send -u normal -i dialog-error -a "Port Manager" "Failed to Kill :${port}" "Permission denied for ${proc} (PID ${pid})."
        echo "Failed to stop ${proc} (PID ${pid}) on port :${port}." >&2
        return 1
    fi
}

case "${1:-}" in
    --list|list)
        printf "\033[1;36m%-6s %-16s %-8s %s\033[0m\n" "PORT" "PROCESS" "PID" "ADDRESS"
        collect_ports
        exit 0
        ;;
    --kill|kill)
        TARGET_PORT="${2#:}"
        if [ -z "$TARGET_PORT" ]; then
            echo "Usage: killport <port>" >&2
            exit 1
        fi
        MATCH=$(collect_ports | awk -v p=":${TARGET_PORT}" '$1 == p {print; exit}')
        if [ -z "$MATCH" ]; then
            echo "No user process found listening on port :${TARGET_PORT}" >&2
            exit 1
        fi
        PROC=$(echo "$MATCH" | awk '{print $2}')
        PID=$(echo "$MATCH" | awk '{print $3}')
        kill_by_pid_and_port "$PID" "$TARGET_PORT" "$PROC"
        exit $?
        ;;
esac

PORTS_LIST=$(collect_ports)
if [ -z "$PORTS_LIST" ]; then
    notify-send -u low -i network-server -a "Port Manager" "🔌 No Active Ports" "No listening TCP ports found."
    exit 0
fi

MENU_ITEMS=$(echo "$PORTS_LIST" | awk '{printf "🔌 %-6s  %-14s (PID %-6s)  [%s]\n", $1, $2, $3, $4}')
LINE_COUNT=$(echo "$MENU_ITEMS" | wc -l)
[ "$LINE_COUNT" -gt 10 ] && LINE_COUNT=10

SELECTED=$(echo "$MENU_ITEMS" | fuzzel --dmenu -p "🔌 Active Ports: " -l "$LINE_COUNT" -w 52)
[ -z "$SELECTED" ] && exit 0

PORT=$(echo "$SELECTED" | awk '{gsub(/^:/, "", $2); print $2}')
PROC=$(echo "$SELECTED" | awk '{print $3}')
PID=$(echo "$SELECTED" | sed -n 's/.*(PID \([0-9-]*\)).*/\1/p')

ACTION=$(printf "💀 Kill Process (%s on :%s)\n🌐 Open http://localhost:%s in Browser\n📋 Copy localhost:%s to Clipboard" "$PROC" "$PORT" "$PORT" "$PORT" | fuzzel --dmenu -p "⚡ Port :${PORT} " -l 3 -w 46)

case "$ACTION" in
    *Kill\ Process*)
        kill_by_pid_and_port "$PID" "$PORT" "$PROC"
        ;;
    *Open\ http*)
        xdg-open "http://localhost:${PORT}" >/dev/null 2>&1 &
        ;;
    *Copy*)
        printf "http://localhost:%s" "$PORT" | wl-copy
        notify-send -u low -i edit-copy -a "Port Manager" "📋 Copied" "http://localhost:${PORT} copied to clipboard."
        ;;
esac
