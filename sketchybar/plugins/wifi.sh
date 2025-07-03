#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Check current Wi-Fi network using networksetup
wifi_info=$(networksetup -getairportnetwork en0 2>/dev/null)

if [[ $wifi_info == *You\ are\ not\ associated* || $wifi_info == *off* || -z $wifi_info ]]; then
  icon="􀙈"  # Disconnected icon
  label="Not Connected"
  color="$RED2"
else
  icon="􀙇"  # Connected icon
  network_name=${wifi_info#*: }
  label="$network_name"
  color="$PINK"
fi

sketchybar --set "$NAME" icon="$icon" label="$label" icon.color="$color"

