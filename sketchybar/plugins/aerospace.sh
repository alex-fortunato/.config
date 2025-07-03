#!/usr/bin/env bash

# make sure it's executable with:
# chmod +x ~/.config/sketchybar/plugins/aerospace.sh
#
# LOGFILE="/tmp/sketchybar_aerospace_debug.log"
# echo "$(date): Script called with arg '$1', FOCUSED_WORKSPACE='$FOCUSED_WORKSPACE'" >> $LOGFILE
#
# # Get the current focused workspace if not provided
# if [ -z "$FOCUSED_WORKSPACE" ]; then
#     FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused)
#     echo "$(date): No FOCUSED_WORKSPACE provided, got '$FOCUSED_WORKSPACE' from aerospace command" >> $LOGFILE
# fi
#
# if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
#     # This workspace is focused, highlight it
#     echo "$(date): Workspace $1 is focused, highlighting" >> $LOGFILE
#     sketchybar --set $NAME background.drawing=on label.color=0xFF000000
# else
#     # This workspace is not focused, use default styling
#     echo "$(date): Workspace $1 is not focused (current is $FOCUSED_WORKSPACE)" >> $LOGFILE
#     sketchybar --set $NAME background.drawing=off label.color=0xFFFFFFFF
# fi


echo "called with $1"
echo "$FOCUSED_WORKSPACE"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on
else
    sketchybar --set $NAME background.drawing=off
fi
