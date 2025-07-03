#!/bin/bash
#prompt-launcher-logic.sh

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-chat.app/Contents/MacOS/pl-chat"

if pgrep -x "WhatsApp" >/dev/null \
  || pgrep -x "Messages" >/dev/null \
  || pgrep -x "pl-chat" >/dev/null \
  || pgrep -x "Discord" >/dev/null; then
# At least one chat app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
