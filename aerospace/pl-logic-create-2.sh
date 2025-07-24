#!/bin/bash

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-create-2.app/Contents/MacOS/pl-create-2"

if pgrep -x "Vienna Ensemble Pro" >/dev/null \
  || pgrep -x "Omnibus" >/dev/null \
  || pgrep -x "pl-create-2" >/dev/null \
  || pgrep -x "Omnibus" >/dev/null \
  || pgrep -x "Console" >/dev/null \
  || pgrep -x "SSL 360" >/dev/null; then
# At least one app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
