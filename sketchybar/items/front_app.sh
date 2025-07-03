#!/bin/bash

sketchybar --add item front_app center \
           --set front_app       background.color=0x00000000 \
                                 background.border_color=0x00000000 \
                                 background.border_width=1 \
                                 background.padding_left=5 \
                                 padding_right=5 \
                                 icon.color=$WHITE \
                                 icon.font="sketchybar-app-font:Regular:16.0" \
                                 icon.padding_left=10 \
                                 label.color=$PINK \
                                 script="$PLUGIN_DIR/front_app.sh"            \
           --subscribe front_app front_app_switched
