#!/bin/bash

# Use the exact path to tmux
TMUX_PATH="/usr/local/bin/tmux"

# Check if the tmux executable exists
if [ ! -x "$TMUX_PATH" ]; then
  echo "Error: tmux executable not found at $TMUX_PATH"
  sleep 3
  exit 1
fi

# Check if a tmux session named "main" exists
$TMUX_PATH has-session -t main 2>/dev/null

# If it doesn't exist, create it
if [ $? != 0 ]; then
  # Start a new detached session
  $TMUX_PATH new-session -d -s main
  
  # Allow time for initial session setup
  sleep 0.5
  
  # Explicitly run the TPM plugin installation/refresh
  $TMUX_PATH run-shell '~/.tmux/plugins/tpm/tpm'
  $TMUX_PATH run-shell '~/.tmux/plugins/tpm/bindings/install_plugins'
  
  # Additional time for plugins to load
  sleep 1
fi

# Attach to the session
exec $TMUX_PATH attach-session -t main
