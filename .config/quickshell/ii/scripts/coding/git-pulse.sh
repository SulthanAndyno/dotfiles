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
    name="${repo##*/}"
    branch="HEAD"
    oid=""
    ahead=0
    behind=0
    dirty=0

    while IFS= read -r sline; do
        case "$sline" in
            "# branch.oid "*)
                oid="${sline#\# branch.oid }"
                ;;
            "# branch.head "*)
                branch="${sline#\# branch.head }"
                ;;
            "# branch.ab "*)
                ab="${sline#\# branch.ab }"
                ahead="${ab%% *}"
                ahead="${ahead#+}"
                behind="${ab##* }"
                behind="${behind#-}"
                ;;
            "# "*)
                ;;
            "")
                ;;
            *)
                dirty=$((dirty + 1))
                ;;
        esac
    done < <(git -C "$repo" status --porcelain=v2 --branch 2>/dev/null)

    if [ "$branch" = "(detached)" ]; then
        if [ -n "$oid" ] && [ "$oid" != "(initial)" ]; then
            branch="${oid:0:7}"
        else
            branch="HEAD"
        fi
    fi

    line="${repo}|${name}|${branch}|${dirty}|${ahead}|${behind}"
    if [ "$dirty" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$behind" -gt 0 ]; then
        DIRTY_OUT+="${line}"$'\n'
    elif [ "$SHOW_CLEAN" = "1" ]; then
        CLEAN_OUT+="${line}"$'\n'
    fi
done <<< "$REPOS"

printf "%s%s" "$DIRTY_OUT" "$CLEAN_OUT"
