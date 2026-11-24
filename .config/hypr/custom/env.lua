-- ==========================================================
-- CUSTOM ENVIRONMENT VARIABLES FOR ASUS TUF (HYBRID AMD + RTX 3050)
-- ==========================================================
hl.env("qsConfig", "ii")

-- Keep desktop compositor/apps on AMD iGPU so RTX 3050 can sleep (D3cold).
-- Use the `rtx <app>` Fish function for on-demand NVIDIA PRIME offload.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Wayland & Qt6 Standards
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
