#!/bin/bash
#prompt-launcher-logic.sh

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-music.app/Contents/MacOS/pl-music"

if pgrep -x "Spotify" >/dev/null \
  || pgrep -x "Music" >/dev/null \
  || pgrep -x "pl-music" >/dev/null; then
# At least one app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
