#!/bin/bash
set -e

exec bash -l

# Check the Tensorflow installation & write it to a log file.
source $VENV_DIR/bin/activate && python3 $HOME/dev/run.py