# sketchybar --add alias "Control Center,WiFi" right \
#            --set "Control Center,WiFi" alias.color=$GREEN \
#                                        alias.scale=1 \
#                                        icon.padding_left=0 \
#                                        icon.padding_right=0 \
#                                        label.padding_left=0 \
#                                        label.padding_right=0 \
#                                        background.color=0xff000000 \
sketchybar --add item wifi left \
           --set wifi   update_freq=10 \
                        script="$PLUGIN_DIR/wifi.sh" \
                        icon.color=$PINK \
                        icon.padding_left=4 \
                        icon.padding_right=4 \
                        label.padding_left=4 \
                        label.padding_right=6 \
                        background.border_width=1 \
                        label.font.size=12.0 \
                        background.border_color=$BG_BORDER_COLOR
  
                                       


