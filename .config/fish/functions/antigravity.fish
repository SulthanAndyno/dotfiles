function antigravity
    env XDG_CONFIG_HOME=/workspace/Antigravity-data/config XDG_CACHE_HOME=/workspace/Antigravity-data/cache XDG_DATA_HOME=/workspace/Antigravity-data/data /workspace/Antigravity/antigravity --no-sandbox $argv &
    disown
end
