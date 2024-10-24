#!/usr/bin/env bash

# Paths to useful directories.
ORIGINAL_DIR=/original
VENV_DIR=/venv

# Clears the virtual environment folder.
cd "$VENV_DIR"
rm -rf ./*

# Generates a new virtual environment.
python3 -m venv "$VENV_DIR"

# Installs all dependencies on the virtual environment.
export CRYPTOGRAPHY_DONT_BUILD_RUST=1
"$VENV_DIR/bin/python3" -m pip install -r "$ORIGINAL_DIR/requirements.txt"

#"$VENV_DIR/bin/python3" -m pip install --upgrade pip
#"$VENV_DIR/bin/python3" -m pip install --global-option=build_ext --global-option="-static-libgcc" cryptography==3.4.7