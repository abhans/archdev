#!/bin/bash
set -e

# Activate the virtual environment
source "$HOME/.venv/bin/activate"

# Check the Tensorflow installation & write it to a log file.
if [ -f "$HOME/.dev/run.py" ]; then
    python3 "$HOME/.dev/run.py"
fi
# Remove the script once it finishes executing.
# rm -rf $HOME/dev/run.py

# Start an interactive shell
exec bash -l