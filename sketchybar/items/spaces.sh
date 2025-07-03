#!/bin/bash

# SPACE_SIDS=(1 2 3 4 5 6 7 8 9 10)
#
# for sid in "${SPACE_SIDS[@]}"
# do
#   sketchybar --add space space.$sid left                                 \
#              --set space.$sid space=$sid                                 \
#                               icon=$sid                                  \
#                               label.font="sketchybar-app-font:Regular:16.0" \
#                               label.padding_right=20                     \
#                               label.y_offset=-1                          \
#                               script="$PLUGIN_DIR/space.sh"
# done
#
# sketchybar --add item space_separator left                             \
#            --set space_separator icon="􀆊"                                \
#                                  icon.color=$ACCENT_COLOR \
#                                  icon.padding_left=4                   \
#                                  label.drawing=off                     \
#                                  background.drawing=off                \
#                                  script="$PLUGIN_DIR/space_windows.sh" \
#            --subscribe space_separator space_windows_change
#
#
sketchybar --add event aerospace_workspace_change


for sid in $(aerospace list-workspaces --all); do
  apps=$(aerospace list-windows --workspace "$sid" | awk -F'|' '{gsub(/^ *| *$/, "", $2); print $2}')
    if [ "${apps}" != "" ]; then
        icon_strip=" "
        while read -r app; do
            icon_strip+=" $($CONFIG_DIR/plugins/icon_map_fn.sh "$app")"
        done <<<"${apps}"
    else
        icon_strip=""
    fi 

    sketchybar --add item "space.$sid" center \
        --subscribe "space.$sid" aerospace_workspace_change \
        --set "space.$sid" \
        icon="$sid"\
        label="$icon_strip" \
                              icon.font="Jetbrains Mono:Regular:16.0"  \
                              icon.padding_left=5                         \
                              icon.padding_right=5                         \
                              icon.color=$RED2 \
                              label.padding_left=5 \
                              label.padding_right=20                       \
                              icon.highlight_color=$RED                     \
                              background.border_color=$BG_BORDER_COLOR \
                              background.border_width=0.5 \
                              background.color=$ITEM_BG_COLOR\
                              background.corner_radius=10 \
                              background.height=30 \
                              background.padding_left=5 \
                              background.padding_right=5 \
                              background.drawing=off                         \
                              label.font="sketchybar-app-font:Regular:18:0" \
                              label.background.height=30                    \
                              label.background.corner_radius=5              \
                              label.background.border_width=1 \
                              label.background.border_color=$BG_BORDER_COLOR \
                              label.y_offset=-1.5 \
        click_script="aerospace workspace $sid" \
        script="$CONFIG_DIR/plugins/aerospacer.sh $sid"


done

# # Push to SketchyBar: number stays as 'icon', icons go into the label
# if [ -n "$ICONS" ]; then
#   sketchybar --set "$NAME" \
#     label="$ICONS" \
#     label.drawing=on \
#     label.font="sketchybar-app-font:Regular:16.0" \
#     label.padding_left=5
# else
#   # no windows → hide the label
#   sketchybar --set "$NAME" label.drawing=off
# fi

# sketchybar   --add item       separator center                         \
#              --set separator  icon=                                  \
#                               icon.color=$ACCENT_COLOR \
#                               icon.padding_left=4 \
#                               label.drawing=off \
#                               background.drawing=off \
#              --subscribe space_separator space_windows_change
#
#
#
#
                              # icon.font="Hack Nerd Font:Regular:16.0" \
                              # background.padding_left=15              \
                              # background.padding_right=15             \
                              # associated_display=active               \
                              # icon.color=$WHITE
