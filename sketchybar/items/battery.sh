#!/bin/bash

sketchybar --add item battery right \
           --set battery update_freq=120 \
                        icon.font="SF Pro:Semibold:11.0" \
                        icon.color=$WHITE \
                        label.font.size=11.0 \
                        script="$PLUGIN_DIR/battery.sh" \
           --subscribe battery system_woke power_source_change
