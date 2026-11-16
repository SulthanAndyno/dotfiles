#!/usr/bin/env bash
# ==========================================================
# GIT COMMITS & DEV ACTIVITY WIDGET (Catppuccin TUI HUD)
# ==========================================================

# 1. Target directory detection
TARGET_DIR="${1:-}"

if [ -z "$TARGET_DIR" ]; then
    # Auto-detect git repo in current pwd, or pick latest modified in /workspace/Projects
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        TARGET_DIR="$(git rev-parse --show-toplevel)"
    else
        # Find the most recently touched project repo
        LATEST=$(find /workspace/Projects /workspace -maxdepth 2 -name ".git" -type d -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n 1 | awk '{print $2}')
        if [ -n "$LATEST" ]; then
            TARGET_DIR=$(dirname "$LATEST")
        else
            TARGET_DIR="$HOME/dots-hyprland"
        fi
    fi
fi

cd "$TARGET_DIR" || exit 1

# 2. Render loop
while true; do
    clear
    REPO_NAME=$(basename "$TARGET_DIR")
    BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "detached")
    
    # Remote sync status
    UPSTREAM=$(git rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>/dev/null || echo "")
    SYNC_STATUS="local only"
    if [ -n "$UPSTREAM" ]; then
        AHEAD=$(git rev-list --count "@{u}..HEAD" 2>/dev/null || echo 0)
        BEHIND=$(git rev-list --count "HEAD..@{u}" 2>/dev/null || echo 0)
        SYNC_STATUS="⇡ ${AHEAD} ahead  •  ⇣ ${BEHIND} behind"
    fi

    # Working tree dirty status
    DIRTY_FILES=$(git status --porcelain 2>/dev/null | wc -l)
    if [ "$DIRTY_FILES" -eq 0 ]; then
        TREE_STATUS="\e[1;32m✔ Working tree clean\e[0m"
    else
        TREE_STATUS="\e[1;33m● ${DIRTY_FILES} file(s) with uncommitted changes\e[0m"
    fi

    echo -e "\e[1;35m╭──────────────────────────────────────────────────────────────────────────╮\e[0m"
    echo -e "\e[1;35m│\e[0m \e[1;36m🐙 GIT DEV WIDGET\e[0m  •  \e[1;37m${REPO_NAME}\e[0m \e[90m(${TARGET_DIR})\e[0m"
    echo -e "\e[1;35m│\e[0m 🌿 Branch: \e[1;34m${BRANCH}\e[0m  │  Sync: \e[33m${SYNC_STATUS}\e[0m"
    echo -e "\e[1;35m│\e[0m Status: ${TREE_STATUS}"
    echo -e "\e[1;35m├──────────────────────────────────────────────────────────────────────────┤\e[0m"
    echo -e "\e[1;35m│\e[0m \e[1;33m📜 Recent Commits:\e[0m"
    echo -e "\e[1;35m╰──────────────────────────────────────────────────────────────────────────╯\e[0m"
    echo ""

    # Output colorful git graph (10 commits)
    git log --graph \
        --pretty=format:'%C(yellow)%h%Creset %C(green)(%cr)%Creset %C(bold cyan)%d%Creset %s %C(dim white)<%an>%Creset' \
        --date=relative -n 12 2>/dev/null

    echo ""
    echo -e "\e[90m────────────────────────────────────────────────────────────────────────────\e[0m"
    echo -e "\e[1;37m[r]\e[0m Refresh  │  \e[1;37m[l]\e[0m Lazygit  │  \e[1;37m[b]\e[0m GitHub Web  │  \e[1;37m[s]\e[0m Switch Repo  │  \e[1;37m[q]\e[0m Close"
    echo -e "\e[90m────────────────────────────────────────────────────────────────────────────\e[0m"

    read -r -s -n 1 -t 15 KEY || true

    case "$KEY" in
        l|L)
            lazygit
            ;;
        b|B)
            REMOTE_URL=$(git config --get remote.origin.url 2>/dev/null || echo "")
            if [ -n "$REMOTE_URL" ]; then
                WEB_URL=$(echo "$REMOTE_URL" | sed -e 's/git@github.com:/https:\/\/github.com\//' -e 's/\.git$//')
                zen-browser "$WEB_URL" &
            else
                zen-browser "https://github.com" &
            fi
            ;;
        s|S)
            SELECTED=$(find /workspace/Projects /workspace "$HOME/dots-hyprland" "$HOME/dotfiles" -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's/\/\.git$//' | sort -u | fuzzel --dmenu -p "Pilih Project: " -w 50)
            if [ -n "$SELECTED" ] && [ -d "$SELECTED" ]; then
                TARGET_DIR="$SELECTED"
                cd "$TARGET_DIR" || true
            fi
            ;;
        q|Q)
            break
            ;;
        r|R)
            continue
            ;;
        *)
            continue
            ;;
    esac
done
