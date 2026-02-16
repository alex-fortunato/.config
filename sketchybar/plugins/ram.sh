#!/bin/bash

# Mode selection: app | pressure | used
MODE=${1:-${RAM_MODE:-app}}

vm_value() {
  # Extract numeric value for a given vm_stat label prefix
  # Usage: vm_value "^Pages free:" 3
  local pattern="$1"
  local field=${2:-3}
  echo "$VM_OUT" | awk -v f=$field -v p="$pattern" 'BEGIN{FS=" ";} $0 ~ p {gsub("\\.", "", $f); print $f; exit}'
}

percent() {
  awk -v u="$1" -v t="$2" 'BEGIN { if (t>0) printf "%.0f", (u/t)*100; else print 0 }'
}

# Try fast path for memory pressure (free percentage)
PRESSURE_USED=""
FREE_PCT=$(memory_pressure -Q 2>/dev/null | awk '/System-wide memory free percentage/ {gsub("%", "", $5); print $5}')
if [[ -n "$FREE_PCT" ]]; then
  PRESSURE_USED=$((100 - FREE_PCT))
fi

# Gather vm_stat once for app/used calculations
VM_OUT=$(vm_stat 2>/dev/null)

pages_free=$(vm_value "^Pages free:" 3)
pages_active=$(vm_value "^Pages active:" 3)
pages_inactive=$(vm_value "^Pages inactive:" 3)
pages_speculative=$(vm_value "^Pages speculative:" 3)
pages_wired=$(vm_value "^Pages wired" 4)
pages_compressed=$(vm_value "^Pages occupied by compressor:" 5)
pages_anonymous=$(vm_value "^Anonymous pages:" 3)

# Defaults if missing
pages_free=${pages_free:-0}
pages_active=${pages_active:-0}
pages_inactive=${pages_inactive:-0}
pages_speculative=${pages_speculative:-0}
pages_wired=${pages_wired:-0}
pages_compressed=${pages_compressed:-0}
pages_anonymous=${pages_anonymous:-0}

total_pages=$((pages_free + pages_active + pages_inactive + pages_speculative + pages_wired + pages_compressed))
used_incl_cache_pages=$((total_pages - pages_free))
used_app_pages=$((pages_wired + pages_compressed + pages_anonymous))

USED_PCT_USED=$(percent "$used_incl_cache_pages" "$total_pages")
USED_PCT_APP=$(percent "$used_app_pages" "$total_pages")
USED_PCT_PRESSURE=${PRESSURE_USED:-}

# Choose which metric to display (as a size)
case "$MODE" in
  pressure)
    # If pressure unavailable, color may be based on app. We still display app bytes.
    DISPLAY_MODE="app"
    ;;
  used)
    DISPLAY_MODE="used"
    ;;
  app|*)
    DISPLAY_MODE="app"
    ;;
esac

# Page size and total mem
PAGESIZE=$(sysctl -n hw.pagesize 2>/dev/null || echo 4096)
TOTAL_MEM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)

to_gb_1dp() {
  awk -v b="$1" 'BEGIN { printf "%.1f", b/1073741824 }'
}

case "$DISPLAY_MODE" in
  used)
    USED_BYTES=$((used_incl_cache_pages * PAGESIZE))
    ;;
  app|*)
    USED_BYTES=$((used_app_pages * PAGESIZE))
    ;;
esac

LABEL_VAL_GB=$(to_gb_1dp "$USED_BYTES")
LABEL="${LABEL_VAL_GB} GB"

# Icon color by used GB thresholds: <16 green, 16-24 yellow, 24-32 red
GB=$((1073741824))
T1=$((16 * GB))
T2=$((24 * GB))
T3=$((32 * GB))

if (( USED_BYTES < T1 )); then
  ICON_COLOR="0xff00ff00"  # Green
elif (( USED_BYTES < T2 )); then
  ICON_COLOR="0xfffffa00"  # Yellow
else
  ICON_COLOR="0xffff0000"  # Red (24-32 or above)
fi

sketchybar --set "$NAME" label="$LABEL" icon.color="$ICON_COLOR"
