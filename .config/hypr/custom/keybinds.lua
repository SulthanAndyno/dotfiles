-- ==========================================================
-- CUSTOM DEVELOPER KEYBINDS (High Ergonomics Daily Driver)
-- ==========================================================
local mainMod = "SUPER"

-- 1. TERMINAL & WORKSPACE ACCESS
hl.bind("CTRL + T", hl.dsp.exec_cmd("kitty"))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + Grave", hl.dsp.workspace.toggle_special("special"), { description = "Dropdown Scratchpad Terminal" })

-- 2. DAILY APPS
hl.unbind(mainMod .. " + E")
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("nautilus --new-window"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("zen-browser"))

-- 3. SCREENSHOTS (Area Snipping & Fullscreen -> /home/Shuu/Pictures/Screenshots)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("/home/Shuu/.config/hypr/scripts/screenshot.sh"), { description = "Area Snipping Screenshot" })
hl.bind("Print", hl.dsp.exec_cmd("mkdir -p /home/Shuu/Pictures/Screenshots && file=\"/home/Shuu/Pictures/Screenshots/Screenshot_$(date +'%Y-%m-%d_%H-%M-%S').png\" && grim \"$file\" && wl-copy < \"$file\" && notify-send -i \"$file\" -a 'Screenshot' 'Fullscreen Captured 📸' 'Disimpan ke Pictures/Screenshots'"), { locked = true, description = "Fullscreen Screenshot" })

-- 4. DEVELOPER DASHBOARDS & WIDGETS (FLOATING UI)
-- Lazygit / GitHub UI: SUPER + SHIFT + G
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/git_ui.sh"), { description = "Git/GitHub UI Dashboard" })
-- Lazydocker UI: SUPER + SHIFT + D
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/docker_ui.sh"), { description = "Docker UI Dashboard" })
-- Git Commits & Activity Widget: SUPER + SHIFT + C
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("kitty --class git_widget -e bash /home/Shuu/.config/hypr/scripts/git_commit_widget.sh"), { description = "Git Commits & Activity Widget" })

-- 5. WINDOW MANAGEMENT (ERGONOMIC FIXES)
-- Real window closing (No annoying popup on Alt+F4)
hl.unbind("ALT + F4")
hl.bind("ALT + F4", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind(mainMod .. " + C", hl.dsp.window.close(), { description = "Window: Close" })
hl.bind(mainMod .. " + Q", hl.dsp.window.close(), { description = "Window: Close" })

-- Split orientation toggle (Vertical <-> Horizontal tiling for Code & Terminal)
hl.bind(mainMod .. " + Backslash", hl.dsp.layout("togglesplit"), { description = "Toggle split orientation" })

-- 6. HARDWARE & POWER PROFILES
-- Display / Screen Duplicate Menu (Windows-style Super+P): SUPER + P
hl.unbind(mainMod .. " + P")
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/display_mode.sh"), { description = "Display & Screen Duplicate Menu" })
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin(), { description = "Window: Pin" })
-- Power Mode Menu: SUPER + F8
hl.bind(mainMod .. " + F8", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/power_profile_menu.sh"), { description = "Power Mode Menu" })
-- Hardware & Fan Telemetry HUD: F9 langsung & SUPER + F9
hl.bind("F9", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/hw_stats.sh"), { description = "Check Temp & Fan Speed (F9)" })
hl.bind("XF86Display", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/hw_stats.sh"), { locked = true, description = "Check Temp & Fan Speed" })
hl.bind(mainMod .. " + F9", hl.dsp.exec_cmd("bash /home/Shuu/.config/hypr/scripts/hw_stats.sh"), { description = "Check Temp & Fan Speed" })

-- 7. FROSTED POWER MENU OVERLAY (WLOGOUT)
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("wlogout -b 5 -c 0 -r 0 -m 0"), { description = "Frosted Glass Power Menu" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("wlogout -b 5 -c 0 -r 0 -m 0"), { description = "Frosted Glass Power Menu" })

-- 8. QUICK CONFIGURATION EDIT
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })
