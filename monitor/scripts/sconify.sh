#!/usr/bin/env bash

# Paths to useful directories.
VENV_DIR=/venv

# Clears the virtual environment folder /bin folder.
rm -rf "$VENV_DIR/bin"

# Creates the folder with the SCONE-enabled Python executable.
mkdir -p "$VENV_DIR/bin"
cp -p "/usr/local/bin/python3" "$VENV_DIR/bin"