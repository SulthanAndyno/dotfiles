
# fnm
set -l FNM_PATH "/home/Shuu/.local/share/fnm"
if test -d "$FNM_PATH"
  fish_add_path "$FNM_PATH"
  if not set -q FNM_MULTISHELL_PATH
    fnm env --shell fish | source
  end
end
