#!/bin/bash
#prompt-launcher-logic.sh

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-web.app/Contents/MacOS/pl-web"

if pgrep -x "firefox" >/dev/null \
  || pgrep -x "pl-web" >/dev/null; then
# At least one app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
