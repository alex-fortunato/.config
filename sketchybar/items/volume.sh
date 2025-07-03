#!/bin/bash

sketchybar --add item volume left \
           --set volume script="$PLUGIN_DIR/volume.sh"\
                  icon.color=$PINK \
                  label.font.size=12.0 \
                  --subscribe volume volume_change \
