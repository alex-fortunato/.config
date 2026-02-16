#!/bin/bash
sketchybar --add item calendar right \
           --set calendar icon=􀧞  \
                         update_freq=30 \
                         icon.color=$PINK\
                         icon.font="SF Pro:Semibold:11.0" \
                         label.font.size=11.0 \
                         background.border_width=1 \
                         background.border_color=$BG_BORDER_COLOR \
                         script="$PLUGIN_DIR/calendar.sh"
