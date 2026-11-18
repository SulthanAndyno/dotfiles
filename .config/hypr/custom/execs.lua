-- ==========================================================
-- CUSTOM AUTOSTART SERVICES
-- ==========================================================
hl.on("hyprland.start", function ()
    -- Bluetooth Pairing & Audio Agent
    hl.exec_cmd("blueman-applet")
end)
