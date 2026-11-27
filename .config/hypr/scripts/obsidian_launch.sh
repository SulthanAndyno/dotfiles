#!/usr/bin/env bash
# Focus existing Obsidian window across workspaces, or launch Obsidian if closed.
ADDR=$(hyprctl clients -j 2>/dev/null | jq -r '[.[] | select(.class | test("obsidian"; "i"))][0].address // empty')
if [ -n "$ADDR" ]; then
    hyprctl eval "hl.dispatch(hl.dsp.focus({ window = \"address:${ADDR}\" }))" >/dev/null 2>&1
else
    obsidian >/dev/null 2>&1 &
fi
