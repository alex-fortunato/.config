#!/bin/bash

sketchybar --add item cpu right \
           --set cpu  update_freq=2 \
                      icon=􀧓  \
                      icon.font="SF Pro:Semibold:11.0" \
                      icon.color=$PINK \
                      label.font.size=11.0 \
                      script="$PLUGIN_DIR/cpu.sh" \
            click_script='open -a "Activity Monitor"'
