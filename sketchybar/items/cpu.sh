#!/bin/bash

sketchybar --add item cpu right \
           --set cpu  update_freq=2 \
                      icon=􀧓  \
                      icon.color=$PINK \
                      background.border_width=1 \
                      background.border_color=$BG_BORDER_COLOR \
                      background.drawing=on\
                      script="$PLUGIN_DIR/cpu.sh" \
            click_script='open -a "Activity Monitor"'
