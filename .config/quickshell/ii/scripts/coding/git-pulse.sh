#!/usr/bin/env bash
# Scan developer git repositories for branch, uncommitted count, and ahead/behind counts.
set -u

SHOW_CLEAN="${1:-0}"

REPOS=$(find /workspace/Projects /workspace /home/Shuu/dotfiles -maxdepth 2 -name ".git" -type d 2>/dev/null | sed 's|/\.git$||' | sort -u)

[ -z "$REPOS" ] && exit 0

DIRTY_OUT=""
CLEAN_OUT=""

while IFS= read -r repo; do
    [ -n "$repo" ] && [ -d "$repo/.git" ] || continue
    name=$(basename "$repo")
    branch=$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")
    dirty=$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    counts=$(git -C "$repo" rev-list --left-right --count '@{u}...HEAD' 2>/dev/null || echo "0 0")
    behind=$(printf "%s" "$counts" | awk '{print $1+0}')
    ahead=$(printf "%s" "$counts" | awk '{print $2+0}')

    line="${repo}|${name}|${branch}|${dirty}|${ahead}|${behind}"
    if [ "$dirty" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        DIRTY_OUT="${DIRTY_OUT}${line}\n"
    elif [ "$SHOW_CLEAN" = "1" ]; then
        CLEAN_OUT="${CLEAN_OUT}${line}\n"
    fi
done <<< "$REPOS"

printf "%b%b" "$DIRTY_OUT" "$CLEAN_OUT"
