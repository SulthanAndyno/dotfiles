-- ==========================================================
-- CUSTOM DEVELOPER WORKFLOW RULES (Flutter, Android, Web, DB)
-- ==========================================================

-- 1. Floating Modals for Git & Docker (Lazygit, Lazydocker & Git Commit Widget)
hl.window_rule({ match = { class = "^(lazygit)$" }, float = true })
hl.window_rule({ match = { class = "^(lazygit)$" }, center = true })
hl.window_rule({ match = { class = "^(lazygit)$" }, size = {"85%", "85%"} })

hl.window_rule({ match = { class = "^(lazydocker)$" }, float = true })
hl.window_rule({ match = { class = "^(lazydocker)$" }, center = true })
hl.window_rule({ match = { class = "^(lazydocker)$" }, size = {"88%", "88%"} })

hl.window_rule({ match = { class = "^(git_widget)$" }, float = true })
hl.window_rule({ match = { class = "^(git_widget)$" }, center = true })
hl.window_rule({ match = { class = "^(git_widget)$" }, size = {"82%", "76%"} })

-- 2. Mobile Development (Android Emulator & Phone Mirroring)
hl.window_rule({ match = { class = "^(emulator|qemu-system-x86_64)$" }, float = true })
hl.window_rule({ match = { class = "^(emulator|qemu-system-x86_64)$" }, keep_aspect_ratio = true })
hl.window_rule({ match = { class = "^(scrcpy)$" }, float = true })
hl.window_rule({ match = { class = "^(scrcpy)$" }, keep_aspect_ratio = true })
hl.window_rule({ match = { title = ".*Android Emulator.*" }, float = true })

-- 3. Web & API Development
hl.window_rule({ match = { title = ".*DevTools.*" }, float = true })
hl.window_rule({ match = { class = "^(Postman)$" }, tile = true })

-- 4. File dialogs & System Utilities
hl.window_rule({ match = { class = "^(zenity)$" }, float = true })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, float = true })
hl.window_rule({ match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({ match = { class = "^(nm-connection-editor)$" }, float = true })

-- 5. Clean IDE Tiling
hl.window_rule({ match = { class = "^(Code|code-oss|cursor|zed)$" }, tile = true })
