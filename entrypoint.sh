#!/usr/bin/bash
set -e
echo "Checking TensorFlow CUDA" >> "$HOME/test.txt"

# Check the Tensorflow installation & write it to a log file.
source $HOME/.venv/bin/activate
python3 $HOME/run.py

exec  bash -l