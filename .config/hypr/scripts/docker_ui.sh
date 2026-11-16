#!/usr/bin/env bash
# ==========================================================
# DOCKER UI LAUNCHER (Lazydocker + Auto Service Health Check)
# ==========================================================

# 1. Check if Docker daemon is running
if ! docker info >/dev/null 2>&1; then
    notify-send -u normal -i docker -a "Docker" "Menyalakan Docker Service..." "Menghubungkan ke docker.sock..."
    pkexec systemctl start docker 2>/dev/null || sudo systemctl start docker 2>/dev/null
fi

# 2. Re-check and launch
if docker info >/dev/null 2>&1; then
    kitty --class lazydocker -e lazydocker
else
    # Show friendly help dialog if docker still isn't running
    notify-send -u critical -i dialog-error -a "Docker" "Docker Service Belum Aktif!" "Jalankan: sudo systemctl start docker di Kitty."
    kitty --class lazydocker -e bash -c 'echo -e "\e[1;31m[!] Docker Service belum berjalan.\e[0m\n\nMenjalankan: sudo systemctl start docker...\n"; sudo systemctl start docker && lazydocker'
fi
