#!/bin/bash

echo "called with $1"
echo "$FOCUSED_WORKSPACE"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=off \
                           icon.color=0xffff10f0 \
                           label.color=0xffffffff
else
    sketchybar --set $NAME background.drawing=off \
                           icon.color=0xffffffff \
                           label.color=0xff535353
fi

