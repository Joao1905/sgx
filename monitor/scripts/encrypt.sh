#!/usr/bin/env bash

ORIGINAL_DIR=/original
ENCRYPTED_DIR=/sgx/monitor
FSPF_DIR=/fspf
VENV_DIR=/venv

mkdir -p $ENCRYPTED_DIR
mkdir -p $FSPF_DIR

scone fspf create "$FSPF_DIR/fspf.pb"
scone fspf addr "$FSPF_DIR/fspf.pb" / --kernel / --not-protected

scone fspf addr "$FSPF_DIR/fspf.pb" "$VENV_DIR" --kernel "$VENV_DIR" --authenticated
scone fspf addf "$FSPF_DIR/fspf.pb" "$VENV_DIR" "/unauth_venv" "$VENV_DIR"

scone fspf addr "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" --kernel "$ENCRYPTED_DIR" --encrypted
scone fspf addf "$FSPF_DIR/fspf.pb" "$ENCRYPTED_DIR" "$ORIGINAL_DIR" "$ENCRYPTED_DIR"

scone fspf encrypt "$FSPF_DIR/fspf.pb" > "$FSPF_DIR/keytag.out"