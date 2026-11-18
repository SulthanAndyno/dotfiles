-- ==========================================================
-- CUSTOM GENERAL OVERRIDES FOR ASUS TUF GAMING A15
-- ==========================================================

-- 144Hz Smooth Display & VRR
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1,
})

-- Crisp 2px window border to showcase the dynamic Matugen gradient
hl.config({
    general = {
        border_size = 2,
    },
})
