#!/bin/bash

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_INFO=$(ps -eo pcpu,user)
CPU_SYS=$(echo "$CPU_INFO" | grep -v $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")
CPU_USER=$(echo "$CPU_INFO" | grep $(whoami) | sed "s/[^ 0-9\.]//g" | awk "{sum+=\$1} END {print sum/(100.0 * $CORE_COUNT)}")

CPU_PERCENT="$(echo "$CPU_SYS $CPU_USER" | awk '{printf "%.0f\n", ($1 + $2)*100}')"

# Icon color thresholds (use explicit hex to avoid env dependency):
# - Green: 0-30%
# - Yellow: 31-60%
# - Red: 61-100%
COLOR="0xff00ff00"    # Green
if [ "$CPU_PERCENT" -le 30 ]; then
  COLOR="0xff00ff00"
elif [ "$CPU_PERCENT" -le 60 ]; then
  COLOR="0xfffffa00"
else
  COLOR="0xffff0000"
fi

sketchybar --set $NAME label="$CPU_PERCENT%" icon.color="$COLOR"
