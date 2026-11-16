<div align="center">

# ❄️ Sulthan's Modern Dotfiles

### Clean, High-Performance Hyprland & Quickshell Setup for ASUS TUF Gaming A15

[![OS: Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-1793D1?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Compositor: Hyprland 0.57.2](https://img.shields.io/badge/Compositor-Hyprland%20v0.57.2%20(Lua)-00bcd4?logo=hyprland&logoColor=white)](https://hyprland.org/)
[![Shell: Quickshell](https://img.shields.io/badge/Shell-Quickshell%20QML-e95420)](https://quickshell.outfoxxed.me/)
[![Terminal: Kitty](https://img.shields.io/badge/Terminal-Kitty-1e1e2e?logo=kitty&logoColor=white)](https://sw.kovidgoyal.net/kitty/)
[![Shell: Fish](https://img.shields.io/badge/Shell-Fish-d65d0e?logo=fish&logoColor=white)](https://fishshell.com/)
[![CI: Security & Lint](https://img.shields.io/badge/CI-Gitleaks%20%2B%20ShellCheck-brightgreen?logo=github-actions&logoColor=white)](https://github.com/SulthanAndyno/dotfiles/actions)

---

</div>

Personal dotfiles crafted by **[@SulthanAndyno](https://github.com/SulthanAndyno)** for daily driving, development, and gaming on Arch Linux. Featuring a pure **Lua-based Hyprland 0.57.2** configuration, reactive **Quickshell (QML)** desktop bar and widgets, and customized hardware automation for dual-GPU laptops.

---

## 💻 Hardware Specifications

Configured and fine-tuned specifically for:

| Component | Specification |
| :--- | :--- |
| **Model** | ASUS TUF Gaming A15 (FA506NC) |
| **Processor** | AMD Ryzen 5 7535HS (6 Cores, 12 Threads @ 4.55 GHz Turbo) |
| **Integrated GPU** | AMD Radeon 660M (RDNA 2) |
| **Dedicated GPU** | NVIDIA GeForce RTX 3050 Mobile (4GB GDDR6, Proprietary Drivers) |
| **Memory** | 16 GB DDR5 @ 4800 MHz |
| **Display** | 15.6" Full HD (1920x1080) IPS, 144Hz |
| **Operating System** | Arch Linux (Kernel `linux-cachyos` / `linux` 6.18+) |

---

## ✨ Key Features & Custom Engineering

### 🎮 Custom NVIDIA RTX 3050 Telemetry
- Integrated dedicated GPU metrics directly into Quickshell (`services/ResourceUsage.qml`):
  - **GPU Core Load %**
  - **VRAM Utilization** (e.g., `1.8 / 4.0 GiB`)
  - **GPU Temperature** in Celsius
- Displayed both in the quick-glance status popup and circular gauge meters.

### ⚡ Dynamic Power & Refresh Rate Daemon (`power_profile_auto.sh`)
- Automated background daemon responding to AC power state changes via UPower / sysfs:
  - **On AC Power (Plugged In)**: Automatically switches to **Performance Mode** and bumps display to **144Hz**.
  - **On Battery**: Drops refresh rate to **60Hz** and activates **Balanced / Power-Saver Mode** to maximize battery longevity.

### 💎 Modern Pure Lua Hyprland Architecture
- Fully migrated to **Hyprland 0.57.2 Lua API** (`hyprland.lua`).
- Clean modular structure separating default presets (`hyprland/`) from user customizations (`custom/`).
- Dynamic IPC dispatchers using `hl.dsp.*` calls.

### 🎨 Visual Polish & Focus Dimming
- Subdued **focus dimming** (`dim_strength = 0.16` with smooth `fadeDim` cubic bezier curve) for distraction-free coding.
- Custom frosted glass power menu (`wlogout`) with centered interactive power controls.
- Fast, minimalist application launcher powered by `fuzzel`.

### 🛡️ Security-First CI/CD Pipeline
- Includes GitHub Actions workflow running:
  - **Gitleaks**: Automatic scans preventing accidental secret/token leaks.
  - **ShellCheck**: Static analysis for shell utility scripts.
  - **Lua Syntax Validator**: Verifies Hyprland Lua code before deployment.

---

## 📂 Repository Structure

```text
dotfiles/
├── .config/
│   ├── hypr/               # Hyprland 0.57.2 Lua configuration & custom scripts
│   ├── quickshell/         # Quickshell (ii) QML shell, widgets, and GPU monitors
│   ├── kitty/              # Kitty terminal configuration & styling
│   ├── fish/               # Fish shell aliases, functions, and completions
│   ├── fuzzel/             # Minimalist app launcher settings
│   ├── wlogout/            # Frosted glass Wayland logout menu
│   ├── fastfetch/          # Custom fetch layout and ASCII art
│   ├── btop/               # Resource monitor themes and config
│   └── starship.toml       # Cross-shell prompt styling
├── scripts/
│   ├── sync.sh             # Sync active configs from ~/.config to this repo
│   └── install.sh          # Safe deployment script (copy or symlink mode)
├── .github/
│   └── workflows/
│       └── ci.yml          # GitHub Actions Gitleaks & linting pipeline
└── .gitignore              # Strict ignore rules for state, tokens, and caches
```

---

## 🚀 Installation & Usage

### 1. Clone the repository
```bash
git clone https://github.com/SulthanAndyno/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. Deploy configurations
Run the interactive deployment script:
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```
*You can choose between **Safe Copy** (backs up existing configs) or **Symlink Mode**.*

### 3. Sync changes back to dotfiles
When making tweaks to your live `~/.config/`, sync them cleanly with:
```bash
# Preview status
./scripts/sync.sh status

# Pull changes from ~/.config to repository
./scripts/sync.sh pull

# Commit & push to GitHub
./scripts/sync.sh push "feat: add new custom keybind"
```

---

## 💖 Credits & Acknowledgements

This personal setup builds upon and draws heavy inspiration from the awesome open-source community:

* **[end-4](https://github.com/end-4)** — Creator of **[dots-hyprland](https://github.com/end-4/dots-hyprland)**. Huge credit and gratitude for the foundational Quickshell (`illogical-impulse`) design, architecture, and aesthetic UI concepts.
* **[Hyprland](https://github.com/hyprwm/Hyprland)** by **Vaxry & contributors** — For the ultimate smooth, dynamic tiling Wayland compositor.
* **[Quickshell](https://github.com/outfoxxed/quickshell)** by **outfoxxed** — For providing a flexible, high-performance QML-based desktop shell toolkit.
* **[Catppuccin](https://github.com/catppuccin/catppuccin)** — For beautiful color palettes and community themes.

---

<div align="center">
  <sub>Maintained with ❤️ by <a href="https://github.com/SulthanAndyno">Sulthan Andyno</a></sub>
</div>
