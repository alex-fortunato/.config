#!/bin/sh


LAST_OUTPUT_FILE="/tmp/sketchybar_last_audio_output"
CURRENT_OUTPUT="$(SwitchAudioSource -c 2>/dev/null)"

if [ -n "$CURRENT_OUTPUT" ]; then
  if [ ! -f "$LAST_OUTPUT_FILE" ] || ["$(cat "$LAST_OUTPUT_FILE")" != "$CURRENT_OUTPUT" ]; then
    echo "$CURRENT_OUTPUT" > "$LAST_OUTPUT_FILE"
    SwitchAudioSource -s "$CURRENT_OUTPUT" >/dev/null 2>&1
  fi
fi

if [ "$SENDER" = "volume_change" ]; then
  VOLUME="$INFO"

  case "$VOLUME" in
    [6-9][0-9]|100) ICON="􀊩" COLOR="0xff00ff00"
    ;;
    [3-5][0-9]) ICON="􀊥" COLOR="0xff00ff00"
    ;;
    [1-9]|[1-2][0-9]) ICON="􀊡" COLOR="0xff00ff00"
    ;;
    *) ICON="􀊣" COLOR="0xffff0000"
  esac




  sketchybar --set "$NAME" icon="$ICON" icon.color="$COLOR" label="$VOLUME% - ${CURRENT_OUTPUT}"
fi
