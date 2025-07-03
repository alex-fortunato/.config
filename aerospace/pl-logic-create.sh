#!/bin/bash

# Path to packaged binary:
LAUNCHER="/Users/alexanderfortunato/Development/prompt-launcher/dist/pl-create.app/Contents/MacOS/pl-create"

if pgrep -x "Cubase 14" >/dev/null \
  || pgrep -x "Live" >/dev/null \
  || pgrep -x "pl-create" >/dev/null \
  || pgrep -x "Pro Tools" >/dev/null \
  || pgrep -x "Resolve" >/dev/null \
  || pgrep -x "Sibelius" >/dev/null; then
# At least one app is running => do nothing
  exit -
else
  # None of them are running => exec launcher
  exec "$LAUNCHER"
fi
