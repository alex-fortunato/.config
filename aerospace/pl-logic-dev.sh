#!/bin/bash
#prompt-launcher-logic.sh

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-dev.app/Contents/MacOS/pl-dev"

if pgrep -x "kitty" >/dev/null \
  || pgrep -x "clion" >/dev/null \
  || pgrep -x "pycharm" >/dev/null \
  || pgrep -x "pl-dev" >/dev/null \
  || pgrep -x "Xcode" >/dev/null \
  || pgrep -x "TouchDesigner" >/dev/null \
  || pgrep -x "WebStorm" >/dev/null; then
# At least one app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
