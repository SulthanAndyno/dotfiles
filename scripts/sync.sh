#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Sync Utility
# Author: Sulthan Andyno (SulthanAndyno)
# System: ASUS TUF Gaming A15 (FA506NC) - Arch Linux + Hyprland + Quickshell
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${HOME}/.config"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

sync_from_system() {
    info "Syncing active configurations from ${CONFIG_DIR} to ${DOTFILES_DIR}/.config/ ..."

    # Hyprland
    info "Syncing Hyprland..."
    rsync -av --delete \
        --exclude="*.bak" --exclude="*.old" --exclude=".git" \
        "${CONFIG_DIR}/hypr/" "${DOTFILES_DIR}/.config/hypr/"

    # Quickshell (ii)
    info "Syncing Quickshell..."
    mkdir -p "${DOTFILES_DIR}/.config/quickshell"
    rsync -av --delete \
        --exclude=".venv" --exclude="__pycache__" --exclude="*.pyc" \
        --exclude="states.json" --exclude="notifications.json" --exclude="user/generated" \
        "${CONFIG_DIR}/quickshell/ii/" "${DOTFILES_DIR}/.config/quickshell/ii/"

    # Kitty
    info "Syncing Kitty..."
    mkdir -p "${DOTFILES_DIR}/.config/kitty"
    rsync -av --delete \
        --exclude="*.bak" --exclude="*.old" \
        "${CONFIG_DIR}/kitty/" "${DOTFILES_DIR}/.config/kitty/"

    # Wlogout
    info "Syncing Wlogout..."
    mkdir -p "${DOTFILES_DIR}/.config/wlogout"
    rsync -av --delete "${CONFIG_DIR}/wlogout/" "${DOTFILES_DIR}/.config/wlogout/"

    # Fuzzel
    info "Syncing Fuzzel..."
    mkdir -p "${DOTFILES_DIR}/.config/fuzzel"
    rsync -av --delete "${CONFIG_DIR}/fuzzel/" "${DOTFILES_DIR}/.config/fuzzel/"

    # Fish (excluding runtime variables)
    info "Syncing Fish..."
    mkdir -p "${DOTFILES_DIR}/.config/fish"
    rsync -av --delete \
        --exclude="fish_variables*" --exclude="*.bak" \
        "${CONFIG_DIR}/fish/" "${DOTFILES_DIR}/.config/fish/"

    # Fastfetch
    info "Syncing Fastfetch..."
    mkdir -p "${DOTFILES_DIR}/.config/fastfetch"
    rsync -av --delete "${CONFIG_DIR}/fastfetch/" "${DOTFILES_DIR}/.config/fastfetch/"

    # Btop
    info "Syncing Btop..."
    mkdir -p "${DOTFILES_DIR}/.config/btop"
    rsync -av --delete "${CONFIG_DIR}/btop/" "${DOTFILES_DIR}/.config/btop/"

    # Starship
    if [ -f "${CONFIG_DIR}/starship.toml" ]; then
        info "Syncing Starship prompt..."
        cp "${CONFIG_DIR}/starship.toml" "${DOTFILES_DIR}/.config/starship.toml"
    fi

    success "Sync completed successfully!"
}

status_check() {
    cd "${DOTFILES_DIR}"
    info "Git status of dotfiles repository:"
    git status -s
}

commit_and_push() {
    sync_from_system
    cd "${DOTFILES_DIR}"

    if [ -z "$(git status --porcelain)" ]; then
        warn "No changes detected. Working tree clean."
        exit 0
    fi

    info "Changes detected. Reviewing modified files:"
    git status -s

    MSG="${1:-"chore: auto-sync configuration $(date '+%Y-%m-%d %H:%M:%S')"}"
    git add .
    git commit -m "$MSG"
    success "Committed with message: '$MSG'"

    info "Pushing to remote origin..."
    git push origin main
    success "Successfully pushed to GitHub!"
}

case "${1:-sync}" in
    sync|pull)
        sync_from_system
        ;;
    status|check)
        status_check
        ;;
    push)
        shift || true
        commit_and_push "${1:-}"
        ;;
    *)
        echo "Usage: $0 {sync|pull|status|push [commit_message]}"
        exit 1
        ;;
esac
