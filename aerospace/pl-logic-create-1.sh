#!/bin/bash

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-create-1.app/Contents/MacOS/pl-create-1"

if pgrep -x "Cubase 14" >/dev/null \
  || pgrep -x "Live" >/dev/null \
  || pgrep -x "pl-create-1" >/dev/null \
  || pgrep -x "Logic Pro X" >/dev/null \
  || pgrep -x "Pro Tools" >/dev/null \
  || pgrep -x "Resolve" >/dev/null \
  || pgrep -x "Sibelius" >/dev/null; then
# At least one app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
