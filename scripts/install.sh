#!/usr/bin/env bash
# ==============================================================================
# Dotfiles Deployment Script
# Author: Sulthan Andyno (SulthanAndyno)
# System: ASUS TUF Gaming A15 (FA506NC)
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="${HOME}/.config"
BACKUP_DIR="${HOME}/.config_backup_$(date '+%Y%m%d_%H%M%S')"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; }

backup_item() {
    local target="$1"
    if [ -e "${target}" ] || [ -L "${target}" ]; then
        mkdir -p "${BACKUP_DIR}"
        info "Backing up ${target} -> ${BACKUP_DIR}/"
        mv "${target}" "${BACKUP_DIR}/"
    fi
}

deploy_copy() {
    info "Deploying configurations using copy mode..."
    mkdir -p "${CONFIG_DIR}"

    ITEMS=("hypr" "quickshell" "kitty" "wlogout" "fuzzel" "fish" "fastfetch" "btop")

    for item in "${ITEMS[@]}"; do
        if [ -d "${DOTFILES_DIR}/.config/${item}" ]; then
            backup_item "${CONFIG_DIR}/${item}"
            info "Copying ${item}..."
            cp -r "${DOTFILES_DIR}/.config/${item}" "${CONFIG_DIR}/"
        fi
    done

    if [ -f "${DOTFILES_DIR}/.config/starship.toml" ]; then
        backup_item "${CONFIG_DIR}/starship.toml"
        cp "${DOTFILES_DIR}/.config/starship.toml" "${CONFIG_DIR}/starship.toml"
    fi

    # Make scripts executable
    find "${CONFIG_DIR}/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

    success "All configurations deployed successfully!"
    if [ -d "${BACKUP_DIR}" ]; then
        info "Old configs were safely archived in: ${BACKUP_DIR}"
    fi
}

deploy_symlink() {
    info "Deploying configurations using symlink mode..."
    mkdir -p "${CONFIG_DIR}"

    ITEMS=("hypr" "quickshell" "kitty" "wlogout" "fuzzel" "fish" "fastfetch" "btop")

    for item in "${ITEMS[@]}"; do
        if [ -d "${DOTFILES_DIR}/.config/${item}" ]; then
            backup_item "${CONFIG_DIR}/${item}"
            info "Symlinking ${item}..."
            ln -s "${DOTFILES_DIR}/.config/${item}" "${CONFIG_DIR}/${item}"
        fi
    done

    if [ -f "${DOTFILES_DIR}/.config/starship.toml" ]; then
        backup_item "${CONFIG_DIR}/starship.toml"
        ln -s "${DOTFILES_DIR}/.config/starship.toml" "${CONFIG_DIR}/starship.toml"
    fi

    find "${DOTFILES_DIR}/.config/hypr/scripts" -type f -name "*.sh" -exec chmod +x {} + 2>/dev/null || true

    success "All configurations symlinked successfully!"
    if [ -d "${BACKUP_DIR}" ]; then
        info "Old configs were safely archived in: ${BACKUP_DIR}"
    fi
}

echo "=========================================================="
echo "   Sulthan's Dotfiles Installer (ASUS TUF A15 / Hyprland) "
echo "=========================================================="
echo "Choose deployment method:"
echo "1) Safe Copy (recommended, leaves dotfiles repo untouched)"
echo "2) Symlink (creates live links to this dotfiles repository)"
echo "q) Quit"
echo "=========================================================="

read -rp "Enter choice [1/2/q]: " CHOICE

case "${CHOICE}" in
    1)
        deploy_copy
        ;;
    2)
        deploy_symlink
        ;;
    q|Q)
        info "Cancelled."
        exit 0
        ;;
    *)
        err "Invalid choice. Aborting."
        exit 1
        ;;
esac
