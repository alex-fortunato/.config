#!/bin/sh

# PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
# CHARGING="$(pmset -g batt | grep 'AC Power')"
#
# if [ "$PERCENTAGE" = "" ]; then
#   exit 0
# fi
#
# case "${PERCENTAGE}" in
#   9[0-9]|100) ICON="􀛨" 
#   ;;
#   [6-8][0-9]) ICON="􀺸"
#   ;;
#   [3-5][0-9]) ICON="􀺶"
#   ;;
#   [1-2][0-9]) ICON="􀛩"
#   ;;
#   *) ICON="􀛪"
# esac
#
# if [[ "$CHARGING" != "" ]]; then
#   ICON="􀢋"
# fi
#
# # The item invoking this script (name $NAME) will get its icon and label
# # updated with the current battery status
# sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%"
#


#!/bin/bash

battery_info=$(pmset -g batt)
battery_percent=$(echo "$battery_info" | grep -Eo "\d+%" | cut -d% -f1)
charging=$(echo "$battery_info" | grep "AC Power")

# Determine icon color based on battery level
if [[ $battery_percent -le 20 ]]; then
  color="0xffff0000" # Red
elif [[ $battery_percent -le 70 ]]; then
  color="0xfff1c40f"  # Yellow
else
  color="0xff00ff00"  # Green
fi

# Use your original logic for icon selection
if [[ $charging != "" ]]; then
  icon="􀢋"  # Your original charging icon
else
  if [[ $battery_percent -ge 90 ]]; then
    icon="􀛨"
  elif [[ $battery_percent -ge 70 ]]; then
    icon="􀺸"
  elif [[ $battery_percent -ge 50 ]]; then
    icon="􀺶"
  elif [[ $battery_percent -ge 25 ]]; then
    icon="􀛩"
  else
    icon="􀛪"
  fi
fi

sketchybar --set battery icon="$icon" icon.color="$color" label="${battery_percent}%"
