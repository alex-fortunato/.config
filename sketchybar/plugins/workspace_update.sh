#!/usr/bin/env bash

# workspace_update.sh - A script to update all workspace indicators at once
# Save this to ~/.config/sketchybar/plugins/workspace_update.sh
# Make it executable: chmod +x ~/.config/sketchybar/plugins/workspace_update.sh

LOGFILE="/tmp/sketchybar_workspace_update.log"

# Get the current focused workspace
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)

echo "$(date): Updating workspace indicators. Focused workspace: $FOCUSED_WORKSPACE" >> $LOGFILE

# Update all workspace indicators
for sid in $(aerospace list-workspaces --all); do
    if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        echo "$(date): Setting workspace $sid as focused" >> $LOGFILE
        sketchybar --set space.$sid background.drawing=on label.color=0xFF000000
    else
        echo "$(date): Setting workspace $sid as unfocused" >> $LOGFILE
        sketchybar --set space.$sid background.drawing=off label.color=0xFFFFFFFF
    fi
done
