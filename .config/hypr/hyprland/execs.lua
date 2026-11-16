-- ==========================================================
-- HYPRLAND AUTOSTART EXECUTIONS (end-4 / Quickshell Default)
-- ==========================================================
hl.on("hyprland.start", function ()
    -- Sync DBus & systemd user environment
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Authentication Agent
    hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")

    -- Quickshell (end-4 Desktop Shell: Dynamic Island, Top Bar, Widgets)
    hl.exec_cmd("qs -c ii")

    -- Auto Power & Refresh Rate Manager (144Hz on Charger / 60Hz on Battery)
    hl.exec_cmd("bash $HOME/.config/hypr/scripts/power_profile_auto.sh")

    -- Idle & Lock Management
    hl.exec_cmd("hypridle")

    -- Geoclue Location Agent
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")

    -- Clipboard History (Cliphist integrated with Quickshell)
    hl.exec_cmd("wl-paste --type text --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'")
    hl.exec_cmd("wl-paste --type image --watch bash -c 'cliphist store && qs -c ii ipc call cliphistService update'")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
