#!/bin/bash
sketchybar --add item calendar right \
           --set calendar icon=􀧞  \
                         update_freq=30 \
                         icon.color=$PINK\
                         background.border_width=1 \
                         background.border_color=$BG_BORDER_COLOR \
                         background.height=30 \
                         script="$PLUGIN_DIR/calendar.sh"



