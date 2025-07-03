#!/bin/bash

echo "called with $1"
echo "$FOCUSED_WORKSPACE"

if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set $NAME background.drawing=on \
                           background.color=0xff000000 \
                           icon.color=0xffff10f0\
                           background.border_color=0xff9d9d9d \
                           background.border_width=1 \
                           label.color=0xffffffff \
                           # label.background.color=0xb34d4d4d
    #                       # dark blue is 0xff37667f
                    
                  
else
    sketchybar --set $NAME background.drawing=on \
                          background.color=0x8a000000\
                          background.border_color=0xd6585858 \
                          background.border_width=1 \
                          icon.color=0xffffffff \
                          label.color=0xff535353 \
                          # label.background.color=0xb31d1d1d
fi

