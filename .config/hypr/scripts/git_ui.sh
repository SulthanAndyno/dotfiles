#!/usr/bin/env bash
# ==========================================================
# GIT & GITHUB UI LAUNCHER (Interactive Fuzzel + Lazygit)
# ==========================================================

# 1. If executed inside a git repository, open directly
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    kitty --class lazygit -e lazygit
    exit 0
fi

# 2. Collect user's git repositories
PROJECTS_DIR="/workspace/Projects"
WORKSPACE_DIR="/workspace"

REPOS=$(find "$PROJECTS_DIR" "$WORKSPACE_DIR" "$HOME/dots-hyprland" "$HOME/dotfiles" -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's/\/\.git$//' | sort -u)

# 3. Build Fuzzel selection menu
MENU="🌐 Buka GitHub Website (github.com)"
while IFS= read -r repo; do
    if [ -n "$repo" ] && [ -d "$repo/.git" ]; then
        bname=$(basename "$repo")
        MENU="$MENU\n📁 $bname  ($repo)"
    fi
done <<< "$REPOS"

CHOSEN=$(echo -e "$MENU" | fuzzel --dmenu -p "🐙 Git / GitHub UI: " -l 9 -w 55)

if [ -z "$CHOSEN" ]; then
    exit 0
fi

if [[ "$CHOSEN" == *"Buka GitHub"* ]]; then
    zen-browser "https://github.com" &
    exit 0
fi

# Extract repo path
TARGET_DIR=$(echo "$CHOSEN" | grep -o '([^)]*)' | tr -d '()')

if [ -d "$TARGET_DIR" ]; then
    kitty --class lazygit --directory "$TARGET_DIR" -e lazygit
fi
