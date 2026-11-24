# ==========================================================
# Fish Configuration
# NIKKE Crimson Night
# ==========================================================

# ----------------------------------------------------------
# Startup
# ----------------------------------------------------------

if status is-interactive
    fastfetch
    printf "\n"
end

# ----------------------------------------------------------
# Environment
# ----------------------------------------------------------

# Ollama (install manual di /workspace, model jangan ke root)
set -gx OLLAMA_MODELS /workspace/ollama/models
fish_add_path /workspace/ollama/bin

# ----------------------------------------------------------
# Navigation
# ----------------------------------------------------------

alias c="clear"

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."

# Better cd
zoxide init fish | source

# ----------------------------------------------------------
# Modern CLI
# ----------------------------------------------------------

alias ls="eza --icons=always --group-directories-first"
alias ll="eza -lah --icons=always --group-directories-first"
alias la="eza -a --icons=always"
alias tree="eza --tree --icons=always"

# ----------------------------------------------------------
# Git
# ----------------------------------------------------------

alias lg="lazygit"

# ----------------------------------------------------------
# File Manager
# ----------------------------------------------------------

alias y="yazi"

function yy
    set -l tmp (mktemp)

    yazi --cwd-file="$tmp" $argv

    if test -f "$tmp"
        set -l cwd (cat "$tmp")

        if test -n "$cwd"; and test "$cwd" != "$PWD"
            cd "$cwd"
        end
    end

    rm -f "$tmp"
end

# ----------------------------------------------------------
# Utilities
# ----------------------------------------------------------

alias ff="fastfetch"
alias cat="bat"
alias top="btop"
alias ports="bash $HOME/.config/hypr/scripts/port_manager.sh --list"
alias killport="bash $HOME/.config/hypr/scripts/port_manager.sh --kill"

# On-demand NVIDIA RTX 3050 offload (while keeping desktop on AMD iGPU for battery life)
function rtx --description "Run app or command on NVIDIA RTX 3050"
    env __NV_PRIME_RENDER_OFFLOAD=1 __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0 __GLX_VENDOR_LIBRARY_NAME=nvidia __VK_LAYER_NV_optimus=NVIDIA_only VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json LIBVA_DRIVER_NAME=nvidia $argv
end

# ----------------------------------------------------------
# Custom Launchers
# ----------------------------------------------------------

alias dashboard="$HOME/.local/bin/dashboard"
alias files="$HOME/.local/bin/files"


# Added by Antigravity CLI installer
fish_add_path /home/Shuu/.local/bin

# opencode
fish_add_path /home/Shuu/.opencode/bin

# PHP + Composer (static build di /workspace, bukan /usr/bin/php)
fish_add_path -m /workspace/php/bin /workspace/php/composer/vendor/bin
set -gx COMPOSER_HOME /workspace/php/composer
set -gx COMPOSER_CACHE_DIR /workspace/.cache/composer

# npm global (prefix + cache di /workspace, root sering penuh)
fish_add_path -m /workspace/npm-global/bin

# ----------------------------------------------------------
# Prompt (Starship + Transient Prompt)
# ----------------------------------------------------------

starship init fish | source
enable_transience

# ----------------------------------------------------------
# FZF (Catppuccin Mocha + Crimson Theme)
# ----------------------------------------------------------

set -gx FZF_DEFAULT_OPTS "\
  --height 40% --layout=reverse --border rounded \
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#e06c75 \
  --color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
  --color=selected-bg:#45475a --prompt '❯ ' --pointer '▶ '"

