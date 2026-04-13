#!/bin/bash

sketchybar --add item ram right \
           --set ram  update_freq=5 \
                     icon=RAM \
                     icon.font="SF Pro:Semibold:11.0" \
                     icon.color=$PINK \
                     label.font.size=11.0 \
                     script="$PLUGIN_DIR/ram.sh app" \
           --subscribe ram system_woke \
           click_script='open -a "Activity Monitor"'
