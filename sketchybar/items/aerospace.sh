#!/usr/bin/env bash

sketchybar --add event aerospace_workspace_change
for sid in $(aerospace list-workspaces --all); do
    sketchybar --add item space."$sid" center \
        --subscribe space."$sid" aerospace_workspace_change \
        --set space."$sid" \
        background.color=0x44ffffff \
        background.corner_radius=5 \
        background.height=20 \
        background.drawing=off \
        label.font.size=12.0 \
        label="$sid" \
        click_script="aerospace workspace $sid" \
        script="$PLUGIN_DIR/aerospacer.sh $sid"
done
